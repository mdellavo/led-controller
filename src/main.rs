mod pixels;
mod effects;
mod runner;
mod api;
mod audio;

use std::sync::{Arc, RwLock, atomic::{AtomicU64, Ordering}};

use audio::AudioAnalysis;

use axum::{routing::{get, post}, Router};
use clap::Parser;
use tracing_subscriber::EnvFilter;

use api::AppState;
use effects::default_registry;
use pixels::ColorOrder;
use runner::{Runner, RunnerConfig, PersistentState, PixelFactory, RegistryFactory};

#[derive(Parser)]
#[command(about = "WS2812B LED strip controller with web interface")]
struct Args {
    /// Number of LEDs in the strip [default: 60, or saved state]
    #[arg(long)]
    pixels: Option<usize>,

    /// GPIO pin number [default: 18, or saved state]
    #[arg(long)]
    gpio_pin: Option<i32>,

    /// Hardware LED brightness 0–255 [default: 25]
    #[arg(long, default_value_t = 25)]
    brightness: u8,

    /// Port to listen on [default: 3000]
    #[arg(long, default_value_t = 3000)]
    port: u16,

    /// File to persist UI state across restarts [default: led-state.json]
    #[arg(long, default_value = "led-state.json")]
    state_file: std::path::PathBuf,

    /// Fade-in duration in milliseconds [default: 3000, or saved state]
    #[arg(long)]
    fade_in_ms: Option<u64>,

    /// Fade-out duration in milliseconds [default: 3000, or saved state]
    #[arg(long)]
    fade_out_ms: Option<u64>,

    /// Crossfade duration in milliseconds [default: 3000, or saved state]
    #[arg(long)]
    crossfade_ms: Option<u64>,

    /// Time each effect plays before auto-advancing (0 = infinite) [default: 0, or saved state]
    #[arg(long)]
    effect_duration_ms: Option<u64>,

    /// Physical color channel order (e.g. rgb, grb, bgr) [default: rgb, or saved state]
    #[arg(long)]
    color_order: Option<String>,

    /// Effect speed multiplier [default: 1.0, or saved state]
    #[arg(long)]
    speed: Option<f32>,

    /// Software brightness scale 0.0–1.0 [default: 1.0, or saved state]
    #[arg(long)]
    brightness_scale: Option<f32>,

    /// Gamma correction exponent [default: 2.2, or saved state]
    #[arg(long)]
    gamma: Option<f32>,

    /// Directory to scan for Lua effect scripts (*.lua) [default: effects/]
    #[arg(long, default_value = "effects")]
    effects_dir: std::path::PathBuf,
}

fn colorwheel(pos: u8) -> [u8; 3] {
    let p = (255u16.wrapping_sub(pos as u16) % 256) as u8;
    if p < 85 {
        [255 - p * 3, 0, p * 3]
    } else if p < 170 {
        let p = p - 85;
        [0, p * 3, 255 - p * 3]
    } else {
        let p = p - 170;
        [p * 3, 255 - p * 3, 0]
    }
}

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| EnvFilter::new("led_controller=info")),
        )
        .init();

    let args = Args::parse();

    // Load persisted state if it exists; CLI args override saved values.
    let saved = PersistentState::load(&args.state_file);
    if saved.is_some() {
        tracing::info!(path = %args.state_file.display(), "loaded saved state");
    }
    let s = saved.as_ref();

    let num_pixels   = args.pixels      .or_else(|| s.map(|s| s.num_pixels  )).unwrap_or(60);
    let gpio_pin     = args.gpio_pin    .or_else(|| s.map(|s| s.gpio_pin    )).unwrap_or(18);
    let fade_in_ms   = args.fade_in_ms  .or_else(|| s.map(|s| s.fade_in_ms  )).unwrap_or(3000);
    let fade_out_ms  = args.fade_out_ms .or_else(|| s.map(|s| s.fade_out_ms )).unwrap_or(3000);
    let crossfade_ms = args.crossfade_ms.or_else(|| s.map(|s| s.crossfade_ms)).unwrap_or(3000);
    let effect_dur   = args.effect_duration_ms.or_else(|| s.map(|s| s.effect_duration_ms)).unwrap_or(0);
    let speed        = args.speed          .or_else(|| s.map(|s| s.speed       )).unwrap_or(1.0);
    let brightness   = args.brightness_scale.or_else(|| s.map(|s| s.brightness )).unwrap_or(1.0);
    let gamma        = args.gamma          .or_else(|| s.map(|s| s.gamma        )).unwrap_or(2.2);
    let color_order_str = args.color_order
        .clone()
        .or_else(|| s.map(|s| s.color_order.clone()))
        .unwrap_or_else(|| "rgb".to_string());
    let color_order = ColorOrder::parse(&color_order_str)?;

    let initial_playlist       = s.map(|s| s.playlist.clone());
    let initial_playlist_index = s.map(|s| s.playlist_index).unwrap_or(0);
    let should_start           = s.map(|s| s.is_running).unwrap_or(true);
    let palette_cycle_ms_val   = s.map(|s| s.palette_cycle_ms).unwrap_or(5000);
    let palette_cycle_ms: Arc<AtomicU64> = Arc::new(AtomicU64::new(palette_cycle_ms_val));

    // 5 evenly-spaced hues starting from a random offset on the color wheel.
    let palette_offset = rand::random::<u8>();
    let initial_palette: Vec<[u8; 3]> = (0u8..5)
        .map(|i| colorwheel(palette_offset.wrapping_add(i.wrapping_mul(51))))
        .collect();
    let palette: Arc<RwLock<Vec<[u8; 3]>>> = Arc::new(RwLock::new(initial_palette));

    // -----------------------------------------------------------------------
    // Pixel factory — called at startup and when GPIO pin / pixel count changes
    // -----------------------------------------------------------------------

    #[cfg(feature = "hardware")]
    let pixel_factory: PixelFactory = Arc::new(|pin: i32, count: usize, brightness: u8| {
        match pixels::hardware::NeoPixelStrip::new(pin, count, brightness) {
            Ok(strip) => {
                tracing::info!(pin, count, brightness, "hardware LED strip initialized");
                Box::new(strip) as Box<dyn pixels::PixelStrip>
            }
            Err(e) => {
                tracing::error!("hardware init failed: {e} — falling back to NullPixels");
                Box::new(pixels::NullPixels::new(count))
            }
        }
    });

    #[cfg(not(feature = "hardware"))]
    let pixel_factory: PixelFactory = Arc::new(|_pin: i32, count: usize, _brightness: u8| {
        tracing::info!(count, "NullPixels (dev mode)");
        Box::new(pixels::NullPixels::new(count)) as Box<dyn pixels::PixelStrip>
    });

    // -----------------------------------------------------------------------
    // Registry factory — called when pixel count changes
    // -----------------------------------------------------------------------

    let audio_analysis: Arc<AudioAnalysis> = Arc::new(AudioAnalysis::new());
    let audio_gain_val = s.map(|s| s.audio_gain).unwrap_or(1.0);
    audio_analysis.gain.store(audio_gain_val.to_bits(), Ordering::Relaxed);
    let band_gains = s.map(|s| s.audio_band_gains.clone()).unwrap_or_else(|| vec![1.0; 16]);
    for (i, &g) in band_gains.iter().enumerate().take(16) {
        audio_analysis.band_gains[i].store(g.to_bits(), Ordering::Relaxed);
    }
    let initial_audio_devices = audio::list_input_devices();

    let effects_dir = args.effects_dir.clone();
    let palette_for_factory       = Arc::clone(&palette);
    let audio_for_factory         = Arc::clone(&audio_analysis);
    let cycle_ms_for_factory      = Arc::clone(&palette_cycle_ms);
    let registry_factory: RegistryFactory = Arc::new(move |n: usize| {
        let mut r = default_registry(n);
        effects::load_lua_effects(
            &effects_dir, n, &mut r,
            Arc::clone(&palette_for_factory),
            Arc::clone(&cycle_ms_for_factory),
            Arc::clone(&audio_for_factory),
        );
        r
    });

    // -----------------------------------------------------------------------
    // Initial pixel strip and registry
    // -----------------------------------------------------------------------

    let pixels = pixel_factory(gpio_pin, num_pixels, args.brightness);
    let mut registry = default_registry(num_pixels);
    effects::load_lua_effects(
        &args.effects_dir, num_pixels, &mut registry,
        Arc::clone(&palette),
        Arc::clone(&palette_cycle_ms),
        Arc::clone(&audio_analysis),
    );

    let config = RunnerConfig {
        fade_in_ms, fade_out_ms, crossfade_ms,
        effect_duration_ms: effect_dur,
        speed, brightness, gamma, color_order,
        gpio_pin,
        hw_brightness: args.brightness,
        initial_playlist,
        initial_playlist_index,
        state_file: Some(args.state_file),
        palette_cycle_ms,
        palette,
        audio_analysis,
        initial_audio_devices,
    };

    let runner = Runner::new(pixels, registry, config, pixel_factory, registry_factory);
    if should_start {
        runner.send(runner::Command::Start);
    }

    let runner_for_shutdown = runner.clone();
    let state = AppState { runner };

    let app = Router::new()
        .route("/", get(api::index))
        .route("/static/app.js", get(api::app_js))
        .route("/manifest.json", get(api::manifest))
        .route("/static/icon.svg", get(api::icon_svg))
        .route("/static/icon-maskable.svg", get(api::icon_maskable_svg))
        .route("/sw.js", get(api::sw_js))
        .route("/ws", get(api::ws_handler))
        .route("/api/state", get(api::get_state))
        .route("/api/command", post(api::post_command))
        .with_state(state);

    let addr = format!("0.0.0.0:{}", args.port);
    let listener = tokio::net::TcpListener::bind(&addr).await?;
    tracing::info!("listening on http://{}", addr);
    axum::serve(listener, app)
        .with_graceful_shutdown(shutdown_signal())
        .await?;

    tracing::info!("shutting down — fading strip to black");
    runner_for_shutdown.shutdown();

    Ok(())
}

async fn shutdown_signal() {
    let ctrl_c = async {
        tokio::signal::ctrl_c()
            .await
            .expect("failed to install Ctrl+C handler");
    };

    #[cfg(unix)]
    let sigterm = async {
        tokio::signal::unix::signal(tokio::signal::unix::SignalKind::terminate())
            .expect("failed to install SIGTERM handler")
            .recv()
            .await;
    };

    #[cfg(not(unix))]
    let sigterm = std::future::pending::<()>();

    tokio::select! {
        _ = ctrl_c => {},
        _ = sigterm => {},
    }
}

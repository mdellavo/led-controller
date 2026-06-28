mod pixels;
mod effects;
mod runner;
mod api;

use std::sync::Arc;

use axum::{routing::{get, post}, Router};
use clap::Parser;
use tracing_subscriber::EnvFilter;

use api::AppState;
use effects::default_registry;
use pixels::ColorOrder;
use runner::{Runner, RunnerConfig, PixelFactory, RegistryFactory};

#[derive(Parser)]
#[command(about = "WS2812B LED strip controller with web interface")]
struct Args {
    /// Number of LEDs in the strip
    #[arg(long, default_value_t = 60)]
    pixels: usize,

    /// GPIO pin number (hardware feature only)
    #[arg(long, default_value_t = 18)]
    gpio_pin: i32,

    /// LED brightness 0–255 (hardware feature only)
    #[arg(long, default_value_t = 25)]
    brightness: u8,

    /// Port to listen on
    #[arg(long, default_value_t = 3000)]
    port: u16,

    /// Fade-in duration in milliseconds
    #[arg(long, default_value_t = 3000)]
    fade_in_ms: u64,

    /// Fade-out duration in milliseconds
    #[arg(long, default_value_t = 3000)]
    fade_out_ms: u64,

    /// Crossfade duration in milliseconds
    #[arg(long, default_value_t = 3000)]
    crossfade_ms: u64,

    /// How long each effect plays before auto-advancing to the next (0 = infinite)
    #[arg(long, default_value_t = 0)]
    effect_duration_ms: u64,

    /// Physical color channel order of the LED strip (e.g. rgb, grb, bgr)
    #[arg(long, default_value = "rgb")]
    color_order: String,

    /// Effect speed multiplier (0.1 = very slow, 1.0 = normal, 4.0 = very fast)
    #[arg(long, default_value_t = 1.0)]
    speed: f32,

    /// Software brightness scale 0.0–1.0 applied to all pixel output
    #[arg(long, default_value_t = 1.0)]
    brightness_scale: f32,

    /// Gamma correction exponent (2.2 = standard display, higher = darker mid-tones)
    #[arg(long, default_value_t = 2.2)]
    gamma: f32,
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
    let color_order = ColorOrder::parse(&args.color_order)?;

    // -----------------------------------------------------------------------
    // Pixel factory — called at startup and when GPIO pin / pixel count changes
    // -----------------------------------------------------------------------

    #[cfg(feature = "hardware")]
    let pixel_factory: PixelFactory = {
        Arc::new(|pin: i32, count: usize, brightness: u8| {
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
        })
    };

    #[cfg(not(feature = "hardware"))]
    let pixel_factory: PixelFactory = Arc::new(|_pin: i32, count: usize, _brightness: u8| {
        tracing::info!(count, "NullPixels (dev mode)");
        Box::new(pixels::NullPixels::new(count)) as Box<dyn pixels::PixelStrip>
    });

    // -----------------------------------------------------------------------
    // Registry factory — called when pixel count changes
    // -----------------------------------------------------------------------

    let registry_factory: RegistryFactory = Arc::new(|num_pixels: usize| {
        default_registry(num_pixels)
    });

    // -----------------------------------------------------------------------
    // Initial pixel strip and registry
    // -----------------------------------------------------------------------

    let pixels = pixel_factory(args.gpio_pin, args.pixels, args.brightness);
    let registry = default_registry(args.pixels);

    let config = RunnerConfig {
        fade_in_ms: args.fade_in_ms,
        fade_out_ms: args.fade_out_ms,
        crossfade_ms: args.crossfade_ms,
        effect_duration_ms: args.effect_duration_ms,
        speed: args.speed,
        brightness: args.brightness_scale,
        gamma: args.gamma,
        gpio_pin: args.gpio_pin,
        hw_brightness: args.brightness,
        color_order,
    };

    let runner = Runner::new(pixels, registry, config, pixel_factory, registry_factory);
    runner.send(runner::Command::Start);

    let state = AppState { runner };

    let app = Router::new()
        .route("/", get(api::index))
        .route("/static/app.js", get(api::app_js))
        .route("/api/state", get(api::get_state))
        .route("/api/command", post(api::post_command))
        .with_state(state);

    let addr = format!("0.0.0.0:{}", args.port);
    let listener = tokio::net::TcpListener::bind(&addr).await?;
    tracing::info!("listening on http://{}", addr);
    axum::serve(listener, app).await?;

    Ok(())
}

mod pixels;
mod effects;
mod runner;
mod api;

use axum::{routing::{get, post}, Router};
use tracing_subscriber::EnvFilter;

use api::AppState;
use effects::default_registry;
use pixels::NullPixels;
use runner::Runner;

const NUM_PIXELS: usize = 60;

#[tokio::main]
async fn main() -> anyhow::Result<()> {
    tracing_subscriber::fmt()
        .with_env_filter(
            EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| EnvFilter::new("led_controller=info")),
        )
        .init();

    let pixels: Box<dyn pixels::PixelStrip> = {
        #[cfg(feature = "hardware")]
        {
            tracing::info!("initializing hardware LED strip on GPIO18, {} pixels", NUM_PIXELS);
            Box::new(pixels::hardware::NeoPixelStrip::new(18, NUM_PIXELS, 25)?)
        }
        #[cfg(not(feature = "hardware"))]
        {
            tracing::info!("no hardware feature — using NullPixels (dev mode)");
            Box::new(NullPixels::new(NUM_PIXELS))
        }
    };

    let registry = default_registry(NUM_PIXELS);
    let runner = Runner::new(pixels, registry);

    // auto-start the first effect
    runner.send(runner::Command::Start);

    let state = AppState { runner };

    let app = Router::new()
        .route("/", get(api::index))
        .route("/static/app.js", get(api::app_js))
        .route("/api/state", get(api::get_state))
        .route("/api/command", post(api::post_command))
        .with_state(state);

    let listener = tokio::net::TcpListener::bind("0.0.0.0:3000").await?;
    tracing::info!("listening on http://0.0.0.0:3000");
    axum::serve(listener, app).await?;

    Ok(())
}

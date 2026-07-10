use axum::{
    extract::{
        ws::{Message, WebSocket, WebSocketUpgrade},
        State,
    },
    http::{header, StatusCode},
    response::{Html, IntoResponse, Response},
    Json,
};
use serde::{Deserialize, Serialize};

use crate::runner::{Command, Runner};

// --------------------------------------------------------------------------
// App state (shared across all handlers via Axum's State extractor)
// --------------------------------------------------------------------------

#[derive(Clone)]
pub struct AppState {
    pub runner: Runner,
}

// --------------------------------------------------------------------------
// Route: GET /
// --------------------------------------------------------------------------

pub async fn index() -> impl IntoResponse {
    Html(include_str!("../static/index.html"))
}

// --------------------------------------------------------------------------
// Route: GET /static/app.js
// --------------------------------------------------------------------------

pub async fn app_js() -> Response {
    (
        [(header::CONTENT_TYPE, "application/javascript")],
        include_str!("../static/app.js"),
    )
        .into_response()
}

// --------------------------------------------------------------------------
// Route: GET /ws  — WebSocket push of SharedState on every change
// --------------------------------------------------------------------------

pub async fn ws_handler(
    ws: WebSocketUpgrade,
    State(app): State<AppState>,
) -> impl IntoResponse {
    ws.on_upgrade(move |socket| handle_ws(socket, app))
}

async fn handle_ws(mut socket: WebSocket, app: AppState) {
    // Serialize before any await so the MutexGuard is dropped first.
    let initial = {
        let state = app.runner.state.lock().unwrap();
        serde_json::to_string(&*state).unwrap_or_default()
    };
    if socket.send(Message::Text(initial)).await.is_err() {
        return;
    }

    let mut rx = app.runner.subscribe();
    loop {
        tokio::select! {
            msg = socket.recv() => {
                match msg {
                    Some(Ok(Message::Close(_))) | None => break,
                    _ => {} // ignore pings / other client frames
                }
            }
            result = rx.recv() => {
                match result {
                    Ok(state) => {
                        let json = serde_json::to_string(&state).unwrap_or_default();
                        if socket.send(Message::Text(json)).await.is_err() {
                            break;
                        }
                    }
                    Err(tokio::sync::broadcast::error::RecvError::Lagged(_)) => continue,
                    Err(_) => break,
                }
            }
        }
    }
}

// --------------------------------------------------------------------------
// Route: GET /api/state
// --------------------------------------------------------------------------

pub async fn get_state(State(app): State<AppState>) -> impl IntoResponse {
    let state = app.runner.state.lock().unwrap().clone();
    Json(state)
}

// --------------------------------------------------------------------------
// Route: POST /api/command
// --------------------------------------------------------------------------

#[derive(Deserialize)]
pub struct PaletteColor {
    pub r: u8,
    pub g: u8,
    pub b: u8,
}

#[derive(Deserialize)]
pub struct CommandRequest {
    pub action: String,
    pub effect: Option<String>,
    pub value_ms: Option<u64>,
    pub value: Option<f32>,
    pub index: Option<usize>,
    pub to_index: Option<usize>,
    pub palette: Option<Vec<PaletteColor>>,
}

#[derive(Serialize)]
pub struct CommandResponse {
    pub ok: bool,
    pub error: Option<String>,
}

pub async fn post_command(
    State(app): State<AppState>,
    Json(req): Json<CommandRequest>,
) -> impl IntoResponse {
    let cmd = match req.action.as_str() {
        "start" => Some(Command::Start),
        "stop" => Some(Command::Stop),
        "next" => Some(Command::Next),
        "randomize" => Some(Command::Randomize),
        "select" => req
            .effect
            .map(Command::Select),
        "set_fade_in" => req.value_ms.map(Command::SetFadeInMs),
        "set_fade_out" => req.value_ms.map(Command::SetFadeOutMs),
        "set_crossfade" => req.value_ms.map(Command::SetCrossfadeMs),
        "set_effect_duration" => req.value_ms.map(Command::SetEffectDurationMs),
        "add_to_playlist" => req.effect.map(Command::AddToPlaylist),
        "add_all_to_playlist" => Some(Command::AddAllToPlaylist),
        "clear_playlist" => Some(Command::ClearPlaylist),
        "remove_from_playlist" => req.index.map(Command::RemoveFromPlaylist),
        "move_in_playlist" => match (req.index, req.to_index) {
            (Some(from), Some(to)) => Some(Command::MoveInPlaylist(from, to)),
            _ => None,
        },
        "set_speed"       => req.value.map(Command::SetSpeed),
        "set_brightness"  => req.value.map(Command::SetBrightness),
        "set_gamma"       => req.value.map(Command::SetGamma),
        "set_color_order" => req.effect.clone().map(Command::SetColorOrder),
        "set_num_pixels"  => req.value_ms.map(|n| Command::SetNumPixels(n as usize)),
        "set_gpio_pin"    => req.value_ms.map(|p| Command::SetGpioPin(p as i32)),
        "set_palette" => req.palette.map(|colors| {
            Command::SetPalette(colors.into_iter().map(|c| [c.r, c.g, c.b]).collect())
        }),
        "set_palette_cycle_ms" => req.value_ms.map(Command::SetPaletteCycleMs),
        "set_audio_device"   => Some(Command::SetAudioDevice(req.effect)),
        "refresh_audio_devices" => Some(Command::RefreshAudioDevices),
        "set_audio_gain"    => req.value.map(Command::SetAudioGain),
        _ => None,
    };

    match cmd {
        Some(cmd) => {
            app.runner.send(cmd);
            (StatusCode::OK, Json(CommandResponse { ok: true, error: None }))
        }
        None => (
            StatusCode::BAD_REQUEST,
            Json(CommandResponse {
                ok: false,
                error: Some(format!("unknown action: {}", req.action)),
            }),
        ),
    }
}

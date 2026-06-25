use axum::{
    extract::State,
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
pub struct CommandRequest {
    pub action: String,
    pub effect: Option<String>,
    pub value_ms: Option<u64>,
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

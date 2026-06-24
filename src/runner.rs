use std::sync::{
    atomic::{AtomicBool, Ordering},
    Arc, Mutex,
};
use std::thread::{self, JoinHandle};
use std::time::{Duration, Instant};

use rand::seq::SliceRandom;

use crate::effects::{Effect, Buffer, EffectRegistry};
use crate::pixels::{Color, PixelStrip};

const FRAME_RATE: u64 = 60;
const FRAME_DURATION: Duration = Duration::from_millis(1000 / FRAME_RATE);
pub const DEFAULT_FADE_DURATION: Duration = Duration::from_secs(3);

// --------------------------------------------------------------------------
// EffectHandle — owns a spawned effect thread and its shared pixel buffer
// --------------------------------------------------------------------------

pub struct EffectHandle {
    pub name: String,
    buffer: Arc<Mutex<Buffer>>,
    stop_flag: Arc<AtomicBool>,
    thread: Option<JoinHandle<()>>,
}

impl EffectHandle {
    pub fn spawn(effect: Box<dyn Effect>, num_pixels: usize) -> Self {
        let name = effect.name().to_string();
        let buffer = Arc::new(Mutex::new(vec![[0u8; 3]; num_pixels]));
        let stop_flag = Arc::new(AtomicBool::new(false));

        let buf_clone = Arc::clone(&buffer);
        let stop_clone = Arc::clone(&stop_flag);

        let thread = thread::spawn(move || {
            let mut effect = effect;
            let mut last = Instant::now();
            loop {
                if stop_clone.load(Ordering::Relaxed) {
                    break;
                }
                let now = Instant::now();
                let delta = now.duration_since(last);
                last = now;

                {
                    if let Ok(mut buf) = buf_clone.lock() {
                        if !effect.update(&mut buf, delta) {
                            break;
                        }
                    }
                }

                let elapsed = Instant::now().duration_since(now);
                if elapsed < FRAME_DURATION {
                    thread::sleep(FRAME_DURATION - elapsed);
                }
            }
        });

        Self {
            name,
            buffer,
            stop_flag,
            thread: Some(thread),
        }
    }

    pub fn read_buffer(&self) -> Vec<Color> {
        self.buffer.lock().map(|b| b.clone()).unwrap_or_default()
    }

    fn stop(&self) {
        self.stop_flag.store(true, Ordering::Relaxed);
    }

    fn join(&mut self) {
        self.stop();
        if let Some(t) = self.thread.take() {
            let _ = t.join();
        }
    }
}

impl Drop for EffectHandle {
    fn drop(&mut self) {
        self.join();
    }
}

// --------------------------------------------------------------------------
// Runner state machine
// --------------------------------------------------------------------------

enum RunnerState {
    Idle,
    FadingIn {
        handle: EffectHandle,
        alpha: f32,
        duration: f32,
    },
    Running {
        handle: EffectHandle,
    },
    CrossFading {
        from: EffectHandle,
        to: EffectHandle,
        alpha: f32,
        duration: f32,
    },
    FadingOut {
        handle: EffectHandle,
        alpha: f32,
        duration: f32,
    },
}

impl RunnerState {
    fn current_name(&self) -> Option<&str> {
        match self {
            Self::Idle => None,
            Self::FadingIn { handle, .. } => Some(&handle.name),
            Self::Running { handle } => Some(&handle.name),
            Self::CrossFading { to, .. } => Some(&to.name),
            Self::FadingOut { handle, .. } => Some(&handle.name),
        }
    }

    fn is_active(&self) -> bool {
        !matches!(self, Self::Idle)
    }
}

// --------------------------------------------------------------------------
// Commands and shared state
// --------------------------------------------------------------------------

pub enum Command {
    Start,
    Stop,
    Next,
    Select(String),
    Randomize,
    SetFadeInMs(u64),
    SetFadeOutMs(u64),
    SetCrossfadeMs(u64),
}

#[derive(Clone, serde::Serialize)]
pub struct SharedState {
    pub is_running: bool,
    pub current_effect: Option<String>,
    pub transition: Option<String>,
    pub playlist: Vec<String>,
    pub playlist_index: usize,
    pub effects: Vec<String>,
    pub fade_in_ms: u64,
    pub fade_out_ms: u64,
    pub crossfade_ms: u64,
}

// --------------------------------------------------------------------------
// Runner — public handle, lives in the Axum app state
// --------------------------------------------------------------------------

#[derive(Clone)]
pub struct Runner {
    pub tx: std::sync::mpsc::SyncSender<Command>,
    pub state: Arc<Mutex<SharedState>>,
}

impl Runner {
    pub fn new(pixels: Box<dyn PixelStrip>, registry: EffectRegistry) -> Self {
        let num_pixels = pixels.len();
        let (tx, rx) = std::sync::mpsc::sync_channel(32);

        let initial_playlist = registry.names().to_vec();
        let effects_list = registry.names().to_vec();
        let shared_state = Arc::new(Mutex::new(SharedState {
            is_running: false,
            current_effect: None,
            transition: None,
            playlist: initial_playlist,
            playlist_index: 0,
            effects: effects_list,
            fade_in_ms: DEFAULT_FADE_DURATION.as_millis() as u64,
            fade_out_ms: DEFAULT_FADE_DURATION.as_millis() as u64,
            crossfade_ms: DEFAULT_FADE_DURATION.as_millis() as u64,
        }));

        let state_clone = Arc::clone(&shared_state);

        thread::spawn(move || {
            run_loop(pixels, registry, rx, num_pixels, state_clone);
        });

        Self {
            tx,
            state: shared_state,
        }
    }

    pub fn send(&self, cmd: Command) {
        let _ = self.tx.try_send(cmd);
    }
}

// --------------------------------------------------------------------------
// Blend helpers
// --------------------------------------------------------------------------

fn blend_buffers(a: &[Color], b: &[Color], t: f32) -> Vec<Color> {
    a.iter()
        .zip(b.iter())
        .map(|(ca, cb)| {
            [
                (ca[0] as f32 * (1.0 - t) + cb[0] as f32 * t) as u8,
                (ca[1] as f32 * (1.0 - t) + cb[1] as f32 * t) as u8,
                (ca[2] as f32 * (1.0 - t) + cb[2] as f32 * t) as u8,
            ]
        })
        .collect()
}

fn scale_buffer(buf: &[Color], alpha: f32) -> Vec<Color> {
    buf.iter()
        .map(|c| c.map(|v| (v as f32 * alpha) as u8))
        .collect()
}

// --------------------------------------------------------------------------
// Main runner loop (runs in its own thread)
// --------------------------------------------------------------------------

fn run_loop(
    mut pixels: Box<dyn PixelStrip>,
    registry: EffectRegistry,
    rx: std::sync::mpsc::Receiver<Command>,
    num_pixels: usize,
    shared: Arc<Mutex<SharedState>>,
) {
    let black = vec![[0u8; 3]; num_pixels];
    let mut state = RunnerState::Idle;
    let mut playlist: Vec<String> = registry.names().to_vec();
    let mut playlist_index: usize = 0;
    let mut fade_in_dur = DEFAULT_FADE_DURATION.as_secs_f32();
    let mut fade_out_dur = DEFAULT_FADE_DURATION.as_secs_f32();
    let mut crossfade_dur = DEFAULT_FADE_DURATION.as_secs_f32();

    let spawn_effect = |playlist: &[String], index: usize, registry: &EffectRegistry| -> Option<EffectHandle> {
        let name = playlist.get(index)?.clone();
        let effect = registry.create(&name)?;
        Some(EffectHandle::spawn(effect, num_pixels))
    };

    loop {
        // --- process incoming commands ---
        while let Ok(cmd) = rx.try_recv() {
            match cmd {
                Command::SetFadeInMs(ms) => {
                    fade_in_dur = ms as f32 / 1000.0;
                    if let Ok(mut s) = shared.lock() { s.fade_in_ms = ms; }
                }
                Command::SetFadeOutMs(ms) => {
                    fade_out_dur = ms as f32 / 1000.0;
                    if let Ok(mut s) = shared.lock() { s.fade_out_ms = ms; }
                }
                Command::SetCrossfadeMs(ms) => {
                    crossfade_dur = ms as f32 / 1000.0;
                    if let Ok(mut s) = shared.lock() { s.crossfade_ms = ms; }
                }
                Command::Randomize => {
                    let mut rng = rand::thread_rng();
                    playlist.shuffle(&mut rng);
                    playlist_index = 0;
                    if let Ok(mut s) = shared.lock() {
                        s.playlist = playlist.clone();
                        s.playlist_index = 0;
                    }
                }

                Command::Stop => {
                    state = match std::mem::replace(&mut state, RunnerState::Idle) {
                        RunnerState::Idle => RunnerState::Idle,
                        RunnerState::FadingIn { handle, alpha, .. } => RunnerState::FadingOut {
                            handle,
                            alpha,
                            duration: fade_out_dur,
                        },
                        RunnerState::Running { handle } => RunnerState::FadingOut {
                            handle,
                            alpha: 1.0,
                            duration: fade_out_dur,
                        },
                        RunnerState::CrossFading { to, alpha, .. } => RunnerState::FadingOut {
                            // from is dropped here, stopping that thread
                            handle: to,
                            alpha,
                            duration: fade_out_dur,
                        },
                        RunnerState::FadingOut { handle, alpha, duration } => {
                            RunnerState::FadingOut { handle, alpha, duration }
                        }
                    };
                }

                Command::Start => {
                    if let Some(new_handle) = spawn_effect(&playlist, playlist_index, &registry) {
                        state = start_effect(
                            std::mem::replace(&mut state, RunnerState::Idle),
                            new_handle,
                            fade_in_dur,
                            crossfade_dur,
                        );
                    }
                }

                Command::Next => {
                    if !playlist.is_empty() {
                        playlist_index = (playlist_index + 1) % playlist.len();
                        if let Ok(mut s) = shared.lock() {
                            s.playlist_index = playlist_index;
                        }
                    }
                    if let Some(new_handle) = spawn_effect(&playlist, playlist_index, &registry) {
                        state = start_effect(
                            std::mem::replace(&mut state, RunnerState::Idle),
                            new_handle,
                            fade_in_dur,
                            crossfade_dur,
                        );
                    }
                }

                Command::Select(name) => {
                    if let Some(idx) = playlist.iter().position(|n| n == &name) {
                        playlist_index = idx;
                        if let Ok(mut s) = shared.lock() {
                            s.playlist_index = idx;
                        }
                    }
                    if let Some(effect) = registry.create(&name) {
                        let new_handle = EffectHandle::spawn(effect, num_pixels);
                        state = start_effect(
                            std::mem::replace(&mut state, RunnerState::Idle),
                            new_handle,
                            fade_in_dur,
                            crossfade_dur,
                        );
                    }
                }
            }
        }

        // --- advance state by one frame and compute output ---
        let dt = FRAME_DURATION.as_secs_f32();

        let (output, next_state) = match std::mem::replace(&mut state, RunnerState::Idle) {
            RunnerState::Idle => (black.clone(), RunnerState::Idle),

            RunnerState::FadingIn { handle, alpha, duration } => {
                let new_alpha = (alpha + dt / duration).min(1.0);
                let buf = handle.read_buffer();
                let output = scale_buffer(&buf, new_alpha);
                let next = if new_alpha >= 1.0 {
                    RunnerState::Running { handle }
                } else {
                    RunnerState::FadingIn { handle, alpha: new_alpha, duration }
                };
                (output, next)
            }

            RunnerState::Running { handle } => {
                let buf = handle.read_buffer();
                (buf, RunnerState::Running { handle })
            }

            RunnerState::CrossFading { from, to, alpha, duration } => {
                let new_alpha = (alpha + dt / duration).min(1.0);
                let from_buf = from.read_buffer();
                let to_buf = to.read_buffer();
                let output = blend_buffers(&from_buf, &to_buf, new_alpha);
                let next = if new_alpha >= 1.0 {
                    // from is dropped here, joining its thread
                    RunnerState::Running { handle: to }
                } else {
                    RunnerState::CrossFading { from, to, alpha: new_alpha, duration }
                };
                (output, next)
            }

            RunnerState::FadingOut { handle, alpha, duration } => {
                let new_alpha = (alpha - dt / duration).max(0.0);
                let buf = handle.read_buffer();
                let output = scale_buffer(&buf, new_alpha);
                let next = if new_alpha <= 0.0 {
                    // handle dropped here, joining its thread
                    RunnerState::Idle
                } else {
                    RunnerState::FadingOut { handle, alpha: new_alpha, duration }
                };
                (output, next)
            }
        };

        state = next_state;

        // --- write to hardware ---
        for (i, color) in output.iter().enumerate() {
            pixels.set(i, *color);
        }
        pixels.show();

        // --- update shared state for API reads ---
        if let Ok(mut s) = shared.lock() {
            s.is_running = state.is_active();
            s.current_effect = state.current_name().map(|n| n.to_string());
            s.transition = match &state {
                RunnerState::FadingIn { .. } => Some("fading_in".into()),
                RunnerState::FadingOut { .. } => Some("fading_out".into()),
                RunnerState::CrossFading { .. } => Some("crossfading".into()),
                _ => None,
            };
        }

        thread::sleep(FRAME_DURATION);
    }
}

// Transition the old state to a new effect, choosing fade-in or crossfade.
fn start_effect(
    old_state: RunnerState,
    new_handle: EffectHandle,
    fade_in_dur: f32,
    crossfade_dur: f32,
) -> RunnerState {
    match old_state {
        RunnerState::Idle | RunnerState::FadingOut { .. } => RunnerState::FadingIn {
            handle: new_handle,
            alpha: 0.0,
            duration: fade_in_dur,
        },
        RunnerState::FadingIn { handle, alpha, .. } => RunnerState::CrossFading {
            from: handle,
            to: new_handle,
            alpha,
            duration: crossfade_dur,
        },
        RunnerState::Running { handle } => RunnerState::CrossFading {
            from: handle,
            to: new_handle,
            alpha: 0.0,
            duration: crossfade_dur,
        },
        RunnerState::CrossFading { to, alpha, .. } => {
            // from is dropped here
            RunnerState::CrossFading {
                from: to,
                to: new_handle,
                alpha: 1.0 - alpha, // flip so we fade from current blend position
                duration: crossfade_dur,
            }
        }
    }
}

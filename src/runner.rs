use std::sync::{
    atomic::{AtomicBool, AtomicU32, Ordering},
    Arc, Mutex,
};
use std::thread::{self, JoinHandle};
use std::time::{Duration, Instant};

use rand::seq::SliceRandom;

use crate::effects::{Effect, Buffer, EffectRegistry};
use crate::pixels::{Color, ColorOrder, PixelStrip, build_gamma_lut};

const FRAME_RATE: u64 = 60;
const FRAME_DURATION: Duration = Duration::from_millis(1000 / FRAME_RATE);
pub const DEFAULT_FADE_DURATION: Duration = Duration::from_secs(3);

/// Factory that creates a fresh pixel strip for the given (gpio_pin, count, hw_brightness).
/// Color order is applied by the runner, not by the strip implementation.
pub type PixelFactory = Arc<dyn Fn(i32, usize, u8) -> Box<dyn PixelStrip> + Send + Sync>;

/// Factory that creates a new effect registry sized for the given pixel count.
pub type RegistryFactory = Arc<dyn Fn(usize) -> EffectRegistry + Send + Sync>;

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
    pub fn spawn(effect: Box<dyn Effect>, num_pixels: usize, speed: Arc<AtomicU32>) -> Self {
        let name = effect.name().to_string();
        let buffer = Arc::new(Mutex::new(vec![[0u8; 3]; num_pixels]));
        let stop_flag = Arc::new(AtomicBool::new(false));

        let buf_clone = Arc::clone(&buffer);
        let stop_clone = Arc::clone(&stop_flag);

        let thread = thread::spawn(move || {
            let mut effect = effect;
            let mut last = Instant::now();
            loop {
                if stop_clone.load(Ordering::Relaxed) { break; }
                let now = Instant::now();
                let real_delta = now.duration_since(last);
                last = now;

                let spd = f32::from_bits(speed.load(Ordering::Relaxed));
                let delta = Duration::from_secs_f32((real_delta.as_secs_f32() * spd).max(0.0));

                if let Ok(mut buf) = buf_clone.lock() {
                    if !effect.update(&mut buf, delta) { break; }
                }

                let elapsed = Instant::now().duration_since(now);
                if elapsed < FRAME_DURATION {
                    thread::sleep(FRAME_DURATION - elapsed);
                }
            }
        });

        Self { name, buffer, stop_flag, thread: Some(thread) }
    }

    pub fn read_buffer(&self) -> Vec<Color> {
        self.buffer.lock().map(|b| b.clone()).unwrap_or_default()
    }

    fn stop(&self) { self.stop_flag.store(true, Ordering::Relaxed); }

    fn join(&mut self) {
        self.stop();
        if let Some(t) = self.thread.take() { let _ = t.join(); }
    }
}

impl Drop for EffectHandle {
    fn drop(&mut self) { self.join(); }
}

// --------------------------------------------------------------------------
// Runner state machine
// --------------------------------------------------------------------------

enum RunnerState {
    Idle,
    FadingIn  { handle: EffectHandle, alpha: f32, duration: f32 },
    Running   { handle: EffectHandle },
    CrossFading { from: EffectHandle, to: EffectHandle, alpha: f32, duration: f32 },
    FadingOut { handle: EffectHandle, alpha: f32, duration: f32 },
}

impl RunnerState {
    fn current_name(&self) -> Option<&str> {
        match self {
            Self::Idle => None,
            Self::FadingIn   { handle, .. } => Some(&handle.name),
            Self::Running    { handle }     => Some(&handle.name),
            Self::CrossFading { to, .. }   => Some(&to.name),
            Self::FadingOut  { handle, .. } => Some(&handle.name),
        }
    }
    fn is_active(&self) -> bool { !matches!(self, Self::Idle) }
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
    SetEffectDurationMs(u64),
    AddToPlaylist(String),
    RemoveFromPlaylist(usize),
    MoveInPlaylist(usize, usize),
    SetSpeed(f32),
    SetBrightness(f32),
    SetGamma(f32),
    SetColorOrder(String),
    SetNumPixels(usize),
    SetGpioPin(i32),
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
    pub effect_duration_ms: u64,
    pub speed: f32,
    pub brightness: f32,
    pub gamma: f32,
    pub num_pixels: usize,
    pub gpio_pin: i32,
    pub color_order: String,
}

// --------------------------------------------------------------------------
// Runner — public handle, lives in the Axum app state
// --------------------------------------------------------------------------

pub struct RunnerConfig {
    pub fade_in_ms: u64,
    pub fade_out_ms: u64,
    pub crossfade_ms: u64,
    pub effect_duration_ms: u64,
    pub speed: f32,
    pub brightness: f32,
    pub gamma: f32,
    pub gpio_pin: i32,
    pub hw_brightness: u8,
    pub color_order: ColorOrder,
}

impl Default for RunnerConfig {
    fn default() -> Self {
        let ms = DEFAULT_FADE_DURATION.as_millis() as u64;
        Self {
            fade_in_ms: ms, fade_out_ms: ms, crossfade_ms: ms,
            effect_duration_ms: 0, speed: 1.0, brightness: 1.0, gamma: 2.2,
            gpio_pin: 18, hw_brightness: 25, color_order: ColorOrder::default(),
        }
    }
}

#[derive(Clone)]
pub struct Runner {
    pub tx: std::sync::mpsc::SyncSender<Command>,
    pub state: Arc<Mutex<SharedState>>,
}

impl Runner {
    pub fn new(
        pixels: Box<dyn PixelStrip>,
        registry: EffectRegistry,
        config: RunnerConfig,
        pixel_factory: PixelFactory,
        registry_factory: RegistryFactory,
    ) -> Self {
        let num_pixels = pixels.len();
        let (tx, rx) = std::sync::mpsc::sync_channel(32);

        let speed      = Arc::new(AtomicU32::new(config.speed.to_bits()));
        let brightness = Arc::new(AtomicU32::new(config.brightness.to_bits()));

        let initial_playlist = registry.names().to_vec();
        let effects_list     = registry.names().to_vec();
        let color_order_str  = config.color_order.to_string();

        let shared_state = Arc::new(Mutex::new(SharedState {
            is_running: false,
            current_effect: None,
            transition: None,
            playlist: initial_playlist,
            playlist_index: 0,
            effects: effects_list,
            fade_in_ms: config.fade_in_ms,
            fade_out_ms: config.fade_out_ms,
            crossfade_ms: config.crossfade_ms,
            effect_duration_ms: config.effect_duration_ms,
            speed: config.speed,
            brightness: config.brightness,
            gamma: config.gamma,
            num_pixels,
            gpio_pin: config.gpio_pin,
            color_order: color_order_str,
        }));

        let state_clone = Arc::clone(&shared_state);
        thread::spawn(move || {
            run_loop(pixels, registry, rx, num_pixels, state_clone, config, speed, brightness, pixel_factory, registry_factory);
        });

        Self { tx, state: shared_state }
    }

    pub fn send(&self, cmd: Command) {
        let _ = self.tx.try_send(cmd);
    }
}

// --------------------------------------------------------------------------
// Blend helpers
// --------------------------------------------------------------------------

fn blend_buffers(a: &[Color], b: &[Color], t: f32) -> Vec<Color> {
    a.iter().zip(b.iter()).map(|(ca, cb)| [
        (ca[0] as f32 * (1.0 - t) + cb[0] as f32 * t) as u8,
        (ca[1] as f32 * (1.0 - t) + cb[1] as f32 * t) as u8,
        (ca[2] as f32 * (1.0 - t) + cb[2] as f32 * t) as u8,
    ]).collect()
}

fn scale_buffer(buf: &[Color], alpha: f32) -> Vec<Color> {
    buf.iter().map(|c| c.map(|v| (v as f32 * alpha) as u8)).collect()
}

// --------------------------------------------------------------------------
// Spawn helper (free function so num_pixels can be passed explicitly)
// --------------------------------------------------------------------------

fn do_spawn(
    playlist: &[String],
    index: usize,
    registry: &EffectRegistry,
    num_pixels: usize,
    speed: Arc<AtomicU32>,
) -> Option<EffectHandle> {
    let name = playlist.get(index)?.clone();
    let effect = registry.create(&name)?;
    Some(EffectHandle::spawn(effect, num_pixels, speed))
}

// --------------------------------------------------------------------------
// Main runner loop (runs in its own thread)
// --------------------------------------------------------------------------

fn run_loop(
    mut pixels: Box<dyn PixelStrip>,
    mut registry: EffectRegistry,
    rx: std::sync::mpsc::Receiver<Command>,
    mut num_pixels: usize,
    shared: Arc<Mutex<SharedState>>,
    config: RunnerConfig,
    speed: Arc<AtomicU32>,
    brightness: Arc<AtomicU32>,
    pixel_factory: PixelFactory,
    registry_factory: RegistryFactory,
) {
    let mut gamma_lut   = build_gamma_lut(config.gamma);
    let mut color_order = config.color_order;
    let mut gpio_pin    = config.gpio_pin;
    let hw_brightness   = config.hw_brightness;

    let mut black = vec![[0u8; 3]; num_pixels];
    let mut state = RunnerState::Idle;
    let mut playlist: Vec<String> = registry.names().to_vec();
    let mut playlist_index: usize = 0;
    let mut fade_in_dur   = config.fade_in_ms as f32 / 1000.0;
    let mut fade_out_dur  = config.fade_out_ms as f32 / 1000.0;
    let mut crossfade_dur = config.crossfade_ms as f32 / 1000.0;
    let mut effect_duration = config.effect_duration_ms as f32 / 1000.0;
    let mut effect_elapsed: f32 = 0.0;

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
                Command::SetEffectDurationMs(ms) => {
                    effect_duration = ms as f32 / 1000.0;
                    effect_elapsed = 0.0;
                    if let Ok(mut s) = shared.lock() { s.effect_duration_ms = ms; }
                }
                Command::SetSpeed(v) => {
                    let v = v.clamp(0.1, 10.0);
                    speed.store(v.to_bits(), Ordering::Relaxed);
                    if let Ok(mut s) = shared.lock() { s.speed = v; }
                }
                Command::SetBrightness(v) => {
                    let v = v.clamp(0.0, 1.0);
                    brightness.store(v.to_bits(), Ordering::Relaxed);
                    if let Ok(mut s) = shared.lock() { s.brightness = v; }
                }
                Command::SetGamma(v) => {
                    let v = v.clamp(1.0, 4.0);
                    gamma_lut = build_gamma_lut(v);
                    if let Ok(mut s) = shared.lock() { s.gamma = v; }
                }
                Command::SetColorOrder(s) => {
                    if let Ok(co) = ColorOrder::parse(&s) {
                        color_order = co;
                        if let Ok(mut st) = shared.lock() { st.color_order = co.to_string(); }
                    }
                }

                // Hardware reinit — stops current effect, rebuilds strip + registry, auto-restarts.
                Command::SetNumPixels(n) => {
                    let n = n.max(1);
                    state = RunnerState::Idle;
                    pixels = pixel_factory(gpio_pin, n, hw_brightness);
                    num_pixels = n;
                    black = vec![[0u8; 3]; n];
                    registry = registry_factory(n);
                    playlist.retain(|name| registry.contains(name));
                    playlist_index = 0;
                    tracing::info!(num_pixels = n, "pixel count changed, restarting");
                    if let Ok(mut st) = shared.lock() {
                        st.num_pixels = n;
                        st.effects = registry.names().to_vec();
                        st.playlist = playlist.clone();
                        st.playlist_index = 0;
                    }
                    if let Some(h) = do_spawn(&playlist, playlist_index, &registry, num_pixels, Arc::clone(&speed)) {
                        state = RunnerState::FadingIn { handle: h, alpha: 0.0, duration: fade_in_dur };
                    }
                }
                Command::SetGpioPin(pin) => {
                    gpio_pin = pin;
                    state = RunnerState::Idle;
                    pixels = pixel_factory(gpio_pin, num_pixels, hw_brightness);
                    tracing::info!(gpio_pin = pin, "GPIO pin changed, reinitializing hardware");
                    if let Ok(mut st) = shared.lock() { st.gpio_pin = pin; }
                    if let Some(h) = do_spawn(&playlist, playlist_index, &registry, num_pixels, Arc::clone(&speed)) {
                        state = RunnerState::FadingIn { handle: h, alpha: 0.0, duration: fade_in_dur };
                    }
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
                Command::AddToPlaylist(name) => {
                    if registry.contains(&name) {
                        playlist.push(name.clone());
                        if let Ok(mut s) = shared.lock() { s.playlist.push(name); }
                    }
                }
                Command::RemoveFromPlaylist(idx) => {
                    if idx < playlist.len() {
                        playlist.remove(idx);
                        playlist_index = if playlist.is_empty() {
                            0
                        } else if idx < playlist_index {
                            playlist_index - 1
                        } else {
                            playlist_index.min(playlist.len() - 1)
                        };
                        if let Ok(mut s) = shared.lock() {
                            s.playlist = playlist.clone();
                            s.playlist_index = playlist_index;
                        }
                    }
                }
                Command::MoveInPlaylist(from, to) => {
                    if from < playlist.len() && to < playlist.len() && from != to {
                        let item = playlist.remove(from);
                        playlist.insert(to, item);
                        playlist_index = if playlist_index == from {
                            to
                        } else if from < playlist_index && to >= playlist_index {
                            playlist_index - 1
                        } else if from > playlist_index && to <= playlist_index {
                            playlist_index + 1
                        } else {
                            playlist_index
                        };
                        if let Ok(mut s) = shared.lock() {
                            s.playlist = playlist.clone();
                            s.playlist_index = playlist_index;
                        }
                    }
                }

                Command::Stop => {
                    state = match std::mem::replace(&mut state, RunnerState::Idle) {
                        RunnerState::Idle => RunnerState::Idle,
                        RunnerState::FadingIn { handle, alpha, .. } => RunnerState::FadingOut { handle, alpha, duration: fade_out_dur },
                        RunnerState::Running  { handle }            => RunnerState::FadingOut { handle, alpha: 1.0, duration: fade_out_dur },
                        RunnerState::CrossFading { to, alpha, .. }  => RunnerState::FadingOut { handle: to, alpha, duration: fade_out_dur },
                        RunnerState::FadingOut { handle, alpha, duration } => RunnerState::FadingOut { handle, alpha, duration },
                    };
                }

                Command::Start => {
                    if let Some(h) = do_spawn(&playlist, playlist_index, &registry, num_pixels, Arc::clone(&speed)) {
                        state = start_effect(std::mem::replace(&mut state, RunnerState::Idle), h, fade_in_dur, crossfade_dur);
                    }
                }
                Command::Next => {
                    if !playlist.is_empty() {
                        playlist_index = (playlist_index + 1) % playlist.len();
                        if let Ok(mut s) = shared.lock() { s.playlist_index = playlist_index; }
                    }
                    if let Some(h) = do_spawn(&playlist, playlist_index, &registry, num_pixels, Arc::clone(&speed)) {
                        state = start_effect(std::mem::replace(&mut state, RunnerState::Idle), h, fade_in_dur, crossfade_dur);
                    }
                }
                Command::Select(name) => {
                    if let Some(idx) = playlist.iter().position(|n| n == &name) {
                        playlist_index = idx;
                        if let Ok(mut s) = shared.lock() { s.playlist_index = idx; }
                    }
                    if let Some(effect) = registry.create(&name) {
                        let h = EffectHandle::spawn(effect, num_pixels, Arc::clone(&speed));
                        state = start_effect(std::mem::replace(&mut state, RunnerState::Idle), h, fade_in_dur, crossfade_dur);
                    }
                }
            }
        }

        // --- advance state machine and compute output ---
        let dt = FRAME_DURATION.as_secs_f32();

        let (output, next_state) = match std::mem::replace(&mut state, RunnerState::Idle) {
            RunnerState::Idle => (black.clone(), RunnerState::Idle),

            RunnerState::FadingIn { handle, alpha, duration } => {
                let new_alpha = (alpha + dt / duration).min(1.0);
                let buf = handle.read_buffer();
                let output = scale_buffer(&buf, new_alpha);
                let next = if new_alpha >= 1.0 {
                    effect_elapsed = 0.0;
                    RunnerState::Running { handle }
                } else {
                    RunnerState::FadingIn { handle, alpha: new_alpha, duration }
                };
                (output, next)
            }

            RunnerState::Running { handle } => {
                effect_elapsed += dt;
                let buf = handle.read_buffer();
                (buf, RunnerState::Running { handle })
            }

            RunnerState::CrossFading { from, to, alpha, duration } => {
                let new_alpha = (alpha + dt / duration).min(1.0);
                let output = blend_buffers(&from.read_buffer(), &to.read_buffer(), new_alpha);
                let next = if new_alpha >= 1.0 {
                    effect_elapsed = 0.0;
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
                let next = if new_alpha <= 0.0 { RunnerState::Idle } else { RunnerState::FadingOut { handle, alpha: new_alpha, duration } };
                (output, next)
            }
        };

        state = next_state;

        // --- auto-advance when effect duration expires ---
        if effect_duration > 0.0 && effect_elapsed >= effect_duration && matches!(state, RunnerState::Running { .. }) {
            effect_elapsed = 0.0;
            playlist_index = (playlist_index + 1) % playlist.len().max(1);
            if let Ok(mut s) = shared.lock() { s.playlist_index = playlist_index; }
            if let Some(h) = do_spawn(&playlist, playlist_index, &registry, num_pixels, Arc::clone(&speed)) {
                state = start_effect(std::mem::replace(&mut state, RunnerState::Idle), h, fade_in_dur, crossfade_dur);
            }
        }

        // --- write to hardware: apply color order, brightness, gamma ---
        let bri = f32::from_bits(brightness.load(Ordering::Relaxed));
        for (i, color) in output.iter().enumerate() {
            let c = color_order.apply(*color);
            let c = c.map(|v| gamma_lut[(v as f32 * bri) as usize]);
            pixels.set(i, c);
        }
        pixels.show();

        // --- update shared state for API reads ---
        if let Ok(mut s) = shared.lock() {
            s.is_running = state.is_active();
            s.current_effect = state.current_name().map(|n| n.to_string());
            s.transition = match &state {
                RunnerState::FadingIn   { .. } => Some("fading_in".into()),
                RunnerState::FadingOut  { .. } => Some("fading_out".into()),
                RunnerState::CrossFading { .. } => Some("crossfading".into()),
                _ => None,
            };
        }

        thread::sleep(FRAME_DURATION);
    }
}

// --------------------------------------------------------------------------
// Transition helper
// --------------------------------------------------------------------------

fn start_effect(old: RunnerState, new_handle: EffectHandle, fade_in_dur: f32, crossfade_dur: f32) -> RunnerState {
    match old {
        RunnerState::Idle | RunnerState::FadingOut { .. } =>
            RunnerState::FadingIn { handle: new_handle, alpha: 0.0, duration: fade_in_dur },
        RunnerState::FadingIn { handle, alpha, .. } =>
            RunnerState::CrossFading { from: handle, to: new_handle, alpha, duration: crossfade_dur },
        RunnerState::Running { handle } =>
            RunnerState::CrossFading { from: handle, to: new_handle, alpha: 0.0, duration: crossfade_dur },
        RunnerState::CrossFading { to, alpha, .. } =>
            RunnerState::CrossFading { from: to, to: new_handle, alpha: 1.0 - alpha, duration: crossfade_dur },
    }
}

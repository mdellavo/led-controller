use std::time::Duration;
use std::collections::HashMap;
use std::sync::{Arc, RwLock, atomic::AtomicU64};
use crate::audio::AudioAnalysis;
use crate::pixels::Color;

pub type Buffer = Vec<Color>;

// --------------------------------------------------------------------------
// Drawing helpers — used by individual effects
// --------------------------------------------------------------------------

/// Additively blend `src * alpha` into `dst`, clamping each channel to 255.
#[inline]
pub fn blend_add(dst: &mut Color, src: Color, alpha: f32) {
    for (d, s) in dst.iter_mut().zip(src.iter()) {
        *d = (*d as f32 + *s as f32 * alpha).min(255.0) as u8;
    }
}

/// Draw a point light at a sub-pixel float position.
/// Splits brightness between the two adjacent LEDs by the fractional part
/// (linear interpolation / antialiasing). Additively blends so multiple
/// sources accumulate correctly in the same buffer.
pub fn plot(buffer: &mut Buffer, pos: f32, color: Color, alpha: f32) {
    let n = buffer.len();
    if n == 0 || pos < 0.0 || pos >= n as f32 { return; }
    let lo = pos.floor() as usize;
    let frac = pos.fract();
    blend_add(&mut buffer[lo], color, alpha * (1.0 - frac));
    if lo + 1 < n {
        blend_add(&mut buffer[lo + 1], color, alpha * frac);
    }
}

/// Multiply every channel of every pixel by `per_second.powf(dt)`.
/// Use this instead of a fixed per-frame multiplier so the decay rate is
/// independent of frame rate and speed scaling.
pub fn fade_buffer(buffer: &mut Buffer, per_second: f32, dt: f32) {
    let factor = per_second.powf(dt);
    for pixel in buffer.iter_mut() {
        *pixel = pixel.map(|c| (c as f32 * factor) as u8);
    }
}

pub trait Effect: Send + 'static {
    fn name(&self) -> &'static str;
    /// Update the pixel buffer for one frame. Return false to signal natural completion.
    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool;
}

pub type EffectFactory = Box<dyn Fn() -> Box<dyn Effect> + Send + Sync>;

pub struct EffectRegistry {
    factories: HashMap<String, EffectFactory>,
    order: Vec<String>,
    descriptions: HashMap<String, String>,
}

impl EffectRegistry {
    pub fn new() -> Self {
        Self {
            factories: HashMap::new(),
            order: Vec::new(),
            descriptions: HashMap::new(),
        }
    }

    pub fn register<F>(&mut self, name: &str, factory: F)
    where
        F: Fn() -> Box<dyn Effect> + Send + Sync + 'static,
    {
        if !self.factories.contains_key(name) {
            self.order.push(name.to_string());
        }
        self.factories.insert(name.to_string(), Box::new(factory));
    }

    pub fn set_description(&mut self, name: &str, desc: String) {
        self.descriptions.insert(name.to_string(), desc);
    }

    pub fn descriptions(&self) -> &HashMap<String, String> {
        &self.descriptions
    }

    pub fn create(&self, name: &str) -> Option<Box<dyn Effect>> {
        self.factories.get(name).map(|f| f())
    }

    pub fn names(&self) -> &[String] {
        &self.order
    }

    #[allow(dead_code)]
    pub fn contains(&self, name: &str) -> bool {
        self.factories.contains_key(name)
    }
}

pub mod lua_effect;

pub mod rainbow;
pub mod fade;
pub mod chase;
pub mod sparkle;
pub mod strobe;
pub mod cylon;
pub mod halloween_eyes;
pub mod twinkle;
pub mod snow_sparkle;
pub mod running_lights;
pub mod theatre_chase;
pub mod fire;
pub mod bouncing_balls;
pub mod meteor;

/// Scan `dir` for `*.lua` files and register each as a `LuaEffect`.
/// Silently skips the directory if it doesn't exist. Scripts that fail to
/// load or lack a `name` global fall back to the filename stem as the name.
pub fn load_lua_effects(
    dir: &std::path::Path,
    num_pixels: usize,
    registry: &mut EffectRegistry,
    palette: Arc<RwLock<Vec<[u8; 3]>>>,
    palette_cycle_ms: Arc<AtomicU64>,
    audio: Arc<AudioAnalysis>,
) {
    let entries = match std::fs::read_dir(dir) {
        Ok(e) => e,
        Err(_) => return,
    };
    for entry in entries.flatten() {
        let path = entry.path();
        if path.extension().and_then(|e| e.to_str()) != Some("lua") {
            continue;
        }
        let source = match std::fs::read_to_string(&path) {
            Ok(s) => s,
            Err(e) => {
                tracing::warn!("skipping {:?}: {e}", path);
                continue;
            }
        };
        let (probed_name, description) = lua_effect::LuaEffect::probe_metadata(&source);
        let name = probed_name
            .or_else(|| path.file_stem().map(|s| s.to_string_lossy().into_owned()))
            .unwrap_or_else(|| "Lua Effect".to_string());
        // Leak the name once — effect names are 'static in the Effect trait.
        let static_name: &'static str = Box::leak(name.into_boxed_str());
        tracing::info!(
            "loaded Lua effect {:?}: {static_name}",
            path.file_name().unwrap_or_default()
        );
        if let Some(desc) = description {
            registry.set_description(static_name, desc);
        }
        registry.register(static_name, {
            let src      = source.clone();
            let pal      = Arc::clone(&palette);
            let cycle_ms = Arc::clone(&palette_cycle_ms);
            let aud      = Arc::clone(&audio);
            move || Box::new(lua_effect::LuaEffect::new(
                static_name, src.clone(), num_pixels,
                Arc::clone(&pal), Arc::clone(&cycle_ms), Arc::clone(&aud),
            ))
        });
    }
}

pub fn default_registry(num_pixels: usize) -> EffectRegistry {
    let mut r = EffectRegistry::new();

    // Original effects
    r.register("Rainbow", || Box::new(rainbow::RainbowEffect::new()));
    r.register("Random Fade", move || Box::new(fade::RandomFadeEffect::new(num_pixels)));
    r.register("Chase", move || Box::new(chase::ChaseEffect::new(num_pixels)));
    r.register("Sparkle", move || Box::new(sparkle::SparkleEffect::new(num_pixels)));

    // Tweaking4all effects
    r.register("Strobe", || Box::new(strobe::StrobeEffect::new([255, 255, 255], 10, 50.0, 1000.0)));
    r.register("Cylon", || Box::new(cylon::CylonEffect::new([255, 0, 0], 4, 30.0)));
    r.register("KITT", || Box::new(cylon::KITTEffect::new([255, 0, 0], 4, 30.0)));
    r.register("Halloween Eyes", move || Box::new(halloween_eyes::HalloweenEyesEffect::new(
        [255, 0, 0], 1, 4, 50, 20.0, 2000.0,
    )));
    r.register("Twinkle", || Box::new(twinkle::TwinkleEffect::new([255, 255, 255], 10, 100.0)));
    r.register("Random Twinkle", || Box::new(twinkle::RandomTwinkleEffect::new(10, 100.0)));
    r.register("Snow Sparkle", || Box::new(snow_sparkle::SnowSparkleEffect::new(
        [20, 20, 20], [255, 255, 255], 20.0, 200.0,
    )));
    r.register("Running Lights", || Box::new(running_lights::RunningLightsEffect::new([255, 0, 0], 1.0)));
    r.register("Theatre Chase", || Box::new(theatre_chase::TheatreChaseEffect::new([255, 255, 255], 100.0)));
    r.register("Theatre Chase Rainbow", || Box::new(theatre_chase::TheatreChaseRainbowEffect::new(100.0)));
    r.register("Fire", move || Box::new(fire::FireEffect::new(num_pixels, 55, 120, 15.0)));
    r.register("Bouncing Balls", || Box::new(bouncing_balls::BouncingBallsEffect::new(vec![], 3)));
    r.register("Meteor Rain", || Box::new(meteor::MeteorRainEffect::new(
        [255, 255, 255], 10, 64, true, 30.0,
    )));

    r
}

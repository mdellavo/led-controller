use std::time::Duration;
use std::collections::HashMap;
use crate::pixels::Color;

pub type Buffer = Vec<Color>;

pub trait Effect: Send + 'static {
    fn name(&self) -> &'static str;
    /// Update the pixel buffer for one frame. Return false to signal natural completion.
    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool;
}

pub type EffectFactory = Box<dyn Fn() -> Box<dyn Effect> + Send + Sync>;

pub struct EffectRegistry {
    factories: HashMap<String, EffectFactory>,
    order: Vec<String>,
}

impl EffectRegistry {
    pub fn new() -> Self {
        Self {
            factories: HashMap::new(),
            order: Vec::new(),
        }
    }

    pub fn register<F>(&mut self, name: &str, factory: F)
    where
        F: Fn() -> Box<dyn Effect> + Send + Sync + 'static,
    {
        self.factories.insert(name.to_string(), Box::new(factory));
        self.order.push(name.to_string());
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

pub mod rainbow;
pub mod fade;
pub mod solid;
pub mod chase;
pub mod sparkle;
pub mod strobe;
pub mod cylon;
pub mod halloween_eyes;
pub mod twinkle;
pub mod snow_sparkle;
pub mod running_lights;
pub mod color_wipe;
pub mod theatre_chase;
pub mod fire;
pub mod bouncing_balls;
pub mod meteor;

pub fn default_registry(num_pixels: usize) -> EffectRegistry {
    let mut r = EffectRegistry::new();

    // Original effects
    r.register("Rainbow", || Box::new(rainbow::RainbowEffect::new()));
    r.register("Random Fade", move || Box::new(fade::RandomFadeEffect::new(num_pixels)));
    r.register("Chase", move || Box::new(chase::ChaseEffect::new(num_pixels)));
    r.register("Sparkle", move || Box::new(sparkle::SparkleEffect::new(num_pixels)));

    // Tweaking4all effects
    r.register("Strobe", || Box::new(strobe::StrobeEffect::new([255, 255, 255], 10, 50.0, 1000.0)));
    r.register("Strobe Red", || Box::new(strobe::StrobeEffect::new([255, 0, 0], 10, 50.0, 1000.0)));
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
    r.register("Running Lights Green", || Box::new(running_lights::RunningLightsEffect::new([0, 255, 0], 1.0)));
    r.register("Color Wipe Red", || Box::new(color_wipe::ColorWipeEffect::new([255, 0, 0], 20.0)));
    r.register("Color Wipe Green", || Box::new(color_wipe::ColorWipeEffect::new([0, 255, 0], 20.0)));
    r.register("Color Wipe Blue", || Box::new(color_wipe::ColorWipeEffect::new([0, 0, 255], 20.0)));
    r.register("Theatre Chase", || Box::new(theatre_chase::TheatreChaseEffect::new([255, 255, 255], 100.0)));
    r.register("Theatre Chase Rainbow", || Box::new(theatre_chase::TheatreChaseRainbowEffect::new(100.0)));
    r.register("Fire", move || Box::new(fire::FireEffect::new(num_pixels, 55, 120, 15.0)));
    r.register("Bouncing Balls", || Box::new(bouncing_balls::BouncingBallsEffect::new(vec![], 3)));
    r.register("Meteor Rain", || Box::new(meteor::MeteorRainEffect::new(
        [255, 255, 255], 10, 64, true, 30.0,
    )));

    // Solid colors
    r.register("Solid Red", || Box::new(solid::SolidEffect::new([200, 0, 0], "Solid Red")));
    r.register("Solid Green", || Box::new(solid::SolidEffect::new([0, 200, 0], "Solid Green")));
    r.register("Solid Blue", || Box::new(solid::SolidEffect::new([0, 0, 200], "Solid Blue")));
    r.register("Solid White", || Box::new(solid::SolidEffect::new([200, 200, 200], "Solid White")));

    r
}

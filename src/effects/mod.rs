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

pub fn default_registry(num_pixels: usize) -> EffectRegistry {
    let mut r = EffectRegistry::new();
    r.register("Rainbow", || Box::new(rainbow::RainbowEffect::new()));
    r.register("Random Fade", move || Box::new(fade::RandomFadeEffect::new(num_pixels)));
    r.register("Chase", move || Box::new(chase::ChaseEffect::new(num_pixels)));
    r.register("Sparkle", move || Box::new(sparkle::SparkleEffect::new(num_pixels)));
    r.register("Solid Red", || Box::new(solid::SolidEffect::new([200, 0, 0], "Solid Red")));
    r.register("Solid Green", || Box::new(solid::SolidEffect::new([0, 200, 0], "Solid Green")));
    r.register("Solid Blue", || Box::new(solid::SolidEffect::new([0, 0, 200], "Solid Blue")));
    r.register("Solid White", || Box::new(solid::SolidEffect::new([200, 200, 200], "Solid White")));
    r
}

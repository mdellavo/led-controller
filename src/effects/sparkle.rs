use std::time::Duration;
use rand::Rng;
use crate::effects::{Effect, Buffer};

pub struct SparkleEffect {
    brightness: Vec<f32>,
    target: Vec<f32>,
    num_pixels: usize,
}

impl SparkleEffect {
    pub fn new(num_pixels: usize) -> Self {
        Self {
            brightness: vec![0.0; num_pixels],
            target: vec![0.0; num_pixels],
            num_pixels,
        }
    }
}

impl Effect for SparkleEffect {
    fn name(&self) -> &'static str { "Sparkle" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        let dt = delta.as_secs_f32();
        let mut rng = rand::thread_rng();

        // randomly trigger new sparkles
        let trigger_count = (self.num_pixels as f32 * dt * 3.0) as usize + 1;
        for _ in 0..trigger_count {
            let idx = rng.gen_range(0..self.num_pixels);
            if self.target[idx] < 0.1 {
                self.target[idx] = rng.gen_range(0.5..1.0);
            }
        }

        for i in 0..self.num_pixels {
            let diff = self.target[i] - self.brightness[i];
            if diff.abs() < 0.01 {
                if self.target[i] > 0.5 {
                    self.target[i] = 0.0;
                }
                self.brightness[i] = self.target[i];
            } else {
                self.brightness[i] += diff * dt * 8.0;
            }

            let b = (self.brightness[i] * 255.0) as u8;
            buffer[i] = [b, b, b];
        }

        true
    }
}

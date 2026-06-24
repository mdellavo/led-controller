use std::time::Duration;
use rand::Rng;
use crate::effects::{Effect, Buffer};
use crate::pixels::Color;

pub struct TwinkleEffect {
    color: Color,
    count: usize,
    speed_ms: f32,
    timer: f32,
}

impl TwinkleEffect {
    pub fn new(color: Color, count: usize, speed_ms: f32) -> Self {
        Self { color, count, speed_ms, timer: 0.0 }
    }
}

impl Effect for TwinkleEffect {
    fn name(&self) -> &'static str { "Twinkle" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        self.timer += delta.as_secs_f32() * 1000.0;
        if self.timer >= self.speed_ms {
            self.timer -= self.speed_ms;
            let n = buffer.len();
            for pixel in buffer.iter_mut() {
                *pixel = [0, 0, 0];
            }
            let mut rng = rand::thread_rng();
            for _ in 0..self.count {
                let idx = rng.gen_range(0..n);
                buffer[idx] = self.color;
            }
        }
        true
    }
}

pub struct RandomTwinkleEffect {
    count: usize,
    speed_ms: f32,
    timer: f32,
}

impl RandomTwinkleEffect {
    pub fn new(count: usize, speed_ms: f32) -> Self {
        Self { count, speed_ms, timer: 0.0 }
    }
}

impl Effect for RandomTwinkleEffect {
    fn name(&self) -> &'static str { "Random Twinkle" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        self.timer += delta.as_secs_f32() * 1000.0;
        if self.timer >= self.speed_ms {
            self.timer -= self.speed_ms;
            let n = buffer.len();
            for pixel in buffer.iter_mut() {
                *pixel = [0, 0, 0];
            }
            let mut rng = rand::thread_rng();
            for _ in 0..self.count {
                let idx = rng.gen_range(0..n);
                buffer[idx] = [rng.gen(), rng.gen(), rng.gen()];
            }
        }
        true
    }
}

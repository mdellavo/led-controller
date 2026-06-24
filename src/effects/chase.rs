use std::time::Duration;
use crate::effects::{Effect, Buffer};

pub struct ChaseEffect {
    position: f32,
    tail_length: usize,
    num_pixels: usize,
    speed: f32,
}

impl ChaseEffect {
    pub fn new(num_pixels: usize) -> Self {
        Self {
            position: 0.0,
            tail_length: (num_pixels / 6).max(3),
            num_pixels,
            speed: num_pixels as f32 * 1.5,
        }
    }
}

impl Effect for ChaseEffect {
    fn name(&self) -> &'static str { "Chase" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        self.position = (self.position + self.speed * delta.as_secs_f32()) % self.num_pixels as f32;

        for pixel in buffer.iter_mut() {
            *pixel = [0, 0, 0];
        }

        for i in 0..self.tail_length {
            let idx_f = (self.position as isize - i as isize).rem_euclid(self.num_pixels as isize) as usize;
            let brightness = 1.0 - (i as f32 / self.tail_length as f32);
            let r = (0.0_f32 * brightness) as u8;
            let g = (150.0 * brightness) as u8;
            let b = (255.0 * brightness) as u8;
            buffer[idx_f] = [r, g, b];
        }

        true
    }
}

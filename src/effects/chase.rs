use std::time::Duration;
use rand::Rng;
use crate::effects::{Effect, Buffer};
use crate::pixels::Color;

pub struct ChaseEffect {
    position: f32,
    prev_position: f32,
    tail_length: usize,
    num_pixels: usize,
    speed: f32,
    color: Color,
}

impl ChaseEffect {
    pub fn new(num_pixels: usize) -> Self {
        let color = rand::thread_rng().gen::<[u8; 3]>();
        Self {
            position: 0.0,
            prev_position: 0.0,
            tail_length: (num_pixels / 6).max(3),
            num_pixels,
            speed: num_pixels as f32 * 1.5,
            color,
        }
    }
}

impl Effect for ChaseEffect {
    fn name(&self) -> &'static str { "Chase" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        let new_position = (self.position + self.speed * delta.as_secs_f32()) % self.num_pixels as f32;

        // detect wrap-around and pick a new color
        if new_position < self.prev_position {
            self.color = rand::thread_rng().gen::<[u8; 3]>();
        }

        self.prev_position = self.position;
        self.position = new_position;

        for pixel in buffer.iter_mut() {
            *pixel = [0, 0, 0];
        }

        let [r, g, b] = self.color;
        for i in 0..self.tail_length {
            let idx = (self.position as isize - i as isize).rem_euclid(self.num_pixels as isize) as usize;
            let brightness = 1.0 - (i as f32 / self.tail_length as f32);
            buffer[idx] = [
                (r as f32 * brightness) as u8,
                (g as f32 * brightness) as u8,
                (b as f32 * brightness) as u8,
            ];
        }

        true
    }
}

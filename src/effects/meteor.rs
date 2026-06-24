use std::time::Duration;
use rand::Rng;
use crate::effects::{Effect, Buffer};
use crate::pixels::Color;

pub struct MeteorRainEffect {
    color: Color,
    meteor_size: usize,
    trail_decay: u8,
    random_decay: bool,
    speed_ms: f32,
    position: isize,
    timer: f32,
}

impl MeteorRainEffect {
    pub fn new(
        color: Color,
        meteor_size: usize,
        trail_decay: u8,
        random_decay: bool,
        speed_ms: f32,
    ) -> Self {
        Self {
            color,
            meteor_size,
            trail_decay,
            random_decay,
            speed_ms,
            position: 0,
            timer: 0.0,
        }
    }
}

impl Effect for MeteorRainEffect {
    fn name(&self) -> &'static str { "Meteor Rain" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        let n = buffer.len();
        self.timer += delta.as_secs_f32() * 1000.0;

        if self.timer < self.speed_ms {
            return true;
        }
        self.timer -= self.speed_ms;

        let mut rng = rand::thread_rng();

        // Step 1: fade all pixels (trail decay)
        let scale = (255u16 - self.trail_decay as u16) as f32 / 255.0;
        for pixel in buffer.iter_mut() {
            if !self.random_decay || rng.gen_bool(0.5) {
                *pixel = pixel.map(|c| (c as f32 * scale) as u8);
            }
        }

        // Step 2: draw meteor
        for i in 0..self.meteor_size {
            let idx = self.position + i as isize;
            if idx >= 0 && (idx as usize) < n {
                buffer[idx as usize] = self.color;
            }
        }

        // Step 3: advance and reset
        self.position += 1;
        if self.position > (n + self.meteor_size) as isize {
            self.position = 0;
            // clear buffer on reset so trail doesn't linger
            for pixel in buffer.iter_mut() {
                *pixel = [0, 0, 0];
            }
        }

        true
    }
}

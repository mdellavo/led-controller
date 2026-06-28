use std::time::Duration;
use rand::Rng;
use crate::effects::{Effect, Buffer, plot, fade_buffer};
use crate::pixels::Color;

pub struct MeteorRainEffect {
    color: Color,
    meteor_size: usize,
    /// Pre-computed per-second decay factor (converted from legacy trail_decay+speed_ms params).
    decay_per_second: f32,
    random_decay: bool,
    /// Pixels per second (converted from legacy speed_ms).
    speed: f32,
    position: f32,
}

impl MeteorRainEffect {
    pub fn new(
        color: Color,
        meteor_size: usize,
        trail_decay: u8,
        random_decay: bool,
        speed_ms: f32,
    ) -> Self {
        // Convert legacy (trail_decay per step, step every speed_ms ms) to
        // a continuous per-second decay rate so movement is frame-rate independent.
        let step_scale = (255u16 - trail_decay as u16) as f32 / 255.0;
        let steps_per_sec = 1000.0 / speed_ms.max(1.0);
        Self {
            color,
            meteor_size,
            decay_per_second: step_scale.powf(steps_per_sec),
            random_decay,
            speed: steps_per_sec,
            position: -(meteor_size as f32),
        }
    }
}

impl Effect for MeteorRainEffect {
    fn name(&self) -> &'static str { "Meteor Rain" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        let n = buffer.len();
        let dt = delta.as_secs_f32();
        let mut rng = rand::thread_rng();

        // Trail decay — delta-time correct.
        if self.random_decay {
            let factor = self.decay_per_second.powf(dt);
            for pixel in buffer.iter_mut() {
                if rng.gen_bool(0.5) {
                    *pixel = pixel.map(|c| (c as f32 * factor) as u8);
                }
            }
        } else {
            fade_buffer(buffer, self.decay_per_second, dt);
        }

        // Advance position continuously.
        self.position += self.speed * dt;

        // Draw meteor head with antialiased sub-pixel positioning.
        for i in 0..self.meteor_size {
            let pos = self.position - i as f32;
            plot(buffer, pos, self.color, 1.0);
        }

        // Reset when the tail has fully left the strip.
        if self.position > (n + self.meteor_size) as f32 {
            self.position = -(self.meteor_size as f32);
            for pixel in buffer.iter_mut() {
                *pixel = [0, 0, 0];
            }
        }

        true
    }
}

use std::time::Duration;
use crate::effects::{Effect, Buffer, plot, fade_buffer};
use crate::pixels::Color;

pub struct CylonEffect {
    color: Color,
    eye_size: usize,
    speed: f32,
    position: f32,
    direction: f32,
}

impl CylonEffect {
    pub fn new(color: Color, eye_size: usize, speed: f32) -> Self {
        Self { color, eye_size, speed, position: 0.0, direction: 1.0 }
    }
}

// Draw a symmetric eye centered at a sub-pixel float position.
fn draw_eye(buffer: &mut Buffer, color: Color, center: f32, eye_size: usize) {
    plot(buffer, center, color, 1.0);
    for i in 1..eye_size {
        let alpha = 1.0 / (1 << i) as f32;
        plot(buffer, center - i as f32, color, alpha);
        plot(buffer, center + i as f32, color, alpha);
    }
}

impl Effect for CylonEffect {
    fn name(&self) -> &'static str { "Cylon" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        let n = buffer.len();
        let dt = delta.as_secs_f32();

        // Decay existing pixels — equivalent to * 0.8 per frame at 60 fps,
        // but correct across any frame rate or speed multiplier.
        fade_buffer(buffer, 0.8_f32.powf(60.0), dt);

        draw_eye(buffer, self.color, self.position, self.eye_size);

        self.position += self.speed * self.direction * dt;

        let max = (n - self.eye_size) as f32;
        if self.position >= max {
            self.position = max;
            self.direction = -1.0;
        } else if self.position < 0.0 {
            self.position = 0.0;
            self.direction = 1.0;
        }

        true
    }
}

pub struct KITTEffect {
    color: Color,
    eye_size: usize,
    speed: f32,
    half_width: f32,
    expanding: bool,
}

impl KITTEffect {
    pub fn new(color: Color, eye_size: usize, speed: f32) -> Self {
        Self { color, eye_size, speed, half_width: 0.0, expanding: true }
    }
}

impl Effect for KITTEffect {
    fn name(&self) -> &'static str { "KITT" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        let n = buffer.len();
        let center = n as f32 / 2.0;
        let dt = delta.as_secs_f32();
        let max_half = (center - self.eye_size as f32).max(0.0);

        fade_buffer(buffer, 0.8_f32.powf(60.0), dt);

        draw_eye(buffer, self.color, center - self.half_width, self.eye_size);
        draw_eye(buffer, self.color, center + self.half_width, self.eye_size);

        if self.expanding {
            self.half_width += self.speed * dt;
            if self.half_width >= max_half {
                self.half_width = max_half;
                self.expanding = false;
            }
        } else {
            self.half_width -= self.speed * dt;
            if self.half_width <= 0.0 {
                self.half_width = 0.0;
                self.expanding = true;
            }
        }

        true
    }
}

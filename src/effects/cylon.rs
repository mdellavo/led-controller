use std::time::Duration;
use crate::effects::{Effect, Buffer};
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
        Self {
            color,
            eye_size,
            speed,
            position: 0.0,
            direction: 1.0,
        }
    }
}

fn draw_eye(buffer: &mut Buffer, color: Color, center: usize, eye_size: usize) {
    let n = buffer.len();
    for i in 0..eye_size {
        let brightness = 1.0 / (1 << i) as f32;
        // draw left side
        if center >= i {
            let idx = center - i;
            buffer[idx] = color.map(|c| (c as f32 * brightness) as u8);
        }
        // draw right side
        let idx = center + i;
        if idx < n {
            buffer[idx] = color.map(|c| (c as f32 * brightness) as u8);
        }
    }
}

impl Effect for CylonEffect {
    fn name(&self) -> &'static str { "Cylon" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        let n = buffer.len();
        let dt = delta.as_secs_f32();

        // fade existing pixels
        for pixel in buffer.iter_mut() {
            *pixel = pixel.map(|c| (c as f32 * 0.8) as u8);
        }

        let center = self.position as usize;
        draw_eye(buffer, self.color, center, self.eye_size);

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
        Self {
            color,
            eye_size,
            speed,
            half_width: 0.0,
            expanding: true,
        }
    }
}

impl Effect for KITTEffect {
    fn name(&self) -> &'static str { "KITT" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        let n = buffer.len();
        let center = n / 2;
        let dt = delta.as_secs_f32();
        let max_half = (center - self.eye_size) as f32;

        // fade existing pixels
        for pixel in buffer.iter_mut() {
            *pixel = pixel.map(|c| (c as f32 * 0.8) as u8);
        }

        let offset = self.half_width as usize;

        // draw left eye
        if center >= offset {
            draw_eye(buffer, self.color, center - offset, self.eye_size);
        }
        // draw right eye
        if center + offset < n {
            draw_eye(buffer, self.color, center + offset, self.eye_size);
        }

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

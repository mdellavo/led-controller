use std::time::Duration;
use std::f32::consts::PI;
use crate::effects::{Effect, Buffer};
use crate::pixels::Color;

pub struct RunningLightsEffect {
    color: Color,
    speed: f32,
    wave_pos: f32,
}

impl RunningLightsEffect {
    pub fn new(color: Color, speed: f32) -> Self {
        Self { color, speed, wave_pos: 0.0 }
    }
}

impl Effect for RunningLightsEffect {
    fn name(&self) -> &'static str { "Running Lights" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        let n = buffer.len();
        self.wave_pos += self.speed * delta.as_secs_f32() * 2.0 * PI;

        for (i, pixel) in buffer.iter_mut().enumerate() {
            let i_f = i as f32;
            let brightness = ((i_f * 2.0 * PI / n as f32 + self.wave_pos).sin() + 1.0) / 2.0;
            *pixel = self.color.map(|c| (c as f32 * brightness) as u8);
        }

        true
    }
}

use std::time::Duration;
use crate::effects::{Effect, Buffer};
use crate::pixels::Color;

pub struct TheatreChaseEffect {
    color: Color,
    speed_ms: f32,
    phase: usize,
    timer: f32,
}

impl TheatreChaseEffect {
    pub fn new(color: Color, speed_ms: f32) -> Self {
        Self { color, speed_ms, phase: 0, timer: 0.0 }
    }
}

fn colorwheel(pos: u8) -> Color {
    let pos = 255 - pos;
    if pos < 85 {
        [255 - pos * 3, 0, pos * 3]
    } else if pos < 170 {
        let pos = pos - 85;
        [0, pos * 3, 255 - pos * 3]
    } else {
        let pos = pos - 170;
        [pos * 3, 255 - pos * 3, 0]
    }
}

impl Effect for TheatreChaseEffect {
    fn name(&self) -> &'static str { "Theatre Chase" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        self.timer += delta.as_secs_f32() * 1000.0;
        if self.timer >= self.speed_ms {
            self.timer -= self.speed_ms;

            let n = buffer.len();
            for pixel in buffer.iter_mut() {
                *pixel = [0, 0, 0];
            }
            let mut i = self.phase;
            while i < n {
                buffer[i] = self.color;
                i += 3;
            }
            self.phase = (self.phase + 1) % 3;
        }
        true
    }
}

pub struct TheatreChaseRainbowEffect {
    speed_ms: f32,
    phase: usize,
    hue_offset: u8,
    timer: f32,
}

impl TheatreChaseRainbowEffect {
    pub fn new(speed_ms: f32) -> Self {
        Self { speed_ms, phase: 0, hue_offset: 0, timer: 0.0 }
    }
}

impl Effect for TheatreChaseRainbowEffect {
    fn name(&self) -> &'static str { "Theatre Chase Rainbow" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        self.timer += delta.as_secs_f32() * 1000.0;
        if self.timer >= self.speed_ms {
            self.timer -= self.speed_ms;

            let n = buffer.len();
            for pixel in buffer.iter_mut() {
                *pixel = [0, 0, 0];
            }
            let mut i = self.phase;
            while i < n {
                buffer[i] = colorwheel(((i as u16 * 256 / n as u16) as u8).wrapping_add(self.hue_offset));
                i += 3;
            }
            self.phase = (self.phase + 1) % 3;
            self.hue_offset = self.hue_offset.wrapping_add(1);
        }
        true
    }
}

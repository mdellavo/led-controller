use std::time::Duration;
use crate::effects::{Effect, Buffer};

pub struct RainbowEffect {
    hue: f32,
}

impl RainbowEffect {
    pub fn new() -> Self {
        Self { hue: 0.0 }
    }
}

fn colorwheel(pos: u8) -> [u8; 3] {
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

impl Effect for RainbowEffect {
    fn name(&self) -> &'static str { "Rainbow" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        self.hue = (self.hue + delta.as_secs_f32() * 50.0) % 256.0;
        let len = buffer.len();
        for (i, pixel) in buffer.iter_mut().enumerate() {
            *pixel = colorwheel(((self.hue as usize + i * 256 / len) % 256) as u8);
        }
        true
    }
}

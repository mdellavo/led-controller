use std::time::Duration;
use crate::effects::{Effect, Buffer};
use crate::pixels::Color;

enum WipeState {
    Wiping,
    Clearing,
}

pub struct ColorWipeEffect {
    color: Color,
    speed_ms: f32,
    state: WipeState,
    pos: usize,
    timer: f32,
}

impl ColorWipeEffect {
    pub fn new(color: Color, speed_ms: f32) -> Self {
        Self {
            color,
            speed_ms,
            state: WipeState::Wiping,
            pos: 0,
            timer: 0.0,
        }
    }
}

impl Effect for ColorWipeEffect {
    fn name(&self) -> &'static str { "Color Wipe" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        let n = buffer.len();
        self.timer += delta.as_secs_f32() * 1000.0;

        while self.timer >= self.speed_ms {
            self.timer -= self.speed_ms;
            match self.state {
                WipeState::Wiping => {
                    if self.pos < n {
                        buffer[self.pos] = self.color;
                        self.pos += 1;
                    }
                    if self.pos >= n {
                        self.pos = 0;
                        self.state = WipeState::Clearing;
                    }
                }
                WipeState::Clearing => {
                    if self.pos < n {
                        buffer[self.pos] = [0, 0, 0];
                        self.pos += 1;
                    }
                    if self.pos >= n {
                        self.pos = 0;
                        self.state = WipeState::Wiping;
                    }
                }
            }
        }

        true
    }
}

use std::time::Duration;
use crate::effects::{Effect, Buffer};
use crate::pixels::Color;

enum StrobeState {
    FlashOn,
    FlashOff,
    Pausing,
}

pub struct StrobeEffect {
    color: Color,
    flashes: u32,
    flash_delay_ms: f32,
    end_pause_ms: f32,
    state: StrobeState,
    flash_count: u32,
    timer: f32,
}

impl StrobeEffect {
    pub fn new(color: Color, flashes: u32, flash_delay_ms: f32, end_pause_ms: f32) -> Self {
        Self {
            color,
            flashes,
            flash_delay_ms,
            end_pause_ms,
            state: StrobeState::FlashOn,
            flash_count: 0,
            timer: 0.0,
        }
    }
}

impl Effect for StrobeEffect {
    fn name(&self) -> &'static str { "Strobe" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        self.timer += delta.as_secs_f32() * 1000.0;

        match self.state {
            StrobeState::FlashOn => {
                for pixel in buffer.iter_mut() {
                    *pixel = self.color;
                }
                if self.timer >= self.flash_delay_ms {
                    self.timer -= self.flash_delay_ms;
                    self.state = StrobeState::FlashOff;
                }
            }
            StrobeState::FlashOff => {
                for pixel in buffer.iter_mut() {
                    *pixel = [0, 0, 0];
                }
                if self.timer >= self.flash_delay_ms {
                    self.timer -= self.flash_delay_ms;
                    self.flash_count += 1;
                    if self.flash_count >= self.flashes {
                        self.flash_count = 0;
                        self.state = StrobeState::Pausing;
                    } else {
                        self.state = StrobeState::FlashOn;
                    }
                }
            }
            StrobeState::Pausing => {
                for pixel in buffer.iter_mut() {
                    *pixel = [0, 0, 0];
                }
                if self.timer >= self.end_pause_ms {
                    self.timer -= self.end_pause_ms;
                    self.state = StrobeState::FlashOn;
                }
            }
        }
        true
    }
}

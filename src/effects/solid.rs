use std::time::Duration;
use crate::effects::{Effect, Buffer};
use crate::pixels::Color;

pub struct SolidEffect {
    color: Color,
    label: &'static str,
}

impl SolidEffect {
    pub fn new(color: Color, label: &'static str) -> Self {
        Self { color, label }
    }
}

impl Effect for SolidEffect {
    fn name(&self) -> &'static str { self.label }

    fn update(&mut self, buffer: &mut Buffer, _delta: Duration) -> bool {
        for pixel in buffer.iter_mut() {
            *pixel = self.color;
        }
        true
    }
}

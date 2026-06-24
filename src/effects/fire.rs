use std::time::Duration;
use rand::Rng;
use crate::effects::{Effect, Buffer};

pub struct FireEffect {
    cooling: u8,
    sparking: u8,
    speed_ms: f32,
    heat: Vec<u8>,
    timer: f32,
}

impl FireEffect {
    pub fn new(num_pixels: usize, cooling: u8, sparking: u8, speed_ms: f32) -> Self {
        Self {
            cooling,
            sparking,
            speed_ms,
            heat: vec![0u8; num_pixels],
            timer: 0.0,
        }
    }

    fn heat_to_color(heat: u8) -> [u8; 3] {
        let t = heat as u32;
        if t < 85 {
            [(t * 3) as u8, 0, 0]
        } else if t < 170 {
            let t = t - 85;
            [255, (t * 3) as u8, 0]
        } else {
            let t = t - 170;
            [255, 255, (t * 3) as u8]
        }
    }
}

impl Effect for FireEffect {
    fn name(&self) -> &'static str { "Fire" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        self.timer += delta.as_secs_f32() * 1000.0;
        if self.timer < self.speed_ms {
            // still render last heat state while waiting
            for (i, pixel) in buffer.iter_mut().enumerate() {
                *pixel = Self::heat_to_color(self.heat[i]);
            }
            return true;
        }
        self.timer -= self.speed_ms;

        let n = self.heat.len();
        let mut rng = rand::thread_rng();

        // Step 1: cool down every cell
        let cool_max = ((self.cooling as usize * 10) / n + 2) as u8;
        for cell in self.heat.iter_mut() {
            let cool = rng.gen_range(0..=cool_max);
            *cell = cell.saturating_sub(cool);
        }

        // Step 2: diffuse heat upward (from top down so we don't double-count)
        for i in (2..n).rev() {
            self.heat[i] = ((self.heat[i] as u16
                + self.heat[i - 1] as u16
                + self.heat[i - 2] as u16)
                / 3) as u8;
        }

        // Step 3: randomly ignite sparks near the bottom
        if rng.gen_range(0u8..=255) < self.sparking {
            let y = rng.gen_range(0..7.min(n));
            self.heat[y] = self.heat[y].saturating_add(rng.gen_range(160..=255));
        }

        // Step 4: map heat to color and write to buffer
        for (i, pixel) in buffer.iter_mut().enumerate() {
            *pixel = Self::heat_to_color(self.heat[i]);
        }

        true
    }
}

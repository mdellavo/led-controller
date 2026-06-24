use std::time::Duration;
use rand::Rng;
use crate::effects::{Effect, Buffer};
use crate::pixels::Color;

enum SnowState {
    Sparkling { pos: usize, timer: f32 },
    Waiting { timer: f32 },
}

pub struct SnowSparkleEffect {
    bg_color: Color,
    sparkle_color: Color,
    sparkle_delay_ms: f32,
    speed_ms: f32,
    state: SnowState,
}

impl SnowSparkleEffect {
    pub fn new(bg_color: Color, sparkle_color: Color, sparkle_delay_ms: f32, speed_ms: f32) -> Self {
        Self {
            bg_color,
            sparkle_color,
            sparkle_delay_ms,
            speed_ms,
            state: SnowState::Waiting { timer: 0.0 },
        }
    }
}

impl Effect for SnowSparkleEffect {
    fn name(&self) -> &'static str { "Snow Sparkle" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        let n = buffer.len();
        let dt_ms = delta.as_secs_f32() * 1000.0;

        for pixel in buffer.iter_mut() {
            *pixel = self.bg_color;
        }

        let mut rng = rand::thread_rng();

        self.state = match self.state {
            SnowState::Sparkling { pos, timer } => {
                buffer[pos] = self.sparkle_color;
                let new_timer = timer + dt_ms;
                if new_timer >= self.sparkle_delay_ms {
                    SnowState::Waiting { timer: new_timer - self.sparkle_delay_ms }
                } else {
                    SnowState::Sparkling { pos, timer: new_timer }
                }
            }
            SnowState::Waiting { timer } => {
                let new_timer = timer + dt_ms;
                if new_timer >= self.speed_ms {
                    let pos = rng.gen_range(0..n);
                    SnowState::Sparkling { pos, timer: new_timer - self.speed_ms }
                } else {
                    SnowState::Waiting { timer: new_timer }
                }
            }
        };

        true
    }
}

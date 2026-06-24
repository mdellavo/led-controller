use std::time::Duration;
use rand::Rng;
use crate::effects::{Effect, Buffer};
use crate::pixels::Color;

enum EyeState {
    Holding,
    Fading,
    Pausing,
}

pub struct HalloweenEyesEffect {
    color: Color,
    eye_width: usize,
    eye_spacing: usize,
    fade_steps: u32,
    fade_delay_ms: f32,
    end_pause_ms: f32,
    state: EyeState,
    eye_pos: usize,
    fade_step: u32,
    timer: f32,
}

impl HalloweenEyesEffect {
    pub fn new(
        color: Color,
        eye_width: usize,
        eye_spacing: usize,
        fade_steps: u32,
        fade_delay_ms: f32,
        end_pause_ms: f32,
    ) -> Self {
        Self {
            color,
            eye_width,
            eye_spacing,
            fade_steps,
            fade_delay_ms,
            end_pause_ms,
            state: EyeState::Holding,
            eye_pos: 0,
            fade_step: 0,
            timer: 0.0,
        }
    }

    fn total_eye_width(&self) -> usize {
        self.eye_width * 2 + self.eye_spacing
    }

    fn draw_eyes(&self, buffer: &mut Buffer, brightness: f32) {
        let color = self.color.map(|c| (c as f32 * brightness) as u8);
        for i in 0..self.eye_width {
            let left = self.eye_pos + i;
            let right = self.eye_pos + self.eye_width + self.eye_spacing + i;
            if left < buffer.len() { buffer[left] = color; }
            if right < buffer.len() { buffer[right] = color; }
        }
    }

    fn pick_random_pos(&mut self, num_pixels: usize) {
        let span = self.total_eye_width();
        if num_pixels > span {
            self.eye_pos = rand::thread_rng().gen_range(0..num_pixels - span);
        } else {
            self.eye_pos = 0;
        }
    }
}

impl Effect for HalloweenEyesEffect {
    fn name(&self) -> &'static str { "Halloween Eyes" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        let n = buffer.len();
        self.timer += delta.as_secs_f32() * 1000.0;

        for pixel in buffer.iter_mut() {
            *pixel = [0, 0, 0];
        }

        match self.state {
            EyeState::Holding => {
                self.draw_eyes(buffer, 1.0);
                // Hold for one fade_delay_ms period before starting fade
                if self.timer >= self.fade_delay_ms * 5.0 {
                    self.timer = 0.0;
                    self.fade_step = 0;
                    self.state = EyeState::Fading;
                }
            }
            EyeState::Fading => {
                if self.timer >= self.fade_delay_ms {
                    self.timer -= self.fade_delay_ms;
                    self.fade_step += 1;
                }
                let brightness = if self.fade_step >= self.fade_steps {
                    0.0
                } else {
                    1.0 - (self.fade_step as f32 / self.fade_steps as f32)
                };
                self.draw_eyes(buffer, brightness);
                if self.fade_step >= self.fade_steps {
                    self.state = EyeState::Pausing;
                }
            }
            EyeState::Pausing => {
                if self.timer >= self.end_pause_ms {
                    self.timer -= self.end_pause_ms;
                    self.pick_random_pos(n);
                    self.state = EyeState::Holding;
                }
            }
        }

        true
    }
}

use std::time::Duration;
use crate::effects::{Effect, Buffer, plot};
use crate::pixels::Color;

const DEFAULT_COLORS: &[Color] = &[
    [255, 0, 0],
    [0, 255, 0],
    [0, 0, 255],
    [255, 255, 0],
    [0, 255, 255],
    [255, 0, 255],
];

struct Ball {
    color: Color,
    height: f32,
    velocity: f32,
    dampening: f32,
}

pub struct BouncingBallsEffect {
    balls: Vec<Ball>,
}

impl BouncingBallsEffect {
    pub fn new(colors: Vec<Color>, ball_count: usize) -> Self {
        let ball_colors: Vec<Color> = if colors.is_empty() {
            let n = ball_count.min(DEFAULT_COLORS.len());
            DEFAULT_COLORS[..n].to_vec()
        } else {
            colors
        };

        let balls = ball_colors
            .into_iter()
            .enumerate()
            .map(|(i, color)| Ball {
                color,
                height: 1.0,
                velocity: -((i as f32 + 1.0) * 0.5),
                dampening: 0.85 + (i as f32 * 0.02).min(0.1),
            })
            .collect();

        Self { balls }
    }
}

impl Effect for BouncingBallsEffect {
    fn name(&self) -> &'static str { "Bouncing Balls" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        let n = buffer.len();
        let dt = delta.as_secs_f32();
        // gravity scaled to strip length so a ball takes ~1s to fall the full strip
        let gravity = -9.8 * n as f32 * 0.01;

        for pixel in buffer.iter_mut() {
            *pixel = [0, 0, 0];
        }

        for ball in self.balls.iter_mut() {
            ball.velocity += gravity * dt;
            ball.height += ball.velocity * dt;

            if ball.height <= 0.0 {
                ball.height = 0.0;
                ball.velocity = -ball.velocity * ball.dampening;
                // prevent balls from getting stuck due to float precision
                if ball.velocity.abs() < 0.01 {
                    ball.velocity = 1.0;
                }
            }

            ball.height = ball.height.clamp(0.0, 1.0);
            let pos = (1.0 - ball.height) * (n - 1) as f32;
            plot(buffer, pos, ball.color, 1.0);
        }

        true
    }
}

use std::time::Duration;
use rand::Rng;
use crate::effects::{Effect, Buffer, fade_buffer};
use crate::pixels::Color;

struct Spark {
    index: usize,
    color: Color,
    life: f32,
    max_life: f32,
}

pub struct RandomFadeEffect {
    sparks: Vec<Spark>,
    spawn_timer: f32,
    spawn_interval: f32,
    num_pixels: usize,
}

impl RandomFadeEffect {
    pub fn new(num_pixels: usize) -> Self {
        Self {
            sparks: Vec::new(),
            spawn_timer: 0.0,
            spawn_interval: 0.1,
            num_pixels,
        }
    }
}

impl Effect for RandomFadeEffect {
    fn name(&self) -> &'static str { "Random Fade" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        let dt = delta.as_secs_f32();
        let mut rng = rand::thread_rng();

        self.spawn_timer += dt;
        while self.spawn_timer >= self.spawn_interval {
            self.spawn_timer -= self.spawn_interval;
            self.sparks.push(Spark {
                index: rng.gen_range(0..self.num_pixels),
                color: [rng.gen(), rng.gen(), rng.gen()],
                life: 0.0,
                max_life: rng.gen_range(0.5..2.5),
            });
        }

        // decay all pixels — delta-time correct, equivalent to * 0.90 per frame at 60 fps
        fade_buffer(buffer, 0.90_f32.powf(60.0), dt);

        self.sparks.retain_mut(|spark| {
            spark.life += dt;
            if spark.life >= spark.max_life {
                return false;
            }
            let t = spark.life / spark.max_life;
            // ramp up then ramp down
            let brightness = if t < 0.3 { t / 0.3 } else { 1.0 - (t - 0.3) / 0.7 };
            buffer[spark.index] = spark.color.map(|c| (c as f32 * brightness) as u8);
            true
        });

        true
    }
}

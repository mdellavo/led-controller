pub type Color = [u8; 3];

pub trait PixelStrip: Send + 'static {
    fn set(&mut self, index: usize, color: Color);
    fn len(&self) -> usize;
    fn show(&mut self);
    #[allow(dead_code)]
    fn fill(&mut self, color: Color) {
        for i in 0..self.len() {
            self.set(i, color);
        }
    }
}

pub struct NullPixels {
    count: usize,
    buffer: Vec<Color>,
}

impl NullPixels {
    pub fn new(count: usize) -> Self {
        Self { count, buffer: vec![[0, 0, 0]; count] }
    }
}

impl PixelStrip for NullPixels {
    fn set(&mut self, index: usize, color: Color) {
        self.buffer[index] = color;
    }
    fn len(&self) -> usize { self.count }
    fn show(&mut self) {
        let preview: Vec<String> = self.buffer.iter().take(6)
            .map(|[r, g, b]| format!("#{:02x}{:02x}{:02x}", r, g, b))
            .collect();
        tracing::debug!(
            pixels = self.count,
            preview = %preview.join(" "),
            "show"
        );
    }
}

#[cfg(feature = "hardware")]
pub mod hardware {
    use super::*;
    use rs_ws281x::{ControllerBuilder, ChannelBuilder, StripType};

    pub struct NeoPixelStrip {
        controller: rs_ws281x::Controller,
        count: usize,
    }

    impl NeoPixelStrip {
        pub fn new(pin: i32, count: usize, brightness: u8) -> anyhow::Result<Self> {
            let controller = ControllerBuilder::new()
                .freq(800_000)
                .dma(5)
                .channel(
                    0,
                    ChannelBuilder::new()
                        .pin(pin)
                        .count(count as i32)
                        .strip_type(StripType::Ws2812)
                        .brightness(brightness)
                        .build(),
                )
                .build()?;
            Ok(Self { controller, count })
        }
    }

    impl PixelStrip for NeoPixelStrip {
        fn set(&mut self, index: usize, color: Color) {
            let leds = self.controller.leds_mut(0);
            // rs_ws281x uses [r, g, b, w] format
            leds[index] = [color[0], color[1], color[2], 0];
        }
        fn len(&self) -> usize { self.count }
        fn show(&mut self) {
            self.controller.render().ok();
        }
    }
}

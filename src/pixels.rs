pub type Color = [u8; 3];

/// Maps logical [r, g, b] to the physical byte order the strip expects.
/// Stored as indices into the source color: e.g. GRB = [1, 0, 2].
#[derive(Clone, Copy, Debug)]
pub struct ColorOrder([u8; 3]);

impl ColorOrder {
    pub fn parse(s: &str) -> anyhow::Result<Self> {
        let lower = s.to_ascii_lowercase();
        if lower.len() != 3 {
            anyhow::bail!("color order must be exactly 3 characters (e.g. 'rgb', 'grb', 'bgr')");
        }
        let mut indices = [0u8; 3];
        for (i, ch) in lower.chars().enumerate() {
            indices[i] = match ch {
                'r' => 0,
                'g' => 1,
                'b' => 2,
                _ => anyhow::bail!("invalid character '{}' in color order — use r, g, b only", ch),
            };
        }
        Ok(Self(indices))
    }

    #[inline]
    pub fn apply(self, color: Color) -> Color {
        [color[self.0[0] as usize], color[self.0[1] as usize], color[self.0[2] as usize]]
    }
}

impl Default for ColorOrder {
    fn default() -> Self { Self([0, 1, 2]) } // RGB passthrough
}

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
    color_order: ColorOrder,
}

impl NullPixels {
    pub fn new(count: usize, color_order: ColorOrder) -> Self {
        Self { count, buffer: vec![[0, 0, 0]; count], color_order }
    }
}

impl PixelStrip for NullPixels {
    fn set(&mut self, index: usize, color: Color) {
        self.buffer[index] = self.color_order.apply(color);
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
        color_order: ColorOrder,
    }

    impl NeoPixelStrip {
        pub fn new(pin: i32, count: usize, brightness: u8, color_order: ColorOrder) -> anyhow::Result<Self> {
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
            Ok(Self { controller, count, color_order })
        }
    }

    // rs_ws281x::Controller holds raw C pointers which Rust marks non-Send by default.
    // Safety: the runner owns the strip exclusively on a single thread at all times.
    unsafe impl Send for NeoPixelStrip {}

    impl PixelStrip for NeoPixelStrip {
        fn set(&mut self, index: usize, color: Color) {
            let leds = self.controller.leds_mut(0);
            let c = self.color_order.apply(color);
            leds[index] = [c[0], c[1], c[2], 0];
        }
        fn len(&self) -> usize { self.count }
        fn show(&mut self) {
            self.controller.render().ok();
        }
    }
}

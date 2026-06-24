# LED Controller

A Rust web server for controlling WS2812B LED strips (NeoPixels) on a Raspberry Pi. Effects run in their own threads, transitions between effects are crossfaded, and everything is controllable from a browser.

## Features

- Web control panel: start, stop, next effect, effect picker, playlist shuffle
- Smooth transitions: fade in on start, fade out on stop, crossfade when switching effects
- Each effect runs in its own OS thread
- Pluggable effect system — add a new effect in one file
- `NullPixels` dev mode (no hardware required) with debug logging
- Single binary deployment — no runtime dependencies beyond the binary itself

## Hardware

- Raspberry Pi (any model with GPIO)
- WS2812B / NeoPixel LED strip connected to **GPIO 18** (PWM0)
- The `rpi_ws281x` C library must be installed on the Pi:

```bash
sudo apt install -y build-essential python3-dev swig python3-setuptools
git clone https://github.com/jgarff/rpi_ws281x
cd rpi_ws281x && mkdir build && cd build
cmake -D BUILD_SHARED=OFF -D BUILD_TEST=OFF ..
cmake --build .
sudo make install
```

## Running

### Development (no hardware)

```bash
cargo run
```

The server starts on `http://localhost:3000`. Pixel output is logged at `DEBUG` level, showing the first 6 pixel colors as hex on each frame:

```bash
RUST_LOG=led_controller=debug cargo run
```

### Cross-compiling for the Raspberry Pi

Use `build-pi.sh`, which wraps [`cross`](https://github.com/cross-rs/cross) (Docker-based cross compilation). `cross` handles the C toolchain needed for the `hardware` feature automatically.

**Prerequisites:**

```bash
cargo install cross
# Docker must be installed and running
```

**Build and deploy in one step:**

```bash
./build-pi.sh --deploy pi@raspberrypi.local
```

**Build only:**

```bash
./build-pi.sh
# binary at target/aarch64-unknown-linux-gnu/release/led-controller
```

**32-bit Raspberry Pi OS (Pi 2/3/4 running 32-bit):**

```bash
./build-pi.sh --target armv7-unknown-linux-gnueabihf --deploy pi@raspberrypi.local
```

**Dev build (NullPixels, no C library dependency):**

```bash
./build-pi.sh --no-hardware --deploy pi@raspberrypi.local
```

| Flag | Default | Description |
|---|---|---|
| `--target <triple>` | `aarch64-unknown-linux-gnu` | Rust target triple |
| `--no-hardware` | off | Build without the hardware feature (NullPixels) |
| `--deploy user@host` | — | SCP the binary to the Pi after building |

### On the Raspberry Pi

Once the binary is deployed:

```bash
sudo ~/led-controller
```

`sudo` is required for GPIO/DMA access. The server listens on `0.0.0.0:3000` — open `http://<pi-ip>:3000` from any device on the network.

### Running as a systemd service

```ini
# /etc/systemd/system/leds.service
[Unit]
Description=LED Controller
After=network.target

[Service]
ExecStart=/home/pi/led-controller/led-controller
WorkingDirectory=/home/pi/led-controller
Restart=on-failure
User=root

[Install]
WantedBy=multi-user.target
```

```bash
sudo systemctl enable --now leds
```

## Configuration

All options are set via command-line flags. Defaults are shown below:

```
Usage: led-controller [OPTIONS]

Options:
      --pixels <PIXELS>              Number of LEDs in the strip [default: 60]
      --gpio-pin <GPIO_PIN>          GPIO pin number (hardware feature only) [default: 18]
      --brightness <BRIGHTNESS>      LED brightness 0–255 (hardware feature only) [default: 25]
      --port <PORT>                  Port to listen on [default: 3000]
      --fade-in-ms <FADE_IN_MS>      Fade-in duration in milliseconds [default: 3000]
      --fade-out-ms <FADE_OUT_MS>    Fade-out duration in milliseconds [default: 3000]
      --crossfade-ms <CROSSFADE_MS>  Crossfade duration in milliseconds [default: 3000]
  -h, --help                         Print help
```

Example — 144-pixel strip on GPIO 12, brighter, 5 s crossfades:

```bash
sudo ./led-controller --pixels 144 --gpio-pin 12 --brightness 80 --crossfade-ms 5000
```

Fade durations can also be adjusted live from the web UI without restarting.

## API

All endpoints accept/return JSON.

### `GET /api/state`

Returns current runner state:

```json
{
  "is_running": true,
  "current_effect": "Rainbow",
  "transition": "crossfading",
  "playlist": ["Rainbow", "Chase", "Sparkle", "Random Fade"],
  "playlist_index": 1,
  "effects": ["Rainbow", "Random Fade", "Chase", "Sparkle", "Solid Red", "..."],
  "fade_in_ms": 3000,
  "fade_out_ms": 3000,
  "crossfade_ms": 3000
}
```

`transition` is `"fading_in"`, `"fading_out"`, `"crossfading"`, or `null`.

### `POST /api/command`

```json
{ "action": "<action>", "effect": "<name>", "value_ms": 2000 }
```

| Action | Extra fields | Description |
|---|---|---|
| `start` | — | Start / resume from current playlist position |
| `stop` | — | Fade out and stop |
| `next` | — | Crossfade to the next effect in the playlist |
| `select` | `effect` | Crossfade to a named effect |
| `randomize` | — | Shuffle the playlist and restart from position 0 |
| `set_fade_in` | `value_ms` | Set fade-in duration in milliseconds |
| `set_fade_out` | `value_ms` | Set fade-out duration in milliseconds |
| `set_crossfade` | `value_ms` | Set crossfade duration in milliseconds |

## Adding an effect

1. Create `src/effects/myeffect.rs`:

```rust
use std::time::Duration;
use crate::effects::{Effect, Buffer};

pub struct MyEffect {
    time: f32,
}

impl MyEffect {
    pub fn new() -> Self { Self { time: 0.0 } }
}

impl Effect for MyEffect {
    fn name(&self) -> &'static str { "My Effect" }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        self.time += delta.as_secs_f32();
        for (i, pixel) in buffer.iter_mut().enumerate() {
            // write RGB values to each pixel
            *pixel = [0, 0, 0];
        }
        true // return false to signal natural completion
    }
}
```

2. Register it in `src/effects/mod.rs`:

```rust
pub mod myeffect;

pub fn default_registry(num_pixels: usize) -> EffectRegistry {
    let mut r = EffectRegistry::new();
    // ... existing effects ...
    r.register("My Effect", || Box::new(myeffect::MyEffect::new()));
    r
}
```

That's it. The effect appears in the web UI dropdown and playlist immediately.

## Project structure

```
src/
├── main.rs              entry point — wires Axum server and runner
├── pixels.rs            PixelStrip trait, NullPixels, hardware NeoPixelStrip
├── runner.rs            effect thread management, fade/crossfade state machine
├── api.rs               Axum route handlers
└── effects/
    ├── mod.rs           Effect trait, EffectRegistry, default_registry()
    ├── rainbow.rs       full-strip color wheel sweep
    ├── fade.rs          random sparks that ignite and decay
    ├── chase.rs         color comet with fading tail
    ├── sparkle.rs       white twinkle with smooth brightness
    └── solid.rs         static solid color
static/
├── index.html           control panel (embedded in binary via include_str!)
└── app.js               frontend JS (embedded in binary via include_str!)
```

## Transition behavior

| Situation | Transition |
|---|---|
| Start from stopped | Fade in from black over `fade_in_ms` |
| Stop while running | Fade out to black over `fade_out_ms` |
| Switch effects while running | Both effect threads run simultaneously; pixel buffers are per-pixel lerped over `crossfade_ms` |
| Switch again mid-crossfade | Outgoing effect is dropped; new effect crossfades from the current blended frame |
| Stop mid-crossfade | Incoming effect fades out from its current blend position |

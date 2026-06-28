# LED Controller

A Rust web server for controlling WS2812B LED strips (NeoPixels) on a Raspberry Pi. Effects run in their own threads, transitions between effects are crossfaded, and everything is controllable from a browser.

## Features

- Web control panel: start, stop, next, effect picker, playlist management
- Smooth transitions: fade in on start, fade out on stop, crossfade when switching effects — each with a configurable duration (default 3 s)
- Auto-advance: configurable per-effect play time before moving to the next playlist entry
- Full playlist management: add, remove, drag-to-reorder, shuffle
- 23 built-in effects (see below)
- Each effect runs in its own OS thread
- Pluggable effect system — add a new effect in one file
- `NullPixels` dev mode (no hardware required) with debug logging
- Single binary deployment — no runtime dependencies on the target beyond the binary itself

## Hardware

- Raspberry Pi (any model with GPIO)
- WS2812B / NeoPixel LED strip connected to **GPIO 18** (PWM0)
- The `rpi_ws281x` C library must be installed on the Pi:

```mermaid
graph LR
    PI["🍓 Raspberry Pi"]

    subgraph LS["Level Shifter (BSS138)"]
        direction TB
        LV["LV — 3.3V ref"]
        LGND["GND"]
        LV1["LV1 — data in"]
        HV["HV — 5V ref"]
        HGND["GND"]
        HV1["HV1 — data out"]
    end

    LED["💡 WS2812B LED strip"]
    PSU["🔌 5V Power Supply"]

    PI -->|"3.3V"| LV
    PI -->|"GND"| LGND
    PI -->|"GPIO18"| LV1

    HV1 -->|"DIN"| LED

    PSU -->|"5V ref"| HV
    PSU -->|"shared GND"| HGND
    PSU -->|"5V VCC"| LED
    PSU -->|"GND"| LED
```

```bash
sudo apt install -y build-essential cmake libclang-dev
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

**Pass app flags through with `--`:**

```bash
./build-pi.sh --deploy pi@raspberrypi.local -- --pixels 144 --brightness 80 --crossfade-ms 5000
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

Script flags (before `--`):

| Flag | Default | Description |
|---|---|---|
| `--target <triple>` | `aarch64-unknown-linux-gnu` | Rust target triple |
| `--no-hardware` | off | Build without the hardware feature (NullPixels) |
| `--deploy user@host` | — | SCP the binary to the Pi after building |

App flags (after `--`, passed through to the binary):

| Flag | Default | Description |
|---|---|---|
| `--pixels <n>` | `60` | Number of LEDs in the strip |
| `--gpio-pin <n>` | `18` | GPIO pin number |
| `--brightness <n>` | `25` | LED brightness 0–255 |
| `--port <n>` | `3000` | Port to listen on |
| `--fade-in-ms <n>` | `3000` | Fade-in duration in milliseconds |
| `--fade-out-ms <n>` | `3000` | Fade-out duration in milliseconds |
| `--crossfade-ms <n>` | `3000` | Crossfade duration in milliseconds |
| `--effect-duration-ms <n>` | `0` | Time each effect plays before auto-advancing (0 = infinite) |
| `--color-order <str>` | `rgb` | Physical color channel order of the strip (e.g. `rgb`, `grb`, `bgr`) |
| `--speed <n>` | `1.0` | Effect speed multiplier (0.1 = very slow, 1.0 = normal, 4.0 = very fast) |
| `--brightness-scale <n>` | `1.0` | Software brightness scale 0.0–1.0 applied to all pixel output |

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
ExecStart=/home/pi/led-controller --effect-duration-ms 30000
WorkingDirectory=/home/pi
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
      --pixels <PIXELS>                      Number of LEDs in the strip [default: 60]
      --gpio-pin <GPIO_PIN>                  GPIO pin number (hardware feature only) [default: 18]
      --brightness <BRIGHTNESS>              LED brightness 0–255 (hardware feature only) [default: 25]
      --port <PORT>                          Port to listen on [default: 3000]
      --fade-in-ms <FADE_IN_MS>              Fade-in duration in milliseconds [default: 3000]
      --fade-out-ms <FADE_OUT_MS>            Fade-out duration in milliseconds [default: 3000]
      --crossfade-ms <CROSSFADE_MS>          Crossfade duration in milliseconds [default: 3000]
      --effect-duration-ms <EFFECT_DUR_MS>   Time per effect before auto-advancing (0 = infinite) [default: 0]
      --color-order <COLOR_ORDER>            Physical color channel order of the strip [default: rgb]
      --speed <SPEED>                        Effect speed multiplier [default: 1.0]
      --brightness-scale <BRIGHTNESS_SCALE>  Software brightness scale 0.0–1.0 [default: 1.0]
  -h, --help                                 Print help
```

Example — 144-pixel strip on GPIO 12, 30 s per effect with 5 s crossfades:

```bash
sudo ./led-controller --pixels 144 --gpio-pin 12 --brightness 80 --effect-duration-ms 30000 --crossfade-ms 5000
```

All timing values can also be adjusted live from the web UI without restarting.

## Web UI

Open `http://<pi-ip>:3000` in a browser.

| Section | Controls |
|---|---|
| **Status** | Coloured dot (green = running, amber = transitioning, grey = stopped) + current effect name |
| **Controls** | Start, Next, Stop |
| **Select Effect** | Dropdown of all registered effects + Play button to jump to it immediately |
| **Playlist** | Ordered list of effects to cycle through. Drag `⠿` to reorder, click `✕` to remove, click effect name to play it. Dropdown + **Add** to append any effect. **Shuffle** to randomise order. |
| **Speed** | Multiplier applied to every effect's time delta (0.1× – 4.0×, live) |
| **Brightness** | Software brightness scale applied to all pixel output (0–100%, live) |
| **Effect Duration** | How long each effect plays before auto-advancing (0 = manual only) |
| **Transition Durations** | Separate sliders for fade-in, crossfade, and fade-out |

## Effects

| Effect | Description |
|---|---|
| Rainbow | Full-strip colour wheel sweep |
| Random Fade | Sparks that ignite and decay at random positions |
| Chase | Colour comet with a fading tail |
| Sparkle | White twinkle with smooth per-pixel brightness transitions |
| Strobe / Strobe Red | Rapid flash burst followed by a pause |
| Cylon | Larson scanner — bright eye bouncing left↔right with a fading tail |
| KITT | Centre-outward Larson scanner |
| Halloween Eyes | Pair of glowing eyes that appear at a random position and fade out |
| Twinkle | Random pixels lit in a fixed colour |
| Random Twinkle | Random pixels each with a random colour |
| Snow Sparkle | Dim white background with bright white sparkles |
| Running Lights | Sine-wave brightness pattern chasing along the strip |
| Color Wipe Red/Green/Blue | Sequential pixel fill then clear, looping |
| Theatre Chase | Every 3rd pixel marching, theatre-marquee style |
| Theatre Chase Rainbow | Theatre chase with rainbow colour cycling |
| Fire | Realistic flame simulation with cooling and sparking physics |
| Bouncing Balls | Gravity-physics balls bouncing on a vertical strip |
| Meteor Rain | Meteor with a glowing decaying tail |
| Solid Red/Green/Blue/White | Static solid colour |

## API

All endpoints accept/return JSON.

### `GET /api/state`

```json
{
  "is_running": true,
  "current_effect": "Rainbow",
  "transition": "crossfading",
  "playlist": ["Rainbow", "Fire", "Meteor Rain"],
  "playlist_index": 1,
  "effects": ["Rainbow", "Random Fade", "Chase", "..."],
  "fade_in_ms": 3000,
  "fade_out_ms": 3000,
  "crossfade_ms": 3000,
  "effect_duration_ms": 30000,
  "speed": 1.0,
  "brightness": 1.0
}
```

`transition` is `"fading_in"`, `"fading_out"`, `"crossfading"`, or `null`.

### `POST /api/command`

```json
{ "action": "<action>", "effect": "<name>", "value_ms": 2000, "value": 1.5, "index": 0, "to_index": 3 }
```

| Action | Extra fields | Description |
|---|---|---|
| `start` | — | Start / resume from current playlist position |
| `stop` | — | Fade out and stop |
| `next` | — | Crossfade to the next effect in the playlist |
| `select` | `effect` | Crossfade to a named effect |
| `randomize` | — | Shuffle the playlist and restart from position 0 |
| `add_to_playlist` | `effect` | Append a named effect to the playlist |
| `remove_from_playlist` | `index` | Remove the effect at the given playlist position |
| `move_in_playlist` | `index`, `to_index` | Move a playlist item to a new position |
| `set_fade_in` | `value_ms` | Set fade-in duration |
| `set_fade_out` | `value_ms` | Set fade-out duration |
| `set_crossfade` | `value_ms` | Set crossfade duration |
| `set_effect_duration` | `value_ms` | Set per-effect play time (0 = infinite) |
| `set_speed` | `value` | Set speed multiplier (float, 0.1–4.0) |
| `set_brightness` | `value` | Set software brightness scale (float, 0.0–1.0) |

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
        for pixel in buffer.iter_mut() {
            *pixel = [0, 0, 0]; // write RGB values
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

The effect appears in the web UI dropdown and playlist immediately.

## Project structure

```
src/
├── main.rs              entry point — parses CLI flags, wires Axum server and runner
├── pixels.rs            PixelStrip trait, NullPixels (dev), NeoPixelStrip (hardware)
├── runner.rs            effect thread management, fade/crossfade state machine, playlist
├── api.rs               Axum route handlers
└── effects/
    ├── mod.rs           Effect trait, EffectRegistry, default_registry()
    ├── rainbow.rs       full-strip colour wheel sweep
    ├── fade.rs          random sparks that ignite and decay
    ├── chase.rs         colour comet with fading tail
    ├── sparkle.rs       white twinkle with smooth brightness
    ├── solid.rs         static solid colour
    ├── strobe.rs        rapid flash burst
    ├── cylon.rs         Larson scanner (Cylon + KITT variants)
    ├── halloween_eyes.rs glowing eyes that appear and fade
    ├── twinkle.rs       random pixel twinkle (fixed + random colour)
    ├── snow_sparkle.rs  dim background with bright sparkles
    ├── running_lights.rs sine-wave brightness chase
    ├── color_wipe.rs    sequential pixel fill
    ├── theatre_chase.rs theatre-marquee march (solid + rainbow)
    ├── fire.rs          flame simulation
    ├── bouncing_balls.rs gravity-physics bouncing balls
    └── meteor.rs        meteor with decaying tail
static/
├── index.html           control panel (embedded in binary via include_str!)
└── app.js               frontend JS (embedded in binary via include_str!)
```

## Roadmap / ideas

### Hardware / control
- **Gamma correction** — apply a gamma lookup table at the hardware write so brightness changes feel perceptually smooth rather than steppy
- **Per-effect color palette** — let effects draw from a user-chosen set of colors rather than hard-coded values
- **Segmented effects** — run different effects on different sections of the strip simultaneously

### UI / usability
- **Saved presets** — name and store a (effect + speed + brightness + duration) configuration to recall later
- **Persist state across restarts** — write current state to a small JSON file so the strip comes back in its last state after a reboot or power cut
- **Dimming schedule** — automatically dim or turn off at a configured time (e.g. midnight), useful for permanent installs
- **Mobile touch targets** — larger sliders and buttons for comfortable use on a small touchscreen
- **Basic auth** — single username/password so the UI is not open to everyone on the local network

### Effects
- **Audio reactive** — sample a USB mic/dongle and drive brightness or color from beat detection or amplitude
- **Custom color picker** — choose the color for solid/wipe/chase effects from the UI without editing code

### Performance / architecture
- **WebSocket push** — replace the 500 ms poll with a WebSocket connection for instant UI updates and lower CPU use on the Pi

## Transition behavior

| Situation | Result |
|---|---|
| Start from stopped | Fade in from black over `fade_in_ms` |
| Stop while running | Fade out to black over `fade_out_ms` |
| Switch effects while running | Both effect threads run simultaneously; buffers are per-pixel lerped over `crossfade_ms` |
| Switch again mid-crossfade | Outgoing effect dropped; new effect crossfades from the current blended frame |
| Stop mid-crossfade | Incoming effect fades out from its current blend position |
| Effect duration expires | Auto-crossfade to next playlist entry; timer resets when effect reaches full Running state |

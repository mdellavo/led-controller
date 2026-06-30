use std::sync::{Arc, RwLock, atomic::{AtomicU8, Ordering}};
use std::time::Duration;

use mlua::prelude::*;

use crate::audio::AudioAnalysis;
use crate::effects::{Buffer, Effect};

// --------------------------------------------------------------------------
// LuaBuf — pixel buffer exposed to scripts as a userdata object.
// One instance lives in the Lua VM's globals and persists across frames,
// so scripts can read previous values for trail-decay effects.
// --------------------------------------------------------------------------

struct LuaBuf {
    pixels: Vec<[u8; 3]>,
}

impl LuaUserData for LuaBuf {
    fn add_methods<M: LuaUserDataMethods<Self>>(methods: &mut M) {
        // len() -> integer
        methods.add_method("len", |_, this, ()| Ok(this.pixels.len()));

        // get(i) -> r, g, b
        methods.add_method("get", |_, this, i: usize| {
            let p = this.pixels.get(i).copied().unwrap_or([0; 3]);
            Ok((p[0], p[1], p[2]))
        });

        // set(i, r, g, b)
        methods.add_method_mut("set", |_, this, (i, r, g, b): (usize, u8, u8, u8)| {
            if let Some(p) = this.pixels.get_mut(i) {
                *p = [r, g, b];
            }
            Ok(())
        });

        // clear() — fill all pixels black
        methods.add_method_mut("clear", |_, this, ()| {
            for p in &mut this.pixels {
                *p = [0; 3];
            }
            Ok(())
        });

        // plot(pos, r, g, b, alpha)
        // Sub-pixel antialiased additive write. `pos` is a float pixel index
        // and wraps around the strip via rem_euclid, so callers don't need to
        // guard bounds themselves.
        methods.add_method_mut(
            "plot",
            |_, this, (pos, r, g, b, alpha): (f32, u8, u8, u8, f32)| {
                let n = this.pixels.len();
                if n == 0 {
                    return Ok(());
                }
                let p = pos.rem_euclid(n as f32);
                let lo = p.floor() as usize;
                let frac = p.fract();
                let hi = (lo + 1) % n;
                let col = [r, g, b];
                for c in 0..3 {
                    this.pixels[lo][c] = (this.pixels[lo][c] as f32
                        + col[c] as f32 * alpha * (1.0 - frac))
                        .min(255.0) as u8;
                    this.pixels[hi][c] = (this.pixels[hi][c] as f32
                        + col[c] as f32 * alpha * frac)
                        .min(255.0) as u8;
                }
                Ok(())
            },
        );

        // fade(per_second, dt)
        // Delta-time correct multiplicative decay: multiplies every channel by
        // per_second^dt, keeping fade speed consistent regardless of frame rate.
        methods.add_method_mut("fade", |_, this, (per_second, dt): (f32, f32)| {
            let factor = per_second.powf(dt);
            for p in &mut this.pixels {
                for ch in p {
                    *ch = (*ch as f32 * factor) as u8;
                }
            }
            Ok(())
        });
    }
}

// --------------------------------------------------------------------------
// LuaEffect
// --------------------------------------------------------------------------

pub struct LuaEffect {
    name: &'static str,
    lua: Lua,
    user_color: Arc<[AtomicU8; 3]>,
    palette: Arc<RwLock<Vec<[u8; 3]>>>,
    audio: Arc<AudioAnalysis>,
}

impl LuaEffect {
    pub fn new(
        name: &'static str,
        source: String,
        num_pixels: usize,
        user_color: Arc<[AtomicU8; 3]>,
        palette: Arc<RwLock<Vec<[u8; 3]>>>,
        audio: Arc<AudioAnalysis>,
    ) -> Self {
        let lua = Lua::new();

        // Load and execute the script so globals / closures are defined.
        if let Err(e) = lua.load(&source).exec() {
            tracing::error!("[{}] load error: {e}", name);
        }

        // NUM_PIXELS constant available to scripts without calling buf:len().
        let _ = lua.globals().set("NUM_PIXELS", num_pixels);

        // Create the buffer userdata and store it as the global `buffer`.
        match lua.create_userdata(LuaBuf { pixels: vec![[0; 3]; num_pixels] }) {
            Ok(ud) => {
                let _ = lua.globals().set("buffer", ud);
            }
            Err(e) => tracing::error!("[{}] failed to create buffer userdata: {e}", name),
        }

        // Call the optional init(num_pixels) hook.
        if let Ok(init) = lua.globals().get::<LuaFunction>("init") {
            if let Err(e) = init.call::<()>(num_pixels) {
                tracing::warn!("[{}] init() error: {e}", name);
            }
        }

        Self { name, lua, user_color, palette, audio }
    }

    /// Run the script in a throw-away VM to read its `name` and `description` globals.
    pub fn probe_metadata(source: &str) -> (Option<String>, Option<String>) {
        let lua = Lua::new();
        if lua.load(source).exec().is_err() {
            return (None, None);
        }
        let name = lua.globals().get::<String>("name").ok();
        let desc = lua.globals().get::<String>("description").ok();
        (name, desc)
    }

    #[allow(dead_code)]
    pub fn probe_name(source: &str) -> Option<String> {
        Self::probe_metadata(source).0
    }
}

impl Effect for LuaEffect {
    fn name(&self) -> &'static str {
        self.name
    }

    fn update(&mut self, buffer: &mut Buffer, delta: Duration) -> bool {
        let dt = delta.as_secs_f32();

        // Inject user color globals so Lua effects can read COLOR_R/G/B.
        let r = self.user_color[0].load(Ordering::Relaxed);
        let g = self.user_color[1].load(Ordering::Relaxed);
        let b = self.user_color[2].load(Ordering::Relaxed);
        let _ = self.lua.globals().set("COLOR_R", r as u32);
        let _ = self.lua.globals().set("COLOR_G", g as u32);
        let _ = self.lua.globals().set("COLOR_B", b as u32);

        // Inject palette globals: PALETTE (1-indexed table of {r,g,b}) and PALETTE_SIZE.
        let palette_snap: Vec<[u8; 3]> = self.palette.read()
            .map(|g| g.clone())
            .unwrap_or_default();
        if let Ok(pal_table) = self.lua.create_table() {
            for (i, &[pr, pg, pb]) in palette_snap.iter().enumerate() {
                if let Ok(entry) = self.lua.create_table() {
                    let _ = entry.set(1, pr as u32);
                    let _ = entry.set(2, pg as u32);
                    let _ = entry.set(3, pb as u32);
                    let _ = pal_table.set(i + 1, entry);
                }
            }
            let _ = self.lua.globals().set("PALETTE", pal_table);
        }
        let _ = self.lua.globals().set("PALETTE_SIZE", palette_snap.len() as u32);

        // Inject audio globals: AUDIO_AMP, AUDIO_BEAT, AUDIO_BASS, AUDIO_MID,
        // AUDIO_HIGH, AUDIO_SPECTRUM[16]. All values are 0.0 when no device is active.
        let _ = self.lua.globals().set("AUDIO_AMP",  f32::from_bits(self.audio.amplitude.load(Ordering::Relaxed)));
        let _ = self.lua.globals().set("AUDIO_BEAT", f32::from_bits(self.audio.beat.load(Ordering::Relaxed)));
        let _ = self.lua.globals().set("AUDIO_BASS", f32::from_bits(self.audio.bass.load(Ordering::Relaxed)));
        let _ = self.lua.globals().set("AUDIO_MID",  f32::from_bits(self.audio.mid.load(Ordering::Relaxed)));
        let _ = self.lua.globals().set("AUDIO_HIGH", f32::from_bits(self.audio.high.load(Ordering::Relaxed)));
        if let Ok(spectrum) = self.audio.spectrum.read() {
            if let Ok(table) = self.lua.create_table() {
                for (i, &v) in spectrum.iter().enumerate() {
                    let _ = table.set(i + 1, v);
                }
                let _ = self.lua.globals().set("AUDIO_SPECTRUM", table);
            }
        }

        // Invoke the Lua update(buffer, dt) function.
        let keep = (|| -> LuaResult<bool> {
            let f: LuaFunction = self.lua.globals().get("update")?;
            let ud: LuaAnyUserData = self.lua.globals().get("buffer")?;
            f.call::<bool>((ud, dt))
        })()
        .unwrap_or_else(|e| {
            tracing::warn!("[{}] update() error: {e}", self.name);
            true // keep the effect alive despite the error
        });

        // Copy the Lua-side pixel data back to the Rust buffer for display.
        if let Ok(ud) = self.lua.globals().get::<LuaAnyUserData>("buffer") {
            if let Ok(b) = ud.borrow::<LuaBuf>() {
                let n = b.pixels.len().min(buffer.len());
                buffer[..n].copy_from_slice(&b.pixels[..n]);
            }
        }

        keep
    }
}

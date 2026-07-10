use std::sync::{
    atomic::{AtomicBool, AtomicU32, Ordering},
    Arc, RwLock,
};
use std::thread::JoinHandle;

// --------------------------------------------------------------------------
// AudioAnalysis — lock-free shared state between audio thread and Lua VMs.
// Always compiled; holds zeros when no audio device is active.
// --------------------------------------------------------------------------

pub struct AudioAnalysis {
    pub amplitude: AtomicU32,         // f32 bits, 0.0–1.0  (smoothed RMS)
    pub beat:      AtomicU32,         // f32 bits, 0.0–1.0  (decaying envelope)
    pub bass:      AtomicU32,         // f32 bits, 0.0–1.0  (20–200 Hz)
    pub mid:       AtomicU32,         // f32 bits, 0.0–1.0  (200–4 kHz)
    pub high:      AtomicU32,         // f32 bits, 0.0–1.0  (4–20 kHz)
    pub spectrum:  RwLock<[f32; 16]>, // 16 log-spaced bands, 0.0–1.0
    pub gain:      AtomicU32,         // f32 bits, post-normalization multiplier (default 1.0)
}

impl AudioAnalysis {
    pub fn new() -> Self {
        Self {
            amplitude: AtomicU32::new(0),
            beat:      AtomicU32::new(0),
            bass:      AtomicU32::new(0),
            mid:       AtomicU32::new(0),
            high:      AtomicU32::new(0),
            spectrum:  RwLock::new([0.0; 16]),
            gain:      AtomicU32::new(1.0f32.to_bits()),
        }
    }

    /// Reset all values to zero (called when audio is stopped).
    pub fn zero(&self) {
        for a in [&self.amplitude, &self.beat, &self.bass, &self.mid, &self.high] {
            a.store(0, Ordering::Relaxed);
        }
        if let Ok(mut s) = self.spectrum.write() {
            s.fill(0.0);
        }
    }

    #[allow(dead_code)]
    pub fn store_f32(atomic: &AtomicU32, v: f32) {
        atomic.store(v.to_bits(), Ordering::Relaxed);
    }

    pub fn load_amplitude(&self) -> f32 { f32::from_bits(self.amplitude.load(Ordering::Relaxed)) }
    pub fn load_beat(&self)      -> f32 { f32::from_bits(self.beat.load(Ordering::Relaxed)) }
    pub fn load_gain(&self)      -> f32 { f32::from_bits(self.gain.load(Ordering::Relaxed)) }
}

// --------------------------------------------------------------------------
// AudioHandle — keeps the capture thread alive; drop to stop.
// Always compiled (std-only, no cpal).
// --------------------------------------------------------------------------

pub struct AudioHandle {
    stop:   Arc<AtomicBool>,
    thread: Option<JoinHandle<()>>,
}

impl Drop for AudioHandle {
    fn drop(&mut self) {
        self.stop.store(true, Ordering::Relaxed);
        if let Some(t) = self.thread.take() {
            let _ = t.join();
        }
    }
}

// --------------------------------------------------------------------------
// list_input_devices / start_audio
// Real implementations only when the `audio` feature is enabled.
// --------------------------------------------------------------------------

#[cfg(feature = "audio")]
mod capture {
    use std::collections::VecDeque;
    use std::sync::{Arc, Mutex};
    use std::thread;
    use std::time::{Duration, Instant};

    use cpal::traits::{DeviceTrait, HostTrait, StreamTrait};
    use cpal::{SampleFormat, StreamConfig};
    use rustfft::{num_complex::Complex, FftPlanner};

    use super::{AtomicBool, AudioAnalysis, AudioHandle, Ordering};

    const FFT_SIZE: usize = 1024;

    const BANDS: [(f32, f32); 16] = [
        (20.0,    40.0),
        (40.0,    80.0),
        (80.0,   160.0),
        (160.0,  300.0),
        (300.0,  500.0),
        (500.0, 1000.0),
        (1000.0, 2000.0),
        (2000.0, 3000.0),
        (3000.0, 4000.0),
        (4000.0, 6000.0),
        (6000.0, 8000.0),
        (8000.0, 10000.0),
        (10000.0,12000.0),
        (12000.0,14000.0),
        (14000.0,16000.0),
        (16000.0,20000.0),
    ];

    fn freq_to_bin(hz: f32, sample_rate: f32) -> usize {
        ((hz * FFT_SIZE as f32 / sample_rate) as usize).clamp(1, FFT_SIZE / 2 - 1)
    }

    fn band_rms(mags: &[f32], lo: f32, hi: f32, sr: f32) -> f32 {
        let lo_bin = freq_to_bin(lo, sr);
        let hi_bin = freq_to_bin(hi, sr).max(lo_bin);
        let n = (hi_bin - lo_bin + 1) as f32;
        (mags[lo_bin..=hi_bin].iter().map(|m| m * m).sum::<f32>() / n).sqrt()
    }

    fn processing_loop(
        ring:        Arc<Mutex<VecDeque<f32>>>,
        stop:        Arc<AtomicBool>,
        analysis:    Arc<AudioAnalysis>,
        sample_rate: f32,
    ) {
        let mut planner = FftPlanner::<f32>::new();
        let fft = planner.plan_fft_forward(FFT_SIZE);

        let mut amp_smooth  = 0.0f32;
        let mut peak        = 0.001f32;
        let mut band_peaks  = [0.001f32; 16];

        const HISTORY: usize = 43;
        let mut energy_history: VecDeque<f32> = VecDeque::with_capacity(HISTORY);
        let mut beat_env  = 0.0f32;
        let mut last_beat = Instant::now();

        while !stop.load(Ordering::Relaxed) {
            thread::sleep(Duration::from_millis(10));

            let samples: Vec<f32> = {
                let r = ring.lock().unwrap();
                if r.len() < FFT_SIZE { continue; }
                r.iter().copied().collect()
            };
            let offset = samples.len() - FFT_SIZE;
            let window = &samples[offset..];

            let mut buf: Vec<Complex<f32>> = window.iter().enumerate().map(|(i, &s)| {
                let w = 0.5 * (1.0 - (2.0 * std::f32::consts::PI * i as f32
                    / (FFT_SIZE - 1) as f32).cos());
                Complex::new(s * w, 0.0)
            }).collect();
            fft.process(&mut buf);
            let mags: Vec<f32> = buf[..FFT_SIZE / 2]
                .iter()
                .map(|c| c.norm() / FFT_SIZE as f32)
                .collect();

            let rms = (window.iter().map(|s| s * s).sum::<f32>() / FFT_SIZE as f32).sqrt();
            peak = (peak * 0.9999).max(rms).max(1e-6);
            let amp_raw = (rms / peak).min(1.0);
            let alpha = if amp_raw > amp_smooth { 0.55 } else { 0.12 };
            amp_smooth += alpha * (amp_raw - amp_smooth);

            let mut bands = [0.0f32; 16];
            for (i, &(lo, hi)) in BANDS.iter().enumerate() {
                let e = band_rms(&mags, lo, hi, sample_rate);
                band_peaks[i] = (band_peaks[i] * 0.9998).max(e).max(1e-9);
                bands[i] = (e / band_peaks[i]).min(1.0);
            }

            let bass = (bands[0] + bands[1] + bands[2] + bands[3]) / 4.0;
            let mid  = (bands[4] + bands[5] + bands[6] + bands[7]) / 4.0;
            let high = (bands[8] + bands[9] + bands[10]+ bands[11]) / 4.0;

            let bass_raw = band_rms(&mags, 20.0, 200.0, sample_rate);
            energy_history.push_back(bass_raw * bass_raw);
            if energy_history.len() > HISTORY { energy_history.pop_front(); }
            let mean = energy_history.iter().sum::<f32>() / energy_history.len() as f32;
            let is_beat = bass_raw * bass_raw > 1.4 * mean
                && mean > 1e-12
                && last_beat.elapsed() >= Duration::from_millis(150);
            if is_beat {
                beat_env  = 1.0;
                last_beat = Instant::now();
            }
            beat_env *= 0.88;

            let gain = f32::from_bits(analysis.gain.load(Ordering::Relaxed)).max(0.01);
            AudioAnalysis::store_f32(&analysis.amplitude, (amp_smooth * gain).min(1.0));
            AudioAnalysis::store_f32(&analysis.beat,      (beat_env  * gain).min(1.0));
            AudioAnalysis::store_f32(&analysis.bass,      (bass      * gain).min(1.0));
            AudioAnalysis::store_f32(&analysis.mid,       (mid       * gain).min(1.0));
            AudioAnalysis::store_f32(&analysis.high,      (high      * gain).min(1.0));
            let gained: [f32; 16] = bands.map(|b| (b * gain).min(1.0));
            if let Ok(mut s) = analysis.spectrum.write() { *s = gained; }
        }
    }

    pub fn list_input_devices() -> Vec<String> {
        let host = cpal::default_host();
        match host.input_devices() {
            Ok(it) => it.filter_map(|d| d.name().ok()).collect(),
            Err(_) => Vec::new(),
        }
    }

    pub fn start_audio(
        device_name: &str,
        analysis: Arc<AudioAnalysis>,
    ) -> anyhow::Result<AudioHandle> {
        use std::sync::Arc as StdArc;

        let host = cpal::default_host();
        let device = host
            .input_devices()?
            .find(|d| d.name().ok().as_deref() == Some(device_name))
            .ok_or_else(|| anyhow::anyhow!("audio device '{device_name}' not found"))?;

        let supported    = device.default_input_config()?;
        let sample_rate  = supported.sample_rate().0 as f32;
        let channels     = supported.channels() as usize;
        let fmt          = supported.sample_format();
        let stream_cfg   = StreamConfig {
            channels:    supported.channels(),
            sample_rate: supported.sample_rate(),
            buffer_size: cpal::BufferSize::Default,
        };

        tracing::info!(device = device_name, sample_rate, channels, ?fmt, "starting audio capture");

        let stop = StdArc::new(AtomicBool::new(false));
        let stop_thread = StdArc::clone(&stop);

        let thread = thread::spawn(move || {
            let ring: StdArc<Mutex<VecDeque<f32>>> =
                StdArc::new(Mutex::new(VecDeque::with_capacity(FFT_SIZE * 8)));

            let err_fn = |e| tracing::warn!("audio stream error: {e}");

            let stream: Box<dyn StreamTrait> = match fmt {
                SampleFormat::F32 => {
                    let r  = StdArc::clone(&ring);
                    let ch = channels;
                    match device.build_input_stream(
                        &stream_cfg,
                        move |data: &[f32], _: &cpal::InputCallbackInfo| {
                            let mut rb = r.lock().unwrap();
                            for chunk in data.chunks(ch) {
                                rb.push_back(chunk.iter().sum::<f32>() / ch as f32);
                            }
                            while rb.len() > FFT_SIZE * 8 { rb.pop_front(); }
                        },
                        err_fn, None,
                    ) {
                        Ok(s)  => Box::new(s),
                        Err(e) => { tracing::error!("failed to open audio stream: {e}"); return; }
                    }
                }
                SampleFormat::I16 => {
                    let r  = StdArc::clone(&ring);
                    let ch = channels;
                    match device.build_input_stream(
                        &stream_cfg,
                        move |data: &[i16], _: &cpal::InputCallbackInfo| {
                            let mut rb = r.lock().unwrap();
                            for chunk in data.chunks(ch) {
                                let mono = chunk.iter().map(|&s| s as f32 / 32768.0).sum::<f32>()
                                    / ch as f32;
                                rb.push_back(mono);
                            }
                            while rb.len() > FFT_SIZE * 8 { rb.pop_front(); }
                        },
                        err_fn, None,
                    ) {
                        Ok(s)  => Box::new(s),
                        Err(e) => { tracing::error!("failed to open audio stream: {e}"); return; }
                    }
                }
                other => {
                    tracing::error!("unsupported sample format: {other:?}");
                    return;
                }
            };

            if let Err(e) = stream.play() {
                tracing::error!("failed to start audio stream: {e}");
                return;
            }

            processing_loop(ring, stop_thread, analysis, sample_rate);
            drop(stream);
        });

        Ok(AudioHandle { stop, thread: Some(thread) })
    }
}

// Public surface — delegates to capture module when `audio` is enabled.

pub fn list_input_devices() -> Vec<String> {
    #[cfg(feature = "audio")]
    { capture::list_input_devices() }
    #[cfg(not(feature = "audio"))]
    { Vec::new() }
}

pub fn start_audio(
    device_name: &str,
    analysis: Arc<AudioAnalysis>,
) -> anyhow::Result<AudioHandle> {
    #[cfg(feature = "audio")]
    { capture::start_audio(device_name, analysis) }
    #[cfg(not(feature = "audio"))]
    {
        let _ = (device_name, analysis);
        anyhow::bail!("audio feature not compiled in")
    }
}

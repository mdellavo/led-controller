const EFFECT_ICONS = {
  'Rainbow':               '🌈',
  'Random Fade':           '🎆',
  'Chase':                 '💨',
  'Sparkle':               '✨',
  'Strobe':                '⚡',
  'Cylon':                 '👁️',
  'KITT':                  '🚗',
  'Halloween Eyes':        '🎃',
  'Twinkle':               '⭐',
  'Random Twinkle':        '🎨',
  'Snow Sparkle':          '❄️',
  'Running Lights':        '🏃',
  'Theatre Chase':         '🎭',
  'Theatre Chase Rainbow': '🎪',
  'Fire':                  '🔥',
  'Bouncing Balls':        '🎱',
  'Meteor Rain':           '☄️',
  'Solid Color':           '🎨',
  'Color Wipe':            '🖌️',
  'Breathing':             '🫁',
  'Candlelight':           '🕯️',
  'Color Cycle':           '🌀',
  'Aurora':                '🌌',
  'Police Lights':         '🚨',
  'Lightning':             '🌩️',
  'Confetti':              '🎊',
  'Sinelon':               '〰️',
  'Juggle':                '🤹',
  'Plasma':                '🔮',
  'Drip':                  '💧',
  'Lava Lamp':             '🌋',
  'Fireworks':             '💥',
  'Pendulum':              '⏳',
  'Ripple':                '💦',
  'Pacifica':              '🌊',
  'Gradient Cycle':        '🌅',
  'Pride':                 '🏳️‍🌈',
  'Christmas':             '🎄',
  'Heartbeat':             '💓',
  'Morse Code':            '📡',
  'Comets':                '🌠',
  'Fireflies':             '🪲',
  'DNA Helix':             '🧬',
  'Sand':                  '🏖️',
  'Neon Sign':             '💡',
  'Sunrise':               '🌄',
  'Pong':                  '🏓',
  'Bioluminescence':       '🦑',
  'Twister':               '🌪️',
  'Oil Slick':             '🫧',
  'Galaxy':                '🔭',
  'Cellular Automata':     '🧩',
  'Reaction Diffusion':    '🧪',
  'VU Meter':              '📊',
  'Waterfall':             '🫗',
  'Popcorn':               '🍿',
  'Worm':                  '🐛',
  'Domino':                '🎲',
  'Sparkler':              '🎇',
  'Easter':                '🐣',
  'Tug of War':            '⚖️',
  'Matrix Rain':           '💻',
  'Starfield':             '🌟',
  'Pendulum Wave':         '🎯',
  'Snake':                 '🐍',
  'Murmuration':           '🐦',
  'Icicles':               '🧊',
  'Pixel Sort':            '🔢',
  'Bloom':                 '🌸',
  'Hypnotic Spiral':       '💫',
  'Northern Lights':       '🏔️',
  'Thunderstorm':          '⛈️',
  'Wave Interference':     '〽️',
  'Traffic':               '🚦',
  'Virus':                 '🦠',
  'Double Pendulum':       '⚙️',
  'Glitch':                '📺',
  'Typewriter':            '⌨️',
  'Lissajous':             '📐',
  'Gravity Well':          '🪐',
  'Breathing Rainbow':     '🦋',
  'Audio Pulse':           '🎵',
  'Audio Beat Flash':      '🥁',
  'Audio Spectrum':        '🎸',
  'Beat Bounce':           '🏀',
  'Beat Confetti':         '🎉',
  'Beat Comet':            '🛸',
  'Spectrum Waterfall':    '🌊',
  'Frequency Comets':      '🎠',
  'Harmonic Rings':        '🎶',
  'Audio Fire':            '🔆',
  'Audio Twinkle':         '💎',
  'Crowd Surf':            '🏄',
  'Bass Treble Split':     '🎚️',
  'Audio Plasma':          '🫀',
  'Spectrum Snake':        '🐉',
};

const effectLabel = (name) => EFFECT_ICONS[name] ? `${EFFECT_ICONS[name]} ${name}` : name;

// --------------------------------------------------------------------------
// Custom effect picker
// --------------------------------------------------------------------------

let selectedEffect = null;
let allEffectOptions = []; // [{ name, label, desc }, ...]

const pickerTrigger = document.getElementById('effect-picker-trigger');
const pickerPanel   = document.getElementById('effect-picker-panel');
const pickerLabel   = document.getElementById('effect-picker-label');
const pickerSearch  = document.getElementById('effect-picker-search');
const pickerList    = document.getElementById('effect-picker-list');

const openPicker = () => {
  pickerPanel.hidden = false;
  pickerTrigger.classList.add('open');
  pickerSearch.value = '';
  renderPickerList('');
  pickerSearch.focus();
};

const closePicker = () => {
  pickerPanel.hidden = true;
  pickerTrigger.classList.remove('open');
};

const renderPickerList = (filter) => {
  const q = filter.trim().toLowerCase();
  pickerList.innerHTML = '';
  allEffectOptions
    .filter(({ label, name, desc }) =>
      !q || name.toLowerCase().includes(q) || label.toLowerCase().includes(q) || (desc || '').toLowerCase().includes(q)
    )
    .forEach(({ name, label, desc }) => {
      const el = document.createElement('div');
      el.className = 'effect-option' + (name === selectedEffect ? ' active' : '');
      el.dataset.name = name;

      const textWrap = document.createElement('div');
      textWrap.className = 'effect-option-text';
      const nameEl = document.createElement('div');
      nameEl.className = 'effect-option-name';
      nameEl.textContent = label;
      textWrap.appendChild(nameEl);
      if (desc) {
        const descEl = document.createElement('div');
        descEl.className = 'effect-option-desc';
        descEl.textContent = desc;
        textWrap.appendChild(descEl);
      }

      const previewBtn = document.createElement('button');
      previewBtn.className = 'effect-option-preview';
      previewBtn.textContent = '▶';
      previewBtn.title = 'Preview on strip';

      el.appendChild(textWrap);
      el.appendChild(previewBtn);

      el.addEventListener('mousedown', (e) => {
        if (e.target === previewBtn) return;
        e.preventDefault();
        selectedEffect = name;
        pickerLabel.textContent = label;
        closePicker();
      });

      previewBtn.addEventListener('mousedown', (e) => {
        e.preventDefault();
        e.stopPropagation();
        selectedEffect = name;
        pickerLabel.textContent = label;
        api('select', { effect: name });
        // Keep picker open so user can continue browsing
        pickerList.querySelectorAll('.effect-option').forEach(row => {
          row.classList.toggle('active', row.dataset.name === name);
        });
      });

      pickerList.appendChild(el);
    });
};

pickerTrigger.addEventListener('click', () => {
  pickerPanel.hidden ? openPicker() : closePicker();
});

pickerSearch.addEventListener('input', () => renderPickerList(pickerSearch.value));

document.addEventListener('pointerdown', (e) => {
  if (!pickerPanel.hidden && !document.getElementById('effect-picker').contains(e.target)) {
    closePicker();
  }
});

const api = async (action, extra = {}) => {
  try {
    const res = await fetch('/api/command', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({ action, ...extra }),
    });
    if (!res.ok) throw new Error(await res.text());
  } catch (e) {
    showError(e.message);
  }
};

const showError = (msg) => {
  const t = document.getElementById('error-toast');
  t.textContent = msg;
  t.style.display = 'block';
  clearTimeout(t._timer);
  t._timer = setTimeout(() => { t.style.display = 'none'; }, 3000);
};

// Transport buttons
document.getElementById('btn-start').onclick = () => api('start');
document.getElementById('btn-stop').onclick = () => api('stop');
document.getElementById('btn-next').onclick = () => api('next');
document.getElementById('btn-shuffle').onclick = () => api('randomize');

// Play selected effect
document.getElementById('btn-play-selected').onclick = () => {
  if (selectedEffect) api('select', { effect: selectedEffect });
};

// Add to playlist
document.getElementById('btn-add-to-playlist').onclick = () => {
  const name = document.getElementById('playlist-add-select').value;
  if (name) api('add_to_playlist', { effect: name });
};

// Add all effects to playlist
document.getElementById('btn-add-all').onclick = () => api('add_all_to_playlist');

// Clear playlist
document.getElementById('btn-clear-playlist').onclick = () => api('clear_playlist');

// --------------------------------------------------------------------------
// Playlist — drag-to-reorder, click-to-play, remove button
// --------------------------------------------------------------------------

// Pointer-event drag — works on both mouse (desktop) and touch (mobile).
// The dragging item gets pointer-events:none via CSS so elementFromPoint
// can see through it to whichever item is underneath.
let dragState = null;

const playlistEl = document.getElementById('playlist');

playlistEl.addEventListener('pointerdown', (e) => {
  const handle = e.target.closest('.item-drag');
  if (!handle) return;
  const item = handle.closest('.playlist-item');
  if (!item) return;
  e.preventDefault();
  playlistEl.setPointerCapture(e.pointerId);
  dragState = { pointerId: e.pointerId, srcIndex: parseInt(item.dataset.index) };
  item.classList.add('dragging');
});

playlistEl.addEventListener('pointermove', (e) => {
  if (!dragState || e.pointerId !== dragState.pointerId) return;
  e.preventDefault();
  document.querySelectorAll('.playlist-item').forEach((el) => el.classList.remove('drag-over'));
  const under = document.elementFromPoint(e.clientX, e.clientY)?.closest('.playlist-item');
  if (under && !under.classList.contains('dragging')) under.classList.add('drag-over');
});

playlistEl.addEventListener('pointerup', (e) => {
  if (!dragState || e.pointerId !== dragState.pointerId) return;
  const under = document.elementFromPoint(e.clientX, e.clientY)?.closest('.playlist-item');
  if (under && !under.classList.contains('dragging')) {
    const toIndex = parseInt(under.dataset.index);
    if (toIndex !== dragState.srcIndex) {
      api('move_in_playlist', { index: dragState.srcIndex, to_index: toIndex });
    }
  }
  document.querySelectorAll('.playlist-item').forEach((el) => el.classList.remove('dragging', 'drag-over'));
  dragState = null;
});

playlistEl.addEventListener('pointercancel', () => {
  document.querySelectorAll('.playlist-item').forEach((el) => el.classList.remove('dragging', 'drag-over'));
  dragState = null;
});

// Click on item name to play; click remove button to remove
playlistEl.addEventListener('click', (e) => {
  if (e.target.closest('.item-remove')) {
    const item = e.target.closest('.playlist-item');
    if (item) api('remove_from_playlist', { index: parseInt(item.dataset.index) });
    return;
  }
  if (e.target.closest('.item-name')) {
    const item = e.target.closest('.playlist-item');
    if (item) api('select', { effect: item.dataset.name });
  }
});

// --------------------------------------------------------------------------
// Sliders
// --------------------------------------------------------------------------

const fadeDebouncers = {};
const setupSlider = (id, action, valId) => {
  const slider = document.getElementById(id);
  const valEl = document.getElementById(valId);
  slider.addEventListener('input', () => {
    const ms = parseInt(slider.value);
    valEl.textContent = (ms / 1000).toFixed(1) + 's';
    clearTimeout(fadeDebouncers[id]);
    fadeDebouncers[id] = setTimeout(() => api(action, { value_ms: ms }), 300);
  });
};
setupSlider('fade-in', 'set_fade_in', 'fade-in-val');
setupSlider('crossfade', 'set_crossfade', 'crossfade-val');
setupSlider('fade-out', 'set_fade_out', 'fade-out-val');

// Speed slider
const speedSlider = document.getElementById('speed');
const speedVal = document.getElementById('speed-val');
speedSlider.addEventListener('input', () => {
  const v = parseFloat(speedSlider.value);
  speedVal.textContent = v.toFixed(1) + '×';
  clearTimeout(fadeDebouncers['speed']);
  fadeDebouncers['speed'] = setTimeout(() => api('set_speed', { value: v }), 150);
});

// Brightness slider
const brightnessSlider = document.getElementById('brightness');
const brightnessVal = document.getElementById('brightness-val');
brightnessSlider.addEventListener('input', () => {
  const v = parseFloat(brightnessSlider.value);
  brightnessVal.textContent = Math.round(v * 100) + '%';
  clearTimeout(fadeDebouncers['brightness']);
  fadeDebouncers['brightness'] = setTimeout(() => api('set_brightness', { value: v }), 150);
});

// Palette
const MAX_PALETTE = 8;
let paletteColors = [];

const hexFromRgb = (r, g, b) =>
  '#' + [r, g, b].map(v => v.toString(16).padStart(2, '0')).join('');

const sendPalette = () => {
  const palette = paletteColors.map(hex => ({
    r: parseInt(hex.slice(1, 3), 16),
    g: parseInt(hex.slice(3, 5), 16),
    b: parseInt(hex.slice(5, 7), 16),
  }));
  clearTimeout(fadeDebouncers['palette']);
  fadeDebouncers['palette'] = setTimeout(() => api('set_palette', { palette }), 80);
};

const renderPalette = () => {
  const container = document.getElementById('palette-swatches');
  container.innerHTML = '';
  paletteColors.forEach((hex, i) => {
    const wrap = document.createElement('div');
    wrap.className = 'palette-swatch';

    const inp = document.createElement('input');
    inp.type = 'color';
    inp.value = hex;
    inp.title = `Color ${i + 1}`;
    inp.addEventListener('input', () => {
      paletteColors[i] = inp.value;
      sendPalette();
    });

    const rm = document.createElement('button');
    rm.className = 'swatch-remove';
    rm.textContent = '×';
    rm.title = 'Remove';
    rm.addEventListener('click', () => {
      paletteColors.splice(i, 1);
      renderPalette();
      sendPalette();
    });

    wrap.appendChild(inp);
    wrap.appendChild(rm);
    container.appendChild(wrap);
  });
  document.getElementById('palette-add').disabled = paletteColors.length >= MAX_PALETTE;
};

document.getElementById('palette-add').addEventListener('click', () => {
  if (paletteColors.length < MAX_PALETTE) {
    paletteColors.push('#ffffff');
    renderPalette();
    sendPalette();
  }
});

// Palette cycle speed slider
const paletteCycleSlider = document.getElementById('palette-cycle');
const paletteCycleVal    = document.getElementById('palette-cycle-val');
paletteCycleSlider.addEventListener('input', () => {
  const ms = parseInt(paletteCycleSlider.value);
  paletteCycleVal.textContent = (ms / 1000).toFixed(1) + 's per color';
  clearTimeout(fadeDebouncers['palette-cycle']);
  fadeDebouncers['palette-cycle'] = setTimeout(
    () => api('set_palette_cycle_ms', { value_ms: ms }), 300
  );
});

// --------------------------------------------------------------------------
// Hardware settings
// --------------------------------------------------------------------------

// Color order — live on change
const colorOrderSelect = document.getElementById('color-order');
colorOrderSelect.addEventListener('change', () => {
  api('set_color_order', { effect: colorOrderSelect.value });
});

// Gamma — debounced slider
const gammaSlider = document.getElementById('gamma');
const gammaVal = document.getElementById('gamma-val');
gammaSlider.addEventListener('input', () => {
  const v = parseFloat(gammaSlider.value);
  gammaVal.textContent = v.toFixed(1);
  clearTimeout(fadeDebouncers['gamma']);
  fadeDebouncers['gamma'] = setTimeout(() => api('set_gamma', { value: v }), 300);
});

// LED count — Apply button (causes hardware reinit)
document.getElementById('btn-apply-pixels').onclick = () => {
  const n = parseInt(document.getElementById('num-pixels').value, 10);
  if (n > 0) api('set_num_pixels', { value_ms: n });
};

// GPIO pin — Apply button (causes hardware reinit)
document.getElementById('btn-apply-gpio').onclick = () => {
  const pin = parseInt(document.getElementById('gpio-pin').value, 10);
  if (pin > 0) api('set_gpio_pin', { value_ms: pin });
};

const effectDurSlider = document.getElementById('effect-duration');
const effectDurVal = document.getElementById('effect-duration-val');
const fmtDuration = (ms) => ms === 0 ? '∞' : ms >= 60000
  ? (ms / 60000).toFixed(1) + 'm'
  : (ms / 1000).toFixed(0) + 's';
effectDurSlider.addEventListener('input', () => {
  const ms = parseInt(effectDurSlider.value);
  effectDurVal.textContent = fmtDuration(ms);
  clearTimeout(fadeDebouncers['effect-duration']);
  fadeDebouncers['effect-duration'] = setTimeout(() => api('set_effect_duration', { value_ms: ms }), 300);
});

// --------------------------------------------------------------------------
// State updates via WebSocket (with polling fallback on disconnect)
// --------------------------------------------------------------------------

let lastState = null;

// Reconnecting WebSocket — resets lastState on each reconnect so sliders
// re-sync from the fresh state the server sends immediately on connect.
let _ws = null;
const connectWS = () => {
  const proto = location.protocol === 'https:' ? 'wss:' : 'ws:';
  const ws = new WebSocket(`${proto}//${location.host}/ws`);
  _ws = ws;

  ws.onmessage = (e) => {
    try {
      const state = JSON.parse(e.data);
      renderState(state);
      lastState = state;
    } catch (_) {}
  };

  ws.onclose = () => {
    lastState = null; // force slider re-sync on next connect
    setTimeout(connectWS, 2000);
  };

  ws.onerror = () => ws.close();
};

connectWS();

const renderState = (state) => {
  // Status
  const dot = document.getElementById('status-dot');
  const label = document.getElementById('status-label');
  const effect = document.getElementById('status-effect');

  dot.className = 'status-dot';
  if (state.transition) {
    dot.classList.add('transition');
    const labels = { fading_in: 'Fading In', fading_out: 'Fading Out', crossfading: 'Crossfading' };
    label.textContent = labels[state.transition] || state.transition;
  } else if (state.is_running) {
    dot.classList.add('running');
    label.textContent = 'Running';
  } else {
    dot.classList.add('stopped');
    label.textContent = 'Stopped';
  }
  effect.textContent = state.current_effect ? effectLabel(state.current_effect) : '';

  // Timer — only shown while Running (not during transitions)
  const timerEl = document.getElementById('status-timer');
  const secs = state.effect_elapsed_secs || 0;
  if (state.is_running && !state.transition && secs > 0) {
    timerEl.textContent = secs < 60
      ? `${secs}s`
      : `${Math.floor(secs / 60)}m ${secs % 60}s`;
  } else {
    timerEl.textContent = '';
  }

  // FPS
  const fpsEl = document.getElementById('status-fps');
  fpsEl.textContent = state.fps ? `${Math.round(state.fps)} fps` : '';

  // Populate effect picker + playlist-add-select (once, or when effect list changes)
  if (!lastState || lastState.effects.length !== state.effects.length) {
    const sorted = [...state.effects].sort((a, b) => a.localeCompare(b));
    const descs  = state.effect_descriptions || {};

    // Custom picker data
    allEffectOptions = sorted.map((name) => ({
      name,
      label: effectLabel(name),
      desc: descs[name] || '',
    }));
    if (!pickerPanel.hidden) renderPickerList(pickerSearch.value);

    // Playlist-add native select
    const addSel = document.getElementById('playlist-add-select');
    const prev   = addSel.value;
    addSel.innerHTML = '';
    sorted.forEach((name) => {
      const opt = document.createElement('option');
      opt.value = name;
      opt.textContent = effectLabel(name);
      addSel.appendChild(opt);
    });
    if (prev) addSel.value = prev;
  }

  // Playlist — skip re-render during drag to avoid interrupting the interaction
  if (!dragState) {
    const newInner = state.playlist
      .map((name, i) => {
        const active = i === state.playlist_index && state.is_running;
        return `<div class="playlist-item${active ? ' active' : ''}" data-name="${name}" data-index="${i}" draggable="true">
          <span class="item-drag" title="Drag to reorder">⠿</span>
          <span class="item-dot"></span>
          <span class="item-num">${i + 1}</span>
          <span class="item-name">${effectLabel(name)}</span>
          <button class="item-remove" title="Remove">✕</button>
        </div>`;
      })
      .join('');
    if (playlistEl.innerHTML !== newInner) playlistEl.innerHTML = newInner;
  }

  // Sync sliders on first load
  if (!lastState) {
    syncSlider('fade-in', 'fade-in-val', state.fade_in_ms);
    syncSlider('crossfade', 'crossfade-val', state.crossfade_ms);
    syncSlider('fade-out', 'fade-out-val', state.fade_out_ms);
    effectDurSlider.value = state.effect_duration_ms;
    effectDurVal.textContent = fmtDuration(state.effect_duration_ms);
    speedSlider.value = state.speed;
    speedVal.textContent = parseFloat(state.speed).toFixed(1) + '×';
    brightnessSlider.value = state.brightness;
    brightnessVal.textContent = Math.round(parseFloat(state.brightness) * 100) + '%';
    // palette cycle slider
    if (state.palette_cycle_ms != null) {
      paletteCycleSlider.value = state.palette_cycle_ms;
      paletteCycleVal.textContent = (state.palette_cycle_ms / 1000).toFixed(1) + 's per color';
    }
    // audio gain slider
    if (state.audio_gain != null) {
      audioGainSlider.value = state.audio_gain;
      audioGainVal.textContent = '×' + parseFloat(state.audio_gain).toFixed(2);
    }
    // hardware settings
    colorOrderSelect.value = (state.color_order || 'rgb').toLowerCase();
    gammaSlider.value = state.gamma;
    gammaVal.textContent = parseFloat(state.gamma).toFixed(1);
    document.getElementById('num-pixels').value = state.num_pixels;
    document.getElementById('gpio-pin').value = state.gpio_pin;
  }

  // Palette — sync whenever server state differs (avoids fighting active edits)
  if (state.palette) {
    const incoming = state.palette.map(([r, g, b]) => hexFromRgb(r, g, b));
    if (JSON.stringify(incoming) !== JSON.stringify(paletteColors)) {
      paletteColors = incoming;
      renderPalette();
    }
  }

  // Audio devices — repopulate dropdown when list changes
  const devList = state.audio_devices || [];
  const serverActive = state.audio_device || null;
  const prevDevJson = audioDeviceSel._lastDevJson;
  const newDevJson  = JSON.stringify(devList) + '|' + serverActive;
  if (newDevJson !== prevDevJson) {
    audioDeviceSel._lastDevJson = newDevJson;
    renderAudioDevices(devList, serverActive);
    currentAudioDevice = serverActive;
  }

  // Strip preview — update every state push (pixel_data pushed ~15 fps)
  if (state.pixel_data) {
    stripCanvas._lastPixels = state.pixel_data;
    renderStrip(state.pixel_data);
  }

  // Audio levels, spectrum, BPM — update every state push
  renderAudioLevels(state.audio_amplitude, state.audio_beat, state.audio_bpm, state.audio_bpm_locked);
  renderSpectrum(state.audio_spectrum);

  // EQ sliders — sync from server on first load and when band gains change
  if (!lastState && state.audio_band_gains) {
    state.audio_band_gains.forEach((g, i) => {
      if (i < eqSliders.length) {
        eqSliders[i].value = g;
        eqVals[i].textContent = '×' + parseFloat(g).toFixed(2);
      }
    });
  }
};

const syncSlider = (id, valId, ms) => {
  document.getElementById(id).value = ms;
  document.getElementById(valId).textContent = (ms / 1000).toFixed(1) + 's';
};

// --------------------------------------------------------------------------
// Strip preview canvas
// --------------------------------------------------------------------------

const stripCanvas = document.getElementById('strip-canvas');
const stripCtx = stripCanvas.getContext('2d');

const renderStrip = (pixels) => {
  const dpr = window.devicePixelRatio || 1;
  const cssW = stripCanvas.clientWidth;
  const cssH = stripCanvas.clientHeight;
  const w = Math.round(cssW * dpr);
  const h = Math.round(cssH * dpr);
  if (stripCanvas.width !== w || stripCanvas.height !== h) {
    stripCanvas.width = w;
    stripCanvas.height = h;
  }

  if (!pixels || pixels.length === 0) {
    stripCtx.fillStyle = '#0a0a0a';
    stripCtx.fillRect(0, 0, w, h);
    return;
  }

  const n = pixels.length;
  const pw = w / n;
  for (let i = 0; i < n; i++) {
    const [r, g, b] = pixels[n - 1 - i];
    stripCtx.fillStyle = `rgb(${r},${g},${b})`;
    // ceil+1 avoids hairline gaps at fractional pixel widths
    stripCtx.fillRect(Math.floor(i * pw), 0, Math.ceil(pw) + 1, h);
  }
};

// Re-render on resize so the canvas stays sharp
new ResizeObserver(() => {
  if (stripCanvas._lastPixels) renderStrip(stripCanvas._lastPixels);
}).observe(stripCanvas);

// --------------------------------------------------------------------------
// Audio device management
// --------------------------------------------------------------------------

let currentAudioDevice = null; // tracks what the server has active

const audioDeviceSel = document.getElementById('audio-device');
const vuBar          = document.getElementById('audio-vu-bar');
const vuLabel        = document.getElementById('audio-vu-label');
const beatDot        = document.getElementById('audio-beat-dot');

audioDeviceSel.addEventListener('change', () => {
  const name = audioDeviceSel.value || null;
  api('set_audio_device', { effect: name });
  currentAudioDevice = name;
});

document.getElementById('btn-refresh-audio').addEventListener('click', () => {
  api('refresh_audio_devices');
});

const audioGainSlider = document.getElementById('audio-gain');
const audioGainVal    = document.getElementById('audio-gain-val');
audioGainSlider.addEventListener('input', () => {
  const v = parseFloat(audioGainSlider.value);
  audioGainVal.textContent = '×' + v.toFixed(2);
  clearTimeout(fadeDebouncers['audio-gain']);
  fadeDebouncers['audio-gain'] = setTimeout(
    () => api('set_audio_gain', { value: v }), 150
  );
});

const baseDeviceName = (name) => {
  // Extract CARD name from ALSA names like "hw:CARD=USB Audio,DEV=0"
  const card = name.match(/CARD=([^,]+)/);
  if (card) return card[1].trim();
  if (/^(sysdefault|default)$/.test(name)) return 'System Default';
  const hw = name.match(/^(?:plug)?hw:(\d+)(?:,\d+)?$/);
  if (hw) return `Hardware Device ${hw[1]}`;
  return name;
};

const deviceTypeSuffix = (name) => {
  if (name.startsWith('plughw:'))     return 'plug';
  if (name.startsWith('sysdefault:')) return 'sysdefault';
  if (name.startsWith('default:'))    return 'default';
  if (name.startsWith('hw:')) {
    const dev = name.match(/DEV=(\d+)/);
    return dev && dev[1] !== '0' ? `hw·dev${dev[1]}` : 'hw';
  }
  // Generic fallback: use whatever prefix appears before the colon
  const colon = name.indexOf(':');
  if (colon > 0) return name.slice(0, colon);
  // No colon at all — use the full raw name as the disambiguator
  return name;
};

const renderAudioDevices = (devices, active) => {
  const prev = audioDeviceSel.value;
  audioDeviceSel.innerHTML = '<option value="">— Off —</option>';

  const list = (devices || []).map(name => ({ name, base: baseDeviceName(name) }));

  // Count how many times each base name appears
  const counts = {};
  list.forEach(({ base }) => { counts[base] = (counts[base] || 0) + 1; });

  list.forEach(({ name, base }) => {
    const opt = document.createElement('option');
    opt.value = name;
    // If the base name is ambiguous, append the interface type to distinguish
    const suffix = counts[base] > 1 ? deviceTypeSuffix(name) : null;
    opt.textContent = suffix ? `${base} (${suffix})` : base;
    audioDeviceSel.appendChild(opt);
  });

  audioDeviceSel.value = active || prev || '';
};

const renderAudioLevels = (amp, beat, bpm, locked) => {
  vuBar.style.width = `${Math.round((amp || 0) * 100)}%`;
  const b = beat || 0;
  beatDot.classList.toggle('active', b > 0.5);
  const bpmEl = document.getElementById('audio-bpm');
  if (currentAudioDevice) {
    vuLabel.textContent = `Amp: ${Math.round((amp || 0) * 100)}%  Beat: ${b > 0.5 ? '●' : '○'}`;
    if (bpm && bpm > 0) {
      bpmEl.textContent = Math.round(bpm) + ' BPM' + (locked ? ' 🔒' : '');
    } else {
      bpmEl.textContent = '— BPM';
    }
  } else {
    vuLabel.textContent = 'Select a device to enable audio reactive effects';
    bpmEl.textContent = '';
  }
};

// Spectrum bars — built once, updated each state push
const spectrumBarsEl = document.getElementById('spectrum-bars');
const spectrumBars = [];
for (let i = 0; i < 16; i++) {
  const bar = document.createElement('div');
  bar.className = 'spectrum-bar';
  bar.style.height = '2px';
  spectrumBarsEl.appendChild(bar);
  spectrumBars.push(bar);
}

const renderSpectrum = (spectrum) => {
  spectrumBars.forEach((bar, i) => {
    const pct = Math.round((spectrum && spectrum[i] || 0) * 100);
    bar.style.height = Math.max(pct, 2) + '%';
  });
};

// EQ band labels (short, for 16 log-spaced bands 20 Hz–20 kHz)
const EQ_LABELS = ['20Hz','40Hz','80Hz','160Hz','300Hz','500Hz','1kHz','2kHz',
                   '3kHz','4kHz','6kHz','8kHz','10kHz','12kHz','14kHz','16kHz'];

const eqGrid = document.getElementById('eq-grid');
const eqSliders = [];
const eqVals = [];
EQ_LABELS.forEach((label, i) => {
  const band = document.createElement('div');
  band.className = 'eq-band';

  const lbl = document.createElement('label');
  lbl.textContent = label;

  const row = document.createElement('div');
  row.className = 'eq-band-row';

  const slider = document.createElement('input');
  slider.type = 'range';
  slider.min = '0';
  slider.max = '4';
  slider.step = '0.05';
  slider.value = '1';

  const val = document.createElement('span');
  val.className = 'eq-band-val';
  val.textContent = '×1.00';

  slider.addEventListener('input', () => {
    const g = parseFloat(slider.value);
    val.textContent = '×' + g.toFixed(2);
    clearTimeout(fadeDebouncers[`band-${i}`]);
    fadeDebouncers[`band-${i}`] = setTimeout(
      () => api('set_band_gain', { index: i, value: g }), 150
    );
  });

  row.appendChild(slider);
  row.appendChild(val);
  band.appendChild(lbl);
  band.appendChild(row);
  eqGrid.appendChild(band);
  eqSliders.push(slider);
  eqVals.push(val);
});

document.getElementById('btn-reset-eq').addEventListener('click', () => {
  eqSliders.forEach((s, i) => {
    s.value = '1';
    eqVals[i].textContent = '×1.00';
    api('set_band_gain', { index: i, value: 1.0 });
  });
});

// Tap tempo
document.getElementById('btn-tap-tempo').addEventListener('click', () => {
  api('tap_tempo');
});
document.getElementById('btn-clear-tap').addEventListener('click', () => {
  api('clear_tap_tempo');
});

// PWA service worker registration
if ('serviceWorker' in navigator) {
  navigator.serviceWorker.register('/sw.js').catch(() => {});
}


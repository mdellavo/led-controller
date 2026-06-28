const EFFECT_ICONS = {
  'Rainbow':               '🌈',
  'Random Fade':           '🎆',
  'Chase':                 '💨',
  'Sparkle':               '✨',
  'Strobe':                '⚡',
  'Strobe Red':            '🔴',
  'Cylon':                 '👁️',
  'KITT':                  '🚗',
  'Halloween Eyes':        '🎃',
  'Twinkle':               '⭐',
  'Random Twinkle':        '🎨',
  'Snow Sparkle':          '❄️',
  'Running Lights':        '🏃',
  'Running Lights Green':  '🌿',
  'Color Wipe Red':        '🟥',
  'Color Wipe Green':      '🟩',
  'Color Wipe Blue':       '🟦',
  'Theatre Chase':         '🎭',
  'Theatre Chase Rainbow': '🎪',
  'Fire':                  '🔥',
  'Bouncing Balls':        '🎱',
  'Meteor Rain':           '☄️',
  'Solid Red':             '🔴',
  'Solid Green':           '🟢',
  'Solid Blue':            '🔵',
  'Solid White':           '⬜',
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
};

const effectLabel = (name) => EFFECT_ICONS[name] ? `${EFFECT_ICONS[name]} ${name}` : name;

const updateEffectHint = () => {
  const sel = document.getElementById('effect-select');
  const opt = sel.options[sel.selectedIndex];
  document.getElementById('effect-hint').textContent = opt?.dataset?.description || '';
};

document.getElementById('effect-select').addEventListener('change', updateEffectHint);

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
  const name = document.getElementById('effect-select').value;
  if (name) api('select', { effect: name });
};

// Add to playlist
document.getElementById('btn-add-to-playlist').onclick = () => {
  const name = document.getElementById('playlist-add-select').value;
  if (name) api('add_to_playlist', { effect: name });
};

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

  // Populate effect dropdowns (once, or when effect list changes)
  if (!lastState || lastState.effects.length !== state.effects.length) {
    ['effect-select', 'playlist-add-select'].forEach((id) => {
      const sel = document.getElementById(id);
      const prev = sel.value;
      sel.innerHTML = '';
      state.effects.forEach((name) => {
        const opt = document.createElement('option');
        opt.value = name;
        opt.textContent = effectLabel(name);
        const desc = (state.effect_descriptions || {})[name];
        if (desc) opt.dataset.description = desc;
        sel.appendChild(opt);
      });
      if (prev) sel.value = prev;
    });
    updateEffectHint();
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
    // hardware settings
    colorOrderSelect.value = (state.color_order || 'rgb').toLowerCase();
    gammaSlider.value = state.gamma;
    gammaVal.textContent = parseFloat(state.gamma).toFixed(1);
    document.getElementById('num-pixels').value = state.num_pixels;
    document.getElementById('gpio-pin').value = state.gpio_pin;
  }
};

const syncSlider = (id, valId, ms) => {
  document.getElementById(id).value = ms;
  document.getElementById(valId).textContent = (ms / 1000).toFixed(1) + 's';
};


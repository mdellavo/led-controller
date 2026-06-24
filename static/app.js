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

// Playlist item click
document.getElementById('playlist').addEventListener('click', (e) => {
  const item = e.target.closest('.playlist-item');
  if (item) api('select', { effect: item.dataset.name });
});

// Fade duration sliders
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

// State polling
let lastState = null;

const renderState = (state) => {
  // Status
  const dot = document.getElementById('status-dot');
  const label = document.getElementById('status-label');
  const effect = document.getElementById('status-effect');

  dot.className = 'status-dot';
  if (state.transition) {
    dot.classList.add('transition');
    const labels = {
      fading_in: 'Fading In',
      fading_out: 'Fading Out',
      crossfading: 'Crossfading',
    };
    label.textContent = labels[state.transition] || state.transition;
  } else if (state.is_running) {
    dot.classList.add('running');
    label.textContent = 'Running';
  } else {
    dot.classList.add('stopped');
    label.textContent = 'Stopped';
  }
  effect.textContent = state.current_effect || '';

  // Populate effects dropdown (once)
  const select = document.getElementById('effect-select');
  if (select.options.length !== state.effects.length) {
    select.innerHTML = '';
    state.effects.forEach((name) => {
      const opt = document.createElement('option');
      opt.value = name;
      opt.textContent = name;
      select.appendChild(opt);
    });
  }

  // Playlist
  const playlistEl = document.getElementById('playlist');
  const prevInner = playlistEl.innerHTML;
  const newInner = state.playlist
    .map((name, i) => {
      const active = i === state.playlist_index && state.is_running;
      return `<div class="playlist-item${active ? ' active' : ''}" data-name="${name}">
        <span class="item-dot"></span>
        <span class="item-num">${i + 1}</span>
        <span>${name}</span>
      </div>`;
    })
    .join('');
  if (newInner !== prevInner) playlistEl.innerHTML = newInner;

  // Sync sliders to reported server values (only on first load)
  if (!lastState) {
    syncSlider('fade-in', 'fade-in-val', state.fade_in_ms);
    syncSlider('crossfade', 'crossfade-val', state.crossfade_ms);
    syncSlider('fade-out', 'fade-out-val', state.fade_out_ms);
  }
};

const syncSlider = (id, valId, ms) => {
  document.getElementById(id).value = ms;
  document.getElementById(valId).textContent = (ms / 1000).toFixed(1) + 's';
};

const poll = async () => {
  try {
    const res = await fetch('/api/state');
    if (res.ok) {
      const state = await res.json();
      renderState(state);
      lastState = state;
    }
  } catch (_) {}
  setTimeout(poll, 500);
};

poll();

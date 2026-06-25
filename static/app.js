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

let dragSrcIndex = null;
let isDragging = false;

const playlistEl = document.getElementById('playlist');

playlistEl.addEventListener('dragstart', (e) => {
  const item = e.target.closest('.playlist-item');
  if (!item) return;
  dragSrcIndex = parseInt(item.dataset.index);
  isDragging = true;
  item.classList.add('dragging');
  e.dataTransfer.effectAllowed = 'move';
});

playlistEl.addEventListener('dragend', (e) => {
  isDragging = false;
  document.querySelectorAll('.playlist-item').forEach((el) => {
    el.classList.remove('dragging', 'drag-over');
  });
});

playlistEl.addEventListener('dragover', (e) => {
  e.preventDefault();
  e.dataTransfer.dropEffect = 'move';
  const item = e.target.closest('.playlist-item');
  document.querySelectorAll('.playlist-item').forEach((el) => el.classList.remove('drag-over'));
  if (item) item.classList.add('drag-over');
});

playlistEl.addEventListener('dragleave', (e) => {
  const item = e.target.closest('.playlist-item');
  if (item) item.classList.remove('drag-over');
});

playlistEl.addEventListener('drop', (e) => {
  e.preventDefault();
  const item = e.target.closest('.playlist-item');
  if (!item) return;
  const toIndex = parseInt(item.dataset.index);
  if (dragSrcIndex !== null && dragSrcIndex !== toIndex) {
    api('move_in_playlist', { index: dragSrcIndex, to_index: toIndex });
  }
  dragSrcIndex = null;
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
// State polling + rendering
// --------------------------------------------------------------------------

let lastState = null;

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
  effect.textContent = state.current_effect || '';

  // Populate effect dropdowns (once)
  if (!lastState || lastState.effects.length !== state.effects.length) {
    ['effect-select', 'playlist-add-select'].forEach((id) => {
      const sel = document.getElementById(id);
      const prev = sel.value;
      sel.innerHTML = '';
      state.effects.forEach((name) => {
        const opt = document.createElement('option');
        opt.value = name;
        opt.textContent = name;
        sel.appendChild(opt);
      });
      if (prev) sel.value = prev;
    });
  }

  // Playlist — skip re-render during drag to avoid interrupting the interaction
  if (!isDragging) {
    const newInner = state.playlist
      .map((name, i) => {
        const active = i === state.playlist_index && state.is_running;
        return `<div class="playlist-item${active ? ' active' : ''}" data-name="${name}" data-index="${i}" draggable="true">
          <span class="item-drag" title="Drag to reorder">⠿</span>
          <span class="item-dot"></span>
          <span class="item-num">${i + 1}</span>
          <span class="item-name">${name}</span>
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

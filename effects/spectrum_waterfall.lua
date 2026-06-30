name        = "Spectrum Waterfall"
description = "The frequency spectrum scrolls across the strip as a color history — newest slice on the left, older frames scroll right. Bass=red, mid=green, treble=blue."

local history = {}
local n_saved = 0

function init(n)
    n_saved = n
    for i = 1, n do
        history[i] = { 0, 0, 0 }
    end
end

local function spectrum_to_rgb(spec, amp)
    if not spec then return 0, 0, 0 end
    -- Sum energy across bass / mid / treble regions
    local bass, mid, high = 0, 0, 0
    for i = 1, 4  do bass = bass + (spec[i] or 0) end
    for i = 5, 10 do mid  = mid  + (spec[i] or 0) end
    for i = 11,16 do high = high + (spec[i] or 0) end
    bass = bass / 4
    mid  = mid  / 6
    high = high / 6
    local scale = 0.2 + (amp or 0) * 0.8
    return math.min(255, math.floor(bass * 255 * scale)),
           math.min(255, math.floor(mid  * 255 * scale)),
           math.min(255, math.floor(high * 255 * scale))
end

function update(buf, dt)
    local n = buf:len()

    -- Shift history right (index 1 = newest)
    for i = n, 2, -1 do
        history[i] = history[i - 1]
    end

    local r, g, b = spectrum_to_rgb(AUDIO_SPECTRUM, AUDIO_AMP)
    history[1] = { r, g, b }

    buf:clear()
    for i = 1, n do
        local c = history[i]
        if c then buf:set(i - 1, c[1], c[2], c[3]) end
    end

    return true
end

name        = "Audio Pulse"
description = "Whole strip pulses brightness and color with audio amplitude; color shifts with AUDIO_BASS/MID/HIGH mix."

local t = 0

function update(buf, dt)
    t = t + dt

    local amp  = AUDIO_AMP  or 0
    local bass = AUDIO_BASS or 0
    local mid  = AUDIO_MID  or 0
    local high = AUDIO_HIGH or 0

    -- Map frequency bands to RGB
    local r = math.floor(bass * 255)
    local g = math.floor(mid  * 255)
    local b = math.floor(high * 255)

    -- Scale by overall amplitude so silence is dark
    local scale = 0.15 + amp * 0.85
    r = math.floor(r * scale)
    g = math.floor(g * scale)
    b = math.floor(b * scale)

    buf:clear()
    for i = 0, buf:len() - 1 do
        buf:set(i, r, g, b)
    end

    return true
end

name        = "Bass Treble Split"
description = "Left half pulses warm red/orange with bass; right half shimmers cool blue/white with treble. The split point slides left/right with mid energy."

local t            = 0
local split_smooth = 0.5

function update(buf, dt)
    local n    = buf:len()
    local bass = AUDIO_BASS or 0
    local mid  = AUDIO_MID  or 0
    local high = AUDIO_HIGH or 0
    local beat = AUDIO_BEAT or 0

    t = t + dt

    -- Split point drifts with mid energy (0.25–0.75 of strip)
    local target = 0.25 + mid * 0.5
    split_smooth = split_smooth + 6 * dt * (target - split_smooth)
    local split = math.floor(split_smooth * n)

    buf:clear()

    -- Bass side: warm pulsing red/orange
    for px = 0, split - 1 do
        local pos  = px / math.max(1, split - 1)   -- 0..1 within segment
        local wave = (math.sin(t * 4 + pos * math.pi) + 1) * 0.5
        local bri  = (0.08 + bass * 0.92) * (0.4 + wave * 0.6) + beat * 0.25
        bri = math.min(1, bri)
        local r = math.min(255, math.floor(bri * 255))
        local g = math.min(255, math.floor(bri * bass * 140))
        buf:set(px, r, g, 0)
    end

    -- Treble side: cool shimmering blue/white
    for px = split, n - 1 do
        local pos  = (px - split) / math.max(1, n - split - 1)
        local wave = (math.sin(t * 10 + pos * math.pi * 4 + 1.3) + 1) * 0.5
        local bri  = (0.04 + high * 0.96) * (0.3 + wave * 0.7) + beat * 0.2
        bri = math.min(1, bri)
        local wb   = math.floor(beat * 55)     -- white flash on beat
        local b = math.min(255, math.floor(bri * 255) + wb)
        local g = math.min(255, math.floor(bri * 160) + wb)
        local r = math.min(255, wb)
        buf:set(px, r, g, b)
    end

    return true
end

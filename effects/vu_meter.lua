name = "VU Meter"
description = "Simulated audio level meter with a bouncing bar, green-to-red color gradient, and peak-hold pixel"

local level      = 0.0
local peak       = 0.0
local peak_timer = 0.0
local PEAK_HOLD  = 1.8   -- seconds to hold before falling
local peak_vel   = 0.0
local sig_t      = 0.0

-- Simulated 120 BPM kick+snare+hihat signal
local function signal(t)
    local beat = 0.5      -- 0.5 s per beat = 120 BPM
    local ph   = t % beat
    local kick  = math.exp(-((ph * 28) ^ 2)) * 0.92
    local sn_ph = (t + beat * 0.5) % beat
    local snare = math.exp(-((sn_ph * 20) ^ 2)) * 0.58
    local hihat = math.abs(math.sin(t * 13.7)) * 0.18
    local noise = math.random() * 0.10
    return math.min(1.0, kick + snare + hihat + noise)
end

function update(buf, dt)
    local n = buf:len()
    sig_t = sig_t + dt

    local target = signal(sig_t)

    -- Fast attack, slower release
    if target > level then
        level = target
    else
        level = level * (0.10 ^ dt)
    end

    -- Peak hold then fall
    if level >= peak then
        peak       = level
        peak_timer = PEAK_HOLD
        peak_vel   = 0.0
    else
        peak_timer = peak_timer - dt
        if peak_timer < 0 then
            peak_vel = peak_vel + 3.0 * dt
            peak = math.max(level, peak - peak_vel * dt)
        end
    end

    -- Bar: green → yellow → red
    local bar = math.floor(level * n)
    for i = 0, n - 1 do
        local frac = i / (n - 1)
        if i < bar then
            if frac < 0.60 then
                buf:set(i, 0, 200, 0)
            elseif frac < 0.82 then
                buf:set(i, 220, 200, 0)
            else
                buf:set(i, 255, 25, 0)
            end
        else
            buf:set(i, 6, 6, 6)
        end
    end

    -- Peak-hold pixel (white)
    local pk_px = math.min(n - 1, math.floor(peak * n))
    if pk_px >= 0 then buf:set(pk_px, 255, 255, 255) end

    return true
end

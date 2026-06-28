name = "Neon Sign"
description = "Pink neon glow with realistic fluorescent tube flicker, buzz, and occasional dropout"

local COLOR = {255, 40, 185}  -- neon pink

local phase1     = 0.0
local phase2     = 0.0
local buzz_timer = 2.5
local buzz_on    = true

function update(buf, dt)
    local n = buf:len()

    -- Multi-frequency flicker (power-line interference feel)
    phase1 = phase1 + dt * 37.1
    phase2 = phase2 + dt *  7.3
    local flicker = 0.93 + 0.04 * math.sin(phase1) + 0.03 * math.sin(phase2 * 1.9)

    -- Per-frame noise (subtle heat shimmer)
    local noise = 1.0 + (math.random() - 0.5) * 0.025

    -- Buzz: short dark dropouts at random intervals
    buzz_timer = buzz_timer - dt
    if buzz_timer <= 0 then
        buzz_on = not buzz_on
        if buzz_on then
            buzz_timer = math.random() * 5.0 + 2.0   -- lit for 2–7 s
        else
            buzz_timer = math.random() * 0.08 + 0.02 -- dark for 20–100 ms
        end
    end

    local bright = flicker * noise * (buzz_on and 1.0 or 0.08)

    local r = math.min(255, math.floor(COLOR[1] * bright))
    local g = math.min(255, math.floor(COLOR[2] * bright))
    local b = math.min(255, math.floor(COLOR[3] * bright))

    for i = 0, n - 1 do buf:set(i, r, g, b) end

    return true
end

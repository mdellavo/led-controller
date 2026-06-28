name = "Candlelight"
description = "Warm orange flicker: each pixel drifts toward a random brightness target, with occasional sharp gusts"

-- Each pixel independently wanders toward a random brightness target.
-- Occasional gusts drop the target low for a realistic flicker.
local base_r, base_g, base_b = 255, 80, 10
local flicker = {}
local target  = {}
local rate    = 8.0  -- lerp speed

function init(n)
    flicker = {}
    target  = {}
    for i = 1, n do
        flicker[i] = math.random() * 0.3 + 0.7
        target[i]  = math.random() * 0.3 + 0.7
    end
end

function update(buf, dt)
    local n = buf:len()
    for i = 1, n do
        flicker[i] = flicker[i] + (target[i] - flicker[i]) * rate * dt
        if math.random() < dt * 3.0 then
            if math.random() < 0.1 then
                target[i] = math.random() * 0.3 + 0.1  -- gust: dip low
            else
                target[i] = math.random() * 0.3 + 0.65
            end
        end
        local b = math.max(0.0, flicker[i])
        buf:set(i - 1,
            math.floor(base_r * b),
            math.floor(base_g * b),
            math.floor(base_b * b))
    end
    return true
end

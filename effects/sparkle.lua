name = "Sparkle"
description = "Pixels independently ramp to a random peak brightness then fade back to dark"

-- Per-pixel brightness with smooth ramp-up then ramp-down, matching Rust SparkleEffect.
local brightness = {}
local target = {}

function init(n)
    brightness = {}
    target = {}
    for i = 1, n do
        brightness[i] = 0.0
        target[i] = 0.0
    end
end

function update(buf, dt)
    local n = buf:len()

    -- Randomly trigger new sparkles
    local triggers = math.floor(n * dt * 3.0) + 1
    for _ = 1, triggers do
        local idx = math.random(1, n)
        if target[idx] < 0.1 then
            target[idx] = math.random() * 0.5 + 0.5
        end
    end

    for i = 1, n do
        local diff = target[i] - brightness[i]
        if math.abs(diff) < 0.01 then
            if target[i] > 0.5 then
                target[i] = 0.0
            end
            brightness[i] = target[i]
        else
            brightness[i] = brightness[i] + diff * dt * 8.0
        end
        local v = math.floor(brightness[i] * 255)
        buf:set(i - 1, v, v, v)
    end

    return true
end

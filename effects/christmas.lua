name = "Christmas"
description = "Alternating red and green bands with a slow white twinkle overlay"

local BAND   = 8     -- pixels per color band
local twinkles = {}
local twinkle_timer = 0.0
local TWINKLE_RATE  = 0.12  -- seconds between new twinkles

function init(n)
    twinkles = {}
    for i = 1, n do twinkles[i] = 0.0 end
end

function update(buf, dt)
    local n = buf:len()

    -- Red / green base
    for i = 0, n - 1 do
        if math.floor(i / BAND) % 2 == 0 then
            buf:set(i, 180, 0, 0)
        else
            buf:set(i, 0, 110, 0)
        end
    end

    -- Fade existing twinkles and paint them
    for i = 1, n do
        if twinkles[i] > 0 then
            twinkles[i] = twinkles[i] * (0.5 ^ dt)  -- half-life ~1 s
            if twinkles[i] < 0.04 then
                twinkles[i] = 0.0
            else
                local v = math.floor(twinkles[i] * 255)
                buf:set(i - 1, v, v, v)
            end
        end
    end

    -- Spawn a new twinkle
    twinkle_timer = twinkle_timer + dt
    if twinkle_timer >= TWINKLE_RATE then
        twinkle_timer = twinkle_timer - TWINKLE_RATE
        local idx = math.random(1, n)
        twinkles[idx] = math.random() * 0.5 + 0.5
    end

    return true
end

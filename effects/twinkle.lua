name = "Twinkle"
description = "Ten white pixels reposition randomly every 100ms"

local tw_r, tw_g, tw_b = 255, 255, 255
local count    = 10
local speed_ms = 100.0
local timer    = 0.0

function update(buf, dt)
    timer = timer + dt * 1000.0
    if timer >= speed_ms then
        timer = timer - speed_ms
        local n = buf:len()
        buf:clear()
        for _ = 1, count do
            buf:set(math.random(0, n - 1), tw_r, tw_g, tw_b)
        end
    end
    return true
end

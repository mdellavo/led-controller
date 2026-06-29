name = "Twinkle"
description = "Ten white pixels reposition randomly every 100ms"

local count    = 10
local speed_ms = 100.0
local timer    = 0.0

function update(buf, dt)
    timer = timer + dt * 1000.0
    if timer >= speed_ms then
        timer = timer - speed_ms
        local n = buf:len()
        local r = COLOR_R or 255
        local g = COLOR_G or 255
        local b = COLOR_B or 255
        buf:clear()
        for _ = 1, count do
            buf:set(math.random(0, n - 1), r, g, b)
        end
    end
    return true
end

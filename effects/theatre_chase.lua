name = "Theatre Chase"
description = "Every third pixel is lit and steps along the strip in a marching-lights pattern"

local speed_ms = 100.0
local phase    = 0
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
        local i = phase
        while i < n do
            buf:set(i, r, g, b)
            i = i + 3
        end
        phase = (phase + 1) % 3
    end
    return true
end

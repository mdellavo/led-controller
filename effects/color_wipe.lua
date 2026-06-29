name = "Color Wipe"
description = "Fills the strip with the user-selected color one pixel at a time, then clears it the same way."

local speed_ms = 20.0
local state    = "wiping"
local pos      = 0
local timer    = 0.0

function init(n)
    pos   = 0
    state = "wiping"
    timer = 0.0
end

function update(buf, dt)
    local n = buf:len()
    local r = COLOR_R or 255
    local g = COLOR_G or 255
    local b = COLOR_B or 255
    timer = timer + dt * 1000.0

    while timer >= speed_ms do
        timer = timer - speed_ms
        if state == "wiping" then
            if pos < n then
                buf:set(pos, r, g, b)
                pos = pos + 1
            end
            if pos >= n then pos = 0; state = "clearing" end
        else
            if pos < n then
                buf:set(pos, 0, 0, 0)
                pos = pos + 1
            end
            if pos >= n then pos = 0; state = "wiping" end
        end
    end
    return true
end

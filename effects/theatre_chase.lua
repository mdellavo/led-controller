name = "Theatre Chase"

local tc_r, tc_g, tc_b = 255, 255, 255
local speed_ms = 100.0
local phase    = 0
local timer    = 0.0

function update(buf, dt)
    timer = timer + dt * 1000.0
    if timer >= speed_ms then
        timer = timer - speed_ms
        local n = buf:len()
        buf:clear()
        local i = phase
        while i < n do
            buf:set(i, tc_r, tc_g, tc_b)
            i = i + 3
        end
        phase = (phase + 1) % 3
    end
    return true
end

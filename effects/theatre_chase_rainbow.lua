name = "Theatre Chase Rainbow"

local speed_ms   = 100.0
local phase      = 0
local hue_offset = 0
local timer      = 0.0

local function colorwheel(pos)
    pos = (255 - pos) % 256
    if pos < 85 then
        return 255 - pos * 3, 0, pos * 3
    elseif pos < 170 then
        pos = pos - 85
        return 0, pos * 3, 255 - pos * 3
    else
        pos = pos - 170
        return pos * 3, 255 - pos * 3, 0
    end
end

function update(buf, dt)
    timer = timer + dt * 1000.0
    if timer >= speed_ms then
        timer = timer - speed_ms
        local n = buf:len()
        buf:clear()
        local i = phase
        while i < n do
            local wheel_pos = (math.floor(i * 256 / n) + hue_offset) % 256
            local r, g, b = colorwheel(wheel_pos)
            buf:set(i, r, g, b)
            i = i + 3
        end
        phase      = (phase + 1) % 3
        hue_offset = (hue_offset + 1) % 256
    end
    return true
end

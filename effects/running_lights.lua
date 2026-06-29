name = "Running Lights"
description = "Red sine-wave brightness ripples continuously down the strip"

local speed    = 1.0
local wave_pos = 0.0

function update(buf, dt)
    local n = buf:len()
    local r = COLOR_R or 255
    local g = COLOR_G or 255
    local b = COLOR_B or 255
    wave_pos = wave_pos + speed * dt * 2.0 * math.pi
    for i = 0, n - 1 do
        local brightness = (math.sin(i * 2.0 * math.pi / n + wave_pos) + 1.0) / 2.0
        buf:set(i,
            math.floor(r * brightness),
            math.floor(g * brightness),
            math.floor(b * brightness))
    end
    return true
end

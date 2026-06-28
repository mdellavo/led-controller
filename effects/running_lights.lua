name = "Running Lights"

local rl_r, rl_g, rl_b = 255, 0, 0
local speed    = 1.0
local wave_pos = 0.0

function update(buf, dt)
    local n = buf:len()
    wave_pos = wave_pos + speed * dt * 2.0 * math.pi
    for i = 0, n - 1 do
        local brightness = (math.sin(i * 2.0 * math.pi / n + wave_pos) + 1.0) / 2.0
        buf:set(i,
            math.floor(rl_r * brightness),
            math.floor(rl_g * brightness),
            math.floor(rl_b * brightness))
    end
    return true
end

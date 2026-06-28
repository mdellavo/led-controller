name = "Sinelon"

-- A single dot rides a sine wave back and forth, leaving a fading trail.
-- Smoother and more graceful than Cylon's linear bounce.
local dot_r, dot_g, dot_b = 255, 0, 200  -- magenta
local speed = 0.7  -- cycles per second
local phase = 0.0

function update(buf, dt)
    local n = buf:len()
    phase = phase + speed * dt * 2.0 * math.pi
    buf:fade(0.85 ^ 60, dt)
    local pos = (math.sin(phase) + 1.0) / 2.0 * (n - 1)
    buf:plot(pos, dot_r, dot_g, dot_b, 1.0)
    return true
end

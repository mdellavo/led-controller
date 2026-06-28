name = "Breathing"

-- All pixels pulse in and out like the Apple sleep indicator.
-- Uses sin^2 so the strip spends more time near dark (natural breathing rhythm).
local r, g, b = 255, 140, 80  -- warm white
local speed    = 0.4  -- breath cycles per second
local phase    = 0.0

function update(buf, dt)
    local n = buf:len()
    phase = phase + speed * dt * 2.0 * math.pi
    local raw        = (math.sin(phase) + 1.0) / 2.0
    local brightness = raw ^ 2
    local rv = math.floor(r * brightness)
    local gv = math.floor(g * brightness)
    local bv = math.floor(b * brightness)
    for i = 0, n - 1 do buf:set(i, rv, gv, bv) end
    return true
end

name = "Confetti"

-- Saturated random-hue dots scattered each frame onto a decaying background.
local spawn_rate = 20.0  -- new dots per second

local function colorwheel(pos)
    pos = math.floor(pos) % 256
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
    local n = buf:len()
    buf:fade(0.85 ^ 60, dt)
    local count = math.max(1, math.floor(spawn_rate * dt))
    for _ = 1, count do
        local r, g, b = colorwheel(math.random(0, 255))
        buf:set(math.random(0, n - 1), r, g, b)
    end
    return true
end

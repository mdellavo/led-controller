name = "Color Cycle"

-- All pixels show the same hue at once, slowly cycling through the wheel.
-- Slower and moodier than Rainbow — the whole strip breathes one color at a time.
local hue   = 0.0
local speed = 8.0  -- colorwheel units per second (256 = full cycle)

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
    hue = (hue + dt * speed) % 256.0
    local r, g, b = colorwheel(hue)
    for i = 0, n - 1 do buf:set(i, r, g, b) end
    return true
end

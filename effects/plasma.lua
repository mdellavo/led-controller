name = "Plasma"

-- Four overlapping sine waves at different spatial frequencies and speeds
-- sum into a continuously shifting interference pattern mapped to hue.
local t = 0.0

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
    t = t + dt
    for i = 0, n - 1 do
        local x = i / n
        local v = math.sin(x * 6.0  + t * 2.0)
              + math.sin(x * 3.0  - t * 1.3)
              + math.sin(x * 10.0 + t * 0.7)
              + math.sin((x + t * 0.5) * 4.0)
        -- v is in [-4, 4]; map to 0–255
        local hue = math.floor((v + 4.0) / 8.0 * 255.0)
        local r, g, b = colorwheel(hue)
        buf:set(i, r, g, b)
    end
    return true
end

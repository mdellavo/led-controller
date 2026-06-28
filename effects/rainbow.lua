name = "Rainbow"

local hue = 0.0

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
    local n = buf:len()
    hue = (hue + dt * 50.0) % 256.0
    for i = 0, n - 1 do
        local r, g, b = colorwheel(math.floor(hue + i * 256 / n) % 256)
        buf:set(i, r, g, b)
    end
    return true
end

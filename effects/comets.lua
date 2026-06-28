name = "Comets"
description = "Three comets of different colors chase each other around the strip at different speeds"

local NUM_COMETS = 3
local comets = {}

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

function init(n)
    comets = {}
    local tail = math.max(4, math.floor(n / 8))
    for i = 1, NUM_COMETS do
        local hue  = math.floor((i - 1) * 256 / NUM_COMETS)
        local r, g, b = colorwheel(hue)
        table.insert(comets, {
            pos   = (i - 1) * n / NUM_COMETS,
            speed = n * (0.9 + (i - 1) * 0.35),  -- each comet faster than the last
            tail  = tail,
            r = r, g = g, b = b,
        })
    end
end

function update(buf, dt)
    local n = buf:len()
    buf:clear()

    for _, c in ipairs(comets) do
        c.pos = (c.pos + c.speed * dt) % n

        for j = 0, c.tail - 1 do
            local p      = (c.pos - j) % n
            local bright = (1.0 - j / c.tail) ^ 2
            buf:plot(p, c.r, c.g, c.b, bright)
        end
    end

    return true
end

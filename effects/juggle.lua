name = "Juggle"
description = "Six differently-colored dots bounce at staggered speeds; their fading trails overlap and blend"

-- Six dots bouncing back and forth at slightly different speeds, each a different hue.
-- Trails overlap and mix as they cross, creating complex moving color patterns.
local NUM_DOTS = 6
local dots     = {}

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
    dots = {}
    for i = 1, NUM_DOTS do
        local r, g, b = colorwheel(math.floor((i - 1) * 256 / NUM_DOTS))
        table.insert(dots, {
            r     = r,
            g     = g,
            b     = b,
            phase = (i - 1) * 2.0 * math.pi / NUM_DOTS,
            speed = 0.5 + (i - 1) * 0.15,
        })
    end
end

function update(buf, dt)
    local n = buf:len()
    buf:fade(0.85 ^ 60, dt)
    for _, dot in ipairs(dots) do
        dot.phase = dot.phase + dot.speed * dt * 2.0 * math.pi
        local pos = (math.sin(dot.phase) + 1.0) / 2.0 * (n - 1)
        buf:plot(pos, dot.r, dot.g, dot.b, 1.0)
    end
    return true
end

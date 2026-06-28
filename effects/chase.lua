name = "Lua Chase"

-- Comet with an antialiased head and a fading tail.
-- Demonstrates buf:plot() for sub-pixel motion and buf:fade() for trails.

local pos = 0.0
local speed = 40.0   -- pixels per second
local tail  = 12     -- tail length in pixels
local r, g, b = 255, 60, 0

function init(n)
    pos = 0.0
    r = math.random(100, 255)
    g = math.random(0,   80)
    b = math.random(100, 255)
end

function update(buf, dt)
    buf:fade(0.12, dt)
    for i = 0, tail - 1 do
        local brightness = (tail - i) / tail
        buf:plot(pos - i, r, g, b, brightness)
    end
    pos = (pos + dt * speed) % buf:len()
    return true
end

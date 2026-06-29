name = "Bloom"
description = "Rings of color bloom outward from random seed points and fade."

local function colorwheel(pos)
    pos = math.floor(pos) % 256
    pos = (255 - pos) % 256
    if pos < 85 then return 255-pos*3, 0, pos*3
    elseif pos < 170 then pos=pos-85; return 0, pos*3, 255-pos*3
    else pos=pos-170; return pos*3, 255-pos*3, 0 end
end

local blooms     = {}
local MAX_BLOOMS = 12
local RATE       = 2.2   -- spawns per second

function init(n)
    blooms = {}
end

function update(buf, dt)
    local n = buf:len()
    buf:fade(0.55^60, dt)

    -- probabilistic spawn
    if math.random() < RATE * dt and #blooms < MAX_BLOOMS then
        table.insert(blooms, {
            center = math.random(0, n - 1),
            radius = 0,
            speed  = math.random() * 12 + 5,
            hue    = math.random(0, 255),
        })
    end

    local alive = {}
    for _, bl in ipairs(blooms) do
        bl.radius = bl.radius + bl.speed * dt
        local alpha = 1.0 - bl.radius / (n * 0.55)
        if alpha > 0 then
            local r, g, b = colorwheel(bl.hue)
            buf:plot(bl.center - bl.radius, r, g, b, alpha)
            buf:plot(bl.center + bl.radius, r, g, b, alpha)
            if bl.radius < 1.5 then
                buf:plot(bl.center, r, g, b, alpha * 0.6)
            end
            table.insert(alive, bl)
        end
    end
    blooms = alive
    return true
end

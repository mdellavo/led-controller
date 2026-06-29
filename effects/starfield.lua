name = "Starfield"
description = "Stars at varying depths scroll past — nearer ones brighter and faster."

local stars = {}
local NUM_STARS = 35

function init(n)
    stars = {}
    for i = 1, NUM_STARS do
        local depth = math.random() * 0.9 + 0.1   -- 0.1 (near) .. 1.0 (far)
        stars[i] = {
            pos   = math.random() * n,
            depth = depth,
            speed = (1.1 - depth) * 28 + 1.5,
        }
    end
end

function update(buf, dt)
    local n = buf:len()
    buf:clear()
    for _, s in ipairs(stars) do
        s.pos = (s.pos + s.speed * dt) % n
        local v = math.floor((1.0 - s.depth) * 215 + 40)
        buf:plot(s.pos, v, v, v, 1.0)
    end
    return true
end

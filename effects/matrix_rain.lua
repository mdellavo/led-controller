name = "Matrix Rain"
description = "Green falling pixel trails cascade along the strip like The Matrix."

local drops = {}

function init(n)
    drops = {}
    local count = math.max(4, n // 8)
    for i = 1, count do
        drops[i] = { pos = math.random() * n, speed = math.random() * 14 + 8 }
    end
end

function update(buf, dt)
    local n = buf:len()
    buf:fade(0.65^60, dt)
    for _, d in ipairs(drops) do
        d.pos = (d.pos + d.speed * dt) % n
        -- bright white-green head, green trail left by fade
        buf:plot(d.pos,       180, 255, 180, 1.0)
        buf:plot(d.pos - 0.7,   0, 220,   0, 0.7)
    end
    return true
end

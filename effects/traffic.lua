name = "Traffic"
description = "Colored cars travel in both directions with headlights and taillights; collisions flash orange."

local cars       = {}
local collisions = {}
local NUM_CARS   = 8

function init(n)
    cars = {}
    for i = 1, NUM_CARS do
        local spd = n * (0.08 + math.random() * 0.06)
        local dir = (i % 2 == 0) and 1 or -1
        cars[i] = {
            pos = math.random() * n,
            vel = dir * spd,
            r   = math.random(100, 255),
            g   = math.random(100, 255),
            b   = math.random(100, 255),
        }
    end
    collisions = {}
end

function update(buf, dt)
    local n = buf:len()

    -- move
    for _, c in ipairs(cars) do
        c.pos = (c.pos + c.vel * dt) % n
    end

    -- detect collisions (opposite-direction cars within 1.5 px)
    for i = 1, #cars do
        for j = i + 1, #cars do
            local a, b_c = cars[i], cars[j]
            local d = math.abs(a.pos - b_c.pos)
            if d < 1.5 and a.vel * b_c.vel < 0 then
                table.insert(collisions, { pos = (a.pos + b_c.pos) * 0.5, life = 0.5 })
                a.vel, b_c.vel = b_c.vel * 0.9, a.vel * 0.9
            end
        end
    end

    buf:clear()

    -- draw cars
    for _, c in ipairs(cars) do
        local head = (c.vel > 0) and c.pos + 0.8 or c.pos - 0.8
        local tail = (c.vel > 0) and c.pos - 0.8 or c.pos + 0.8
        buf:plot(c.pos, c.r, c.g, c.b, 1.0)
        buf:plot(head, 210, 210, 210, 0.85)   -- headlight: white
        buf:plot(tail, 200,   0,   0, 0.75)   -- taillight: red
    end

    -- draw collisions
    local alive = {}
    for _, col in ipairs(collisions) do
        col.life = col.life - dt
        if col.life > 0 then
            buf:plot(col.pos, 255, 180, 20, math.min(1.0, col.life * 2.5))
            table.insert(alive, col)
        end
    end
    collisions = alive

    return true
end

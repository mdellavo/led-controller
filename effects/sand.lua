name = "Sand"
description = "Sandy particles settle under gravity, then scatter with a periodic shake"

local NUM_PARTICLES = 22
local particles = {}
local shake_timer = 0.0
local SHAKE_INTERVAL = 5.0
local GRAVITY = 0.0  -- set in init

function init(n)
    GRAVITY = n * 2.8
    shake_timer = 0.0
    particles = {}
    for i = 1, NUM_PARTICLES do
        table.insert(particles, {
            pos     = math.random() * (n - 1),
            vel     = 0.0,
            damping = math.random() * 0.35 + 0.25,
            r       = math.random(185, 230),
            g       = math.random(145, 190),
            b       = math.random(35,  75),
        })
    end
end

function update(buf, dt)
    local n = buf:len()
    buf:clear()

    -- Periodic shake launches all particles upward
    shake_timer = shake_timer + dt
    if shake_timer >= SHAKE_INTERVAL then
        shake_timer = 0.0
        for _, p in ipairs(particles) do
            p.vel = -(math.random() * n * 2.2 + n * 0.4)
        end
    end

    for _, p in ipairs(particles) do
        p.vel = p.vel + GRAVITY * dt
        p.pos = p.pos + p.vel * dt

        -- Bounce off bottom with damping
        if p.pos >= n - 1 then
            p.pos = n - 1
            p.vel = -math.abs(p.vel) * p.damping
            if math.abs(p.vel) < 3 then p.vel = 0 end
        end

        -- Ceiling bounce
        if p.pos < 0 then
            p.pos = 0
            p.vel = math.abs(p.vel) * 0.6
        end

        buf:plot(p.pos, p.r, p.g, p.b, 1.0)
    end

    return true
end

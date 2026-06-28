name = "Drip"
description = "Colored drops spawn at one end, accelerate under gravity, and splat at the other end"

-- Colored drops spawn at index 0, accelerate under gravity, and splat at the far end.
-- The splat leaves a brief bright burst that fades with the rest of the trail.
local drops          = {}
local spawn_timer    = 0.0
local spawn_interval = 0.7  -- seconds between drops

function init(n)
    drops       = {}
    spawn_timer = 0.0
end

local function new_drop()
    return {
        pos = 0.0,
        vel = 0.0,
        r   = math.random(80, 255),
        g   = math.random(80, 255),
        b   = math.random(80, 255),
    }
end

function update(buf, dt)
    local n       = buf:len()
    local gravity = n * 8.0  -- px/s²

    spawn_timer = spawn_timer + dt
    if spawn_timer >= spawn_interval then
        spawn_timer = spawn_timer - spawn_interval
        table.insert(drops, new_drop())
    end

    buf:fade(0.65 ^ 60, dt)

    local i = 1
    while i <= #drops do
        local d = drops[i]
        d.vel = d.vel + gravity * dt
        d.pos = d.pos + d.vel * dt

        if d.pos >= n - 1 then
            -- splat: brief bright burst across a few pixels at the end
            for j = math.max(0, n - 4), n - 1 do
                buf:set(j, d.r, d.g, d.b)
            end
            table.remove(drops, i)
        else
            buf:plot(d.pos, d.r, d.g, d.b, 1.0)
            i = i + 1
        end
    end

    return true
end

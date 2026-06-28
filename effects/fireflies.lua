name = "Fireflies"
description = "Dim drifting dots that randomly glow bright then fade, like fireflies on a summer night"

local NUM = 15
local flies = {}

function init(n)
    flies = {}
    for i = 1, NUM do
        table.insert(flies, {
            pos     = math.random() * (n - 1),
            vel     = (math.random() * 0.4 + 0.1) * (math.random() < 0.5 and 1 or -1),
            bright  = 0.01,
            target  = 0.01,
            glowing = false,
            timer   = math.random() * 4.0 + 0.5,
            phase   = math.random() * 2 * math.pi,
        })
    end
end

function update(buf, dt)
    local n = buf:len()
    buf:clear()

    for _, f in ipairs(flies) do
        -- Gentle drift with slow sine wander
        f.phase = f.phase + dt * 0.6
        f.pos   = (f.pos + (f.vel + math.sin(f.phase) * 0.35) * dt) % n

        -- State: dim ↔ glowing
        f.timer = f.timer - dt
        if f.timer <= 0 then
            if not f.glowing then
                f.glowing = true
                f.target  = math.random() * 0.7 + 0.3
                f.timer   = math.random() * 0.6 + 0.2
            else
                f.glowing = false
                f.target  = 0.01
                f.timer   = math.random() * 4.0 + 1.5
            end
        end

        -- Smooth brightness approach (rate-independent)
        f.bright = f.bright + (f.target - f.bright) * (1 - 0.01^dt)

        -- Yellow-green firefly glow
        local b = f.bright
        buf:plot(f.pos, math.floor(220 * b), math.floor(255 * b), math.floor(50 * b), 1.0)
    end

    return true
end

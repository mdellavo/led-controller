name = "Random Fade"
description = "Sparks of random color ignite at random positions, ramp up to peak brightness, then fade out"

local sparks = {}
local spawn_timer = 0.0
local spawn_interval = 0.1

function update(buf, dt)
    local n = buf:len()

    spawn_timer = spawn_timer + dt
    while spawn_timer >= spawn_interval do
        spawn_timer = spawn_timer - spawn_interval
        table.insert(sparks, {
            index   = math.random(0, n - 1),
            r       = math.random(0, 255),
            g       = math.random(0, 255),
            b       = math.random(0, 255),
            life    = 0.0,
            max_life = math.random() * 2.0 + 0.5,
        })
    end

    -- delta-time-correct trail decay (0.90 per frame at 60 fps)
    buf:fade(0.90 ^ 60, dt)

    local i = 1
    while i <= #sparks do
        local s = sparks[i]
        s.life = s.life + dt
        if s.life >= s.max_life then
            table.remove(sparks, i)
        else
            local t = s.life / s.max_life
            local brightness = t < 0.3 and (t / 0.3) or (1.0 - (t - 0.3) / 0.7)
            buf:set(s.index,
                math.floor(s.r * brightness),
                math.floor(s.g * brightness),
                math.floor(s.b * brightness))
            i = i + 1
        end
    end

    return true
end

name = "Bioluminescence"
description = "Deep ocean darkness with expanding blue-green pulses, like disturbed bioluminescent plankton"

local pulses      = {}
local spawn_timer = 0.0
local SPAWN_INT   = 0.85

function update(buf, dt)
    local n = buf:len()

    -- Deep blue-black base
    for i = 0, n - 1 do buf:set(i, 0, 4, 18) end

    -- Spawn new disturbance pulses
    spawn_timer = spawn_timer + dt
    if spawn_timer >= SPAWN_INT then
        spawn_timer = spawn_timer - SPAWN_INT
        table.insert(pulses, {
            center = math.random(0, n - 1),
            radius = 0.0,
            speed  = n * 0.22,
            max_r  = n * 0.42,
        })
    end

    local i = 1
    while i <= #pulses do
        local p = pulses[i]
        p.radius = p.radius + p.speed * dt
        local life = 1.0 - p.radius / p.max_r

        if life <= 0 then
            table.remove(pulses, i)
        else
            if p.radius < 1.0 then
                -- Initial burst at tap point
                buf:plot(p.center, 20, 220, 195, life)
            else
                -- Two expanding wavefronts (bounds-checked to avoid wrap)
                local right = p.center + p.radius
                local left  = p.center - p.radius
                if right >= 0 and right <= n - 1 then
                    buf:plot(right, 20, 220, 195, life * 0.9)
                end
                if left >= 0 and left <= n - 1 then
                    buf:plot(left,  20, 220, 195, life * 0.9)
                end
            end
            i = i + 1
        end
    end

    return true
end

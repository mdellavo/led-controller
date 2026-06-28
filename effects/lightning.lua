name = "Lightning"
description = "Random white strikes flare across the strip, then fade into a flickering blue-white afterglow"

-- Idle → blinding white strike → flickering blue-white afterglow → idle.
-- Random delay between strikes keeps it unpredictable.
local state      = "idle"
local idle_ms    = 2000.0
local strike_ms  = 80.0
local brightness = 0.0
local timer      = 0.0

function init(n)
    state      = "idle"
    idle_ms    = math.random(500, 3000)
    timer      = 0.0
    brightness = 0.0
end

function update(buf, dt)
    local n = buf:len()
    timer = timer + dt * 1000.0

    if state == "idle" then
        buf:clear()
        if timer >= idle_ms then
            state = "strike"
            timer = 0.0
        end

    elseif state == "strike" then
        for i = 0, n - 1 do buf:set(i, 240, 240, 255) end
        if timer >= strike_ms then
            state      = "flicker"
            brightness = 0.8
            timer      = 0.0
        end

    elseif state == "flicker" then
        brightness = brightness - dt * 1.8
        if brightness <= 0.0 then
            state   = "idle"
            idle_ms = math.random(500, 3000)
            timer   = 0.0
            buf:clear()
        else
            local b = brightness
            if math.random() < 0.3 then
                b = b * (math.random() * 0.5 + 0.5)
            end
            local v  = math.floor(b * 240)
            local bv = math.floor(b * 255)
            for i = 0, n - 1 do buf:set(i, v, v, bv) end
        end
    end

    return true
end

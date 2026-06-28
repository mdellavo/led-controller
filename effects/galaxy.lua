name = "Galaxy"
description = "Soft drifting nebula of blues and purples with occasional bright star flares"

local stars    = {}
local nebula_t = 0.0

function init(n)
    stars = {}
    for i = 1, 10 do
        table.insert(stars, {
            pos    = math.random(0, n - 1),
            bright = 0.0,
            state  = "dim",
            timer  = math.random() * 5.0,
            wr     = math.random(180, 255),
            wg     = math.random(180, 255),
            wb     = math.random(220, 255),
        })
    end
end

function update(buf, dt)
    local n = buf:len()
    nebula_t = nebula_t + dt * 0.06

    -- Nebula: slow soft blue-purple haze
    for i = 0, n - 1 do
        local x  = i / n * 2 * math.pi
        local v1 = (math.sin(x * 1.4 + nebula_t      ) + 1) / 2
        local v2 = (math.sin(x * 0.6 - nebula_t * 0.7) + 1) / 2
        local g  = v1 * 0.55 + v2 * 0.45

        buf:set(i,
            math.floor((18 + 55  * g) * 0.5),
            math.floor(( 4 + 18  * g) * 0.5),
            math.floor((55 + 115 * g) * 0.5))
    end

    -- Stars: dim → flaring → fading → relocate → repeat
    for _, s in ipairs(stars) do
        s.timer = s.timer - dt
        if s.timer <= 0 then
            if s.state == "dim" then
                s.state = "flaring"
                s.timer = math.random() * 0.5 + 0.2
            elseif s.state == "flaring" then
                s.state = "fading"
                s.timer = math.random() * 2.0 + 0.5
            else
                s.state = "dim"
                s.timer = math.random() * 6.0 + 2.0
                s.pos   = math.random(0, n - 1)
            end
        end

        local target = s.state == "flaring" and 1.0 or 0.0
        s.bright = s.bright + (target - s.bright) * (1 - 0.005^dt)

        if s.bright > 0.02 then
            local er, eg, eb = buf:get(s.pos)
            buf:set(s.pos,
                math.min(255, er + math.floor(s.wr * s.bright)),
                math.min(255, eg + math.floor(s.wg * s.bright)),
                math.min(255, eb + math.floor(s.wb * s.bright)))
        end
    end

    return true
end

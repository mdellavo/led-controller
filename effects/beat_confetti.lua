name        = "Beat Confetti"
description = "On each beat a burst of colorful dots scatter from a random position and drift outward. Quiet periods fade to dark."

local dots = {}
local last_beat = 0

local function hsv(h, s, v)
    local i = math.floor(h / 60) % 6
    local f = h / 60 - math.floor(h / 60)
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    local r, g, b
    if     i == 0 then r,g,b = v,t,p
    elseif i == 1 then r,g,b = q,v,p
    elseif i == 2 then r,g,b = p,v,t
    elseif i == 3 then r,g,b = p,q,v
    elseif i == 4 then r,g,b = t,p,v
    else              r,g,b = v,p,q end
    return math.floor(r*255), math.floor(g*255), math.floor(b*255)
end

function update(buf, dt)
    local n    = buf:len()
    local beat = AUDIO_BEAT or 0
    local amp  = AUDIO_AMP  or 0

    if beat > 0.5 and last_beat <= 0.5 then
        local center = math.random(0, n - 1)
        local count  = math.floor(3 + beat * 14)
        for _ = 1, count do
            local h = math.random(0, 359)
            local r, g, b = hsv(h, 1, 1)
            -- Random speed in either direction
            local vel = (math.random() * 2 - 1) * n * (0.3 + beat * 0.6)
            table.insert(dots, { pos = center + 0.0, vel = vel, r = r, g = g, b = b, life = 1.0 })
        end
    end
    last_beat = beat

    buf:fade(0.05 + amp * 0.1, dt)

    local alive = {}
    for _, d in ipairs(dots) do
        d.pos  = d.pos + d.vel * dt
        d.life = d.life - dt * 1.2
        if d.life > 0 then
            buf:plot(d.pos % n, d.r, d.g, d.b, d.life)
            table.insert(alive, d)
        end
    end
    dots = alive

    return true
end

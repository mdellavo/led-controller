name        = "Beat Bounce"
description = "Balls launch from both ends of the strip on each beat. Harder hits mean faster balls. Multiple balls accumulate with fading trails."

local balls = {}
local last_beat = 0
local hue = 0

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
    local n   = buf:len()
    local beat = AUDIO_BEAT or 0
    local amp  = AUDIO_AMP  or 0

    -- Launch a pair of balls on each beat rising edge
    if beat > 0.55 and last_beat <= 0.55 then
        hue = (hue + 47) % 360
        local speed = n * (0.7 + beat * 1.2)
        local r1, g1, b1 = hsv(hue, 1, 1)
        local r2, g2, b2 = hsv((hue + 180) % 360, 1, 1)
        table.insert(balls, { pos = 0,     vel =  speed, r = r1, g = g1, b = b1 })
        table.insert(balls, { pos = n - 1, vel = -speed, r = r2, g = g2, b = b2 })
    end
    last_beat = beat

    buf:fade(0.06 + amp * 0.06, dt)

    local alive = {}
    for _, ball in ipairs(balls) do
        ball.pos = ball.pos + ball.vel * dt
        if ball.pos >= -1 and ball.pos < n + 1 then
            buf:plot(ball.pos, ball.r, ball.g, ball.b, 1.0)
            table.insert(alive, ball)
        end
    end
    balls = alive

    return true
end

name        = "Beat Comet"
description = "A bright comet launches on each beat — harder hits send it faster and leave longer trails. Multiple comets accumulate."

local comets = {}
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
    local n    = buf:len()
    local beat = AUDIO_BEAT or 0
    local amp  = AUDIO_AMP  or 0

    if beat > 0.45 and last_beat <= 0.45 then
        hue = (hue + 73) % 360
        local dir   = math.random() < 0.5 and 1 or -1
        local speed = n * (0.6 + beat * 1.5)
        local start = dir > 0 and 0.0 or (n - 1.0)
        local r, g, b = hsv(hue, 0.85, 1)
        table.insert(comets, { pos = start, vel = dir * speed, r = r, g = g, b = b, intensity = beat })
    end
    last_beat = beat

    -- Trail decay: longer at high amplitude (brighter music → more vivid trails)
    local decay = 0.04 + amp * 0.25
    buf:fade(decay, dt)

    local alive = {}
    for _, c in ipairs(comets) do
        c.pos = c.pos + c.vel * dt
        if c.pos >= -2 and c.pos < n + 2 then
            buf:plot(c.pos, c.r, c.g, c.b, c.intensity)
            table.insert(alive, c)
        end
    end
    comets = alive

    return true
end

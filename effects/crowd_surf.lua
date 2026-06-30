name        = "Crowd Surf"
description = "Particles drift lazily at silence. Loud audio multiplies them and speeds them up. Each beat reverses and accelerates every particle simultaneously."

local particles = {}
local last_beat  = 0
local MAX_P      = 40

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

local function spawn(n)
    if #particles >= MAX_P then return end
    local hue = math.random(0, 359)
    local r, g, b = hsv(hue, 1, 1)
    table.insert(particles, {
        pos = math.random(0, n - 1) + 0.0,
        vel = (math.random() * 2 - 1) * 20,
        r = r, g = g, b = b,
    })
end

function init(n)
    for _ = 1, 8 do spawn(n) end
end

function update(buf, dt)
    local n    = buf:len()
    local amp  = AUDIO_AMP  or 0
    local beat = AUDIO_BEAT or 0

    -- Beat: reverse + amplify every particle and spawn a burst
    if beat > 0.55 and last_beat <= 0.55 then
        for _, p in ipairs(particles) do
            p.vel = p.vel * -(1.2 + beat)
        end
        local burst = math.floor(beat * 12)
        for _ = 1, burst do spawn(n) end
    end
    last_beat = beat

    -- Amplitude slowly adds particles
    if amp > 0.3 and #particles < MAX_P and math.random() < amp * 0.15 then
        spawn(n)
    end

    buf:fade(0.06 + amp * 0.08, dt)

    local alive = {}
    for _, p in ipairs(particles) do
        local speed_scale = 1 + amp * 3
        p.pos = (p.pos + p.vel * speed_scale * dt) % n
        if p.pos < 0 then p.pos = p.pos + n end
        -- Gentle drag toward rest speed
        p.vel = p.vel * (1 - dt * 0.4 * (1 - amp))
        local alpha = 0.25 + amp * 0.75
        buf:plot(p.pos, p.r, p.g, p.b, alpha)
        -- Keep particle alive unless it has nearly stopped and amp is low
        if math.abs(p.vel) > 0.5 or amp > 0.1 then
            table.insert(alive, p)
        end
    end
    particles = alive

    -- Always keep a few alive
    if #particles < 4 then
        for _ = 1, 4 - #particles do spawn(n) end
    end

    return true
end

name        = "Audio Plasma"
description = "Plasma interference pattern whose four wave frequencies are modulated in real-time by spectrum bands — the shape literally changes with the music."

local t = 0

local function hsv(h, s, v)
    local i = math.floor(h / 60) % 6
    local f = h / 60 - math.floor(h / 60)
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local tv = v * (1 - (1 - f) * s)
    local r, g, b
    if     i == 0 then r,g,b = v,tv,p
    elseif i == 1 then r,g,b = q,v,p
    elseif i == 2 then r,g,b = p,v,tv
    elseif i == 3 then r,g,b = p,q,v
    elseif i == 4 then r,g,b = tv,p,v
    else              r,g,b = v,p,q end
    return math.floor(r*255), math.floor(g*255), math.floor(b*255)
end

function update(buf, dt)
    local n    = buf:len()
    local amp  = AUDIO_AMP  or 0
    local beat = AUDIO_BEAT or 0
    local spec = AUDIO_SPECTRUM

    t = t + dt

    -- Four waves; their spatial frequencies are driven by spectrum bands
    -- Bass → wave 1, low-mid → wave 2, high-mid → wave 3, treble → wave 4
    local f1 = 1.0 + (spec and spec[2]  or 0) * 5
    local f2 = 2.0 + (spec and spec[5]  or 0) * 7
    local f3 = 1.5 + (spec and spec[9]  or 0) * 6
    local f4 = 0.8 + (spec and spec[13] or 0) * 4

    local speed = 0.6 + amp * 2.5
    local pi2   = 2 * math.pi

    for px = 0, n - 1 do
        local x = px / n

        local v1 = math.sin(x * f1 * pi2 + t * speed)
        local v2 = math.sin(x * f2 * pi2 - t * speed * 0.7)
        local v3 = math.sin(x * f3 * pi2 + t * speed * 1.4)
        local v4 = math.sin((x + 0.3) * f4 * pi2 - t * speed * 0.5)

        local v = (v1 + v2 + v3 + v4) / 4   -- -1..1
        local hue = ((v + 1) * 0.5 * 360 + beat * 90) % 360
        local bri = 0.2 + amp * 0.8
        local r, g, b = hsv(hue, 0.9, bri)
        buf:set(px, r, g, b)
    end

    return true
end

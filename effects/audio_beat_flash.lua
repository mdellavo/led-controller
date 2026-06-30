name        = "Audio Beat Flash"
description = "Flashes white on each beat, with a color background that breathes with amplitude."

local hue = 0

-- HSV → RGB (h: 0–360, s/v: 0–1) returns r,g,b as integers 0–255
local function hsv(h, s, v)
    local i = math.floor(h / 60) % 6
    local f = h / 60 - math.floor(h / 60)
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local tv = v * (1 - (1 - f) * s)
    local r, g, b
    if i == 0 then r,g,b = v,tv,p
    elseif i == 1 then r,g,b = q,v,p
    elseif i == 2 then r,g,b = p,v,tv
    elseif i == 3 then r,g,b = p,q,v
    elseif i == 4 then r,g,b = tv,p,v
    else r,g,b = v,p,q end
    return math.floor(r*255), math.floor(g*255), math.floor(b*255)
end

function update(buf, dt)
    local beat = AUDIO_BEAT or 0
    local amp  = AUDIO_AMP  or 0

    hue = (hue + dt * 30) % 360

    buf:clear()

    -- Background: slow-cycling hue, amplitude-modulated brightness
    local br = 0.05 + amp * 0.4
    local r, g, b = hsv(hue, 0.9, br)
    for i = 0, buf:len() - 1 do
        buf:set(i, r, g, b)
    end

    -- Beat flash: add white proportional to beat envelope
    if beat > 0.01 then
        local flash = math.floor(beat * 220)
        for i = 0, buf:len() - 1 do
            local cr, cg, cb = buf:get(i)
            buf:set(i,
                math.min(255, cr + flash),
                math.min(255, cg + flash),
                math.min(255, cb + flash))
        end
    end

    return true
end

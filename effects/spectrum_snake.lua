name        = "Spectrum Snake"
description = "A snake speeds up on each beat and shifts color toward the currently dominant frequency band — bass makes it red, treble makes it violet."

local head      = 0.0
local direction = 1
local body      = {}
local BODY_LEN  = 24
local hue       = 0.0

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

local function dominant_band()
    local spec = AUDIO_SPECTRUM
    if not spec then return 8 end
    local best_val, best_band = 0, 8
    for i = 1, 16 do
        local v = spec[i] or 0
        if v > best_val then best_val = v; best_band = i end
    end
    return best_band
end

function init(n)
    head = n / 2
    body = {}
    for i = 1, BODY_LEN do
        body[i] = head - i * direction
    end
end

function update(buf, dt)
    local n    = buf:len()
    local beat = AUDIO_BEAT or 0
    local amp  = AUDIO_AMP  or 0

    -- Speed scales with beat and amplitude
    local speed = (n * 0.4) * (1 + beat * 4 + amp)
    head = head + direction * speed * dt

    if head >= n then
        head = n - 1; direction = -1
    elseif head < 0 then
        head = 0; direction = 1
    end

    -- Shift body
    for i = BODY_LEN, 2, -1 do body[i] = body[i - 1] end
    body[1] = head

    -- Smoothly track dominant frequency band → hue
    local band       = dominant_band()
    local target_hue = (band - 1) / 15 * 270
    hue = hue + 8 * dt * (target_hue - hue)

    buf:fade(0.06, dt)

    for i, pos in ipairs(body) do
        local bri = (1 - (i - 1) / BODY_LEN) * (0.3 + amp * 0.7)
        if bri > 0.02 then
            local r, g, b = hsv(hue, 0.9, bri)
            buf:plot(pos % n, r, g, b, bri)
        end
    end

    return true
end

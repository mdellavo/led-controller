name        = "Audio Spectrum"
description = "Displays the 16-band frequency spectrum as a bar graph across the strip. Bass on the left, treble on the right."

local smoothed = {}
for i = 1, 16 do smoothed[i] = 0 end

-- Band index → hue (bass=red, treble=violet)
local function band_hue(i)
    return (i - 1) / 15 * 270  -- 0° red → 270° violet
end

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
    local n = buf:len()
    local spec = AUDIO_SPECTRUM  -- 1-indexed table of 16 values

    -- Smooth each band: fast attack, slower release
    for i = 1, 16 do
        local v = (spec and spec[i]) or 0
        local alpha = v > smoothed[i] and 0.6 or 0.15
        smoothed[i] = smoothed[i] + alpha * (v - smoothed[i])
    end

    buf:clear()

    -- Each of the 16 bands gets n/16 pixels
    local seg = n / 16
    for band = 1, 16 do
        local level  = smoothed[band]
        local hue    = band_hue(band)
        local lo_px  = math.floor((band - 1) * seg)
        local hi_px  = math.floor(band * seg) - 1

        for px = lo_px, hi_px do
            -- Within this segment, light pixels up to the level mark
            local frac = (px - lo_px) / math.max(1, hi_px - lo_px)
            local brightness = frac <= level and (0.15 + level * 0.85) or 0.04
            local r, g, b = hsv(hue, 1.0, brightness)
            buf:set(px, r, g, b)
        end
    end

    return true
end

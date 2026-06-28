name = "Oil Slick"
description = "Dark iridescent rainbow sheen slowly shifts across the strip like light on spilled oil"

local t = 0.0
local SPEED = 0.12

local function colorwheel(p)
    p = math.floor(p) % 256
    p = (255 - p) % 256
    if p < 85 then return 255-p*3, 0, p*3
    elseif p < 170 then p=p-85; return 0, p*3, 255-p*3
    else p=p-170; return p*3, 255-p*3, 0 end
end

function update(buf, dt)
    local n = buf:len()
    t = t + SPEED * dt

    for i = 0, n - 1 do
        local x = i / n

        -- Interference of multiple spatial frequencies → iridescent shimmer
        local shimmer = math.sin(x * 11.3 + t * 5.7)
                      + math.sin(x *  7.1 - t * 3.2)
                      + math.sin(x *  4.3 + t * 7.1)
        shimmer = (shimmer / 3 + 1) / 2  -- normalise 0..1

        -- Hue drifts with position and time
        local hue    = math.floor((x * 200 + t * 60) % 256)
        local bright = shimmer * 0.65 + 0.04

        local r, g, b = colorwheel(hue)
        buf:set(i,
            math.floor(r * bright),
            math.floor(g * bright),
            math.floor(b * bright))
    end

    return true
end

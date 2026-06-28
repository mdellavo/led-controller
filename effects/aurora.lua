name = "Aurora"
description = "Four overlapping sine-wave bands of green, teal, blue, and purple shimmer at independent speeds"

-- Four overlapping sine-wave bands in cool aurora colors (greens, teals, blues, purples).
-- Each band has its own speed and spatial frequency, creating a living shimmer.
local waves = {
    {phase = 0.0, speed = 0.30, freq = 1.5, hue = 120},
    {phase = 2.1, speed = 0.50, freq = 0.8, hue = 165},
    {phase = 4.2, speed = 0.20, freq = 2.5, hue = 220},
    {phase = 1.0, speed = 0.40, freq = 1.1, hue = 285},
}

local function hue_to_rgb(h)
    h = h % 360
    local i = math.floor(h / 60)
    local f = h / 60 - i
    local q = math.floor((1.0 - f) * 255)
    local t = math.floor(f * 255)
    if     i == 0 then return 255, t,   0
    elseif i == 1 then return q,   255, 0
    elseif i == 2 then return 0,   255, t
    elseif i == 3 then return 0,   q,   255
    elseif i == 4 then return t,   0,   255
    else                return 255, 0,   q
    end
end

function update(buf, dt)
    local n = buf:len()
    for _, w in ipairs(waves) do
        w.phase = w.phase + w.speed * dt
    end
    for i = 0, n - 1 do
        local x = i / n * 2.0 * math.pi
        local ra, ga, ba = 0, 0, 0
        for _, w in ipairs(waves) do
            local bright = ((math.sin(x * w.freq + w.phase) + 1.0) / 2.0) ^ 1.5
            local wr, wg, wb = hue_to_rgb(w.hue)
            ra = ra + wr * bright
            ga = ga + wg * bright
            ba = ba + wb * bright
        end
        buf:set(i,
            math.min(255, math.floor(ra * 0.5)),
            math.min(255, math.floor(ga * 0.5)),
            math.min(255, math.floor(ba * 0.5)))
    end
    return true
end

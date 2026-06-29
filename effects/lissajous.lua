name = "Lissajous"
description = "Parametric Lissajous figure mapped to the strip — brightness shows the curve density at each position."

local function colorwheel(pos)
    pos = math.floor(pos) % 256
    pos = (255 - pos) % 256
    if pos < 85 then return 255-pos*3, 0, pos*3
    elseif pos < 170 then pos=pos-85; return 0, pos*3, 255-pos*3
    else pos=pos-170; return pos*3, 255-pos*3, 0 end
end

-- Interesting frequency ratios (a:b)
local RATIOS = { {3,2}, {5,4}, {5,3}, {4,3}, {7,4}, {7,5}, {2,1} }
local ra, rb      = 3, 2
local ratio_idx   = 1
local ratio_timer = 0.0
local RATIO_PERIOD = 9.0

local delta = math.pi / 4   -- phase offset (slowly drifts)
local hue   = 0.0
local t     = 0.0

function init(n)
    t         = 0
    hue       = math.random(0, 255)
    ratio_idx = 1
    ra, rb    = RATIOS[1][1], RATIOS[1][2]
    delta     = math.pi / 4
    ratio_timer = 0
end

function update(buf, dt)
    local n = buf:len()
    t     = t + dt
    hue   = (hue + 16 * dt) % 256
    delta = delta + dt * 0.35
    ratio_timer = ratio_timer + dt

    if ratio_timer >= RATIO_PERIOD then
        ratio_timer = 0
        ratio_idx   = (ratio_idx % #RATIOS) + 1
        ra, rb      = RATIOS[ratio_idx][1], RATIOS[ratio_idx][2]
    end

    -- Accumulate brightness by sampling the parametric curve
    local bright = {}
    for p = 0, n - 1 do bright[p] = 0.0 end

    local SAMPLES = 900
    for i = 0, SAMPLES - 1 do
        local s = i / SAMPLES * math.pi * 2
        local x = (math.sin(ra * s + delta) + 1) * 0.5   -- 0..1 → position
        local y = (math.sin(rb * s)          + 1) * 0.5   -- 0..1 → brightness
        local p = math.floor(x * (n - 1) + 0.5)
        if p >= 0 and p < n then
            bright[p] = bright[p] + y
        end
    end

    -- Normalize and render
    local mx = 0.001
    for p = 0, n - 1 do if bright[p] > mx then mx = bright[p] end end

    local cr, cg, cb = colorwheel(math.floor(hue))
    for p = 0, n - 1 do
        local v = bright[p] / mx
        buf:set(p, math.floor(cr * v), math.floor(cg * v), math.floor(cb * v))
    end
    return true
end

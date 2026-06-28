name = "Sunrise"
description = "Slow day cycle shifting through night purple, deep red, orange, golden yellow, and back"

local PERIOD = 40.0  -- seconds per full day cycle
local timer  = 0.0

local KEYS = {
    { 0.00, {  0,   0,   3} },  -- night
    { 0.08, { 25,   0,  50} },  -- pre-dawn purple
    { 0.20, {120,  15,   0} },  -- deep red
    { 0.35, {230,  80,   0} },  -- orange
    { 0.50, {255, 215,  45} },  -- golden peak
    { 0.65, {230, 100,  10} },  -- afternoon gold
    { 0.78, {150,  35,   0} },  -- sunset red
    { 0.88, { 28,   4,  22} },  -- dusk purple
    { 1.00, {  0,   0,   3} },  -- night
}

local function sky_color(t)
    local k1, k2 = KEYS[1], KEYS[#KEYS]
    for i = 1, #KEYS - 1 do
        if t >= KEYS[i][1] and t <= KEYS[i + 1][1] then
            k1, k2 = KEYS[i], KEYS[i + 1]
            break
        end
    end
    local span = k2[1] - k1[1]
    local frac = span > 0 and (t - k1[1]) / span or 0
    -- Cosine ease for smooth keyframe transitions
    frac = (1 - math.cos(frac * math.pi)) / 2
    local a, b = k1[2], k2[2]
    return
        math.floor(a[1] * (1 - frac) + b[1] * frac),
        math.floor(a[2] * (1 - frac) + b[2] * frac),
        math.floor(a[3] * (1 - frac) + b[3] * frac)
end

function update(buf, dt)
    local n = buf:len()
    timer = (timer + dt) % PERIOD
    local r, g, b = sky_color(timer / PERIOD)
    for i = 0, n - 1 do buf:set(i, r, g, b) end
    return true
end

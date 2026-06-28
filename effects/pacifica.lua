name = "Pacifica"
description = "Three-layer ocean wave simulation in deep blue-green, inspired by FastLED's Pacifica"

local t1 = 0.0
local t2 = 0.0
local t3 = 0.0

-- Deep-ocean palette: dark teal -> bright aqua -> white crest
local function ocean_rgb(wave, crest)
    -- wave: 0.0 (trough) to 1.0 (peak), crest: extra white
    local r = math.floor(wave * 10  + crest * 255)
    local g = math.floor(wave * 160 + crest * 255)
    local b = math.floor(wave * 220 + crest * 255)
    return math.min(255, r), math.min(255, g), math.min(255, b)
end

function update(buf, dt)
    local n   = buf:len()
    local pi2 = 2 * math.pi

    t1 = t1 + 0.9 * dt
    t2 = t2 + 1.3 * dt
    t3 = t3 + 0.6 * dt

    for i = 0, n - 1 do
        local x = i / n * pi2

        local v1 = (math.sin(x * 1.3 + t1) + 1) / 2
        local v2 = (math.sin(x * 0.8 - t2) + 1) / 2
        local v3 = (math.sin(x * 2.1 + t3 * 0.7) + 1) / 2

        local wave = v1 * 0.45 + v2 * 0.35 + v3 * 0.20

        -- Whitecap brightens peaks that exceed threshold
        local crest = math.max(0, (wave - 0.78) * 4.5) ^ 2 * 0.8

        local r, g, b = ocean_rgb(wave * 0.85 + 0.08, crest)
        buf:set(i, r, g, b)
    end

    return true
end

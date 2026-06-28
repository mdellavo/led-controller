name = "Lua Fire"

-- Classic fire simulation: heat diffuses upward and cools downward.
-- Each cell is a heat value 0–255 mapped to a black→red→yellow→white palette.

local heat = {}

function init(n)
    for i = 0, n - 1 do heat[i] = 0 end
end

local function palette(t)
    -- t: 0.0 (black) → 1.0 (white) via red → orange → yellow
    if t < 0.33 then
        return math.floor(t / 0.33 * 255), 0, 0
    elseif t < 0.66 then
        local f = (t - 0.33) / 0.33
        return 255, math.floor(f * 160), 0
    else
        local f = (t - 0.66) / 0.34
        return 255, math.floor(160 + f * 95), math.floor(f * 255)
    end
end

function update(buf, dt)
    local n = buf:len()
    local cooling  = 55 * dt
    local sparking = 0.5  -- probability per pixel at base

    -- Cool every cell
    for i = 0, n - 1 do
        heat[i] = math.max(0, heat[i] - math.random() * cooling)
    end

    -- Diffuse heat upward (toward index 0)
    for i = n - 1, 2, -1 do
        heat[i] = (heat[i - 1] + heat[i - 2] + heat[i - 2]) / 3.0
    end

    -- Randomly ignite sparks at the base
    if math.random() < sparking then
        local y = math.random(0, math.min(7, n - 1))
        heat[y] = math.min(1.0, heat[y] + math.random() * 0.6 + 0.2)
    end

    -- Map heat to colour and write buffer
    for i = 0, n - 1 do
        local r, g, b = palette(heat[i])
        buf:set(n - 1 - i, r, g, b)   -- base at the bottom (high index)
    end

    return true
end

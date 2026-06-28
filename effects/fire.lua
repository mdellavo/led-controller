name = "Fire"
description = "Heat-diffusion simulation: base glows hot, heat rises upward through a black→red→yellow→white palette"

-- Faithful port of Rust FireEffect: integer heat 0-255, same cooling/sparking/diffusion.
local cooling = 55
local sparking = 120  -- threshold out of 255
local speed_ms = 15.0

local heat = {}
local timer = 0.0

function init(n)
    heat = {}
    for i = 1, n do heat[i] = 0 end
    timer = 0.0
end

local function heat_to_color(h)
    if h < 85 then
        return h * 3, 0, 0
    elseif h < 170 then
        local t = h - 85
        return 255, t * 3, 0
    else
        local t = h - 170
        return 255, 255, t * 3
    end
end

function update(buf, dt)
    local n = buf:len()
    timer = timer + dt * 1000.0

    if timer < speed_ms then
        for i = 1, n do
            local r, g, b = heat_to_color(heat[i])
            buf:set(i - 1, r, g, b)
        end
        return true
    end
    timer = timer - speed_ms

    -- Step 1: cool down every cell by a random amount
    local cool_max = math.floor(cooling * 10 / n) + 2
    for i = 1, n do
        local cool = math.random(0, cool_max)
        heat[i] = math.max(0, heat[i] - cool)
    end

    -- Step 2: diffuse heat upward (index 1 = base/hot, index n = top/cool)
    for i = n, 3, -1 do
        heat[i] = math.floor((heat[i - 1] + heat[i - 2] + heat[i - 2]) / 3)
    end

    -- Step 3: ignite sparks near the base
    if math.random(0, 255) < sparking then
        local y = math.random(1, math.min(7, n))
        heat[y] = math.min(255, heat[y] + math.random(160, 255))
    end

    -- Step 4: map heat to colour
    for i = 1, n do
        local r, g, b = heat_to_color(heat[i])
        buf:set(i - 1, r, g, b)
    end

    return true
end

name = "Snake"
description = "Classic snake grows as it eats food items, bouncing between the strip ends."

local body  = {}
local food  = 0
local dir   = 1
local grow  = 0
local accum = 0
local SPEED = 10   -- steps per second

function init(n)
    body = {}
    for i = 1, 6 do body[i] = math.floor(n / 2) - i + 1 end
    food  = math.random(0, n - 1)
    dir   = 1
    grow  = 0
    accum = 0
end

function update(buf, dt)
    local n = buf:len()
    accum = accum + dt
    local step = 1.0 / SPEED

    while accum >= step do
        accum = accum - step
        local head = body[1] + dir

        -- bounce at walls
        if head >= n then head = n - 2; dir = -1
        elseif head < 0 then head = 1; dir = 1 end

        table.insert(body, 1, head)

        if head == food then
            grow = grow + 5
            local tries, ok = 0, false
            while tries < 30 and not ok do
                food = math.random(0, n - 1)
                ok = true
                for _, p in ipairs(body) do if p == food then ok = false; break end end
                tries = tries + 1
            end
        end

        if grow > 0 then grow = grow - 1
        else table.remove(body) end
    end

    buf:clear()
    -- food: red pulse
    buf:plot(food, 255, 40, 40, 1.0)
    -- snake: bright green head fading to dark tail
    for i, pos in ipairs(body) do
        local frac = 1.0 - (i - 1) / math.max(#body, 1)
        buf:plot(pos, 0, math.floor(frac * 200 + 40), math.floor((1 - frac) * 80), 1.0)
    end
    return true
end

name = "Virus"
description = "Infection seeds spread outward to neighbors, color shifts green→red as it ages, then resets."

local SPREAD_INTERVAL = 0.22   -- seconds between spread steps
local MAX_AGE         = 5.0    -- seconds until a cell dies

local cells  = {}   -- age >= 0 means infected; -1 means healthy
local timer  = 0.0

local function seed(n)
    cells = {}
    for i = 0, n - 1 do cells[i] = -1 end
    for _ = 1, math.random(1, 3) do
        cells[math.random(0, n - 1)] = 0.0
    end
    timer = 0.0
end

function init(n)
    seed(n)
end

function update(buf, dt)
    local n = buf:len()
    timer = timer + dt

    -- spread step
    if timer >= SPREAD_INTERVAL then
        timer = timer - SPREAD_INTERVAL
        local new_cells = {}
        for i = 0, n - 1 do new_cells[i] = cells[i] end
        for i = 0, n - 1 do
            if cells[i] >= 0 then
                if i > 0     and cells[i - 1] < 0 then new_cells[i - 1] = 0.0 end
                if i < n - 1 and cells[i + 1] < 0 then new_cells[i + 1] = 0.0 end
            end
        end
        cells = new_cells
    end

    -- age cells; detect full extinction
    local any_alive    = false
    local any_infected = false
    for i = 0, n - 1 do
        if cells[i] >= 0 then
            cells[i]   = cells[i] + dt
            any_infected = true
            if cells[i] < MAX_AGE then any_alive = true end
        end
    end
    if any_infected and not any_alive then seed(n) end

    -- render: green (young) → yellow → red → fades out
    buf:clear()
    for i = 0, n - 1 do
        local age = cells[i]
        if age >= 0 then
            local t2   = math.min(1.0, age / MAX_AGE)
            local fade = t2 < 0.75 and 1.0 or (1.0 - (t2 - 0.75) / 0.25)
            local r    = math.floor(math.min(1.0, t2 * 2.5) * 220 * fade)
            local g    = math.floor(math.max(0.0, 1.0 - t2 * 2.0) * 200 * fade)
            buf:set(i, r, g, 0)
        end
    end
    return true
end

name = "Cellular Automata"
description = "Rule 30 cellular automaton; complex patterns emerge each generation from a simple 3-cell neighborhood rule"

-- Rule 30: 00011110₂  (index = left*4 + center*2 + right)
local RULE = {[0]=0,[1]=1,[2]=1,[3]=1,[4]=1,[5]=0,[6]=0,[7]=0}

local cells   = {}
local hue     = 0
local timer   = 0.0
local gen     = 0
local reset_at = 0

local function colorwheel(p)
    p = math.floor(p) % 256
    p = (255 - p) % 256
    if p < 85 then return 255-p*3, 0, p*3
    elseif p < 170 then p=p-85; return 0, p*3, 255-p*3
    else p=p-170; return p*3, 255-p*3, 0 end
end

function init(n)
    cells = {}
    for i = 1, n do cells[i] = 0 end
    cells[math.floor(n / 2) + 1] = 1  -- single seed at center
    hue      = math.random(0, 255)
    gen      = 0
    reset_at = math.random(n, n * 3)
end

local function step(n)
    local new = {}
    local sum = 0
    for i = 1, n do
        local l = cells[((i - 2) % n) + 1]
        local c = cells[i]
        local r = cells[(i % n) + 1]
        new[i] = RULE[l * 4 + c * 2 + r]
        sum = sum + new[i]
    end
    cells = new
    -- Avoid stuck-all-same state
    if sum == 0 or sum == n then
        for i = 1, n do cells[i] = math.random(0, 1) end
    end
end

function update(buf, dt)
    local n = buf:len()

    timer = timer + dt
    if timer >= 0.05 then   -- 20 generations / s
        timer = timer - 0.05
        step(n)
        hue = (hue + 2) % 256
        gen = gen + 1
        if gen >= reset_at then init(n) end
    end

    for i = 0, n - 1 do
        if cells[i + 1] == 1 then
            local r, g, b = colorwheel((hue + i * 3) % 256)
            buf:set(i, r, g, b)
        else
            buf:set(i, 4, 4, 4)
        end
    end

    return true
end

name = "Domino"
description = "A tap at one end triggers a chain reaction that cascades to the other end, each pixel tipping the next"

local lit      = {}    -- per-pixel brightness 0..1
local front    = -1.0  -- leading edge of cascade
local running  = false
local pause    = 1.0   -- initial pause before first cascade
local hue      = 0
local SPEED    = 0.0   -- set in init

local function colorwheel(p)
    p = math.floor(p) % 256
    p = (255 - p) % 256
    if p < 85 then return 255-p*3, 0, p*3
    elseif p < 170 then p=p-85; return 0, p*3, 255-p*3
    else p=p-170; return p*3, 255-p*3, 0 end
end

function init(n)
    SPEED = n * 2.2
    lit   = {}
    for i = 1, n do lit[i] = 0.0 end
    front   = -1.0
    running = false
    pause   = 0.8
    hue     = math.random(0, 255)
end

function update(buf, dt)
    local n = buf:len()

    if not running then
        pause = pause - dt
        if pause <= 0 then
            running = true
            front   = 0.0
            hue     = (hue + 45) % 256
            for i = 1, n do lit[i] = 0.0 end
        end
    else
        local prev_idx = math.floor(front)
        front = front + SPEED * dt
        -- Light any newly reached pixels
        for i = prev_idx, math.min(math.floor(front), n - 1) do
            lit[i + 1] = 1.0
        end
        if front >= n then
            running = false
            pause   = 1.4
        end
    end

    -- Decay and render
    buf:clear()
    local r0, g0, b0 = colorwheel(hue)
    for i = 1, n do
        if lit[i] > 0.005 then
            lit[i] = lit[i] * (0.18 ^ dt)   -- half-life ~0.37 s
            buf:set(i - 1,
                math.floor(r0 * lit[i]),
                math.floor(g0 * lit[i]),
                math.floor(b0 * lit[i]))
        end
    end

    return true
end

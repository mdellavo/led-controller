name = "Waterfall"
description = "A stream of slowly-shifting color flows steadily from one end to the other"

local hues    = {}   -- ring buffer: index 1 = newest injected color
local inj_hue = 0.0  -- slowly rotating injection hue
local acc     = 0.0  -- fractional pixel accumulator
local RATE    = 0.30 -- fraction of strip length per second

local function colorwheel(p)
    p = math.floor(p) % 256
    p = (255 - p) % 256
    if p < 85 then return 255-p*3, 0, p*3
    elseif p < 170 then p=p-85; return 0, p*3, 255-p*3
    else p=p-170; return p*3, 255-p*3, 0 end
end

function init(n)
    hues    = {}
    inj_hue = math.random(0, 255)
    acc     = 0.0
    for i = 1, n do
        hues[i] = math.floor(inj_hue + i * 256 / n) % 256
    end
end

function update(buf, dt)
    local n = buf:len()

    acc = acc + n * RATE * dt

    while acc >= 1.0 do
        acc = acc - 1.0
        -- Advance injection hue slowly so colors blend naturally
        inj_hue = (inj_hue + math.random() * 4 + 1) % 256
        -- Shift ring: drop oldest (last), prepend newest
        table.remove(hues, n)
        table.insert(hues, 1, inj_hue)
    end

    -- Pixel 0 shows newest color; pixel n-1 shows oldest
    for i = 0, n - 1 do
        local r, g, b = colorwheel(math.floor(hues[i + 1]))
        buf:set(i, r, g, b)
    end

    return true
end

name = "Pendulum Wave"
description = "Multiple pendulums with slightly different periods create mesmerizing wave patterns."

local function colorwheel(pos)
    pos = math.floor(pos) % 256
    pos = (255 - pos) % 256
    if pos < 85 then return 255-pos*3, 0, pos*3
    elseif pos < 170 then pos=pos-85; return 0, pos*3, 255-pos*3
    else pos=pos-170; return pos*3, 255-pos*3, 0 end
end

local N_PEND = 16
local freqs  = {}
local t      = 0

function init(n)
    t = 0
    freqs = {}
    -- frequencies spread from 0.4 Hz to 1.6 Hz
    for i = 1, N_PEND do
        freqs[i] = 0.4 + (i - 1) * (1.2 / (N_PEND - 1))
    end
end

function update(buf, dt)
    local n = buf:len()
    t = t + dt
    buf:clear()

    local seg = n / N_PEND
    for i = 1, N_PEND do
        local phase = math.sin(2 * math.pi * freqs[i] * t)   -- -1 to 1
        local center = (i - 0.5) * seg
        local pos    = center + phase * seg * 0.44
        local r, g, b = colorwheel(math.floor((i - 1) / N_PEND * 255))
        buf:plot(pos, r, g, b, 1.0)
    end
    return true
end

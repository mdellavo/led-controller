name = "Heartbeat"
description = "A red lub-dub double pulse at 72 BPM with a long dark pause between beats"

local BPM    = 72.0
local PERIOD = 60.0 / BPM   -- ~0.833 s
local timer  = 0.0

local function pulse(t)
    -- Lub: Gaussian peak at t=0
    local lub = math.exp(-((t * 32) ^ 2))
    -- Dub: slightly softer peak at t=0.13 s
    local dub = math.exp(-(((t - 0.13) * 34) ^ 2)) * 0.65
    return math.max(lub, dub)
end

function update(buf, dt)
    local n = buf:len()
    timer = (timer + dt) % PERIOD

    local bright = pulse(timer)
    local r = math.floor(255 * bright)
    local g = math.floor(15  * bright)
    local b = math.floor(15  * bright)

    for i = 0, n - 1 do buf:set(i, r, g, b) end

    return true
end

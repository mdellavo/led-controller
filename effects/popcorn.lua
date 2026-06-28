name = "Popcorn"
description = "Pixels pop bright then fade; spawn rate ramps up in waves like corn popping"

local CYCLE   = 6.0   -- seconds per popping wave
local cycle_t = 0.0

function update(buf, dt)
    local n = buf:len()

    buf:fade(0.78^60, dt)

    cycle_t = (cycle_t + dt) % CYCLE

    -- Rate ramps cubically: slow start, frantic peak, then resets
    local x    = cycle_t / CYCLE
    local rate = x ^ 3 * n * 1.8   -- 0 → ~108 pops/s at peak for n=60

    -- Poisson approximation: random integer number of pops this frame
    local expected = rate * dt
    local num_pops = math.floor(expected + math.random())

    for _ = 1, num_pops do
        local pos = math.random(0, n - 1)
        -- Warm yellow-white pop
        buf:set(pos, math.random(230, 255), math.random(190, 230), math.random(30, 90))
    end

    return true
end

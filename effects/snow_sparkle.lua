name = "Snow Sparkle"
description = "Dim white background with a single bright sparkle that jumps to a new position every 200ms"

local bg_r, bg_g, bg_b         = 20, 20, 20
local spark_r, spark_g, spark_b = 255, 255, 255
local sparkle_delay = 20.0   -- ms the sparkle is visible
local wait_time     = 200.0  -- ms between sparkles

local mode       = "waiting"
local sparkle_pos = 0
local timer      = 0.0

function init(n)
    mode  = "waiting"
    timer = 0.0
end

function update(buf, dt)
    local n = buf:len()
    timer = timer + dt * 1000.0

    for i = 0, n - 1 do buf:set(i, bg_r, bg_g, bg_b) end

    if mode == "sparkling" then
        buf:set(sparkle_pos, spark_r, spark_g, spark_b)
        if timer >= sparkle_delay then
            timer = timer - sparkle_delay
            mode  = "waiting"
        end
    else  -- waiting
        if timer >= wait_time then
            timer       = timer - wait_time
            sparkle_pos = math.random(0, n - 1)
            mode        = "sparkling"
        end
    end

    return true
end

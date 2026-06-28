name = "Gradient Cycle"
description = "Smooth gradient between two complementary colors that slowly scrolls across the strip"

local COLOR_A = {255, 50,  210}   -- magenta-purple
local COLOR_B = {0,   210, 255}   -- cyan
local offset  = 0.0
local SPEED   = 0.18   -- full cycles per second

function update(buf, dt)
    local n = buf:len()
    offset = (offset + SPEED * dt) % 1.0

    for i = 0, n - 1 do
        local t     = (i / n + offset) % 1.0
        -- cosine so both endpoints smoothly match
        local blend = (1 - math.cos(t * 2 * math.pi)) / 2

        buf:set(i,
            math.floor(COLOR_A[1] * (1 - blend) + COLOR_B[1] * blend),
            math.floor(COLOR_A[2] * (1 - blend) + COLOR_B[2] * blend),
            math.floor(COLOR_A[3] * (1 - blend) + COLOR_B[3] * blend))
    end

    return true
end

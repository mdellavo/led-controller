name = "DNA Helix"
description = "Two interlocked sine waves in cyan and orange scroll along the strip like a DNA double helix"

local offset = 0.0
local SPEED  = 2.0  -- radians/s

function update(buf, dt)
    local n  = buf:len()
    offset = offset + SPEED * dt

    for i = 0, n - 1 do
        local x = i / n * 4 * math.pi + offset
        -- sin² + cos² = 1 at all positions: two complementary strands
        local v1 = math.sin(x) ^ 2   -- strand 1 (cyan)
        local v2 = math.cos(x) ^ 2   -- strand 2 (orange)

        -- Cyan (0, 210, 255) × v1  +  Orange (255, 130, 0) × v2  additive
        local r = math.min(255, math.floor(v2 * 255))
        local g = math.min(255, math.floor(v1 * 210 + v2 * 130))
        local b = math.min(255, math.floor(v1 * 255))

        buf:set(i, r, g, b)
    end

    return true
end

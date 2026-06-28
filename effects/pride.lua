name = "Pride"
description = "Six-color pride flag mapped across the strip and slowly scrolling"

-- Standard six-stripe pride flag colors
local FLAG = {
    {228,  3,   3},   -- red
    {255, 140,   0},  -- orange
    {255, 237,   0},  -- yellow
    {0,   128,  38},  -- green
    {0,    77, 255},  -- blue
    {117,   7, 135},  -- violet
}
local NUM_BANDS = #FLAG

local offset = 0.0
local SPEED  = 0.08   -- full scrolls per second

function update(buf, dt)
    local n = buf:len()
    offset = (offset + SPEED * dt) % 1.0

    for i = 0, n - 1 do
        local t    = ((i / n + offset) % 1.0) * NUM_BANDS
        local idx  = math.floor(t) % NUM_BANDS + 1
        local nxt  = idx % NUM_BANDS + 1
        local frac = t - math.floor(t)
        -- Cosine ease for soft band edges
        local blend = (1 - math.cos(frac * math.pi)) / 2

        local c1, c2 = FLAG[idx], FLAG[nxt]
        buf:set(i,
            math.floor(c1[1] * (1 - blend) + c2[1] * blend),
            math.floor(c1[2] * (1 - blend) + c2[2] * blend),
            math.floor(c1[3] * (1 - blend) + c2[3] * blend))
    end

    return true
end

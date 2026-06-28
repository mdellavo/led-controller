name = "Easter"
description = "Soft pastel mint, lavender, peach, sky blue, and rose pink breathe gently across the strip"

local PASTELS = {
    {170, 255, 190},  -- mint
    {205, 175, 255},  -- lavender
    {255, 205, 175},  -- peach
    {170, 225, 255},  -- sky blue
    {255, 200, 220},  -- rose pink
}
local NP    = #PASTELS
local t     = 0.0
local SPEED = 0.07   -- scrolls per second

function update(buf, dt)
    local n = buf:len()
    t = (t + SPEED * dt) % 1.0

    -- Slow global breath (0.65× to 1.0× brightness)
    local breath = 0.65 + 0.35 * (math.sin(t * 2 * math.pi * 0.28 * (1/SPEED)) + 1) / 2

    for i = 0, n - 1 do
        local pos   = ((i / n + t) % 1.0) * NP
        local idx   = math.floor(pos) % NP + 1
        local nxt   = idx % NP + 1
        local frac  = pos - math.floor(pos)
        frac = (1 - math.cos(frac * math.pi)) / 2

        local c1 = PASTELS[idx]
        local c2 = PASTELS[nxt]
        buf:set(i,
            math.floor((c1[1] * (1-frac) + c2[1] * frac) * breath),
            math.floor((c1[2] * (1-frac) + c2[2] * frac) * breath),
            math.floor((c1[3] * (1-frac) + c2[3] * frac) * breath))
    end

    return true
end

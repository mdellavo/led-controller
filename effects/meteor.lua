name = "Meteor Rain"
description = "White meteor streaks across the strip leaving a randomly-decaying trail, then resets"

local meteor_size  = 10
local random_decay = true
-- Rust defaults: trail_decay=64, step interval=30ms → ~33.3 steps/sec
-- decay per step = (255-64)/255, per_second = that^(1000/30)
local decay_per_second = ((255 - 64) / 255) ^ (1000 / 30)
local speed            = 1000 / 30  -- pixels per second

local pos = 0.0

function init(n)
    pos = -meteor_size
end

function update(buf, dt)
    local n      = buf:len()
    local factor = decay_per_second ^ dt

    -- Decay trail (random per-pixel for organic look)
    if random_decay then
        for i = 0, n - 1 do
            if math.random() < 0.5 then
                local pr, pg, pb = buf:get(i)
                buf:set(i,
                    math.floor(pr * factor),
                    math.floor(pg * factor),
                    math.floor(pb * factor))
            end
        end
    else
        buf:fade(decay_per_second, dt)
    end

    -- Advance meteor
    pos = pos + speed * dt

    local mr = COLOR_R or 255
    local mg = COLOR_G or 255
    local mb = COLOR_B or 255
    -- Draw meteor head (non-wrapping)
    for i = 0, meteor_size - 1 do
        local p = pos - i
        if p >= 0 and p < n then
            buf:plot(p, mr, mg, mb, 1.0)
        end
    end

    -- Reset when fully past the strip
    if pos > n + meteor_size then
        pos = -meteor_size
        buf:clear()
    end

    return true
end

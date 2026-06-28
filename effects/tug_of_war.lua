name = "Tug of War"
description = "Red and blue forces push from opposite ends; the boundary oscillates and occasionally surges"

local LEFT  = {255, 40,  40}   -- red team
local RIGHT = {40,  40, 255}   -- blue team

local boundary = 0.5   -- normalised position 0=far left, 1=far right
local vel      = 0.0
local phase    = 0.0

function update(buf, dt)
    local n = buf:len()
    phase = phase + dt

    -- Each side exerts a rhythmic force at a slightly different frequency → beating
    local left_push  = math.sin(phase * 1.30) * 0.25 + (math.random() - 0.5) * 0.06
    local right_push = math.sin(phase * 0.91 + 1.4) * 0.25 + (math.random() - 0.5) * 0.06

    -- Restoring spring toward centre
    local restore = (0.5 - boundary) * 2.8

    vel = vel + (left_push - right_push + restore) * dt
    vel = vel * (0.35 ^ dt)   -- damping

    boundary = math.max(0.04, math.min(0.96, boundary + vel * dt))

    local bpx = boundary * (n - 1)

    -- Render two solid halves with a soft blend zone at the boundary
    for i = 0, n - 1 do
        local dist = i - bpx
        if dist < -1.5 then
            buf:set(i, LEFT[1], LEFT[2], LEFT[3])
        elseif dist > 1.5 then
            buf:set(i, RIGHT[1], RIGHT[2], RIGHT[3])
        else
            local frac = (dist + 1.5) / 3.0
            frac = (1 - math.cos(frac * math.pi)) / 2
            buf:set(i,
                math.floor(LEFT[1] * (1-frac) + RIGHT[1] * frac),
                math.floor(LEFT[2] * (1-frac) + RIGHT[2] * frac),
                math.floor(LEFT[3] * (1-frac) + RIGHT[3] * frac))
        end
    end

    -- Bright white marker at exact boundary
    buf:plot(bpx, 255, 255, 255, 0.55)

    return true
end

name = "Murmuration"
description = "Boids flocking — particles attract, align, and avoid each other in flight."

local function colorwheel(pos)
    pos = math.floor(pos) % 256
    pos = (255 - pos) % 256
    if pos < 85 then return 255-pos*3, 0, pos*3
    elseif pos < 170 then pos=pos-85; return 0, pos*3, 255-pos*3
    else pos=pos-170; return pos*3, 255-pos*3, 0 end
end

local NUM   = 22
local boids = {}

local SEP_R     = 3.0
local ALI_R     = 12.0
local MAX_SPEED = 22.0

function init(n)
    boids = {}
    for i = 1, NUM do
        boids[i] = {
            pos = math.random() * n,
            vel = (math.random() > 0.5 and 1 or -1) * (math.random() * 8 + 5),
            hue = math.floor((i - 1) / NUM * 255),
        }
    end
end

function update(buf, dt)
    local n = buf:len()
    local new_vels = {}

    for i = 1, NUM do
        local b = boids[i]
        local sep, ali, coh_d, neighbors = 0, 0, 0, 0

        for j = 1, NUM do
            if i ~= j then
                local o = boids[j]
                local d = o.pos - b.pos
                if d >  n * 0.5 then d = d - n
                elseif d < -n * 0.5 then d = d + n end
                local dist = math.abs(d)

                if dist < SEP_R and dist > 0.001 then
                    sep = sep - (d / dist) * (SEP_R - dist)
                end
                if dist < ALI_R then
                    ali   = ali   + o.vel
                    coh_d = coh_d + d
                    neighbors = neighbors + 1
                end
            end
        end

        local v = b.vel + sep * 2.5 * dt
        if neighbors > 0 then
            v = v + (ali / neighbors - v) * 0.6 * dt    -- alignment
            v = v + coh_d / neighbors * 0.4 * dt         -- cohesion
        end
        if v >  MAX_SPEED then v =  MAX_SPEED
        elseif v < -MAX_SPEED then v = -MAX_SPEED end
        new_vels[i] = v
    end

    buf:fade(0.82^60, dt)
    for i = 1, NUM do
        boids[i].vel = new_vels[i]
        boids[i].pos = (boids[i].pos + boids[i].vel * dt) % n
        local r, g, b = colorwheel(boids[i].hue)
        buf:plot(boids[i].pos, r, g, b, 0.9)
    end
    return true
end

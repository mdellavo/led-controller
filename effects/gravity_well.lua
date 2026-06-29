name = "Gravity Well"
description = "Particles orbit a drifting gravity center — closer ones orbit faster and glow brighter."

local function colorwheel(pos)
    pos = math.floor(pos) % 256
    pos = (255 - pos) % 256
    if pos < 85 then return 255-pos*3, 0, pos*3
    elseif pos < 170 then pos=pos-85; return 0, pos*3, 255-pos*3
    else pos=pos-170; return pos*3, 255-pos*3, 0 end
end

local NUM = 14
local particles = {}
local center    = 0.0
local cvel      = 0.0
local t         = 0.0

function init(n)
    t      = 0
    center = n * 0.5
    cvel   = n * 0.04
    particles = {}
    for i = 1, NUM do
        local frac   = i / NUM
        local radius = frac * n * 0.44 + n * 0.02
        -- Kepler: period ∝ radius^1.5
        local period = 1.5 * (radius / (n * 0.5)) ^ 1.5 + 0.4
        particles[i] = {
            radius = radius,
            phase  = (i - 1) / NUM * math.pi * 2,
            period = period,
            hue    = math.floor((i - 1) / NUM * 255),
        }
    end
end

function update(buf, dt)
    local n = buf:len()
    t = t + dt

    -- drift center, bounce off margins
    center = center + cvel * dt
    if center < n * 0.08 then
        center = n * 0.08; cvel = math.abs(cvel)
    elseif center > n * 0.92 then
        center = n * 0.92; cvel = -math.abs(cvel)
    end

    buf:clear()

    -- gravity well glow
    for p = 0, n - 1 do
        local d    = (p - center) / n
        local glow = math.exp(-d * d * 300)
        buf:plot(p, math.floor(glow * 90), math.floor(glow * 35), 0, 1.0)
    end

    -- orbiting particles
    for _, part in ipairs(particles) do
        local angle = t * 2 * math.pi / part.period + part.phase
        local pos   = center + math.sin(angle) * part.radius
        local bri   = 1.0 - part.radius / (n * 0.5)   -- closer = brighter
        local cr, cg, cb = colorwheel(part.hue)
        buf:plot(pos, cr, cg, cb, bri * 0.85 + 0.15)
    end

    return true
end

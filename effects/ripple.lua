name = "Ripple"
description = "Random tap points send expanding rings of light that fade as they travel outward"

local ripples      = {}
local spawn_timer  = 0.0
local SPAWN_INTERVAL = 1.4

-- Random vibrant hue
local function rand_color()
    local h = math.random(0, 5)
    local colors = {
        {255, 60,  60},   -- red
        {255, 180, 0},    -- orange
        {60,  255, 60},   -- green
        {60,  200, 255},  -- cyan
        {120, 60,  255},  -- violet
        {255, 60,  200},  -- pink
    }
    return table.unpack(colors[h + 1])
end

function update(buf, dt)
    local n = buf:len()

    buf:fade(0.6^60, dt)

    spawn_timer = spawn_timer + dt
    if spawn_timer >= SPAWN_INTERVAL then
        spawn_timer = spawn_timer - SPAWN_INTERVAL
        local r, g, b = rand_color()
        table.insert(ripples, {
            center = math.random(0, n - 1),
            radius = 0.0,
            speed  = n * 0.45,   -- pixels/s
            max_r  = n * 0.55,
            r = r, g = g, b = b,
        })
    end

    local i = 1
    while i <= #ripples do
        local rp = ripples[i]
        rp.radius = rp.radius + rp.speed * dt
        local life = 1.0 - rp.radius / rp.max_r

        if life <= 0 then
            table.remove(ripples, i)
        else
            -- Two wavefronts expanding in each direction
            local left  = rp.center - rp.radius
            local right = rp.center + rp.radius
            if left >= 0 then
                buf:plot(left, rp.r, rp.g, rp.b, life)
            end
            if right < n then
                buf:plot(right, rp.r, rp.g, rp.b, life)
            end
            i = i + 1
        end
    end

    return true
end

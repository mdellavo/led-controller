name = "Fireworks"
description = "Rockets launch from the base, reach an apex, and burst into colorful fragments"

local rockets   = {}
local fragments = {}
local spawn_timer    = 0.0
local spawn_interval = 1.5
local gravity = 10.0  -- pixels/s²

local function colorwheel(pos)
    pos = math.floor(pos) % 256
    pos = (255 - pos) % 256
    if pos < 85 then
        return 255 - pos * 3, 0, pos * 3
    elseif pos < 170 then
        pos = pos - 85
        return 0, pos * 3, 255 - pos * 3
    else
        pos = pos - 170
        return pos * 3, 255 - pos * 3, 0
    end
end

-- Plot only if within strip bounds (no wrapping for ballistic objects)
local function safe_plot(buf, n, pos, r, g, b, alpha)
    if pos >= 0 and pos < n then buf:plot(pos, r, g, b, alpha) end
end

function init(n)
    rockets   = {}
    fragments = {}
    spawn_timer = math.random() * spawn_interval
    gravity = n * 0.16  -- scales with strip length
end

function update(buf, dt)
    local n = buf:len()

    buf:fade(0.75^60, dt)

    -- Spawn new rocket
    spawn_timer = spawn_timer + dt
    if spawn_timer >= spawn_interval then
        spawn_timer = spawn_timer - spawn_interval
        local apex = math.random(0, math.floor(n * 0.45))
        local dist = (n - 1) - apex
        local v0   = -math.sqrt(2 * gravity * dist)
        local hue  = math.random(0, 255)
        local r, g, b = colorwheel(hue)
        table.insert(rockets, { pos = n - 1.0, vel = v0, apex = apex, r = r, g = g, b = b })
    end

    -- Update rockets
    local i = 1
    while i <= #rockets do
        local rk = rockets[i]
        rk.vel = rk.vel + gravity * dt
        rk.pos = rk.pos + rk.vel * dt

        if rk.pos <= rk.apex or rk.vel >= 0 then
            -- Burst into fragments
            local num_frags = math.random(10, 18)
            for j = 1, num_frags do
                local spd  = (math.random() * n * 0.3 + n * 0.05)
                local sign = (j <= num_frags // 2) and 1 or -1
                table.insert(fragments, {
                    pos   = rk.pos,
                    vel   = spd * sign + (math.random() - 0.5) * n * 0.05,
                    r     = rk.r, g = rk.g, b = rk.b,
                    life  = 1.0,
                    decay = math.random() * 0.8 + 0.7,
                })
            end
            table.remove(rockets, i)
        else
            safe_plot(buf, n, rk.pos,     rk.r, rk.g, rk.b, 1.0)
            safe_plot(buf, n, rk.pos + 1, rk.r, rk.g, rk.b, 0.3)
            safe_plot(buf, n, rk.pos + 2, rk.r, rk.g, rk.b, 0.1)
            i = i + 1
        end
    end

    -- Update fragments (gravity pulls them back down, no wrap)
    local fi = 1
    while fi <= #fragments do
        local f = fragments[fi]
        f.vel  = f.vel + gravity * dt
        f.pos  = f.pos + f.vel * dt
        f.life = f.life - f.decay * dt
        if f.life <= 0 or f.pos < -1 or f.pos >= n + 1 then
            table.remove(fragments, fi)
        else
            safe_plot(buf, n, f.pos, f.r, f.g, f.b, f.life)
            fi = fi + 1
        end
    end

    return true
end

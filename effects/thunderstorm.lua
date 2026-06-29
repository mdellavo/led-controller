name = "Thunderstorm"
description = "Rain drops fall under gravity while periodic lightning flashes illuminate the whole strip."

local drops = {}
local flash      = 0.0
local spawn_acc  = 0.0
local bolt_timer = 0.0

local function new_drop(n)
    return {
        pos = 0.0,
        vel = 0.0,
        r   = math.random(30,  80),
        g   = math.random(30,  80),
        b   = math.random(100, 180),
    }
end

function init(n)
    drops      = {}
    flash      = 0.0
    spawn_acc  = 0.0
    bolt_timer = math.random() * 3.0 + 1.5
end

function update(buf, dt)
    local n       = buf:len()
    local gravity = n * 7.0

    -- spawn rain
    spawn_acc = spawn_acc + dt
    while spawn_acc >= 0.35 do
        spawn_acc = spawn_acc - 0.35
        table.insert(drops, new_drop(n))
    end

    -- lightning countdown
    bolt_timer = bolt_timer - dt
    if bolt_timer <= 0 then
        flash      = 1.0
        bolt_timer = math.random() * 4.0 + 1.5
    end
    flash = math.max(0.0, flash - dt * 7.0)

    buf:fade(0.72^60, dt)

    -- lightning overlay (additive bright blue-white)
    if flash > 0.01 then
        for i = 0, n - 1 do
            buf:plot(i, 210, 220, 255, flash * 0.9)
        end
    end

    -- update drops
    local alive = {}
    for _, d in ipairs(drops) do
        d.vel = d.vel + gravity * dt
        d.pos = d.pos + d.vel * dt
        if d.pos >= n - 1 then
            for j = math.max(0, n - 3), n - 1 do
                buf:set(j, d.r, d.g, d.b)
            end
        else
            buf:plot(d.pos, d.r, d.g, d.b, 1.0)
            table.insert(alive, d)
        end
    end
    drops = alive
    return true
end

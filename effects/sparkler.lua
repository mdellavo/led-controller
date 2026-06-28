name = "Sparkler"
description = "A drifting source continuously throws fast short-lived sparks in both directions"

local sparks   = {}
local src      = 0.0
local src_vel  = 0.0
local MAX_SPARKS = 80

function init(n)
    sparks  = {}
    src     = n / 2
    src_vel = n * 0.09
end

function update(buf, dt)
    local n = buf:len()

    -- Drift source back and forth
    src = src + src_vel * dt
    if src >= n - 1 then src = n - 1; src_vel = -math.abs(src_vel)
    elseif src <= 0  then src = 0;    src_vel =  math.abs(src_vel) end

    -- Spawn sparks: ~2.5 strip-lengths worth per second
    local expected = n * 2.5 * dt
    local count    = math.floor(expected + math.random())
    for _ = 1, count do
        if #sparks < MAX_SPARKS then
            local spd = (math.random() * n * 0.9 + n * 0.15)
                      * (math.random() < 0.5 and 1 or -1)
            table.insert(sparks, {
                pos  = src + (math.random() - 0.5) * 1.5,
                vel  = spd,
                life = math.random() * 0.18 + 0.04,
                r    = math.random(220, 255),
                g    = math.random(160, 220),
                b    = math.random(15,  70),
            })
        end
    end

    buf:fade(0.65^60, dt)

    -- Core glow at source
    buf:plot(src, 255, 245, 120, 1.0)
    buf:plot(src - 0.5, 255, 180, 40, 0.4)
    buf:plot(src + 0.5, 255, 180, 40, 0.4)

    -- Update sparks
    local i = 1
    while i <= #sparks do
        local s = sparks[i]
        s.pos  = s.pos + s.vel * dt
        s.life = s.life - dt
        if s.life <= 0 or s.pos < 0 or s.pos >= n then
            table.remove(sparks, i)
        else
            local alpha = math.min(1.0, s.life * 6)
            buf:plot(s.pos, s.r, s.g, s.b, alpha)
            i = i + 1
        end
    end

    return true
end

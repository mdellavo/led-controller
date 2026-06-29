name = "Wave Interference"
description = "Sine-wave sources drift toward each other; constructive and destructive interference shifts patterns."

local function colorwheel(pos)
    pos = math.floor(pos) % 256
    pos = (255 - pos) % 256
    if pos < 85 then return 255-pos*3, 0, pos*3
    elseif pos < 170 then pos=pos-85; return 0, pos*3, 255-pos*3
    else pos=pos-170; return pos*3, 255-pos*3, 0 end
end

local K = 0.45   -- spatial frequency (rad/pixel)
local sources = {}
local t = 0

function init(n)
    t = 0
    sources = {
        { pos = n * 0.15, vel =  n * 0.07, omega = 5.5, hue = 0   },
        { pos = n * 0.85, vel = -n * 0.07, omega = 5.5, hue = 128 },
        { pos = n * 0.50, vel =  n * 0.04, omega = 4.0, hue = 64  },
    }
end

function update(buf, dt)
    local n = buf:len()
    t = t + dt

    for _, s in ipairs(sources) do
        s.pos = s.pos + s.vel * dt
        if s.pos < 0 then
            s.pos = 0; s.vel = math.abs(s.vel)
        elseif s.pos > n - 1 then
            s.pos = n - 1; s.vel = -math.abs(s.vel)
        end
    end

    local ns = #sources
    for p = 0, n - 1 do
        local tr, tg, tb = 0, 0, 0
        for _, s in ipairs(sources) do
            local dist = math.abs(p - s.pos)
            local amp  = (math.sin(K * dist - s.omega * t) + 1) * 0.5
            local cr, cg, cb = colorwheel(s.hue)
            tr = tr + cr * amp
            tg = tg + cg * amp
            tb = tb + cb * amp
        end
        buf:set(p,
            math.min(255, math.floor(tr / ns)),
            math.min(255, math.floor(tg / ns)),
            math.min(255, math.floor(tb / ns)))
    end
    return true
end

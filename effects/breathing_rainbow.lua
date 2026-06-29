name = "Breathing Rainbow"
description = "Rainbow colors sweep through the strip while a breathing pulse slowly expands and contracts."

local function colorwheel(pos)
    pos = math.floor(pos) % 256
    pos = (255 - pos) % 256
    if pos < 85 then return 255-pos*3, 0, pos*3
    elseif pos < 170 then pos=pos-85; return 0, pos*3, 255-pos*3
    else pos=pos-170; return pos*3, 255-pos*3, 0 end
end

local BREATH_PERIOD = 4.0   -- seconds per inhale+exhale cycle
local HUE_SPEED     = 38.0  -- hue units per second
local t   = 0.0
local hue = 0.0

function init(n)
    t   = 0
    hue = math.random(0, 255)
end

function update(buf, dt)
    local n = buf:len()
    t   = t   + dt
    hue = (hue + HUE_SPEED * dt) % 256

    -- breathing envelope: squared sine so it lingers near zero and peaks quickly
    local breath = (math.sin(t * 2 * math.pi / BREATH_PERIOD - math.pi / 2) + 1) * 0.5
    breath = breath * breath

    for i = 0, n - 1 do
        local h  = math.floor((i / n * 255 + hue) % 256)
        local cr, cg, cb = colorwheel(h)
        buf:set(i,
            math.floor(cr * breath),
            math.floor(cg * breath),
            math.floor(cb * breath))
    end
    return true
end

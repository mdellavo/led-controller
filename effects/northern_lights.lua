name = "Northern Lights"
description = "Slow curtains of aurora light drift across the strip in structured beams."

local function colorwheel(pos)
    pos = math.floor(pos) % 256
    pos = (255 - pos) % 256
    if pos < 85 then return 255-pos*3, 0, pos*3
    elseif pos < 170 then pos=pos-85; return 0, pos*3, 255-pos*3
    else pos=pos-170; return pos*3, 255-pos*3, 0 end
end

local NUM_BEAMS = 5
local beams     = {}
local t         = 0

function init(n)
    t     = 0
    beams = {}
    for i = 1, NUM_BEAMS do
        beams[i] = {
            center     = (i - 0.5) * n / NUM_BEAMS,
            width      = n / NUM_BEAMS * (math.random() * 0.35 + 0.25),
            drift      = (math.random() - 0.5) * 4.5,
            hue        = 100 + math.random(0, 75),   -- green → cyan → blue-purple
            phase      = math.random() * math.pi * 2,
            pulse_spd  = math.random() * 0.35 + 0.15,
        }
    end
end

function update(buf, dt)
    local n = buf:len()
    t = t + dt
    buf:clear()

    for _, bm in ipairs(beams) do
        bm.center = (bm.center + bm.drift * dt) % n
        local pulse = (math.sin(t * bm.pulse_spd + bm.phase) + 1) * 0.38 + 0.12

        for p = 0, n - 1 do
            local d = p - bm.center
            if d >  n * 0.5 then d = d - n
            elseif d < -n * 0.5 then d = d + n end

            local sigma  = bm.width * 0.55
            local alpha  = math.exp(-(d * d) / (2 * sigma * sigma)) * pulse
            if alpha > 0.015 then
                local hue_shift = d / bm.width * 18
                local r, g, b = colorwheel(math.floor((bm.hue + hue_shift) % 256))
                -- additive via plot (alpha < 1 blends into existing pixel)
                buf:plot(p, r, g, b, alpha)
            end
        end
    end
    return true
end

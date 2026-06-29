name = "Glitch"
description = "Digital corruption — block shifts, channel swaps, noise bursts, and color inversions."

local function colorwheel(pos)
    pos = math.floor(pos) % 256
    pos = (255 - pos) % 256
    if pos < 85 then return 255-pos*3, 0, pos*3
    elseif pos < 170 then pos=pos-85; return 0, pos*3, 255-pos*3
    else pos=pos-170; return pos*3, 255-pos*3, 0 end
end

local hue         = 0.0
local glitch_cd   = 0.0   -- countdown to next glitch event
local glitch_type = 0
local glitch_life = 0.0

function init(n)
    hue        = math.random(0, 255)
    glitch_cd  = math.random() * 0.6 + 0.1
    glitch_life = 0.0
end

function update(buf, dt)
    local n = buf:len()
    hue = (hue + 25 * dt) % 256

    -- base: slow-rolling rainbow
    for i = 0, n - 1 do
        local cr, cg, cb = colorwheel(math.floor((i / n * 255 + hue) % 256))
        buf:set(i, cr, cg, cb)
    end

    -- glitch countdown
    glitch_life = glitch_life - dt
    glitch_cd   = glitch_cd   - dt

    if glitch_cd <= 0 then
        glitch_cd   = math.random() * 0.7 + 0.1
        glitch_life = math.random() * 0.12 + 0.04
        glitch_type = math.random(1, 4)
    end

    if glitch_life > 0 then
        if glitch_type == 1 then
            -- block shift: take a segment and displace it
            local seg_s = math.random(0, n - 1)
            local seg_l = math.random(2, math.max(2, n // 4))
            local shift = math.random(-(n // 6), n // 6)
            for i = seg_s, math.min(seg_s + seg_l - 1, n - 1) do
                local src = i + shift
                if src >= 0 and src < n then
                    local cr, cg, cb = colorwheel(math.floor((src / n * 255 + hue) % 256))
                    buf:set(i, cr, cg, cb)
                else
                    buf:set(i, 0, 0, 0)
                end
            end

        elseif glitch_type == 2 then
            -- channel swap R↔B on a segment
            local seg_s = math.random(0, n - 1)
            local seg_l = math.random(3, math.max(3, n // 3))
            for i = seg_s, math.min(seg_s + seg_l - 1, n - 1) do
                local cr, cg, cb = colorwheel(math.floor((i / n * 255 + hue) % 256))
                buf:set(i, cb, cg, cr)
            end

        elseif glitch_type == 3 then
            -- random noise pixels
            for _ = 1, math.random(2, math.max(2, n // 5)) do
                buf:set(math.random(0, n - 1),
                    math.random(0, 255),
                    math.random(0, 255),
                    math.random(0, 255))
            end

        else
            -- invert a segment
            local seg_s = math.random(0, n - 1)
            local seg_l = math.random(2, math.max(2, n // 3))
            for i = seg_s, math.min(seg_s + seg_l - 1, n - 1) do
                local cr, cg, cb = colorwheel(math.floor((i / n * 255 + hue) % 256))
                buf:set(i, 255 - cr, 255 - cg, 255 - cb)
            end
        end
    end

    return true
end

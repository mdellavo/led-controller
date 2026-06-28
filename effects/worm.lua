name = "Worm"
description = "A glowing segmented worm crawls the strip; speed variation makes the body snake and bunch"

local BODY_LEN = 0
local HIST_CAP = 0
local SEG_GAP  = 3    -- history frames between body segments

local hist     = {}
local hist_ptr = 0    -- next write index (0-based)
local base_pos = 0.0
local dir      = 1
local hue      = 0
local wiggle_t = 0.0

local BASE_SPEED  = 0.0
local WIGGLE_AMP  = 0.0

local function colorwheel(p)
    p = math.floor(p) % 256
    p = (255 - p) % 256
    if p < 85 then return 255-p*3, 0, p*3
    elseif p < 170 then p=p-85; return 0, p*3, 255-p*3
    else p=p-170; return p*3, 255-p*3, 0 end
end

function init(n)
    BODY_LEN  = math.max(8, math.floor(n / 5))
    HIST_CAP  = BODY_LEN * SEG_GAP + 4
    BASE_SPEED = n * 0.28
    WIGGLE_AMP = n * 0.10
    base_pos  = n / 2
    dir       = 1
    hue       = math.random(0, 255)
    wiggle_t  = 0.0
    hist = {}
    for i = 1, HIST_CAP do hist[i] = base_pos end
    hist_ptr = 0
end

function update(buf, dt)
    local n = buf:len()

    wiggle_t = wiggle_t + dt

    -- Speed oscillates sinusoidally so body segments bunch and spread
    local speed_factor = 1.0 + 0.65 * math.sin(wiggle_t * 3.2)
    base_pos = base_pos + dir * BASE_SPEED * speed_factor * dt

    if base_pos >= n - 1 then
        base_pos = n - 1
        dir  = -1
        hue  = (hue + 50) % 256
    elseif base_pos <= 0 then
        base_pos = 0
        dir  = 1
        hue  = (hue + 50) % 256
    end

    -- Record head in ring buffer
    hist[hist_ptr + 1] = base_pos
    hist_ptr = (hist_ptr + 1) % HIST_CAP

    buf:clear()

    local r, g, b = colorwheel(hue)
    for seg = 0, BODY_LEN - 1 do
        local offset = seg * SEG_GAP
        local idx    = (hist_ptr - 1 - offset) % HIST_CAP
        local pos    = hist[idx + 1]
        local bright = ((BODY_LEN - seg) / BODY_LEN) ^ 1.4
        -- Slight hue shift along body
        local sr, sg, sb = colorwheel((hue + seg * 6) % 256)
        buf:plot(pos, sr, sg, sb, bright)
    end

    return true
end

name = "Pong"
description = "A bright dot bounces between the two ends, getting faster with each hit"

local pos         = 0.0
local vel         = 0.0
local hue         = 0
local flash_left  = 0.0
local flash_right = 0.0

local function colorwheel(p)
    p = math.floor(p) % 256
    p = (255 - p) % 256
    if p < 85 then return 255-p*3, 0, p*3
    elseif p < 170 then p=p-85; return 0, p*3, 255-p*3
    else p=p-170; return p*3, 255-p*3, 0 end
end

function init(n)
    pos = n / 2
    vel = n * 0.55
    hue = math.random(0, 255)
end

function update(buf, dt)
    local n = buf:len()

    pos = pos + vel * dt

    if pos >= n - 1 then
        pos = n - 1
        vel = -(math.abs(vel) * 1.06)
        flash_right = 0.12
        hue = (hue + 28) % 256
    elseif pos <= 0 then
        pos = 0
        vel = math.abs(vel) * 1.06
        flash_left = 0.12
        hue = (hue + 28) % 256
    end

    -- Reset speed when strip becomes too fast to see
    if math.abs(vel) > n * 6 then
        vel = n * (vel > 0 and 0.55 or -0.55)
        hue = math.random(0, 255)
    end

    buf:fade(0.55^60, dt)

    -- End flash on hit
    flash_left  = math.max(0, flash_left  - dt)
    flash_right = math.max(0, flash_right - dt)
    if flash_left  > 0 then buf:set(0,     255, 255, 255) end
    if flash_right > 0 then buf:set(n - 1, 255, 255, 255) end

    local r, g, b = colorwheel(hue)
    buf:plot(pos, r, g, b, 1.0)

    return true
end

name = "Chase"
description = "Antialiased comet with a tail proportional to strip length; picks a new random color each lap"

local pos = 0.0
local prev_pos = 0.0
local tail_length = 3
local speed = 0.0
local r, g, b = 255, 0, 0

function init(n)
    tail_length = math.max(3, math.floor(n / 6))
    speed = n * 1.5
    r = math.random(0, 255)
    g = math.random(0, 255)
    b = math.random(0, 255)
    pos = 0.0
    prev_pos = 0.0
end

function update(buf, dt)
    local n = buf:len()
    local new_pos = (pos + speed * dt) % n

    -- wrap-around: pick a new random color
    if new_pos < prev_pos then
        r = math.random(0, 255)
        g = math.random(0, 255)
        b = math.random(0, 255)
    end

    prev_pos = pos
    pos = new_pos

    buf:clear()
    for i = 0, tail_length - 1 do
        local tail_pos = (pos - i) % n
        local brightness = 1.0 - i / tail_length
        buf:plot(tail_pos, r, g, b, brightness)
    end

    return true
end

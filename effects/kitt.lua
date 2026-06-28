name = "KITT"

local color      = {255, 0, 0}
local eye_size   = 4
local speed      = 30.0
local half_width = 0.0
local expanding  = true

local function draw_eye(buf, cx)
    local n = buf:len()
    buf:plot(cx, color[1], color[2], color[3], 1.0)
    for i = 1, eye_size - 1 do
        local alpha = 1.0 / (2 ^ i)
        if cx - i >= 0 then
            buf:plot(cx - i, color[1], color[2], color[3], alpha)
        end
        if cx + i < n then
            buf:plot(cx + i, color[1], color[2], color[3], alpha)
        end
    end
end

function init(n)
    half_width = 0.0
    expanding  = true
end

function update(buf, dt)
    local n       = buf:len()
    local center  = n / 2.0
    local max_half = math.max(0.0, center - eye_size)

    buf:fade(0.8 ^ 60, dt)
    draw_eye(buf, center - half_width)
    draw_eye(buf, center + half_width)

    if expanding then
        half_width = half_width + speed * dt
        if half_width >= max_half then
            half_width = max_half
            expanding  = false
        end
    else
        half_width = half_width - speed * dt
        if half_width <= 0.0 then
            half_width = 0.0
            expanding  = true
        end
    end

    return true
end

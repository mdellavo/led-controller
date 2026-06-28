name = "Cylon"

local color    = {255, 0, 0}
local eye_size = 4
local speed    = 30.0
local pos      = 0.0
local dir      = 1.0

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
    pos = 0.0
    dir = 1.0
end

function update(buf, dt)
    local n = buf:len()
    buf:fade(0.8 ^ 60, dt)
    draw_eye(buf, pos)
    pos = pos + speed * dir * dt
    local max_pos = n - eye_size
    if pos >= max_pos then
        pos = max_pos
        dir = -1.0
    elseif pos < 0.0 then
        pos = 0.0
        dir = 1.0
    end
    return true
end

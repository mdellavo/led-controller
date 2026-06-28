name = "Halloween Eyes"

local eye_color   = {255, 0, 0}
local eye_width   = 1
local eye_spacing = 4
local fade_steps  = 50
local fade_delay  = 20.0   -- ms between fade steps
local end_pause   = 2000.0 -- ms after eyes disappear

local state     = "holding"
local eye_pos   = 0
local fade_step = 0
local timer     = 0.0

local function total_width()
    return eye_width * 2 + eye_spacing
end

local function draw_eyes(buf, brightness)
    local n = buf:len()
    local rv = math.floor(eye_color[1] * brightness)
    local gv = math.floor(eye_color[2] * brightness)
    local bv = math.floor(eye_color[3] * brightness)
    for i = 0, eye_width - 1 do
        local left  = eye_pos + i
        local right = eye_pos + eye_width + eye_spacing + i
        if left  < n then buf:set(left,  rv, gv, bv) end
        if right < n then buf:set(right, rv, gv, bv) end
    end
end

function init(n)
    eye_pos   = math.random(0, math.max(0, n - total_width()))
    state     = "holding"
    fade_step = 0
    timer     = 0.0
end

function update(buf, dt)
    local n = buf:len()
    timer = timer + dt * 1000.0
    buf:clear()

    if state == "holding" then
        draw_eyes(buf, 1.0)
        if timer >= fade_delay * 5.0 then
            timer     = 0.0
            fade_step = 0
            state     = "fading"
        end
    elseif state == "fading" then
        if timer >= fade_delay then
            timer     = timer - fade_delay
            fade_step = fade_step + 1
        end
        local brightness = fade_step >= fade_steps and 0.0 or (1.0 - fade_step / fade_steps)
        draw_eyes(buf, brightness)
        if fade_step >= fade_steps then
            state = "pausing"
        end
    else  -- pausing
        if timer >= end_pause then
            timer   = timer - end_pause
            eye_pos = math.random(0, math.max(0, n - total_width()))
            state   = "holding"
        end
    end

    return true
end

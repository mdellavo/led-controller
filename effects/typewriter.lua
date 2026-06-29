name = "Typewriter"
description = "Pixels illuminate left-to-right like text being typed, pause, then erase right-to-left."

local function colorwheel(pos)
    pos = math.floor(pos) % 256
    pos = (255 - pos) % 256
    if pos < 85 then return 255-pos*3, 0, pos*3
    elseif pos < 170 then pos=pos-85; return 0, pos*3, 255-pos*3
    else pos=pos-170; return pos*3, 255-pos*3, 0 end
end

local TYPE_SPD  = 0.035   -- seconds per pixel when typing
local ERASE_SPD = 0.018   -- faster erase
local PAUSE_DUR = 1.4

local state = "typing"
local pos   = 0
local timer = 0.0
local hue   = 0

function init(n)
    pos   = 0
    state = "typing"
    timer = 0.0
    hue   = math.random(0, 255)
end

function update(buf, dt)
    local n = buf:len()
    timer = timer + dt

    if state == "typing" then
        local target = math.floor(timer / TYPE_SPD)
        if target > pos then
            for i = pos, math.min(target, n) - 1 do
                local cr, cg, cb = colorwheel(math.floor((hue + i * 3) % 256))
                buf:set(i, cr, cg, cb)
            end
            pos = math.min(target, n)
        end
        if pos >= n then
            state = "pause"
            timer = 0.0
        end

    elseif state == "pause" then
        if timer >= PAUSE_DUR then
            state = "erasing"
            timer = 0.0
            pos   = n - 1
        end

    else  -- erasing
        local target = n - 1 - math.floor(timer / ERASE_SPD)
        if target < pos then
            for i = target + 1, pos do
                if i >= 0 and i < n then buf:set(i, 0, 0, 0) end
            end
            pos = target
        end
        if pos < 0 then
            hue   = (hue + 38) % 256
            state = "typing"
            timer = 0.0
            pos   = 0
        end
    end

    return true
end

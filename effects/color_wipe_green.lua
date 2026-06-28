name = "Color Wipe Green"

local cw_r, cw_g, cw_b = 0, 255, 0
local speed_ms = 20.0
local state    = "wiping"
local pos      = 0
local timer    = 0.0

function init(n)
    pos   = 0
    state = "wiping"
    timer = 0.0
end

function update(buf, dt)
    local n = buf:len()
    timer = timer + dt * 1000.0

    while timer >= speed_ms do
        timer = timer - speed_ms
        if state == "wiping" then
            if pos < n then
                buf:set(pos, cw_r, cw_g, cw_b)
                pos = pos + 1
            end
            if pos >= n then
                pos   = 0
                state = "clearing"
            end
        else
            if pos < n then
                buf:set(pos, 0, 0, 0)
                pos = pos + 1
            end
            if pos >= n then
                pos   = 0
                state = "wiping"
            end
        end
    end

    return true
end

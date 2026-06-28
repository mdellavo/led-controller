name = "Strobe"

local flash_r, flash_g, flash_b = 255, 255, 255
local flashes       = 10
local flash_delay   = 50.0   -- ms per on/off half-cycle
local end_pause     = 1000.0 -- ms between bursts

local state       = "on"  -- "on" | "off" | "pause"
local flash_count = 0
local timer       = 0.0

function update(buf, dt)
    local n = buf:len()
    timer = timer + dt * 1000.0

    if state == "on" then
        for i = 0, n - 1 do buf:set(i, flash_r, flash_g, flash_b) end
        if timer >= flash_delay then
            timer = timer - flash_delay
            state = "off"
        end
    elseif state == "off" then
        buf:clear()
        if timer >= flash_delay then
            timer = timer - flash_delay
            flash_count = flash_count + 1
            if flash_count >= flashes then
                flash_count = 0
                state = "pause"
            else
                state = "on"
            end
        end
    else  -- pause
        buf:clear()
        if timer >= end_pause then
            timer = timer - end_pause
            state = "on"
        end
    end

    return true
end

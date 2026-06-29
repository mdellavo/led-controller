name = "Pixel Sort"
description = "Bubble sort visualized — hued pixels shuffle into chromatic order, then reset."

local function colorwheel(pos)
    pos = math.floor(pos) % 256
    pos = (255 - pos) % 256
    if pos < 85 then return 255-pos*3, 0, pos*3
    elseif pos < 170 then pos=pos-85; return 0, pos*3, 255-pos*3
    else pos=pos-170; return pos*3, 255-pos*3, 0 end
end

local arr   = {}
local outer = 1
local inner = 1
local done  = false
local pause = 0
local STEPS = 3   -- compare-swaps per frame

function init(n)
    arr = {}
    for i = 1, n do arr[i] = math.random(0, 255) end
    outer = 1
    inner = 1
    done  = false
    pause = 0
end

function update(buf, dt)
    local n = buf:len()

    if done then
        pause = pause + dt
        if pause >= 2.5 then init(n) end
    else
        for _ = 1, STEPS do
            local limit = n - outer
            if limit < 1 then done = true; break end
            if arr[inner] > arr[inner + 1] then
                arr[inner], arr[inner + 1] = arr[inner + 1], arr[inner]
            end
            inner = inner + 1
            if inner > limit then
                inner = 1
                outer = outer + 1
            end
        end
    end

    -- sorted tail is dimmed to show progress
    local sorted_from = n - outer + 2
    for p = 1, n do
        local r, g, b = colorwheel(arr[p])
        if p >= sorted_from then
            buf:plot(p - 1, math.floor(r * 0.45), math.floor(g * 0.45), math.floor(b * 0.45), 1.0)
        else
            buf:plot(p - 1, r, g, b, 1.0)
        end
    end
    return true
end

name = "Hypnotic Spiral"
description = "Rotating color bands create a hypnotic optical illusion."

local t = 0

function init(n)
    t = 0
end

function update(buf, dt)
    local n   = buf:len()
    t = t + dt

    for i = 0, n - 1 do
        local x = i / n
        -- two overlapping bands rotating at different speeds
        local v1 = (math.sin(x * math.pi * 12 - t * 2.8) + 1) * 0.5
        local v2 = (math.sin(x * math.pi *  7 + t * 1.9) + 1) * 0.5
        local combined = v1 * 0.55 + v2 * 0.45

        -- hue sweeps along strip and rotates with time
        local hue = math.floor((x * 230 + t * 45) % 256)
        local pos = (255 - hue) % 256
        local r, g, b
        if pos < 85 then r, g, b = 255-pos*3, 0, pos*3
        elseif pos < 170 then local p=pos-85; r, g, b = 0, p*3, 255-p*3
        else local p=pos-170; r, g, b = p*3, 255-p*3, 0 end

        buf:plot(i,
            math.floor(r * combined),
            math.floor(g * combined),
            math.floor(b * combined), 1.0)
    end
    return true
end

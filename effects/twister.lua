name = "Twister"
description = "Multiple overlapping sine waves at different frequencies create shifting interference patterns"

local WAVES = {
    { scale = 1.00, speed =  0.80, hue = 0   },
    { scale = 1.73, speed = -1.10, hue = 85  },
    { scale = 2.41, speed =  1.50, hue = 170 },
    { scale = 3.17, speed = -0.60, hue = 42  },
}

local phases = { 0, 0, 0, 0 }

local function colorwheel(p)
    p = math.floor(p) % 256
    p = (255 - p) % 256
    if p < 85 then return 255-p*3, 0, p*3
    elseif p < 170 then p=p-85; return 0, p*3, 255-p*3
    else p=p-170; return p*3, 255-p*3, 0 end
end

function update(buf, dt)
    local n   = buf:len()
    local pi2 = 2 * math.pi

    for j, w in ipairs(WAVES) do
        phases[j] = phases[j] + w.speed * dt
    end

    for i = 0, n - 1 do
        local x = i / n * pi2

        local tr, tg, tb = 0, 0, 0

        for j, w in ipairs(WAVES) do
            local v   = (math.sin(x * w.scale + phases[j]) + 1) / 2
            local amp = v * v  -- sharpen peaks so dark gaps appear between strands
            local r, g, b = colorwheel(w.hue)
            tr = tr + r * amp
            tg = tg + g * amp
            tb = tb + b * amp
        end

        local sc = 1 / #WAVES
        buf:set(i,
            math.min(255, math.floor(tr * sc)),
            math.min(255, math.floor(tg * sc)),
            math.min(255, math.floor(tb * sc)))
    end

    return true
end

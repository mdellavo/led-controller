name = "Lava Lamp"
description = "Slow warm blobs drift through a dim red background, like a lava lamp"

local NUM_BLOBS = 5
local blobs     = {}

function init(n)
    blobs = {}
    for i = 1, NUM_BLOBS do
        table.insert(blobs, {
            phase = math.random() * 2 * math.pi,
            speed = (math.random() * 0.25 + 0.08) * (math.random() < 0.5 and 1 or -1),
            sigma = (math.random() * 0.12 + 0.06),  -- width as fraction of strip
            r     = math.random(200, 255),
            g     = math.random(40,  100),
            b     = 0,
        })
    end
end

function update(buf, dt)
    local n = buf:len()

    -- Dim warm background
    for i = 0, n - 1 do buf:set(i, 18, 4, 0) end

    -- Additively blend each blob
    for _, blob in ipairs(blobs) do
        blob.phase = blob.phase + blob.speed * dt
        local center = (math.sin(blob.phase) + 1.0) / 2.0 * (n - 1)
        local sigma  = blob.sigma * n

        for i = 0, n - 1 do
            local dist   = i - center
            local bright = math.exp(-(dist * dist) / (2 * sigma * sigma))
            if bright > 0.01 then
                local er, eg, eb = buf:get(i)
                buf:set(i,
                    math.min(255, er + math.floor(blob.r * bright)),
                    math.min(255, eg + math.floor(blob.g * bright)),
                    math.min(255, eb + math.floor(blob.b * bright)))
            end
        end
    end

    return true
end

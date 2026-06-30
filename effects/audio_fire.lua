name        = "Audio Fire"
description = "Fire simulation driven by audio — silence leaves cold embers, loud peaks drive flames to the tips, and beats send explosive flares."

local heat = {}

function init(n)
    for i = 1, n + 4 do
        heat[i] = 0
    end
end

local function fire_color(v)
    -- v: 0=black → 0.4=deep red → 0.7=orange/yellow → 1.0=white
    v = math.max(0, math.min(1, v))
    if v < 0.4 then
        local f = v / 0.4
        return math.floor(f * 255), 0, 0
    elseif v < 0.7 then
        local f = (v - 0.4) / 0.3
        return 255, math.floor(f * 180), 0
    else
        local f = (v - 0.7) / 0.3
        return 255, math.floor(180 + f * 75), math.floor(f * 220)
    end
end

function update(buf, dt)
    local n    = buf:len()
    local amp  = AUDIO_AMP  or 0
    local beat = AUDIO_BEAT or 0
    local bass = AUDIO_BASS or 0

    -- Base heat from amplitude; beats add explosive flares
    local base = amp * 0.8 + bass * 0.15 + beat * 0.4

    -- Stoke the base — more sparks the louder it gets
    local sparks = math.floor(1 + base * 5)
    for _ = 1, sparks do
        local p = math.random(1, math.max(1, math.floor(n * 0.2)))
        heat[p] = math.min(1, heat[p] + base * (0.4 + math.random() * 0.6))
    end

    -- On a beat, add a sudden surge across the base
    if beat > 0.7 then
        for i = 1, math.floor(n * 0.25) do
            heat[i] = math.min(1, heat[i] + beat * 0.5)
        end
    end

    -- Diffuse upward and cool slightly
    local cool = 0.015 + (1 - amp) * 0.03
    for i = n + 4, 2, -1 do
        heat[i] = ((heat[i - 1] or 0) * 0.55
                 + (heat[i]     or 0) * 0.40) * (1 - cool * dt * 60)
        heat[i] = math.max(0, heat[i])
    end

    buf:clear()
    for i = 1, n do
        local r, g, b = fire_color(heat[n + 4 + 1 - i])
        buf:set(i - 1, r, g, b)
    end

    return true
end

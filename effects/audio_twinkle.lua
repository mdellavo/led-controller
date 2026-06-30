name        = "Audio Twinkle"
description = "Stars spawn at a rate proportional to audio amplitude. Each beat sends a white flash that fades back to the starfield. Treble frequencies tint stars blue-white."

function update(buf, dt)
    local n    = buf:len()
    local amp  = AUDIO_AMP  or 0
    local beat = AUDIO_BEAT or 0
    local high = AUDIO_HIGH or 0

    -- Decay background; silence fades fast, loud audio preserves stars longer
    buf:fade(0.04 + amp * 0.12, dt)

    -- Beat flash: additive white overlay proportional to beat envelope
    if beat > 0.05 then
        local flash = math.floor(beat * beat * 200)
        for i = 0, n - 1 do
            local r, g, b = buf:get(i)
            buf:set(i,
                math.min(255, r + flash),
                math.min(255, g + flash),
                math.min(255, b + flash))
        end
    end

    -- Spawn stars — quadratic in amplitude so quiet audio gives just a few
    local spawn = math.floor(amp * amp * n * 3 + amp * 0.5)
    for _ = 1, spawn do
        local pos = math.random(0, n - 1)
        -- Cool white shifted toward blue with treble content
        local brightness = math.floor(180 + amp * 75)
        local blue_boost = math.floor(high * 75)
        buf:set(pos,
            math.max(0, brightness - blue_boost),
            math.max(0, brightness - math.floor(blue_boost * 0.3)),
            math.min(255, brightness + blue_boost))
    end

    return true
end

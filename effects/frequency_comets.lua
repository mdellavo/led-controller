name        = "Frequency Comets"
description = "Three comets orbit the strip — bass (red), mid (green), treble (blue). Each brightens and accelerates when its frequency band is active."

local comets = {
    { pos = 0,   vel = 25,  r = 255, g = 30,  b = 30,  band = "bass" },
    { pos = 0,   vel = 45,  r = 30,  g = 220, b = 80,  band = "mid"  },
    { pos = 0,   vel = 75,  r = 60,  g = 100, b = 255, band = "high" },
}

function init(n)
    comets[1].pos = 0
    comets[2].pos = n / 3
    comets[3].pos = n * 2 / 3
end

function update(buf, dt)
    local n    = buf:len()
    local bass = AUDIO_BASS or 0
    local mid  = AUDIO_MID  or 0
    local high = AUDIO_HIGH or 0
    local amp  = AUDIO_AMP  or 0

    local levels = { bass = bass, mid = mid, high = high }

    buf:fade(0.07 + amp * 0.05, dt)

    for _, c in ipairs(comets) do
        local level = levels[c.band]
        c.pos = (c.pos + c.vel * (1 + level * 5) * dt) % n
        local alpha = 0.15 + level * 0.85
        buf:plot(c.pos, c.r, c.g, c.b, alpha)
    end

    return true
end

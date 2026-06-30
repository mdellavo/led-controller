name        = "Harmonic Rings"
description = "16 sine waves layered additively — each wave's amplitude tracks its frequency band. The superposition morphs continuously with the music."

local t = 0

-- Precomputed hue→RGB lookup (16 evenly-spaced hues, bass=red to treble=violet)
local BAND_R = {}
local BAND_G = {}
local BAND_B = {}

local function _hsv_to_rgb(h)
    -- h: 0–360
    local i = math.floor(h / 60) % 6
    local f = h / 60 - math.floor(h / 60)
    local q = 1 - f
    local lr, lg, lb
    if     i == 0 then lr,lg,lb = 1,f,0
    elseif i == 1 then lr,lg,lb = q,1,0
    elseif i == 2 then lr,lg,lb = 0,1,f
    elseif i == 3 then lr,lg,lb = 0,q,1
    elseif i == 4 then lr,lg,lb = f,0,1
    else              lr,lg,lb = 1,0,q end
    return lr, lg, lb
end

function init(n)
    for band = 1, 16 do
        local hue = (band - 1) / 15 * 270
        local r, g, b = _hsv_to_rgb(hue)
        BAND_R[band] = r
        BAND_G[band] = g
        BAND_B[band] = b
    end
end

function update(buf, dt)
    local n   = buf:len()
    local amp = AUDIO_AMP  or 0
    local spec = AUDIO_SPECTRUM

    t = t + dt

    local pi2 = 2 * math.pi

    for px = 0, n - 1 do
        local x  = px / n
        local rs, gs, bs = 0, 0, 0

        for band = 1, 16 do
            local energy = (spec and spec[band] or 0)
            if energy > 0.01 then
                -- Spatial frequency increases with band index
                local spatial = band * 1.5
                -- Temporal drift speed also increases with band
                local temporal = band * 0.4
                local phase = pi2 * (spatial * x - temporal * t)
                -- Half-rectified wave (0..1) gives additive-only contribution
                local wave = (math.sin(phase) + 1) * 0.5
                local contribution = wave * energy
                rs = rs + BAND_R[band] * contribution
                gs = gs + BAND_G[band] * contribution
                bs = bs + BAND_B[band] * contribution
            end
        end

        -- Scale by amplitude so silence is dark
        local scale = 0.15 + amp * 0.85
        buf:set(px,
            math.min(255, math.floor(rs * 180 * scale)),
            math.min(255, math.floor(gs * 180 * scale)),
            math.min(255, math.floor(bs * 180 * scale)))
    end

    return true
end

name = "Morse Code"
description = "Flashes 'SOS' in International Morse Code on a repeating loop"

local MESSAGE = "SOS"
local UNIT_S  = 0.15   -- one dit = 150 ms

local MORSE = {
    A=".-",   B="-...", C="-.-.", D="-..",  E=".",    F="..-.",
    G="--.",  H="....", I="..",   J=".---", K="-.-",  L=".-..",
    M="--",   N="-.",   O="---",  P=".--.", Q="--.-", R=".-.",
    S="...",  T="-",    U="..-",  V="...-", W=".--",  X="-..-",
    Y="-.--", Z="--..",
}

-- Build flat sequence of {on, duration_in_units}
local function encode(msg)
    local seq = {}
    local first = true
    msg = msg:upper()
    for ci = 1, #msg do
        local ch = msg:sub(ci, ci)
        if ch == " " then
            if #seq > 0 then seq[#seq].dur = seq[#seq].dur + 4 end
            first = true
        else
            local code = MORSE[ch] or ""
            if not first then
                seq[#seq + 1] = { on = false, dur = 3 }  -- inter-char gap
            end
            first = false
            for si = 1, #code do
                if si > 1 then seq[#seq + 1] = { on = false, dur = 1 } end
                seq[#seq + 1] = { on = true, dur = code:sub(si, si) == "-" and 3 or 1 }
            end
        end
    end
    seq[#seq + 1] = { on = false, dur = 7 }  -- inter-message gap
    return seq
end

local sequence = encode(MESSAGE)
local seq_idx  = 1
local timer    = 0.0

function update(buf, dt)
    local n = buf:len()
    timer = timer + dt

    -- Advance through sequence
    while timer >= sequence[seq_idx].dur * UNIT_S do
        timer   = timer - sequence[seq_idx].dur * UNIT_S
        seq_idx = seq_idx % #sequence + 1
    end

    if sequence[seq_idx].on then
        for i = 0, n - 1 do buf:set(i, 255, 220, 80) end
    else
        buf:clear()
    end

    return true
end

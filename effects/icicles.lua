name = "Icicles"
description = "Ice crystals grow from anchor points, drip, and shatter on impact."

local NUM = 5
local icicles = {}

local function new_icicle(anchor, n)
    return {
        anchor    = anchor,
        length    = 0,
        max_len   = math.floor(n * 0.12 + math.random() * n * 0.18),
        grow_spd  = math.random() * 2.5 + 0.8,
        dripping  = false,
        drip_pos  = 0,
        drip_vel  = 0,
        delay     = math.random() * 5.0,
    }
end

function init(n)
    icicles = {}
    for i = 1, NUM do
        local anchor = math.floor((i - 0.5) * n / NUM)
        icicles[i] = new_icicle(anchor, n)
    end
end

function update(buf, dt)
    local n = buf:len()
    buf:clear()

    for idx = 1, #icicles do
        local ic = icicles[idx]

        if ic.delay > 0 then
            ic.delay = ic.delay - dt

        elseif not ic.dripping then
            ic.length = ic.length + ic.grow_spd * dt
            if ic.length >= ic.max_len then
                ic.dripping = true
                ic.drip_pos = ic.anchor + ic.length
                ic.drip_vel = 3.0
            end

        else
            ic.drip_vel = ic.drip_vel + 18.0 * dt
            ic.drip_pos = ic.drip_pos + ic.drip_vel * dt
            if ic.drip_pos >= n then
                icicles[idx] = new_icicle(ic.anchor, n)
                icicles[idx].delay = math.random() * 4.0 + 1.5
            end
        end

        -- draw icicle body (blue-white, tip darker)
        local tip = math.floor(ic.anchor + ic.length)
        for p = ic.anchor, math.min(tip, n - 1) do
            local frac = (p - ic.anchor) / (ic.max_len + 0.001)
            local v  = math.floor(210 - frac * 90)
            local bv = math.floor(250 - frac * 30)
            buf:plot(p, math.floor(v * 0.72), math.floor(v * 0.88), bv, 1.0)
        end

        -- draw drip bead
        if ic.dripping then
            local dp = ic.drip_pos
            if dp >= 0 and dp < n then
                buf:plot(dp, 100, 190, 255, 1.0)
            end
        end
    end

    return true
end

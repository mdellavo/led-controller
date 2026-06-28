name = "Police Lights"

-- Alternating red/blue half-strip strobes with a brief white center flash between sides.
local cycle_ms = 600.0
local timer    = 0.0

function update(buf, dt)
    local n    = buf:len()
    local half = math.floor(n / 2)
    local cx   = math.floor(n / 2)
    timer = (timer + dt * 1000.0) % cycle_ms
    local phase = timer / cycle_ms  -- 0.0–1.0

    buf:clear()

    if phase < 0.38 then
        for i = 0, half - 1 do buf:set(i, 255, 0, 0) end
    elseif phase < 0.42 then
        for i = math.max(0, cx - 2), math.min(n - 1, cx + 2) do
            buf:set(i, 255, 255, 255)
        end
    elseif phase < 0.50 then
        -- brief off
    elseif phase < 0.88 then
        for i = half, n - 1 do buf:set(i, 0, 0, 255) end
    elseif phase < 0.92 then
        for i = math.max(0, cx - 2), math.min(n - 1, cx + 2) do
            buf:set(i, 255, 255, 255)
        end
    end
    -- 0.92–1.0: brief off before repeat

    return true
end

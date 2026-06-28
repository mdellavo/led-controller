name = "Lua Sparkle"

-- Random pixels ignite to white and decay over time.
-- buf:fade() keeps the decay frame-rate independent.

function update(buf, dt)
    buf:fade(0.05, dt)
    local n = buf:len()
    if math.random() < 0.4 then
        local v = math.random(180, 255)
        buf:set(math.random(0, n - 1), v, v, v)
    end
    return true
end

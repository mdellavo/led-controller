name = "Solid Blue"

function update(buf, dt)
    local n = buf:len()
    for i = 0, n - 1 do buf:set(i, 0, 0, 200) end
    return true
end

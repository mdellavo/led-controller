name = "Solid White"

function update(buf, dt)
    local n = buf:len()
    for i = 0, n - 1 do buf:set(i, 200, 200, 200) end
    return true
end

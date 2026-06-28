name = "Solid Green"
description = "Solid static green"

function update(buf, dt)
    local n = buf:len()
    for i = 0, n - 1 do buf:set(i, 0, 200, 0) end
    return true
end

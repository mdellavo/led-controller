name = "Solid Red"
description = "Solid static red"

function update(buf, dt)
    local n = buf:len()
    for i = 0, n - 1 do buf:set(i, 200, 0, 0) end
    return true
end

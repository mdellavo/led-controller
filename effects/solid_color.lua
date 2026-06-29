name = "Solid Color"
description = "Strip fills with the user-selected color from the Color picker."

function update(buf, dt)
    local r = COLOR_R or 255
    local g = COLOR_G or 255
    local b = COLOR_B or 255
    local n = buf:len()
    for i = 0, n - 1 do buf:set(i, r, g, b) end
    return true
end

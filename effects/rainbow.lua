name = "Lua Rainbow"

local hue = 0.0

local function hsv(h, s, v)
    local i = math.floor(h * 6) % 6
    local f = h * 6 - math.floor(h * 6)
    local p = v * (1 - s)
    local q = v * (1 - f * s)
    local t = v * (1 - (1 - f) * s)
    if i == 0 then return v, t, p
    elseif i == 1 then return q, v, p
    elseif i == 2 then return p, v, t
    elseif i == 3 then return p, q, v
    elseif i == 4 then return t, p, v
    else return v, p, q end
end

function update(buf, dt)
    local n = buf:len()
    for i = 0, n - 1 do
        local r, g, b = hsv((hue + i / n) % 1.0, 1.0, 1.0)
        buf:set(i, math.floor(r * 255), math.floor(g * 255), math.floor(b * 255))
    end
    hue = (hue + dt * 0.08) % 1.0
    return true
end

name = "Double Pendulum"
description = "Chaotic double-pendulum physics — the tip traces an unpredictable path with a fading color trail."

local function colorwheel(pos)
    pos = math.floor(pos) % 256
    pos = (255 - pos) % 256
    if pos < 85 then return 255-pos*3, 0, pos*3
    elseif pos < 170 then pos=pos-85; return 0, pos*3, 255-pos*3
    else pos=pos-170; return pos*3, 255-pos*3, 0 end
end

local G  = 9.8
local L1, L2 = 1.0, 1.0
local M1, M2 = 1.0, 1.0

local th1, th2 = 0, 0   -- angles
local w1,  w2  = 0, 0   -- angular velocities
local hue = 0

local function accel()
    local d    = th1 - th2
    local sd   = math.sin(d)
    local cd   = math.cos(d)
    local denom = 2*M1 + M2 - M2 * math.cos(2*d)

    local a1 = (-G*(2*M1+M2)*math.sin(th1)
                - M2*G*math.sin(th1 - 2*th2)
                - 2*sd*M2*(w2*w2*L2 + w1*w1*L1*cd))
               / (L1 * denom)

    local a2 = (2*sd*(w1*w1*L1*(M1+M2)
                + G*(M1+M2)*math.cos(th1)
                + w2*w2*L2*M2*cd))
               / (L2 * denom)
    return a1, a2
end

function init(n)
    -- slightly off-vertical for chaos
    th1 = math.pi * (0.85 + (math.random() - 0.5) * 0.2)
    th2 = math.pi * (0.80 + (math.random() - 0.5) * 0.2)
    w1, w2 = 0, 0
    hue = math.random(0, 255)
end

function update(buf, dt)
    local n = buf:len()
    buf:fade(0.78^60, dt)

    -- RK4 sub-steps for stability
    local SUB = 8
    local h   = dt / SUB
    for _ = 1, SUB do
        local a1, a2 = accel()
        w1  = w1  + a1 * h
        w2  = w2  + a2 * h
        th1 = th1 + w1 * h
        th2 = th2 + w2 * h
    end

    -- x-position of tip 2 in range [-2, 2] → [0, n-1]
    local x2  = L1 * math.sin(th1) + L2 * math.sin(th2)
    local pos = (x2 + 2.0) / 4.0 * (n - 1)

    hue = (hue + 55 * dt) % 256
    local r, g, b = colorwheel(math.floor(hue))
    buf:plot(pos, r, g, b, 1.0)

    return true
end

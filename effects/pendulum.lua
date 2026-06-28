name = "Pendulum"
description = "A glowing dot swings with realistic pendulum physics, slowing at each end"

local theta   = 0.75  -- starting angle in radians (~43°)
local omega   = 0.0   -- angular velocity rad/s
local G_OVER_L = 4.9  -- g/L ratio (controls period; ~3.6s for θ₀=0.75)
local THETA_MAX = 0.75

function update(buf, dt)
    local n = buf:len()

    -- Symplectic Euler integration (energy-preserving for undamped pendulum)
    omega = omega - G_OVER_L * math.sin(theta) * dt
    theta = theta + omega * dt

    -- Map angle to strip position
    local pos = math.max(0, math.min(n - 1,
        (theta / THETA_MAX + 1.0) / 2.0 * (n - 1)))

    buf:fade(0.82^60, dt)

    -- Glow proportional to speed (brighter at center, dimmer at ends)
    local speed_frac = math.min(1.0, math.abs(omega) / (THETA_MAX * G_OVER_L^0.5))
    local bright = 0.4 + speed_frac * 0.6

    buf:plot(pos, 255, 200, 60, bright)
    buf:plot(pos - 0.5, 255, 120, 20, bright * 0.3)
    buf:plot(pos + 0.5, 255, 120, 20, bright * 0.3)

    return true
end

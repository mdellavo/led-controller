name = "Reaction Diffusion"
description = "Gray-Scott activator-inhibitor model; organic Turing stripe patterns emerge from chemistry"

local DA = 0.20   -- activator diffusion rate
local DB = 0.10   -- inhibitor diffusion rate
local F  = 0.055  -- feed rate  (coral / mitosis parameters)
local K  = 0.062  -- kill rate

local A = {}
local B = {}

local function seed(n)
    for i = 1, n do A[i] = 1.0; B[i] = 0.0 end
    for _ = 1, 4 do
        local c = math.random(2, n - 1)
        for d = -2, 2 do
            local idx = ((c + d - 1) % n) + 1
            A[idx] = 0.50 + (math.random() - 0.5) * 0.1
            B[idx] = 0.25 + (math.random() - 0.5) * 0.05
        end
    end
end

function init(n)
    A = {}; B = {}
    seed(n)
end

function update(buf, dt)
    local n = buf:len()

    -- Multiple sim steps per visual frame (dt_sim = 0.5, steps = 20)
    for _ = 1, 20 do
        local nA = {}
        local nB = {}
        for i = 1, n do
            local p = ((i - 2) % n) + 1
            local q = (i % n) + 1
            local lapA = A[p] + A[q] - 2 * A[i]
            local lapB = B[p] + B[q] - 2 * B[i]
            local react = A[i] * B[i] * B[i]
            nA[i] = math.max(0, math.min(1, A[i] + (DA * lapA - react + F * (1 - A[i])) * 0.5))
            nB[i] = math.max(0, math.min(1, B[i] + (DB * lapB + react - (F + K) * B[i]) * 0.5))
        end
        A = nA; B = nB
    end

    -- Check for extinction; re-seed if needed
    local total_B = 0
    for i = 1, n do total_B = total_B + B[i] end
    if total_B < 0.01 then seed(n) end

    -- Render: low B → deep blue, high B → bright cyan-white
    for i = 0, n - 1 do
        local b_val = B[i + 1]
        local t = math.min(1.0, b_val * 4)   -- 0.25 → fully saturated
        buf:set(i,
            math.floor(t * t * 100),
            math.floor(t * 210),
            math.floor(30 + t * 225))
    end

    return true
end

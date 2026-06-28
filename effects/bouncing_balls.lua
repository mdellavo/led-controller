name = "Bouncing Balls"

local DEFAULT_COLORS = {{255, 0, 0}, {0, 255, 0}, {0, 0, 255}}

local balls = {}

function init(n)
    balls = {}
    for i, c in ipairs(DEFAULT_COLORS) do
        table.insert(balls, {
            r         = c[1],
            g         = c[2],
            b         = c[3],
            height    = 1.0,
            velocity  = -(i * 0.5),
            dampening = 0.85 + math.min(0.1, (i - 1) * 0.02),
        })
    end
end

function update(buf, dt)
    local n       = buf:len()
    local gravity = -9.8 * n * 0.01

    buf:clear()

    for _, ball in ipairs(balls) do
        ball.velocity = ball.velocity + gravity * dt
        ball.height   = ball.height   + ball.velocity * dt

        if ball.height <= 0.0 then
            ball.height   = 0.0
            ball.velocity = -ball.velocity * ball.dampening
            if math.abs(ball.velocity) < 0.01 then
                ball.velocity = 1.0
            end
        end

        ball.height = math.max(0.0, math.min(1.0, ball.height))
        local pos   = (1.0 - ball.height) * (n - 1)
        buf:plot(pos, ball.r, ball.g, ball.b, 1.0)
    end

    return true
end

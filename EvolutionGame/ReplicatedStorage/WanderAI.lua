local WanderAI = {}

function WanderAI.startWandering(model)
    local humanoid = model:FindFirstChildOfClass("Humanoid")
    if not humanoid then return end

    local rootPart = model.PrimaryPart
    if not rootPart then return end

    coroutine.wrap(function()
        while model.Parent do
            local randomDirection
            repeat
                randomDirection = Vector3.new(math.random(-1, 1), 0, math.random(-1, 1))
            until randomDirection.Magnitude > 0
            randomDirection = randomDirection.Unit

            local targetPosition = rootPart.Position + randomDirection * math.random(10, 30)

            humanoid:MoveTo(targetPosition)
            humanoid.MoveToFinished:Wait()

            task.wait(math.random(2, 5))
        end
    end)()
end

return WanderAI

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldUtil = require(ReplicatedStorage.WorldUtil)

local AnimalService = {}

function AnimalService.spawnAnimal()
    local x = math.random(1, 1024)
    local z = math.random(1, 1024)

    local groundPosition = WorldUtil.getGroundPosition(x, z)

    if groundPosition then
        local y = groundPosition.Y + 2

        local animal = Instance.new("Part")
        animal.Parent = workspace
        animal.Size = Vector3.new(2, 2, 4)
        animal.Position = Vector3.new(x, y, z)
        animal.Anchored = false -- Animals should be able to move
        animal.Name = "Animal"
        animal.Color = Color3.fromRGB(150, 75, 0) -- Brown
    end
end

function AnimalService.start()
    print("AnimalService started")
    -- Spawn a few animals to start
    for _ = 1, 10 do
        AnimalService.spawnAnimal()
    end
end

return AnimalService

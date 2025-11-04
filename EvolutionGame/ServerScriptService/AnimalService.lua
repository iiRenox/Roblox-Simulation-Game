local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldUtil = require(ReplicatedStorage.WorldUtil)

local AnimalService = {}

function AnimalService.spawnAnimal()
    print("Attempting to spawn an animal...")
    -- Spawn within the full range of the generated world
    local x = math.random(-1024, 1024)
    local z = math.random(-1024, 1024)
    print("Generated coordinates: " .. x .. ", " .. z)

    local groundPosition = WorldUtil.getGroundPosition(x, z)

    if groundPosition then
        print("Ground found at: " .. tostring(groundPosition))
        local y = groundPosition.Y + 2

        local animal = Instance.new("Part")
        animal.Parent = workspace
        animal.Size = Vector3.new(2, 2, 4)
        animal.Position = Vector3.new(x, y, z)
        animal.Anchored = false -- Animals should be able to move
        animal.Name = "Animal"
        animal.Color = Color3.fromRGB(150, 75, 0) -- Brown
        print("Animal spawned successfully at: " .. tostring(animal.Position))
    else
        print("Failed to find ground for animal at: " .. x .. ", " .. z)
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

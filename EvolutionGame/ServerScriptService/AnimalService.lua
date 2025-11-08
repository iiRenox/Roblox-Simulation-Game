local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldUtil = require(ReplicatedStorage.WorldUtil)
local WanderAI = require(ReplicatedStorage.WanderAI)

local AnimalService = {}

function AnimalService.createAnimal(spawnPosition)
    local animal = Instance.new("Model")
    animal.Name = "Animal"

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(4, 2, 6)
    torso.Color = Color3.fromRGB(150, 75, 0)
    torso.Parent = animal

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(2, 2, 2)
    head.Position = Vector3.new(0, 1, -4)
    head.Color = Color3.fromRGB(150, 75, 0)
    head.Parent = animal
    local weldHead = Instance.new("WeldConstraint")
    weldHead.Part0 = torso
    weldHead.Part1 = head
    weldHead.Parent = torso

    local legSize = Vector3.new(1, 2, 1)
    local legPositions = {
        Vector3.new(1.5, -2, 2),
        Vector3.new(-1.5, -2, 2),
        Vector3.new(1.5, -2, -2),
        Vector3.new(-1.5, -2, -2)
    }

    for i, pos in ipairs(legPositions) do
        local leg = Instance.new("Part")
        leg.Name = "Leg" .. i
        leg.Size = legSize
        leg.Position = pos
        leg.Color = Color3.fromRGB(150, 75, 0)
        leg.Parent = animal
        local weldLeg = Instance.new("WeldConstraint")
        weldLeg.Part0 = torso
        weldLeg.Part1 = leg
        weldLeg.Parent = torso
    end

    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = animal

    animal.PrimaryPart = torso
    animal:SetPrimaryPartCFrame(CFrame.new(spawnPosition))

    return animal
end

function AnimalService.spawnAnimal()
    print("Attempting to spawn an animal...")
    local x = math.random(-1024, 1024)
    local z = math.random(-1024, 1024)
    print("Generated coordinates: " .. x .. ", " .. z)

    local groundPosition = WorldUtil.getGroundPosition(x, z)

    if groundPosition then
        print("Ground found at: " .. tostring(groundPosition))
        local spawnPosition = groundPosition + Vector3.new(0, 4, 0)

        local animal = AnimalService.createAnimal(spawnPosition)
        animal.Parent = workspace
        WanderAI.startWandering(animal)

        print("Animal spawned successfully at: " .. tostring(spawnPosition))
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

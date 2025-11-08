local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldUtil = require(ReplicatedStorage.WorldUtil)
local Animal = require(ServerScriptService.Animal)
local TimeService = require(ServerScriptService.TimeService)

local AnimalService = {}

local activeAnimals = {} -- Holds all the active Animal objects

function AnimalService.getActiveAnimals()
    return activeAnimals
end

function AnimalService.createLandAnimal(spawnPosition)
    local animal = Instance.new("Model")
    animal.Name = "LandAnimal"

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

function AnimalService.createWaterAnimal(spawnPosition)
    local animal = Instance.new("Model")
    animal.Name = "WaterAnimal"

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 3, 5)
    torso.Color = Color3.fromRGB(0, 100, 200) -- Blue
    torso.Parent = animal

    local tail = Instance.new("Part")
    tail.Name = "Tail"
    tail.Size = Vector3.new(1, 1, 3)
    tail.Position = Vector3.new(0, 0, 4)
    tail.Color = Color3.fromRGB(0, 80, 180)
    tail.Parent = animal
    local weldTail = Instance.new("WeldConstraint")
    weldTail.Part0 = torso
    weldTail.Part1 = tail
    weldTail.Parent = torso

    animal.PrimaryPart = torso
    animal:SetPrimaryPartCFrame(CFrame.new(spawnPosition))

    return animal
end

function AnimalService.spawnAnimal()
    local animalType = math.random(1, 2)
    local maxAttempts = 50
    local attempts = 0
    local positionFound = false
    local groundPosition, material

    print("Attempting to spawn a ".. (animalType == 1 and "Land" or "Water") .." animal...")

    while not positionFound and attempts < maxAttempts do
        local x = math.random(-1024, 1024)
        local z = math.random(-1024, 1024)

        groundPosition = WorldUtil.getGroundPosition(x, z)

        if groundPosition then
            material = WorldUtil.getMaterialAtPosition(groundPosition)

            if animalType == 1 and material ~= Enum.Material.Water then
                positionFound = true
            elseif animalType == 2 and material == Enum.Material.Water then
                positionFound = true
            end
        end
        attempts = attempts + 1
    end

    if positionFound then
        if animalType == 1 then
            local spawnPosition = groundPosition + Vector3.new(0, 4, 0)
            local animalModel = AnimalService.createLandAnimal(spawnPosition)
            animalModel.Parent = workspace

            local animalObject = Animal.new(animalModel)
            table.insert(activeAnimals, animalObject)

            print("Land animal spawned successfully at: " .. tostring(spawnPosition))
            return animalObject
        else
            local waterDepth = 0
            local waterPosition = Vector3.new(groundPosition.X, waterDepth, groundPosition.Z)
            local animal = AnimalService.createWaterAnimal(waterPosition)
            animal.Parent = workspace
            -- NOTE: Water animals do not yet have AI
            print("Water animal spawned successfully at: " .. tostring(waterPosition))
        end
    else
        print("Failed to find a valid location for animal after " .. maxAttempts .. " attempts.")
    end
end

function AnimalService.start()
    print("AnimalService started")
    -- Spawn a mix of animals to start
    for _ = 1, 20 do
        AnimalService.spawnAnimal()
    end

    -- Connect to the game loop
    TimeService.getTick():Connect(function(deltaTime)
        for _, animal in ipairs(activeAnimals) do
            animal:update(deltaTime, activeAnimals, AnimalService.spawnAnimal)
        end
    end)
end

return AnimalService

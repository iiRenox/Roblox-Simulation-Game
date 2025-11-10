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

function AnimalService.createLandAnimal(spawnPosition, genome)
    local animal = Instance.new("Model")
    animal.Name = "LandAnimal"

    -- Base color variation
    local baseColor = Color3.fromHSV(math.random(), 0.6, 0.8)

    -- Archetype generation based on genome
    local torsoSize
    local headSize
    local snout

    if genome.dietType > 0.5 then -- Carnivore (Wolf-like)
        torsoSize = Vector3.new(genome.size * 0.8, genome.size * 0.4, genome.size * 1.2)
        headSize = Vector3.new(genome.size * 0.4, genome.size * 0.4, genome.size * 0.4)
        snout = true
    elseif genome.size > 10 then -- Large Herbivore (Elephant-like)
        torsoSize = Vector3.new(genome.size, genome.size * 1.2, genome.size * 1.5)
        headSize = Vector3.new(genome.size * 0.5, genome.size * 0.5, genome.size * 0.5)
    else -- Small Herbivore (Bunny-like)
        torsoSize = Vector3.new(genome.size * 0.6, genome.size, genome.size * 0.8)
        headSize = Vector3.new(genome.size * 0.3, genome.size * 0.3, genome.size * 0.3)
    end

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = torsoSize
    torso.Color = baseColor
    torso.Parent = animal

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = headSize
    head.Position = Vector3.new(0, torsoSize.Y / 2, -torsoSize.Z / 2 - headSize.Z / 2)
    head.Color = baseColor
    head.Parent = animal
    local weldHead = Instance.new("WeldConstraint")
    weldHead.Part0 = torso
    weldHead.Part1 = head
    weldHead.Parent = torso

    if snout then
        local snoutPart = Instance.new("Part")
        snoutPart.Name = "Snout"
        snoutPart.Size = Vector3.new(headSize.X * 0.5, headSize.Y * 0.5, headSize.Z)
        snoutPart.Position = head.Position + Vector3.new(0, 0, -headSize.Z / 2)
        snoutPart.Color = baseColor
        snoutPart.Parent = animal
        local weldSnout = Instance.new("WeldConstraint")
        weldSnout.Part0 = head
        weldSnout.Part1 = snoutPart
        weldSnout.Parent = head
    end

    local legSize = Vector3.new(genome.size * 0.2, genome.size * 0.5, genome.size * 0.2)
    local legPositions = {
        Vector3.new(torsoSize.X/2, -torsoSize.Y/2, torsoSize.Z/2),
        Vector3.new(-torsoSize.X/2, -torsoSize.Y/2, torsoSize.Z/2),
        Vector3.new(torsoSize.X/2, -torsoSize.Y/2, -torsoSize.Z/2),
        Vector3.new(-torsoSize.X/2, -torsoSize.Y/2, -torsoSize.Z/2)
    }

    for i, pos in ipairs(legPositions) do
        local leg = Instance.new("Part")
        leg.Name = "Leg" .. i
        leg.Size = legSize
        leg.Position = pos
        leg.Color = baseColor
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

    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = animal

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

            local animalObject = Animal.new(nil) -- Create the object first to get the genome
            local animalModel = AnimalService.createLandAnimal(spawnPosition, animalObject.genome)
            animalObject.model = animalModel
            animalObject.humanoid = animalModel:FindFirstChildOfClass("Humanoid")
            animalModel.Parent = workspace

            table.insert(activeAnimals, animalObject)

            -- Apply genetic traits
            animalModel:ScaleTo(1) -- Start as an infant
            animalObject.humanoid.WalkSpeed = animalObject.genome.speed

            print("Land animal spawned successfully at: " .. tostring(spawnPosition))
            return animalObject
        else
            local waterDepth = 0
            local waterPosition = Vector3.new(groundPosition.X, waterDepth, groundPosition.Z)
            local animalModel = AnimalService.createWaterAnimal(waterPosition)
            animalModel.Parent = workspace

            local animalObject = Animal.new(animalModel)
            table.insert(activeAnimals, animalObject)

            -- Apply genetic traits
            animalModel:ScaleTo(1) -- Start as an infant
            animalObject.humanoid.WalkSpeed = animalObject.genome.speed

            print("Water animal spawned successfully at: " .. tostring(waterPosition))
            return animalObject
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
        local NatureService = require(ServerScriptService.NatureService)
        local activePlants = NatureService.getActivePlants()

        for i = #activeAnimals, 1, -1 do
            local animal = activeAnimals[i]
            local status = animal:update(deltaTime, activeAnimals, activePlants, AnimalService.spawnAnimal)
            if status == "dead" then
                table.remove(activeAnimals, i)
            end
        end
    end)
end

return AnimalService

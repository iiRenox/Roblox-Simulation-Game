--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldUtil = require(ReplicatedStorage.WorldUtil)
local Animal = require(ServerScriptService.Animal)
local TimeService = require(ServerScriptService.TimeService)

--- Manages the lifecycle of all animals in the simulation.
-- This service handles the creation, spawning, and updating of all animal entities.
-- It maintains the list of active animals and connects their AI to the main game loop.
local AnimalService = {}

-- Holds all the active Animal objects.
local activeAnimals = {}

--- Returns the list of all active animals.
-- @return table A list containing all active Animal objects.
function AnimalService.getActiveAnimals()
    return activeAnimals
end

--- Procedurally generates a model for a land animal based on its genome.
-- The animal's appearance (size, color, body shape, appendages) is determined
-- by its genetic traits, creating significant visual diversity.
-- @param spawnPosition Vector3 The world position where the animal should be created.
-- @param genome table The animal's genome, used to define its physical characteristics.
-- @return Model The fully constructed and welded animal model.
function AnimalService.createLandAnimal(spawnPosition, genome)
	local animal = Instance.new("Model")
	animal.Name = "LandAnimal"

	-- Color is determined by diet and a random hue
	local dietHue = if genome.dietType > 0.5 then 0 else 0.3 -- Carnivores are reddish, Herbivores are greenish
	local baseColor = Color3.fromHSV(dietHue + math.random(-5, 5)/100, 0.7, 0.8)

	-- *** BODY SHAPE ***
	-- Torso size is based on energy storage and overall size
	local torsoWidth = (genome.energyStorage / 150) * genome.size
	local torsoHeight = (genome.size / 10) * genome.size
	local torsoLength = (genome.size / 8) * genome.size
	local torsoSize = Vector3.new(torsoWidth, torsoHeight, torsoLength)

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = torsoSize
	torso.Color = baseColor
	torso.Parent = animal

	-- *** HEAD SHAPE ***
	local headSize = Vector3.new(genome.size * 0.4, genome.size * 0.4, genome.size * 0.4)
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

	-- Carnivores get a snout, herbivores get a smaller mouth
	if genome.dietType > 0.5 then
		local snoutPart = Instance.new("Part")
		snoutPart.Name = "Snout"
		snoutPart.Size = Vector3.new(headSize.X * 0.6, headSize.Y * 0.6, headSize.Z * 1.2)
		snoutPart.Position = head.Position + Vector3.new(0, 0, -headSize.Z / 2)
		snoutPart.Color = baseColor
		snoutPart.Parent = animal
		local weldSnout = Instance.new("WeldConstraint")
		weldSnout.Part0 = head
		weldSnout.Part1 = snoutPart
		weldSnout.Parent = head
	end

	-- *** APPENDAGES ***
	-- Horns/Antlers for defense
	if genome.defense > 12 then
		local horn = Instance.new("Part")
		horn.Name = "Horn"
		horn.Shape = Enum.PartType.Ball
		horn.Size = Vector3.new(genome.defense * 0.2, genome.defense * 0.5, genome.defense * 0.2)
		horn.Position = head.Position + Vector3.new(0, head.Size.Y/2, 0)
		horn.Color = Color3.new(0.8, 0.8, 0.8)
		horn.Parent = animal
		local weldHorn = Instance.new("WeldConstraint")
		weldHorn.Part0 = head
		weldHorn.Part1 = horn
		weldHorn.Parent = head
	end

	-- *** LEGS ***
	-- Leg length is based on speed, thickness is based on size
	local legLength = (genome.speed / 20) * (genome.size * 0.4)
	local legThickness = genome.size * 0.15
	local legSize = Vector3.new(legThickness, legLength, legThickness)

	local legPositions = {
		Vector3.new(torsoSize.X / 2, -torsoSize.Y / 2, torsoSize.Z / 2),
		Vector3.new(-torsoSize.X / 2, -torsoSize.Y / 2, torsoSize.Z / 2),
		Vector3.new(torsoSize.X / 2, -torsoSize.Y / 2, -torsoSize.Z / 2),
		Vector3.new(-torsoSize.X / 2, -torsoSize.Y / 2, -torsoSize.Z / 2)
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

--- Creates a model for a water-based animal.
-- @param spawnPosition Vector3 The world position where the animal should be created.
-- @param genome table The animal's genome, used to define its physical characteristics.
-- @return Model The fully constructed and welded water animal model.
function AnimalService.createWaterAnimal(spawnPosition, genome)
    local animal = Instance.new("Model")
    animal.Name = "WaterAnimal"

    -- Body shape and color are influenced by genes
    local baseColor = Color3.fromHSV(0.6, 0.8, 0.6 + (genome.size / 30))
    local torsoSize = Vector3.new(genome.size * 0.4, genome.size * 0.6, genome.size)

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = torsoSize
    torso.Color = baseColor
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

--- Spawns a new animal in a valid location in the world.
-- The function randomly decides whether to spawn a land or water animal, then
-- searches for a suitable location. If successful, it creates the animal object
-- and its model, and adds it to the simulation.
-- @return table? The new Animal object, or nil if no valid spawn location was found.
function AnimalService.spawnAnimal()
    local animalType = math.random(1, 2)
    local maxAttempts = 50
    local attempts = 0
    local positionFound = false
    local groundPosition, material

    print("Attempting to spawn a ".. (animalType == 1 and "Land" or "Water") .." animal...")

    while not positionFound and attempts < maxAttempts do
        local x = math.random(-4096, 4096)
        local z = math.random(-4096, 4096)

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
        local animalObject
        if animalType == 1 then
            local spawnPosition = groundPosition + Vector3.new(0, 4, 0)

            -- Create a temporary genome to build the model
            local tempGenome = require(ReplicatedStorage.Genome).create(require(ServerScriptService.Animal).animalGenomeTemplate)
            local animalModel = AnimalService.createLandAnimal(spawnPosition, tempGenome)
            animalModel.Parent = workspace

            -- Now create the definitive Animal object with the model
            animalObject = Animal.new(animalModel)
            if not animalObject then return nil end -- Guard against constructor failure
            animalObject.genome = tempGenome -- Assign the genome we used

            print("Land animal spawned successfully at: " .. tostring(spawnPosition))
        else
            local waterDepth = 0
            local waterPosition = Vector3.new(groundPosition.X, waterDepth, groundPosition.Z)

             -- Create a temporary genome to build the model
            local tempGenome = require(ReplicatedStorage.Genome).create(require(ServerScriptService.Animal).animalGenomeTemplate)
            local animalModel = AnimalService.createWaterAnimal(waterPosition, tempGenome)
            animalModel.Parent = workspace

            -- Now create the definitive Animal object with the model
            animalObject = Animal.new(animalModel)
            if not animalObject then return nil end -- Guard against constructor failure
            animalObject.genome = tempGenome -- Assign the genome we used

            print("Water animal spawned successfully at: " .. tostring(waterPosition))
        end

        table.insert(activeAnimals, animalObject)

        -- Apply genetic traits
        animalObject.model:ScaleTo(1) -- Start as an infant
        animalObject.humanoid.WalkSpeed = animalObject.genome.speed

        return animalObject
    else
        print("Failed to find a valid location for animal after " .. maxAttempts .. " attempts.")
        return nil
    end
end

--- Initializes the AnimalService.
-- Spawns the initial population of animals and connects the service's update
-- loop to the global `TimeService` tick.
function AnimalService.start()
    print("AnimalService started")
    -- Spawn a small, balanced population to start
    for _ = 1, 10 do
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

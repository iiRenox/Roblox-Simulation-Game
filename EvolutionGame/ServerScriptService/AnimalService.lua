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

--- Creates a simple model for a land animal.
--- Creates a genetically customized model for a land animal.
-- @param genome table The genome defining the animal's traits.
-- @return Model The fully constructed and welded animal model.
function AnimalService.createLandAnimal(genome)
	local animal = Instance.new("Model")
	animal.Name = "LandAnimal"

	local torsoSize = genome.size
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(torsoSize * 0.8, torsoSize * 0.4, torsoSize * 1.2)
	torso.Color = if genome.dietType < 0.5 then Color3.fromRGB(139, 69, 19) else Color3.fromRGB(128, 128, 128) -- Brown for herbivores, grey for carnivores
	torso.Parent = animal

	local headSize = torsoSize * 0.4 * (genome.eyesight / 100) -- Eyesight affects head size
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(headSize, headSize, headSize)
	head.Position = Vector3.new(0, torsoSize * 0.2, -torsoSize * 0.7)
	head.Color = torso.Color
	head.Parent = animal
	local weldHead = Instance.new("WeldConstraint")
	weldHead.Part0 = torso
	weldHead.Part1 = head
	weldHead.Parent = torso

	-- Carnivores get a snout
	if genome.dietType >= 0.5 then
		local snout = Instance.new("Part")
		snout.Name = "Snout"
		snout.Size = Vector3.new(headSize * 0.5, headSize * 0.5, headSize * 1.5)
		snout.Position = Vector3.new(0, 0, -headSize)
		snout.Color = torso.Color
		snout.Parent = head
		local weldSnout = Instance.new("WeldConstraint")
		weldSnout.Part0 = head
		weldSnout.Part1 = snout
		weldSnout.Parent = head
	end

	-- Create and attach four legs
	local legLength = torsoSize * 0.5 * (genome.speed / 20) -- Speed affects leg length
	local legSize = Vector3.new(torsoSize * 0.2, legLength, torsoSize * 0.2)
	local positions = {
		Vector3.new(torsoSize * 0.3, -torsoSize * 0.2, torsoSize * 0.4), -- Front-right
		Vector3.new(-torsoSize * 0.3, -torsoSize * 0.2, torsoSize * 0.4), -- Front-left
		Vector3.new(torsoSize * 0.3, -torsoSize * 0.2, -torsoSize * 0.4), -- Back-right
		Vector3.new(-torsoSize * 0.3, -torsoSize * 0.2, -torsoSize * 0.4), -- Back-left
	}

	for i, pos in ipairs(positions) do
		local leg = Instance.new("Part")
		leg.Name = "Leg" .. i
		leg.Size = legSize
		leg.Position = pos
		leg.Color = torso.Color
		leg.Parent = animal
		local weldLeg = Instance.new("WeldConstraint")
		weldLeg.Part0 = torso
		weldLeg.Part1 = leg
		weldLeg.Parent = torso
	end

	local humanoid = Instance.new("Humanoid")
	humanoid.WalkSpeed = genome.speed
	humanoid.Parent = animal

	animal.PrimaryPart = torso

	return animal
end

--- Creates a simple model for a water-based animal.
-- @param spawnPosition Vector3 The world position where the animal should be created.
-- @return Model The fully constructed and welded water animal model.
function AnimalService.createWaterAnimal(spawnPosition)
    local animal = Instance.new("Model")
    animal.Name = "WaterAnimal"

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 8)
    torso.Color = Color3.fromRGB(0, 100, 150) -- Blueish
    torso.Parent = animal

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
-- @param genomeOverride table? An optional genome to assign to the new animal. If nil, a random one is created.
-- @return table? The new Animal object, or nil if no valid spawn location was found.
function AnimalService.spawnAnimal(genomeOverride)
    local animalType = math.random(1, 2)
    local maxAttempts = 500 -- Increased attempts to ensure spawning
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
        local animalObject = Animal.new() -- Create the data object first
        if genomeOverride then
            animalObject.genome = genomeOverride
        end
        local animalModel

        if animalType == 1 then
            animalModel = AnimalService.createLandAnimal(animalObject.genome)
            local spawnPosition = groundPosition + Vector3.new(0, animalObject.genome.size, 0)
            animalModel:SetPrimaryPartCFrame(CFrame.new(spawnPosition))
            print("Land animal spawned successfully at: " .. tostring(spawnPosition))
        else
            local waterPosition = groundPosition + Vector3.new(0, 2, 0)
            animalModel = AnimalService.createWaterAnimal(waterPosition) -- Water animal generation remains simple for now
            print("Water animal spawned successfully at: " .. tostring(waterPosition))
        end

        animalModel.Parent = workspace
        animalObject.model = animalModel
        animalObject.humanoid = animalModel:FindFirstChildOfClass("Humanoid")
        table.insert(activeAnimals, animalObject)

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
            if animal then
                local status = animal:update(deltaTime, activeAnimals, activePlants, AnimalService.spawnAnimal)
                if status == "dead" then
                    table.remove(activeAnimals, i)
                end
            else
                -- If the entry is somehow nil, remove it to prevent future errors
                table.remove(activeAnimals, i)
            end
        end
    end)
end

return AnimalService

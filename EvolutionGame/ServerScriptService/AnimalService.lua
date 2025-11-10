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
-- @param spawnPosition Vector3 The world position where the animal should be created.
-- @return Model The fully constructed and welded animal model.
function AnimalService.createLandAnimal(spawnPosition)
	local animal = Instance.new("Model")
	animal.Name = "LandAnimal"

	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(4, 2, 6)
	torso.Color = Color3.fromRGB(139, 69, 19) -- Brown
	torso.Parent = animal

	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(2, 2, 2)
	head.Position = Vector3.new(0, 1, -4)
	head.Color = Color3.fromRGB(139, 69, 19)
	head.Parent = animal
	local weldHead = Instance.new("WeldConstraint")
	weldHead.Part0 = torso
	weldHead.Part1 = head
	weldHead.Parent = torso

	local humanoid = Instance.new("Humanoid")
	humanoid.Parent = animal

	animal.PrimaryPart = torso
	animal:SetPrimaryPartCFrame(CFrame.new(spawnPosition))

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
-- @return table? The new Animal object, or nil if no valid spawn location was found.
function AnimalService.spawnAnimal()
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
        local animalModel
        if animalType == 1 then
            local spawnPosition = groundPosition + Vector3.new(0, 4, 0)
            animalModel = AnimalService.createLandAnimal(spawnPosition)
            print("Land animal spawned successfully at: " .. tostring(spawnPosition))
        else
            local waterPosition = groundPosition + Vector3.new(0, 2, 0)
            animalModel = AnimalService.createWaterAnimal(waterPosition)
            print("Water animal spawned successfully at: " .. tostring(waterPosition))
        end

        animalModel.Parent = workspace
        local animalObject = Animal.new(animalModel)
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
            local status = animal:update(deltaTime, activeAnimals, activePlants, AnimalService.spawnAnimal)
            if status == "dead" then
                table.remove(activeAnimals, i)
            end
        end
    end)
end

return AnimalService

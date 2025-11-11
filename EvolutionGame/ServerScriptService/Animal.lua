--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Genome = require(ReplicatedStorage.Genome)
local Pathfinding = require(ServerScriptService.Pathfinding)

--- Manages the state, needs, and behavior of a single animal.
-- This class represents an individual animal in the simulation, handling its AI,
-- physical growth, needs (like hunger), and interactions with the world and
-- other entities.
local Animal = {}
Animal.__index = Animal

-- Defines the genetic structure for all animals.
local animalGenomeTemplate = {
    -- Physical Attributes
    size = { type = "number", defaultValue = 5, min = 2, max = 15 },
    speed = { type = "number", defaultValue = 20, min = 10, max = 40 },
    -- Senses
    eyesight = { type = "number", defaultValue = 100, min = 50, max = 200 },
    smell = { type = "number", defaultValue = 150, min = 75, max = 250 },
    -- Behavioral Genes
    dietType = { type = "number", defaultValue = 0.1, min = 0, max = 1 }, -- 0=Herbivore, 1=Carnivore
    sociality = { type = "string", defaultValue = "Solitary", possibleValues = {"Solitary", "Herd"} },
    intelligence = { type = "number", defaultValue = 1, min = 1, max = 10 },
}

--- Creates a new Animal instance.
--- Creates a new Animal instance without a model.
-- The model must be assigned separately after creation.
-- @return table The new Animal object.
function Animal.new()
    local self = setmetatable({}, Animal)

    self.type = "Animal"
    self.model = nil
    self.humanoid = nil
    self.genome = Genome.create(animalGenomeTemplate)
    self.age = 0
    self.hunger = 0
    self.state = "Idle" -- Idle, Foraging, Hunting, Breeding
    self.isMoving = false

    return self
end

--- Moves the animal to a specified destination using the Pathfinding service.
-- @param destination Vector3 The target position to move to.
function Animal:moveTo(destination)
    if self.isMoving then return end
    self.isMoving = true

    local path = Pathfinding.computePath(self.model.PrimaryPart.Position, destination)
    Pathfinding.followPath(self.humanoid, path)

    self.isMoving = false
end

--- Gradually increases the animal's size towards its genetically determined size.
-- @param deltaTime number The time elapsed since the last frame.
function Animal:grow(deltaTime)
    if self.model:GetScale() < self.genome.size then
        local newScale = self.model:GetScale() + (self.genome.size / 20) * deltaTime -- Grow to full size in 20 seconds
        self.model:ScaleTo(newScale)
    end
end

--- Finds the nearest food source based on the animal's diet.
-- Herbivores search for plants, while carnivores search for other animals.
-- The search radius is determined by the animal's eyesight gene.
-- @param activeAnimals table A list of all active animals in the simulation.
-- @param activePlants table A list of all active plants in the simulation.
-- @return table? The nearest food entity, or nil if none is found.
function Animal:findFood(activeAnimals, activePlants)
    -- NOTE: This is not a scalable solution. A spatial partitioning system (like a quadtree)
    -- would be needed to efficiently query for nearby entities in a large-scale simulation.
    local nearestFood = nil
    local minDistance = math.huge
    local searchRadius = self.genome.eyesight -- Use eyesight for now

    if not self.model or not self.model.PrimaryPart then
        return nil
    end

    if self.genome.dietType < 0.5 then -- Herbivore
        for _, plant in ipairs(activePlants) do
            if plant and plant.model and plant.model.PrimaryPart then
                local distance = (self.model.PrimaryPart.Position - plant.model.PrimaryPart.Position).Magnitude
                if distance < minDistance and distance < searchRadius then
                    minDistance = distance
                    nearestFood = plant
                end
            end
        end
    else -- Carnivore
        for _, otherAnimal in ipairs(activeAnimals) do
            if otherAnimal and otherAnimal.model and otherAnimal.model.PrimaryPart and otherAnimal ~= self and otherAnimal.genome.dietType < 0.5 then -- Hunt herbivores
                local distance = (self.model.PrimaryPart.Position - otherAnimal.model.PrimaryPart.Position).Magnitude
                if distance < minDistance and distance < searchRadius then
                    minDistance = distance
                    nearestFood = otherAnimal
                end
            end
        end
    end

    return nearestFood
end

--- Consumes a food source to reduce hunger.
-- The amount of hunger restored depends on the type of food.
-- @param food table The plant or animal object to be eaten.
function Animal:eat(food)
    if not food or not food.model or not food.model.PrimaryPart then return end

    print("An animal is eating a " .. food.model.Name)
    if food.type == "Animal" then
        self.hunger = self.hunger - food.genome.size -- Simple nutrition for now
    else -- It's a plant
        self.hunger = self.hunger - food.genome.nutritionalValue
    end
    self.state = "Idle"
    food:die() -- The food is consumed
end

--- Handles the death of the animal.
-- Destroys the animal's model and marks it for cleanup.
-- @return string Returns "dead" to signal removal from the active list.
function Animal:die()
    if self.model then
        self.model:Destroy()
        self.model = nil
    end
    return "dead"
end

--- Finds a suitable mate for breeding.
-- The search is based on the animal's smell radius and looks for other animals
-- also in the "Breeding" state.
-- @param activeAnimals table A list of all active animals in the simulation.
-- @return table? The nearest suitable mate, or nil if none is found.
function Animal:findMate(activeAnimals)
    -- NOTE: This is not a scalable solution. A spatial partitioning system (like a quadtree)
    -- would be needed to efficiently query for nearby entities in a large-scale simulation.
    local nearestMate = nil
    local minDistance = math.huge
    local searchRadius = self.genome.smell -- Use smell for finding mates

    -- Find another animal of the same species (for now, any land animal)
    for _, otherAnimal in ipairs(activeAnimals) do
        if otherAnimal and otherAnimal.model and otherAnimal.model.PrimaryPart and self.model and self.model.PrimaryPart and otherAnimal ~= self and otherAnimal.state == "Breeding" then
            local distance = (self.model.PrimaryPart.Position - otherAnimal.model.PrimaryPart.Position).Magnitude
            if distance < minDistance and distance < searchRadius then
                minDistance = distance
                nearestMate = otherAnimal
            end
        end
    end

    return nearestMate
end

--- Initiates the breeding process with a mate.
-- Creates a new offspring by combining and mutating the parents' genomes.
-- The new genome is then passed to the spawn function.
-- @param mate table The other animal to breed with.
-- @param spawnAnimal function A function passed from the AnimalService to spawn a new animal.
function Animal:breedWith(mate, spawnAnimal)
    print("Two animals are breeding!")

    -- 1. Create the offspring's genome first
    local combinedGenome = Genome.combine(self.genome, mate.genome, animalGenomeTemplate)
    local newGenome = Genome.mutate(combinedGenome, animalGenomeTemplate, 0.1)

    -- 2. Pass the created genome to the spawn function
    local newAnimal = spawnAnimal(newGenome)

    if newAnimal then
        print("A new animal has been born with inherited traits!")
    end

    self.state = "Idle"
    mate.state = "Idle"
end

--- The main update loop for the animal's AI and life cycle.
-- This function is called on every simulation tick. It manages hunger, growth,
-- and the state machine that drives the animal's behavior.
-- @param deltaTime number The time since the last update.
-- @param activeAnimals table A list of all active animals.
-- @param activePlants table A list of all active plants.
-- @param spawnAnimal function A function to call to spawn a new animal (for breeding).
-- @return string? "dead" if the animal has died during the update, otherwise nil.
function Animal:update(deltaTime, activeAnimals, activePlants, spawnAnimal)
    self.age = self.age + deltaTime
    self.hunger = self.hunger + deltaTime * 0.1

    if self.hunger > 100 then
        print("An animal has starved to death.")
        return self:die()
    end

    self:grow(deltaTime)

    -- State machine logic
    if self.hunger > 70 then
        self.state = "Foraging"
    elseif self.hunger < 10 and self.age > 20 then
        self.state = "Breeding"
    else
        self.state = "Idle"
    end

    if self.state == "Foraging" then
        local food = self:findFood(activeAnimals, activePlants)
        if food and food.model and food.model.PrimaryPart then
            self:moveTo(food.model.PrimaryPart.Position)
            -- Re-verify the target exists before acting on it
            if food and food.model and food.model.PrimaryPart and (self.model.PrimaryPart.Position - food.model.PrimaryPart.Position).Magnitude < 10 then
                self:eat(food)
            end
        else
            -- Wander to search for food
            if math.random() < 0.1 then
                local randomDirection = Vector3.new(math.random(-200, 200), 0, math.random(-200, 200))
                self:moveTo(self.model.PrimaryPart.Position + randomDirection)
            end
        end
    elseif self.state == "Breeding" then
        local mate = self:findMate(activeAnimals)
        if mate and mate.model and mate.model.PrimaryPart then
            self:moveTo(mate.model.PrimaryPart.Position)
            if mate and mate.model and mate.model.PrimaryPart and (self.model.PrimaryPart.Position - mate.model.PrimaryPart.Position).Magnitude < 10 then
                self:breedWith(mate, spawnAnimal)
            end
        else
            -- If no mate is available, just wander
            if math.random() < 0.1 then
                self:moveTo(self.model.PrimaryPart.Position + Vector3.new(math.random(-100, 100), 0, math.random(-100, 100)))
            end
        end
    elseif self.state == "Idle" then
        if self.genome.sociality == "Herd" then
            local ally = self:findNearestAlly(activeAnimals)
            if ally and ally.model and ally.model.PrimaryPart then
                -- Move towards the ally to form a herd
                self:moveTo(ally.model.PrimaryPart.Position)
            else
                -- Wander if no allies are nearby
                if math.random() < 0.1 then
                    self:moveTo(self.model.PrimaryPart.Position + Vector3.new(math.random(-100, 100), 0, math.random(-100, 100)))
                end
            end
        else -- Solitary
            if math.random() < 0.1 then
                self:moveTo(self.model.PrimaryPart.Position + Vector3.new(math.random(-100, 100), 0, math.random(-100, 100)))
            end
        end
    end
end

--- Finds the nearest allied animal for herd behavior.
-- An ally is defined as another animal with the "Herd" sociality gene.
-- @param activeAnimals table A list of all active animals.
-- @return table? The nearest herd ally, or nil if none is found.
function Animal:findNearestAlly(activeAnimals)
    local nearestAlly = nil
    local minDistance = math.huge
    local searchRadius = self.genome.eyesight

    if not self.model or not self.model.PrimaryPart then return nil end

    for _, otherAnimal in ipairs(activeAnimals) do
        if otherAnimal and otherAnimal.model and otherAnimal.model.PrimaryPart and otherAnimal ~= self and otherAnimal.genome.sociality == "Herd" then
            local distance = (self.model.PrimaryPart.Position - otherAnimal.model.PrimaryPart.Position).Magnitude
            if distance < minDistance and distance < searchRadius then
                minDistance = distance
                nearestAlly = otherAnimal
            end
        end
    end

    return nearestAlly
end

return Animal

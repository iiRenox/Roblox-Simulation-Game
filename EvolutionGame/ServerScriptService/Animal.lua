--!strict
-- Animal Class
-- Manages the state, needs, and behavior of a single animal.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerScriptService = game:GetService("ServerScriptService")
local Genome = require(ReplicatedStorage.Genome)
local Pathfinding = require(ServerScriptService.Pathfinding)

local Animal = {}
Animal.__index = Animal

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

function Animal.new(model)
    local self = setmetatable({}, Animal)

    self.model = model
    self.humanoid = model:FindFirstChildOfClass("Humanoid")
    self.genome = Genome.create(animalGenomeTemplate)
    self.age = 0
    self.hunger = 0
    self.state = "Idle" -- Idle, Foraging, Hunting, Breeding
    self.isMoving = false

    return self
end

function Animal:moveTo(destination)
    if self.isMoving then return end
    self.isMoving = true

    local path = Pathfinding.computePath(self.model.PrimaryPart.Position, destination)
    Pathfinding.followPath(self.humanoid, path)

    self.isMoving = false
end

function Animal:grow(deltaTime)
    if self.model:GetScale() < self.genome.size then
        local newScale = self.model:GetScale() + (self.genome.size / 20) * deltaTime -- Grow to full size in 20 seconds
        self.model:ScaleTo(newScale)
    end
end

function Animal:findFood(activeAnimals, activePlants)
    -- NOTE: This is not a scalable solution. A spatial partitioning system (like a quadtree)
    -- would be needed to efficiently query for nearby entities in a large-scale simulation.
    local nearestFood = nil
    local minDistance = math.huge
    local searchRadius = self.genome.eyesight -- Use eyesight for now

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
            if otherAnimal and otherAnimal.model and otherAnimal ~= self and otherAnimal.genome.dietType < 0.5 then -- Hunt herbivores
                local distance = (self.model.PrimaryPart.Position - otherAnimal.model.PrimaryPart.Position).Magnitude
                if distance < minDistance and distance < searchRadius then
                    minDistance = distance
                    nearestFood = otherAnimal.model
                end
            end
        end
    end

    return nearestFood
end

function Animal:eat(food)
    if not food or not food.model or not food.model.PrimaryPart then return end

    print("An animal is eating a " .. food.model.Name)
    self.hunger = self.hunger - food.genome.nutritionalValue
    self.state = "Idle"
    food.model:Destroy() -- The plant is consumed
end

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

function Animal:breedWith(mate, spawnAnimal)
    print("Two animals are breeding!")

    local newAnimal = spawnAnimal()

    if newAnimal then
        local combinedGenome = Genome.combine(self.genome, mate.genome, animalGenomeTemplate)
        newAnimal.genome = Genome.mutate(combinedGenome, animalGenomeTemplate, 0.1)
        print("A new animal has been born!")
    end

    self.state = "Idle"
    mate.state = "Idle"
end

function Animal:update(deltaTime, activeAnimals, activePlants, spawnAnimal)
    self.age = self.age + deltaTime
    self.hunger = self.hunger + deltaTime * 0.1

    if self.hunger > 100 then
        print("An animal has starved to death.")
        self.model:Destroy()
        return "dead"
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
        if food then
            self:moveTo(food.model.PrimaryPart.Position)
            if (self.model.PrimaryPart.Position - food.model.PrimaryPart.Position).Magnitude < 10 then
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
        if mate then
            self:moveTo(mate.model.PrimaryPart.Position)
            if (self.model.PrimaryPart.Position - mate.model.PrimaryPart.Position).Magnitude < 10 then
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
            if ally then
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

function Animal:findNearestAlly(activeAnimals)
    local nearestAlly = nil
    local minDistance = math.huge
    local searchRadius = self.genome.eyesight

    for _, otherAnimal in ipairs(activeAnimals) do
        if otherAnimal and otherAnimal.model and otherAnimal ~= self and otherAnimal.genome.sociality == "Herd" then
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

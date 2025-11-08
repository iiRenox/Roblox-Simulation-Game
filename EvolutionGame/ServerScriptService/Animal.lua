--!strict
-- Animal Class
-- Manages the state, needs, and behavior of a single animal.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Genome = require(ReplicatedStorage.Genome)

local Animal = {}
Animal.__index = Animal

local animalGenomeTemplate = {
    speed = 20,
    size = 5,
    strength = 10,
    dietType = "Herbivore", -- Herbivore, Carnivore
}

function Animal.new(model)
    local self = setmetatable({}, Animal)

    self.model = model
    self.humanoid = model:FindFirstChildOfClass("Humanoid")
    self.genome = Genome.create(animalGenomeTemplate)
    self.age = 0
    self.hunger = 0
    self.state = "Idle" -- Idle, Foraging, Hunting, Breeding

    return self
end

function Animal:findFood()
    -- NOTE: This is not a scalable solution. A spatial partitioning system (like a quadtree)
    -- would be needed to efficiently query for nearby entities in a large-scale simulation.
    local nearestFood = nil
    local minDistance = math.huge

    -- For now, herbivores will look for bushes
    if self.genome.dietType == "Herbivore" then
        local natureFolder = workspace:FindFirstChild("Nature")
        if natureFolder then
            for _, child in ipairs(natureFolder:GetChildren()) do
                if child.Name == "Bush" then
                    local distance = (self.model.PrimaryPart.Position - child.PrimaryPart.Position).Magnitude
                    if distance < minDistance then
                        minDistance = distance
                        nearestFood = child
                    end
                end
            end
        end
    end

    return nearestFood
end

function Animal:eat(food)
    if not food or not food.PrimaryPart then return end

    print("An animal is eating a bush.")
    self.hunger = 0
    self.state = "Idle"
    food:Destroy() -- The bush is consumed
end

function Animal:findMate(activeAnimals)
    -- NOTE: This is not a scalable solution. A spatial partitioning system (like a quadtree)
    -- would be needed to efficiently query for nearby entities in a large-scale simulation.
    local nearestMate = nil
    local minDistance = math.huge

    -- Find another animal of the same species (for now, any land animal)
    for _, otherAnimal in ipairs(activeAnimals) do
        if otherAnimal ~= self and otherAnimal.state == "Breeding" then
            local distance = (self.model.PrimaryPart.Position - otherAnimal.model.PrimaryPart.Position).Magnitude
            if distance < minDistance then
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
        newAnimal.genome = Genome.mutate(Genome.combine(self.genome, mate.genome), 0.1, 0.2)
        print("A new animal has been born!")
    end

    self.state = "Idle"
    mate.state = "Idle"
end

function Animal:update(deltaTime, activeAnimals, spawnAnimal)
    self.age = self.age + deltaTime
    self.hunger = self.hunger + deltaTime * 0.1

    -- State machine logic
    if self.hunger > 70 then
        self.state = "Foraging"
    elseif self.hunger < 10 and self.age > 20 then
        self.state = "Breeding"
    else
        self.state = "Idle"
    end

    if self.state == "Foraging" then
        local food = self:findFood()
        if food then
            self.humanoid:MoveTo(food.PrimaryPart.Position)
            if (self.model.PrimaryPart.Position - food.PrimaryPart.Position).Magnitude < 10 then
                self:eat(food)
            end
        end
    elseif self.state == "Breeding" then
        local mate = self:findMate(activeAnimals)
        if mate then
            self.humanoid:MoveTo(mate.model.PrimaryPart.Position)
            if (self.model.PrimaryPart.Position - mate.model.PrimaryPart.Position).Magnitude < 10 then
                self:breedWith(mate, spawnAnimal)
            end
        else
            -- If no mate is available, just wander
            if self.humanoid and math.random() < 0.1 then
                self.humanoid:MoveTo(self.model.PrimaryPart.Position + Vector3.new(math.random(-100, 100), 0, math.random(-100, 100)))
            end
        end
    elseif self.state == "Idle" then
        if self.humanoid and math.random() < 0.1 then
            self.humanoid:MoveTo(self.model.PrimaryPart.Position + Vector3.new(math.random(-100, 100), 0, math.random(-100, 100)))
        end
    end
end

return Animal

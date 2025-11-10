--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Genome = require(ReplicatedStorage.Genome)

--- Manages the state and behavior of a single generic plant (e.g., bush, flower).
-- This class handles the lifecycle of a plant, including its growth, reproduction,
-- and death, all governed by its unique genetic makeup.
local Plant = {}
Plant.__index = Plant

-- The genetic blueprint for all simple plants
local plantGenomeTemplate = {
	-- Core Genetic Traits
	mutationChance = { type = "number", defaultValue = 0.02, min = 0.0, max = 0.1 },
	inheritanceAllele = { type = "allele", defaultValue = "average" },
	-- Size & Structure
	maxSize = { type = "number", defaultValue = 5, min = 2, max = 10 },
	-- Energy & Resources
	nutritionalValue = { type = "number", defaultValue = 10, min = 5, max = 20 },
	-- Lifespan & Growth
	growthRate = { type = "number", defaultValue = 0.5, min = 0.1, max = 2 },
	lifespan = { type = "number", defaultValue = 50, min = 20, max = 100 },
	-- Reproduction
	seedSpread = { type = "number", defaultValue = 10, min = 5, max = 20 },
	reproductiveRate = { type = "number", defaultValue = 10, min = 5, max = 20 },
	-- Defense
	toxicity = { type = "number", defaultValue = 0, min = 0, max = 1 },
	thorniness = { type = "number", defaultValue = 0, min = 0, max = 1 },
}

--- Creates a new Plant instance.
-- @param model Model The visual representation of the plant in the workspace.
-- @return table The new Plant object.
function Plant.new(model)
    local self = setmetatable({}, Plant)

    self.model = model
    self.genome = Genome.create(plantGenomeTemplate)
    self.age = 0
    self.lastReproduction = 0

    self.model:ScaleTo(1)

    return self
end

--- Handles the death of the plant.
-- Destroys the plant's model and marks it for cleanup.
-- @return string Returns "dead" to signal removal from the active list.
function Plant:die()
    if self.model then
        self.model:Destroy()
        self.model = nil
    end
    return "dead"
end

--- The main update loop for the plant's life cycle.
-- This function is called on every simulation tick. It handles aging and growth.
-- @param deltaTime number The time since the last update.
-- @return string? "dead" if the plant has died of old age, otherwise nil.
function Plant:grow(deltaTime)
    self.age = self.age + deltaTime

    if self.age > self.genome.lifespan then
        return self:die()
    end

    if self.model and self.model:GetScale() < self.genome.maxSize then
        local newScale = self.model:GetScale() + self.genome.growthRate * deltaTime
        self.model:ScaleTo(newScale)
    end
end

--- Handles the reproduction of the plant.
-- It drops a "seed" in a random nearby location. After a delay, if the location
-- is suitable, a new plant with a mutated genome will spawn.
function Plant:reproduce()
    if (os.clock() - self.lastReproduction) < self.genome.reproductiveRate then
        return
    end
    self.lastReproduction = os.clock()

    -- These are required late to avoid circular dependencies
    local NatureService = require(game.ServerScriptService.NatureService)
    local WorldUtil = require(game.ReplicatedStorage.WorldUtil)

    local seedDropPosition = self.model.PrimaryPart.Position + Vector3.new(
        math.random(-self.genome.seedSpread, self.genome.seedSpread),
        0,
        math.random(-self.genome.seedSpread, self.genome.seedSpread)
    )

    local groundPosition = WorldUtil.getGroundPosition(seedDropPosition.X, seedDropPosition.Z)

    if groundPosition then
        delay(math.random(2, 8), function()
            local material = WorldUtil.getMaterialAtPosition(groundPosition)
            if material == Enum.Material.Grass or material == Enum.Material.Water then
                -- The NatureService's generic createPlant function handles different plant types
                local newPlantObject = NatureService.createPlant(groundPosition, self.model.Name)
                if newPlantObject then
                    newPlantObject.genome = Genome.mutate(self.genome, plantGenomeTemplate, 0.1)
                end
            end
        end)
    end
end

return Plant

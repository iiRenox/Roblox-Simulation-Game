--!strict
-- Plant Class
-- Manages the state and behavior of a single plant, driven by its genome.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Genome = require(ReplicatedStorage.Genome)

local Plant = {}
Plant.__index = Plant

-- The genetic blueprint for all simple plants
local plantGenomeTemplate = {
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
}

function Plant.new(model)
    local self = setmetatable({}, Plant)

    self.model = model
    self.genome = Genome.create(plantGenomeTemplate)
    self.age = 0
    self.lastReproduction = 0

    self.model:ScaleTo(1)

    return self
end

function Plant:die()
    if self.model then
        self.model:Destroy()
        self.model = nil
    end
    return "dead"
end

function Plant:grow(deltaTime)
    self.age = self.age + deltaTime

    if self.age > self.genome.lifespan then
        return self:die()
    end

    if self.model:GetScale() < self.genome.maxSize then
        local newScale = self.model:GetScale() + self.genome.growthRate * deltaTime
        self.model:ScaleTo(newScale)
    end
end

function Plant:reproduce()
    if (os.clock() - self.lastReproduction) < self.genome.reproductiveRate then
        return
    end
    self.lastReproduction = os.clock()

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
            if material == Enum.Material.Grass then
                -- The NatureService will need a generic createPlant function
                local newPlantObject = NatureService.createPlant(groundPosition, self.model.Name)
                if newPlantObject then
                    newPlantObject.genome = Genome.mutate(self.genome, plantGenomeTemplate, 0.1)
                end
            end
        end)
    end
end

return Plant

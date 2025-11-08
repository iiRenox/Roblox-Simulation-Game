--!strict
-- Tree Class
-- Manages the state and behavior of a single tree, driven by its genome.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Genome = require(ReplicatedStorage.Genome)

local Tree = {}
Tree.__index = Tree

-- The genetic blueprint for all trees, based on "Pillar 1"
local treeGenomeTemplate = {
    -- Size & Structure
    maxHeight = { type = "number", defaultValue = 40, min = 10, max = 80 },
    canopyWidth = { type = "number", defaultValue = 20, min = 5, max = 40 },
    trunkThickness = { type = "number", defaultValue = 4, min = 2, max = 10 },
    rootDepth = { type = "number", defaultValue = 10, min = 5, max = 20 },
    -- Energy & Resources
    sunlightRequirement = { type = "number", defaultValue = 0.5, min = 0.1, max = 1 },
    waterConsumption = { type = "number", defaultValue = 0.5, min = 0.1, max = 1 },
    -- Lifespan & Growth
    growthRate = { type = "number", defaultValue = 1, min = 0.2, max = 3 },
    lifespan = { type = "number", defaultValue = 100, min = 50, max = 200 },
    -- Reproduction
    seedType = { type = "string", defaultValue = "Wind", possibleValues = {"Wind", "Fruit", "Nut", "Toxic"} },
    reproductiveRate = { type = "number", defaultValue = 5, min = 1, max = 10 },
    seedViability = { type = "number", defaultValue = 0.2, min = 0.05, max = 0.5 },
    -- Defense
    thorns = { type = "number", defaultValue = 0, min = 0, max = 1 }, -- 0 = no, 1 = yes (as a continuous trait)
    barkThickness = { type = "number", defaultValue = 1, min = 0.5, max = 3 },
    toxicity = { type = "number", defaultValue = 0, min = 0, max = 1 },
}

function Tree.new(model)
    local self = setmetatable({}, Tree)

    self.model = model
    self.genome = Genome.create(treeGenomeTemplate)
    self.age = 0
    self.growthState = "Sapling" -- Sapling, Mature
    self.lastReproduction = 0

    -- Start as a small sapling
    self.model:ScaleTo(2)

    return self
end

function Tree:grow(deltaTime)
    self.age = self.age + deltaTime

    if self.age > self.genome.lifespan then
        self.model:Destroy()
        -- In the future, this would leave behind a dead tree model
        return
    end

    if self.growthState == "Sapling" then
        local currentHeight = self.model.PrimaryPart.Size.Y
        if currentHeight < self.genome.maxHeight then
            -- The growth logic will be more complex in the future,
            -- but for now, we'll keep it simple.
            local newScale = currentHeight + self.genome.growthRate * deltaTime
            self.model:ScaleTo(newScale)
        else
            self.growthState = "Mature"
            print("A tree has matured!")
        end
    end
end

function Tree:reproduce()
    if self.growthState ~= "Mature" or (os.clock() - self.lastReproduction) < (self.genome.reproductiveRate * 10) then
        return
    end
    self.lastReproduction = os.clock()

    print("A tree is reproducing with seed type:", self.genome.seedType)

    local NatureService = require(game.ServerScriptService.NatureService)
    local WorldUtil = require(game.ReplicatedStorage.WorldUtil)

    -- In a real implementation, the seed type would have a huge impact.
    -- For now, we'll just drop a generic seed.
    local seedDropPosition = self.model.PrimaryPart.Position + Vector3.new(
        math.random(-self.genome.canopyWidth, self.genome.canopyWidth),
        0,
        math.random(-self.genome.canopyWidth, self.genome.canopyWidth)
    )

    local groundPosition = WorldUtil.getGroundPosition(seedDropPosition.X, seedDropPosition.Z)

    if groundPosition and math.random() < self.genome.seedViability then
        delay(math.random(2, 8), function()
            local material = WorldUtil.getMaterialAtPosition(groundPosition)
            if material == Enum.Material.Grass then
                local newTreeObject = NatureService.createTree(groundPosition)
                if newTreeObject then
                    newTreeObject.genome = Genome.mutate(self.genome, treeGenomeTemplate, 0.1)
                    print("A new tree has sprouted from a seed!")
                end
            end
        end)
    end
end

return Tree

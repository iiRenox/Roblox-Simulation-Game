--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Genome = require(ReplicatedStorage.Genome)

--- Manages the state and behavior of a single tree, driven by its genome.
-- This class represents an individual tree in the simulation, handling its entire
-- lifecycle from a sapling to a mature, reproducing tree. Its growth, appearance,
-- and reproductive strategies are all determined by its genetic data.
local Tree = {}
Tree.__index = Tree

-- The genetic blueprint for all trees
local treeGenomeTemplate = {
    -- Size & Structure
    maxHeight = { type = "number", defaultValue = 15, min = 10, max = 80 },
    canopyWidth = { type = "number", defaultValue = 10, min = 5, max = 40 },
    trunkThickness = { type = "number", defaultValue = 2, min = 2, max = 10 },
    rootDepth = { type = "number", defaultValue = 10, min = 5, max = 20 },
    -- Energy & Resources
    sunlightRequirement = { type = "number", defaultValue = 0.5, min = 0.1, max = 1 },
    waterConsumption = { type = "number", defaultValue = 0.5, min = 0.1, max = 1 },
    -- Lifespan & Growth
    growthRate = { type = "number", defaultValue = 0.5, min = 0.2, max = 3 },
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

--- Creates a new Tree instance.
-- @param model Model The visual representation of the tree in the workspace.
-- @return table The new Tree object.
function Tree.new(model)
    local self = setmetatable({}, Tree)

    self.model = model
    self.genome = Genome.create(treeGenomeTemplate)
    self.age = 0
    self.growthState = "Sapling" -- Sapling, Mature
    self.lastReproduction = 0

    -- Start as a small sapling
    self.model:ScaleTo(1)
    self.currentScale = 1

    return self
end

--- Scales the tree model from its base, ensuring it grows upwards.
-- This custom scaling function resizes and repositions each part relative to the
-- model's pivot point at the base, preventing the tree from scaling into the ground.
-- @param scale number The factor by which to scale the tree.
function Tree:scaleUpwards(scale)
    local originalPivot = self.model:GetPivot()
    local basePosition = originalPivot.Position

    for _, part in ipairs(self.model:GetDescendants()) do
        if part:IsA("BasePart") then
            -- Calculate the part's offset from the model's pivot
            local offset = part.Position - basePosition

            -- Scale the part's size and its offset from the base
            part.Size = part.Size * scale
            part.Position = basePosition + (offset * scale)
        end
    end
end

--- The main update loop for the tree's life cycle.
-- This function is called on every simulation tick. It handles aging and the
-- transition from a sapling to a mature tree.
-- @param deltaTime number The time since the last update.
-- @return string? "dead" if the tree has died of old age, otherwise nil.
function Tree:grow(deltaTime)
    self.age = self.age + deltaTime

    if self.age > self.genome.lifespan then
        self.model:Destroy()
        -- In the future, this would leave behind a dead tree model
        return "dead"
    end

    if self.growthState == "Sapling" then
        if self.currentScale < self.genome.maxHeight then
            local growthAmount = self.genome.growthRate * deltaTime
            local newScale = 1 + growthAmount / self.currentScale
            self:scaleUpwards(newScale)
            self.currentScale = self.currentScale + growthAmount
        else
            self.growthState = "Mature"
            print("A tree has matured!")
        end
    end
end

--- Handles the reproduction of the tree.
-- Once mature, a tree will periodically drop seeds in a radius determined by its
-- canopy width. If a seed lands in a viable location, a new tree will sprout.
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

--!strict
-- Tree Class
-- Manages the state and behavior of a single tree.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Genome = require(ReplicatedStorage.Genome)

local Tree = {}
Tree.__index = Tree

local treeGenomeTemplate = {
    maxHeight = 30,
    growthRate = 1,
    seedSpreadRadius = 50,
}

function Tree.new(model)
    local self = setmetatable({}, Tree)

    self.model = model
    self.genome = Genome.create(treeGenomeTemplate)
    self.age = 0
    self.growthState = "Sapling" -- Sapling, Mature, Reproducing

    return self
end

function Tree:grow(deltaTime)
    self.age = self.age + deltaTime

    if self.growthState == "Sapling" then
        -- Simple linear growth for now
        local currentHeight = self.model.PrimaryPart.Size.Y
        if currentHeight < self.genome.maxHeight then
            local newScale = currentHeight + self.genome.growthRate * deltaTime
            self.model:ScaleTo(newScale)
        else
            self.growthState = "Mature"
            print("A tree has matured!")
        end
    end
end

function Tree:reproduce()
    if self.growthState ~= "Mature" or math.random() > 0.1 then return end

    print("A tree is reproducing...")

    local NatureService = require(game.ServerScriptService.NatureService)
    local WorldUtil = require(game.ReplicatedStorage.WorldUtil)

    local seedDropPosition = self.model.PrimaryPart.Position + Vector3.new(
        math.random(-self.genome.seedSpreadRadius, self.genome.seedSpreadRadius),
        0,
        math.random(-self.genome.seedSpreadRadius, self.genome.seedSpreadRadius)
    )

    local groundPosition = WorldUtil.getGroundPosition(seedDropPosition.X, seedDropPosition.Z)

    if groundPosition then
        local seed = Instance.new("Part")
        seed.Name = "Seed"
        seed.Shape = Enum.PartType.Ball
        seed.Size = Vector3.new(0.5, 0.5, 0.5)
        seed.Position = groundPosition + Vector3.new(0, 1, 0)
        seed.Color = Color3.fromRGB(139, 69, 19)
        seed.Anchored = true
        seed.Parent = workspace -- temp parent

        -- After a delay, the seed will sprout
        delay(math.random(5, 15), function()
            local material = WorldUtil.getMaterialAtPosition(seed.Position)
            if material == Enum.Material.Grass then
                local newTree = NatureService.createTree(seed.Position)
                newTree.genome = Genome.mutate(self.genome, 0.1, 0.2)
                print("A new tree has sprouted from a seed!")
            end
            seed:Destroy()
        end)
    end
end

return Tree

--!strict
-- NPC Class
-- Manages the state, needs, and behavior of a single NPC.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Genome = require(ReplicatedStorage.Genome)

local NPC = {}
NPC.__index = NPC

local npcGenomeTemplate = {
    intelligence = 1,
    strength = 5,
}

function NPC.new(model)
    local self = setmetatable({}, NPC)

    self.model = model
    self.humanoid = model:FindFirstChildOfClass("Humanoid")
    self.genome = Genome.create(npcGenomeTemplate)
    self.age = 0
    self.state = "Wandering" -- Wandering, Gathering, Building, Breeding

    return self
end

function NPC:findNearestTree()
    local nearestTree = nil
    local minDistance = math.huge

    local natureFolder = workspace:FindFirstChild("Nature")
    if natureFolder then
        for _, child in ipairs(natureFolder:GetChildren()) do
            if child.Name == "Tree" then
                local distance = (self.model.PrimaryPart.Position - child.PrimaryPart.Position).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    nearestTree = child
                end
            end
        end
    end

    return nearestTree
end

function NPC:chopTree(tree)
    if not tree or not tree.PrimaryPart then return end

    print("An NPC is chopping down a tree.")
    tree:Destroy()
    -- In a full implementation, the NPC would gain a "wood" resource.
end

function NPC:buildHouse()
    print("An NPC is building a house.")

    local house = Instance.new("Model")
    house.Name = "House"

    local floor = Instance.new("Part")
    floor.Name = "Floor"
    floor.Size = Vector3.new(10, 1, 10)
    floor.Position = self.model.PrimaryPart.Position - Vector3.new(0, self.model.PrimaryPart.Size.Y / 2, 0)
    floor.Color = Color3.fromRGB(139, 69, 19)
    floor.Material = Enum.Material.Wood
    floor.Anchored = true
    floor.Parent = house

    house.Parent = workspace

    -- For now, building is instant.
    self.state = "Idle"
end

function NPC:findMate(activeNPCs)
    local nearestMate = nil
    local minDistance = math.huge

    for _, otherNPC in ipairs(activeNPCs) do
        if otherNPC ~= self and otherNPC.state == "Breeding" then
            local distance = (self.model.PrimaryPart.Position - otherNPC.model.PrimaryPart.Position).Magnitude
            if distance < minDistance then
                minDistance = distance
                nearestMate = otherNPC
            end
        end
    end

    return nearestMate
end

function NPC:breedWith(mate, spawnNPC)
    print("Two NPCs are breeding!")

    local newNPC = spawnNPC()

    if newNPC then
        newNPC.genome = Genome.mutate(Genome.combine(self.genome, mate.genome), 0.1, 0.2)
        print("A new NPC has been born!")
    end

    self.state = "Idle"
    mate.state = "Idle"
end

function NPC:update(deltaTime, activeNPCs, spawnNPC)
    self.age = self.age + deltaTime

    -- State machine logic based on intelligence
    if self.genome.intelligence < 5 then
        self.state = "Wandering"
    elseif self.genome.intelligence >= 5 and self.genome.intelligence < 10 then
        self.state = "Gathering"
    elseif self.genome.intelligence >= 10 and not workspace:FindFirstChild("House") then
        self.state = "Building"
    elseif self.genome.intelligence >= 10 and workspace:FindFirstChild("House") then
        self.state = "Breeding"
    else
        self.state = "Wandering"
    end

    if self.state == "Gathering" then
        local tree = self:findNearestTree()
        if tree then
            self.humanoid:MoveTo(tree.PrimaryPart.Position)
            if (self.model.PrimaryPart.Position - tree.PrimaryPart.Position).Magnitude < 10 then
                self:chopTree(tree)
            end
        end
    elseif self.state == "Building" then
        self:buildHouse()
    elseif self.state == "Breeding" then
        local mate = self:findMate(activeNPCs)
        if mate then
            self.humanoid:MoveTo(mate.model.PrimaryPart.Position)
            if (self.model.PrimaryPart.Position - mate.model.PrimaryPart.Position).Magnitude < 10 then
                self:breedWith(mate, spawnNPC)
            end
        end
    elseif self.state == "Wandering" then
        if self.humanoid and math.random() < 0.1 then
            self.humanoid:MoveTo(self.model.PrimaryPart.Position + Vector3.new(math.random(-100, 100), 0, math.random(-100, 100)))
        end
    end
end

return NPC

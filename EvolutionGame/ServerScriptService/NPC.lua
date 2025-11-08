--!strict
-- NPC Class
-- Manages the state, needs, and behavior of a single NPC, driven by knowledge.

local ServerScriptService = game:GetService("ServerScriptService")
local Pathfinding = require(ServerScriptService.Pathfinding)

local NPC = {}
NPC.__index = NPC

function NPC.new(model)
    local self = setmetatable({}, NPC)

    self.model = model
    self.humanoid = model:FindFirstChildOfClass("Humanoid")

    -- Knowledge-based "evolution"
    self.knowledge = {
        ediblePlants = {},
        dangerousAnimals = {},
        toolBlueprints = {},
    }

    -- Core Drives
    self.hunger = 0
    self.thirst = 0
    self.shelter = 100 -- 100 = fully sheltered

    self.age = 0
    self.state = "Wandering" -- Wandering, Gathering, Hunting, SeekingShelter, Breeding
    self.isMoving = false
    self.tribe = nil

    return self
end

function NPC:moveTo(destination)
    if self.isMoving then return end
    self.isMoving = true

    local path = Pathfinding.computePath(self.model.PrimaryPart.Position, destination)
    Pathfinding.followPath(self.humanoid, path)

    self.isMoving = false
end

function NPC:findNearestResource(resourceName)
    local nearestResource = nil
    local minDistance = math.huge

    local searchFolder = workspace.Nature -- For now, all resources are in Nature
    if searchFolder then
        for _, child in ipairs(searchFolder:GetChildren()) do
            if child.Name == resourceName then
                local distance = (self.model.PrimaryPart.Position - child.PrimaryPart.Position).Magnitude
                if distance < minDistance then
                    minDistance = distance
                    nearestResource = child
                end
            end
        end
    end

    return nearestResource
end

function NPC:update(deltaTime, activeNPCs, spawnNPC)
    self.age = self.age + deltaTime
    self.hunger = self.hunger + deltaTime * 0.1
    self.thirst = self.thirst + deltaTime * 0.15

    -- State machine driven by needs
    if self.hunger > 70 then
        if self.knowledge.toolBlueprints["SimpleSpear"] then
            self.state = "Hunting"
        else
            self.state = "Gathering"
        end
    elseif self.thirst > 80 then
        self.state = "SeekingWater"
    elseif game.Lighting.ClockTime > 18 or game.Lighting.ClockTime < 6 then
        self.state = "SeekingShelter"
    else
        self.state = "Wandering"
    end

    -- Handle actions based on state
    if self.state == "Gathering" then
        local plant = self:findNearestResource("Bush")
        if plant then
            self:moveTo(plant.PrimaryPart.Position)
            if (self.model.PrimaryPart.Position - plant.PrimaryPart.Position).Magnitude < 10 then
                self.hunger = 0
                plant:Destroy()
            end
        end
    elseif self.state == "Wandering" then
        if math.random() < 0.1 then
            self:moveTo(self.model.PrimaryPart.Position + Vector3.new(math.random(-100, 100), 0, math.random(-100, 100)))
        end
    end
end

return NPC

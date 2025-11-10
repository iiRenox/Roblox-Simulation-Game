--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Genome = require(ReplicatedStorage.Genome)
local Pathfinding = require(ServerScriptService.Pathfinding)

--- Manages the state, needs, and behavior of a single NPC.
-- This class represents an individual Non-Player Character, handling their AI,
-- needs (hunger, thirst), knowledge, and interactions with the environment.
-- NPC evolution is primarily technological and social, with subtle genetic influences.
local NPC = {}
NPC.__index = NPC

-- Defines the genetic structure for all NPCs (Humans)
local npcGenomeTemplate = {
	-- Core Genetic Traits
	mutationChance = { type = "number", defaultValue = 0.01, min = 0.0, max = 0.05 }, -- Lower than animals
	inheritanceAllele = { type = "allele", defaultValue = "average" },
	-- Physical Attributes (Internal)
	metabolism = { type = "number", defaultValue = 1, min = 0.5, max = 1.5 }, -- Hunger/thirst rate multiplier
	diseaseResistance = { type = "number", defaultValue = 0.5, min = 0, max = 1 },
	lifespan = { type = "number", defaultValue = 200, min = 150, max = 300 },
	strength = { type = "number", defaultValue = 10, min = 5, max = 20 },
	endurance = { type = "number", defaultValue = 10, min = 5, max = 20 },
	-- Reproduction
	childAmount = { type = "number", defaultValue = 1, min = 1, max = 3 },
}

--- Creates a new NPC instance.
-- @param model Model The visual representation of the NPC in the workspace.
-- @return table The new NPC object.
function NPC.new(model)
    local self = setmetatable({}, NPC)

    self.model = model
    self.humanoid = model:FindFirstChildOfClass("Humanoid")
    self.genome = Genome.create(npcGenomeTemplate)

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

--- Moves the NPC to a specified destination using the Pathfinding service.
-- @param destination Vector3 The target position to move to.
function NPC:moveTo(destination)
    if self.isMoving then return end
    self.isMoving = true

    local path = Pathfinding.computePath(self.model.PrimaryPart.Position, destination)
    Pathfinding.followPath(self.humanoid, path)

    self.isMoving = false
end

--- Finds the nearest plant resource.
-- Used for gathering food.
-- @param activePlants table A list of all active plants in the simulation.
-- @return table? The nearest plant object, or nil if none is found.
function NPC:findNearestResource(activePlants)
    local nearestResource = nil
    local minDistance = math.huge

    for _, plant in ipairs(activePlants) do
        if plant and plant.model and plant.model.PrimaryPart then
            local distance = (self.model.PrimaryPart.Position - plant.model.PrimaryPart.Position).Magnitude
            if distance < minDistance then
                minDistance = distance
                nearestResource = plant
            end
        end
    end

    return nearestResource
end

--- Handles the death of the NPC.
-- Destroys the NPC's model and marks it for cleanup.
-- @return string Returns "dead" to signal removal from the active list.
function NPC:die()
    if self.model then
        self.model:Destroy()
        self.model = nil
    end
    return "dead"
end

--- The main update loop for the NPC's AI and life cycle.
-- This function is called on every simulation tick. It manages needs,
-- and the state machine that drives the NPC's behavior.
-- @param deltaTime number The time since the last update.
-- @param activeNPCs table A list of all active NPCs.
-- @param activePlants table A list of all active plants.
-- @param spawnNPC function A function to call to spawn a new NPC (for breeding).
-- @return string? "dead" if the NPC has died during the update, otherwise nil.
function NPC:update(deltaTime, activeNPCs, activePlants, spawnNPC)
    self.age = self.age + deltaTime
    self.hunger = self.hunger + (deltaTime * 0.1 * self.genome.metabolism)
    self.thirst = self.thirst + (deltaTime * 0.15 * self.genome.metabolism)

    if self.hunger > 100 then
        print("An NPC has starved to death.")
        return self:die()
    end

    if self.age > self.genome.lifespan then
        print("An NPC has died of old age.")
        return self:die()
    end

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
        local plant = self:findNearestResource(activePlants)
        if plant then
            self:moveTo(plant.model.PrimaryPart.Position)
            if (self.model.PrimaryPart.Position - plant.model.PrimaryPart.Position).Magnitude < 10 then
                self.hunger = self.hunger - plant.genome.nutritionalValue
                plant:die()
            end
        else
            -- Wander to search for food
            if math.random() < 0.1 then
                local randomDirection = Vector3.new(math.random(-150, 150), 0, math.random(-150, 150))
                self:moveTo(self.model.PrimaryPart.Position + randomDirection)
            end
        end
    elseif self.state == "Wandering" then
        if math.random() < 0.1 then
            self:moveTo(self.model.PrimaryPart.Position + Vector3.new(math.random(-100, 100), 0, math.random(-100, 100)))
        end
    end
end

return NPC

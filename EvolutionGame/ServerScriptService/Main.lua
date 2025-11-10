--!strict

-- The main entry point for the entire simulation.
-- This script is responsible for requiring and initializing all the core services
-- in the correct order to ensure dependencies are met. It orchestrates the
-- startup sequence of the game.

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create communication channels for client-server interaction
local toggleSimulationEvent = Instance.new("RemoteEvent")
toggleSimulationEvent.Name = "ToggleSimulation"
toggleSimulationEvent.Parent = ReplicatedStorage

local requestDataFunction = Instance.new("RemoteFunction")
requestDataFunction.Name = "RequestSimulationData"
requestDataFunction.Parent = ReplicatedStorage

-- Require all the major services
local NatureService = require(ServerScriptService.NatureService)
local AnimalService = require(ServerScriptService.AnimalService)
local NPCService = require(ServerScriptService.NPCService)
local LightingService = require(ServerScriptService.LightingService)
local TimeService = require(ServerScriptService.TimeService)
local DataService = require(ServerScriptService.DataService)

-- Initialize services
LightingService.setup()
TimeService.start()
DataService.start()

-- Start world generation and wait for it to complete
-- Start world generation
local onNatureFinished = NatureService.start()

-- Connect the dependent services to the completion event
onNatureFinished:Connect(function()
	print("Nature generation finished. Starting Animal and NPC services.")
	AnimalService.start()
	NPCService.start()
end)

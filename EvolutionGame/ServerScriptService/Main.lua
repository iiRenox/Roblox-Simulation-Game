--!strict

-- The main entry point for the entire simulation.
-- This script is responsible for requiring and initializing all the core services
-- in the correct order to ensure dependencies are met. It orchestrates the
-- startup sequence of the game.

local ServerScriptService = game:GetService("ServerScriptService")

-- Require all the major services
local NatureService = require(ServerScriptService.NatureService)
local AnimalService = require(ServerScriptService.AnimalService)
local NPCService = require(ServerScriptService.NPCService)
local LightingService = require(ServerScriptService.LightingService)
local TimeService = require(ServerScriptService.TimeService)

-- Initialize services
LightingService.setup()
TimeService.start()

-- Start world generation and wait for it to complete
local onNatureFinished = NatureService.start()
onNatureFinished:Wait()

-- Once the world is generated, start the entity services
AnimalService.start()
NPCService.start()

local ServerScriptService = game:GetService("ServerScriptService")

local NatureService = require(ServerScriptService.NatureService)
local AnimalService = require(ServerScriptService.AnimalService)
local NPCService = require(ServerScriptService.NPCService)
local LightingService = require(ServerScriptService.LightingService)
local TimeService = require(ServerScriptService.TimeService)

LightingService.setup()
TimeService.start()

local onNatureFinished = NatureService.start()

onNatureFinished:Wait()

AnimalService.start()
NPCService.start()

local ServerScriptService = game:GetService("ServerScriptService")

local NatureService = require(ServerScriptService.NatureService)
local AnimalService = require(ServerScriptService.AnimalService)
local NPCService = require(ServerScriptService.NPCService)

local onNatureFinished = NatureService.start()

onNatureFinished:Wait()

AnimalService.start()
NPCService.start()

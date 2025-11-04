local ServerScriptService = game:GetService("ServerScriptService")

local NatureService = require(ServerScriptService.NatureService)
local AnimalService = require(ServerScriptService.AnimalService)
local NPCService = require(ServerScriptService.NPCService)

NatureService.start()
AnimalService.start()
NPCService.start()

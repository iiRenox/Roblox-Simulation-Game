--!strict
-- NPCService
-- Manages the spawning and updating of all NPCs.

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldUtil = require(ReplicatedStorage.WorldUtil)
local NPC = require(ServerScriptService.NPC)
local TimeService = require(ServerScriptService.TimeService)

local NPCService = {}

local activeNPCs = {} -- Holds all the active NPC objects
local tribe = {} -- A simple table to represent the first tribe

function NPCService.createNPC(spawnPosition)
    local npc = Instance.new("Model")
    npc.Name = "NPC"

    local torso = Instance.new("Part")
    torso.Name = "Torso"
    torso.Size = Vector3.new(2, 2, 1)
    torso.Color = Color3.fromRGB(0, 162, 255)
    torso.Parent = npc

    local head = Instance.new("Part")
    head.Name = "Head"
    head.Size = Vector3.new(1.5, 1.5, 1.5)
    head.Position = Vector3.new(0, 2, 0)
    head.Color = Color3.fromRGB(255, 204, 153)
    head.Parent = npc
    local weldHead = Instance.new("WeldConstraint")
    weldHead.Part0 = torso
    weldHead.Part1 = head
    weldHead.Parent = torso

    local limbSize = Vector3.new(1, 2, 1)
    local armPositions = { Vector3.new(1.5, 0, 0), Vector3.new(-1.5, 0, 0) }
    local legPositions = { Vector3.new(0.5, -2, 0), Vector3.new(-0.5, -2, 0) }

    for i, pos in ipairs(armPositions) do
        local arm = Instance.new("Part")
        arm.Name = "Arm" .. i
        arm.Size = limbSize
        arm.Position = pos
        arm.Color = Color3.fromRGB(255, 204, 153)
        arm.Parent = npc
        local weldArm = Instance.new("WeldConstraint")
        weldArm.Part0 = torso
        weldArm.Part1 = arm
        weldArm.Parent = torso
    end

    for i, pos in ipairs(legPositions) do
        local leg = Instance.new("Part")
        leg.Name = "Leg" .. i
        leg.Size = limbSize
        leg.Position = pos
        leg.Color = Color3.fromRGB(110, 110, 110)
        leg.Parent = npc
        local weldLeg = Instance.new("WeldConstraint")
        weldLeg.Part0 = torso
        weldLeg.Part1 = leg
        weldLeg.Parent = torso
    end

    local humanoid = Instance.new("Humanoid")
    humanoid.Parent = npc

    npc.PrimaryPart = torso
    npc:SetPrimaryPartCFrame(CFrame.new(spawnPosition))

    return npc
end

function NPCService.spawnNPC()
    print("Attempting to spawn an NPC...")

    local groundPosition
    local material
    local attempts = 0

    repeat
        local x = math.random(-1024, 1024)
        local z = math.random(-1024, 1024)

        groundPosition = WorldUtil.getGroundPosition(x, z)

        if groundPosition then
            material = WorldUtil.getMaterialAtPosition(groundPosition)
        end

        attempts = attempts + 1

    until (groundPosition and material ~= Enum.Material.Water) or attempts > 50

    if groundPosition and material ~= Enum.Material.Water then
        print("Ground found at: " .. tostring(groundPosition))
        local spawnPosition = groundPosition + Vector3.new(0, 4, 0)

        local npcModel = NPCService.createNPC(spawnPosition)
        npcModel.Parent = workspace

        local npcObject = NPC.new(npcModel)
        table.insert(activeNPCs, npcObject)
        table.insert(tribe, npcObject)
        npcObject.tribe = tribe

        print("NPC spawned successfully at: " .. tostring(spawnPosition))
        return npcObject
    else
        print("Failed to find a valid ground position for NPC after 50 attempts.")
    end
end

function NPCService.start()
    print("NPCService started")
    -- Spawn the first two humans
    NPCService.spawnNPC()
    NPCService.spawnNPC()

    -- Connect to the game loop
    TimeService.getTick():Connect(function(deltaTime, season)
        local NatureService = require(ServerScriptService.NatureService)
        local activePlants = NatureService.getActivePlants()

        for i = #activeNPCs, 1, -1 do
            local npc = activeNPCs[i]
            local status = npc:update(deltaTime, activeNPCs, activePlants, NPCService.spawnNPC)

            if status == "dead" then
                -- Also remove from tribe
                for j, tribeNpc in ipairs(tribe) do
                    if tribeNpc == npc then
                        table.remove(tribe, j)
                        break
                    end
                end
                table.remove(activeNPCs, i)
                continue
            end

            -- "Eureka!" moment
            if npc.state == "Hunting" and math.random() < 0.01 then
                if not npc.knowledge.toolBlueprints["SimpleSpear"] then
                    npc.knowledge.toolBlueprints["SimpleSpear"] = true
                    print("An NPC has discovered how to make a Simple Spear!")
                end
            end
        end

        -- Breeding logic
        if season == "Spring" then
            for _, npc in ipairs(tribe) do
                if npc.state == "SeekingShelter" and #tribe < 10 then -- Limit tribe size for now
                    for _, otherNpc in ipairs(tribe) do
                        if npc ~= otherNpc and otherNpc.state == "SeekingShelter" then
                            -- Simple breeding logic
                            local newNpc = NPCService.spawnNPC()
                            if newNpc then
                                -- Knowledge is passed down
                                newNpc.knowledge = npc.knowledge
                                print("A new NPC has been born into the tribe!")
                            end
                            return -- Only one birth per spring for now
                        end
                    end
                end
            end
        end
    end)
end

return NPCService

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldUtil = require(ReplicatedStorage.WorldUtil)
local WanderAI = require(ReplicatedStorage.WanderAI)

local NPCService = {}

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
    local x = math.random(-1024, 1024)
    local z = math.random(-1024, 1024)
    print("Generated coordinates: " .. x .. ", " .. z)

    local groundPosition = WorldUtil.getGroundPosition(x, z)

    if groundPosition then
        print("Ground found at: " .. tostring(groundPosition))
        local spawnPosition = groundPosition + Vector3.new(0, 4, 0)

        local npc = NPCService.createNPC(spawnPosition)
        npc.Parent = workspace
        WanderAI.startWandering(npc)

        print("NPC spawned successfully at: " .. tostring(spawnPosition))
    else
        print("Failed to find ground for NPC at: " .. x .. ", " .. z)
    end
end

function NPCService.start()
    print("NPCService started")
    -- Spawn a couple of NPCs to start
    for _ = 1, 2 do
        NPCService.spawnNPC()
    end
end

return NPCService

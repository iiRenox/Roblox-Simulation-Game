local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldUtil = require(ReplicatedStorage.WorldUtil)

local NPCService = {}

function NPCService.spawnNPC()
    local x = math.random(1, 1024)
    local z = math.random(1, 1024)

    local groundPosition = WorldUtil.getGroundPosition(x, z)

    if groundPosition then
        local spawnPosition = groundPosition + Vector3.new(0, 4, 0)

        local npc = Instance.new("Model")
        npc.Name = "NPC"
        npc.Parent = workspace

        local torso = Instance.new("Part")
        torso.Parent = npc
        torso.Name = "Torso"
        torso.Size = Vector3.new(4, 4, 2)
        torso.Position = spawnPosition

        local head = Instance.new("Part")
        head.Parent = npc
        head.Name = "Head"
        head.Size = Vector3.new(2, 2, 2)
        head.Position = spawnPosition + Vector3.new(0, 3, 0)

        -- Weld the head to the torso
        local weld = Instance.new("WeldConstraint")
        weld.Parent = torso
        weld.Part0 = torso
        weld.Part1 = head

        local humanoid = Instance.new("Humanoid")
        humanoid.Parent = npc

        -- Set the primary part for the model
        npc.PrimaryPart = torso

        -- Move the NPC to the spawn position
        npc:SetPrimaryPartCFrame(CFrame.new(spawnPosition))
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

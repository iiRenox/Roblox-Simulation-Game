local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldUtil = require(ReplicatedStorage.WorldUtil)
local NatureService = {}

-- Noise parameters for foliage
local foliageSmothness = 50
local foliageThreshold = 0.5
local flowerSmothness = 20
local flowerThreshold = 0.7

function NatureService.generateWorld()
    print("Starting world generation...")
    local terrain = workspace.Terrain

    -- Generation parameters
    local xSize = 512 -- Increased size for a larger world
    local zSize = 512 -- Increased size for a larger world
    local seed = math.random(1, 1000)
    local baseHeight = -20

    -- Noise parameters for multiple layers
    local continentSmothness = 500
    local continentMultiplier = 150

    local mountainSmothness = 100
    local mountainMultiplier = 200
    local mountainPower = 1.5

    local detailSmothness = 20
    local detailMultiplier = 10

    -- Noise parameters for craggy rock formations
    local craggySmothness = 15
    local craggyMultiplier = 25
    local cragginessMaskSmothness = 100
    local cragginessMaskThreshold = 0.6

    -- Create a height map to store the terrain data before rendering
    local heightMap = {}
    -- 1. Generate the base terrain heights and store them in the heightMap
    print("Generating height map...")
    for x = 1, xSize do
        heightMap[x] = {}
        for z = 1, zSize do
            local worldX = x - xSize / 2
            local worldZ = z - zSize / 2

            -- Calculate each noise layer
            local continentNoise = (math.noise(worldX / continentSmothness, worldZ / continentSmothness, seed)) * continentMultiplier
            local mountainNoise = math.pow(math.abs(math.noise(worldX / mountainSmothness, worldZ / mountainSmothness, seed + 1)), mountainPower) * mountainMultiplier
            local detailNoise = (math.noise(worldX / detailSmothness, worldZ / detailSmothness, seed + 2)) * detailMultiplier

            -- Calculate craggy noise and a mask to control where it appears
            local cragginessMask = (math.noise(worldX / cragginessMaskSmothness, worldZ / cragginessMaskSmothness, seed + 3) + 1) / 2
            local craggyNoise = 0
            if cragginessMask > cragginessMaskThreshold then
                craggyNoise = (math.noise(worldX / craggySmothness, worldZ / craggySmothness, seed + 4) * craggyMultiplier) * ((cragginessMask - cragginessMaskThreshold) / (1 - cragginessMaskThreshold))
            end

            -- Combine the noise layers to get the final height
            heightMap[x][z] = continentNoise + mountainNoise + detailNoise + craggyNoise
        end
        if x % 16 == 0 then
            task.wait()
        end
    end
    print("Height map generation complete.")

    -- 2. Carve rivers into the heightMap
    print("Generating rivers...")
    NatureService.generateRivers(heightMap, xSize, zSize)
    print("River generation complete.")

    -- 3. Render the terrain from the heightMap
    print("Rendering terrain...")
    for x = 1, xSize do
        for z = 1, zSize do
            local y = heightMap[x][z]
            local worldX = x - xSize / 2
            local worldZ = z - zSize / 2

            -- Define the terrain block (column)
            local size = Vector3.new(4, y - baseHeight, 4)
            local position = Vector3.new(worldX * 4, baseHeight + size.Y / 2, worldZ * 4)
            local cframe = CFrame.new(position)

            -- Determine the material based on the height to create biomes
            local material
            if y > 180 then
                material = Enum.Material.Snow
            elseif y > 90 then
                material = Enum.Material.Rock
            elseif y > 5 then
                material = Enum.Material.Grass
            elseif y > 0 then
                material = Enum.Material.Sand -- Beach biome
            else
                material = Enum.Material.Water
            end

            -- If the material is water, fill it up to the sea level
            if material == Enum.Material.Water then
                local waterSize = Vector3.new(4, 0 - baseHeight, 4)
                local waterPosition = Vector3.new(worldX * 4, baseHeight + waterSize.Y / 2, worldZ * 4)
                terrain:FillBlock(CFrame.new(waterPosition), waterSize, Enum.Material.Water)
            else
                -- Fill the block with the determined material
                terrain:FillBlock(cframe, size, material)
            end
        end
        if x % 16 == 0 then
            task.wait()
        end
    end
    print("World generation complete.")

    NatureService.generateTrees(xSize, zSize, seed)
    NatureService.generateFlowers(xSize, zSize, seed)
end

function NatureService.generateFlowers(xSize, zSize, seed)
    for x = 1, xSize, 4 do
        for z = 1, zSize, 4 do
            local worldX = (x - xSize / 2) * 4
            local worldZ = (z - zSize / 2) * 4

            local flowerNoise = (math.noise(worldX / flowerSmothness, worldZ / flowerSmothness, seed + 6) + 1) / 2

            if flowerNoise > flowerThreshold then
                local groundPosition = WorldUtil.getGroundPosition(worldX, worldZ)

                if groundPosition then
                    local material = WorldUtil.getMaterialAtPosition(groundPosition)

                    if material == Enum.Material.Grass then
                        NatureService.createFlower(groundPosition)
                    end
                end
            end
        end
        task.wait()
    end
end

function NatureService.generateTrees(xSize, zSize, seed)
    for x = 1, xSize, 8 do
        for z = 1, zSize, 8 do
            local worldX = (x - xSize / 2) * 4
        local worldZ = (z - zSize / 2) * 4

        local groundPosition = WorldUtil.getGroundPosition(worldX, worldZ)

        if groundPosition then
            local foliageNoise = (math.noise(worldX / foliageSmothness, worldZ / foliageSmothness, seed + 5) + 1) / 2

            if foliageNoise > foliageThreshold then
                local material = WorldUtil.getMaterialAtPosition(groundPosition)

                if material == Enum.Material.Grass then
                    NatureService.createTree(groundPosition)
                end
            end
        end
    end
    task.wait()
    end
end

function NatureService.start()
    print("NatureService started")
    local onFinished = Instance.new("BindableEvent")

    coroutine.wrap(function()
        -- Clear all existing terrain
        workspace.Terrain:Clear()

        -- Destroy any old terrain parts from previous versions
        for _, child in ipairs(workspace:GetChildren()) do
            if child.Name == "TerrainBlock" or child.Name == "Baseplate" then
                child:Destroy()
            end
        end

        -- Generate the new terrain
        NatureService.generateWorld()

        onFinished:Fire()
    end)()

    return onFinished.Event
end

function NatureService.generateRivers(heightMap, xSize, zSize)
    local seaLevel = 0
    local numRivers = 15
    local riverDepth = 10

    for i = 1, numRivers do
        -- Find a random starting point for the river at a high elevation
        local startX, startZ
        local startHeight = -math.huge

        for i=1, 10 do -- Try 10 times to find a high point
            local tryX = math.random(1, xSize)
            local tryZ = math.random(1, zSize)
            if heightMap[tryX][tryZ] > startHeight then
                startX = tryX
                startZ = tryZ
                startHeight = heightMap[tryX][tryZ]
            end
        end

        -- Carve the river path from the starting point
        local currentX = startX
        local currentZ = startZ
        while heightMap[currentX][currentZ] > seaLevel do
            heightMap[currentX][currentZ] = heightMap[currentX][currentZ] - riverDepth

            -- Find the lowest neighbor to continue the path
            local lowestNeighborX, lowestNeighborZ = currentX, currentZ
            local lowestHeight = heightMap[currentX][currentZ]

            for nx = -1, 1 do
                for nz = -1, 1 do
                    local nextX = currentX + nx
                    local nextZ = currentZ + nz

                    if nextX > 0 and nextX <= xSize and nextZ > 0 and nextZ <= zSize and heightMap[nextX][nextZ] < lowestHeight then
                        lowestHeight = heightMap[nextX][nextZ]
                        lowestNeighborX = nextX
                        lowestNeighborZ = nextZ
                    end
                end
            end

            -- If we are stuck in a local minimum, stop carving
            if lowestNeighborX == currentX and lowestNeighborZ == currentZ then
                break
            end

            currentX = lowestNeighborX
            currentZ = lowestNeighborZ
        end
    end
end

function NatureService.createTree(position)
    local treeType = math.random(1, 10)

    if treeType <= 3 then -- 30% chance of a bush
        NatureService.createBush(position)
    else -- 70% chance of a regular tree
        NatureService.createRegularTree(position)
    end
end

function NatureService.createBush(position)
    local bush = Instance.new("Model")
    bush.Name = "Bush"
    bush.Parent = workspace

    local leaves = Instance.new("Part")
    leaves.Name = "Leaves"
    leaves.Parent = bush
    leaves.Shape = Enum.PartType.Ball
    leaves.Size = Vector3.new(math.random(4, 8), math.random(4, 8), math.random(4, 8))
    leaves.Position = position + Vector3.new(0, leaves.Size.Y / 2, 0)
    leaves.Color = Color3.fromRGB(34, 139, 34)
    leaves.Anchored = true

    bush.PrimaryPart = leaves
    return bush
end

function NatureService.createRegularTree(position)
    local tree = Instance.new("Model")
    tree.Name = "Tree"
    tree.Parent = workspace

    local trunkHeight = math.random(12, 25)
    local trunkRadius = math.random(1, 3)

    local trunk = Instance.new("Part")
    trunk.Name = "Trunk"
    trunk.Parent = tree
    trunk.Shape = Enum.PartType.Cylinder
    trunk.Size = Vector3.new(trunkRadius * 2, trunkHeight, trunkRadius * 2)
    trunk.Position = position + Vector3.new(0, trunk.Size.Y / 2, 0)
    trunk.Color = Color3.fromRGB(87, 56, 34)
    trunk.Anchored = true

    local function createBranch(parent, level, position, direction)
        if level > 5 then
            return
        end

        local branchLength = trunkHeight / level * math.random(0.8, 1.2)
        local branchRadius = trunkRadius / level * math.random(0.8, 1.2)

        local branch = Instance.new("Part")
        branch.Name = "Branch"
        branch.Parent = parent
        branch.Shape = Enum.PartType.Cylinder
        branch.Size = Vector3.new(branchRadius * 2, branchLength, branchRadius * 2)
        branch.CFrame = CFrame.new(position, position + direction) * CFrame.Angles(math.rad(90), 0, 0)
        branch.Color = Color3.fromRGB(87, 56, 34)
        branch.Anchored = true

        local endPosition = position + direction * branchLength

        if level < 3 then
            local numBranches = math.random(2, 4)
            for i = 1, numBranches do
                local randomOffset = Vector3.new(math.random(-10, 10) / 10, math.random(-10, 10) / 10, math.random(-10, 10) / 10)
                if (direction + randomOffset).Magnitude > 0 then
                    local newDirection = (direction + randomOffset).Unit
                    createBranch(parent, level + 1, endPosition, newDirection)
                end
            end
        else
            local leaves = Instance.new("Part")
            leaves.Name = "Leaves"
            leaves.Parent = parent
            leaves.Shape = Enum.PartType.Ball
            leaves.Size = Vector3.new(math.random(8, 12), math.random(8, 12), math.random(8, 12))
            leaves.Position = endPosition
            leaves.Color = Color3.fromRGB(34, 139, 34)
            leaves.Anchored = true
        end
    end

    createBranch(tree, 1, trunk.Position + Vector3.new(0, trunkHeight / 2, 0), Vector3.new(0, 1, 0))

    tree.PrimaryPart = trunk
    return tree
end

function NatureService.createFlower(position)
    local flower = Instance.new("Model")
    flower.Name = "Flower"
    flower.Parent = workspace

    local stem = Instance.new("Part")
    stem.Name = "Stem"
    stem.Parent = flower
    stem.Size = Vector3.new(0.2, 1, 0.2)
    stem.Position = position + Vector3.new(0, 0.5, 0)
    stem.Color = Color3.fromRGB(0, 100, 0)
    stem.Anchored = true

    local petal = Instance.new("Part")
    petal.Name = "Petal"
    petal.Parent = flower
    petal.Shape = Enum.PartType.Ball
    petal.Size = Vector3.new(1, 1, 1)
    petal.Position = stem.Position + Vector3.new(0, 0.5, 0)
    petal.Color = Color3.fromHSV(math.random(), 1, 1)
    petal.Anchored = true

    flower.PrimaryPart = stem
    return flower
end

return NatureService

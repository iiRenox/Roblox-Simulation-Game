local ReplicatedStorage = game:GetService("ReplicatedStorage")
local WorldUtil = require(ReplicatedStorage.WorldUtil)
local NatureService = {}

local natureFolder -- This will hold all the generated nature models

-- Noise parameters for foliage
local foliageSmothness = 50
local foliageThreshold = 0.5

-- Forest biome noise parameters
local forestNoiseSmothness = 200 -- Large scale noise for biome definition
local forestThreshold = 0.6 -- Defines dense forest areas
local patchThreshold = 0.4 -- Defines sparse patch areas

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
    NatureService.generateBushes(xSize, zSize, seed)
    NatureService.generateFlowers(xSize, zSize, seed)
end

function NatureService.generateBushes(xSize, zSize, seed)
    for x = 1, xSize, 6 do
        for z = 1, zSize, 6 do
            local worldX = (x - xSize / 2) * 4
            local worldZ = (z - zSize / 2) * 4

            local bushNoise = (math.noise(worldX / 40, worldZ / 40, seed + 7) + 1) / 2

            if bushNoise > 0.6 then
                local groundPosition = WorldUtil.getGroundPosition(worldX, worldZ)

                if groundPosition then
                    local material = WorldUtil.getMaterialAtPosition(groundPosition)

                    if material == Enum.Material.Grass then
                        NatureService.createBush(groundPosition)
                    end
                end
            end
        end
        task.wait()
    end
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
    local clusterStep = 32 -- How far apart to check for potential cluster centers
    for x = 1, xSize, clusterStep do
        for z = 1, zSize, clusterStep do
            local worldX = (x - xSize / 2) * 4
            local worldZ = (z - zSize / 2) * 4

            -- Determine the biome type using the forest noise map
            local forestNoise = (math.noise(worldX / forestNoiseSmothness, worldZ / forestNoiseSmothness, seed + 8) + 1) / 2

            if forestNoise > forestThreshold then
                -- DENSE FOREST: Spawn a large cluster of 10-25 trees
                local numTrees = math.random(10, 25)
                for i = 1, numTrees do
                    local offsetX = math.random(-64, 64)
                    local offsetZ = math.random(-64, 64)
                    local treeX = worldX + offsetX
                    local treeZ = worldZ + offsetZ

                    local groundPosition = WorldUtil.getGroundPosition(treeX, treeZ)
                    if groundPosition then
                        local material = WorldUtil.getMaterialAtPosition(groundPosition)
                        if material == Enum.Material.Grass then
                            NatureService.createTree(groundPosition)
                        end
                    end
                end
            elseif forestNoise > patchThreshold then
                -- SPARSE PATCH: Spawn a small cluster of 2-4 trees
                local numTrees = math.random(2, 4)
                for i = 1, numTrees do
                    local offsetX = math.random(-32, 32)
                    local offsetZ = math.random(-32, 32)
                    local treeX = worldX + offsetX
                    local treeZ = worldZ + offsetZ

                    local groundPosition = WorldUtil.getGroundPosition(treeX, treeZ)
                    if groundPosition then
                        local material = WorldUtil.getMaterialAtPosition(groundPosition)
                        if material == Enum.Material.Grass then
                            NatureService.createTree(groundPosition)
                        end
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
            if child.Name == "TerrainBlock" or child.Name == "Baseplate" or child.Name == "Nature" then
                child:Destroy()
            end
        end

        -- Create a new folder for nature models
        natureFolder = Instance.new("Folder")
        natureFolder.Name = "Nature"
        natureFolder.Parent = workspace

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
    NatureService.createRegularTree(position)
end

function NatureService.createBush(position)
    local bush = Instance.new("Model")
    bush.Name = "Bush"
    bush.Parent = natureFolder

    -- Create a small, dark stump
    local stump = Instance.new("Part")
    stump.Name = "Stump"
    stump.Parent = bush
    stump.Shape = Enum.PartType.Cylinder
    stump.Size = Vector3.new(2, 1, 2)
    stump.Position = position + Vector3.new(0, 0.5, 0)
    stump.Color = Color3.fromRGB(87, 56, 34)
    stump.Material = Enum.Material.Wood
    stump.Anchored = true

    -- Create the leafy part
    local leaves = Instance.new("Part")
    leaves.Name = "Leaves"
    leaves.Parent = bush
    leaves.Shape = Enum.PartType.Ball
    local leafSize = math.random(6, 10)
    leaves.Size = Vector3.new(leafSize, leafSize, leafSize)
    leaves.Position = position + Vector3.new(0, leafSize / 2, 0)
    leaves.Color = Color3.fromRGB(34, 139, 34)
    leaves.Material = Enum.Material.LeafyGrass
    leaves.Anchored = true

    bush.PrimaryPart = leaves
    return bush
end

function NatureService.createRegularTree(position)
    local tree = Instance.new("Model")
    tree.Name = "Tree"
    tree.Parent = natureFolder

    -- Generation Parameters
    local MAX_ITERATIONS = math.random(4, 6)
    local BASE_ANGLE = 45
    local woodColor = Color3.fromRGB(87, 56, 34)
    local leafColor = Color3.fromRGB(34, 139, 34)
    local trunkHeight = math.random(25, 40)
    local trunkRadius = trunkHeight / 12

    -- Create a multi-part, organic trunk
    local trunkParts = {}
    local trunkCFrame = CFrame.new(position)
    local segments = math.floor(trunkHeight / 4)
    local trunkPart = nil

    for i = 1, segments do
        trunkPart = Instance.new("Part")
        trunkPart.Name = "TrunkSegment"
        trunkPart.Shape = Enum.PartType.Block
        local segmentLength = trunkHeight / segments
        local radius = trunkRadius * (1 - (i / (segments * 2))) -- Taper the trunk
        trunkPart.Size = Vector3.new(radius * 2, segmentLength, radius * 2)
        trunkPart.Color = woodColor
        trunkPart.Material = Enum.Material.Wood
        trunkPart.Anchored = true

        -- Position the segment and apply a slight rotation for a natural look
        trunkCFrame = trunkCFrame * CFrame.new(0, segmentLength / 2, 0)
        local rotation = CFrame.Angles(math.rad(math.random(-10, 10)), math.rad(math.random(-10, 10)), math.rad(math.random(-10, 10)))
        trunkPart.CFrame = trunkCFrame * rotation
        trunkPart.Parent = tree
        table.insert(trunkParts, trunkPart)

        trunkCFrame = trunkCFrame * CFrame.new(0, segmentLength / 2, 0)
    end
    local trunk = trunkPart -- The last part is the top of the trunk

    -- Recursive function to generate the tree structure
    local function generateBranch(parentBranch, iter)
        if iter > MAX_ITERATIONS then
            -- Base case: create a leaf at the end of the branch
            local leaf = Instance.new("Part")
            leaf.Name = "Leaf"
            leaf.Shape = Enum.PartType.Ball
            leaf.Size = Vector3.new(1, 1, 1) * math.random(8, 12)
            leaf.Color = leafColor
            leaf.Material = Enum.Material.LeafyGrass
            leaf.Anchored = true
            leaf:PivotTo(parentBranch:GetPivot() * CFrame.new(parentBranch.Size.X, 0, 0))
            leaf.Parent = tree
            return
        end

        local progress = iter / MAX_ITERATIONS
        local baseAngle = math.lerp(10, BASE_ANGLE, progress) -- Start with a more upward angle
        local variation = 25 * (1 - progress * 0.7)
        local droopAngle = baseAngle + math.random(-variation, variation)
        -- Randomly orient the new branch around the parent
        local rotation = CFrame.Angles(
            math.random() * 2 * math.pi,
            math.rad(droopAngle),
            0
        )

        -- Create the new branch part
        local newBranch = Instance.new("Part")
        newBranch.Name = "Branch"
        newBranch.Shape = Enum.PartType.Block
        newBranch.Color = woodColor
        newBranch.Material = Enum.Material.Wood
        newBranch.Anchored = true

        local newWidth = parentBranch.Size.Y * math.random(70, 85) / 100
        local newLength = parentBranch.Size.X * math.random(85, 95) / 100
        newBranch.Size = Vector3.new(newLength, newWidth, newWidth)
        -- Set the pivot to the base of the branch
        newBranch.PivotOffset = CFrame.new(-newLength / 2, 0, 0)

        -- Position and orient the new branch at the end of the parent
        local parentPivot = parentBranch:GetPivot()
        local parentEnd = CFrame.new(parentBranch.Size.X, 0, 0)
        newBranch:PivotTo(parentPivot * parentEnd * rotation)
        newBranch.Parent = tree

        -- Continue growing the main branch
        generateBranch(newBranch, iter + 1)

        -- Probabilistically create side branches
        local chance = math.max(0.1, 1.2 - progress * 0.8)
        while math.random() < chance do
            generateBranch(newBranch, iter + 1)
            chance *= 0.6
        end
    end

    -- Create the initial main branches sprouting from the top of the trunk
    local trunkTopCFrame = trunk.CFrame * CFrame.new(0, trunk.Size.Y / 2, 0)
    local numMainBranches = math.random(3, 5)
    for i = 1, numMainBranches do
        -- Create the first branch part
        local startBranch = Instance.new("Part")
        startBranch.Name = "Branch"
        startBranch.Shape = Enum.PartType.Block
        startBranch.Color = woodColor
        startBranch.Material = Enum.Material.Wood
        startBranch.Anchored = true

        local startLength = trunkHeight * (math.random(40, 60) / 100)
        local startWidth = trunkRadius * (math.random(60, 80) / 100)
        startBranch.Size = Vector3.new(startLength, startWidth, startWidth)
        startBranch.PivotOffset = CFrame.new(-startLength / 2, 0, 0)

        -- Calculate a natural upward and outward angle for the first branches
        local upwardAngle = math.rad(math.random(30, 60))
        local horizontalAngle = math.rad(math.random(0, 360))
        local startRotation = CFrame.Angles(0, horizontalAngle, 0) * CFrame.Angles(0, 0, upwardAngle)

        startBranch:PivotTo(trunkTopCFrame * startRotation)
        startBranch.Parent = tree

        -- Start the recursive generation for this main branch
        generateBranch(startBranch, 1)
    end

    tree.PrimaryPart = trunk
    return tree
end

function NatureService.createFlower(position)
    local flower = Instance.new("Model")
    flower.Name = "Flower"
    flower.Parent = natureFolder

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

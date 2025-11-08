local NatureService = {}

function NatureService.generateWorld()
    print("Starting world generation...")
    local terrain = workspace.Terrain

    -- Generation parameters
    local xSize = 512 -- Increased size for a larger world
    local zSize = 512 -- Increased size for a larger world
    local seed = math.random(1, 1000)
    local baseHeight = -20

    -- Noise parameters for multiple layers
    local continentSmothness = 200
    local continentMultiplier = 100

    local mountainSmothness = 50
    local mountainMultiplier = 40

    local detailSmothness = 10
    local detailMultiplier = 5

    -- Create a height map to store the terrain data before rendering
    local heightMap = {}

    -- 1. Generate the base terrain heights and store them in the heightMap
    print("Generating height map...")
    for x = 1, xSize do
        heightMap[x] = {}
        for z = 1, zSize do
            if z % 50 == 0 then
                task.wait()
            end
            local worldX = x - xSize / 2
            local worldZ = z - zSize / 2

            -- Calculate each noise layer
            local continentNoise = (math.noise(worldX / continentSmothness, worldZ / continentSmothness, seed)) * continentMultiplier
            local mountainNoise = (math.noise(worldX / mountainSmothness, worldZ / mountainSmothness, seed + 1)) * mountainMultiplier
            local detailNoise = (math.noise(worldX / detailSmothness, worldZ / detailSmothness, seed + 2)) * detailMultiplier

            -- Combine the noise layers to get the final height
            heightMap[x][z] = continentNoise + mountainNoise + detailNoise
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
            if z % 50 == 0 then
                task.wait()
            end
            local y = heightMap[x][z]
            local worldX = x - xSize / 2
            local worldZ = z - zSize / 2

            -- Define the terrain block (column)
            local size = Vector3.new(4, y - baseHeight, 4)
            local position = Vector3.new(worldX * 4, baseHeight + size.Y / 2, worldZ * 4)
            local cframe = CFrame.new(position)

            -- Determine the material based on the height to create biomes
            local material
            if y > 50 then
                material = Enum.Material.Snow
            elseif y > 30 then
                material = Enum.Material.Rock
            elseif y > 0 then
                material = Enum.Material.Grass
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
    end
    print("World generation complete.")

    NatureService.generateTrees(heightMap, xSize, zSize, baseHeight)
end

function NatureService.generateTrees(heightMap, xSize, zSize, baseHeight)
    print("Generating trees...")
    local treeDensity = 0.05 -- 5% chance of a tree spawning in a valid location

    for x = 1, xSize do
        for z = 1, zSize do
            if math.random() < treeDensity then
                local y = heightMap[x][z]

                -- Only spawn trees on grass
                if y > 0 and y <= 30 then
                    local worldX = (x - xSize / 2) * 4
                    local worldZ = (z - zSize / 2) * 4
                    local groundPosition = Vector3.new(worldX, y + baseHeight, worldZ)

                    NatureService.createTree(groundPosition)
                end
            end
        end
    end
    print("Tree generation complete.")
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
    local tree = Instance.new("Model")
    tree.Name = "Tree"
    tree.Parent = workspace

    local trunk = Instance.new("Part")
    trunk.Name = "Trunk"
    trunk.Parent = tree
    trunk.Size = Vector3.new(2, 10, 2)
    trunk.Position = position + Vector3.new(0, trunk.Size.Y / 2, 0)
    trunk.Color = Color3.fromRGB(87, 56, 34) -- Brown
    trunk.Anchored = true

    local leaves = Instance.new("Part")
    leaves.Name = "Leaves"
    leaves.Parent = tree
    leaves.Size = Vector3.new(8, 6, 8)
    leaves.Position = trunk.Position + Vector3.new(0, trunk.Size.Y / 2, 0)
    leaves.Color = Color3.fromRGB(34, 139, 34) -- Forest Green
    leaves.Anchored = true

    tree.PrimaryPart = trunk
    return tree
end

return NatureService

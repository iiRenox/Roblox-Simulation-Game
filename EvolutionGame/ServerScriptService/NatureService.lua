local NatureService = {}

function NatureService.generateWorld()
    local terrain = workspace.Terrain

    -- Generation parameters
    local xSize = 256
    local zSize = 256
    local yMultiplier = 40
    local smoothness = 50
    local seed = math.random(1, 1000)
    local baseHeight = -20

    -- Create a grid of terrain heights
    for x = 1, xSize do
        for z = 1, zSize do
            -- Calculate the height at this point using Perlin noise
            local y = math.noise(x / smoothness, z / smoothness, seed) * yMultiplier

            -- Define the terrain block (column)
            local size = Vector3.new(4, y - baseHeight, 4)
            local position = Vector3.new(x * 4, baseHeight + size.Y / 2, z * 4)
            local cframe = CFrame.new(position)

            -- Fill the block with grass
            terrain:FillBlock(cframe, size, Enum.Material.Grass)
        end
    end
end

function NatureService.start()
    print("NatureService started")

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
end

return NatureService

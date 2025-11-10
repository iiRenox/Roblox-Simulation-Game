--!strict

local ServerScriptService = game:GetService("ServerScriptService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local WorldUtil = require(ReplicatedStorage.WorldUtil)
local Tree = require(ServerScriptService.Tree)
local Plant = require(ServerScriptService.Plant)
local TimeService = require(ServerScriptService.TimeService)

--- Manages the procedural generation of the world and the lifecycle of all flora.
-- This service is responsible for creating the terrain, rivers, and all plant life
-- (trees, bushes, flowers). It uses multiple layers of Perlin noise for realistic
-- landscapes and connects to the TimeService to handle the growth and reproduction
-- of plants over time.
local NatureService = {}

local natureFolder -- This will hold all the generated nature models
local activeTrees = {} -- Holds all the active Tree objects
local activePlants = {} -- Holds all the active Plant objects

--- Returns the list of all active non-tree plants (bushes, flowers, etc.).
-- @return table A list of all active Plant objects.
function NatureService.getActivePlants()
	return activePlants
end

-- Biome definitions
-- Biome definitions with secondary and tertiary materials for texture
local BIOMES = {
	JUNGLE = { materials = {Enum.Material.Grass, Enum.Material.LeafyGrass, Enum.Material.Mud}, foliageColor = Color3.fromRGB(34, 139, 34), density = 0.8 },
	DESERT = { materials = {Enum.Material.Sand, Enum.Material.Sandstone, Enum.Material.Rock}, foliageColor = Color3.fromRGB(210, 180, 140), density = 0.05 },
	FOREST = { materials = {Enum.Material.Grass, Enum.Material.LeafyGrass, Enum.Material.Ground}, foliageColor = Color3.fromRGB(46, 139, 87), density = 0.7 },
	PLAINS = { materials = {Enum.Material.Grass, Enum.Material.LeafyGrass, Enum.Material.Ground}, foliageColor = Color3.fromRGB(124, 252, 0), density = 0.2 },
	SWAMP = { materials = {Enum.Material.Mud, Enum.Material.Water, Enum.Material.Grass}, foliageColor = Color3.fromRGB(85, 107, 47), density = 0.4 },
	TUNDRA = { materials = {Enum.Material.Snow, Enum.Material.Ice, Enum.Material.Rock}, foliageColor = Color3.fromRGB(240, 248, 255), density = 0.1 },
	ARCTIC = { materials = {Enum.Material.Snow, Enum.Material.Ice, Enum.Material.Glacier}, foliageColor = Color3.fromRGB(255, 255, 255), density = 0.01 },
	MOUNTAIN = { materials = {Enum.Material.Rock, Enum.Material.Basalt, Enum.Material.Snow}, foliageColor = Color3.fromRGB(139, 137, 137), density = 0.05 },
	BEACH = { materials = {Enum.Material.Sand, Enum.Material.Rock, Enum.Material.Pavement}, foliageColor = Color3.fromRGB(250, 235, 215), density = 0.02 },
	WATER = { materials = {Enum.Material.Water, Enum.Material.Sand, Enum.Material.Rock}, foliageColor = Color3.fromRGB(0, 0, 139), density = 0.3 }
}

--- Determines the biome for a given location based on its elevation, temperature, and moisture.
-- @param y number The elevation of the point.
-- @param temperature number The temperature value (0-1).
-- @param moisture number The moisture value (0-1).
-- @return table The biome definition table from BIOMES.
local function getBiome(y, temperature, moisture)
	if y <= 0 then return BIOMES.WATER end
	if y <= 5 then return BIOMES.BEACH end
	if y > 180 then return BIOMES.ARCTIC end
	if y > 90 then return BIOMES.MOUNTAIN end

	if temperature > 0.6 then -- Hot
		if moisture > 0.5 then
			return BIOMES.JUNGLE
		else
			return BIOMES.DESERT
		end
	elseif temperature > 0.3 then -- Temperate
		if moisture > 0.5 then
			return BIOMES.FOREST
		else
			return BIOMES.PLAINS
		end
	else -- Cold
		if moisture > 0.5 then
			return BIOMES.SWAMP
		else
			return BIOMES.TUNDRA
		end
	end
end

--- Generates the entire game world, including terrain, biomes, rivers, and flora.
-- This is a multi-step process:
-- 1. A height map is generated using multiple layers of Perlin noise.
-- 2. New features like volcanoes and rivers are carved into the height map.
-- 3. The terrain is rendered block by block based on the final height map data.
-- 4. Trees, bushes, and other plants are spawned in appropriate locations.
-- 5. Ores are generated in underground clusters.
function NatureService.generateWorld()
	print("Starting world generation...")
	local terrain = workspace.Terrain

	-- Generation parameters (8192x8192 studs world)
	local xSize = 2048
	local zSize = 2048
	local seed = math.random(1, 1000)
	local baseHeight = -20

	-- Noise parameters for multiple layers
	local continentSmothness = 1000
	local continentMultiplier = 150

	local mountainSmothness = 200
	local mountainMultiplier = 300
	local mountainPower = 1.8

	local detailSmothness = 40
	local detailMultiplier = 15

	-- Biome noise parameters
	local temperatureSmothness = 1200
	local moistureSmothness = 900
	local textureSmothness = 25

	-- Create maps to store the generated data
	local heightMap = {}
	local temperatureMap = {}
	local moistureMap = {}

	-- 1. Generate the base terrain heights and biome data
	print("Generating height, temperature, and moisture maps...")
	for x = 1, xSize do
		heightMap[x] = {}
		temperatureMap[x] = {}
		moistureMap[x] = {}
		for z = 1, zSize do
			local worldX = x - xSize / 2
			local worldZ = z - zSize / 2

			-- Calculate height noise layers
			local continentNoise = (math.noise(worldX / continentSmothness, worldZ / continentSmothness, seed)) * continentMultiplier
			local mountainNoise = math.pow(math.abs(math.noise(worldX / mountainSmothness, worldZ / mountainSmothness, seed + 1)), mountainPower) * mountainMultiplier
			local detailNoise = (math.noise(worldX / detailSmothness, worldZ / detailSmothness, seed + 2)) * detailMultiplier

			-- Combine the noise layers to get the final height
			heightMap[x][z] = continentNoise + mountainNoise + detailNoise

			-- Generate temperature and moisture noise
			local temperatureNoise = (math.noise(worldX / temperatureSmothness, worldZ / temperatureSmothness, seed + 10) + 1) / 2
			local moistureNoise = (math.noise(worldX / moistureSmothness, worldZ / moistureSmothness, seed + 11) + 1) / 2
			temperatureMap[x][z] = temperatureNoise
			moistureMap[x][z] = moistureNoise
		end
		if x % 64 == 0 then task.wait() end
	end
	print("Map generation complete.")

	-- 2. Add geological features to the heightMap
	print("Generating volcanoes...")
	NatureService.generateVolcanoes(heightMap, xSize, zSize, seed)
	print("Generating rivers...")
	NatureService.generateRivers(heightMap, xSize, zSize)
	print("Geological feature generation complete.")

	-- 3. Render the terrain from the maps
	print("Rendering terrain...")
	for x = 1, xSize do
		for z = 1, zSize do
			local y = heightMap[x][z]
			local worldX = (x - xSize / 2) * 4
			local worldZ = (z - zSize / 2) * 4

			-- Determine the biome and material
			local biome = getBiome(y, temperatureMap[x][z], moistureMap[x][z])
			local textureNoise = (math.noise(worldX / textureSmothness, worldZ / textureSmothness, seed + 15) + 1) / 2

			local material
			if textureNoise > 0.8 then
				material = biome.materials[3] or biome.materials[1]
			elseif textureNoise > 0.6 then
				material = biome.materials[2] or biome.materials[1]
			else
				material = biome.materials[1]
			end

			-- Define the terrain block (column)
			local size = Vector3.new(4, y - baseHeight, 4)
			local position = Vector3.new(worldX, baseHeight + size.Y / 2, worldZ)

			-- If the material is water, fill it up to the sea level
			if material == Enum.Material.Water then
				local waterSize = Vector3.new(4, 0 - baseHeight, 4)
				local waterPosition = Vector3.new(worldX, baseHeight + waterSize.Y / 2, worldZ)
				terrain:FillBlock(CFrame.new(waterPosition), waterSize, Enum.Material.Water)
			else
				-- Fill the block with the determined material
				terrain:FillBlock(CFrame.new(position), size, material)
			end
		end
		if x % 64 == 0 then task.wait() end
	end
	print("Terrain rendering complete.")

	print("Spawning flora...")
	NatureService.generateFlora(xSize, zSize, seed, heightMap, temperatureMap, moistureMap)
	print("Flora spawning complete.")

	print("Generating ore veins...")
	NatureService.generateOres(xSize, zSize, seed)
	print("Ore generation complete.")

	print("Generating rock formations...")
	NatureService.generateRockFormations(xSize, zSize, seed)
	print("Rock formation generation complete.")

	print("World generation finished successfully.")
end

--- Generates small, decorative rock formations in appropriate biomes.
-- @param xSize number The width of the world grid.
-- @param zSize number The depth of the world grid.
-- @param seed number The random seed for Perlin noise.
function NatureService.generateRockFormations(xSize, zSize, seed)
	local rockSmothness = 30
	local rockThreshold = 0.75
	for x = 1, xSize, 10 do
		for z = 1, zSize, 10 do
			local worldX = (x - xSize / 2) * 4
			local worldZ = (z - zSize / 2) * 4

			local rockNoise = (math.noise(worldX / rockSmothness, worldZ / rockSmothness, seed + 16) + 1) / 2

			if rockNoise > rockThreshold then
				local groundPosition = WorldUtil.getGroundPosition(worldX, worldZ)
				if groundPosition then
					local material = WorldUtil.getMaterialAtPosition(groundPosition)
					if material == Enum.Material.Grass or material == Enum.Material.Sand then
						local rock = Instance.new("Part")
						local size = math.random(3, 7)
						rock.Name = "RockFormation"
						rock.Shape = Enum.PartType.Ball
						rock.Size = Vector3.new(size, size, size)
						rock.Position = groundPosition + Vector3.new(0, size/2, 0)
						rock.Material = Enum.Material.Rock
						rock.Color = Color3.fromRGB(139, 137, 137)
						rock.Anchored = true
						rock.Parent = natureFolder
					end
				end
			end
		end
		if x % 32 == 0 then task.wait() end
	end
end

--- Generates volcanoes on the heightmap.
-- @param heightMap table The 2D array of height data.
-- @param xSize number The width of the height map.
-- @param zSize number The depth of the height map.
-- @param seed number The random seed.
function NatureService.generateVolcanoes(heightMap, xSize, zSize, seed)
	local numVolcanoes = math.random(3, 6)
	for i = 1, numVolcanoes do
		local volcanoX = math.random(1, xSize)
		local volcanoZ = math.random(1, zSize)
		local volcanoRadius = math.random(40, 80)
		local volcanoHeight = heightMap[volcanoX][volcanoZ] + math.random(200, 350)
		local calderaRadius = volcanoRadius * 0.3

		for x = -volcanoRadius, volcanoRadius do
			for z = -volcanoRadius, volcanoRadius do
				local dist = math.sqrt(x*x + z*z)
				if dist < volcanoRadius then
					local currentX = volcanoX + x
					local currentZ = volcanoZ + z
					if currentX > 0 and currentX <= xSize and currentZ > 0 and currentZ <= zSize then
						-- Create a smoother cone shape
						local height = volcanoHeight * (1 - (dist / volcanoRadius)^2)
						height = height + math.noise(currentX / 25, currentZ / 25, seed + i) * 25

						-- Carve out the caldera
						if dist < calderaRadius then
							local calderaDepth = (volcanoHeight * 0.5) * (1 - (dist / calderaRadius))
							heightMap[currentX][currentZ] = math.max(heightMap[currentX][currentZ], height - calderaDepth)
						else
							heightMap[currentX][currentZ] = math.max(heightMap[currentX][currentZ], height)
						end
					end
				end
			end
		end
	end
end

--- Generates ore veins in the world.
-- @param xSize number The width of the world grid.
-- @param zSize number The depth of the world grid.
-- @param seed number The random seed for Perlin noise.
function NatureService.generateOres(xSize, zSize, seed)
	local oreSmothness = 20
	local oreThreshold = 0.7
	for x = 1, xSize, 8 do
		for z = 1, zSize, 8 do
			local worldX = (x - xSize / 2) * 4
			local worldZ = (z - zSize / 2) * 4

			local oreNoise = (math.noise(worldX / oreSmothness, worldZ / oreSmothness, seed + 12) + 1) / 2

			if oreNoise > oreThreshold then
				local groundPosition = WorldUtil.getGroundPosition(worldX, worldZ)
				if groundPosition and groundPosition.Y < 50 then -- Only generate ores underground
					local veinPosition = groundPosition - Vector3.new(math.random(-10, 10), math.random(10, 30), math.random(-10, 10))

					-- Create a cluster of ore parts
					for i=1, math.random(5, 12) do
						local orePart = Instance.new("Part")
						local size = math.random(4, 8)
						orePart.Name = "Ore"
						orePart.Shape = Enum.PartType.Ball
						orePart.Size = Vector3.new(size, size, size)
						orePart.Position = veinPosition + Vector3.new(math.random(-10, 10), math.random(-10, 10), math.random(-10, 10))
						orePart.Material = Enum.Material.Basalt
						orePart.Color = Color3.fromRGB(80, 80, 80)
						orePart.Anchored = true
						orePart.Parent = natureFolder
					end
				end
			end
		end
		if x % 32 == 0 then task.wait() end
	end
end

--- Populates the world with all types of flora based on biome rules.
-- @param xSize number The width of the world grid.
-- @param zSize number The depth of the world grid.
-- @param seed number The random seed for Perlin noise.
-- @param heightMap table The 2D array of height data.
-- @param temperatureMap table The 2D array of temperature data.
-- @param moistureMap table The 2D array of moisture data.
function NatureService.generateFlora(xSize, zSize, seed, heightMap, temperatureMap, moistureMap)
	local primordialTrees = 0
	local maxPrimordialTrees = 50

	for x = 1, xSize, 4 do
		for z = 1, zSize, 4 do
			local y = heightMap[x][z]
			local worldX = (x - xSize / 2) * 4
			local worldZ = (z - zSize / 2) * 4

			local biome = getBiome(y, temperatureMap[x][z], moistureMap[x][z])
			if biome.density > 0 and math.random() < biome.density then
				local groundPosition = WorldUtil.getGroundPosition(worldX, worldZ)
				if groundPosition then
					local material = WorldUtil.getMaterialAtPosition(groundPosition)

					if material == biome.material then
						local foliageNoise = (math.noise(worldX/50, worldZ/50, seed+5)+1)/2

						-- Spawn trees
						if primordialTrees < maxPrimordialTrees and (biome == BIOMES.FOREST or biome == BIOMES.JUNGLE) and foliageNoise > 0.6 then
							NatureService.createTree(groundPosition)
							primordialTrees += 1
						-- Spawn bushes
						elseif (biome == BIOMES.PLAINS or biome == BIOMES.FOREST) and foliageNoise > 0.5 then
							NatureService.createPlant(groundPosition, "Bush")
						-- Spawn flowers/mushrooms
						elseif (biome == BIOMES.PLAINS or biome == BIOMES.SWAMP) and foliageNoise < 0.4 then
							if biome == BIOMES.SWAMP then
								NatureService.createPlant(groundPosition, "Mushroom")
							else
								NatureService.createPlant(groundPosition, "Flower")
							end
						-- Spawn underwater plants
						elseif biome == BIOMES.WATER and material == Enum.Material.Water then
							NatureService.createPlant(groundPosition, "Seaweed")
						-- Spawn desert plants
						elseif biome == BIOMES.DESERT and foliageNoise > 0.7 then
							NatureService.createPlant(groundPosition, "Cactus")
						end
					end
				end
			end
		end
		if x % 32 == 0 then task.wait() end
	end
end

--- Initializes the NatureService.
-- This function runs the world generation in a separate coroutine so it doesn't
-- block the main game thread. It also connects the plant lifecycle updates to the
-- global `TimeService` tick.
-- @return Event A BindableEvent that fires when world generation is complete.
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

		-- Generate the new terrain and initial life
		NatureService.generateWorld()

		onFinished:Fire()
	end)()

	-- Connect to the game loop
	TimeService.getTick():Connect(function(deltaTime, season, day)
		-- Dynamic Terrain Proof-of-Concept: Volcano Eruption
		if day % 25 == 0 then -- Every 25 days
			-- This is a very simplified placeholder. A real implementation would
			-- need to properly find the volcano and add terrain more elegantly.
			print("A volcano is rumbling...")
			local lava = Instance.new("Part")
			lava.Shape = Enum.PartType.Ball
			lava.Size = Vector3.new(200, 200, 200)
			lava.Position = Vector3.new(0, 250, 0) -- Approximate volcano center
			lava.Material = Enum.Material.Lava
			lava.Anchored = true
			lava.CanCollide = false
			lava.Parent = workspace
			task.delay(10, function() lava:Destroy() end)
		end

		-- Iterate backwards to safely remove dead trees
		for i = #activeTrees, 1, -1 do
			local tree = activeTrees[i]
			local status = tree:grow(deltaTime)

			if status == "dead" then
				table.remove(activeTrees, i)
			elseif season == "Spring" then
				tree:reproduce()
			end
		end

		-- Iterate backwards to safely remove dead plants
		for i = #activePlants, 1, -1 do
			local plant = activePlants[i]
			local status = plant:grow(deltaTime)

			if status == "dead" then
				table.remove(activePlants, i)
			elseif season == "Spring" then
				plant:reproduce()
			end
		end
	end)

	return onFinished.Event
end

--- Carves river paths into the pre-generated height map.
-- It works by finding high-elevation points and then carving a path downwards
-- towards the sea level by always moving to the lowest neighboring point.
-- @param heightMap table The 2D array of height data.
-- @param xSize number The width of the height map.
-- @param zSize number The depth of the height map.
function NatureService.generateRivers(heightMap, xSize, zSize)
	local seaLevel = 0
	local numRivers = 25
	local riverDepth = 15

	for i = 1, numRivers do
		-- Find a random starting point for the river at a high elevation
		local startX, startZ
		local startHeight = -math.huge

		for _ = 1, 20 do -- Try 20 times to find a high point
			local tryX = math.random(1, xSize)
			local tryZ = math.random(1, zSize)
			if heightMap[tryX][tryZ] > 100 and heightMap[tryX][tryZ] > startHeight then
				startX = tryX
				startZ = tryZ
				startHeight = heightMap[tryX][tryZ]
			end
		end

		-- Carve the river path from the starting point
		if startX and startZ then
			local currentX = startX
			local currentZ = startZ
			while heightMap[currentX][currentZ] > seaLevel do
				heightMap[currentX][currentZ] = heightMap[currentX][currentZ] - riverDepth

				-- Carve a wider path
				for nx = -1, 1 do
					for nz = -1, 1 do
						local nextX, nextZ = currentX + nx, currentZ + nz
						if nextX > 0 and nextX <= xSize and nextZ > 0 and nextZ <= zSize then
							heightMap[nextX][nextZ] = heightMap[nextX][nextZ] - (riverDepth * 0.5)
						end
					end
				end

				-- Find the lowest neighbor to continue the path
				local lowestNeighborX, lowestNeighborZ = currentX, currentZ
				local lowestHeight = heightMap[currentX][currentZ]

				for nx = -1, 1 do
					for nz = -1, 1 do
						if not (nx == 0 and nz == 0) then
							local nextX = currentX + nx
							local nextZ = currentZ + nz

							if nextX > 0 and nextX <= xSize and nextZ > 0 and nextZ <= zSize and heightMap[nextX][nextZ] < lowestHeight then
								lowestHeight = heightMap[nextX][nextZ]
								lowestNeighborX = nextX
								lowestNeighborZ = nextZ
							end
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
end

--- Creates a new tree and adds it to the simulation.
-- @param position Vector3 The world position to spawn the tree at.
-- @return table The newly created Tree object.
function NatureService.createTree(position)
	return NatureService.createRegularTree(position)
end

--- Creates a new non-tree plant (bush, flower, etc.) and adds it to the simulation.
-- @param position Vector3 The world position to spawn the plant at.
-- @param plantType string The type of plant to create ("Bush", "Flower", "Seaweed", "Mushroom", "Cactus").
-- @return table? The newly created Plant object, or nil if the type is invalid.
function NatureService.createPlant(position, plantType)
	-- Create the generic plant object first to get its genome
	local plantObject = Plant.new(nil) -- Pass nil for model initially

	local model
	if plantType == "Bush" then
		model = NatureService.createBush(position, plantObject.genome)
	elseif plantType == "Flower" then
		model = NatureService.createFlower(position, plantObject.genome)
	elseif plantType == "Seaweed" then
		model = NatureService.createSeaweed(position)
	elseif plantType == "Mushroom" then
		model = NatureService.createMushroom(position)
	elseif plantType == "Cactus" then
		model = NatureService.createCactus(position)
	else
		return nil
	end

	plantObject.model = model -- Assign the created model back to the object
	table.insert(activePlants, plantObject)
	return plantObject
end

--- Creates a model for a seaweed plant.
-- @param position Vector3 The position to create the model at.
-- @return Model The generated seaweed model.
function NatureService.createSeaweed(position)
	local seaweed = Instance.new("Model")
	seaweed.Name = "Seaweed"
	seaweed.Parent = natureFolder

	local stalk = Instance.new("Part")
	stalk.Name = "Stalk"
	stalk.Parent = seaweed
	stalk.Shape = Enum.PartType.Block
	stalk.Size = Vector3.new(0.5, math.random(5, 10), 0.5)
	stalk.Position = position + Vector3.new(0, stalk.Size.Y / 2, 0)
	stalk.Color = Color3.fromRGB(22, 84, 46)
	stalk.Material = Enum.Material.LeafyGrass
	stalk.Anchored = true

	seaweed.PrimaryPart = stalk
	return seaweed
end

--- Creates a model for a cactus plant.
-- @param position Vector3 The position to create the model at.
-- @return Model The generated cactus model.
function NatureService.createCactus(position)
	local cactus = Instance.new("Model")
	cactus.Name = "Cactus"
	cactus.Parent = natureFolder

	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Parent = cactus
	trunk.Shape = Enum.PartType.Block
	local height = math.random(5, 12)
	trunk.Size = Vector3.new(2, height, 2)
	trunk.Position = position + Vector3.new(0, height/2, 0)
	trunk.Color = Color3.fromRGB(0, 100, 0)
	trunk.Material = Enum.Material.Grass
	trunk.Anchored = true

	cactus.PrimaryPart = trunk
	return cactus
end

--- Creates a model for a mushroom plant.
-- @param position Vector3 The position to create the model at.
-- @return Model The generated mushroom model.
function NatureService.createMushroom(position)
	local mushroom = Instance.new("Model")
	mushroom.Name = "Mushroom"
	mushroom.Parent = natureFolder

	local stem = Instance.new("Part")
	stem.Name = "Stem"
	stem.Parent = mushroom
	stem.Shape = Enum.PartType.Cylinder
	stem.Size = Vector3.new(1, 1, 1)
	stem.Position = position + Vector3.new(0, 0.5, 0)
	stem.Color = Color3.fromRGB(220, 220, 220)
	stem.Material = Enum.Material.Plastic
	stem.Anchored = true

	local cap = Instance.new("Part")
	cap.Name = "Cap"
	cap.Parent = mushroom
	cap.Shape = Enum.PartType.Ball
	cap.Size = Vector3.new(2.5, 2, 2.5)
	cap.Position = stem.Position + Vector3.new(0, 1, 0)
	cap.Color = Color3.fromRGB(255, 0, 0)
	cap.Material = Enum.Material.Plastic
	cap.Anchored = true

	mushroom.PrimaryPart = cap
	return mushroom
end

--- Creates a model for a bush plant.
--- Creates a model for a bush plant based on its genome.
-- @param position Vector3 The position to create the model at.
-- @param genome table The plant's genome.
-- @return Model The generated bush model.
function NatureService.createBush(position, genome)
	local bush = Instance.new("Model")
	bush.Name = "Bush"
	bush.Parent = natureFolder

	local stump = Instance.new("Part")
	stump.Name = "Stump"
	stump.Parent = bush
	stump.Shape = Enum.PartType.Cylinder
	stump.Size = Vector3.new(2, 1, 2)
	stump.Position = position + Vector3.new(0, 0.5, 0)
	stump.Color = Color3.fromRGB(87, 56, 34)
	stump.Material = Enum.Material.Wood
	stump.Anchored = true

	local leaves = Instance.new("Part")
	leaves.Name = "Leaves"
	leaves.Parent = bush
	leaves.Shape = Enum.PartType.Ball
	local leafSize = genome.maxSize
	leaves.Size = Vector3.new(leafSize, leafSize, leafSize)
	leaves.Position = position + Vector3.new(0, leafSize / 2, 0)
	-- Toxic plants get a purplish tint
	leaves.Color = if genome.toxicity > 0.5 then Color3.fromRGB(138, 43, 226) else Color3.fromRGB(34, 139, 34)
	leaves.Material = Enum.Material.LeafyGrass
	leaves.Anchored = true

	-- Thorny plants get spikes
	if genome.thorniness > 0.5 then
		for i=1, 8 do
			local spike = Instance.new("Part")
			spike.Name = "Thorn"
			spike.Shape = Enum.PartType.Block
			spike.Size = Vector3.new(0.5, genome.thorniness * 3, 0.5)
			spike.Color = Color3.new(0.2, 0.2, 0.2)
			spike.Anchored = true
			spike.CFrame = CFrame.new(leaves.Position) * CFrame.Angles(math.random()*math.pi*2, math.random()*math.pi*2, math.random()*math.pi*2) * CFrame.new(0, leafSize/2, 0)
			spike.Parent = bush
		end
	end

	bush.PrimaryPart = leaves
	return bush
end

--- Creates a model for a flower plant based on its genome.
-- @param position Vector3 The position to create the model at.
-- @param genome table The plant's genome.
-- @return Model The generated flower model.
function NatureService.createFlower(position, genome)
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
	petal.Size = Vector3.new(genome.maxSize * 0.3, genome.maxSize * 0.3, genome.maxSize * 0.3)
	petal.Position = stem.Position + Vector3.new(0, 0.5, 0)
	-- Toxicity affects the flower's color, making it darker and less vibrant
	petal.Color = if genome.toxicity > 0.5 then Color3.fromHSV(math.random(), 0.5, 0.4) else Color3.fromHSV(math.random(), 1, 1)
	petal.Anchored = true

	flower.PrimaryPart = stem
	return flower
end

--- Creates a complex, organic-looking tree model using a recursive algorithm.
-- The tree features a gnarled, multi-part trunk and fractal-based branches,
-- resulting in a natural and varied appearance.
-- @param position Vector3 The position to create the model at.
-- @return table The newly created Tree object.
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
	local trunk = trunkParts[1] -- The first part is the base of the trunk

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

	-- Create and register the Tree object
	local treeObject = Tree.new(tree)
	table.insert(activeTrees, treeObject)

	-- The Tree class will handle the initial scaling
	return treeObject
end

return NatureService

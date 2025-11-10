--!strict

local ServerScriptService = game:GetService("ServerScriptService")

local TimeService = require(ServerScriptService.TimeService)
local AnimalService = require(ServerScriptService.AnimalService)
local NatureService = require(ServerScriptService.NatureService)

--- Manages the collection and storage of simulation data over time.
-- This service connects to the TimeService and, on a daily interval, it gathers
-- statistics about the populations of all living entities, creating a historical
-- record of the world's evolution.
local DataService = {}

local simulationData = {} -- Stores the historical data for the simulation
local dayCounter = 0
local lastTickDay = 0

--- Returns the collected simulation data.
-- @return table The historical data of the simulation.
function DataService.getSimulationData()
    return simulationData
end

--- The main update loop for the data collection service.
-- Fires on every tick, but only collects data once per in-game day.
-- @param _ number The time elapsed since the last frame.
function DataService.onTick(_, _, day)
    if day > lastTickDay then
        lastTickDay = day

        local dailyData = {
            day = day,
            populations = {},
            averageGenomes = {}
        }

        -- Collect Animal Data
        local activeAnimals = AnimalService.getActiveAnimals()
        dailyData.populations.Animals = #activeAnimals

        local animalGenomeSums = {}
        if #activeAnimals > 0 then
            for _, animal in ipairs(activeAnimals) do
                for trait, value in pairs(animal.genome) do
                    if type(value) == "number" then
                        animalGenomeSums[trait] = (animalGenomeSums[trait] or 0) + value
                    end
                end
            end

            dailyData.averageGenomes.Animals = {}
            for trait, sum in pairs(animalGenomeSums) do
                dailyData.averageGenomes.Animals[trait] = sum / #activeAnimals
            end
        end

        -- Collect Plant Data
        local activePlants = NatureService.getActivePlants()
        local plantPopulations = {}
        local plantGenomeSums = {}

        for _, plant in ipairs(activePlants) do
            local plantType = plant.model.Name
            plantPopulations[plantType] = (plantPopulations[plantType] or 0) + 1

            if not plantGenomeSums[plantType] then plantGenomeSums[plantType] = {} end

            for trait, value in pairs(plant.genome) do
                if type(value) == "number" then
                    plantGenomeSums[plantType][trait] = (plantGenomeSums[plantType][trait] or 0) + value
                end
            end
        end

        dailyData.populations.Plants = plantPopulations
        dailyData.averageGenomes.Plants = {}
        for plantType, sums in pairs(plantGenomeSums) do
            dailyData.averageGenomes.Plants[plantType] = {}
            for trait, sum in pairs(sums) do
                 dailyData.averageGenomes.Plants[plantType][trait] = sum / plantPopulations[plantType]
            end
        end

        table.insert(simulationData, dailyData)
        print("DataService: Logged data for day " .. day)
    end
end

--- Initializes the DataService.
function DataService.start()
    print("DataService started")
    local ReplicatedStorage = game:GetService("ReplicatedStorage")

    ReplicatedStorage.RequestSimulationData.OnServerInvoke = DataService.getSimulationData

    TimeService.getTick():Connect(DataService.onTick)
end

return DataService

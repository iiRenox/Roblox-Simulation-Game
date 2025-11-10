--!strict

local RunService = game:GetService("RunService")

--- Manages the global game clock, simulation speed, and the main update loop.
-- This service is the central heartbeat of the simulation. It provides a global `tick`
-- event that all other dynamic services connect to. It also manages the day/night cycle,
-- seasonal changes, and allows the simulation speed to be adjusted.
local TimeService = {}

local simulationSpeed = 1 -- Multiplier for the tick rate
local timeOfDay = 0 -- 0 to 24 hours
local day = 1
local season = "Spring" -- Spring, Summer, Autumn, Winter
local daysPerSeason = 2 -- How many in-game days each season lasts
local isPaused = false

local speedTiers = {0.1, 1, 10, 100}
local currentSpeedIndex = 2 -- Start at 1x speed

-- This is the main event that will drive the entire simulation
local onTick = Instance.new("BindableEvent")

--- Cycles through the available simulation speed tiers.
-- The speed tiers are 0.1x, 1x, 10x, and 100x.
function TimeService.changeSpeed()
    currentSpeedIndex = (currentSpeedIndex % #speedTiers) + 1
    simulationSpeed = speedTiers[currentSpeedIndex]
    print("Simulation speed changed to:", simulationSpeed .. "x")
end

--- Returns the BindableEvent used as the main simulation tick.
-- Other services can connect to this event to synchronize their updates.
-- @return Event The tick event.
function TimeService.getTick()
    return onTick.Event
end

--- Initializes the TimeService.
-- It sets up the remote event for changing simulation speed and starts the main
-- update loop by connecting to the `RunService.Heartbeat` event.
function TimeService.start()
    print("TimeService started")

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local changeSpeedEvent = Instance.new("RemoteEvent")
    changeSpeedEvent.Name = "ChangeSpeedEvent"
    changeSpeedEvent.Parent = ReplicatedStorage

    changeSpeedEvent.OnServerEvent:Connect(function(player)
        TimeService.changeSpeed()
    end)

    ReplicatedStorage.ToggleSimulation.OnServerEvent:Connect(function()
        isPaused = not isPaused
        print("Simulation is now", isPaused and "paused" or "resumed")
    end)

    -- Connect to the Heartbeat event, which fires every frame
    RunService.Heartbeat:Connect(function(deltaTime)
        if isPaused then return end -- Halt the simulation if paused

        local scaledDeltaTime = deltaTime * simulationSpeed

        -- Increment the time of day
        timeOfDay = (timeOfDay + scaledDeltaTime / 30) % 24 -- /30 to make days last a bit longer

        -- Check for a new day
        if timeOfDay < 0.1 and math.abs(timeOfDay - (scaledDeltaTime / 30)) > 1 then
            day = day + 1
            print("A new day has begun. Day:", day)

            -- Check for a new season
            local seasonIndex = math.floor((day - 1) / daysPerSeason) % 4 + 1
            local seasons = {"Spring", "Summer", "Autumn", "Winter"}
            if seasons[seasonIndex] ~= season then
                season = seasons[seasonIndex]
                print("The season is now " .. season)
            end
        end

        -- Fire the tick event, passing the scaled delta time, the current season, and the day
        onTick:Fire(scaledDeltaTime, season, day)
    end)
end

return TimeService

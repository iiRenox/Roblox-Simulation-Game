--!strict
-- TimeService
-- Manages the global game clock, simulation speed, and the main update loop.

local TimeService = {}

local RunService = game:GetService("RunService")

local simulationSpeed = 1 -- Multiplier for the tick rate
local timeOfDay = 0 -- 0 to 24 hours
local day = 1
local season = "Spring" -- Spring, Summer, Autumn, Winter
local daysPerSeason = 2 -- How many in-game days each season lasts

local speedTiers = {0.1, 1, 10, 100}
local currentSpeedIndex = 2 -- Start at 1x speed

-- This is the main event that will drive the entire simulation
local onTick = Instance.new("BindableEvent")

function TimeService.changeSpeed()
    currentSpeedIndex = (currentSpeedIndex % #speedTiers) + 1
    simulationSpeed = speedTiers[currentSpeedIndex]
    print("Simulation speed changed to:", simulationSpeed .. "x")
end

function TimeService.getTick()
    return onTick.Event
end

function TimeService.start()
    print("TimeService started")

    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local changeSpeedEvent = Instance.new("RemoteEvent")
    changeSpeedEvent.Name = "ChangeSpeedEvent"
    changeSpeedEvent.Parent = ReplicatedStorage

    changeSpeedEvent.OnServerEvent:Connect(function(player)
        TimeService.changeSpeed()
    end)

    -- Connect to the Heartbeat event, which fires every frame
    RunService.Heartbeat:Connect(function(deltaTime)
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

        -- Fire the tick event, passing the scaled delta time and the current season
        onTick:Fire(scaledDeltaTime, season)
    end)
end

return TimeService

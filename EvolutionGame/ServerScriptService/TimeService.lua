--!strict
-- TimeService
-- Manages the global game clock, simulation speed, and the main update loop.

local TimeService = {}

local RunService = game:GetService("RunService")

local simulationSpeed = 1 -- Multiplier for the tick rate
local timeOfDay = 0 -- 0 to 24 hours
local day = 1
local season = "Spring" -- Spring, Summer, Autumn, Winter
local seasonLength = 120 -- seconds per season

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
        -- Increment the time of day, scaled by our simulation speed
        timeOfDay = (timeOfDay + (deltaTime * simulationSpeed)) % 24

        -- A simple day counter
        if timeOfDay < 0.1 then -- A new day has started
            day = day + 1
        end

        -- Season cycle
        local totalSeconds = day * 24 * 60 * 60 + timeOfDay * 60 * 60
        local seasonIndex = math.floor(totalSeconds / seasonLength) % 4 + 1
        local seasons = {"Spring", "Summer", "Autumn", "Winter"}
        if seasons[seasonIndex] ~= season then
            season = seasons[seasonIndex]
            print("The season is now " .. season)
        end

        -- Fire the tick event, passing the scaled delta time and the current season
        onTick:Fire(deltaTime * simulationSpeed, season)
    end)
end

return TimeService

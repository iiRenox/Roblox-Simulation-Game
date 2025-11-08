--!strict
-- GameSpeedController
-- Handles the player's interaction with the game speed UI.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- UI Elements
local screenGui = script.Parent
local speedButton = Instance.new("TextButton")

-- RemoteEvent for communication
local changeSpeedEvent = Instance.new("RemoteEvent")
changeSpeedEvent.Name = "ChangeSpeedEvent"
changeSpeedEvent.Parent = ReplicatedStorage

function setupUI()
    speedButton.Name = "SpeedButton"
    speedButton.Text = "Speed: 1x"
    speedButton.Size = UDim2.new(0, 150, 0, 50)
    speedButton.Position = UDim2.new(1, -160, 0, 10)
    speedButton.Parent = screenGui

    local speedTiers = {0.1, 1, 10, 100}
    local currentSpeedIndex = 2

    speedButton.MouseButton1Click:Connect(function()
        currentSpeedIndex = (currentSpeedIndex % #speedTiers) + 1
        speedButton.Text = "Speed: " .. speedTiers[currentSpeedIndex] .. "x"
        changeSpeedEvent:FireServer()
    end)
end

setupUI()

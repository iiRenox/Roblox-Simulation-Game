--!strict
-- GameSpeedController
-- Handles the player's interaction with the game speed UI.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- RemoteEvent for communication
local changeSpeedEvent = ReplicatedStorage:WaitForChild("ChangeSpeedEvent")

function setupUI()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GameSpeedGui"
    screenGui.Parent = playerGui

    local speedButton = Instance.new("TextButton")
    speedButton.Name = "SpeedButton"
    speedButton.Size = UDim2.new(0, 150, 0, 50)
    speedButton.Position = UDim2.new(1, -160, 0, 10)
    speedButton.Parent = screenGui

    local speedTiers = {0.1, 1, 10, 100}
    local currentSpeedIndex = 2 -- Start at 1x

    speedButton.Text = "Speed: " .. speedTiers[currentSpeedIndex] .. "x"

    speedButton.MouseButton1Click:Connect(function()
        currentSpeedIndex = (currentSpeedIndex % #speedTiers) + 1
        speedButton.Text = "Speed: " .. speedTiers[currentSpeedIndex] .. "x"
        changeSpeedEvent:FireServer()
    end)
end

setupUI()

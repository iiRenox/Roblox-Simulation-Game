--!strict

--- Handles the player's interaction with the game speed user interface.
-- This client-side script creates a button that allows the player to cycle through
-- different simulation speeds (0.1x, 1x, 10x, 100x). When clicked, it updates the
-- button's text and fires a RemoteEvent to notify the server of the change.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- RemoteEvent for communication
local changeSpeedEvent = ReplicatedStorage:WaitForChild("ChangeSpeedEvent")

--- Creates and manages the UI elements for controlling game speed.
-- This function builds the ScreenGui, the TextButton, and handles the
-- client-side logic for updating the UI and firing the server event.
local function setupUI()
    local playerGui = Players.LocalPlayer:WaitForChild("PlayerGui")

    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "GameSpeedGui"
    screenGui.Parent = playerGui

    local speedButton = Instance.new("TextButton")
    speedButton.Name = "SpeedButton"
    speedButton.Size = UDim2.new(0, 150, 0, 50)
    speedButton.Position = UDim2.new(1, -160, 0, 10)
    speedButton.Text = "Speed: 1x"
    speedButton.Parent = screenGui

    -- This table must be kept in sync with the one in TimeService
    local speedTiers = {0.1, 1, 10, 100}
    local currentSpeedIndex = 2 -- Start at 1x

    speedButton.MouseButton1Click:Connect(function()
        -- Cycle to the next speed tier
        currentSpeedIndex = (currentSpeedIndex % #speedTiers) + 1
        speedButton.Text = "Speed: " .. speedTiers[currentSpeedIndex] .. "x"

        -- Notify the server to change the actual simulation speed
        changeSpeedEvent:FireServer()
    end)
end

setupUI()

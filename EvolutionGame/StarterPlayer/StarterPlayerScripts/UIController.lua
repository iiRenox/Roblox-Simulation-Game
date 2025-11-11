--!strict

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Wait for communication channels to exist
local toggleSimulationEvent = ReplicatedStorage:WaitForChild("ToggleSimulation")
local requestDataFunction = ReplicatedStorage:WaitForChild("RequestSimulationData")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local mainScreen = Instance.new("ScreenGui")
mainScreen.Name = "SimulationUI"
mainScreen.Parent = playerGui

-- Create a frame for the control buttons
local controlFrame = Instance.new("Frame")
controlFrame.Size = UDim2.new(0.2, 0, 0.1, 0)
controlFrame.Position = UDim2.new(0.8, 0, 0.9, 0)
controlFrame.BackgroundColor3 = Color3.new(0, 0, 0)
controlFrame.BackgroundTransparency = 0.5
controlFrame.Parent = mainScreen

local pauseButton = Instance.new("TextButton")
pauseButton.Name = "PauseButton"
pauseButton.Size = UDim2.new(0.45, 0, 0.8, 0)
pauseButton.Position = UDim2.new(0.025, 0, 0.1, 0)
pauseButton.Text = "Pause"
pauseButton.Parent = controlFrame

local endButton = Instance.new("TextButton")
endButton.Name = "EndButton"
endButton.Size = UDim2.new(0.45, 0, 0.8, 0)
endButton.Position = UDim2.new(0.525, 0, 0.1, 0)
endButton.Text = "End Simulation"
endButton.Parent = controlFrame

-- Create the data display screen (initially hidden)
local dataScreen = Instance.new("Frame")
dataScreen.Name = "DataScreen"
dataScreen.Size = UDim2.new(0.8, 0, 0.8, 0)
dataScreen.Position = UDim2.new(0.1, 0, 0.1, 0)
dataScreen.BackgroundColor3 = Color3.new(0.1, 0.1, 0.1)
dataScreen.BackgroundTransparency = 0.2
dataScreen.Visible = false
dataScreen.Parent = mainScreen

local graphFrame = Instance.new("Frame")
graphFrame.Name = "GraphFrame"
graphFrame.Size = UDim2.new(0.9, 0, 0.9, 0)
graphFrame.Position = UDim2.new(0.05, 0, 0.05, 0)
graphFrame.Parent = dataScreen

-- --- A simple function to draw a line between two points.
local function drawLine(startPos, endPos, parent)
	local line = Instance.new("Frame")
	line.AnchorPoint = Vector2.new(0, 0.5)
	line.Size = UDim2.new(0, (endPos - startPos).Magnitude, 0, 2)
	line.Position = UDim2.new(0, startPos.X, 0, startPos.Y)
	line.Rotation = math.deg(math.atan2(endPos.Y - startPos.Y, endPos.X - startPos.X))
	line.BackgroundColor3 = Color3.new(1, 1, 1)
	line.BorderSizePixel = 0
	line.Parent = parent
	return line
end

-- --- Renders a graph based on the provided data.
local function renderGraph(data, key)
	graphFrame:ClearAllChildren()

	local points = {}
	local maxValue = 0
	for _, dailyData in ipairs(data) do
		local value = dailyData.populations[key] or 0
		if value > maxValue then maxValue = value end
		table.insert(points, value)
	end

	if #points < 2 then return end

	local frameSize = graphFrame.AbsoluteSize
	local xIncrement = frameSize.X / (#points - 1)

	for i = 1, #points - 1 do
		local y1 = frameSize.Y - (points[i] / maxValue) * frameSize.Y
		local y2 = frameSize.Y - (points[i+1] / maxValue) * frameSize.Y
		drawLine(Vector2.new((i-1) * xIncrement, y1), Vector2.new(i * xIncrement, y2), graphFrame)
	end
end


-- Event Handlers
pauseButton.MouseButton1Click:Connect(function()
	toggleSimulationEvent:FireServer()
	pauseButton.Text = (pauseButton.Text == "Pause") and "Resume" or "Pause"
end)

local isEnding = false
endButton.MouseButton1Click:Connect(function()
	if isEnding then return end
	isEnding = true

	-- Don't pause immediately, let it run for a moment to collect final data
	endButton.Text = "Ending..."
	endButton.AutoButtonColor = false
	pauseButton.AutoButtonColor = false


	task.wait(2) -- Wait for 2 seconds to ensure at least one more data point is gathered

	toggleSimulationEvent:FireServer() -- Now pause the sim

	local data = requestDataFunction:InvokeServer()
	if data and #data > 0 then
		renderGraph(data, "Animals")
		dataScreen.Visible = true
	else
		warn("No data, or not enough data, received from server for graph.")
	end
end)

print("UIController.lua loaded.")

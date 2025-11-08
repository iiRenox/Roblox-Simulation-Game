--!strict
-- Pathfinding Module
-- Provides pathfinding services for entities.

local PathfindingService = game:GetService("PathfindingService")

local Pathfinding = {}

local pathfindingSettings = {
    AgentRadius = 2,
    AgentHeight = 5,
    AgentCanJump = true,
    Costs = {
        Water = math.huge -- Avoid water
    }
}

function Pathfinding.computePath(startPosition, endPosition)
    local path = PathfindingService:CreatePath(pathfindingSettings)
    path:ComputeAsync(startPosition, endPosition)
    return path
end

function Pathfinding.followPath(humanoid, path)
    if path.Status == Enum.PathStatus.Success then
        for _, waypoint in ipairs(path:GetWaypoints()) do
            humanoid:MoveTo(waypoint.Position)
            humanoid.MoveToFinished:Wait()
        end
    end
end

return Pathfinding

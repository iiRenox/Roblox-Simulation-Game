--!strict

local PathfindingService = game:GetService("PathfindingService")

--- A reusable module for handling AI pathfinding.
-- This module wraps Roblox's PathfindingService to provide a simplified and
-- consistent interface for entities like Animals and NPCs to navigate the world.
-- It includes predefined settings to ensure characters avoid obstacles like water.
local Pathfinding = {}

-- Default pathfinding parameters for most land-based entities.
local pathfindingSettings = {
    AgentRadius = 2,
    AgentHeight = 5,
    AgentCanJump = true,
    Costs = {
        Water = math.huge -- Avoid water
    }
}

--- Computes a path between two points.
-- @param startPosition Vector3 The starting position of the path.
-- @param endPosition Vector3 The destination of the path.
-- @return Path The computed path object.
function Pathfinding.computePath(startPosition, endPosition)
    local path = PathfindingService:CreatePath(pathfindingSettings)
    path:ComputeAsync(startPosition, endPosition)
    return path
end

--- Commands a Humanoid to follow a pre-computed path.
-- It iterates through all waypoints in the path and moves the humanoid sequentially.
-- @param humanoid Humanoid The humanoid to move.
-- @param path Path The path object to follow.
function Pathfinding.followPath(humanoid, path)
    if path.Status == Enum.PathStatus.Success then
        for _, waypoint in ipairs(path:GetWaypoints()) do
            humanoid:MoveTo(waypoint.Position)
            humanoid.MoveToFinished:Wait()
        end
    end
end

return Pathfinding

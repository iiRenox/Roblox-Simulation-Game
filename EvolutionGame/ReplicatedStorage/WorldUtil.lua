--!strict

--- A module containing utility functions for interacting with the game world.
-- This module provides helper functions for common world-related tasks, such as
-- finding ground positions and identifying terrain materials, ensuring that
-- complex or error-prone operations are centralized and handled safely.
local WorldUtil = {}

--- Finds the precise ground position on the terrain at a given (X, Z) coordinate.
-- It performs a raycast downwards from a safe height to accurately determine the
-- surface level of the terrain. This is the preferred method for placing objects
-- on the ground.
-- @param x number The world-space X-coordinate.
-- @param z number The world-space Z-coordinate.
-- @return Vector3? The Vector3 position of the ground, or nil if no ground is found beneath the given coordinates.
function WorldUtil.getGroundPosition(x, z)
    -- Raycast to find the ground height, starting from a safe height above the max terrain height
    local origin = Vector3.new(x, 200, z)
    local direction = Vector3.new(0, -400, 0)

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {workspace.Terrain}
    raycastParams.FilterType = Enum.RaycastFilterType.Whitelist

    local raycastResult = workspace:Raycast(origin, direction, raycastParams)

    if raycastResult then
        return raycastResult.Position
    else
        return nil -- No ground found
    end
end

--- Retrieves the terrain material at a specific world position.
-- This function correctly handles the 4-stud voxel grid alignment required by Roblox's
-- terrain system to prevent errors when reading voxel data.
-- @param position Vector3 The world position to check.
-- @return Enum.Material The terrain material at the specified position.
function WorldUtil.getMaterialAtPosition(position)
    -- Align the position to the 4-stud voxel grid
    local alignedPosition = Vector3.new(
        math.floor(position.X / 4) * 4,
        math.floor(position.Y / 4) * 4,
        math.floor(position.Z / 4) * 4
    )

    -- Create a 4x4x4 region centered on the aligned position
    local region = Region3.new(alignedPosition, alignedPosition + Vector3.new(4, 4, 4))
    region = region:ExpandToGrid(4)

    -- Read the voxel data
    local materials = workspace.Terrain:ReadVoxels(region, 4)

    return materials[1][1][1]
end

return WorldUtil

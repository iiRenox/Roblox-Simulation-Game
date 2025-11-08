local WorldUtil = {}

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

function WorldUtil.getMaterialAtPosition(position)
    -- Align the position to the 4-stud voxel grid
    local alignedPosition = Vector3.new(
        math.floor(position.X / 4) * 4,
        math.floor(position.Y / 4) * 4,
        math.floor(position.Z / 4) * 4
    )

    -- Create a 4x4x4 region centered on the aligned position
    local region = Region3.new(alignedPosition, alignedPosition + Vector3.new(4, 4, 4))

    -- Read the voxel data
    local materials = workspace.Terrain:ReadVoxels(region, 4)

    return materials[1][1][1]
end

return WorldUtil

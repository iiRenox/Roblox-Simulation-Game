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

return WorldUtil

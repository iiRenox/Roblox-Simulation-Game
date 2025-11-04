local WorldUtil = {}

function WorldUtil.getGroundPosition(x, z)
    -- Raycast to find the ground height, starting from a safe height above the max terrain height
    local origin = Vector3.new(x, 200, z)
    local direction = Vector3.new(0, -400, 0)
    print("Raycasting from " .. tostring(origin) .. " in direction " .. tostring(direction))

    local raycastParams = RaycastParams.new()
    raycastParams.FilterDescendantsInstances = {workspace.Terrain}
    raycastParams.FilterType = Enum.RaycastFilterType.Whitelist

    local raycastResult = workspace:Raycast(origin, direction, raycastParams)

    if raycastResult then
        print("Raycast hit at: " .. tostring(raycastResult.Position))
        return raycastResult.Position
    else
        print("Raycast did not hit anything.")
        return nil -- No ground found
    end
end

return WorldUtil

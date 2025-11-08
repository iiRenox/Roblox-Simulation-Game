local LightingService = {}

function LightingService.setup()
    local lighting = game:GetService("Lighting")

    -- Basic properties
    lighting.Ambient = Color3.fromRGB(128, 128, 128)
    lighting.Brightness = 2
    lighting.ColorShift_Top = Color3.fromRGB(255, 230, 200)
    lighting.ColorShift_Bottom = Color3.fromRGB(150, 180, 255)
    lighting.OutdoorAmbient = Color3.fromRGB(128, 128, 128)
    lighting.GlobalShadows = true
    lighting.ShadowSoftness = 0.5
    lighting.GeographicLatitude = 23.5 -- Tilt the sun for more interesting shadows

    -- Atmosphere for a sense of depth
    local atmosphere = Instance.new("Atmosphere")
    atmosphere.Parent = lighting
    atmosphere.Density = 0.3
    atmosphere.Offset = 0.5
    atmosphere.Color = Color3.fromRGB(190, 210, 255)
    atmosphere.Decay = Color3.fromRGB(100, 120, 150)

    -- Sky
    local sky = Instance.new("Sky")
    sky.Parent = lighting
    sky.SkyboxAsphalt = true
    sky.SkyboxUp = true
    sky.SkyboxBk = true
    sky.SkyboxDn = true
    sky.SkyboxFt = true
    sky.SkyboxLf = true
    sky.SkyboxRt = true
    sky.SunAngularSize = 10
    sky.SunTextureId = "rbxassetid://123456789" -- Placeholder, will be replaced with a suitable texture
    sky.MoonTextureId = "rbxassetid://987654321" -- Placeholder

    -- Day/night cycle
    lighting.ClockTime = 14 -- Afternoon
    local dayNightCycle = Instance.new("Script")
    dayNightCycle.Parent = lighting
    dayNightCycle.Source = [[
        while wait(1) do
            game.Lighting.ClockTime = game.Lighting.ClockTime + 0.01
        end
    ]]
end

return LightingService

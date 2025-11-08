local ServerScriptService = game:GetService("ServerScriptService")
local TimeService = require(ServerScriptService.TimeService)

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
    sky.SunAngularSize = 10
    -- NOTE: Using a procedural sky for now, so no skybox textures are needed.
    -- sky.SunTextureId = "rbxassetid://..."
    -- sky.MoonTextureId = "rbxassetid://..."

    -- Post-processing effects for a more vibrant look
    local bloom = Instance.new("BloomEffect")
    bloom.Parent = lighting
    bloom.Intensity = 0.2
    bloom.Size = 24
    bloom.Threshold = 0.8

    local colorCorrection = Instance.new("ColorCorrectionEffect")
    colorCorrection.Parent = lighting
    colorCorrection.TintColor = Color3.fromRGB(255, 245, 235)
    colorCorrection.Brightness = 0.1
    colorCorrection.Contrast = 0.15
    colorCorrection.Saturation = 0.1

    local sunRays = Instance.new("SunRaysEffect")
    sunRays.Parent = lighting
    sunRays.Intensity = 0.1
    sunRays.Spread = 0.5

    -- Day/night cycle is now driven by TimeService
    TimeService.getTick():Connect(function(deltaTime, season)
        lighting.ClockTime = lighting.ClockTime + deltaTime
    end)
end

return LightingService

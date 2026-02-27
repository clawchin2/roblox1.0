-- PlatformModule - Simple and reliable
local Platform = {}
Platform.__index = Platform

Platform.Types = {
    STATIC = "static",
    MOVING = "moving",
    FADING = "fading",
}

function Platform.CreatePlatform(platformType, position, parent)
    local part = Instance.new("Part")
    part.Name = "Platform"
    part.Size = Vector3.new(12, 1, 12)
    part.Position = position
    part.Anchored = true
    part.CanCollide = true
    
    if platformType == Platform.Types.MOVING then
        part.Color = Color3.fromRGB(100, 150, 255)
    elseif platformType == Platform.Types.FADING then
        part.Color = Color3.fromRGB(255, 200, 100)
    else
        part.Color = Color3.fromRGB(150, 150, 150)
    end
    
    part.Parent = parent or workspace
    return part
end

return Platform
-- PlatformModule
local Platform = {}

function Platform.Create(position, parent)
    local part = Instance.new("Part")
    part.Size = Vector3.new(12, 1, 12)
    part.Position = position
    part.Anchored = true
    part.Color = Color3.fromRGB(150, 150, 150)
    part.Material = Enum.Material.SmoothPlastic
    part.Parent = parent
    return part
end

return Platform
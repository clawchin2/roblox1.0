-- Lobby Placeholder
-- Simple lobby area with instructions

local lobby = Instance.new("Model")
lobby.Name = "LobbyModel"

-- Base plate
local base = Instance.new("Part")
base.Name = "LobbyBase"
base.Size = Vector3.new(50, 1, 50)
base.Position = Vector3.new(0, 9.5, 0)
base.Anchored = true
base.Color = Color3.fromRGB(100, 100, 100)
base.Material = Enum.Material.Concrete
base.Parent = lobby

-- Instruction sign
local sign = Instance.new("Part")
sign.Name = "Instructions"
sign.Size = Vector3.new(20, 10, 1)
sign.Position = Vector3.new(0, 15, -20)
sign.Anchored = true
sign.Color = Color3.fromRGB(50, 50, 60)
sign.Parent = lobby

return lobby
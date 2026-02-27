-- Camera Controller
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

camera.CameraType = Enum.CameraType.Custom

local function updateCamera()
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Simple follow camera
    local targetPos = hrp.Position + Vector3.new(0, 15, 25)
    camera.CFrame = CFrame.new(targetPos, hrp.Position)
end

RunService.RenderStepped:Connect(updateCamera)

print("[CameraController] Started")
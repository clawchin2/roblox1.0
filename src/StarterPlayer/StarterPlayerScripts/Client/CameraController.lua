-- Camera Controller
-- Smooth follow camera for endless runner

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CameraController = {}
CameraController.offset = Vector3.new(0, 15, 25)
CameraController.lookOffset = Vector3.new(0, 0, -10)
CameraController.smoothSpeed = 0.1

function CameraController.init()
    camera.CameraType = Enum.CameraType.Scriptable
    
    RunService.RenderStepped:Connect(function()
        local character = player.Character
        if not character then return end
        
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if not hrp then return end
        
        local targetPos = hrp.Position + CameraController.offset
        local targetLook = hrp.Position + CameraController.lookOffset
        
        camera.CFrame = camera.CFrame:Lerp(CFrame.new(targetPos, targetLook), CameraController.smoothSpeed)
    end)
end

return CameraController
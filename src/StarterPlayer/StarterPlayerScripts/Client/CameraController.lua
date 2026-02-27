-- Camera Controller
-- Smooth follow camera for endless runner with dynamic positioning

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local camera = workspace.CurrentCamera

local CameraController = {}

-- Camera configuration
CameraController.offset = Vector3.new(15, 12, 20)      -- Behind and above player
CameraController.lookOffset = Vector3.new(0, 2, -15)   -- Look ahead of player
CameraController.smoothSpeed = 0.08                    -- Smooth lerp factor (lower = smoother)
CameraController.rotationDamping = 0.05                -- Rotation smoothness

-- Runtime state
CameraController.targetFov = 70
CameraController.currentFov = 70
CameraController.lastHrpPosition = nil
CameraController.velocityOffset = Vector3.new(0, 0, 0)

function CameraController.init()
    print("[CameraController] Initializing smooth follow camera...")
    
    camera.CameraType = Enum.CameraType.Scriptable
    camera.FieldOfView = CameraController.targetFov
    
    -- Setup render stepped connection for smooth camera
    RunService.RenderStepped:Connect(function(deltaTime)
        CameraController.update(deltaTime)
    end)
    
    print("[CameraController] Camera initialized - smooth follow active")
end

function CameraController.update(deltaTime)
    local character = player.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Calculate player velocity for dynamic offset
    local velocity = Vector3.new(0, 0, 0)
    if CameraController.lastHrpPosition then
        velocity = (hrp.Position - CameraController.lastHrpPosition) / math.max(deltaTime, 0.001)
    end
    CameraController.lastHrpPosition = hrp.Position
    
    -- Dynamic offset based on velocity (lean into movement)
    local targetVelocityOffset = Vector3.new(
        math.clamp(velocity.X * 0.1, -5, 5),
        0,
        math.clamp(velocity.Z * 0.05, -3, 3)
    )
    CameraController.velocityOffset = CameraController.velocityOffset:Lerp(targetVelocityOffset, 0.1)
    
    -- Calculate target camera position (behind player at angle)
    local baseOffset = CameraController.offset
    local angleOffset = Vector3.new(
        baseOffset.X + math.sin(tick() * 0.5) * 2,  -- Subtle sway
        baseOffset.Y,
        baseOffset.Z
    )
    
    local targetPos = hrp.Position + angleOffset + CameraController.velocityOffset
    local targetLook = hrp.Position + CameraController.lookOffset
    
    -- Smooth lerp to target position
    local targetCFrame = CFrame.new(targetPos, targetLook)
    local smoothFactor = math.clamp(CameraController.smoothSpeed * (deltaTime * 60), 0.01, 0.3)
    camera.CFrame = camera.CFrame:Lerp(targetCFrame, smoothFactor)
    
    -- Smooth FOV adjustment based on speed
    local speed = velocity.Magnitude
    CameraController.targetFov = 70 + math.clamp((speed - 16) * 0.5, 0, 15)
    CameraController.currentFov = CameraController.currentFov + (CameraController.targetFov - CameraController.currentFov) * 0.05
    camera.FieldOfView = CameraController.currentFov
end

function CameraController.setOffset(newOffset)
    CameraController.offset = newOffset
end

function CameraController.reset()
    camera.CFrame = CFrame.new(Vector3.new(0, 50, 100), Vector3.new(0, 0, 0))
end

return CameraController

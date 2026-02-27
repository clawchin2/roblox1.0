-- Camera
local player = game.Players.LocalPlayer
local camera = workspace.CurrentCamera

camera.CameraType = Enum.CameraType.Scriptable

game:GetService("RunService").RenderStepped:Connect(function()
    local char = player.Character
    if not char then return end
    
    local hrp = char:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    camera.CFrame = CFrame.new(hrp.Position + Vector3.new(0, 15, 25), hrp.Position)
end)
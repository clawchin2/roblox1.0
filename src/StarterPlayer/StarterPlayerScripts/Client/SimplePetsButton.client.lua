-- SimplePetsButton.client.lua
-- Minimal test - just creates a PETS button

local player = game.Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

print("[SimplePets] Starting...")

-- Wait for GameUI
local gameUI = gui:WaitForChild("GameUI", 5)
if not gameUI then
	warn("[SimplePets] GameUI not found!")
	return
end

print("[SimplePets] GameUI found, creating button...")

-- Create simple button
local btn = Instance.new("TextButton")
btn.Name = "PetsButton"
btn.Size = UDim2.new(0, 100, 0, 40)
btn.Position = UDim2.new(0, 10, 0, 100)
btn.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
btn.Text = "PETS"
btn.TextSize = 18
btn.Parent = gameUI

btn.MouseButton1Click:Connect(function()
	print("[SimplePets] Button clicked!")
end)

print("[SimplePets] Button created!")
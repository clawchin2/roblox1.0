-- UI Controller - Simple and reliable
local Players = game:GetService("Players")
local player = Players.LocalPlayer

-- Wait for PlayerGui
local playerGui = player:WaitForChild("PlayerGui")

-- Remove old UI if exists
local old = playerGui:FindFirstChild("GameUI")
if old then old:Destroy() end

-- Create new UI
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameUI"
screenGui.ResetOnSpawn = false -- CRITICAL: Don't reset on death
screenGui.Parent = playerGui

-- Score Display (TOP CENTER)
local scoreLabel = Instance.new("TextLabel")
scoreLabel.Name = "ScoreLabel"
scoreLabel.Size = UDim2.new(0, 300, 0, 60)
scoreLabel.Position = UDim2.new(0.5, -150, 0, 20)
scoreLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
scoreLabel.BackgroundTransparency = 0.3
scoreLabel.Text = "0m"
scoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
scoreLabel.TextSize = 40
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.Parent = screenGui

-- Round corners
local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 15)
corner.Parent = scoreLabel

-- Update loop
local lastScore = 0

while true do
    task.wait(0.1)
    
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local score = leaderstats:FindFirstChild("Score")
        if score then
            if score.Value ~= lastScore then
                lastScore = score.Value
                scoreLabel.Text = tostring(lastScore) .. "m"
                
                -- Pulse animation on milestone
                if lastScore % 100 == 0 and lastScore > 0 then
                    scoreLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
                    task.wait(0.5)
                    scoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end
        end
    end
end
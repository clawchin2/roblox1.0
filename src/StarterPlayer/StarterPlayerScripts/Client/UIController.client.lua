-- Simple UI Controller
local Players = game:GetService("Players")
local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create ScreenGui
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "GameUI"
screenGui.Parent = playerGui

-- Score Display
local scoreFrame = Instance.new("Frame")
scoreFrame.Name = "ScoreFrame"
scoreFrame.Size = UDim2.new(0, 200, 0, 50)
scoreFrame.Position = UDim2.new(0.5, -100, 0, 20)
scoreFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
scoreFrame.BackgroundTransparency = 0.5
scoreFrame.BorderSizePixel = 0
scoreFrame.Parent = screenGui

local scoreCorner = Instance.new("UICorner")
scoreCorner.CornerRadius = UDim.new(0, 10)
scoreCorner.Parent = scoreFrame

local scoreLabel = Instance.new("TextLabel")
scoreLabel.Name = "ScoreLabel"
scoreLabel.Size = UDim2.new(1, 0, 1, 0)
scoreLabel.BackgroundTransparency = 1
scoreLabel.Text = "0m"
scoreLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
scoreLabel.TextScaled = true
scoreLabel.Font = Enum.Font.GothamBold
scoreLabel.Parent = scoreFrame

-- Update score display
local function updateScore()
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local score = leaderstats:FindFirstChild("Score")
        if score then
            scoreLabel.Text = score.Value .. "m"
        end
    end
end

-- Check every frame
while true do
    task.wait(0.1)
    updateScore()
end
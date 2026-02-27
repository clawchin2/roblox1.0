-- UI
local player = game.Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

local screen = Instance.new("ScreenGui")
screen.Name = "UI"
screen.ResetOnSpawn = false
screen.Parent = gui

local label = Instance.new("TextLabel")
label.Size = UDim2.new(0, 200, 0, 50)
label.Position = UDim2.new(0.5, -100, 0, 20)
label.BackgroundTransparency = 0.5
label.Text = "0m"
label.TextSize = 36
label.Parent = screen

while true do
    task.wait(0.1)
    
    local s = player:FindFirstChild("leaderstats")
    if s then
        local sc = s:FindFirstChild("Score")
        if sc then
            label.Text = sc.Value .. "m"
        end
    end
end
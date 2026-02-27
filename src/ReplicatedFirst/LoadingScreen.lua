-- Loading Screen
-- Shown while game loads

local Players = game:GetService("Players")
local ReplicatedFirst = game:GetService("ReplicatedFirst")
local TweenService = game:GetService("TweenService")

ReplicatedFirst:RemoveDefaultLoadingScreen()

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create loading screen
local screenGui = Instance.new("ScreenGui")
screenGui.Name = "LoadingScreen"
screenGui.Parent = playerGui

local frame = Instance.new("Frame")
frame.Size = UDim2.new(1, 0, 1, 0)
frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
frame.BorderSizePixel = 0
frame.Parent = screenGui

local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(0, 400, 0, 80)
title.Position = UDim2.new(0.5, -200, 0.4, 0)
title.BackgroundTransparency = 1
title.Text = "ENDLESS ESCAPE"
title.TextColor3 = Color3.fromRGB(255, 100, 100)
title.TextScaled = true
title.Font = Enum.Font.GothamBold
title.Parent = frame

local subtitle = Instance.new("TextLabel")
subtitle.Name = "Subtitle"
subtitle.Size = UDim2.new(0, 400, 0, 40)
subtitle.Position = UDim2.new(0.5, -200, 0.5, 0)
subtitle.BackgroundTransparency = 1
subtitle.Text = "Loading..."
subtitle.TextColor3 = Color3.fromRGB(200, 200, 200)
subtitle.TextScaled = true
subtitle.Font = Enum.Font.Gotham
subtitle.Parent = frame

local progressBar = Instance.new("Frame")
progressBar.Name = "ProgressBar"
progressBar.Size = UDim2.new(0, 400, 0, 10)
progressBar.Position = UDim2.new(0.5, -200, 0.6, 0)
progressBar.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
progressBar.BorderSizePixel = 0
progressBar.Parent = frame

local fill = Instance.new("Frame")
fill.Name = "Fill"
fill.Size = UDim2.new(0, 0, 1, 0)
fill.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
fill.BorderSizePixel = 0
fill.Parent = progressBar

-- Animate loading
local contentLoaded = false
task.spawn(function()
    for i = 1, 100 do
        if contentLoaded then break end
        fill.Size = UDim2.new(i/100, 0, 1, 0)
        task.wait(0.03)
    end
end)

-- Wait for game content
repeat task.wait() until game:IsLoaded()
contentLoaded = true
fill.Size = UDim2.new(1, 0, 1, 0)

task.wait(0.5)

-- Fade out
local tween = TweenService:Create(frame, TweenInfo.new(0.5), {BackgroundTransparency = 1})
tween:Play()
tween.Completed:Wait()

screenGui:Destroy()
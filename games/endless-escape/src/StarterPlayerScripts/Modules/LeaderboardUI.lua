--!strict
-- LeaderboardUI.lua
-- Client-side leaderboard display
-- Location: StarterPlayerScripts/Modules/LeaderboardUI.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer

-- RemoteEvents
local LeaderboardEvents = ReplicatedStorage:WaitForChild("LeaderboardEvents")
local GetLeaderboard = LeaderboardEvents:WaitForChild("GetLeaderboard") :: RemoteFunction
local LeaderboardUpdateEvent = LeaderboardEvents:WaitForChild("LeaderboardUpdate")

local LeaderboardUI = {}

-- ============================================================================
-- UI CREATION
-- ============================================================================

local screenGui = player.PlayerGui:FindFirstChild("EndlessEscapeUI") :: ScreenGui
if not screenGui then
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "EndlessEscapeUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player.PlayerGui
end

-- Main frame
local lbFrame = Instance.new("Frame")
lbFrame.Name = "Leaderboard"
lbFrame.Size = UDim2.new(0, 400, 0, 500)
lbFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
lbFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
lbFrame.BorderSizePixel = 0
lbFrame.Visible = false
lbFrame.ZIndex = 100
lbFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = lbFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 80, 160)
stroke.Thickness = 3
stroke.Parent = lbFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 15)
title.BackgroundTransparency = 1
title.Text = "🏆 LEADERBOARD"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.TextSize = 28
title.Font = Enum.Font.GothamBlack
title.ZIndex = 101
title.Parent = lbFrame

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "Close"
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 10)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
closeBtn.TextSize = 28
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 101
closeBtn.Parent = lbFrame

-- Tab buttons
local globalTab = Instance.new("TextButton")
globalTab.Name = "GlobalTab"
globalTab.Size = UDim2.new(0, 100, 0, 30)
globalTab.Position = UDim2.new(0, 30, 0, 65)
globalTab.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
globalTab.Text = "Global"
globalTab.TextColor3 = Color3.new(1, 1, 1)
globalTab.TextSize = 14
globalTab.Font = Enum.Font.GothamBold
globalTab.ZIndex = 101
globalTab.Parent = lbFrame

local weeklyTab = Instance.new("TextButton")
weeklyTab.Name = "WeeklyTab"
weeklyTab.Size = UDim2.new(0, 100, 0, 30)
weeklyTab.Position = UDim2.new(0, 140, 0, 65)
weeklyTab.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
weeklyTab.Text = "Weekly"
weeklyTab.TextColor3 = Color3.fromRGB(180, 180, 180)
weeklyTab.TextSize = 14
weeklyTab.Font = Enum.Font.GothamBold
weeklyTab.ZIndex = 101
weeklyTab.Parent = lbFrame

local tabCorner1 = Instance.new("UICorner")
tabCorner1.CornerRadius = UDim.new(0, 6)
tabCorner1.Parent = globalTab

local tabCorner2 = Instance.new("UICorner")
tabCorner2.CornerRadius = UDim.new(0, 6)
tabCorner2.Parent = weeklyTab

-- Your rank display
local rankFrame = Instance.new("Frame")
rankFrame.Name = "YourRank"
rankFrame.Size = UDim2.new(1, -40, 0, 50)
rankFrame.Position = UDim2.new(0, 20, 0, 105)
rankFrame.BackgroundColor3 = Color3.fromRGB(40, 60, 100)
rankFrame.BorderSizePixel = 0
rankFrame.ZIndex = 101
rankFrame.Parent = lbFrame

local rankCorner = Instance.new("UICorner")
rankCorner.CornerRadius = UDim.new(0, 8)
rankCorner.Parent = rankFrame

local rankLabel = Instance.new("TextLabel")
rankLabel.Size = UDim2.new(1, 0, 1, 0)
rankLabel.BackgroundTransparency = 1
rankLabel.Text = "Your Best: Loading..."
rankLabel.TextColor3 = Color3.new(1, 1, 1)
rankLabel.TextSize = 16
rankLabel.Font = Enum.Font.GothamBold
rankLabel.ZIndex = 102
rankLabel.Parent = rankFrame

-- Scrolling list
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "LeaderboardList"
scrollFrame.Size = UDim2.new(1, -40, 0, 330)
scrollFrame.Position = UDim2.new(0, 20, 0, 165)
scrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ZIndex = 101
scrollFrame.Parent = lbFrame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 12)
scrollCorner.Parent = scrollFrame

-- List layout
local listLayout = Instance.new("UIListLayout")
listLayout.Padding = UDim.new(0, 5)
listLayout.SortOrder = Enum.SortOrder.LayoutOrder
listLayout.Parent = scrollFrame

-- ============================================================================
-- STATE
-- ============================================================================

local currentTab = "Global"
local leaderboardData = nil

-- ============================================================================
-- DISPLAY FUNCTIONS
-- ============================================================================

local function clearList()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function createEntry(rank: number, name: string, distance: number, isPlayer: boolean): Frame
	local entry = Instance.new("Frame")
	entry.Name = "Entry_" .. tostring(rank)
	entry.Size = UDim2.new(1, -10, 0, 40)
	entry.LayoutOrder = rank
	entry.BackgroundColor3 = isPlayer 
		and Color3.fromRGB(60, 100, 60) 
		or (rank % 2 == 1 and Color3.fromRGB(45, 45, 65) or Color3.fromRGB(40, 40, 60))
	entry.BorderSizePixel = 0
	entry.ZIndex = 102
	
	local entryCorner = Instance.new("UICorner")
	entryCorner.CornerRadius = UDim.new(0, 6)
	entryCorner.Parent = entry
	
	-- Rank number
	local rankNum = Instance.new("TextLabel")
	rankNum.Size = UDim2.new(0, 40, 1, 0)
	rankNum.Position = UDim2.new(0, 10, 0, 0)
	rankNum.BackgroundTransparency = 1
	
	-- Crown for top 3
	if rank == 1 then
		rankNum.Text = "👑"
		rankNum.TextColor3 = Color3.fromRGB(255, 215, 0)
	elseif rank == 2 then
		rankNum.Text = "🥈"
		rankNum.TextColor3 = Color3.fromRGB(192, 192, 192)
	elseif rank == 3 then
		rankNum.Text = "🥉"
		rankNum.TextColor3 = Color3.fromRGB(205, 127, 50)
	else
		rankNum.Text = "#" .. tostring(rank)
		rankNum.TextColor3 = Color3.fromRGB(200, 200, 200)
	end
	
	rankNum.TextSize = 18
	rankNum.Font = Enum.Font.GothamBold
	rankNum.ZIndex = 103
	rankNum.Parent = entry
	
	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Size = UDim2.new(0, 180, 1, 0)
	nameLabel.Position = UDim2.new(0, 55, 0, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = name
	nameLabel.TextColor3 = isPlayer and Color3.fromRGB(150, 255, 150) or Color3.new(1, 1, 1)
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.Gotham
	nameLabel.TextXAlignment = Enum.TextXAlignment.Left
	nameLabel.ZIndex = 103
	nameLabel.Parent = entry
	
	-- Distance
	local distLabel = Instance.new("TextLabel")
	distLabel.Size = UDim2.new(0, 100, 1, 0)
	distLabel.Position = UDim2.new(1, -110, 0, 0)
	distLabel.BackgroundTransparency = 1
	distLabel.Text = tostring(math.floor(distance)) .. "m"
	distLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	distLabel.TextSize = 16
	distLabel.Font = Enum.Font.GothamBold
	distLabel.TextXAlignment = Enum.TextXAlignment.Right
	distLabel.ZIndex = 103
	distLabel.Parent = entry
	
	return entry
end

local function populateGlobal()
	clearList()
	if not leaderboardData then return end
	
	for i, entry in ipairs(leaderboardData.global) do
		if i > 100 then break end
		local card = createEntry(i, entry.name, entry.distance, entry.userId == player.UserId)
		card.Parent = scrollFrame
	end
end

local function populateWeekly()
	clearList()
	if not leaderboardData then return end
	
	for i, entry in ipairs(leaderboardData.weekly) do
		local card = createEntry(i, entry.name, entry.distance, entry.userId == player.UserId)
		card.Parent = scrollFrame
	end
end

local function updateDisplay()
	if currentTab == "Global" then
		populateGlobal()
	else
		populateWeekly()
	end
	
	-- Update rank display
	if leaderboardData and leaderboardData.rank then
		rankLabel.Text = string.format("Your Rank: #%d | Best: %dm", 
			leaderboardData.rank, math.floor(player:GetAttribute("PersonalBest") or 0))
	else
		rankLabel.Text = "Your Best: " .. tostring(math.floor(player:GetAttribute("PersonalBest") or 0)) .. "m"
	end
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

globalTab.MouseButton1Click:Connect(function()
	currentTab = "Global"
	globalTab.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
	globalTab.TextColor3 = Color3.new(1, 1, 1)
	weeklyTab.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
	weeklyTab.TextColor3 = Color3.fromRGB(180, 180, 180)
	updateDisplay()
end)

weeklyTab.MouseButton1Click:Connect(function()
	currentTab = "Weekly"
	weeklyTab.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
	weeklyTab.TextColor3 = Color3.new(1, 1, 1)
	globalTab.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
	globalTab.TextColor3 = Color3.fromRGB(180, 180, 180)
	updateDisplay()
end)

closeBtn.MouseButton1Click:Connect(function()
	lbFrame.Visible = false
end)

-- Server updates
LeaderboardUpdateEvent.OnClientEvent:Connect(function(data)
	if leaderboardData then
		leaderboardData.global = data.global
		leaderboardData.weekly = data.weekly
		updateDisplay()
	end
end)

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function LeaderboardUI:Show()
	leaderboardData = GetLeaderboard:InvokeServer()
	updateDisplay()
	lbFrame.Visible = true
end

function LeaderboardUI:Hide()
	lbFrame.Visible = false
end

function LeaderboardUI:Toggle()
	if lbFrame.Visible then
		LeaderboardUI:Hide()
	else
		LeaderboardUI:Show()
	end
end

return LeaderboardUI

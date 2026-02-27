--!strict
-- BackgroundClient.client.lua
-- Client-side background effects and zone notifications
-- Location: StarterPlayerScripts/Client/BackgroundClient.client.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Wait for background events
local BackgroundEvents = ReplicatedStorage:WaitForChild("BackgroundEvents")
local ZoneChangeEvent = BackgroundEvents:WaitForChild("ZoneChange")
local MilestoneReachedEvent = BackgroundEvents:WaitForChild("MilestoneReached")

-- ============================================================================
-- UI CREATION
-- ============================================================================

local function createZoneNotification(zoneName: string, minDist: number, maxDist: number)
	-- Create screen GUI if not exists
	local screenGui = playerGui:FindFirstChild("ZoneNotificationGui")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "ZoneNotificationGui"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = playerGui
	end
	
	-- Create notification frame
	local frame = Instance.new("Frame")
	frame.Name = "ZoneNotification"
	frame.Size = UDim2.new(0, 400, 0, 100)
	frame.Position = UDim2.new(0.5, -200, 0, -150) -- Start above screen
	frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	frame.BackgroundTransparency = 0.2
	frame.BorderSizePixel = 0
	frame.Parent = screenGui
	
	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = frame
	
	-- Stroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 200, 255)
	stroke.Thickness = 3
	stroke.Parent = frame
	
	-- Zone name label
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.5, 0)
	titleLabel.Position = UDim2.new(0, 0, 0, 5)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "You entered the"
	titleLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	titleLabel.TextSize = 20
	titleLabel.Font = Enum.Font.Gotham
	titleLabel.Parent = frame
	
	-- Zone name (big)
	local zoneLabel = Instance.new("TextLabel")
	zoneLabel.Name = "ZoneName"
	zoneLabel.Size = UDim2.new(1, 0, 0.5, -5)
	zoneLabel.Position = UDim2.new(0, 0, 0.5, 0)
	zoneLabel.BackgroundTransparency = 1
	zoneLabel.Text = zoneName:upper()
	zoneLabel.TextColor3 = Color3.fromRGB(100, 220, 255)
	zoneLabel.TextSize = 32
	zoneLabel.Font = Enum.Font.GothamBold
	zoneLabel.Parent = frame
	
	-- Animate in
	local tweenIn = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -200, 0, 50)
	})
	tweenIn:Play()
	
	-- Wait and animate out
	task.delay(4, function()
		local tweenOut = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Position = UDim2.new(0.5, -200, 0, -150)
		})
		tweenOut:Play()
		tweenOut.Completed:Wait()
		frame:Destroy()
	end)
end

local function createMilestoneNotification(milestoneName: string, distance: number)
	-- Create screen GUI if not exists
	local screenGui = playerGui:FindFirstChild("MilestoneNotificationGui")
	if not screenGui then
		screenGui = Instance.new("ScreenGui")
		screenGui.Name = "MilestoneNotificationGui"
		screenGui.ResetOnSpawn = false
		screenGui.Parent = playerGui
	end
	
	-- Create notification frame (larger, more epic)
	local frame = Instance.new("Frame")
	frame.Name = "MilestoneNotification"
	frame.Size = UDim2.new(0, 500, 0, 150)
	frame.Position = UDim2.new(0.5, -250, 0.5, -75)
	frame.BackgroundColor3 = Color3.fromRGB(40, 20, 60)
	frame.BackgroundTransparency = 0.1
	frame.BorderSizePixel = 0
	frame.Parent = screenGui
	
	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 16)
	corner.Parent = frame
	
	-- Gradient stroke effect
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 200, 100)
	stroke.Thickness = 4
	stroke.Parent = frame
	
	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "Title"
	titleLabel.Size = UDim2.new(1, 0, 0.3, 0)
	titleLabel.Position = UDim2.new(0, 0, 0.1, 0)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🏆 MILESTONE REACHED! 🏆"
	titleLabel.TextColor3 = Color3.fromRGB(255, 220, 100)
	titleLabel.TextSize = 24
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = frame
	
	-- Milestone name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "MilestoneName"
	nameLabel.Size = UDim2.new(1, 0, 0.35, 0)
	nameLabel.Position = UDim2.new(0, 0, 0.4, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = milestoneName
	nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	nameLabel.TextSize = 36
	nameLabel.Font = Enum.Font.GothamBlack
	nameLabel.Parent = frame
	
	-- Distance
	local distLabel = Instance.new("TextLabel")
	distLabel.Name = "Distance"
	distLabel.Size = UDim2.new(1, 0, 0.25, 0)
	distLabel.Position = UDim2.new(0, 0, 0.75, 0)
	distLabel.BackgroundTransparency = 1
	distLabel.Text = tostring(distance) .. " meters"
	distLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	distLabel.TextSize = 20
	distLabel.Font = Enum.Font.Gotham
	distLabel.Parent = frame
	
	-- Animate scale in
	frame.Size = UDim2.new(0, 0, 0, 0)
	local tweenIn = TweenService:Create(frame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 500, 0, 150)
	})
	tweenIn:Play()
	
	-- Flash effect
	local flash = Instance.new("Frame")
	flash.Name = "Flash"
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	flash.BackgroundTransparency = 0
	flash.BorderSizePixel = 0
	flash.Parent = frame
	
	local flashTween = TweenService:Create(flash, TweenInfo.new(0.5), {
		BackgroundTransparency = 1
	})
	flashTween:Play()
	flashTween.Completed:Wait()
	flash:Destroy()
	
	-- Wait and animate out
	task.delay(5, function()
		local tweenOut = TweenService:Create(frame, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.In), {
			Size = UDim2.new(0, 0, 0, 0)
		})
		tweenOut:Play()
		tweenOut.Completed:Wait()
		frame:Destroy()
	end)
end

-- ============================================================================
-- SKYBOX SETUP
-- ============================================================================

local function setupSkybox()
	-- Create or find Sky
	local sky = Lighting:FindFirstChildOfClass("Sky")
	if not sky then
		sky = Instance.new("Sky")
		sky.Parent = Lighting
	end
	
	-- Set daytime sky initially
	sky.SkyboxBk = "rbxassetid://52643431"
	sky.SkyboxDn = "rbxassetid://52643454"
	sky.SkyboxFt = "rbxassetid://52643499"
	sky.SkyboxLf = "rbxassetid://52643515"
	sky.SkyboxRt = "rbxassetid://52643538"
	sky.SkyboxUp = "rbxassetid://52643556"
	sky.StarCount = 3000
end

-- ============================================================================
-- EVENT CONNECTIONS
-- ============================================================================

ZoneChangeEvent.OnClientEvent:Connect(function(zoneName: string, minDist: number, maxDist: number)
	print("[BackgroundClient] Zone changed to: " .. zoneName)
	createZoneNotification(zoneName, minDist, maxDist)
end)

MilestoneReachedEvent.OnClientEvent:Connect(function(milestoneName: string, distance: number)
	print("[BackgroundClient] Milestone reached: " .. milestoneName)
	createMilestoneNotification(milestoneName, distance)
end)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

setupSkybox()
print("[BackgroundClient] Ready!")

--!strict
-- LuckySpinUI.lua
-- Client-side lucky spin wheel interface
-- Location: StarterPlayerScripts/Modules/LuckySpinUI.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage.Shared.Config)

-- RemoteEvents
local SpinEvents = ReplicatedStorage:WaitForChild("SpinEvents")
local GetSpinInfo = SpinEvents:WaitForChild("GetSpinInfo") :: RemoteFunction
local RequestSpin = SpinEvents:WaitForChild("RequestSpin") :: RemoteFunction
local SpinResultEvent = SpinEvents:WaitForChild("SpinResult")
local SpinAvailableEvent = SpinEvents:WaitForChild("SpinAvailable")

local LuckySpinUI = {}

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

-- Main spin frame
local spinFrame = Instance.new("Frame")
spinFrame.Name = "LuckySpin"
spinFrame.Size = UDim2.new(0, 450, 0, 500)
spinFrame.Position = UDim2.new(0.5, -225, 0.5, -250)
spinFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
spinFrame.BorderSizePixel = 0
spinFrame.Visible = false
spinFrame.ZIndex = 100
spinFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = spinFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 80, 160)
stroke.Thickness = 3
stroke.Parent = spinFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 15)
title.BackgroundTransparency = 1
title.Text = "🎰 LUCKY SPIN"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.TextSize = 32
title.Font = Enum.Font.GothamBlack
title.ZIndex = 101
title.Parent = spinFrame

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
closeBtn.Parent = spinFrame

-- Wheel container
local wheelContainer = Instance.new("Frame")
wheelContainer.Name = "WheelContainer"
wheelContainer.Size = UDim2.new(0, 350, 0, 350)
wheelContainer.Position = UDim2.new(0.5, -175, 0, 70)
wheelContainer.BackgroundTransparency = 1
wheelContainer.ZIndex = 101
wheelContainer.Parent = spinFrame

-- Wheel background
local wheelBg = Instance.new("Frame")
wheelBg.Name = "WheelBg"
wheelBg.Size = UDim2.new(1, 0, 1, 0)
wheelBg.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
wheelBg.ZIndex = 102
wheelBg.Parent = wheelContainer

local wheelCorner = Instance.new("UICorner")
wheelCorner.CornerRadius = UDim.new(1, 0)
wheelCorner.Parent = wheelBg

-- Wheel segments (will be created dynamically)
local wheelSegments = Instance.new("Frame")
wheelSegments.Name = "Segments"
wheelSegments.Size = UDim2.new(1, 0, 1, 0)
wheelSegments.BackgroundTransparency = 1
wheelSegments.ZIndex = 103
wheelSegments.Parent = wheelContainer

-- Center indicator (pointer)
local pointer = Instance.new("Frame")
pointer.Name = "Pointer"
pointer.Size = UDim2.new(0, 20, 0, 30)
pointer.Position = UDim2.new(0.5, -10, 0, -10)
pointer.BackgroundColor3 = Color3.fromRGB(255, 50, 50)
pointer.ZIndex = 110
pointer.Parent = wheelContainer

local pointerCorner = Instance.new("UICorner")
pointerCorner.CornerRadius = UDim.new(0, 4)
pointerCorner.Parent = pointer

-- Center circle (spin button initially)
local centerBtn = Instance.new("TextButton")
centerBtn.Name = "SpinButton"
centerBtn.Size = UDim2.new(0, 100, 0, 100)
centerBtn.Position = UDim2.new(0.5, -50, 0.5, -50)
centerBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
centerBtn.Text = "SPIN"
centerBtn.TextColor3 = Color3.new(1, 1, 1)
centerBtn.TextSize = 24
centerBtn.Font = Enum.Font.GothamBlack
.centerBtn.ZIndex = 111
.centerBtn.Parent = wheelContainer

local centerCorner = Instance.new("UICorner")
centerCorner.CornerRadius = UDim.new(1, 0)
centerCorner.Parent = centerBtn

-- Status label (stored spins / cooldown)
local statusLabel = Instance.new("TextLabel")
statusLabel.Name = "Status"
statusLabel.Size = UDim2.new(1, 0, 0, 30)
statusLabel.Position = UDim2.new(0, 0, 1, -75)
statusLabel.BackgroundTransparency = 1
statusLabel.Text = "Loading..."
statusLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
statusLabel.TextSize = 18
statusLabel.Font = Enum.Font.Gotham
statusLabel.ZIndex = 101
statusLabel.Parent = spinFrame

-- Buy spin button
local buyBtn = Instance.new("TextButton")
buyBtn.Name = "BuySpin"
buyBtn.Size = UDim2.new(0, 200, 0, 45)
buyBtn.Position = UDim2.new(0.5, -100, 1, -40)
buyBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 120)
buyBtn.Text = "Buy Spin (50 🪙)"
buyBtn.TextColor3 = Color3.new(1, 1, 1)
buyBtn.TextSize = 18
buyBtn.Font = Enum.Font.GothamBold
buyBtn.ZIndex = 101
buyBtn.Parent = spinFrame
buyBtn.Visible = false

local buyCorner = Instance.new("UICorner")
buyCorner.CornerRadius = UDim.new(0, 10)
buyCorner.Parent = buyBtn

-- Prize popup (shown after spin)
local prizePopup = Instance.new("Frame")
prizePopup.Name = "PrizePopup"
prizePopup.Size = UDim2.new(0, 300, 0, 150)
prizePopup.Position = UDim2.new(0.5, -150, 0.5, -75)
prizePopup.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
prizePopup.BorderSizePixel = 0
prizePopup.Visible = false
prizePopup.ZIndex = 200
prizePopup.Parent = spinFrame

local popupCorner = Instance.new("UICorner")
popupCorner.CornerRadius = UDim.new(0, 16)
popupCorner.Parent = prizePopup

local popupStroke = Instance.new("UIStroke")
popupStroke.Color = Color3.fromRGB(255, 215, 0)
popupStroke.Thickness = 3
popupStroke.Parent = prizePopup

local popupTitle = Instance.new("TextLabel")
popupTitle.Size = UDim2.new(1, 0, 0, 40)
popupTitle.Position = UDim2.new(0, 0, 0, 20)
popupTitle.BackgroundTransparency = 1
ppopupTitle.Text = "YOU WON!"
popupTitle.TextColor3 = Color3.fromRGB(255, 215, 0)
popupTitle.TextSize = 28
popupTitle.Font = Enum.Font.GothamBlack
popupTitle.ZIndex = 201
popupTitle.Parent = prizePopup

local popupPrize = Instance.new("TextLabel")
local popupPrize.Size = UDim2.new(1, 0, 0, 50)
local popupPrize.Position = UDim2.new(0, 0, 0, 70)
local popupPrize.BackgroundTransparency = 1
local popupPrize.Text = "???"
local popupPrize.TextColor3 = Color3.new(1, 1, 1)
local popupPrize.TextSize = 36
local popupPrize.Font = Enum.Font.GothamBold
local popupPrize.ZIndex = 201
local popupPrize.Parent = prizePopup

local popupClose = Instance.new("TextButton")
local popupClose.Size = UDim2.new(0, 100, 0, 35)
local popupClose.Position = UDim2.new(0.5, -50, 1, -45)
local popupClose.BackgroundColor3 = Color3.fromRGB(80, 80, 120)
local popupClose.Text = "NICE!"
local popupClose.TextColor3 = Color3.new(1, 1, 1)
local popupClose.TextSize = 18
local popupClose.Font = Enum.Font.GothamBold
local popupClose.ZIndex = 201
local popupClose.Parent = prizePopup

local popupCloseCorner = Instance.new("UICorner")
local popupCloseCorner.CornerRadius = UDim.new(0, 8)
local popupCloseCorner.Parent = popupClose

-- ============================================================================
-- WHEEL SEGMENTS
-- ============================================================================

local PRIZES = Config.LuckySpin.Prizes
local NUM_SEGMENTS = #PRIZES
local SEGMENT_ANGLE = 360 / NUM_SEGMENTS

-- Create wheel segments
local function createWheelSegments()
	-- Clear existing
	for _, child in ipairs(wheelSegments:GetChildren()) do
		child:Destroy()
	end
	
	for i, prize in ipairs(PRIZES) do
		local angle = (i - 1) * SEGMENT_ANGLE
		
		-- Segment wedge
		local segment = Instance.new("Frame")
		segment.Name = "Segment_" .. tostring(i)
		segment.Size = UDim2.new(0, 140, 0, 140)
		segment.Position = UDim2.new(0.5, 0, 0.5, 0)
		segment.AnchorPoint = Vector2.new(0.5, 1)
		segment.BackgroundColor3 = i % 2 == 0 
			and Color3.fromRGB(60, 60, 90) 
			or Color3.fromRGB(50, 50, 80)
		segment.BorderSizePixel = 0
		segment.Rotation = angle + SEGMENT_ANGLE / 2
		segment.ZIndex = 103
		segment.Parent = wheelSegments
		
		-- Prize label
		local label = Instance.new("TextLabel")
		label.Size = UDim2.new(1, 0, 0, 30)
		label.Position = UDim2.new(0, 0, 0, 10)
		label.BackgroundTransparency = 1
		label.Text = prize.type == "coins" and tostring(prize.amount) .. " 🪙" or "✨"
		label.TextColor3 = Color3.new(1, 1, 1)
		label.TextSize = prize.weight <= 4 and 14 or 16
		label.Font = Enum.Font.GothamBold
		label.Rotation = -angle - SEGMENT_ANGLE / 2
		label.ZIndex = 104
		label.Parent = segment
	end
end

createWheelSegments()

-- ============================================================================
-- STATE
-- ============================================================================

local isSpinning = false
local currentSpinInfo = nil

-- ============================================================================
-- FUNCTIONS
-- ============================================================================

local function updateUI()
	if not currentSpinInfo then return end
	
	-- Update spin button
	if currentSpinInfo.canSpinFree then
		centerBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
		centerBtn.Text = "FREE SPIN"
		statusLabel.Text = string.format("🎫 %d/%d spins available", 
			currentSpinInfo.storedSpins, currentSpinInfo.maxStored)
		statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
	else
		centerBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 100)
		centerBtn.Text = "COOLDOWN"
		
		local hours = math.floor(currentSpinInfo.timeUntilFree / 3600)
		local mins = math.floor((currentSpinInfo.timeUntilFree % 3600) / 60)
		statusLabel.Text = string.format("⏰ Free spin in %dh %dm", hours, mins)
		statusLabel.TextColor3 = Color3.fromRGB(255, 200, 100)
	end
	
	-- Update buy button
	buyBtn.Visible = not currentSpinInfo.canSpinFree and currentSpinInfo.canBuySpin
	if currentSpinInfo.canBuySpin then
		buyBtn.Text = string.format("Buy Spin (%d 🪙)", currentSpinInfo.spinCost)
		buyBtn.BackgroundColor3 = Color3.fromRGB(80, 60, 120)
	else
		buyBtn.Text = "Need more coins"
		buyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
	end
end

local function refreshSpinInfo()
	currentSpinInfo = GetSpinInfo:InvokeServer()
	updateUI()
end

-- Spin animation
local function animateSpin(targetSegment: number): number
	local spins = 5 + math.random(2, 4) -- 5-8 full rotations
	local finalAngle = (targetSegment - 1) * SEGMENT_ANGLE + SEGMENT_ANGLE / 2
	local totalRotation = spins * 360 + finalAngle
	
	-- Animate wheel
	local tweenInfo = TweenInfo.new(4, Enum.EasingStyle.Quart, Enum.EasingDirection.Out)
	local tween = TweenService:Create(wheelSegments, tweenInfo, {
		Rotation = totalRotation,
	})
	
	tween:Play()
	tween.Completed:Wait()
	
	return finalAngle
end

-- Show prize popup
local function showPrize(prizeDisplay: string)
	popupPrize.Text = prizeDisplay
	prizePopup.Visible = true
	
	local tween = TweenService:Create(prizePopup, TweenInfo.new(0.3), {
		Size = UDim2.new(0, 300, 0, 150),
	})
	prizePopup.Size = UDim2.new(0, 250, 0, 125)
	tween:Play()
end

-- Perform spin
local function doSpin(useCoins: boolean)
	if isSpinning then return end
	isSpinning = true
	
	-- Disable buttons
	centerBtn.Visible = false
	buyBtn.Visible = false
	
	-- Request spin from server
	local result = RequestSpin:InvokeServer(useCoins)
	
	if not result.success then
		-- Failed - show error and re-enable
		statusLabel.Text = result.error or "Spin failed"
		statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
		isSpinning = false
		centerBtn.Visible = true
		refreshSpinInfo()
		return
	end
	
	-- Find which segment corresponds to the prize
	local targetSegment = 1
	for i, prize in ipairs(PRIZES) do
		if prize.id == result.prize.id then
			targetSegment = i
			break
		end
	end
	
	-- Animate
	animateSpin(targetSegment)
	
	-- Show prize
	showPrize(result.prize.display)
	
	-- Reset
	isSpinning = false
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

closeBtn.MouseButton1Click:Connect(function()
	spinFrame.Visible = false
end)

centerBtn.MouseButton1Click:Connect(function()
	if currentSpinInfo and currentSpinInfo.canSpinFree then
		doSpin(false)
	end
end)

buyBtn.MouseButton1Click:Connect(function()
	if currentSpinInfo and currentSpinInfo.canBuySpin then
		doSpin(true)
	end
end)

popupClose.MouseButton1Click:Connect(function()
	prizePopup.Visible = false
	refreshSpinInfo()
	centerBtn.Visible = true
end)

-- Server events
SpinResultEvent.OnClientEvent:Connect(function(data)
	-- Prize already granted on server, just update UI after popup closes
end)

SpinAvailableEvent.OnClientEvent:Connect(function(data)
	refreshSpinInfo()
	
	-- Show notification
	local notif = Instance.new("TextLabel")
	notif.Size = UDim2.new(0, 250, 0, 40)
	notif.Position = UDim2.new(0.5, -125, 0.3, 0)
	notif.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
	notif.Text = "🎰 Free spin available!"
	notif.TextColor3 = Color3.fromRGB(100, 255, 100)
	notif.TextSize = 18
	notif.Font = Enum.Font.GothamBold
	notif.ZIndex = 150
	notif.Parent = screenGui
	
	local notifCorner = Instance.new("UICorner")
	notifCorner.CornerRadius = UDim.new(0, 8)
	notifCorner.Parent = notif
	
	task.delay(3, function()
		local fade = TweenService:Create(notif, TweenInfo.new(0.5), {TextTransparency = 1, BackgroundTransparency = 1})
		fade:Play()
		fade.Completed:Wait()
		notif:Destroy()
	end)
end)

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function LuckySpinUI:Show()
	spinFrame.Visible = true
	refreshSpinInfo()
end

function LuckySpinUI:Hide()
	spinFrame.Visible = false
end

function LuckySpinUI:Toggle()
	if spinFrame.Visible then
		LuckySpinUI:Hide()
	else
		LuckySpinUI:Show()
	end
end

-- Initial load
refreshSpinInfo()

return LuckySpinUI

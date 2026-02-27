--!strict
-- MainUIHandler.client.lua
-- Enhanced UI Controller with colorful design, animations, and kid-friendly visuals
-- Location: StarterGui/MainUIHandler.client.lua

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- ============================================================================
-- COLOR PALETTE - Bright, kid-friendly neon colors
-- ============================================================================
local Colors = {
	Primary = Color3.fromRGB(255, 107, 107),	 -- Coral Red
	Secondary = Color3.fromRGB(78, 205, 196),	-- Turquoise
	Accent = Color3.fromRGB(255, 230, 109),	  -- Bright Yellow
	Success = Color3.fromRGB(150, 255, 130),	 -- Neon Green
	Warning = Color3.fromRGB(255, 159, 67),	  -- Orange
	Danger = Color3.fromRGB(255, 71, 87),		-- Bright Red
	Purple = Color3.fromRGB(162, 95, 255),	   -- Neon Purple
	Pink = Color3.fromRGB(255, 105, 180),		-- Hot Pink
	Dark = Color3.fromRGB(30, 30, 45),		   -- Dark background
	Card = Color3.fromRGB(45, 45, 65),		   -- Card background
	White = Color3.fromRGB(255, 255, 255),
	Gold = Color3.fromRGB(255, 215, 0),
	Silver = Color3.fromRGB(192, 192, 192),
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

local function createGradient(parent: Instance, colors: {Color3}, rotation: number?): UIGradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new(colors)
	gradient.Rotation = rotation or 45
	gradient.Parent = parent
	return gradient
end

local function createCorner(parent: Instance, radius: number?): UICorner
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, radius or 16)
	corner.Parent = parent
	return corner
end

local function createStroke(parent: Instance, color: Color3?, thickness: number?): UIStroke
	local stroke = Instance.new("UIStroke")
	stroke.Color = color or Colors.White
	stroke.Thickness = thickness or 3
	stroke.Parent = parent
	return stroke
end

local function createShadow(parent: Instance, offset: number?): ImageLabel
	local shadow = Instance.new("ImageLabel")
	shadow.Name = "Shadow"
	shadow.Size = UDim2.new(1, offset or 8, 1, offset or 8)
	shadow.Position = UDim2.new(0, (offset or 8) / 2, 0, (offset or 8) / 2)
	shadow.BackgroundTransparency = 1
	shadow.Image = "rbxassetid://131296983"
	shadow.ImageColor3 = Color3.new(0, 0, 0)
	shadow.ImageTransparency = 0.7
	shadow.ScaleType = Enum.ScaleType.Slice
	shadow.SliceCenter = Rect.new(10, 10, 118, 118)
	shadow.ZIndex = parent.ZIndex - 1
	shadow.Parent = parent
	return shadow
end

local function createButtonAnimation(button: GuiObject)
	local originalSize = button.Size
	
	button.MouseEnter:Connect(function()
		local tween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset * 1.05, originalSize.Y.Scale, originalSize.Y.Offset * 1.05),
		})
		tween:Play()
	end)
	
	button.MouseLeave:Connect(function()
		local tween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = originalSize,
		})
		tween:Play()
	end)
	
	button.MouseButton1Down:Connect(function()
		local tween = TweenService:Create(button, TweenInfo.new(0.1, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Size = UDim2.new(originalSize.X.Scale, originalSize.X.Offset * 0.95, originalSize.Y.Scale, originalSize.Y.Offset * 0.95),
		})
		tween:Play()
	end)
	
	button.MouseButton1Up:Connect(function()
		local tween = TweenService:Create(button, TweenInfo.new(0.2, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Size = originalSize,
		})
		tween:Play()
	end)
end

-- ============================================================================
-- MAIN UI CREATION
-- ============================================================================

local mainUI = Instance.new("ScreenGui")
mainUI.Name = "MainUI"
mainUI.ResetOnSpawn = false
mainUI.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
mainUI.Parent = playerGui

-- ============================================================================
-- HUD FRAME
-- ============================================================================

local hudFrame = Instance.new("Frame")
hudFrame.Name = "HUD"
hudFrame.Size = UDim2.new(1, 0, 1, 0)
hudFrame.BackgroundTransparency = 1
hudFrame.Parent = mainUI

-- Distance Display with Progress Bar
local distanceContainer = Instance.new("Frame")
distanceContainer.Name = "DistanceContainer"
distanceContainer.Size = UDim2.new(0, 320, 0, 80)
distanceContainer.Position = UDim2.new(0.5, -160, 0, 20)
distanceContainer.BackgroundColor3 = Colors.Card
distanceContainer.BorderSizePixel = 0
distanceContainer.Parent = hudFrame

local distanceGradient = createGradient(distanceContainer, {Colors.Secondary, Colors.Purple})
createCorner(distanceContainer, 20)
createStroke(distanceContainer, Colors.Secondary, 3)
createShadow(distanceContainer, 10)

-- Distance icon
local distanceIcon = Instance.new("TextLabel")
distanceIcon.Name = "Icon"
distanceIcon.Size = UDim2.new(0, 50, 0, 50)
distanceIcon.Position = UDim2.new(0, 15, 0.5, -25)
distanceIcon.BackgroundTransparency = 1
distanceIcon.Text = "🏃"
distanceIcon.TextSize = 36
distanceIcon.Parent = distanceContainer

-- Distance text
local distanceLabel = Instance.new("TextLabel")
distanceLabel.Name = "DistanceLabel"
distanceLabel.Size = UDim2.new(0, 200, 0, 35)
distanceLabel.Position = UDim2.new(0, 75, 0, 8)
distanceLabel.BackgroundTransparency = 1
distanceLabel.Text = "0m"
distanceLabel.TextColor3 = Colors.White
distanceLabel.TextScaled = true
distanceLabel.Font = Enum.Font.FredokaOne
distanceLabel.TextStrokeTransparency = 0
distanceLabel.TextStrokeColor3 = Colors.Dark
distanceLabel.Parent = distanceContainer

-- Progress bar background
local progressBarBg = Instance.new("Frame")
progressBarBg.Name = "ProgressBarBg"
progressBarBg.Size = UDim2.new(0, 220, 0, 12)
progressBarBg.Position = UDim2.new(0, 75, 0, 52)
progressBarBg.BackgroundColor3 = Colors.Dark
progressBarBg.BorderSizePixel = 0
progressBarBg.Parent = distanceContainer
createCorner(progressBarBg, 6)

-- Progress bar fill
local progressBarFill = Instance.new("Frame")
progressBarFill.Name = "ProgressBarFill"
progressBarFill.Size = UDim2.new(0, 0, 1, 0)
progressBarFill.BackgroundColor3 = Colors.Success
createGradient(progressBarFill, {Colors.Success, Colors.Secondary}, 0)
progressBarFill.BorderSizePixel = 0
progressBarFill.Parent = progressBarBg
createCorner(progressBarFill, 6)

-- Progress bar glow effect
local progressGlow = Instance.new("ImageLabel")
progressGlow.Name = "Glow"
progressGlow.Size = UDim2.new(0, 20, 1.5, 0)
progressGlow.Position = UDim2.new(1, -10, -0.25, 0)
progressGlow.BackgroundTransparency = 1
progressGlow.Image = "rbxassetid://131296983"
progressGlow.ImageColor3 = Colors.Success
progressGlow.ImageTransparency = 0.5
progressGlow.Parent = progressBarFill

-- Animated Coins Display
local coinsContainer = Instance.new("Frame")
coinsContainer.Name = "CoinsContainer"
coinsContainer.Size = UDim2.new(0, 180, 0, 60)
coinsContainer.Position = UDim2.new(1, -200, 0, 20)
coinsContainer.BackgroundColor3 = Colors.Card
coinsContainer.BorderSizePixel = 0
coinsContainer.Parent = hudFrame

createGradient(coinsContainer, {Colors.Warning, Colors.Danger})
createCorner(coinsContainer, 16)
createStroke(coinsContainer, Colors.Gold, 3)
createShadow(coinsContainer, 8)

-- Coin icon (animated)
local coinIcon = Instance.new("ImageLabel")
coinIcon.Name = "CoinIcon"
coinIcon.Size = UDim2.new(0, 45, 0, 45)
coinIcon.Position = UDim2.new(0, 10, 0.5, -22)
coinIcon.BackgroundTransparency = 1
coinIcon.Image = "rbxassetid://134082042"
coinIcon.ImageColor3 = Colors.Gold
coinIcon.Parent = coinsContainer

-- Spin animation for coin
local function spinCoin()
	while coinIcon and coinIcon.Parent do
		local tween = TweenService:Create(coinIcon, TweenInfo.new(0.5, Enum.EasingStyle.Linear), {
			Rotation = coinIcon.Rotation + 360,
		})
		tween:Play()
		tween.Completed:Wait()
	end
end
task.spawn(spinCoin)

-- Coin counter
local coinsLabel = Instance.new("TextLabel")
coinsLabel.Name = "CoinsLabel"
coinsLabel.Size = UDim2.new(0, 110, 0, 40)
coinsLabel.Position = UDim2.new(0, 60, 0.5, -20)
coinsLabel.BackgroundTransparency = 1
coinsLabel.Text = "0"
coinsLabel.TextColor3 = Colors.Gold
coinsLabel.TextScaled = true
coinsLabel.Font = Enum.Font.FredokaOne
coinsLabel.TextStrokeTransparency = 0
coinsLabel.TextStrokeColor3 = Colors.Dark
coinsLabel.Parent = coinsContainer

-- Animated coin counter
local currentCoins = 0
local targetCoins = 0
local function updateCoinDisplay()
	local diff = targetCoins - currentCoins
	if math.abs(diff) > 0 then
		local step = math.ceil(math.abs(diff) / 10) * (diff > 0 and 1 or -1)
		currentCoins += step
		coinsLabel.Text = tostring(currentCoins)
		
		-- Bounce animation
		local tween = TweenService:Create(coinsLabel, TweenInfo.new(0.1, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			TextSize = 42,
		})
		tween:Play()
		tween.Completed:Connect(function()
			local tween2 = TweenService:Create(coinsLabel, TweenInfo.new(0.1), {
				TextSize = 40,
			})
			tween2:Play()
		end)
	end
end

RunService.Heartbeat:Connect(function()
	if currentCoins ~= targetCoins then
		updateCoinDisplay()
	end
end)

-- Shop Button (Colorful, rounded)
local shopButton = Instance.new("TextButton")
shopButton.Name = "ShopButton"
shopButton.Size = UDim2.new(0, 140, 0, 55)
shopButton.Position = UDim2.new(1, -165, 0, 90)
shopButton.BackgroundColor3 = Colors.Purple
shopButton.Text = "🛍️ SHOP"
shopButton.TextColor3 = Colors.White
shopButton.TextScaled = true
shopButton.Font = Enum.Font.FredokaOne
createGradient(shopButton, {Colors.Purple, Colors.Pink})
createCorner(shopButton, 16)
createStroke(shopButton, Colors.White, 3)
createShadow(shopButton, 8)
shopButton.Parent = hudFrame

createButtonAnimation(shopButton)

-- ============================================================================
-- JUMP! INDICATOR
-- ============================================================================

local jumpIndicator = Instance.new("Frame")
jumpIndicator.Name = "JumpIndicator"
jumpIndicator.Size = UDim2.new(0, 200, 0, 80)
jumpIndicator.Position = UDim2.new(0.5, -100, 0.7, 0)
jumpIndicator.BackgroundColor3 = Colors.Danger
jumpIndicator.BorderSizePixel = 0
jumpIndicator.Visible = false
jumpIndicator.ZIndex = 5
jumpIndicator.Parent = hudFrame

createGradient(jumpIndicator, {Colors.Danger, Colors.Warning})
createCorner(jumpIndicator, 20)
createStroke(jumpIndicator, Colors.White, 4)
createShadow(jumpIndicator, 12)

local jumpText = Instance.new("TextLabel")
jumpText.Name = "JumpText"
jumpText.Size = UDim2.new(1, 0, 1, 0)
jumpText.BackgroundTransparency = 1
jumpText.Text = "JUMP! ⬆️"
jumpText.TextColor3 = Colors.White
jumpText.TextScaled = true
jumpText.Font = Enum.Font.FredokaOne
jumpText.TextStrokeTransparency = 0
jumpText.TextStrokeColor3 = Colors.Dark
jumpText.ZIndex = 6
jumpText.Parent = jumpIndicator

-- Pulsing animation
local function pulseJumpIndicator()
	while jumpIndicator and jumpIndicator.Parent do
		if jumpIndicator.Visible then
			local tween = TweenService:Create(jumpIndicator, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.new(0, 220, 0, 88),
			})
			tween:Play()
			tween.Completed:Wait()
			
			local tween2 = TweenService:Create(jumpIndicator, TweenInfo.new(0.5, Enum.EasingStyle.Sine, Enum.EasingDirection.InOut), {
				Size = UDim2.new(0, 200, 0, 80),
			})
			tween2:Play()
			tween2.Completed:Wait()
		else
			task.wait(0.5)
		end
	end
end
task.spawn(pulseJumpIndicator)

-- ============================================================================
-- DIRECTION ARROW
-- ============================================================================

local arrowContainer = Instance.new("Frame")
arrowContainer.Name = "ArrowContainer"
arrowContainer.Size = UDim2.new(0, 120, 0, 120)
arrowContainer.Position = UDim2.new(0.5, -60, 0.5, -60)
arrowContainer.BackgroundTransparency = 1
arrowContainer.Visible = false
arrowContainer.Parent = hudFrame

local arrowImage = Instance.new("ImageLabel")
arrowImage.Name = "Arrow"
arrowImage.Size = UDim2.new(1, 0, 1, 0)
arrowImage.BackgroundTransparency = 1
arrowImage.Image = "rbxassetid://131296983"
arrowImage.ImageColor3 = Colors.Success
arrowImage.Parent = arrowContainer

-- ============================================================================
-- DEATH SCREEN
-- ============================================================================

local deathScreen = Instance.new("Frame")
deathScreen.Name = "DeathScreen"
deathScreen.Size = UDim2.new(1, 0, 1, 0)
deathScreen.BackgroundColor3 = Color3.new(0, 0, 0)
deathScreen.BackgroundTransparency = 0.4

local deathGradient = Instance.new("Frame")
deathGradient.Name = "GradientOverlay"
deathGradient.Size = UDim2.new(1, 0, 1, 0)
deathGradient.BackgroundColor3 = Colors.Danger
createGradient(deathGradient, {Colors.Danger, Colors.Purple}, 135)
deathGradient.BackgroundTransparency = 0.7
deathGradient.Parent = deathScreen

deathScreen.Visible = false
deathScreen.ZIndex = 100
deathScreen.Parent = mainUI

-- Skull icon container (animated)
local skullContainer = Instance.new("Frame")
skullContainer.Name = "SkullContainer"
skullContainer.Size = UDim2.new(0, 150, 0, 150)
skullContainer.Position = UDim2.new(0.5, -75, 0.15, 0)
skullContainer.BackgroundColor3 = Colors.Card
createCorner(skullContainer, 30)
createStroke(skullContainer, Colors.Danger, 4)
skullContainer.ZIndex = 101
skullContainer.Parent = deathScreen

createGradient(skullContainer, {Colors.Dark, Colors.Card})

-- Animated skull emoji
local skullIcon = Instance.new("TextLabel")
skullIcon.Name = "SkullIcon"
skullIcon.Size = UDim2.new(1, 0, 1, 0)
skullIcon.BackgroundTransparency = 1
skullIcon.Text = "💀"
skullIcon.TextSize = 100
skullIcon.Font = Enum.Font.GothamBold
skullIcon.ZIndex = 102
skullIcon.Parent = skullContainer

-- Skull shake animation
local function shakeSkull()
	while skullIcon and skullIcon.Parent do
		if deathScreen.Visible then
			local tween = TweenService:Create(skullIcon, TweenInfo.new(0.1), {
				Rotation = math.random(-10, 10),
			})
			tween:Play()
			tween.Completed:Wait()
		else
			skullIcon.Rotation = 0
			task.wait(0.5)
		end
	end
end
task.spawn(shakeSkull)

-- "YOU DIED" title
local diedTitle = Instance.new("TextLabel")
diedTitle.Name = "DiedTitle"
diedTitle.Size = UDim2.new(0, 400, 0, 60)
diedTitle.Position = UDim2.new(0.5, -200, 0.32, 0)
diedTitle.BackgroundTransparency = 1
diedTitle.Text = "YOU DIED!"
diedTitle.TextColor3 = Colors.Danger
diedTitle.TextScaled = true
diedTitle.Font = Enum.Font.FredokaOne
diedTitle.TextStrokeTransparency = 0
diedTitle.TextStrokeColor3 = Colors.White
diedTitle.ZIndex = 101
diedTitle.Parent = deathScreen

-- Distance display
local deathDistanceFrame = Instance.new("Frame")
deathDistanceFrame.Name = "DeathDistanceFrame"
deathDistanceFrame.Size = UDim2.new(0, 300, 0, 50)
deathDistanceFrame.Position = UDim2.new(0.5, -150, 0.4, 0)
deathDistanceFrame.BackgroundColor3 = Colors.Card
createCorner(deathDistanceFrame, 12)
createStroke(deathDistanceFrame, Colors.Silver, 2)
deathDistanceFrame.ZIndex = 101
deathDistanceFrame.Parent = deathScreen

local deathDistanceLabel = Instance.new("TextLabel")
deathDistanceLabel.Name = "DistanceLabel"
deathDistanceLabel.Size = UDim2.new(1, 0, 1, 0)
deathDistanceLabel.BackgroundTransparency = 1
deathDistanceLabel.Text = "You ran: 0m"
deathDistanceLabel.TextColor3 = Colors.White
deathDistanceLabel.TextScaled = true
deathDistanceLabel.Font = Enum.Font.GothamBold
deathDistanceLabel.ZIndex = 102
deathDistanceLabel.Parent = deathDistanceFrame

-- High score badge
local badgeFrame = Instance.new("Frame")
badgeFrame.Name = "BadgeFrame"
badgeFrame.Size = UDim2.new(0, 280, 0, 40)
badgeFrame.Position = UDim2.new(0.5, -140, 0.47, 0)
badgeFrame.BackgroundColor3 = Colors.Gold
badgeFrame.Visible = false
createCorner(badgeFrame, 10)
badgeFrame.ZIndex = 101
badgeFrame.Parent = deathScreen

local badgeText = Instance.new("TextLabel")
badgeText.Name = "BadgeText"
badgeText.Size = UDim2.new(1, 0, 1, 0)
badgeText.BackgroundTransparency = 1
badgeText.Text = "🏆 NEW RECORD!"
badgeText.TextColor3 = Colors.Dark
badgeText.TextScaled = true
badgeText.Font = Enum.Font.GothamBlack
badgeText.ZIndex = 102
badgeText.Parent = badgeFrame

-- Buttons container
local buttonsContainer = Instance.new("Frame")
buttonsContainer.Name = "ButtonsContainer"
buttonsContainer.Size = UDim2.new(0, 400, 0, 220)
buttonsContainer.Position = UDim2.new(0.5, -200, 0.55, 0)
buttonsContainer.BackgroundTransparency = 1
buttonsContainer.ZIndex = 101
buttonsContainer.Parent = deathScreen

-- REVIVE button
local reviveButton = Instance.new("TextButton")
reviveButton.Name = "ReviveButton"
reviveButton.Size = UDim2.new(0, 380, 0, 80)
reviveButton.Position = UDim2.new(0, 10, 0, 0)
reviveButton.BackgroundColor3 = Colors.Success
reviveButton.Text = "💀 REVIVE NOW!\n⚡ 25 R$"
reviveButton.TextColor3 = Colors.White
reviveButton.TextScaled = true
reviveButton.Font = Enum.Font.FredokaOne
reviveButton.ZIndex = 102
reviveButton.Parent = buttonsContainer

createGradient(reviveButton, {Colors.Success, Colors.Secondary})
createCorner(reviveButton, 20)
createStroke(reviveButton, Colors.White, 4)
createShadow(reviveButton, 10)
createButtonAnimation(reviveButton)

-- Respawn button
local respawnButton = Instance.new("TextButton")
respawnButton.Name = "RespawnButton"
respawnButton.Size = UDim2.new(0, 380, 0, 60)
respawnButton.Position = UDim2.new(0, 10, 0, 100)
respawnButton.BackgroundColor3 = Colors.Card
respawnButton.Text = "RESPAWN"
respawnButton.TextColor3 = Colors.Silver
respawnButton.TextScaled = true
respawnButton.Font = Enum.Font.GothamBold
respawnButton.ZIndex = 102
respawnButton.Parent = buttonsContainer

createCorner(respawnButton, 16)
createStroke(respawnButton, Colors.Silver, 2)
createShadow(respawnButton, 6)
createButtonAnimation(respawnButton)

-- Power-up buttons row
local powerUpFrame = Instance.new("Frame")
powerUpFrame.Name = "PowerUpFrame"
powerUpFrame.Size = UDim2.new(0, 380, 0, 50)
powerUpFrame.Position = UDim2.new(0, 10, 0, 170)
powerUpFrame.BackgroundTransparency = 1
powerUpFrame.ZIndex = 101
powerUpFrame.Parent = buttonsContainer

local function createPowerUpButton(name: string, icon: string, price: number, position: number): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 115, 0, 50)
	btn.Position = UDim2.new(0, position, 0, 0)
	btn.BackgroundColor3 = Colors.Card
	btn.Text = icon .. " " .. price
	btn.TextColor3 = Colors.White
	btn.TextScaled = true
	btn.Font = Enum.Font.GothamBold
	btn.ZIndex = 102
	
	createCorner(btn, 10)
	createStroke(btn, Colors.Purple, 2)
	createButtonAnimation(btn)
	
	return btn
end

local shieldBtn = createPowerUpButton("ShieldBtn", "🛡️", 15, 0)
shieldBtn.Parent = powerUpFrame

local speedBtn = createPowerUpButton("SpeedBtn", "⚡", 15, 132)
speedBtn.Parent = powerUpFrame

local skipBtn = createPowerUpButton("SkipBtn", "🏃", 25, 265)
skipBtn.Parent = powerUpFrame

-- ============================================================================
-- SHOP FRAME
-- ============================================================================

local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.Size = UDim2.new(0, 550, 0, 450)
shopFrame.Position = UDim2.new(0.5, -275, 0.5, -225)
shopFrame.BackgroundColor3 = Colors.Card
shopFrame.Visible = false
shopFrame.ZIndex = 50
shopFrame.Parent = mainUI

createGradient(shopFrame, {Colors.Card, Colors.Dark})
createCorner(shopFrame, 24)
createStroke(shopFrame, Colors.Purple, 4)
createShadow(shopFrame, 15)

-- Shop title
local shopTitle = Instance.new("TextLabel")
shopTitle.Name = "Title"
shopTitle.Size = UDim2.new(1, 0, 0, 60)
shopTitle.BackgroundTransparency = 1
shopTitle.Text = "🛍️ ITEM SHOP"
shopTitle.TextColor3 = Colors.Gold
shopTitle.TextScaled = true
shopTitle.Font = Enum.Font.FredokaOne
shopTitle.TextStrokeTransparency = 0
shopTitle.TextStrokeColor3 = Colors.Dark
shopTitle.ZIndex = 51
shopTitle.Parent = shopFrame

-- Close button
local closeShopBtn = Instance.new("TextButton")
closeShopBtn.Name = "CloseButton"
closeShopBtn.Size = UDim2.new(0, 50, 0, 50)
closeShopBtn.Position = UDim2.new(1, -60, 0, 10)
closeShopBtn.BackgroundColor3 = Colors.Danger
closeShopBtn.Text = "✕"
closeShopBtn.TextColor3 = Colors.White
closeShopBtn.TextSize = 30
closeShopBtn.Font = Enum.Font.GothamBlack
closeShopBtn.ZIndex = 51
closeShopBtn.Parent = shopFrame

createCorner(closeShopBtn, 12)
createButtonAnimation(closeShopBtn)

-- Shop content placeholder
local shopContent = Instance.new("Frame")
shopContent.Name = "Content"
shopContent.Size = UDim2.new(1, -40, 1, -100)
shopContent.Position = UDim2.new(0, 20, 0, 80)
shopContent.BackgroundTransparency = 1
shopContent.ZIndex = 51
shopContent.Parent = shopFrame

-- ============================================================================
-- REMOTE EVENT CONNECTIONS
-- ============================================================================

local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local EconomyEvents = ReplicatedStorage:WaitForChild("EconomyEvents")

-- Update distance display with progress bar
GameEvents:WaitForChild("DistanceUpdate").OnClientEvent:Connect(function(distance: number)
	distanceLabel.Text = tostring(math.floor(distance)) .. "m"
	
	-- Update progress bar (assuming 1000m is "full")
	local progress = math.min(distance / 1000, 1)
	progressBarFill.Size = UDim2.new(progress, 0, 1, 0)
	
	-- Change color based on progress
	if progress >= 0.75 then
		progressBarFill.BackgroundColor3 = Colors.Success
	elseif progress >= 0.5 then
		progressBarFill.BackgroundColor3 = Colors.Warning
	else
		progressBarFill.BackgroundColor3 = Colors.Primary
	end
end)

-- Update coins
EconomyEvents:WaitForChild("CoinAdded").OnClientEvent:Connect(function(amount: number, total: number)
	targetCoins = total
end)

-- Show death screen
GameEvents:WaitForChild("DeathScreenData").OnClientEvent:Connect(function(context)
	deathScreen.Visible = true
	deathDistanceLabel.Text = "You ran: " .. tostring(math.floor(context.distance)) .. "m"
	
	if context.badge then
		badgeText.Text = context.badge
		badgeFrame.Visible = true
	else
		badgeFrame.Visible = false
	end
end)

-- Button connections
closeShopBtn.MouseButton1Click:Connect(function()
	shopFrame.Visible = false
end)

shopButton.MouseButton1Click:Connect(function()
	shopFrame.Visible = true
end)

respawnButton.MouseButton1Click:Connect(function()
	deathScreen.Visible = false
	GameEvents:WaitForChild("Respawn"):FireServer(false)
end)

reviveButton.MouseButton1Click:Connect(function()
	local MarketplaceService = game:GetService("MarketplaceService")
	MarketplaceService:PromptProductPurchase(player, Config.DevProducts.InstantRevive.id)
end)

shieldBtn.MouseButton1Click:Connect(function()
	local MarketplaceService = game:GetService("MarketplaceService")
	MarketplaceService:PromptProductPurchase(player, Config.DevProducts.ShieldBubble.id)
end)

speedBtn.MouseButton1Click:Connect(function()
	local MarketplaceService = game:GetService("MarketplaceService")
	MarketplaceService:PromptProductPurchase(player, Config.DevProducts.SpeedBoost.id)
end)

skipBtn.MouseButton1Click:Connect(function()
	local MarketplaceService = game:GetService("MarketplaceService")
	MarketplaceService:PromptProductPurchase(player, Config.DevProducts.SkipAhead.id)
end)

-- Purchase success handling
ReplicatedStorage:WaitForChild("ShopEvents"):WaitForChild("PurchaseSuccess").OnClientEvent:Connect(function(productType: string)
	if productType == "InstantRevive" then
		deathScreen.Visible = false
		GameEvents:WaitForChild("Respawn"):FireServer(true)
	end
end)

-- Jump indicator logic
local function showJumpIndicator(shouldShow: boolean)
	jumpIndicator.Visible = shouldShow
end

-- Make functions available globally for other scripts
_G.MainUI = {
	ShowJumpIndicator = showJumpIndicator,
	ShowDeathScreen = function() deathScreen.Visible = true end,
	HideDeathScreen = function() deathScreen.Visible = false end,
	ShowShop = function() shopFrame.Visible = true end,
	HideShop = function() shopFrame.Visible = false end,
	UpdateCoins = function(amount: number) targetCoins = amount end,
	UpdateDistance = function(dist: number) 
		distanceLabel.Text = tostring(math.floor(dist)) .. "m"
	end,
}

print("[MainUI] Enhanced UI initialized with colorful design!")
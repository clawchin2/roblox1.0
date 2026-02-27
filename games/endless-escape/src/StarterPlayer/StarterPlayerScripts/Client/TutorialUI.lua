--!strict
-- TutorialUI.lua
-- Interactive tutorial system for first-time players
-- Location: StarterPlayer/StarterPlayerScripts/Client/TutorialUI.lua

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Tutorial module
local TutorialUI = {}

-- ============================================================================
-- COLOR PALETTE (Matching MainUI)
-- ============================================================================
local Colors = {
	Primary = Color3.fromRGB(255, 107, 107),
	Secondary = Color3.fromRGB(78, 205, 196),
	Accent = Color3.fromRGB(255, 230, 109),
	Success = Color3.fromRGB(150, 255, 130),
	Warning = Color3.fromRGB(255, 159, 67),
	Danger = Color3.fromRGB(255, 71, 87),
	Purple = Color3.fromRGB(162, 95, 255),
	Pink = Color3.fromRGB(255, 105, 180),
	Dark = Color3.fromRGB(30, 30, 45),
	Card = Color3.fromRGB(45, 45, 65),
	White = Color3.fromRGB(255, 255, 255),
	Gold = Color3.fromRGB(255, 215, 0),
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

-- ============================================================================
-- TUTORIAL DATA
-- ============================================================================

local tutorialSteps = {
	{
		id = "welcome",
		title = "Welcome to Endless Escape! 🎮",
		description = "Run as far as you can without falling! Dodge obstacles and collect coins along the way.",
		icon = "🏃",
		position = UDim2.new(0.5, -200, 0.3, 0),
		highlightArea = nil,
	},
	{
		id = "controls",
		title = "How to Move! 🎯",
		description = "Use WASD or arrow keys to move. Press SPACE to jump over gaps between platforms!",
		icon = "⌨️",
		position = UDim2.new(0.5, -200, 0.6, 0),
		highlightArea = "center",
	},
	{
		id = "coins",
		title = "Collect Coins! 🪙",
		description = "Grab shiny coins to buy awesome trails, skins, and power-ups in the shop!",
		icon = "💰",
		position = UDim2.new(0.7, -100, 0.1, 0),
		highlightArea = "topright",
	},
	{
		id = "jump",
		title = "Watch for Gaps! ⚠️",
		description = "Look for the JUMP! indicator when you're near a gap. Time your jumps carefully!",
		icon = "⬆️",
		position = UDim2.new(0.5, -200, 0.5, 0),
		highlightArea = "center",
	},
	{
		id = "powerups",
		title = "Power Ups! ⚡",
		description = "Buy shields, speed boosts, and revives when you die. Press the buttons to get help!",
		icon = "🛡️",
		position = UDim2.new(0.5, -200, 0.4, 0),
		highlightArea = nil,
	},
	{
		id = "shop",
		title = "Visit the Shop! 🛍️",
		description = "Click the SHOP button to buy cool cosmetics and make your character unique!",
		icon = "🎨",
		position = UDim2.new(0.8, -150, 0.15, 0),
		highlightArea = "shop",
	},
	{
		id = "ready",
		title = "Ready to Run! 🚀",
		description = "That's everything! Click START and see how far you can escape! Good luck!",
		icon = "⭐",
		position = UDim2.new(0.5, -200, 0.35, 0),
		highlightArea = "start",
	},
}

-- ============================================================================
-- TUTORIAL UI CREATION
-- ============================================================================

local tutorialScreen = Instance.new("ScreenGui")
tutorialScreen.Name = "TutorialUI"
tutorialScreen.ResetOnSpawn = false
 tutorialScreen.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
tutorialScreen.Enabled = false
tutorialScreen.Parent = playerGui

-- Dark overlay
local overlay = Instance.new("Frame")
overlay.Name = "Overlay"
overlay.Size = UDim2.new(1, 0, 1, 0)
overlay.BackgroundColor3 = Color3.new(0, 0, 0)
overlay.BackgroundTransparency = 0.5
overlay.ZIndex = 100
overlay.Parent = tutorialScreen

-- Spotlight effect (creates a hole where we want to highlight)
local spotlight = Instance.new("Frame")
spotlight.Name = "Spotlight"
spotlight.Size = UDim2.new(0, 200, 0, 200)
spotlight.Position = UDim2.new(0.5, -100, 0.5, -100)
spotlight.BackgroundTransparency = 1
spotlight.ZIndex = 101
spotlight.Parent = tutorialScreen

-- Tutorial card
local tutorialCard = Instance.new("Frame")
tutorialCard.Name = "TutorialCard"
tutorialCard.Size = UDim2.new(0, 400, 0, 280)
tutorialCard.Position = UDim2.new(0.5, -200, 0.3, 0)
tutorialCard.BackgroundColor3 = Colors.Card
tutorialCard.BorderSizePixel = 0
tutorialCard.ZIndex = 102
tutorialCard.Parent = tutorialScreen

createGradient(tutorialCard, {Colors.Secondary, Colors.Purple})
createCorner(tutorialCard, 24)
createStroke(tutorialCard, Colors.White, 4)
createShadow(tutorialCard, 15)

-- Icon container
local iconContainer = Instance.new("Frame")
iconContainer.Name = "IconContainer"
iconContainer.Size = UDim2.new(0, 80, 0, 80)
iconContainer.Position = UDim2.new(0.5, -40, 0, -40)
iconContainer.BackgroundColor3 = Colors.Accent
createGradient(iconContainer, {Colors.Accent, Colors.Warning})
createCorner(iconContainer, 20)
createStroke(iconContainer, Colors.White, 3)
iconContainer.ZIndex = 103
iconContainer.Parent = tutorialCard

-- Icon
local iconLabel = Instance.new("TextLabel")
iconLabel.Name = "Icon"
iconLabel.Size = UDim2.new(1, 0, 1, 0)
iconLabel.BackgroundTransparency = 1
iconLabel.Text = "🏃"
iconLabel.TextSize = 50
iconLabel.Font = Enum.Font.GothamBold
iconLabel.ZIndex = 104
iconLabel.Parent = iconContainer

-- Bounce animation for icon
local function bounceIcon()
	while iconContainer and iconContainer.Parent do
		local tween = TweenService:Create(iconContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, -40, 0, -50),
		})
		tween:Play()
		tween.Completed:Wait()
		
		local tween2 = TweenService:Create(iconContainer, TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, -40, 0, -40),
		})
		tween2:Play()
		tween2.Completed:Wait()
	end
end
task.spawn(bounceIcon)

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Name = "Title"
titleLabel.Size = UDim2.new(1, -40, 0, 50)
titleLabel.Position = UDim2.new(0, 20, 0, 50)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "Welcome!"
titleLabel.TextColor3 = Colors.White
titleLabel.TextScaled = true
titleLabel.Font = Enum.Font.FredokaOne
titleLabel.TextStrokeTransparency = 0
titleLabel.TextStrokeColor3 = Colors.Dark
titleLabel.ZIndex = 103
titleLabel.Parent = tutorialCard

-- Description
local descLabel = Instance.new("TextLabel")
descLabel.Name = "Description"
descLabel.Size = UDim2.new(1, -40, 0, 90)
descLabel.Position = UDim2.new(0, 20, 0, 110)
descLabel.BackgroundTransparency = 1
descLabel.Text = "Tutorial description goes here..."
descLabel.TextColor3 = Colors.White
descLabel.TextSize = 22
descLabel.Font = Enum.Font.GothamBold
descLabel.TextWrapped = true
descLabel.TextXAlignment = Enum.TextXAlignment.Center
descLabel.TextYAlignment = Enum.TextYAlignment.Center
descLabel.ZIndex = 103
descLabel.Parent = tutorialCard

-- Step indicator
local stepIndicator = Instance.new("Frame")
stepIndicator.Name = "StepIndicator"
stepIndicator.Size = UDim2.new(0, 200, 0, 30)
stepIndicator.Position = UDim2.new(0.5, -100, 0, 210)
stepIndicator.BackgroundTransparency = 1
stepIndicator.ZIndex = 103
stepIndicator.Parent = tutorialCard

-- Create step dots
local stepDots = {}
for i = 1, #tutorialSteps do
	local dot = Instance.new("Frame")
	dot.Name = "Dot_" .. i
	dot.Size = UDim2.new(0, 12, 0, 12)
	dot.Position = UDim2.new(0, (i - 1) * 28, 0.5, -6)
	dot.BackgroundColor3 = i == 1 and Colors.Accent or Colors.Dark
	dot.BorderSizePixel = 0
	dot.ZIndex = 104
	dot.Parent = stepIndicator
	createCorner(dot, 6)
	stepDots[i] = dot
end

-- Button container
local buttonContainer = Instance.new("Frame")
buttonContainer.Name = "ButtonContainer"
buttonContainer.Size = UDim2.new(1, -40, 0, 50)
buttonContainer.Position = UDim2.new(0, 20, 0, 220)
buttonContainer.BackgroundTransparency = 1
buttonContainer.ZIndex = 103
buttonContainer.Parent = tutorialCard

-- Previous button
local prevButton = Instance.new("TextButton")
prevButton.Name = "PrevButton"
prevButton.Size = UDim2.new(0, 100, 0, 45)
prevButton.Position = UDim2.new(0, 0, 0, 2)
prevButton.BackgroundColor3 = Colors.Dark
prevButton.Text = "← Back"
prevButton.TextColor3 = Colors.White
prevButton.TextSize = 20
prevButton.Font = Enum.Font.GothamBold
prevButton.ZIndex = 104
prevButton.Parent = buttonContainer

createCorner(prevButton, 10)
createStroke(prevButton, Colors.Silver, 2)

-- Next button
local nextButton = Instance.new("TextButton")
nextButton.Name = "NextButton"
nextButton.Size = UDim2.new(0, 180, 0, 50)
nextButton.Position = UDim2.new(1, -180, 0, 0)
nextButton.BackgroundColor3 = Colors.Success
nextButton.Text = "NEXT →"
nextButton.TextColor3 = Colors.White
nextButton.TextSize = 24
nextButton.Font = Enum.Font.GothamBlack
nextButton.ZIndex = 104
nextButton.Parent = buttonContainer

createGradient(nextButton, {Colors.Success, Colors.Secondary})
createCorner(nextButton, 12)
createStroke(nextButton, Colors.White, 3)

-- Skip button
local skipButton = Instance.new("TextButton")
skipButton.Name = "SkipButton"
skipButton.Size = UDim2.new(0, 80, 0, 30)
skipButton.Position = UDim2.new(1, -90, 1, -35)
skipButton.BackgroundTransparency = 1
skipButton.Text = "Skip Tutorial →"
skipButton.TextColor3 = Colors.Silver
skipButton.TextSize = 14
skipButton.Font = Enum.Font.Gotham
skipButton.ZIndex = 104
skipButton.Parent = tutorialScreen

-- Hand pointer for gestures
local handPointer = Instance.new("ImageLabel")
handPointer.Name = "HandPointer"
handPointer.Size = UDim2.new(0, 60, 0, 60)
handPointer.Position = UDim2.new(0.5, -30, 0.5, -30)
handPointer.BackgroundTransparency = 1
handPointer.Image = "rbxassetid://131296983"
handPointer.ImageColor3 = Colors.White
handPointer.ZIndex = 105
handPointer.Visible = false
handPointer.Parent = tutorialScreen

-- ============================================================================
-- ANIMATION FUNCTIONS
-- ============================================================================

local currentStep = 1
local isTutorialActive = false

local function animateCardIn()
	tutorialCard.Size = UDim2.new(0, 360, 0, 252)
	tutorialCard.Position = tutorialSteps[currentStep].position
	
	local tween = TweenService:Create(tutorialCard, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 400, 0, 280),
	})
	tween:Play()
end

local function animateCardOut(callback: () -> ())
	local tween = TweenService:Create(tutorialCard, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In), {
		Size = UDim2.new(0, 360, 0, 252),
	})
	tween:Play()
	tween.Completed:Connect(function()
		if callback then callback() end
	end)
end

local function updateStepDots()
	for i, dot in ipairs(stepDots) do
		if i == currentStep then
			local tween = TweenService:Create(dot, TweenInfo.new(0.2), {
				BackgroundColor3 = Colors.Accent,
				Size = UDim2.new(0, 16, 0, 16),
			})
			tween:Play()
		else
			local tween = TweenService:Create(dot, TweenInfo.new(0.2), {
				BackgroundColor3 = Colors.Dark,
				Size = UDim2.new(0, 12, 0, 12),
			})
			tween:Play()
		end
	end
end

local function updateCardContent()
	local step = tutorialSteps[currentStep]
	
	-- Update text
	iconLabel.Text = step.icon
	titleLabel.Text = step.title
	descLabel.Text = step.description
	
	-- Update position with animation
	local tween = TweenService:Create(tutorialCard, TweenInfo.new(0.4, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = step.position,
	})
	tween:Play()
	
	-- Update dots
	updateStepDots()
	
	-- Update buttons
	prevButton.Visible = currentStep > 1
	
	if currentStep == #tutorialSteps then
		nextButton.Text = "START! 🚀"
		nextButton.BackgroundColor3 = Colors.Gold
		createGradient(nextButton, {Colors.Gold, Colors.Warning})
	else
		nextButton.Text = "NEXT →"
		nextButton.BackgroundColor3 = Colors.Success
		createGradient(nextButton, {Colors.Success, Colors.Secondary})
	end
	
	-- Show/hide spotlight for highlighting
	if step.highlightArea then
		spotlight.Visible = true
		-- Position spotlight based on highlight area
		handPointer.Visible = true
	else
		spotlight.Visible = false
		handPointer.Visible = false
	end
end

-- ============================================================================
-- BUTTON HANDLERS
-- ============================================================================

nextButton.MouseButton1Click:Connect(function()
	-- Button press animation
	local tween = TweenService:Create(nextButton, TweenInfo.new(0.1), {
		Size = UDim2.new(0, 170, 0, 47),
	})
	tween:Play()
	tween.Completed:Wait()
	
	tween = TweenService:Create(nextButton, TweenInfo.new(0.1), {
		Size = UDim2.new(0, 180, 0, 50),
	})
	tween:Play()
	
	if currentStep < #tutorialSteps then
		currentStep += 1
		updateCardContent()
	else
		-- Tutorial complete
		TutorialUI.Hide()
		-- Save that tutorial was shown
		local tutorialCompleted = Instance.new("BoolValue")
		tutorialCompleted.Name = "TutorialCompleted"
		tutorialCompleted.Value = true
		tutorialCompleted.Parent = player
	end
end)

prevButton.MouseButton1Click:Connect(function()
	if currentStep > 1 then
		currentStep -= 1
		updateCardContent()
	end
end)

skipButton.MouseButton1Click:Connect(function()
	TutorialUI.Hide()
	-- Save that tutorial was skipped
	local tutorialCompleted = Instance.new("BoolValue")
	tutorialCompleted.Name = "TutorialCompleted"
	tutorialCompleted.Value = true
	tutorialCompleted.Parent = player
end)

-- Hover animations
nextButton.MouseEnter:Connect(function()
	local tween = TweenService:Create(nextButton, TweenInfo.new(0.2), {
		Size = UDim2.new(0, 190, 0, 53),
	})
	tween:Play()
end)

nextButton.MouseLeave:Connect(function()
	local tween = TweenService:Create(nextButton, TweenInfo.new(0.2), {
		Size = UDim2.new(0, 180, 0, 50),
	})
	tween:Play()
end)

-- ============================================================================
-- PUBLIC FUNCTIONS
-- ============================================================================

function TutorialUI.Show()
	if isTutorialActive then return end
	
	-- Check if tutorial was already completed
	local existing = player:FindFirstChild("TutorialCompleted")
	if existing and existing.Value then
		return
	end
	
	isTutorialActive = true
	currentStep = 1
	tutorialScreen.Enabled = true
	
	-- Animate in
	overlay.BackgroundTransparency = 1
	tutorialCard.Visible = false
	
	local tween = TweenService:Create(overlay, TweenInfo.new(0.3), {
		BackgroundTransparency = 0.5,
	})
	tween:Play()
	
	task.delay(0.2, function()
		tutorialCard.Visible = true
		updateCardContent()
		animateCardIn()
	end)
	
	-- Show start message after delay
	ReplicatedStorage:WaitForChild("GameEvents"):WaitForChild("ShowTutorial"):FireServer()
end

function TutorialUI.Hide()
	if not isTutorialActive then return end
	
	isTutorialActive = false
	
	animateCardOut(function()
		tutorialScreen.Enabled = false
	end)
	
	local tween = TweenService:Create(overlay, TweenInfo.new(0.3), {
		BackgroundTransparency = 1,
	})
	tween:Play()
end

function TutorialUI.IsActive(): boolean
	return isTutorialActive
end

function TutorialUI.NextStep()
	if currentStep < #tutorialSteps then
		currentStep += 1
		updateCardContent()
	end
end

function TutorialUI.PreviousStep()
	if currentStep > 1 then
		currentStep -= 1
		updateCardContent()
	end
end

-- ============================================================================
-- AUTO-START
-- ============================================================================

-- Show tutorial on first spawn
player.CharacterAdded:Connect(function()
	task.wait(2) -- Wait for other UI to load
	TutorialUI.Show()
end)

-- Also check if character already exists
if player.Character then
	task.spawn(function()
		task.wait(2)
		TutorialUI.Show()
	end)
end

print("[TutorialUI] Tutorial system initialized!")

return TutorialUI
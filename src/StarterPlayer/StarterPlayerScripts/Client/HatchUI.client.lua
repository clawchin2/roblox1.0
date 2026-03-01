-- HatchUI.client.lua
-- Client-side UI for egg hatching with ANIMATED EGG SEQUENCE
-- Flow: Egg appears → Shakes → Cracks → Hatches → Reveal creature

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("[HatchUI] Initializing with Egg Animation...")

-- ============================================
-- WAIT FOR REMOTE EVENT
-- ============================================
local hatchEvent = ReplicatedStorage:WaitForChild("HatchEvent", 10)
if not hatchEvent then
	hatchEvent = Instance.new("RemoteEvent")
	hatchEvent.Name = "HatchEvent"
	hatchEvent.Parent = ReplicatedStorage
end

local hatchRequestEvent = ReplicatedStorage:FindFirstChild("HatchRequest")
if not hatchRequestEvent then
	hatchRequestEvent = Instance.new("RemoteEvent")
	hatchRequestEvent.Name = "HatchRequest"
	hatchRequestEvent.Parent = ReplicatedStorage
end

-- ============================================
-- CREATURE IMAGE IDs
-- ============================================
local CREATURE_IMAGES = {
	["Tiny Dragon"] = "rbxassetid://100352058348043",
	["Baby Unicorn"] = "rbxassetid://111331437291244",
	["Mini Griffin"] = "rbxassetid://111177400493982",
	["Fire Fox"] = "rbxassetid://99173862361424",
	["Ice Wolf"] = "rbxassetid://85023087116411",
	["Thunder Bird"] = "rbxassetid://115102972096254",
	["Phoenix"] = "rbxassetid://118782453217813",
	["Kraken"] = "rbxassetid://135611116481587",
	["Cerberus"] = "rbxassetid://103052472025415",
	["Hydra"] = "rbxassetid://129788824744472",
	["Chimera"] = "rbxassetid://92846288329362",
	["Ancient Dragon"] = "rbxassetid://0",
	["World Serpent"] = "rbxassetid://0",
}

-- ============================================
-- EVOLUTION SYSTEM (NEW)
-- ============================================
-- Each creature evolves into its own advanced form
-- Stage 1 → 2 → 3 → 4
-- Evolution requires 3 of same creature + coins
local EVOLUTION_LINES = {
	{
		base = "Tiny Dragon",
		stages = {
			{stage = 1, name = "Tiny Dragon", coins = 1, image = "rbxassetid://100352058348043"},
			{stage = 2, name = "Dragon", coins = 2, image = "rbxassetid://0"},
			{stage = 3, name = "Great Dragon", coins = 5, image = "rbxassetid://0"},
			{stage = 4, name = "Ancient Dragon", coins = 10, image = "rbxassetid://0"},
		}
	},
	{
		base = "Baby Unicorn",
		stages = {
			{stage = 1, name = "Baby Unicorn", coins = 1, image = "rbxassetid://111331437291244"},
			{stage = 2, name = "Unicorn", coins = 2, image = "rbxassetid://0"},
			{stage = 3, name = "Royal Unicorn", coins = 5, image = "rbxassetid://0"},
			{stage = 4, name = "Celestial Unicorn", coins = 10, image = "rbxassetid://0"},
		}
	},
	{
		base = "Mini Griffin",
		stages = {
			{stage = 1, name = "Mini Griffin", coins = 1, image = "rbxassetid://111177400493982"},
			{stage = 2, name = "Griffin", coins = 2, image = "rbxassetid://0"},
			{stage = 3, name = "Imperial Griffin", coins = 5, image = "rbxassetid://0"},
			{stage = 4, name = "Mythic Griffin", coins = 10, image = "rbxassetid://0"},
		}
	},
	{
		base = "Fire Fox",
		stages = {
			{stage = 1, name = "Fire Fox", coins = 2, image = "rbxassetid://99173862361424"},
			{stage = 2, name = "Flame Fox", coins = 4, image = "rbxassetid://0"},
			{stage = 3, name = "Inferno Fox", coins = 8, image = "rbxassetid://0"},
			{stage = 4, name = "Volcanic Fox", coins = 15, image = "rbxassetid://0"},
		}
	},
	{
		base = "Ice Wolf",
		stages = {
			{stage = 1, name = "Ice Wolf", coins = 2, image = "rbxassetid://85023087116411"},
			{stage = 2, name = "Frost Wolf", coins = 4, image = "rbxassetid://0"},
			{stage = 3, name = "Glacier Wolf", coins = 8, image = "rbxassetid://0"},
			{stage = 4, name = "Arctic Wolf", coins = 15, image = "rbxassetid://0"},
		}
	},
	{
		base = "Thunder Bird",
		stages = {
			{stage = 1, name = "Thunder Bird", coins = 2, image = "rbxassetid://115102972096254"},
			{stage = 2, name = "Storm Bird", coins = 4, image = "rbxassetid://0"},
			{stage = 3, name = "Tempest Bird", coins = 8, image = "rbxassetid://0"},
			{stage = 4, name = "Thunderbird King", coins = 15, image = "rbxassetid://0"},
		}
	},
	{
		base = "Phoenix",
		stages = {
			{stage = 1, name = "Phoenix", coins = 5, image = "rbxassetid://118782453217813"},
			{stage = 2, name = "Firebird", coins = 10, image = "rbxassetid://0"},
			{stage = 3, name = "Sunbird", coins = 20, image = "rbxassetid://0"},
			{stage = 4, name = "Eternal Phoenix", coins = 50, image = "rbxassetid://0"},
		}
	},
	{
		base = "Kraken",
		stages = {
			{stage = 1, name = "Kraken", coins = 5, image = "rbxassetid://135611116481587"},
			{stage = 2, name = "Sea Beast", coins = 10, image = "rbxassetid://0"},
			{stage = 3, name = "Ocean Lord", coins = 20, image = "rbxassetid://0"},
			{stage = 4, name = "Abyssal Kraken", coins = 50, image = "rbxassetid://0"},
		}
	},
	{
		base = "Cerberus",
		stages = {
			{stage = 1, name = "Cerberus", coins = 5, image = "rbxassetid://103052472025415"},
			{stage = 2, name = "Hellhound", coins = 10, image = "rbxassetid://0"},
			{stage = 3, name = "Underworld Guard", coins = 20, image = "rbxassetid://0"},
			{stage = 4, name = "Cerberus Alpha", coins = 50, image = "rbxassetid://0"},
		}
	},
	{
		base = "Hydra",
		stages = {
			{stage = 1, name = "Hydra", coins = 10, image = "rbxassetid://129788824744472"},
			{stage = 2, name = "Multi-Head", coins = 20, image = "rbxassetid://0"},
			{stage = 3, name = "Hydra Emperor", coins = 40, image = "rbxassetid://0"},
			{stage = 4, name = "World Hydra", coins = 100, image = "rbxassetid://0"},
		}
	},
	{
		base = "Chimera",
		stages = {
			{stage = 1, name = "Chimera", coins = 10, image = "rbxassetid://92846288329362"},
			{stage = 2, name = "Beast", coins = 20, image = "rbxassetid://0"},
			{stage = 3, name = "Chimera Lord", coins = 40, image = "rbxassetid://0"},
			{stage = 4, name = "Primordial Chimera", coins = 100, image = "rbxassetid://0"},
		}
	},
}

-- Evolution costs
local EVOLUTION_COSTS = {
	{from = 1, to = 2, coinCost = 100, robuxSkip = 25},
	{from = 2, to = 3, coinCost = 500, robuxSkip = 49},
	{from = 3, to = 4, coinCost = 2000, robuxSkip = 99},
}

-- Helper: Get evolution line for a creature name
function GetEvolutionLine(creatureName)
	for _, line in ipairs(EVOLUTION_LINES) do
		for _, stage in ipairs(line.stages) do
			if stage.name == creatureName then
				return line
			end
		end
	end
	return nil
end

-- ============================================
-- EGG IMAGES (Add your egg decal IDs here)
-- ============================================
local EGG_IMAGES = {
	basic = "rbxassetid://0",      -- Replace with your basic egg texture ID
	fantasy = "rbxassetid://0",    -- Replace with your fantasy egg texture ID
	mythic = "rbxassetid://0",     -- Replace with your mythic egg texture ID
}

-- ============================================
-- RARITY COLORS
-- ============================================
local RARITY_COLORS = {
	Common = Color3.fromRGB(169, 169, 169),
	Uncommon = Color3.fromRGB(0, 255, 0),
	Rare = Color3.fromRGB(0, 100, 255),
	Epic = Color3.fromRGB(150, 0, 255),
	Legendary = Color3.fromRGB(255, 215, 0)
}

local RARITY_GLOW = {
	Common = Color3.fromRGB(100, 100, 100),
	Uncommon = Color3.fromRGB(0, 150, 0),
	Rare = Color3.fromRGB(0, 50, 200),
	Epic = Color3.fromRGB(100, 0, 200),
	Legendary = Color3.fromRGB(255, 180, 0)
}

-- ============================================
-- EGG ANIMATION UI
-- ============================================
local eggAnimationUI = nil
local resultUI = nil
local isAnimating = false

local function createEggAnimationUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "EggAnimationUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	
	-- Dark overlay
	local overlay = Instance.new("Frame")
	overlay.Name = "Overlay"
	overlay.Size = UDim2.new(1, 0, 1, 0)
	overlay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
	overlay.BackgroundTransparency = 0.5
	overlay.BorderSizePixel = 0
	overlay.Parent = screenGui
	
	-- Egg container
	local eggContainer = Instance.new("Frame")
	eggContainer.Name = "EggContainer"
	eggContainer.Size = UDim2.new(0, 200, 0, 250)
	eggContainer.Position = UDim2.new(0.5, -100, 0.5, -125)
	eggContainer.BackgroundTransparency = 1
	eggContainer.Parent = screenGui
	
	-- Egg image
	local eggImage = Instance.new("ImageLabel")
	eggImage.Name = "EggImage"
	eggImage.Size = UDim2.new(1, 0, 0, 200)
	eggImage.Position = UDim2.new(0, 0, 0, 0)
	eggImage.BackgroundTransparency = 1
	eggImage.Image = "rbxassetid://0" -- Will be set based on egg type
	eggImage.ScaleType = Enum.ScaleType.Fit
	eggImage.Parent = eggContainer
	
	-- Egg shadow (for depth)
	local eggShadow = Instance.new("ImageLabel")
	eggShadow.Name = "EggShadow"
	eggShadow.Size = UDim2.new(0.8, 0, 0, 30)
	eggShadow.Position = UDim2.new(0.1, 0, 1, -40)
	eggShadow.BackgroundTransparency = 1
	eggShadow.Image = "rbxassetid://0"
	eggShadow.ImageColor3 = Color3.fromRGB(0, 0, 0)
	eggShadow.ImageTransparency = 0.7
	eggShadow.ScaleType = Enum.ScaleType.Fit
	eggShadow.Parent = eggContainer
	
	-- Status text
	local statusLabel = Instance.new("TextLabel")
	statusLabel.Name = "StatusLabel"
	statusLabel.Size = UDim2.new(1, 0, 0, 40)
	statusLabel.Position = UDim2.new(0, 0, 1, -40)
	statusLabel.BackgroundTransparency = 1
	statusLabel.Text = "Hatching..."
	statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	statusLabel.TextScaled = true
	statusLabel.Font = Enum.Font.GothamBold
	statusLabel.Parent = eggContainer
	
	-- Particle container
	local particleContainer = Instance.new("Frame")
	particleContainer.Name = "Particles"
	particleContainer.Size = UDim2.new(1, 0, 1, 0)
	particleContainer.BackgroundTransparency = 1
	particleContainer.Parent = screenGui
	
	return {
		screenGui = screenGui,
		overlay = overlay,
		eggContainer = eggContainer,
		eggImage = eggImage,
		statusLabel = statusLabel,
		particleContainer = particleContainer
	}
end

-- ============================================
-- RESULT UI (Creature Reveal)
-- ============================================
local function createResultUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HatchResultUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	
	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 450, 0, 400)
	mainFrame.Position = UDim2.new(0.5, -225, 0.5, -200)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent = mainFrame
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Thickness = 4
	stroke.Parent = mainFrame
	
	-- Title
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0, 50)
	titleLabel.Position = UDim2.new(0, 0, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "NEW PET HATCHED!"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = mainFrame
	
	-- Pet name
	local petNameLabel = Instance.new("TextLabel")
	petNameLabel.Name = "PetNameLabel"
	petNameLabel.Size = UDim2.new(1, 0, 0, 45)
	petNameLabel.Position = UDim2.new(0, 0, 0, 65)
	petNameLabel.BackgroundTransparency = 1
	petNameLabel.Text = "Pet Name"
	petNameLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	petNameLabel.TextScaled = true
	petNameLabel.Font = Enum.Font.GothamBlack
	petNameLabel.Parent = mainFrame
	
	-- Rarity label
	local rarityLabel = Instance.new("TextLabel")
	rarityLabel.Name = "RarityLabel"
	rarityLabel.Size = UDim2.new(1, 0, 0, 30)
	rarityLabel.Position = UDim2.new(0, 0, 0, 110)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = "RARITY"
	rarityLabel.TextColor3 = Color3.fromRGB(169, 169, 169)
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = mainFrame
	
	-- Pet display (circular)
	local petDisplay = Instance.new("Frame")
	petDisplay.Name = "PetDisplay"
	petDisplay.Size = UDim2.new(0, 120, 0, 120)
	petDisplay.Position = UDim2.new(0.5, -60, 0, 150)
	petDisplay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	petDisplay.BorderSizePixel = 0
	petDisplay.ClipsDescendants = true
	petDisplay.Parent = mainFrame
	
	local petCorner = Instance.new("UICorner")
	petCorner.CornerRadius = UDim.new(1, 0)
	petCorner.Parent = petDisplay
	
	local petStroke = Instance.new("UIStroke")
	petStroke.Color = Color3.fromRGB(255, 255, 255)
	petStroke.Thickness = 4
	petStroke.Parent = petDisplay
	
	-- Pet image
	local petImage = Instance.new("ImageLabel")
	petImage.Name = "PetImage"
	petImage.Size = UDim2.new(1, 0, 1, 0)
	petImage.BackgroundTransparency = 1
	petImage.Image = ""
	petImage.ScaleType = Enum.ScaleType.Crop
	petImage.Parent = petDisplay
	
	local imageCorner = Instance.new("UICorner")
	imageCorner.CornerRadius = UDim.new(1, 0)
	imageCorner.Parent = petImage
	
	-- Stats frame
	local statsFrame = Instance.new("Frame")
	statsFrame.Name = "StatsFrame"
	statsFrame.Size = UDim2.new(0.9, 0, 0, 35)
	statsFrame.Position = UDim2.new(0.05, 0, 0, 285)
	statsFrame.BackgroundTransparency = 1
	statsFrame.Parent = mainFrame
	
	local statsLayout = Instance.new("UIListLayout")
	statsLayout.FillDirection = Enum.FillDirection.Horizontal
	statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	statsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	statsLayout.Padding = UDim.new(0, 20)
	statsLayout.Parent = statsFrame
	
	-- Speed
	local speedLabel = Instance.new("TextLabel")
	speedLabel.Name = "SpeedLabel"
	speedLabel.Size = UDim2.new(0, 100, 0, 30)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Text = "Speed: 0"
	speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	speedLabel.TextScaled = true
	speedLabel.Font = Enum.Font.GothamBold
	speedLabel.Parent = statsFrame
	
	-- Coins
	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "CoinsLabel"
	coinsLabel.Size = UDim2.new(0, 100, 0, 30)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "1x Coins"
	coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	coinsLabel.TextScaled = true
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.Parent = statsFrame
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 180, 0, 50)
	closeButton.Position = UDim2.new(0.5, -90, 1, -10)
	closeButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	closeButton.Text = "AWESOME!"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = mainFrame
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 10)
	closeCorner.Parent = closeButton
	
	closeButton.MouseButton1Click:Connect(function()
		mainFrame.Visible = false
		screenGui.Enabled = false
	end)
	
	return {
		screenGui = screenGui,
		mainFrame = mainFrame,
		titleLabel = titleLabel,
		petNameLabel = petNameLabel,
		rarityLabel = rarityLabel,
		petDisplay = petDisplay,
		petImage = petImage,
		petStroke = petStroke,
		stroke = stroke,
		speedLabel = speedLabel,
		coinsLabel = coinsLabel,
		closeButton = closeButton
	}
end

-- ============================================
-- SHAKE ANIMATION (Slower, more dramatic)
-- ============================================
local function shakeEgg(eggImage, intensity, duration)
	local startTime = tick()
	local originalPosition = eggImage.Position
	
	while tick() - startTime < duration do
		local offsetX = math.random(-intensity, intensity)
		local offsetY = math.random(-intensity, intensity)
		local rotation = math.random(-8, 8)
		
		eggImage.Position = UDim2.new(
			originalPosition.X.Scale, originalPosition.X.Offset + offsetX,
			originalPosition.Y.Scale, originalPosition.Y.Offset + offsetY
		)
		eggImage.Rotation = rotation
		
		task.wait(0.05) -- Slower shake updates
	end
	
	eggImage.Position = originalPosition
	eggImage.Rotation = 0
end

-- ============================================
-- PARTICLE EFFECT
-- ============================================
local function spawnParticles(container, color, count)
	for i = 1, count do
		local particle = Instance.new("Frame")
		particle.Size = UDim2.new(0, math.random(4, 10), 0, math.random(4, 10))
		particle.Position = UDim2.new(0.5, math.random(-100, 100), 0.5, math.random(-100, 100))
		particle.BackgroundColor3 = color or Color3.fromRGB(255, 255, 0)
		particle.BorderSizePixel = 0
		particle.Parent = container
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(1, 0)
		corner.Parent = particle
		
		-- Animate outward
		local angle = math.random() * math.pi * 2
		local distance = math.random(50, 200)
		local targetX = math.cos(angle) * distance
		local targetY = math.sin(angle) * distance
		
		local tween = TweenService:Create(particle, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
			Position = UDim2.new(0.5, targetX, 0.5, targetY),
			Size = UDim2.new(0, 0, 0, 0),
			BackgroundTransparency = 1
		})
		tween:Play()
		
		tween.Completed:Connect(function()
			particle:Destroy()
		end)
	end
end

-- ============================================
-- CLOSE SHOP/PURCHASE WINDOWS
-- ============================================
local function closeShopWindows()
	-- Close GameUI EggShopFrame (Egg Shop) - try multiple possible names
	local gameUI = playerGui:FindFirstChild("GameUI")
	if gameUI then
		-- Try EggShopFrame first (new name)
		local shopFrame = gameUI:FindFirstChild("EggShopFrame")
		if shopFrame then
			shopFrame.Visible = false
			print("[HatchUI] Closed GameUI.EggShopFrame")
		else
			-- Fallback: look for frame with "EGG" in title
			for _, child in ipairs(gameUI:GetChildren()) do
				if child:IsA("Frame") or child:IsA("ScrollingFrame") then
					local titleLabel = child:FindFirstChild("TextLabel")
					if titleLabel and titleLabel.Text and string.find(titleLabel.Text:upper(), "EGG") then
						child.Visible = false
						print("[HatchUI] Closed egg shop by title: " .. child.Name)
						break
					end
				end
			end
		end
	end
	
	-- Close EndlessEscapeUI CosmeticShop
	local endlessUI = playerGui:FindFirstChild("EndlessEscapeUI")
	if endlessUI then
		local cosmeticShop = endlessUI:FindFirstChild("CosmeticShop")
		if cosmeticShop then
			cosmeticShop.Visible = false
			print("[HatchUI] Closed EndlessEscapeUI.CosmeticShop")
		end
	end
	
	-- Close InventorySystem
	local invSystem = playerGui:FindFirstChild("InventorySystem")
	if invSystem then
		invSystem.Enabled = false
		print("[HatchUI] Closed InventorySystem")
	end
	
	print("[HatchUI] Shop windows closed")
end

-- ============================================
-- MAIN HATCH SEQUENCE
-- ============================================
local function playHatchSequence(petData, eggType)
	if isAnimating then return end
	isAnimating = true
	
	-- CLOSE SHOP WINDOWS FIRST
	closeShopWindows()
	
	-- Brief pause after closing shop before animation starts
	task.wait(0.3)
	
	-- Create or get UI
	if not eggAnimationUI then
		eggAnimationUI = createEggAnimationUI()
	end
	
	local ui = eggAnimationUI
	ui.screenGui.Enabled = true
	
	-- Set egg image based on type
	local eggImageId = EGG_IMAGES[eggType] or EGG_IMAGES.basic
	if eggImageId and eggImageId ~= "rbxassetid://0" then
		ui.eggImage.Image = eggImageId
	else
		-- Default egg appearance
		ui.eggImage.BackgroundColor3 = Color3.fromRGB(200, 150, 100)
		ui.eggImage.BackgroundTransparency = 0
	end
	
	-- Reset
	ui.eggImage.Size = UDim2.new(1, 0, 0, 200)
	ui.eggImage.Position = UDim2.new(0, 0, 0, 0)
	ui.eggImage.ImageTransparency = 0
	ui.eggImage.Rotation = 0
	ui.statusLabel.Text = "Hatching..."
	
	-- Fade in overlay (slower)
	ui.overlay.BackgroundTransparency = 1
	TweenService:Create(ui.overlay, TweenInfo.new(0.5), {BackgroundTransparency = 0.5}):Play()
	
	-- PHASE 1: Egg appears and pulses (slower)
	ui.eggContainer.Size = UDim2.new(0, 0, 0, 0)
	TweenService:Create(ui.eggContainer, TweenInfo.new(0.8, Enum.EasingStyle.Back), {
		Size = UDim2.new(0, 200, 0, 250)
	}):Play()
	
	task.wait(1.0)
	
	-- PHASE 2: Shaking (intensity increases - LONGER DURATION)
	ui.statusLabel.Text = "Something's moving..."
	
	-- Light shake (longer)
	shakeEgg(ui.eggImage, 4, 1.0)
	task.wait(0.4)
	
	-- Medium shake (longer)
	ui.statusLabel.Text = "Something is stirring..."
	shakeEgg(ui.eggImage, 8, 1.2)
	task.wait(0.4)
	
	-- Heavy shake (longer)
	ui.statusLabel.Text = "It's hatching!"
	shakeEgg(ui.eggImage, 15, 1.5)
	
	-- PHASE 3: Hatch burst (slower)
	local rarityColor = RARITY_COLORS[petData.rarity] or Color3.fromRGB(255, 215, 0)
	spawnParticles(ui.particleContainer, rarityColor, 40)
	
	-- Flash effect (longer)
	local flash = Instance.new("Frame")
	flash.Size = UDim2.new(1, 0, 1, 0)
	flash.BackgroundColor3 = Color3.new(1, 1, 1)
	flash.BorderSizePixel = 0
	flash.Parent = ui.screenGui
	
	TweenService:Create(flash, TweenInfo.new(0.5), {BackgroundTransparency = 1}):Play()
	
	-- Egg scale down and fade (slower)
	TweenService:Create(ui.eggImage, TweenInfo.new(0.5, Enum.EasingStyle.Back), {
		Size = UDim2.new(1.8, 0, 0, 360),
		ImageTransparency = 1
	}):Play()
	
	task.wait(0.6)
	flash:Destroy()
	
	-- Pause before showing result (dramatic effect)
	task.wait(0.5)
	
	-- Hide egg UI
	ui.screenGui.Enabled = false
	
	-- PHASE 4: Show result
	showResultPopup(petData)
	
	isAnimating = false
end

-- ============================================
-- RESULT POPUP
-- ============================================
function showResultPopup(petData)
	if not resultUI then
		resultUI = createResultUI()
	end
	
	local ui = resultUI
	
	-- Set content
	ui.petNameLabel.Text = petData.name or "Unknown Pet"
	ui.rarityLabel.Text = (petData.rarity or "Common"):upper()
	
	local rarityColor = RARITY_COLORS[petData.rarity] or Color3.fromRGB(255, 255, 255)
	local glowColor = RARITY_GLOW[petData.rarity] or rarityColor
	
	ui.petNameLabel.TextColor3 = rarityColor
	ui.rarityLabel.TextColor3 = rarityColor
	ui.petDisplay.BackgroundColor3 = rarityColor
	ui.petStroke.Color = glowColor
	ui.stroke.Color = glowColor
	
	-- Set creature image
	local imageId = CREATURE_IMAGES[petData.name] or ""
	if imageId and imageId ~= "" and imageId ~= "rbxassetid://0" then
		ui.petImage.Image = imageId
		ui.petImage.Visible = true
	else
		ui.petImage.Visible = false
	end
	
	-- Stats with debug logging
	local stats = petData.stats or {}
	local speedVal = tonumber(stats.speed) or tonumber(petData.speed) or 0
	ui.speedLabel.Text = "Speed: " .. speedVal
	
	-- Coin multiplier with fallback chain
	local coinMult = 1
	if stats.coins then
		coinMult = tonumber(stats.coins) or 1
	elseif petData.coins then
		coinMult = tonumber(petData.coins) or 1
	end
	
	-- DEBUG: Log what we received
	print("[HatchUI] Coin data - stats.coins: " .. tostring(stats.coins) .. ", petData.coins: " .. tostring(petData.coins) .. ", final: " .. coinMult)
	
	ui.coinsLabel.Text = coinMult .. "x Coins"
	
	-- Show with animation
	ui.screenGui.Enabled = true
	ui.mainFrame.Visible = true
	ui.mainFrame.Size = UDim2.new(0, 0, 0, 0)
	ui.mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	
	TweenService:Create(ui.mainFrame, TweenInfo.new(0.6, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
		Size = UDim2.new(0, 450, 0, 400),
		Position = UDim2.new(0.5, -225, 0.5, -200)
	}):Play()
	
	-- Play sound
	local SoundManager = nil
	pcall(function()
		SoundManager = require(ReplicatedStorage.Modules:WaitForChild("SoundManager", 2))
	end)
	
	if SoundManager then
		if petData.rarity == "Legendary" then
			SoundManager:Play("LegendaryHatch")
		elseif petData.rarity == "Rare" or petData.rarity == "Epic" then
			SoundManager:Play("RareHatch")
		else
			SoundManager:Play("HatchSuccess")
		end
	end
	
	-- Update equipped UI
	updateEquippedUI(petData)
end

function updateEquippedUI(petData)
	local equippedEvent = ReplicatedStorage:FindFirstChild("EquippedPetEvent")
	if equippedEvent then
		equippedEvent:FireClient(player, petData)
	end
	player:SetAttribute("EquippedPet", petData.id)
	player:SetAttribute("EquippedPetName", petData.name)
	player:SetAttribute("EquippedPetRarity", petData.rarity)
end

-- ============================================
-- REMOTE EVENT HANDLER
-- ============================================
hatchEvent.OnClientEvent:Connect(function(data)
	if not data or typeof(data) ~= "table" then
		warn("[HatchUI] Invalid data received")
		return
	end
	
	if data.success == false then
		-- Show error
		local errorGui = Instance.new("ScreenGui")
		errorGui.Name = "ErrorNotification"
		errorGui.Parent = playerGui
		
		local errorFrame = Instance.new("Frame")
		errorFrame.Size = UDim2.new(0, 350, 0, 80)
		errorFrame.Position = UDim2.new(0.5, -175, 0, 100)
		errorFrame.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		errorFrame.Parent = errorGui
		
		Instance.new("UICorner", errorFrame).CornerRadius = UDim.new(0, 10)
		
		local errorLabel = Instance.new("TextLabel")
		errorLabel.Size = UDim2.new(1, -20, 1, 0)
		errorLabel.Position = UDim2.new(0, 10, 0, 0)
		errorLabel.BackgroundTransparency = 1
		errorLabel.Text = "❌ " .. (data.error or "Hatch failed")
		errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		errorLabel.TextScaled = true
		errorLabel.Font = Enum.Font.GothamBold
		errorLabel.Parent = errorFrame
		
		task.delay(3, function()
			errorGui:Destroy()
		end)
		return
	end
	
	if data.success == true then
		-- Play full egg hatch sequence
		playHatchSequence(data, data.eggType or "basic")
	end
end)

-- ============================================
-- PUBLIC API
-- ============================================
function requestHatch(eggType)
	print("[HatchUI] Requesting hatch for " .. (eggType or "basic") .. " egg")
	hatchRequestEvent:FireServer(eggType)
end

print("[HatchUI] Ready! Egg animation system loaded.")

return {
	requestHatch = requestHatch,
	showResultPopup = showResultPopup
}

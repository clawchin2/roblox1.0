-- HatchUI.client.lua
-- Client-side UI for egg hatching popup
-- FIXED: Ensures RemoteEvent exists before connecting

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local ContentProvider = game:GetService("ContentProvider")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("[HatchUI] Initializing...")

-- ============================================
-- WAIT FOR REMOTE EVENT (FIXED)
-- ============================================

-- FIXED: Wait for event to exist before connecting
local hatchEvent = ReplicatedStorage:WaitForChild("HatchEvent", 10)
if not hatchEvent then
	warn("[HatchUI] HatchEvent not found after waiting 10 seconds!")
	-- Create as fallback
	hatchEvent = Instance.new("RemoteEvent")
	hatchEvent.Name = "HatchEvent"
	hatchEvent.Parent = ReplicatedStorage
end

-- Get or create hatch request event
local hatchRequestEvent = ReplicatedStorage:FindFirstChild("HatchRequest")
if not hatchRequestEvent then
	hatchRequestEvent = Instance.new("RemoteEvent")
	hatchRequestEvent.Name = "HatchRequest"
	hatchRequestEvent.Parent = ReplicatedStorage
end

print("[HatchUI] Remote events connected")

-- ============================================
-- CREATURE IMAGE IDs (Upload your images to Roblox and paste IDs here)
-- ============================================

local CREATURE_IMAGES = {
	-- Common (Texture IDs from Studio)
	["Tiny Dragon"] = "rbxassetid://100352058348043",
	["Baby Unicorn"] = "rbxassetid://111331437291244",
	["Mini Griffin"] = "rbxassetid://111177400493982",

	-- Uncommon
	["Fire Fox"] = "rbxassetid://99173862361424",
	["Ice Wolf"] = "rbxassetid://85023087116411",
	["Thunder Bird"] = "rbxassetid://115102972096254",

	-- Rare
	["Phoenix"] = "rbxassetid://118782453217813",
	["Kraken"] = "rbxassetid://135611116481587",
	["Cerberus"] = "rbxassetid://103052472025415",

	-- Epic
	["Hydra"] = "rbxassetid://129788824744472",
	["Chimera"] = "rbxassetid://92846288329362",

	-- Legendary (waiting for images)
	["Ancient Dragon"] = "rbxassetid://0",
	["World Serpent"] = "rbxassetid://0",
}

-- Print all image IDs for debugging
print("[HatchUI] Creature Images Configured:")
for name, id in pairs(CREATURE_IMAGES) do
	print("  - " .. name .. ": " .. id)
end

-- ============================================
-- RARITY COLORS (From Expert Knowledge)
-- ============================================

local RARITY_COLORS = {
	Common = Color3.fromRGB(169, 169, 169),    -- Gray
	Uncommon = Color3.fromRGB(0, 255, 0),      -- Green
	Rare = Color3.fromRGB(0, 100, 255),        -- Blue
	Epic = Color3.fromRGB(150, 0, 255),        -- Purple
	Legendary = Color3.fromRGB(255, 215, 0)    -- Gold
}

local RARITY_GLOW = {
	Common = Color3.fromRGB(100, 100, 100),
	Uncommon = Color3.fromRGB(0, 150, 0),
	Rare = Color3.fromRGB(0, 50, 200),
	Epic = Color3.fromRGB(100, 0, 200),
	Legendary = Color3.fromRGB(255, 180, 0)
}

-- ============================================
-- UI CREATION
-- ============================================

local hatchPopup = nil
local isShowing = false

local function createHatchPopup()
	-- Create ScreenGui
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "HatchPopupUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = playerGui
	
	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "HatchFrame"
	mainFrame.Size = UDim2.new(0, 400, 0, 320)
	mainFrame.Position = UDim2.new(0.5, -200, 0.5, -160)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	mainFrame.BorderSizePixel = 0
	mainFrame.Visible = false
	mainFrame.Parent = screenGui
	
	-- Corner radius
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 20)
	corner.Parent = mainFrame
	
	-- Glow border
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 215, 0)
	stroke.Thickness = 4
	stroke.Parent = mainFrame
	
	-- Title label
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Name = "TitleLabel"
	titleLabel.Size = UDim2.new(1, 0, 0, 50)
	titleLabel.Position = UDim2.new(0, 0, 0, 10)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Text = "🎉 NEW PET HATCHED! 🎉"
	titleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	titleLabel.TextScaled = true
	titleLabel.Font = Enum.Font.GothamBold
	titleLabel.Parent = mainFrame
	
	-- Pet name label
	local petNameLabel = Instance.new("TextLabel")
	petNameLabel.Name = "PetNameLabel"
	petNameLabel.Size = UDim2.new(1, 0, 0, 45)
	petNameLabel.Position = UDim2.new(0, 0, 0, 70)
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
	rarityLabel.Position = UDim2.new(0, 0, 0, 115)
	rarityLabel.BackgroundTransparency = 1
	rarityLabel.Text = "RARITY"
	rarityLabel.TextColor3 = Color3.fromRGB(169, 169, 169)
	rarityLabel.TextScaled = true
	rarityLabel.Font = Enum.Font.GothamBold
	rarityLabel.Parent = mainFrame
	
	-- Pet display frame (circular background)
	local petDisplay = Instance.new("Frame")
	petDisplay.Name = "PetDisplay"
	petDisplay.Size = UDim2.new(0, 100, 0, 100)
	petDisplay.Position = UDim2.new(0.5, -50, 0, 155)
	petDisplay.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	petDisplay.BorderSizePixel = 0
	petDisplay.ClipsDescendants = true -- Clip to circle
	petDisplay.Parent = mainFrame
	
	local petCorner = Instance.new("UICorner")
	petCorner.CornerRadius = UDim.new(1, 0)
	petCorner.Parent = petDisplay
	
	-- Pet display glow
	local petStroke = Instance.new("UIStroke")
	petStroke.Color = Color3.fromRGB(255, 255, 255)
	petStroke.Thickness = 4
	petStroke.Parent = petDisplay
	
	-- Creature 2D Image (Circular)
	local petImage = Instance.new("ImageLabel")
	petImage.Name = "PetImage"
	petImage.Size = UDim2.new(1, 0, 1, 0)
	petImage.Position = UDim2.new(0, 0, 0, 0)
	petImage.BackgroundTransparency = 1
	petImage.Image = "" -- Will be set when showing
	petImage.ScaleType = Enum.ScaleType.Crop -- Crop to fill circle
	petImage.ImageColor3 = Color3.fromRGB(255, 255, 255) -- Ensure white tint
	petImage.Parent = petDisplay
	
	-- Make image circular
	local imageCorner = Instance.new("UICorner")
	imageCorner.CornerRadius = UDim.new(1, 0)
	imageCorner.Parent = petImage
	
	-- DEBUG: Image loading status
	local imageStatus = Instance.new("TextLabel")
	imageStatus.Name = "ImageStatus"
	imageStatus.Size = UDim2.new(1, 0, 0, 20)
	imageStatus.Position = UDim2.new(0, 0, 0.5, -10)
	imageStatus.BackgroundTransparency = 1
	imageStatus.Text = "📷"
	imageStatus.TextColor3 = Color3.fromRGB(100, 100, 100)
	imageStatus.TextScaled = true
	imageStatus.Font = Enum.Font.GothamBold
	imageStatus.Visible = false -- Hidden by default
	imageStatus.Parent = petImage
	
	-- Stats frame
	local statsFrame = Instance.new("Frame")
	statsFrame.Name = "StatsFrame"
	statsFrame.Size = UDim2.new(0.9, 0, 0, 35)
	statsFrame.Position = UDim2.new(0.05, 0, 0, 265)
	statsFrame.BackgroundTransparency = 1
	statsFrame.Parent = mainFrame
	
	local statsLayout = Instance.new("UIListLayout")
	statsLayout.FillDirection = Enum.FillDirection.Horizontal
	statsLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
	statsLayout.VerticalAlignment = Enum.VerticalAlignment.Center
	statsLayout.Padding = UDim.new(0, 15)
	statsLayout.Parent = statsFrame
	
	-- Speed stat
	local speedLabel = Instance.new("TextLabel")
	speedLabel.Name = "SpeedLabel"
	speedLabel.Size = UDim2.new(0, 90, 0, 30)
	speedLabel.BackgroundTransparency = 1
	speedLabel.Text = "Speed: 0"
	speedLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	speedLabel.TextScaled = true
	speedLabel.Font = Enum.Font.GothamBold
	speedLabel.Parent = statsFrame
	
	-- Jump stat
	local jumpLabel = Instance.new("TextLabel")
	jumpLabel.Name = "JumpLabel"
	jumpLabel.Size = UDim2.new(0, 90, 0, 30)
	jumpLabel.BackgroundTransparency = 1
	jumpLabel.Text = "Jump: 0"
	jumpLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	jumpLabel.TextScaled = true
	jumpLabel.Font = Enum.Font.GothamBold
	jumpLabel.Parent = statsFrame
	
	-- Coins stat
	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "CoinsLabel"
	coinsLabel.Size = UDim2.new(0, 90, 0, 30)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "x1 coins"
	coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	coinsLabel.TextScaled = true
	coinsLabel.Font = Enum.Font.GothamBold
	coinsLabel.Parent = statsFrame
	
	-- Close button
	local closeButton = Instance.new("TextButton")
	closeButton.Name = "CloseButton"
	closeButton.Size = UDim2.new(0, 150, 0, 45)
	closeButton.Position = UDim2.new(0.5, -75, 1, -5)
	closeButton.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
	closeButton.Text = "AWESOME!"
	closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
	closeButton.TextScaled = true
	closeButton.Font = Enum.Font.GothamBold
	closeButton.Parent = mainFrame
	
	local closeCorner = Instance.new("UICorner")
	closeCorner.CornerRadius = UDim.new(0, 10)
	closeCorner.Parent = closeButton
	
	-- Click handler
	closeButton.MouseButton1Click:Connect(function()
		hideHatchPopup()
	end)
	
	return {
		screenGui = screenGui,
		mainFrame = mainFrame,
		titleLabel = titleLabel,
		petNameLabel = petNameLabel,
		rarityLabel = rarityLabel,
		petDisplay = petDisplay,
		petImage = petImage,
		imageStatus = imageStatus,
		petStroke = petStroke,
		speedLabel = speedLabel,
		jumpLabel = jumpLabel,
		coinsLabel = coinsLabel,
		stroke = stroke,
		closeButton = closeButton
	}
end

-- ============================================
-- SHOW/HIDE FUNCTIONS
-- ============================================

function showHatchPopup(petData)
	if isShowing then
		hideHatchPopup()
		task.wait(0.2)
	end
	
	if not hatchPopup then
		hatchPopup = createHatchPopup()
	end
	
	-- SAFELY update content with nil checks
	hatchPopup.petNameLabel.Text = petData.name or "Unknown Pet"
	hatchPopup.rarityLabel.Text = (petData.rarity or "Common"):upper()
	
	-- Set rarity colors
	local rarityColor = RARITY_COLORS[petData.rarity] or Color3.fromRGB(255, 255, 255)
	local glowColor = RARITY_GLOW[petData.rarity] or rarityColor
	
	hatchPopup.petNameLabel.TextColor3 = rarityColor
	hatchPopup.rarityLabel.TextColor3 = rarityColor
	hatchPopup.petDisplay.BackgroundColor3 = rarityColor
	hatchPopup.petStroke.Color = glowColor
	hatchPopup.stroke.Color = glowColor
	
	-- Set creature image with DEBUG logging
	local imageId = CREATURE_IMAGES[petData.name] or ""
	print("[HatchUI] Looking for image: '" .. petData.name .. "' -> ID: '" .. imageId .. "'")
	
	if imageId and imageId ~= "" and imageId ~= "rbxassetid://0" then
		hatchPopup.petImage.Image = imageId
		hatchPopup.petImage.Visible = true
		hatchPopup.imageStatus.Visible = false
		print("[HatchUI] Set image to: " .. imageId)
		
		-- Try to preload the image
		task.spawn(function()
			local success, err = pcall(function()
				ContentProvider:PreloadAsync({hatchPopup.petImage})
			end)
			if success then
				print("[HatchUI] Image preloaded successfully")
			else
				warn("[HatchUI] Image preload failed: " .. tostring(err))
			end
		end)
	else
		-- No image found - show debug info
		hatchPopup.petImage.Visible = false
		hatchPopup.imageStatus.Visible = true
		hatchPopup.imageStatus.Text = "❓"
		warn("[HatchUI] No image found for: '" .. petData.name .. "'")
		
		-- List available images for debugging
		print("[HatchUI] Available creature images:")
		for name, _ in pairs(CREATURE_IMAGES) do
			print("  - " .. name)
		end
	end
	
	-- Update stats safely
	local stats = petData.stats or {}
	hatchPopup.speedLabel.Text = "Speed: " .. (tonumber(stats.speed) or tonumber(petData.speed) or 0)
	hatchPopup.jumpLabel.Text = "Jump: " .. (tonumber(stats.jump) or tonumber(petData.jump) or 0)
	
	-- Coin multiplier display
	local coinMultiplier = tonumber(stats.coins) or tonumber(petData.coins) or 1
	hatchPopup.coinsLabel.Text = "x" .. coinMultiplier .. " coins"
	
	-- Show popup with animation
	hatchPopup.mainFrame.Visible = true
	hatchPopup.mainFrame.Size = UDim2.new(0, 0, 0, 0)
	hatchPopup.mainFrame.Position = UDim2.new(0.5, 0, 0.5, 0)
	
	isShowing = true
	
	-- Animate in with Back easing
	local tweenInfo = TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out)
	targetSize = UDim2.new(0, 400, 0, 320)
	targetPos = UDim2.new(0.5, -200, 0.5, -160)
	
	local sizeTween = TweenService:Create(hatchPopup.mainFrame, tweenInfo, {Size = targetSize})
	local posTween = TweenService:Create(hatchPopup.mainFrame, tweenInfo, {Position = targetPos})
	
	sizeTween:Play()
	posTween:Play()
	
	-- Play sound if available
	local SoundManager = nil
	pcall(function()
		SoundManager = require(ReplicatedStorage.Modules:WaitForChild("SoundManager", 2))
	end)
	
	if SoundManager then
		if petData.rarity == "Legendary" then
			SoundManager:Play("LegendaryHatch")
		elseif petData.rarity == "Rare" then
			SoundManager:Play("RareHatch")
		else
			SoundManager:Play("HatchSuccess")
		end
	end
	
	-- Update Equipped UI
	updateEquippedUI(petData)
	
	print("[HatchUI] Showing hatch popup for " .. petData.name .. " (" .. petData.rarity .. ")")
end

function hideHatchPopup()
	if not hatchPopup or not isShowing then
		return
	end
	
	local tweenInfo = TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.In)
	targetSize = UDim2.new(0, 0, 0, 0)
	targetPos = UDim2.new(0.5, 0, 0.5, 0)
	
	local sizeTween = TweenService:Create(hatchPopup.mainFrame, tweenInfo, {Size = targetSize})
	local posTween = TweenService:Create(hatchPopup.mainFrame, tweenInfo, {Position = targetPos})
	
	sizeTween:Play()
	posTween:Play()
	
	sizeTween.Completed:Connect(function()
		hatchPopup.mainFrame.Visible = false
		isShowing = false
	end)
end

-- ============================================
-- UPDATE EQUIPPED UI
-- ============================================

function updateEquippedUI(petData)
	-- Fire event to EquippedUI if it exists
	local equippedEvent = ReplicatedStorage:FindFirstChild("EquippedPetEvent")
	if equippedEvent then
		equippedEvent:FireClient(player, petData)
	end
	
	-- Also set player attributes for persistence
	player:SetAttribute("EquippedPet", petData.id)
	player:SetAttribute("EquippedPetName", petData.name)
	player:SetAttribute("EquippedPetRarity", petData.rarity)
end

-- ============================================
-- REMOTE EVENT HANDLER (FIXED FOR SINGLE TABLE FORMAT)
-- ============================================

hatchEvent.OnClientEvent:Connect(function(data)
	-- Server sends single table: {success = false, error = "..."} or {success = true, name = "...", ...}
	if not data or typeof(data) ~= "table" then
		warn("[HatchUI] Invalid data received from server")
		return
	end
	
	if data.success == false then
		-- Show error notification
		local errorMessage = data.error or "Hatch failed"
		print("[HatchUI] Hatch error: " .. errorMessage)
		
		local errorGui = Instance.new("ScreenGui")
		errorGui.Name = "ErrorNotification"
		errorGui.Parent = playerGui
		
		local errorFrame = Instance.new("Frame")
		errorFrame.Size = UDim2.new(0, 350, 0, 80)
		errorFrame.Position = UDim2.new(0.5, -175, 0, 100)
		errorFrame.BackgroundColor3 = Color3.fromRGB(200, 50, 50)
		errorFrame.Parent = errorGui
		
		local corner = Instance.new("UICorner")
		corner.CornerRadius = UDim.new(0, 10)
		corner.Parent = errorFrame
		
		local errorLabel = Instance.new("TextLabel")
		errorLabel.Size = UDim2.new(1, -20, 1, 0)
		errorLabel.Position = UDim2.new(0, 10, 0, 0)
		errorLabel.BackgroundTransparency = 1
		errorLabel.Text = "❌ " .. errorMessage
		errorLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
		errorLabel.TextScaled = true
		errorLabel.Font = Enum.Font.GothamBold
		errorLabel.Parent = errorFrame
		
		task.delay(3, function()
			errorGui:Destroy()
		end)
		
		return
	end
	
	-- Success - show hatch popup
	if data.success == true then
		showHatchPopup(data)
	end
end)

-- ============================================
-- PUBLIC API
-- ============================================

function requestHatch(eggType)
	print("[HatchUI] Requesting hatch for " .. (eggType or "basic") .. " egg")
	hatchRequestEvent:FireServer(eggType)
end

print("[HatchUI] Ready! Listening for hatch events.")

return {
	requestHatch = requestHatch,
	showHatchPopup = showHatchPopup,
	hideHatchPopup = hideHatchPopup
}

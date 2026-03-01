-- IdleCollector.client.lua
-- AFK Coin Collection + Player Tapping + Limited Drops
-- Location: StarterPlayerScripts/Client/

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")
local character = player.Character or player.CharacterAdded:Wait()

print("[IdleCollector] Initializing...")

-- ============================================
-- CONFIGURATION
-- ============================================
local IDLE_CONFIG = {
	-- Base coin generation per second by pet stage
	stageRates = {
		[1] = 1,    -- Stage 1: 1 coin/s
		[2] = 3,    -- Stage 2: 3 coin/s
		[3] = 8,    -- Stage 3: 8 coin/s
		[4] = 20,   -- Stage 4: 20 coin/s
	},
	
	-- Rarity multipliers
	rarityMultipliers = {
		Common = 1,
		Uncommon = 1.5,
		Rare = 2.5,
		Epic = 5,
		Legendary = 10,
	},
	
	-- Player tapping
	tapCooldown = 3,           -- Seconds between taps on same player
	tapCoinPercent = 0.05,     -- Steal 5% of their idle coins
	maxTapCoins = 50,          -- Max coins per tap
	
	-- Limited drops
	limitedDropInterval = 300, -- Every 5 minutes
	limitedDropDuration = 60,  -- Available for 60 seconds
}

-- ============================================
-- UI CREATION - Idle Coin Display
-- ============================================
local function createIdleUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "IdleCollectorUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- Main coin display frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "IdleFrame"
	mainFrame.Size = UDim2.new(0, 280, 0, 100)
	mainFrame.Position = UDim2.new(0, 20, 0.5, -50)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	
	Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 12)
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(100, 200, 100)
	stroke.Thickness = 2
	stroke.Parent = mainFrame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 25)
	title.Position = UDim2.new(0, 0, 0, 5)
	title.BackgroundTransparency = 1
	title.Text = "AFK EARNINGS"
	title.TextColor3 = Color3.fromRGB(100, 200, 100)
	title.TextSize = 16
	title.Font = Enum.Font.GothamBold
	title.Parent = mainFrame
	
	-- Current rate display
	local rateLabel = Instance.new("TextLabel")
	rateLabel.Name = "RateLabel"
	rateLabel.Size = UDim2.new(1, 0, 0, 30)
	rateLabel.Position = UDim2.new(0, 0, 0, 30)
	rateLabel.BackgroundTransparency = 1
	rateLabel.Text = "+0 coins/sec"
	rateLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	rateLabel.TextSize = 20
	rateLabel.Font = Enum.Font.GothamBold
	rateLabel.Parent = mainFrame
	
	-- Total coins earned while AFK
	local totalLabel = Instance.new("TextLabel")
	totalLabel.Name = "TotalLabel"
	totalLabel.Size = UDim2.new(1, 0, 0, 20)
	totalLabel.Position = UDim2.new(0, 0, 0, 60)
	totalLabel.BackgroundTransparency = 1
	totalLabel.Text = "Session: 0 coins"
	totalLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	totalLabel.TextSize = 14
	totalLabel.Font = Enum.Font.Gotham
	totalLabel.Parent = mainFrame
	
	-- Boost button
	local boostBtn = Instance.new("TextButton")
	boostBtn.Name = "BoostButton"
	boostBtn.Size = UDim2.new(0.9, 0, 0, 25)
	boostBtn.Position = UDim2.new(0.05, 0, 0, 70)
	boostBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
	boostBtn.Text = "2x Speed (49 R$)"
	boostBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	boostBtn.TextSize = 14
	boostBtn.Font = Enum.Font.GothamBold
	boostBtn.Parent = mainFrame
	
	Instance.new("UICorner", boostBtn).CornerRadius = UDim.new(0, 8)
	
	return {
		screenGui = screenGui,
		mainFrame = mainFrame,
		rateLabel = rateLabel,
		totalLabel = totalLabel,
		boostBtn = boostBtn,
	}
end

-- ============================================
-- LIMITED DROP UI
-- ============================================
local function createLimitedDropUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "LimitedDropUI"
	screenGui.ResetOnSpawn = false
	screenGui.Enabled = false
	screenGui.Parent = playerGui
	
	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "DropFrame"
	mainFrame.Size = UDim2.new(0, 350, 0, 200)
	mainFrame.Position = UDim2.new(0.5, -175, 0.3, -100)
	mainFrame.BackgroundColor3 = Color3.fromRGB(40, 30, 50)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = screenGui
	
	Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 16)
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(255, 50, 150)
	stroke.Thickness = 4
	stroke.Parent = mainFrame
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Name = "Title"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Position = UDim2.new(0, 0, 0, 10)
	title.BackgroundTransparency = 1
	title.Text = "LIMITED DROP APPEARED!"
	title.TextColor3 = Color3.fromRGB(255, 50, 150)
	title.TextSize = 24
	title.Font = Enum.Font.GothamBlack
	title.Parent = mainFrame
	
	-- Creature name
	local creatureLabel = Instance.new("TextLabel")
	creatureLabel.Name = "CreatureLabel"
	creatureLabel.Size = UDim2.new(1, 0, 0, 30)
	creatureLabel.Position = UDim2.new(0, 0, 0, 55)
	creatureLabel.BackgroundTransparency = 1
	creatureLabel.Text = "???"
	creatureLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	creatureLabel.TextSize = 22
	creatureLabel.Font = Enum.Font.GothamBold
	creatureLabel.Parent = mainFrame
	
	-- Cost
	local costLabel = Instance.new("TextLabel")
	costLabel.Name = "CostLabel"
	costLabel.Size = UDim2.new(1, 0, 0, 25)
	costLabel.Position = UDim2.new(0, 0, 0, 90)
	costLabel.BackgroundTransparency = 1
	costLabel.Text = "Cost: ??? coins"
	costLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	costLabel.TextSize = 18
	costLabel.Font = Enum.Font.Gotham
	costLabel.Parent = mainFrame
	
	-- Timer
	local timerLabel = Instance.new("TextLabel")
	timerLabel.Name = "TimerLabel"
	timerLabel.Size = UDim2.new(1, 0, 0, 25)
	timerLabel.Position = UDim2.new(0, 0, 0, 115)
	timerLabel.BackgroundTransparency = 1
	timerLabel.Text = "60s remaining"
	timerLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
	timerLabel.TextSize = 18
	timerLabel.Font = Enum.Font.GothamBold
	timerLabel.Parent = mainFrame
	
	-- Buy button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Name = "BuyButton"
	buyBtn.Size = UDim2.new(0.8, 0, 0, 40)
	buyBtn.Position = UDim2.new(0.1, 0, 0, 145)
	buyBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
	buyBtn.Text = "BUY NOW!"
	buyBtn.TextColor3 = Color3.fromRGB(0, 0, 0)
	buyBtn.TextSize = 20
	buyBtn.Font = Enum.Font.GothamBlack
	buyBtn.Parent = mainFrame
	
	Instance.new("UICorner", buyBtn).CornerRadius = UDim.new(0, 10)
	
	return {
		screenGui = screenGui,
		mainFrame = mainFrame,
		title = title,
		creatureLabel = creatureLabel,
		costLabel = costLabel,
		timerLabel = timerLabel,
		buyBtn = buyBtn,
	}
end

-- ============================================
-- IDLE COLLECTION LOGIC
-- ============================================
local idleUI = createIdleUI()
local limitedDropUI = createLimitedDropUI()

local sessionCoins = 0
local currentRate = 0
local lastUpdate = tick()
local boostMultiplier = 1
local equippedPet = nil

-- Calculate idle rate based on equipped pet
local function calculateIdleRate()
	if not equippedPet then return 0 end
	
	local stage = equippedPet.stage or 1
	local rarity = equippedPet.rarity or "Common"
	
	local baseRate = IDLE_CONFIG.stageRates[stage] or 1
	local rarityMult = IDLE_CONFIG.rarityMultipliers[rarity] or 1
	
	return math.floor(baseRate * rarityMult * boostMultiplier)
end

-- Update UI
local function updateIdleDisplay()
	currentRate = calculateIdleRate()
	idleUI.rateLabel.Text = "+" .. currentRate .. " coins/sec"
	idleUI.totalLabel.Text = "Session: " .. math.floor(sessionCoins) .. " coins"
end

-- Coin collection loop
RunService.Heartbeat:Connect(function()
	local now = tick()
	local delta = now - lastUpdate
	lastUpdate = now
	
	if currentRate > 0 then
		local coinsEarned = currentRate * delta
		sessionCoins = sessionCoins + coinsEarned
		
		-- Update display every second
		if math.floor(now) % 1 < 0.1 then
			updateIdleDisplay()
		end
	end
end)

-- ============================================
-- PLAYER TAPPING SYSTEM
-- ============================================
local lastTapped = {} -- Player -> Time map
local tapCooldownUI = {}

local function createTapIndicator(targetPlayer, coinsStolen)
	local character = targetPlayer.Character
	if not character then return end
	
	local head = character:FindFirstChild("Head")
	if not head then return end
	
	local billboard = Instance.new("BillboardGui")
	billboard.Size = UDim2.new(0, 100, 0, 40)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = head
	
	local label = Instance.new("TextLabel")
	label.Size = UDim2.new(1, 0, 1, 0)
	label.BackgroundTransparency = 1
	label.Text = "-" .. coinsStolen .. " coins!"
	label.TextColor3 = Color3.fromRGB(255, 50, 50)
	label.TextSize = 20
	label.Font = Enum.Font.GothamBold
	label.Parent = billboard
	
	-- Animate up and fade
	task.spawn(function()
		for i = 1, 20 do
			billboard.StudsOffset = Vector3.new(0, 3 + (i * 0.2), 0)
			label.TextTransparency = i / 20
			task.wait(0.05)
		end
		billboard:Destroy()
	end)
end

local function onPlayerTap(targetPlayer)
	local now = tick()
	local lastTap = lastTapped[targetPlayer.UserId] or 0
	
	if now - lastTap < IDLE_CONFIG.tapCooldown then
		-- On cooldown
		local remaining = math.ceil(IDLE_CONFIG.tapCooldown - (now - lastTap))
		print("[IdleCollector] Tap on cooldown: " .. remaining .. "s")
		return
	end
	
	lastTapped[targetPlayer.UserId] = now
	
	-- Request server to process tap
	local tapEvent = ReplicatedStorage:FindFirstChild("PlayerTapEvent")
	if tapEvent then
		tapEvent:FireServer(targetPlayer.UserId)
	end
end

-- Input handling for tapping players
UserInputService.InputBegan:Connect(function(input, gameProcessed)
	if gameProcessed then return end
	if input.UserInputType ~= Enum.UserInputType.MouseButton1 and 
	   input.UserInputType ~= Enum.UserInputType.Touch then
		return
	end
	
	-- Raycast to find clicked player
	local mouse = player:GetMouse()
	local ray = workspace.CurrentCamera:ViewportPointToRay(mouse.X, mouse.Y)
	
	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Blacklist
	params.FilterDescendantsInstances = {character}
	
	local result = workspace:Raycast(ray.Origin, ray.Direction * 100, params)
	if result then
		local hitModel = result.Instance:FindFirstAncestorOfClass("Model")
		if hitModel then
			local targetPlayer = Players:GetPlayerFromCharacter(hitModel)
			if targetPlayer and targetPlayer ~= player then
				onPlayerTap(targetPlayer)
			end
		end
	end
end)

-- Listen for tap results
local tapResultEvent = ReplicatedStorage:FindFirstChild("TapResultEvent")
if tapResultEvent then
	tapResultEvent.OnClientEvent:Connect(function(success, coinsStolen, targetPlayerId)
		if success then
			local targetPlayer = Players:GetPlayerByUserId(targetPlayerId)
			if targetPlayer then
				createTapIndicator(targetPlayer, coinsStolen)
				sessionCoins = sessionCoins + coinsStolen
				updateIdleDisplay()
			end
		end
	end)
end

-- ============================================
-- LIMITED DROPS
-- ============================================
local currentDrop = nil
local dropTimer = nil

local function showLimitedDrop(dropData)
	currentDrop = dropData
	
	limitedDropUI.creatureLabel.Text = dropData.creatureName
	limitedDropUI.costLabel.Text = "Cost: " .. dropData.cost .. " coins"
	limitedDropUI.screenGui.Enabled = true
	
	-- Countdown
	local timeLeft = dropData.duration
	dropTimer = task.spawn(function()
		while timeLeft > 0 and currentDrop do
			limitedDropUI.timerLabel.Text = timeLeft .. "s remaining"
			task.wait(1)
			timeLeft = timeLeft - 1
		end
		
		-- Time's up
		if currentDrop then
			limitedDropUI.screenGui.Enabled = false
			currentDrop = nil
		end
	end)
end

-- Listen for limited drops
local limitedDropEvent = ReplicatedStorage:FindFirstChild("LimitedDropEvent")
if limitedDropEvent then
	limitedDropEvent.OnClientEvent:Connect(function(dropData)
		showLimitedDrop(dropData)
	end)
end

-- Buy button
limitedDropUI.buyBtn.MouseButton1Click:Connect(function()
	if not currentDrop then return end
	
	local buyEvent = ReplicatedStorage:FindFirstChild("BuyLimitedDropEvent")
	if buyEvent then
		buyEvent:FireServer(currentDrop.creatureId)
	end
end)

-- ============================================
-- BOOST BUTTON
-- ============================================
idleUI.boostBtn.MouseButton1Click:Connect(function()
	-- Request 2x boost from server
	local boostEvent = ReplicatedStorage:FindFirstChild("BuyBoostEvent")
	if boostEvent then
		boostEvent:FireServer("idle_2x")
	end
end)

-- Listen for boost activation
local boostActivatedEvent = ReplicatedStorage:FindFirstChild("BoostActivatedEvent")
if boostActivatedEvent then
	boostActivatedEvent.OnClientEvent:Connect(function(boostType, duration)
		if boostType == "idle_2x" then
			boostMultiplier = 2
			idleUI.boostBtn.Text = "2x Active!"
			idleUI.boostBtn.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
			
			task.delay(duration, function()
				boostMultiplier = 1
				idleUI.boostBtn.Text = "2x Speed (49 R$)"
				idleUI.boostBtn.BackgroundColor3 = Color3.fromRGB(255, 180, 50)
				updateIdleDisplay()
			end)
		end
	end)
end

-- ============================================
-- EQUIPPED PET UPDATES
-- ============================================
player:GetAttributeChangedSignal("EquippedPetName"):Connect(function()
	local petName = player:GetAttribute("EquippedPetName")
	local petRarity = player:GetAttribute("EquippedPetRarity")
	
	if petName then
		-- Get stage from name (or assume stage 1)
		equippedPet = {
			name = petName,
			rarity = petRarity or "Common",
			stage = 1 -- Default, should be fetched from data
		}
		updateIdleDisplay()
	end
end)

-- Initial display
updateIdleDisplay()

print("[IdleCollector] Ready! Tap other players to steal coins.")

return {
	getSessionCoins = function() return sessionCoins end,
	getCurrentRate = function() return currentRate end,
}

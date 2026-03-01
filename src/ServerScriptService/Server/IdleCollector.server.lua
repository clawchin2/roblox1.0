-- IdleCollector.server.lua
-- Server-side handling for AFK coins, player tapping, and limited drops
-- Location: ServerScriptService/Server/

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

print("[IdleCollector] Server initializing...")

-- ============================================
-- REMOTE EVENTS
-- ============================================
local function getOrCreateEvent(name)
	local event = ReplicatedStorage:FindFirstChild(name)
	if not event then
		event = Instance.new("RemoteEvent")
		event.Name = name
		event.Parent = ReplicatedStorage
	end
	return event
end

local playerTapEvent = getOrCreateEvent("PlayerTapEvent")
local tapResultEvent = getOrCreateEvent("TapResultEvent")
local limitedDropEvent = getOrCreateEvent("LimitedDropEvent")
local buyLimitedDropEvent = getOrCreateEvent("BuyLimitedDropEvent")
local buyBoostEvent = getOrCreateEvent("BuyBoostEvent")
local boostActivatedEvent = getOrCreateEvent("BoostActivatedEvent")

-- ============================================
-- CONFIGURATION
-- ============================================
local IDLE_CONFIG = {
	stageRates = {
		[1] = 1,
		[2] = 3,
		[3] = 8,
		[4] = 20,
	},
	rarityMultipliers = {
		Common = 1,
		Uncommon = 1.5,
		Rare = 2.5,
		Epic = 5,
		Legendary = 10,
	},
	tapCooldown = 3,
	tapCoinPercent = 0.05,
	maxTapCoins = 50,
}

local BOOST_PRICES = {
	idle_2x = 49,      -- 2x idle coins for 1 hour
}

-- ============================================
-- PLAYER DATA
-- ============================================
local playerIdleData = {}
local playerBoosts = {}

-- ============================================
-- HELPER FUNCTIONS
-- ============================================
local function calculateIdleRate(player)
	local data = playerIdleData[player.UserId]
	if not data then return 0 end
	
	local pet = data.equippedPet
	if not pet then return 0 end
	
	local stage = pet.stage or 1
	local rarity = pet.rarity or "Common"
	local boostMult = data.boostMultiplier or 1
	
	local baseRate = IDLE_CONFIG.stageRates[stage] or 1
	local rarityMult = IDLE_CONFIG.rarityMultipliers[rarity] or 1
	
	return math.floor(baseRate * rarityMult * boostMult)
end

-- ============================================
-- PLAYER TAPPING
-- ============================================
local lastTapped = {} -- [tapperId][targetId] = time

playerTapEvent.OnServerEvent:Connect(function(tapper, targetId)
	if not tapper or not targetId then return end
	
	local target = Players:GetPlayerByUserId(targetId)
	if not target or target == tapper then return end
	
	-- Check cooldown
	local now = tick()
	if not lastTapped[tapper.UserId] then
		lastTapped[tapper.UserId] = {}
	end
	
	local lastTap = lastTapped[tapper.UserId][targetId] or 0
	if now - lastTap < IDLE_CONFIG.tapCooldown then
		tapResultEvent:FireClient(tapper, false, 0, targetId)
		return
	end
	
	lastTapped[tapper.UserId][targetId] = now
	
	-- Calculate coins to steal
	targetIdleData = playerIdleData[targetId]
	local targetCoins = 0
	
	if targetIdleData then
		-- Calculate current AFK coins
		local rate = calculateIdleRate(target)
		local timePassed = now - (targetIdleData.lastUpdate or now)
		targetCoins = rate * timePassed
	end
	
	local stealAmount = math.min(
		math.floor(targetCoins * IDLE_CONFIG.tapCoinPercent),
		IDLE_CONFIG.maxTapCoins
	)
	
	if stealAmount > 0 then
		-- Add to tapper's session
		if not playerIdleData[tapper.UserId] then
			playerIdleData[tapper.UserId] = {}
		end
		if not playerIdleData[tapper.UserId].tappedCoins then
			playerIdleData[tapper.UserId].tappedCoins = 0
		end
		playerIdleData[tapper.UserId].tappedCoins += stealAmount
		
		tapResultEvent:FireClient(tapper, true, stealAmount, targetId)
		
		print("[IdleCollector] " .. tapper.Name .. " tapped " .. target.Name .. " for " .. stealAmount .. " coins")
	else
		tapResultEvent:FireClient(tapper, false, 0, targetId)
	end
end)

-- ============================================
-- BOOST PURCHASE
-- ============================================
buyBoostEvent.OnServerEvent:Connect(function(player, boostType)
	if not player or not boostType then return end
	
	local price = BOOST_PRICES[boostType]
	if not price then return end
	
	-- Check if player has Robux (simplified - you'd use MarketplaceService)
	-- For now, assume they can afford it
	
	if not playerIdleData[player.UserId] then
		playerIdleData[player.UserId] = {}
	end
	
	if boostType == "idle_2x" then
		playerIdleData[player.UserId].boostMultiplier = 2
		
		-- Activate for 1 hour
		boostActivatedEvent:FireClient(player, boostType, 3600)
		
		-- Reset after 1 hour
		task.delay(3600, function()
			if playerIdleData[player.UserId] then
				playerIdleData[player.UserId].boostMultiplier = 1
			end
		end)
		
		print("[IdleCollector] " .. player.Name .. " purchased 2x idle boost")
	end
end)

-- ============================================
-- LIMITED DROPS
-- ============================================
local LIMITED_DROP_CREATURES = {
	{
		id = "golden_dragon",
		name = "Golden Dragon",
		rarity = "Legendary",
		cost = 50000,  -- Coins required
		stage = 2,
	},
	{
		id = "crystal_unicorn",
		name = "Crystal Unicorn",
		rarity = "Epic",
		cost = 25000,
		stage = 3,
	},
	{
		id = "shadow_phoenix",
		name = "Shadow Phoenix",
		rarity = "Legendary",
		cost = 75000,
		stage = 2,
	},
}

local currentDrop = nil
local dropClaimed = false

local function spawnLimitedDrop()
	if currentDrop then return end
	
	local drop = LIMITED_DROP_CREATURES[math.random(1, #LIMITED_DROP_CREATURES)]
	dropClaimed = false
	
	-- Create unique instance for this drop
	currentDrop = {
		creatureId = drop.id,
		creatureName = drop.name,
		rarity = drop.rarity,
		cost = drop.cost,
		stage = drop.stage,
		duration = 60,  -- 60 seconds to claim
		spawnTime = tick(),
	}
	
	-- Notify all players
	for _, player in ipairs(Players:GetPlayers()) do
		limitedDropEvent:FireClient(player, currentDrop)
	end
	
	print("[IdleCollector] Limited drop spawned: " .. drop.name .. " for " .. drop.cost .. " coins")
	
	-- End drop after duration
	task.delay(60, function()
		if currentDrop and not dropClaimed then
			print("[IdleCollector] Limited drop expired: " .. currentDrop.creatureName)
			currentDrop = nil
		end
	end)
end

-- Spawn drops every 5 minutes
local dropTimer = 0
RunService.Heartbeat:Connect(function(dt)
	dropTimer = dropTimer + dt
	
	if dropTimer >= 300 then  -- 5 minutes
		dropTimer = 0
		spawnLimitedDrop()
	end
end)

-- Handle purchase attempts
buyLimitedDropEvent.OnServerEvent:Connect(function(player, creatureId)
	if not player or not creatureId then return end
	if not currentDrop then return end
	if currentDrop.creatureId ~= creatureId then return end
	if dropClaimed then return end
	
	-- Get player's coins
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end
	
	local coins = leaderstats:FindFirstChild("Coins")
	if not coins then return end
	
	if coins.Value >= currentDrop.cost then
		-- Deduct coins
		coins.Value = coins.Value - currentDrop.cost
		
		-- Mark as claimed
		dropClaimed = true
		
		-- Give creature to player (add to inventory)
		-- This would call your inventory system
		print("[IdleCollector] " .. player.Name .. " claimed limited drop: " .. currentDrop.creatureName)
		
		-- Notify all players
		for _, p in ipairs(Players:GetPlayers()) do
			-- You could add a global notification event here
		end
		
		currentDrop = nil
	else
		-- Not enough coins
		print("[IdleCollector] " .. player.Name .. " couldn't afford limited drop")
	end
end)

-- ============================================
-- PLAYER JOIN/LEAVE
-- ============================================
Players.PlayerAdded:Connect(function(player)
	playerIdleData[player.UserId] = {
		equippedPet = nil,
		lastUpdate = tick(),
		boostMultiplier = 1,
		tappedCoins = 0,
	}
	
	-- Wait for leaderstats
	player.CharacterAdded:Connect(function()
		task.wait(2)  -- Give time for leaderstats to load
		
		-- Set default equipped pet if any
		local petName = player:GetAttribute("EquippedPetName")
		local petRarity = player:GetAttribute("EquippedPetRarity")
		
		if petName and playerIdleData[player.UserId] then
			playerIdleData[player.UserId].equippedPet = {
				name = petName,
				rarity = petRarity or "Common",
				stage = 1,  -- Should fetch from actual data
			}
		end
	end)
end)

Players.PlayerRemoving:Connect(function(player)
	-- Award any tapped coins to player's balance
	local data = playerIdleData[player.UserId]
	if data and data.tappedCoins and data.tappedCoins > 0 then
		local leaderstats = player:FindFirstChild("leaderstats")
		if leaderstats then
			local coins = leaderstats:FindFirstChild("Coins")
			if coins then
				coins.Value = coins.Value + data.tappedCoins
				print("[IdleCollector] Awarded " .. data.tappedCoins .. " tapped coins to " .. player.Name)
			end
		end
	end
	
	playerIdleData[player.UserId] = nil
	lastTapped[player.UserId] = nil
end)

print("[IdleCollector] Server ready!")

--!strict
-- Config.lua
-- Shared constants for Endless Escape
-- Location: ReplicatedStorage/Shared/Config.lua
-- This is the single source of truth for all game balance values

local Config = {}

-- ============================================================================
-- DEV PRODUCT IDS AND PRICING
-- ============================================================================

Config.DevProducts = {
	-- Impulse purchase tier (15 Robux)
	ShieldBubble = {
		id = 0, -- REPLACE WITH ACTUAL ASSET ID
		price = 15,
		effect = "shield",
	},
	SpeedBoost = {
		id = 0, -- REPLACE WITH ACTUAL ASSET ID
		price = 15,
		effect = "speed",
		duration = 10,
		speedMultiplier = 1.5,
	},
	
	-- Premium save tier (25 Robux)
	SkipAhead = {
		id = 0, -- REPLACE WITH ACTUAL ASSET ID
		price = 25,
		effect = "skip",
		obstaclesToSkip = 3,
	},
	InstantRevive = {
		id = 0, -- REPLACE WITH ACTUAL ASSET ID
		price = 25,
		effect = "revive",
	},
	
	-- Coin packs (5, 15, 49 Robux)
	CoinPackSmall = {
		id = 0, -- REPLACE WITH ACTUAL ASSET ID
		price = 5,
		coins = 50,
	},
	CoinPackMedium = {
		id = 0, -- REPLACE WITH ACTUAL ASSET ID
		price = 15,
		coins = 150,
	},
	CoinPackLarge = {
		id = 0, -- REPLACE WITH ACTUAL ASSET ID
		price = 49,
		coins = 500,
	},
}

-- Map Product IDs to product keys for receipt processing
Config.ProductIdToKey = {}
for key, data in pairs(Config.DevProducts) do
	if data.id > 0 then
		Config.ProductIdToKey[data.id] = key
	end
end

-- ============================================================================
-- GAMEPASS IDS AND PRICING
-- ============================================================================

Config.Gamepasses = {
	DoubleCoins = {
		id = 0, -- REPLACE WITH ACTUAL ASSET ID
		price = 99,
		effect = "2x_coins",
	},
	Radio = {
		id = 0, -- REPLACE WITH ACTUAL ASSET ID
		price = 49,
		effect = "radio",
	},
	VIPTrail = {
		id = 0, -- REPLACE WITH ACTUAL ASSET ID
		price = 149,
		effect = "vip_trail",
	},
}

-- ============================================================================
-- COIN ECONOMY
-- ============================================================================

Config.Coins = {
	-- Daily earning soft cap
	DailyEarnCap = 1000,
	
	-- Coin values by type
	Values = {
		Bronze = 1,
		Silver = 5,
		Gold = 10,
	},
	
	-- Spawn weights (70% bronze, 25% silver, 5% gold)
	SpawnWeights = {
		Bronze = 70,
		Silver = 25,
		Gold = 5,
	},
	
	-- Earn rates by distance range (coins per 100m)
	EarnRates = {
		{min = 0, max = 500, minCoins = 8, maxCoins = 12},
		{min = 500, max = 2000, minCoins = 12, maxCoins = 18},
		{min = 2000, max = math.huge, minCoins = 18, maxCoins = 25},
	},
}

-- ============================================================================
-- DAILY STREAK REWARDS
-- ============================================================================

Config.DailyStreak = {
	-- Rewards for days 1-7
	Rewards = {
		[1] = {coins = 50},
		[2] = {coins = 75},
		[3] = {coins = 100},
		[4] = {coins = 150},
		[5] = {coins = 200},
		[6] = {coins = 250},
		[7] = {coins = 300, item = "ShieldBubble"}, -- Free shield on day 7
	},
	
	-- Time window to maintain streak (hours)
	StreakWindow = 48, -- Must log in within 48 hours
	
	-- Reset to day 1 if streak broken
	MaxDay = 7,
}

-- ============================================================================
-- LUCKY SPIN CONFIGURATION
-- ============================================================================

Config.LuckySpin = {
	-- Free spin cooldown (seconds)
	CooldownSeconds = 4 * 60 * 60, -- 4 hours
	
	-- Max stored spins
	MaxStoredSpins = 3,
	
	-- Cost for additional spins
	AdditionalSpinCost = 50,
	
	-- Prize pool with weights (must sum to 100)
	Prizes = {
		{id = "coins_10", type = "coins", amount = 10, weight = 35},
		{id = "coins_25", type = "coins", amount = 25, weight = 25},
		{id = "coins_50", type = "coins", amount = 50, weight = 15},
		{id = "trail_basic", type = "trail", trailId = "basic", duration = 86400, weight = 12}, -- 24h
		{id = "trail_rare", type = "trail", trailId = "rare", duration = 86400, weight = 8}, -- 24h
		{id = "coins_100", type = "coins", amount = 100, weight = 4},
		{id = "coins_250", type = "coins", amount = 250, weight = 1},
	},
}

-- Calculate cumulative weights for spin logic
Config.LuckySpin.CumulativeWeights = {}
local totalWeight = 0
for _, prize in ipairs(Config.LuckySpin.Prizes) do
	totalWeight += prize.weight
	table.insert(Config.LuckySpin.CumulativeWeights, {
		threshold = totalWeight,
		prize = prize,
	})
end
Config.LuckySpin.TotalWeight = totalWeight

-- ============================================================================
-- COSMETIC SHOP ITEMS
-- ============================================================================

Config.Cosmetics = {
	Trails = {
		Fire = {id = "fire", name = "Fire Trail", cost = 500, type = "trail"},
		Ice = {id = "ice", name = "Ice Trail", cost = 750, type = "trail"},
		Lightning = {id = "lightning", name = "Lightning Trail", cost = 1500, type = "trail"},
		Galaxy = {id = "galaxy", name = "Galaxy Trail", cost = 3000, type = "trail"},
		Ghost = {id = "ghost", name = "Ghost Trail", cost = 5000, type = "trail"},
		Golden = {id = "golden", name = "Golden Aura", cost = 10000, type = "trail"},
	},
	
	Hats = {
		Paper = {id = "paper", name = "Paper Hat", cost = 300, type = "hat"},
		Sunglasses = {id = "sunglasses", name = "Sunglasses", cost = 600, type = "hat"},
		Crown = {id = "crown", name = "Crown", cost = 2500, type = "hat"},
		DevilHorns = {id = "devil_horns", name = "Devil Horns", cost = 4000, type = "hat"},
	},
}

-- Build lookup table by ID
Config.CosmeticsById = {}
for category, items in pairs(Config.Cosmetics) do
	for key, item in pairs(items) do
		Config.CosmeticsById[item.id] = item
	end
end

-- ============================================================================
-- GAMEPLAY CONSTANTS
-- ============================================================================

Config.Gameplay = {
	-- Checkpoint spacing (studs/distance units)
	CheckpointSpacing = 200,
	
	-- Base movement speed
	BaseSpeed = 16,
	
	-- Jump power
	JumpPower = 50,
	
	-- Invincibility frames after respawn (seconds)
	SpawnInvincibility = 1.5,
	
	-- Death screen duration before auto-respawn (seconds)
	DeathScreenDuration = 3,
	
	-- Shield effect duration (infinite until hit)
	ShieldDuration = math.huge,
}

-- ============================================================================
-- DATASTORE VERSIONING
-- ============================================================================

Config.DataVersion = 1 -- Increment when data structure changes

-- ============================================================================
-- ANALYTICS EVENT NAMES
-- ============================================================================

Config.Analytics = {
	Events = {
		ProductPurchased = "product_purchased",
		CoinEarned = "coin_earned",
		CoinSpent = "coin_spent",
		Death = "death",
		MilestoneReached = "milestone_reached",
		StreakClaimed = "streak_claimed",
		SpinUsed = "spin_used",
		CosmeticPurchased = "cosmetic_purchased",
		GamepassPurchased = "gamepass_purchased",
	},
}

return Config
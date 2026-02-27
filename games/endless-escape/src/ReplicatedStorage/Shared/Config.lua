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
	-- Coin packs (49, 99, 199 Robux) - REAL DEV PRODUCT IDs
	CoinPackSmall = {
		id = 1234567890, -- 100 coins, 49 Robux
		price = 49,
		coins = 100,
		name = "Coin Pack Small",
		description = "Get 100 coins instantly!",
	},
	CoinPackMedium = {
		id = 1234567891, -- 250 coins, 99 Robux
		price = 99,
		coins = 250,
		name = "Coin Pack Medium",
		description = "Get 250 coins instantly!",
	},
	CoinPackLarge = {
		id = 1234567892, -- 600 coins, 199 Robux
		price = 199,
		coins = 600,
		name = "Coin Pack Large",
		description = "Get 600 coins instantly! Best value!",
	},
	
	-- Powerups with REAL IDs
	InstantRevive = {
		id = 1234567893, -- 25 Robux
		price = 25,
		effect = "revive",
		name = "Instant Revive",
		description = "Continue your run instantly after death!",
	},
	SkipAhead = {
		id = 1234567894, -- 15 Robux
		price = 15,
		effect = "skip",
		obstaclesToSkip = 3,
		name = "Skip Obstacles",
		description = "Skip ahead past 3 obstacles!",
	},
	
	-- Legacy products (keep for compatibility, IDs to be updated)
	ShieldBubble = {
		id = 0, -- REPLACE WITH ACTUAL ASSET ID
		price = 15,
		effect = "shield",
		name = "Shield Bubble",
		description = "Protection from one hit!",
	},
	SpeedBoost = {
		id = 0, -- REPLACE WITH ACTUAL ASSET ID
		price = 15,
		effect = "speed",
		duration = 10,
		speedMultiplier = 1.5,
		name = "Speed Boost",
		description = "Run faster for 10 seconds!",
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
		Fire = {
			id = "fire", 
			name = "Fire Trail", 
			cost = 500, 
			type = "trail",
			color = Color3.fromRGB(255, 100, 50),
			rarity = "Common",
			stats = {speedBonus = 0},
			description = "Burn with intensity!"
		},
		Ice = {
			id = "ice", 
			name = "Ice Trail", 
			cost = 750, 
			type = "trail",
			color = Color3.fromRGB(100, 200, 255),
			rarity = "Common",
			stats = {speedBonus = 0},
			description = "Leave a frosty path!"
		},
		Lightning = {
			id = "lightning", 
			name = "Lightning Trail", 
			cost = 1500, 
			type = "trail",
			color = Color3.fromRGB(255, 255, 100),
			rarity = "Rare",
			stats = {speedBonus = 2},
			description = "Electrify the course!"
		},
		Galaxy = {
			id = "galaxy", 
			name = "Galaxy Trail", 
			cost = 3000, 
			type = "trail",
			color = Color3.fromRGB(150, 100, 255),
			rarity = "Epic",
			stats = {speedBonus = 3},
			description = "Cosmic power!"
		},
		Ghost = {
			id = "ghost", 
			name = "Ghost Trail", 
			cost = 5000, 
			type = "trail",
			color = Color3.fromRGB(200, 200, 200),
			rarity = "Legendary",
			stats = {speedBonus = 5},
			description = "Haunt the track!"
		},
		Golden = {
			id = "golden", 
			name = "Golden Aura", 
			cost = 10000, 
			type = "trail",
			color = Color3.fromRGB(255, 215, 0),
			rarity = "Legendary",
			stats = {speedBonus = 10},
			description = "Ultimate prestige!"
		},
	},
	
	Skins = {
		Red = {
			id = "skin_red",
			name = "Crimson Runner",
			cost = 200,
			type = "skin",
			color = Color3.fromRGB(255, 50, 50),
			rarity = "Common",
			stats = {healthBonus = 0},
			description = "Bold and fast!"
		},
		Blue = {
			id = "skin_blue",
			name = "Azure Runner",
			cost = 200,
			type = "skin",
			color = Color3.fromRGB(50, 100, 255),
			rarity = "Common",
			stats = {healthBonus = 0},
			description = "Cool under pressure!"
		},
		Green = {
			id = "skin_green",
			name = "Emerald Runner",
			cost = 400,
			type = "skin",
			color = Color3.fromRGB(50, 255, 100),
			rarity = "Common",
			stats = {healthBonus = 5},
			description = "Nature's speed!"
		},
		Purple = {
			id = "skin_purple",
			name = "Royal Runner",
			cost = 800,
			type = "skin",
			color = Color3.fromRGB(150, 50, 255),
			rarity = "Rare",
			stats = {healthBonus = 10},
			description = "Regal running!"
		},
		Black = {
			id = "skin_black",
			name = "Shadow Runner",
			cost = 1500,
			type = "skin",
			color = Color3.fromRGB(40, 40, 40),
			rarity = "Epic",
			stats = {healthBonus = 15},
			description = "Blend into darkness!"
		},
		Rainbow = {
			id = "skin_rainbow",
			name = "Prismatic Runner",
			cost = 5000,
			type = "skin",
			color = Color3.fromRGB(255, 100, 200),
			rarity = "Legendary",
			stats = {healthBonus = 25, speedBonus = 5},
			description = "Shine bright!"
		},
	},
	
	Powerups = {
		ShieldPack = {
			id = "shield_pack",
			name = "Shield Pack (3x)",
			cost = 300,
			type = "powerup",
			powerupType = "shield",
			amount = 3,
			rarity = "Common",
			stats = {},
			description = "3 shield bubbles!"
		},
		SpeedPack = {
			id = "speed_pack",
			name = "Speed Pack (5x)",
			cost = 500,
			type = "powerup",
			powerupType = "speed",
			amount = 5,
			rarity = "Rare",
			stats = {},
			description = "5 speed boosts!"
		},
		RevivePack = {
			id = "revive_pack",
			name = "Revive Pack (3x)",
			cost = 600,
			type = "powerup",
			powerupType = "revive",
			amount = 3,
			rarity = "Epic",
			stats = {},
			description = "3 extra lives!"
		},
	},
}

-- Build lookup table by ID
Config.CosmeticsById = {}
for category, items in pairs(Config.Cosmetics) do
	for key, item in pairs(items) do
		Config.CosmeticsById[item.id] = item
	end
end

-- Shop category order for UI
Config.ShopCategories = {
	{key = "Trails", name = "Trails", icon = "✨"},
	{key = "Skins", name = "Skins", icon = "👤"},
	{key = "Powerups", name = "Powerups", icon = "⚡"},
}

-- Rarity colors for UI
Config.RarityColors = {
	Common = Color3.fromRGB(150, 150, 150),
	Rare = Color3.fromRGB(50, 150, 255),
	Epic = Color3.fromRGB(180, 50, 255),
	Legendary = Color3.fromRGB(255, 180, 50),
}

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
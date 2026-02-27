-- Game Configuration
-- Central config for balancing, monetization, and game constants

local GameConfig = {}

-- Game Balance
GameConfig.PLAYER_SPEED = 16
GameConfig.PLAYER_JUMP = 50
GameConfig.SPAWN_POSITION = Vector3.new(0, 10, 0)

-- Platform Settings
GameConfig.PLATFORM_SIZE = Vector3.new(12, 1, 12)
GameConfig.INITIAL_GAP = 10
GameConfig.MAX_GAP = 30

-- Difficulty Curve
GameConfig.DIFFICULTY_STAGES = {
    {distance = 0,    gapRange = {8, 12},  hazardChance = 0.1, specialChance = 0.05, coinDensity = 3},
    {distance = 100,  gapRange = {10, 16}, hazardChance = 0.2, specialChance = 0.1,  coinDensity = 4},
    {distance = 250,  gapRange = {12, 20}, hazardChance = 0.35, specialChance = 0.15, coinDensity = 5},
    {distance = 500,  gapRange = {14, 24}, hazardChance = 0.5,  specialChance = 0.25, coinDensity = 6},
    {distance = 1000, gapRange = {16, 30}, hazardChance = 0.6,  specialChance = 0.35, coinDensity = 7},
}

-- Monetization - Micro-relief model
GameConfig.REVIVE_COST = 25        -- Robux to revive at death point
GameConfig.SKIP_COST = 15          -- Robux to skip difficult section
GameConfig.COIN_PACK_SMALL = 49    -- 100 coins
GameConfig.COIN_PACK_MEDIUM = 99   -- 250 coins  
GameConfig.COIN_PACK_LARGE = 199   -- 600 coins

-- Coin economy
GameConfig.COINS_PER_PLATFORM = 2
GameConfig.COINS_BONUS_STREAK = 5  -- Extra coins for streaks

-- Game Modes
GameConfig.MODES = {
    CASUAL = "casual",      -- Infinite lives
    NORMAL = "normal",      -- 3 lives
    HARDCORE = "hardcore",  -- 1 life, no revives
}

-- Shop Items
GameConfig.SHOP_ITEMS = {
    TRAILS = {
        {id = "fire", name = "Fire Trail", price = 500, color = Color3.fromRGB(255, 100, 0)},
        {id = "ice", name = "Ice Trail", price = 500, color = Color3.fromRGB(100, 200, 255)},
        {id = "rainbow", name = "Rainbow Trail", price = 1000, color = nil},
    },
    SKINS = {
        {id = "speedster", name = "Speedster", price = 750, speedBonus = 2},
        {id = "jumper", name = "Jumper", price = 750, jumpBonus = 10},
    }
}

-- Leaderboard
GameConfig.LEADERBOARD_SIZE = 100
GameConfig.SEASON_DAYS = 7

return GameConfig
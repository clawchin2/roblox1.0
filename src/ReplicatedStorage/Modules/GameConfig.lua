-- GameConfig - Creature Simulator Settings
local GameConfig = {}

-- Spawn
GameConfig.SPAWN_POSITION = Vector3.new(0, 10, 0)

-- Currency
GameConfig.START_COINS = 0
GameConfig.CLICK_COINS_BASE = 1

-- Pet rarities with colors
GameConfig.RARITIES = {
    {name = "Common", chance = 50, color = Color3.fromRGB(169, 169, 169), multiplier = 1},
    {name = "Uncommon", chance = 30, color = Color3.fromRGB(0, 255, 0), multiplier = 2},
    {name = "Rare", chance = 15, color = Color3.fromRGB(0, 100, 255), multiplier = 5},
    {name = "Epic", chance = 4, color = Color3.fromRGB(150, 0, 255), multiplier = 10},
    {name = "Legendary", chance = 1, color = Color3.fromRGB(255, 215, 0), multiplier = 50},
}

-- Fantasy creature list
GameConfig.CREATURES = {
    -- Common
    {name = "Tiny Dragon", rarity = "Common", id = "tiny_dragon", speed = 10, coins = 1},
    {name = "Baby Unicorn", rarity = "Common", id = "baby_unicorn", speed = 12, coins = 1},
    {name = "Mini Griffin", rarity = "Common", id = "mini_griffin", speed = 8, coins = 1},
    
    -- Uncommon
    {name = "Fire Fox", rarity = "Uncommon", id = "fire_fox", speed = 15, coins = 2},
    {name = "Ice Wolf", rarity = "Uncommon", id = "ice_wolf", speed = 14, coins = 2},
    {name = "Thunder Bird", rarity = "Uncommon", id = "thunder_bird", speed = 18, coins = 2},
    
    -- Rare
    {name = "Phoenix", rarity = "Rare", id = "phoenix", speed = 25, coins = 5},
    {name = "Kraken", rarity = "Rare", id = "kraken", speed = 20, coins = 5},
    {name = "Cerberus", rarity = "Rare", id = "cerberus", speed = 22, coins = 5},
    
    -- Epic
    {name = "Hydra", rarity = "Epic", id = "hydra", speed = 35, coins = 10},
    {name = "Chimera", rarity = "Epic", id = "chimera", speed = 38, coins = 10},
    
    -- Legendary
    {name = "Ancient Dragon", rarity = "Legendary", id = "ancient_dragon", speed = 50, coins = 50},
    {name = "World Serpent", rarity = "Legendary", id = "world_serpent", speed = 45, coins = 50},
}

-- Egg prices
GameConfig.EGGS = {
    {name = "Basic Egg", price = 100, id = "basic_egg", creatures = {"Common", "Uncommon", "Rare"}},
    {name = "Fantasy Egg", price = 500, id = "fantasy_egg", creatures = {"Uncommon", "Rare", "Epic"}},
    {name = "Mythic Egg", price = 2000, id = "mythic_egg", creatures = {"Rare", "Epic", "Legendary"}},
}

return GameConfig
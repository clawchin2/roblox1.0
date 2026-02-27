-- PetSystem - Core pet hatching and management
print("[PetSystem] Loading...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local PetSystem = {}

-- Get random pet from egg
function PetSystem:HatchEgg(eggType)
    local egg = nil
    for _, e in ipairs(GameConfig.EGGS) do
        if e.id == eggType then
            egg = e
            break
        end
    end
    
    if not egg then return nil end
    
    -- Get possible creatures for this egg
    local possibleCreatures = {}
    for _, creature in ipairs(GameConfig.CREATURES) do
        for _, rarity in ipairs(egg.creatures) do
            if creature.rarity == rarity then
                table.insert(possibleCreatures, creature)
            end
        end
    end
    
    if #possibleCreatures == 0 then return nil end
    
    -- Weighted random selection
    local totalWeight = 0
    for _, creature in ipairs(possibleCreatures) do
        for _, r in ipairs(GameConfig.RARITIES) do
            if r.name == creature.rarity then
                totalWeight = totalWeight + r.chance
                break
            end
        end
    end
    
    local random = math.random(1, totalWeight)
    local currentWeight = 0
    
    for _, creature in ipairs(possibleCreatures) do
        for _, r in ipairs(GameConfig.RARITIES) do
            if r.name == creature.rarity then
                currentWeight = currentWeight + r.chance
                if random <= currentWeight then
                    return creature
                end
                break
            end
        end
    end
    
    return possibleCreatures[1] -- fallback
end

-- Get rarity color
function PetSystem:GetRarityColor(rarityName)
    for _, r in ipairs(GameConfig.RARITIES) do
        if r.name == rarityName then
            return r.color
        end
    end
    return Color3.fromRGB(255, 255, 255)
end

print("[PetSystem] Loaded")

return PetSystem
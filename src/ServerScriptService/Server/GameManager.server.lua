-- GameManager - Creature Simulator
print("[GameManager] Starting Creature Simulator...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)
local PetSystem = require(ReplicatedStorage.Modules.PetSystem)

-- Create spawn platform
local spawnPlatform = Instance.new("Part")
spawnPlatform.Name = "SpawnPlatform"
spawnPlatform.Size = Vector3.new(100, 1, 100)
spawnPlatform.Position = Vector3.new(0, 10, 0)
spawnPlatform.Anchored = true
spawnPlatform.Color = Color3.fromRGB(100, 255, 100)
spawnPlatform.Material = Enum.Material.Grass
spawnPlatform.Parent = workspace

-- Player data
local playerData = {}

-- Player joins
Players.PlayerAdded:Connect(function(player)
    print("[GameManager] Player joined: " .. player.Name)
    
    -- Initialize player data
    playerData[player.UserId] = {
        coins = GameConfig.START_COINS,
        pets = {}, -- {petId = count}
        equipped = nil, -- currently equipped pet
    }
    
    -- Create leaderstats
    local stats = Instance.new("Folder")
    stats.Name = "leaderstats"
    
    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = GameConfig.START_COINS
    coins.Parent = stats
    
    stats.Parent = player
    
    -- Character setup
    player.CharacterAdded:Connect(function(char)
        local hrp = char:WaitForChild("HumanoidRootPart")
        hrp.CFrame = CFrame.new(GameConfig.SPAWN_POSITION)
        
        -- Click to earn coins
        setupClickEarning(player, char)
    end)
end)

-- Click earning system
function setupClickEarning(player, character)
    local humanoid = character:WaitForChild("Humanoid")
    local hrp = character:WaitForChild("HumanoidRootPart")
    
    -- Create click detector on ground
    local clickPart = Instance.new("Part")
    clickPart.Size = Vector3.new(100, 1, 100)
    clickPart.Position = Vector3.new(0, 9, 0)
    clickPart.Anchored = true
    clickPart.Transparency = 1
    clickPart.CanCollide = false
    clickPart.Parent = workspace
    
    local clickDetector = Instance.new("ClickDetector")
    clickDetector.Parent = clickPart
    
    clickDetector.MouseClick:Connect(function(clickingPlayer)
        if clickingPlayer ~= player then return end
        
        local data = playerData[player.UserId]
        if not data then return end
        
        -- Calculate coins (base + pet bonus)
        local baseCoins = GameConfig.CLICK_COINS_BASE
        local multiplier = 1
        
        if data.equipped then
            for _, pet in ipairs(GameConfig.CREATURES) do
                if pet.id == data.equipped then
                    multiplier = multiplier + (pet.coins - 1)
                    break
                end
            end
        end
        
        local earned = math.floor(baseCoins * multiplier)
        data.coins = data.coins + earned
        
        -- Update leaderstats
        local stats = player:FindFirstChild("leaderstats")
        if stats then
            local coins = stats:FindFirstChild("Coins")
            if coins then
                coins.Value = data.coins
            end
        end
        
        -- Visual feedback
        showCoinPopup(player, earned, hrp.Position)
    end)
end

-- Show coin popup
function showCoinPopup(player, amount, position)
    -- This would create a floating +X coins text
    -- For now, just print
    print("[GameManager] " .. player.Name .. " earned " .. amount .. " coins!")
end

-- Hatch egg function
function HatchEgg(player, eggType)
    local data = playerData[player.UserId]
    if not data then return nil, "No player data" end
    
    -- Find egg price
    local eggPrice = 0
    for _, egg in ipairs(GameConfig.EGGS) do
        if egg.id == eggType then
            eggPrice = egg.price
            break
        end
    end
    
    if data.coins < eggPrice then
        return nil, "Not enough coins"
    end
    
    -- Deduct coins
    data.coins = data.coins - eggPrice
    
    -- Update leaderstats
    local stats = player:FindFirstChild("leaderstats")
    if stats then
        local coins = stats:FindFirstChild("Coins")
        if coins then
            coins.Value = data.coins
        end
    end
    
    -- Hatch!
    local pet = PetSystem:HatchEgg(eggType)
    if pet then
        -- Add to inventory
        data.pets[pet.id] = (data.pets[pet.id] or 0) + 1
        
        -- Auto-equip if first pet
        if not data.equipped then
            data.equipped = pet.id
        end
        
        return pet, nil
    end
    
    return nil, "Hatch failed"
end

-- Expose hatch function
_G.HatchEgg = HatchEgg
_G.GetPlayerData = function(userId) return playerData[userId] end

print("[GameManager] Ready")

return {}
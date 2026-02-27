-- Game Manager
-- Main server controller

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

print("[GameManager] Loading...")

local LevelGenerator = require(script.Parent.LevelGenerator)
local GameConfig = require(game.ReplicatedStorage.Modules.GameConfig)

-- Setup level generator immediately
print("[GameManager] Starting LevelGenerator...")
local Generator = LevelGenerator.new()
Generator:start()

-- Handle players
Players.PlayerAdded:Connect(function(player)
    print("[GameManager] Player joined: " .. player.Name)
    
    -- Create leaderstats
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    
    local score = Instance.new("IntValue")
    score.Name = "Score"
    score.Value = 0
    score.Parent = leaderstats
    
    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = 0
    coins.Parent = leaderstats
    
    leaderstats.Parent = player
    
    -- Handle character
    player.CharacterAdded:Connect(function(char)
        print("[GameManager] Character spawned for " .. player.Name)
        
        local humanoid = char:WaitForChild("Humanoid")
        humanoid.Died:Connect(function()
            task.delay(3, function()
                player:LoadCharacter()
            end)
        end)
    end)
end)

print("[GameManager] Ready!")
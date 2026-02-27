-- Game Manager
-- Main server controller

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")
local MarketplaceService = game:GetService("MarketplaceService")

local LevelGenerator = require(script.Parent.LevelGenerator)
local GameConfig = require(game.ReplicatedStorage.Modules.GameConfig)

local GameManager = {}
GameManager.Players = {}
GameManager.Generator = nil

-- Data stores
local playerDataStore = DataStoreService:GetDataStore("PlayerData_v1")

function GameManager.init()
    GameManager.Generator = LevelGenerator.new()
    
    Players.PlayerAdded:Connect(GameManager.onPlayerAdded)
    Players.PlayerRemoving:Connect(GameManager.onPlayerRemoving)
    
    -- Start level generation
    GameManager.Generator:start()
    
    print("[GameManager] Initialized")
end

function GameManager.onPlayerAdded(player)
    -- Load data
    local success, data = pcall(function()
        return playerDataStore:GetAsync(player.UserId) or {}
    end)
    
    local playerData = {
        coins = data.coins or 0,
        highScore = data.highScore or 0,
        trails = data.trails or {},
        skins = data.skins or {},
        currentTrail = data.currentTrail or nil,
        currentSkin = data.currentSkin or nil,
        lives = 3,
        isPlaying = false,
    }
    
    GameManager.Players[player.UserId] = playerData
    
    -- Setup leaderstats
    local leaderstats = Instance.new("Folder")
    leaderstats.Name = "leaderstats"
    
    local score = Instance.new("IntValue")
    score.Name = "Score"
    score.Value = 0
    score.Parent = leaderstats
    
    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = playerData.coins
    coins.Parent = leaderstats
    
    leaderstats.Parent = player
    
    -- Spawn character
    player.CharacterAdded:Connect(function(char)
        GameManager.onCharacterAdded(player, char)
    end)
    
    print("[GameManager] Player joined:", player.Name)
end

function GameManager.onCharacterAdded(player, character)
    local humanoid = character:WaitForChild("Humanoid")
    local data = GameManager.Players[player.UserId]
    
    humanoid.Died:Connect(function()
        data.lives = data.lives - 1
        if data.lives <= 0 then
            -- Game over
            GameManager.savePlayerData(player)
        else
            -- Respawn
            task.delay(2, function()
                player:LoadCharacter()
            end)
        end
    end)
    
    -- Apply speed/jump from skins
    if data.currentSkin then
        for _, skin in ipairs(GameConfig.SHOP_ITEMS.SKINS) do
            if skin.id == data.currentSkin then
                if skin.speedBonus then
                    humanoid.WalkSpeed = GameConfig.PLAYER_SPEED + skin.speedBonus
                end
                if skin.jumpBonus then
                    humanoid.JumpPower = GameConfig.PLAYER_JUMP + skin.jumpBonus
                end
            end
        end
    end
    
    -- Position at spawn
    local hrp = character:WaitForChild("HumanoidRootPart")
    hrp.CFrame = CFrame.new(GameConfig.SPAWN_POSITION + Vector3.new(0, 5, 0))
end

function GameManager.onPlayerRemoving(player)
    GameManager.savePlayerData(player)
    GameManager.Players[player.UserId] = nil
end

function GameManager.savePlayerData(player)
    local data = GameManager.Players[player.UserId]
    if not data then return end
    
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        data.coins = leaderstats.Coins.Value
    end
    
    pcall(function()
        playerDataStore:SetAsync(player.UserId, data)
    end)
end

-- Periodic save
task.spawn(function()
    while true do
        task.wait(60)
        for _, player in ipairs(Players:GetPlayers()) do
            GameManager.savePlayerData(player)
        end
    end
end)

-- Dev products
MarketplaceService.ProcessReceipt = function(receiptInfo)
    local player = Players:GetPlayerByUserId(receiptInfo.PlayerId)
    if not player then return Enum.ProductPurchaseDecision.NotProcessedYet end
    
    local data = GameManager.Players[player.UserId]
    if not data then return Enum.ProductPurchaseDecision.NotProcessedYet end
    
    -- Handle purchases
    if receiptInfo.ProductId == REVIVE_PRODUCT_ID then
        -- Revive logic
        return Enum.ProductPurchaseDecision.PurchaseGranted
    end
    
    return Enum.ProductPurchaseDecision.NotProcessedYet
end

GameManager.init()
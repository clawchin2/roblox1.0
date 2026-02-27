-- Game Manager
-- Main server controller

local Players = game:GetService("Players")
local DataStoreService = game:GetService("DataStoreService")

local LevelGenerator = require(script.Parent.LevelGenerator)
local GameConfig = require(game.ReplicatedStorage.Modules.GameConfig)

local GameManager = {}
GameManager.Players = {}
GameManager.Generator = nil

-- Try to get data store (will fail if API not enabled)
local playerDataStore = nil
local dataStoreEnabled = pcall(function()
    playerDataStore = DataStoreService:GetDataStore("PlayerData_v1")
end)

if dataStoreEnabled then
    print("[GameManager] DataStore enabled")
else
    print("[GameManager] DataStore not available - running without persistence")
end

function GameManager.init()
    -- Start level generation BEFORE players join
    GameManager.Generator = LevelGenerator.new()
    GameManager.Generator:start()
    
    Players.PlayerAdded:Connect(GameManager.onPlayerAdded)
    Players.PlayerRemoving:Connect(GameManager.onPlayerRemoving)
    
    print("[GameManager] Initialized - waiting for players")
end

function GameManager.onPlayerAdded(player)
    print("[GameManager] Player joining:", player.Name)
    
    -- Load data (with fallback if datastore fails)
    local data = {}
    if dataStoreEnabled then
        local success, loadedData = pcall(function()
            return playerDataStore:GetAsync(player.UserId) or {}
        end)
        if success then
            data = loadedData
        end
    end
    
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
    
    -- Handle character spawning
    player.CharacterAdded:Connect(function(char)
        GameManager.onCharacterAdded(player, char)
    end)
    
    print("[GameManager] Player ready:", player.Name)
end

function GameManager.onCharacterAdded(player, character)
    print("[GameManager] Character spawned for", player.Name)
    
    local humanoid = character:WaitForChild("Humanoid")
    local data = GameManager.Players[player.UserId]
    
    -- Handle death
    humanoid.Died:Connect(function()
        data.lives = data.lives - 1
        if data.lives <= 0 then
            GameManager.savePlayerData(player)
        else
            task.delay(2, function()
                player:LoadCharacter()
            end)
        end
    end)
    
    -- SpawnLocation handles the spawn position automatically
    -- Just print for debugging
    local hrp = character:WaitForChild("HumanoidRootPart")
    if hrp then
        print("[GameManager] Spawned at", tostring(hrp.Position))
    end
end

function GameManager.onPlayerRemoving(player)
    GameManager.savePlayerData(player)
    GameManager.Players[player.UserId] = nil
end

function GameManager.savePlayerData(player)
    if not dataStoreEnabled then return end
    
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

-- Periodic save (only if datastore enabled)
if dataStoreEnabled then
    task.spawn(function()
        while true do
            task.wait(60)
            for _, player in ipairs(Players:GetPlayers()) do
                GameManager.savePlayerData(player)
            end
        end
    end)
end

GameManager.init()
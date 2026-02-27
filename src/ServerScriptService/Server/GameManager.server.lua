-- Game Manager - FIXED VERSION
-- Server controller with working coins, distance, and backgrounds

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

print("[GameManager] Initializing...")

-- Get modules
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

-- Safety configuration
local SAFETY_CONFIG = {
    FALL_THRESHOLD = -50,
    CHECK_INTERVAL = 0.5,
    TELEPORT_OFFSET = Vector3.new(0, 5, 0),
    MAX_FALL_DISTANCE = -100,
}

-- Player data
local playerData = {}

-- Initialize player
local function initPlayer(player)
    playerData[player.UserId] = {
        startZ = nil,
        furthestDistance = 0,
        coins = 0,
    }
    
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
    
    print("[GameManager] Leaderstats created for " .. player.Name)
end

-- Setup character tracking
local function setupCharacter(player, character)
    local data = playerData[player.UserId]
    if not data then return end
    
    local hrp = character:WaitForChild("HumanoidRootPart")
    local humanoid = character:WaitForChild("Humanoid")
    
    -- Set start Z position
    data.startZ = hrp.Position.Z
    print("[GameManager] " .. player.Name .. " start Z: " .. data.startZ)
    
    -- Handle death
    humanoid.Died:Connect(function()
        task.delay(3, function()
            if player.Parent then
                player:LoadCharacter()
            end
        end)
    end)
end

-- Players joining
Players.PlayerAdded:Connect(function(player)
    print("[GameManager] Player joined: " .. player.Name)
    initPlayer(player)
    
    player.CharacterAdded:Connect(function(char)
        setupCharacter(player, char)
    end)
end)

-- Main update loop - Distance tracking
print("[GameManager] Starting distance tracking...")
task.spawn(function()
    while true do
        task.wait(0.1) -- Update every 0.1 seconds
        
        for _, player in ipairs(Players:GetPlayers()) do
            local data = playerData[player.UserId]
            if not data then continue end
            if not data.startZ then continue end
            
            local char = player.Character
            if not char then continue end
            
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            
            -- Calculate distance
            local currentZ = hrp.Position.Z
            local distance = data.startZ - currentZ
            
            if distance > 0 then
                data.furthestDistance = math.max(data.furthestDistance, distance)
                
                -- Update leaderstats
                local leaderstats = player:FindFirstChild("leaderstats")
                if leaderstats then
                    local score = leaderstats:FindFirstChild("Score")
                    if score then
                        score.Value = math.floor(data.furthestDistance)
                    end
                end
            end
            
            -- Safety check - teleport if fell
            if hrp.Position.Y < SAFETY_CONFIG.FALL_THRESHOLD then
                hrp.CFrame = CFrame.new(0, 15, 0)
                print("[GameManager] Teleported " .. player.Name .. " back to start")
            end
        end
    end
end)

-- COIN COLLECTION - Direct touch handler
print("[GameManager] Setting up coin collection...")

local function setupCoin(coin)
    if coin:GetAttribute("CoinSetup") then return end
    coin:SetAttribute("CoinSetup", true)
    
    coin.Touched:Connect(function(hit)
        local char = hit:FindFirstAncestorOfClass("Model")
        if not char then return end
        
        local player = Players:GetPlayerFromCharacter(char)
        if not player then return end
        
        if not coin or not coin.Parent then return end
        
        -- Get value
        local value = coin:GetAttribute("CoinValue") or 10
        
        -- Update coins
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local coins = leaderstats:FindFirstChild("Coins")
            if coins then
                coins.Value = coins.Value + value
                print("[GameManager] " .. player.Name .. " collected coin: " .. value .. " (Total: " .. coins.Value .. ")")
            end
        end
        
        -- Destroy with effect
        coin:Destroy()
    end)
end

-- Setup existing coins
for _, obj in ipairs(workspace:GetDescendants()) do
    if obj.Name == "Coin" and obj:IsA("BasePart") then
        setupCoin(obj)
    end
end

-- Setup new coins as they're created
workspace.DescendantAdded:Connect(function(descendant)
    if descendant.Name == "Coin" and descendant:IsA("BasePart") then
        task.wait(0.1) -- Small delay to ensure coin is fully created
        setupCoin(descendant)
    end
end)

-- BACKGROUND MANAGER START
print("[GameManager] Starting BackgroundManager...")
local bgModule = script.Parent:FindFirstChild("BackgroundManager")
if bgModule then
    local success, BackgroundManager = pcall(function()
        return require(bgModule)
    end)
    if success and BackgroundManager then
        local bgSuccess, bgErr = pcall(function()
            local bg = BackgroundManager.new()
            bg:start()
            _G.BackgroundManager = bg
        end)
        if bgSuccess then
            print("[GameManager] BackgroundManager started!")
        else
            warn("[GameManager] BackgroundManager failed: " .. tostring(bgErr))
        end
    else
        warn("[GameManager] Could not load BackgroundManager: " .. tostring(BackgroundManager))
    end
else
    warn("[GameManager] BackgroundManager not found")
end

print("[GameManager] Ready! Distance tracking and coins active.")
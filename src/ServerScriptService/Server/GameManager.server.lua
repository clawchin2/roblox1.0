-- Game Manager - ULTRA DEBUG VERSION
-- With extensive logging to find the issue

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

print("[GameManager] ==========================================")
print("[GameManager] INITIALIZING")
print("[GameManager] ==========================================")

local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

-- Player data
local playerData = {}

-- Initialize player
local function initPlayer(player)
    print("[GameManager] initPlayer called for " .. player.Name)
    
    playerData[player.UserId] = {
        startZ = nil,
        furthestDistance = 0,
    }
    
    -- Create leaderstats IMMEDIATELY
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
    print("[GameManager] Score value: " .. score.Value)
    print("[GameManager] Coins value: " .. coins.Value)
end

-- Setup character
local function setupCharacter(player, character)
    print("[GameManager] setupCharacter for " .. player.Name)
    
    local data = playerData[player.UserId]
    if not data then 
        print("[GameManager] No data for player!")
        return 
    end
    
    local hrp = character:WaitForChild("HumanoidRootPart", 5)
    if not hrp then
        print("[GameManager] HumanoidRootPart not found!")
        return
    end
    
    data.startZ = hrp.Position.Z
    print("[GameManager] Start Z set: " .. data.startZ)
end

-- Players joining
Players.PlayerAdded:Connect(function(player)
    print("[GameManager] PlayerAdded: " .. player.Name)
    initPlayer(player)
    
    if player.Character then
        print("[GameManager] Character already exists, setting up...")
        setupCharacter(player, player.Character)
    end
    
    player.CharacterAdded:Connect(function(char)
        print("[GameManager] CharacterAdded for " .. player.Name)
        setupCharacter(player, char)
    end)
end)

-- DISTANCE TRACKING
print("[GameManager] Starting distance tracking loop...")
task.spawn(function()
    local loopCount = 0
    while true do
        task.wait(0.5)
        loopCount = loopCount + 1
        
        for _, player in ipairs(Players:GetPlayers()) do
            local data = playerData[player.UserId]
            if not data then continue end
            if not data.startZ then continue end
            
            local char = player.Character
            if not char then continue end
            
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            
            local currentZ = hrp.Position.Z
            local distance = data.startZ - currentZ
            
            if distance > 0 and distance > data.furthestDistance then
                data.furthestDistance = distance
                
                local leaderstats = player:FindFirstChild("leaderstats")
                if leaderstats then
                    local score = leaderstats:FindFirstChild("Score")
                    if score then
                        score.Value = math.floor(distance)
                        if loopCount % 10 == 0 then -- Print every 5 seconds
                            print("[GameManager] " .. player.Name .. " distance: " .. math.floor(distance) .. "m")
                        end
                    end
                end
            end
        end
    end
end)

-- COIN COLLECTION
print("[GameManager] Setting up coin collection...")

local function setupCoin(coin)
    if coin:GetAttribute("CoinSetup") then return end
    coin:SetAttribute("CoinSetup", true)
    
    print("[GameManager] Setting up coin: " .. coin:GetFullName())
    
    coin.Touched:Connect(function(hit)
        local char = hit:FindFirstAncestorOfClass("Model")
        if not char then return end
        
        local player = Players:GetPlayerFromCharacter(char)
        if not player then return end
        
        if not coin or not coin.Parent then return end
        
        local value = coin:GetAttribute("CoinValue") or 10
        
        print("[GameManager] Coin touched by " .. player.Name .. " value: " .. value)
        
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local coins = leaderstats:FindFirstChild("Coins")
            if coins then
                coins.Value = coins.Value + value
                print("[GameManager] " .. player.Name .. " now has " .. coins.Value .. " coins")
            else
                print("[GameManager] ERROR: Coins leaderstat not found!")
            end
        else
            print("[GameManager] ERROR: Leaderstats not found!")
        end
        
        coin:Destroy()
    end)
end

-- Setup existing coins
local existingCoins = 0
for _, obj in ipairs(workspace:GetDescendants()) do
    if obj.Name == "Coin" and obj:IsA("BasePart") then
        setupCoin(obj)
        existingCoins = existingCoins + 1
    end
end
print("[GameManager] Set up " .. existingCoins .. " existing coins")

-- Setup new coins
workspace.DescendantAdded:Connect(function(descendant)
    if descendant.Name == "Coin" and descendant:IsA("BasePart") then
        print("[GameManager] New coin created: " .. descendant:GetFullName())
        task.wait(0.1)
        setupCoin(descendant)
    end
end)

print("[GameManager] ==========================================")
print("[GameManager] READY")
print("[GameManager] ==========================================")
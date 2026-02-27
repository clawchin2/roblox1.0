-- Game Manager
-- Main server controller with safety mechanics and checkpoint system

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

print("[GameManager] Initializing...")

-- Safety configuration
local SAFETY_CONFIG = {
    FALL_THRESHOLD = -50,           -- Teleport if below Y = -50
    CHECK_INTERVAL = 0.5,           -- Check every 0.5 seconds
    TELEPORT_OFFSET = Vector3.new(0, 5, 0),  -- Spawn slightly above checkpoint
    MAX_FALL_DISTANCE = -100,       -- Emergency respawn threshold
}

-- Player data storage
local playerData = {}

-- Initialize player data
local function initPlayerData(player)
    playerData[player.UserId] = {
        lastCheckpointPlatform = nil,  -- Index of last touched checkpoint
        lastCheckpointPosition = Vector3.new(0, 15, 0),  -- Last safe position
        furthestDistance = 0,          -- Furthest Z distance reached
        currentDistance = 0,           -- Current distance
        platformsTouched = {},         -- Track touched platforms
        isFalling = false,             -- Falling state
    }
end

-- Clean up player data
local function cleanupPlayerData(player)
    playerData[player.UserId] = nil
end

-- Get player's current distance (negative Z)
local function getPlayerDistance(player)
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local pos = player.Character.HumanoidRootPart.Position
        return math.abs(pos.Z)  -- Distance from start
    end
    return 0
end

-- Teleport player to checkpoint
local function teleportToCheckpoint(player)
    local data = playerData[player.UserId]
    if not data then return end
    
    local checkpointPos = data.lastCheckpointPosition
    local targetPos = checkpointPos + SAFETY_CONFIG.TELEPORT_OFFSET
    
    if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
        local hrp = player.Character.HumanoidRootPart
        hrp.CFrame = CFrame.new(targetPos)
        
        -- Reset velocity
        if player.Character:FindFirstChild("Humanoid") then
            player.Character.Humanoid:ChangeState(Enum.HumanoidStateType.GettingUp)
        end
        
        print("[GameManager] Teleported " .. player.Name .. " to checkpoint at " .. tostring(checkpointPos))
    end
end

-- Safety check - monitor player fall
local function checkPlayerSafety(player)
    local data = playerData[player.UserId]
    if not data then return end
    
    if not player.Character or not player.Character:FindFirstChild("HumanoidRootPart") then
        return
    end
    
    local hrp = player.Character.HumanoidRootPart
    local pos = hrp.Position
    
    -- Check if player fell below threshold
    if pos.Y < SAFETY_CONFIG.FALL_THRESHOLD then
        print("[GameManager] " .. player.Name .. " fell below threshold (Y=" .. pos.Y .. "), teleporting to checkpoint")
        teleportToCheckpoint(player)
        data.isFalling = false
        return
    end
    
    -- Emergency check - way too far down
    if pos.Y < SAFETY_CONFIG.MAX_FALL_DISTANCE then
        print("[GameManager] EMERGENCY: " .. player.Name .. " way below threshold, respawning")
        player:LoadCharacter()
        return
    end
    
    -- Update distance tracking
    local currentDist = math.abs(pos.Z)
    data.currentDistance = currentDist
    
    -- Update furthest distance and leaderstats
    if currentDist > data.furthestDistance then
        data.furthestDistance = currentDist
        
        -- Update leaderstats immediately
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats then
            local score = leaderstats:FindFirstChild("Score")
            if score then
                score.Value = math.floor(data.furthestDistance)
            end
        end
    end
end

-- Setup platform touch detection for checkpoint system
local function setupPlatformDetection(player, character)
    local humanoid = character:WaitForChild("Humanoid")
    local hrp = character:WaitForChild("HumanoidRootPart")
    
    local data = playerData[player.UserId]
    if not data then return end
    
    -- Touch detection connection
    local touchConnection = hrp.Touched:Connect(function(hit)
        -- Check if touched a platform
        if hit.Name:match("Platform") or hit.Parent.Name:match("GeneratedLevel") then
            -- Update checkpoint if it's a checkpoint platform
            local isCheckpoint = hit:GetAttribute("IsCheckpoint")
            local platformIndex = hit:GetAttribute("PlatformIndex")
            
            if isCheckpoint and platformIndex then
                data.lastCheckpointPlatform = platformIndex
                data.lastCheckpointPosition = hit.Position
                print("[GameManager] " .. player.Name .. " reached checkpoint at platform #" .. platformIndex)
            end
            
            -- Always update last safe position when touching any platform
            if hit.Position.Y > SAFETY_CONFIG.FALL_THRESHOLD then
                data.lastCheckpointPosition = hit.Position
            end
        end
    end)
    
    -- Store connection for cleanup
    data.touchConnection = touchConnection
    
    -- Handle death
    humanoid.Died:Connect(function()
        if data.touchConnection then
            data.touchConnection:Disconnect()
        end
        
        -- Respawn at checkpoint after delay
        task.delay(3, function()
            if player.Parent then
                player:LoadCharacter()
            end
        end)
    end)
end

-- Handle players
Players.PlayerAdded:Connect(function(player)
    print("[GameManager] Player joined: " .. player.Name)
    
    -- Initialize player data
    initPlayerData(player)
    
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
    
    local distance = Instance.new("IntValue")
    distance.Name = "Distance"
    distance.Value = 0
    distance.Parent = leaderstats
    
    leaderstats.Parent = player
    
    -- Handle character
    player.CharacterAdded:Connect(function(char)
        print("[GameManager] Character spawned for " .. player.Name)
        
        -- Setup platform detection for checkpoint system
        setupPlatformDetection(player, char)
        
        -- Reset falling state
        local data = playerData[player.UserId]
        if data then
            data.isFalling = false
        end
    end)
    
    player.CharacterRemoving:Connect(function()
        local data = playerData[player.UserId]
        if data and data.touchConnection then
            data.touchConnection:Disconnect()
            data.touchConnection = nil
        end
    end)
end)

Players.PlayerRemoving:Connect(function(player)
    print("[GameManager] Player left: " .. player.Name)
    cleanupPlayerData(player)
end)

-- Main safety check loop
print("[GameManager] Starting safety check loop...")
task.spawn(function()
    while true do
        task.wait(SAFETY_CONFIG.CHECK_INTERVAL)
        
        for _, player in ipairs(Players:GetPlayers()) do
            local success, err = pcall(function()
                checkPlayerSafety(player)
            end)
            if not success then
                warn("[GameManager] Error checking safety for " .. player.Name .. ": " .. tostring(err))
            end
        end
    end
end)

print("[GameManager] Ready! Safety checks active.")

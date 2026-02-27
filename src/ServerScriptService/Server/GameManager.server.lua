-- GameManager - FIXED with proper respawn and visible score
print("[GameManager] Loading...")

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local playerData = {}

Players.PlayerAdded:Connect(function(player)
    print("[GameManager] Player joined: " .. player.Name)
    
    -- Create leaderstats
    local stats = Instance.new("Folder")
    stats.Name = "leaderstats"
    
    local score = Instance.new("IntValue")
    score.Name = "Score"
    score.Value = 0
    score.Parent = stats
    
    local coins = Instance.new("IntValue")
    coins.Name = "Coins"
    coins.Value = 0
    coins.Parent = stats
    
    stats.Parent = player
    
    playerData[player.UserId] = {
        startZ = nil,
        distance = 0,
        deaths = 0,
        hasSpawned = false
    }
    
    -- Handle character spawn
    player.CharacterAdded:Connect(function(char)
        print("[GameManager] Character added for " .. player.Name)
        
        local data = playerData[player.UserId]
        local hrp = char:WaitForChild("HumanoidRootPart")
        local humanoid = char:WaitForChild("Humanoid")
        
        -- ALWAYS teleport to start position
        task.wait(0.1)
        hrp.CFrame = CFrame.new(GameConfig.SPAWN_POSITION + Vector3.new(0, 5, 0))
        print("[GameManager] Teleported " .. player.Name .. " to spawn")
        
        -- Reset distance tracking from new position
        task.wait(0.2)
        data.startZ = hrp.Position.Z
        data.distance = 0
        
        -- Update score to 0
        local stats = player:FindFirstChild("leaderstats")
        if stats then
            local score = stats:FindFirstChild("Score")
            if score then
                score.Value = 0
            end
        end
        
        -- Handle death
        humanoid.Died:Connect(function()
            print("[GameManager] " .. player.Name .. " died")
            data.deaths = data.deaths + 1
            
            task.delay(2, function()
                if player.Parent then
                    player:LoadCharacter()
                end
            end)
        end)
    end)
end)

-- Distance tracking
 task.spawn(function()
    while true do
        task.wait(0.1) -- Update faster
        
        for _, player in ipairs(Players:GetPlayers()) do
            local data = playerData[player.UserId]
            if not data or not data.startZ then continue end
            
            local char = player.Character
            if not char then continue end
            
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            
            -- Calculate distance
            local dist = math.floor(data.startZ - hrp.Position.Z)
            
            if dist > 0 and dist > data.distance then
                data.distance = dist
                
                -- Update leaderstats
                local stats = player:FindFirstChild("leaderstats")
                if stats then
                    local score = stats:FindFirstChild("Score")
                    if score then
                        score.Value = data.distance
                    end
                end
            end
            
            -- Fall safety - die if fall too far
            if hrp.Position.Y < -20 then
                local humanoid = char:FindFirstChild("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    humanoid.Health = 0
                end
            end
        end
    end
end)

print("[GameManager] Ready")
-- GameManager - Fixed with respawn handling
print("[GameManager] Loading...")

local Players = game:GetService("Players")

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
        deaths = 0
    }
    
    -- Handle spawn
    player.CharacterAdded:Connect(function(char)
        local hrp = char:WaitForChild("HumanoidRootPart")
        local humanoid = char:WaitForChild("Humanoid")
        
        local data = playerData[player.UserId]
        
        -- If respawn (not first spawn), teleport to start
        if data.deaths > 0 then
            hrp.CFrame = CFrame.new(GameConfig.SPAWN_POSITION + Vector3.new(0, 5, 0))
            print("[GameManager] Respawned " .. player.Name .. " at start")
        end
        
        -- Set start Z for distance tracking
        task.wait(0.1) -- Small delay to ensure position set
        data.startZ = hrp.Position.Z
        
        -- Handle death
        humanoid.Died:Connect(function()
            data.deaths = data.deaths + 1
            task.delay(2, function()
                if player.Parent then
                    player:LoadCharacter()
                end
            end)
        end)
    end)
end)

-- Distance tracking with print debug
 task.spawn(function()
    while true do
        task.wait(0.5)
        
        for _, player in ipairs(Players:GetPlayers()) do
            local data = playerData[player.UserId]
            if not data or not data.startZ then continue end
            
            local char = player.Character
            if not char then continue end
            
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            
            local dist = math.floor(data.startZ - hrp.Position.Z)
            if dist > 0 and dist > data.distance then
                data.distance = dist
                
                local stats = player:FindFirstChild("leaderstats")
                if stats then
                    local score = stats:FindFirstChild("Score")
                    if score then
                        score.Value = data.distance
                        -- Print every 50m
                        if dist % 50 == 0 then
                            print("[GameManager] " .. player.Name .. " reached " .. dist .. "m")
                        end
                    end
                end
            end
            
            -- Fall safety
            if hrp.Position.Y < -30 then
                local humanoid = char:FindFirstChild("Humanoid")
                if humanoid then
                    humanoid.Health = 0
                end
            end
        end
    end
end)

print("[GameManager] Ready")
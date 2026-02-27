-- GameManager - FIXED with permanent UI and infinite generation
print("[GameManager] Loading...")

local Players = game:GetService("Players")

-- Store player data
local playerData = {}

Players.PlayerAdded:Connect(function(player)
    print("[GameManager] Player joined: " .. player.Name)
    
    -- Initialize data
    playerData[player.UserId] = {
        startZ = nil,
        distance = 0,
        hasSpawned = false
    }
    
    -- Handle character
    player.CharacterAdded:Connect(function(char)
        print("[GameManager] Character spawned for " .. player.Name)
        
        local data = playerData[player.UserId]
        local hrp = char:WaitForChild("HumanoidRootPart")
        local humanoid = char:WaitForChild("Humanoid")
        
        -- ALWAYS reset to spawn position
        task.wait(0.1)
        hrp.CFrame = CFrame.new(0, 15, 0)
        data.startZ = 0
        data.distance = 0
        
        print("[GameManager] Reset " .. player.Name .. " to start")
        
        -- Death handler
        humanoid.Died:Connect(function()
            print("[GameManager] " .. player.Name .. " died")
            task.delay(2, function()
                if player.Parent then
                    player:LoadCharacter()
                end
            end)
        end)
    end)
end)

-- Distance tracking - runs forever
print("[GameManager] Starting distance tracker...")
task.spawn(function()
    while true do
        task.wait(0.1)
        
        for _, player in ipairs(Players:GetPlayers()) do
            local data = playerData[player.UserId]
            if not data then continue end
            
            local char = player.Character
            if not char then continue end
            
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if not hrp then continue end
            
            -- Calculate distance from spawn (0,0,0)
            local currentZ = hrp.Position.Z
            local dist = math.floor(-currentZ) -- Negative Z is forward
            
            if dist > 0 and dist > data.distance then
                data.distance = dist
                
                -- Update leaderstats
                local stats = player:FindFirstChild("leaderstats")
                if not stats then
                    -- Recreate if missing
                    stats = Instance.new("Folder")
                    stats.Name = "leaderstats"
                    
                    local score = Instance.new("IntValue")
                    score.Name = "Score"
                    score.Parent = stats
                    
                    local coins = Instance.new("IntValue")
                    coins.Name = "Coins"
                    coins.Value = 0
                    coins.Parent = stats
                    
                    stats.Parent = player
                end
                
                local score = stats:FindFirstChild("Score")
                if score then
                    score.Value = data.distance
                end
            end
            
            -- Fall death
            if hrp.Position.Y < -20 then
                humanoid.Health = 0
            end
        end
    end
end)

print("[GameManager] Ready")
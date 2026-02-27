-- GameManager
print("[GameManager] Starting...")

local Players = game:GetService("Players")

-- Player data
local data = {}

Players.PlayerAdded:Connect(function(player)
    print("Player joined: " .. player.Name)
    
    -- Create leaderstats
    local stats = Instance.new("Folder")
    stats.Name = "leaderstats"
    
    local score = Instance.new("IntValue")
    score.Name = "Score"
    score.Value = 0
    score.Parent = stats
    
    stats.Parent = player
    
    -- Store data
    data[player.UserId] = {
        startZ = nil,
        dist = 0
    }
    
    -- Character spawn
    player.CharacterAdded:Connect(function(char)
        local hrp = char:WaitForChild("HumanoidRootPart")
        local humanoid = char:WaitForChild("Humanoid")
        
        -- Reset to spawn
        hrp.CFrame = CFrame.new(0, 15, 0)
        
        -- Set start Z
        data[player.UserId].startZ = 0
        data[player.UserId].dist = 0
        
        -- Reset score
        local s = player:FindFirstChild("leaderstats")
        if s then
            local sc = s:FindFirstChild("Score")
            if sc then sc.Value = 0 end
        end
        
        -- Death
        humanoid.Died:Connect(function()
            task.wait(2)
            player:LoadCharacter()
        end)
    end)
end)

-- Track distance
while true do
    task.wait(0.1)
    
    for _, player in ipairs(Players:GetPlayers()) do
        local d = data[player.UserId]
        if not d or not d.startZ then continue end
        
        local char = player.Character
        if not char then continue end
        
        local hrp = char:FindFirstChild("HumanoidRootPart")
        if not hrp then continue end
        
        -- Distance is negative Z (running forward)
        local dist = math.floor(-hrp.Position.Z)
        
        if dist > 0 and dist > d.dist then
            d.dist = dist
            
            local s = player:FindFirstChild("leaderstats")
            if s then
                local sc = s:FindFirstChild("Score")
                if sc then sc.Value = dist end
            end
        end
        
        -- Fall death
        if hrp.Position.Y < -20 then
            local hum = char:FindFirstChild("Humanoid")
            if hum then hum.Health = 0 end
        end
    end
end
-- GameManager - Server controller
print("[GameManager] Loading...")

local Players = game:GetService("Players")

-- Simple player data
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
        distance = 0
    }
    
    -- Track character
    player.CharacterAdded:Connect(function(char)
        local hrp = char:WaitForChild("HumanoidRootPart")
        playerData[player.UserId].startZ = hrp.Position.Z
        print("[GameManager] Start position set for " .. player.Name)
    end)
end)

-- Distance tracking
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
            if dist > 0 then
                data.distance = math.max(data.distance, dist)
                
                local stats = player:FindFirstChild("leaderstats")
                if stats then
                    local score = stats:FindFirstChild("Score")
                    if score then
                        score.Value = data.distance
                    end
                end
            end
        end
    end
end)

print("[GameManager] Ready")
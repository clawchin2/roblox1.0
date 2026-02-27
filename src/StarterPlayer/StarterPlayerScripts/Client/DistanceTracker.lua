-- Distance Tracker
-- Tracks player progress and updates score

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer
local GameConfig = require(game.ReplicatedStorage.Modules.GameConfig)

local DistanceTracker = {}
DistanceTracker.currentDistance = 0
DistanceTracker.bestDistance = 0
DistanceTracker.isRunning = false

function DistanceTracker.init()
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    
    local startZ = hrp.Position.Z
    DistanceTracker.isRunning = true
    
    RunService.Heartbeat:Connect(function()
        if not DistanceTracker.isRunning then return end
        if not hrp or not hrp.Parent then
            character = player.Character
            if character then
                hrp = character:FindFirstChild("HumanoidRootPart")
            end
            return
        end
        
        local distance = math.abs(startZ - hrp.Position.Z)
        DistanceTracker.currentDistance = math.floor(distance)
        
        -- Update leaderstats
        local leaderstats = player:FindFirstChild("leaderstats")
        if leaderstats and leaderstats:FindFirstChild("Score") then
            leaderstats.Score.Value = DistanceTracker.currentDistance
        end
        
        if DistanceTracker.currentDistance > DistanceTracker.bestDistance then
            DistanceTracker.bestDistance = DistanceTracker.currentDistance
        end
    end)
end

return DistanceTracker
-- Distance Tracker
-- Tracks player progress and updates score

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local player = Players.LocalPlayer

local DistanceTracker = {}
DistanceTracker.currentDistance = 0
DistanceTracker.bestDistance = 0
DistanceTracker.isRunning = false

function DistanceTracker.init()
    print("[DistanceTracker] Initializing...")
    
    -- Wait for character
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    
    -- Wait a frame to ensure leaderstats is created by server
    task.wait(0.1)
    
    -- Get or wait for leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then
        leaderstats = player.ChildAdded:Wait()
        while leaderstats.Name ~= "leaderstats" do
            leaderstats = player.ChildAdded:Wait()
        end
    end
    
    -- Get score value
    local scoreValue = leaderstats:WaitForChild("Score")
    
    -- Store starting Z position
    local startZ = hrp.Position.Z
    DistanceTracker.isRunning = true
    
    print("[DistanceTracker] Started tracking from Z=" .. startZ)
    
    -- Update loop - runs every heartbeat for smooth updates
    RunService.Heartbeat:Connect(function()
        if not DistanceTracker.isRunning then return end
        
        -- Re-find hrp if character respawned
        if not hrp or not hrp.Parent then
            character = player.Character
            if character then
                hrp = character:FindFirstChild("HumanoidRootPart")
                if hrp then
                    startZ = hrp.Position.Z  -- Reset start position on respawn
                    print("[DistanceTracker] Character respawned, reset start Z to " .. startZ)
                end
            end
            return
        end
        
        -- Calculate distance traveled (absolute difference in Z)
        -- Player runs in negative Z direction, so we use abs
        local currentZ = hrp.Position.Z
        local rawDistance = startZ - currentZ
        
        -- If running forward (more negative Z), distance increases
        -- If somehow running backward, clamp to 0
        local distance = math.max(0, rawDistance)
        DistanceTracker.currentDistance = math.floor(distance + 0.5)  -- Round to nearest integer
        
        -- Update leaderstats Score
        if scoreValue and scoreValue.Parent then
            scoreValue.Value = DistanceTracker.currentDistance
        end
        
        -- Track best distance
        if DistanceTracker.currentDistance > DistanceTracker.bestDistance then
            DistanceTracker.bestDistance = DistanceTracker.currentDistance
        end
    end)
    
    print("[DistanceTracker] Initialization complete")
end

-- Get current distance (for other systems)
function DistanceTracker.getDistance()
    return DistanceTracker.currentDistance
end

-- Get best distance
function DistanceTracker.getBestDistance()
    return DistanceTracker.bestDistance
end

-- Stop tracking (e.g., on death)
function DistanceTracker.stop()
    DistanceTracker.isRunning = false
end

-- Restart tracking (e.g., on respawn)
function DistanceTracker.restart()
    DistanceTracker.isRunning = true
    DistanceTracker.currentDistance = 0
end

return DistanceTracker

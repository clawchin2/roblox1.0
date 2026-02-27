-- Level Generator
-- Server-side procedural generation

print("[LevelGenerator] Module loading...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Platform = require(ReplicatedStorage.Modules.PlatformModule)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

print("[LevelGenerator] Dependencies loaded")

local LevelGenerator = {}
LevelGenerator.__index = LevelGenerator

function LevelGenerator.new()
    print("[LevelGenerator] Creating new instance...")
    local self = setmetatable({}, LevelGenerator)
    self.platforms = {}
    self.currentDistance = 0
    self.lastPlatformPos = Vector3.new(0, 10, -30)
    self.active = false
    print("[LevelGenerator] Instance created")
    return self
end

function LevelGenerator:getDifficultySettings(distance)
    local stages = GameConfig.DIFFICULTY_STAGES
    for i = #stages, 1, -1 do
        if distance >= stages[i].distance then
            return stages[i]
        end
    end
    return stages[1]
end

function LevelGenerator:selectPlatformType(settings)
    local rand = math.random()
    if rand < settings.specialChance then
        local specials = {Platform.Types.MOVING, Platform.Types.ROTATING, Platform.Types.BOUNCE}
        return specials[math.random(1, #specials)]
    elseif rand < settings.specialChance + settings.hazardChance then
        local hazards = {Platform.Types.KILL, Platform.Types.FADING, Platform.Types.CRUMBLING}
        return hazards[math.random(1, #hazards)]
    end
    return Platform.Types.STATIC
end

function LevelGenerator:generateNextPlatform()
    local settings = self:getDifficultySettings(self.currentDistance)
    local gap = math.random(settings.gapRange[1], settings.gapRange[2])
    local platformType = self:selectPlatformType(settings)
    
    local xOffset = math.random(-5, 5)
    local newPos = self.lastPlatformPos + Vector3.new(xOffset, 0, -gap)
    
    if self.currentDistance > 200 then
        newPos = newPos + Vector3.new(0, math.random(-2, 2), 0)
    end
    
    local success, platform, part = pcall(function()
        return Platform.CreatePlatform(platformType, newPos, self.platformFolder)
    end)
    
    if success then
        table.insert(self.platforms, platform)
        self.lastPlatformPos = newPos
        self.currentDistance = self.currentDistance + gap
        return platform
    else
        warn("[LevelGenerator] Failed to create platform: " .. tostring(platform))
        return nil
    end
end

function LevelGenerator:start()
    print("[LevelGenerator] START called!")
    
    self.active = true
    
    -- Create folder
    print("[LevelGenerator] Creating platform folder...")
    self.platformFolder = Instance.new("Folder")
    self.platformFolder.Name = "GeneratedLevel"
    self.platformFolder.Parent = workspace
    print("[LevelGenerator] Folder created: " .. self.platformFolder:GetFullName())
    
    -- Generate platforms
    print("[LevelGenerator] Generating 25 initial platforms...")
    local count = 0
    for i = 1, 25 do
        local platform = self:generateNextPlatform()
        if platform then
            count = count + 1
        end
        -- Small delay to prevent lag
        if i % 5 == 0 then
            task.wait(0.01)
        end
    end
    
    print("[LevelGenerator] Successfully created " .. count .. " platforms!")
    print("[LevelGenerator] Last platform at: " .. tostring(self.lastPlatformPos))
    
    -- Continuous generation
    task.spawn(function()
        print("[LevelGenerator] Starting continuous generation loop...")
        while self.active do
            task.wait(1)
            
            local furthestZ = 0
            local playerCount = 0
            
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local z = player.Character.HumanoidRootPart.Position.Z
                    if z < furthestZ then
                        furthestZ = z
                    end
                    playerCount = playerCount + 1
                end
            end
            
            -- Generate more platforms ahead of players
            while self.lastPlatformPos.Z > furthestZ - 100 do
                self:generateNextPlatform()
            end
        end
    end)
    
    print("[LevelGenerator] FULLY STARTED AND RUNNING!")
end

function LevelGenerator:stop()
    print("[LevelGenerator] Stopping...")
    self.active = false
    for _, platform in ipairs(self.platforms) do 
        if platform and platform.destroy then 
            platform:destroy() 
        end 
    end
    self.platforms = {}
    if self.platformFolder then 
        self.platformFolder:Destroy() 
    end
    print("[LevelGenerator] Stopped")
end

print("[LevelGenerator] Module fully loaded and ready!")

return LevelGenerator
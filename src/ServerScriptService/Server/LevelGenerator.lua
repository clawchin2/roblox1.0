-- Level Generator
-- Server-side procedural generation

local Platform = require(game.ReplicatedStorage.Modules.PlatformModule)
local GameConfig = require(game.ReplicatedStorage.Modules.GameConfig)

local LevelGenerator = {}
LevelGenerator.__index = LevelGenerator

function LevelGenerator.new()
    local self = setmetatable({}, LevelGenerator)
    self.platforms = {}
    self.currentDistance = 0
    self.lastPlatformPos = Vector3.new(0, 10, -30)
    self.active = false
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
    
    local platform, part = Platform.CreatePlatform(platformType, newPos, self.platformFolder)
    
    table.insert(self.platforms, platform)
    self.lastPlatformPos = newPos
    self.currentDistance = self.currentDistance + gap
    
    return platform
end

function LevelGenerator:start()
    print("[LevelGenerator] STARTING level generation...")
    
    self.active = true
    self.platformFolder = Instance.new("Folder")
    self.platformFolder.Name = "GeneratedLevel"
    self.platformFolder.Parent = workspace
    
    -- Generate platforms
    print("[LevelGenerator] Generating initial platforms...")
    for i = 1, 25 do
        self:generateNextPlatform()
    end
    
    print("[LevelGenerator] Generated " .. tostring(#self.platforms) .. " platforms!")
    
    -- Keep generating
    task.spawn(function()
        while self.active do
            task.wait(1)
            
            local furthestZ = -math.huge
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local z = player.Character.HumanoidRootPart.Position.Z
                    if z < furthestZ then
                        furthestZ = z
                    end
                end
            end
            
            -- Generate more if needed
            while self.lastPlatformPos.Z > furthestZ - 150 do
                self:generateNextPlatform()
            end
        end
    end)
end

function LevelGenerator:stop()
    self.active = false
    for _, platform in ipairs(self.platforms) do 
        if platform.destroy then platform:destroy() end 
    end
    self.platforms = {}
    if self.platformFolder then 
        self.platformFolder:Destroy() 
    end
end

return LevelGenerator
-- Level Generator for Endless Escape
-- Generates procedural platform sequences
-- Place in ServerScriptService

local Platform = require(game.ReplicatedStorage.Modules.PlatformModule)
local RunService = game:GetService("RunService")

local LevelGenerator = {}
LevelGenerator.__index = LevelGenerator

-- Difficulty curve configuration
local DIFFICULTY_SETTINGS = {
    {distance = 0,    gapRange = {8, 12},  hazardChance = 0.1, specialChance = 0.05},
    {distance = 100,  gapRange = {10, 16}, hazardChance = 0.2, specialChance = 0.1},
    {distance = 250,  gapRange = {12, 20}, hazardChance = 0.35, specialChance = 0.15},
    {distance = 500,  gapRange = {14, 24}, hazardChance = 0.5,  specialChance = 0.25},
    {distance = 1000, gapRange = {16, 30}, hazardChance = 0.6,  specialChance = 0.35},
}

function LevelGenerator.new()
    local self = setmetatable({}, LevelGenerator)
    self.platforms = {}
    self.currentDistance = 0
    self.lastPlatformPos = Vector3.new(0, 10, 0)
    self.playerProgress = {}
    self.active = false
    return self
end

function LevelGenerator:getDifficultySettings(distance)
    for i = #DIFFICULTY_SETTINGS, 1, -1 do
        if distance >= DIFFICULTY_SETTINGS[i].distance then
            return DIFFICULTY_SETTINGS[i]
        end
    end
    return DIFFICULTY_SETTINGS[1]
end

function LevelGenerator:selectPlatformType(settings)
    local rand = math.random()
    if rand < settings.specialChance then
        -- Special platform (moving, rotating, etc.)
        local specials = {Platform.Types.MOVING, Platform.Types.ROTATING, Platform.Types.BOUNCE}
        return specials[math.random(1, #specials)]
    elseif rand < settings.specialChance + settings.hazardChance then
        -- Hazard platform
        local hazards = {Platform.Types.KILL, Platform.Types.FADING, Platform.Types.CRUMBLING}
        return hazards[math.random(1, #hazards)]
    end
    return Platform.Types.STATIC
end

function LevelGenerator:generateNextPlatform()
    local settings = self:getDifficultySettings(self.currentDistance)
    
    -- Calculate gap
    local gap = math.random(settings.gapRange[1], settings.gapRange[2])
    local platformType = self:selectPlatformType(settings)
    
    -- Calculate position (alternate X slightly for variety)
    local xOffset = math.random(-5, 5)
    local newPos = self.lastPlatformPos + Vector3.new(xOffset, 0, -gap)
    
    -- Height variation for difficulty
    if self.currentDistance > 200 then
        newPos = newPos + Vector3.new(0, math.random(-2, 2), 0)
    end
    
    local platform, part = Platform.CreatePlatform(platformType, newPos, self.platformFolder)
    
    -- Add visual flair based on type
    self:decoratePlatform(part, platformType)
    
    table.insert(self.platforms, platform)
    self.lastPlatformPos = newPos
    self.currentDistance = self.currentDistance + gap
    
    return platform
end

function LevelGenerator:decoratePlatform(part, pType)
    if pType == Platform.Types.KILL then
        -- Add spikes
        for i = 1, 3 do
            local spike = Instance.new("Part")
            spike.Shape = Enum.PartType.Cone
            spike.Size = Vector3.new(1, 2, 1)
            spike.Color = Color3.fromRGB(80, 80, 80)
            spike.Material = Enum.Material.Metal
            spike.Anchored = true
            spike.CFrame = part.CFrame * CFrame.new(math.random(-4, 4), 1.5, math.random(-4, 4))
            spike.Parent = part.Parent
        end
    elseif pType == Platform.Types.FADING then
        -- Warning stripes
        local decal = Instance.new("Texture")
        decal.Texture = "rbxassetid://YOUR_WARNING_TEXTURE"
        decal.Face = Enum.NormalId.Top
        decal.Parent = part
    end
end

function LevelGenerator:cleanupBehindPlayer(playerZ)
    local cleanupDistance = 100
    for i = #self.platforms, 1, -1 do
        local platform = self.platforms[i]
        if platform.instance and platform.instance.Position.Z > playerZ + cleanupDistance then
            platform:destroy()
            table.remove(self.platforms, i)
        end
    end
end

function LevelGenerator:start(originPosition)
    self.active = true
    self.platformFolder = Instance.new("Folder")
    self.platformFolder.Name = "GeneratedLevel"
    self.platformFolder.Parent = workspace
    
    if originPosition then
        self.lastPlatformPos = originPosition
    end
    
    -- Generate initial platforms
    for i = 1, 15 do
        self:generateNextPlatform()
    end
    
    -- Keep ahead of furthest player
    task.spawn(function()
        while self.active do
            local furthestZ = math.huge
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    furthestZ = math.min(furthestZ, player.Character.HumanoidRootPart.Position.Z)
                end
            end
            
            -- Generate more if needed
            while self.lastPlatformPos.Z > furthestZ - 200 do
                self:generateNextPlatform()
            end
            
            -- Cleanup old platforms
            self:cleanupBehindPlayer(furthestZ)
            
            task.wait(0.5)
        end
    end)
end

function LevelGenerator:stop()
    self.active = false
    for _, platform in ipairs(self.platforms) do
        platform:destroy()
    end
    self.platforms = {}
    if self.platformFolder then
        self.platformFolder:Destroy()
    end
end

return LevelGenerator
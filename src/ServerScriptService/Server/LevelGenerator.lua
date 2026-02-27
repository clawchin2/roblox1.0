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
    -- Start RIGHT at edge of baseplate (baseplate is 50x50, so edge is at z = -25)
    -- First platform should be VERY close and easy to reach
    self.lastPlatformPos = Vector3.new(0, 10, -20) -- Only 5 studs from baseplate edge
    self.active = false
    print("[LevelGenerator] Instance created, starting position: " .. tostring(self.lastPlatformPos))
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

function LevelGenerator:generateNextPlatform(gapOverride)
    local settings = self:getDifficultySettings(self.currentDistance)
    
    -- Use small gap for first few platforms (tutorial section)
    local gap
    if gapOverride then
        gap = gapOverride
    elseif #self.platforms < 3 then
        -- First 3 platforms: very close together (easy tutorial)
        gap = 6 -- Small jump
    elseif #self.platforms < 6 then
        -- Next 3: medium
        gap = 8
    else
        -- Normal difficulty
        gap = math.random(settings.gapRange[1], settings.gapRange[2])
    end
    
    local platformType = self:selectPlatformType(settings)
    
    -- Keep first platforms relatively straight (small x offset)
    local xOffset
    if #self.platforms < 5 then
        xOffset = math.random(-2, 2) -- Almost straight line
    else
        xOffset = math.random(-5, 5)
    end
    
    local newPos = self.lastPlatformPos + Vector3.new(xOffset, 0, -gap)
    
    if self.currentDistance > 200 then
        newPos = newPos + Vector3.new(0, math.random(-2, 2), 0)
    end
    
    local success, platform, part = pcall(function()
        return Platform.CreatePlatform(platformType, newPos, self.platformFolder)
    end)
    
    if success and platform then
        table.insert(self.platforms, platform)
        self.lastPlatformPos = newPos
        self.currentDistance = self.currentDistance + gap
        print("[LevelGenerator] Created platform #" .. #self.platforms .. " at " .. tostring(newPos) .. " (gap: " .. gap .. ")")
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
    
    -- Create a STARTING BRIDGE from baseplate to first platform
    print("[LevelGenerator] Creating starting bridge...")
    local bridge = Instance.new("Part")
    bridge.Name = "StartBridge"
    bridge.Size = Vector3.new(8, 1, 6)
    bridge.Position = Vector3.new(0, 10, -17) -- Between baseplate (z=-25 edge) and first platform
    bridge.Anchored = true
    bridge.Color = Color3.fromRGB(100, 200, 100) -- Slightly lighter green
    bridge.Material = Enum.Material.SmoothPlastic
    bridge.Parent = self.platformFolder
    print("[LevelGenerator] Bridge created at " .. tostring(bridge.Position))
    
    -- Generate platforms with small gaps for tutorial
    print("[LevelGenerator] Generating initial platforms...")
    local count = 0
    for i = 1, 25 do
        local platform = self:generateNextPlatform()
        if platform then
            count = count + 1
        end
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
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    local z = player.Character.HumanoidRootPart.Position.Z
                    if z < furthestZ then
                        furthestZ = z
                    end
                end
            end
            
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
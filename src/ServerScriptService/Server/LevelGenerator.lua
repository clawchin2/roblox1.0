-- LevelGenerator - FIXED with guaranteed gaps
print("[LevelGenerator] Loading...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Platform = require(ReplicatedStorage.Modules.PlatformModule)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local LevelGenerator = {}
LevelGenerator.__index = LevelGenerator

function LevelGenerator.new()
    local self = setmetatable({}, LevelGenerator)
    self.platforms = {}
    self.lastPos = nil
    self.platformFolder = nil
    return self
end

function LevelGenerator:start()
    print("[LevelGenerator] Starting...")
    
    -- Clear existing
    if self.platformFolder then
        self.platformFolder:Destroy()
    end
    
    self.platformFolder = Instance.new("Folder")
    self.platformFolder.Name = "Platforms"
    self.platformFolder.Parent = workspace
    
    -- Start position
    self.lastPos = GameConfig.SPAWN_POSITION
    
    -- Clear platforms table
    self.platforms = {}
    
    -- Create starting platform (bigger)
    local start = Instance.new("Part")
    start.Name = "StartPlatform"
    start.Size = Vector3.new(50, 1, 50)
    start.Position = GameConfig.SPAWN_POSITION
    start.Anchored = true
    start.Color = Color3.fromRGB(100, 255, 100)
    start.Material = Enum.Material.SmoothPlastic
    start.Parent = self.platformFolder
    
    print("[LevelGenerator] Start platform at " .. tostring(self.lastPos))
    
    -- Generate 25 platforms with CLEAR gaps
    for i = 1, 25 do
        self:generatePlatform(i)
    end
    
    print("[LevelGenerator] Generated " .. #self.platforms .. " platforms")
    
    -- Continuous generation - faster
    task.spawn(function()
        while true do
            task.wait(0.3)
            if #self.platforms < 50 then
                self:generatePlatform(#self.platforms + 1)
            end
        end
    end)
end

function LevelGenerator:generatePlatform(index)
    -- FIXED: Explicit 8-stud gap forward
    local gap = 8
    local xOffset = math.random(-3, 3)
    
    -- Move position forward (negative Z is forward in Roblox)
    local newZ = self.lastPos.Z - gap
    local newX = self.lastPos.X + xOffset
    local newPos = Vector3.new(newX, self.lastPos.Y, newZ)
    
    self.lastPos = newPos
    
    -- Create platform
    local platform = Instance.new("Part")
    platform.Name = "Platform_" .. index
    platform.Size = Vector3.new(12, 1, 12)
    platform.Position = newPos
    platform.Anchored = true
    platform.CanCollide = true
    
    -- Color based on index
    if index <= 5 then
        platform.Color = Color3.fromRGB(150, 255, 150) -- Easy (greenish)
    elseif index <= 10 then
        platform.Color = Color3.fromRGB(150, 200, 255) -- Medium (blueish)
    else
        platform.Color = Color3.fromRGB(200, 200, 200) -- Normal (gray)
    end
    
    platform.Material = Enum.Material.SmoothPlastic
    platform.Parent = self.platformFolder
    
    table.insert(self.platforms, platform)
    
    -- Remove old platforms to keep count manageable
    if #self.platforms > 60 then
        local old = table.remove(self.platforms, 1)
        if old then old:Destroy() end
    end
end

return LevelGenerator
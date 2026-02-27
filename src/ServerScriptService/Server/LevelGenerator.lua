-- LevelGenerator - FIXED with proper gaps
print("[LevelGenerator] Loading...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Platform = require(ReplicatedStorage.Modules.PlatformModule)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local LevelGenerator = {}
LevelGenerator.__index = LevelGenerator

function LevelGenerator.new()
    local self = setmetatable({}, LevelGenerator)
    self.platforms = {}
    self.lastPos = GameConfig.SPAWN_POSITION
    self.platformFolder = nil
    self.initialized = false
    return self
end

function LevelGenerator:start()
    print("[LevelGenerator] Starting...")
    
    -- Clear any existing
    if self.platformFolder then
        self.platformFolder:Destroy()
    end
    
    self.platformFolder = Instance.new("Folder")
    self.platformFolder.Name = "Platforms"
    self.platformFolder.Parent = workspace
    
    -- Reset position
    self.lastPos = GameConfig.SPAWN_POSITION
    self.platforms = {}
    
    -- Bigger starting platform (40x40)
    local start = Platform.CreatePlatform("static", GameConfig.SPAWN_POSITION, self.platformFolder)
    start.Size = Vector3.new(40, 1, 40)
    start.Color = Color3.fromRGB(100, 255, 100)
    start.Name = "StartPlatform"
    
    -- Generate first 20 platforms with PROPER gaps
    for i = 1, 20 do
        self:generateNext(i)
    end
    
    self.initialized = true
    print("[LevelGenerator] Generated 20 platforms, ready!")
end

function LevelGenerator:generateNext(index)
    -- Fixed 8-stud gap (jumpable but not too easy)
    local gap = 8
    
    -- Small random x offset for variety
    local xOffset = math.random(-2, 2)
    
    -- Move forward (negative Z is forward)
    self.lastPos = self.lastPos + Vector3.new(xOffset, 0, -gap)
    
    local platform = Platform.CreatePlatform("static", self.lastPos, self.platformFolder)
    platform.Name = "Platform_" .. index
    
    -- First few platforms are easier (wider)
    if index <= 5 then
        platform.Size = Vector3.new(14, 1, 14)
        platform.Color = Color3.fromRGB(120, 200, 120)
    end
    
    table.insert(self.platforms, platform)
    
    -- Keep 50 platforms
    if #self.platforms > 50 then
        local old = table.remove(self.platforms, 1)
        if old then old:Destroy() end
    end
end

-- Reset everything for respawn
function LevelGenerator:reset()
    print("[LevelGenerator] Resetting...")
    
    -- Clear all platforms
    for _, p in ipairs(self.platforms) do
        if p then p:Destroy() end
    end
    self.platforms = {}
    
    -- Reset position to spawn
    self.lastPos = GameConfig.SPAWN_POSITION
    
    -- Regenerate
    for i = 1, 20 do
        self:generateNext(i)
    end
    
    print("[LevelGenerator] Reset complete")
end

return LevelGenerator
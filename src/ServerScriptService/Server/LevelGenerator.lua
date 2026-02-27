-- LevelGenerator - Fixed version with faster generation
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
    return self
end

function LevelGenerator:start()
    print("[LevelGenerator] Starting...")
    
    self.platformFolder = Instance.new("Folder")
    self.platformFolder.Name = "Platforms"
    self.platformFolder.Parent = workspace
    
    -- Bigger starting platform
    local start = Platform.CreatePlatform("static", GameConfig.SPAWN_POSITION, self.platformFolder)
    start.Size = Vector3.new(30, 1, 30)
    start.Color = Color3.fromRGB(100, 255, 100)
    
    -- Generate first 15 platforms immediately
    for i = 1, 15 do
        self:generateNext()
    end
    
    print("[LevelGenerator] Generated 15 platforms")
    
    -- Generate faster (every 0.5s instead of 2s)
    task.spawn(function()
        while true do
            task.wait(0.5)
            self:generateNext()
        end
    end)
end

function LevelGenerator:generateNext()
    local gap = math.random(6, 10) -- Smaller gaps
    local xOffset = math.random(-2, 2) -- Less side variation
    
    self.lastPos = self.lastPos + Vector3.new(xOffset, 0, -gap)
    
    local platform = Platform.CreatePlatform("static", self.lastPos, self.platformFolder)
    table.insert(self.platforms, platform)
    
    -- Keep more platforms (40 instead of 30)
    if #self.platforms > 40 then
        local old = table.remove(self.platforms, 1)
        if old then old:Destroy() end
    end
end

-- Reset for new player
function LevelGenerator:reset()
    -- Clear old platforms
    for _, p in ipairs(self.platforms) do
        if p then p:Destroy() end
    end
    self.platforms = {}
    
    -- Reset position
    self.lastPos = GameConfig.SPAWN_POSITION
    
    -- Regenerate
    for i = 1, 15 do
        self:generateNext()
    end
end

return LevelGenerator
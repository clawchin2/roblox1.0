-- LevelGenerator - Generates platforms ahead of player
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
    
    -- Create folder
    self.platformFolder = Instance.new("Folder")
    self.platformFolder.Name = "Platforms"
    self.platformFolder.Parent = workspace
    
    -- Create starting platform
    local start = Platform.CreatePlatform("static", GameConfig.SPAWN_POSITION, self.platformFolder)
    start.Size = Vector3.new(20, 1, 20)
    start.Color = Color3.fromRGB(100, 255, 100)
    
    -- Generate first 10 platforms
    for i = 1, 10 do
        self:generateNext()
    end
    
    print("[LevelGenerator] Generated 10 platforms")
    
    -- Keep generating
    task.spawn(function()
        while true do
            task.wait(2)
            self:generateNext()
        end
    end)
end

function LevelGenerator:generateNext()
    local gap = math.random(GameConfig.PLATFORM_GAP_MIN, GameConfig.PLATFORM_GAP_MAX)
    local xOffset = math.random(-3, 3)
    
    self.lastPos = self.lastPos + Vector3.new(xOffset, 0, -gap)
    
    local platform = Platform.CreatePlatform("static", self.lastPos, self.platformFolder)
    table.insert(self.platforms, platform)
    
    -- Cleanup old platforms
    if #self.platforms > 30 then
        local old = table.remove(self.platforms, 1)
        if old then old:Destroy() end
    end
end

return LevelGenerator
-- LevelGenerator
print("[LevelGenerator] Starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Platform = require(ReplicatedStorage.Modules.PlatformModule)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local platformsFolder = Instance.new("Folder")
platformsFolder.Name = "Platforms"
platformsFolder.Parent = workspace

local lastPos = GameConfig.SPAWN
local platforms = {}

-- Starting platform
local start = Platform.Create(GameConfig.SPAWN, platformsFolder)
start.Size = Vector3.new(30, 1, 30)
start.Color = Color3.fromRGB(100, 255, 100)

-- Generate platforms
for i = 1, 30 do
    local gap = 10
    local xOffset = math.random(-2, 2)
    
    -- Move forward
    lastPos = lastPos + Vector3.new(xOffset, 0, -gap)
    
    local p = Platform.Create(lastPos, platformsFolder)
    table.insert(platforms, p)
end

print("[LevelGenerator] Created " .. #platforms .. " platforms")

-- Keep generating more
while true do
    task.wait(0.5)
    
    local gap = 10
    local xOffset = math.random(-2, 2)
    lastPos = lastPos + Vector3.new(xOffset, 0, -gap)
    
    local p = Platform.Create(lastPos, platformsFolder)
    table.insert(platforms, p)
    
    -- Remove old
    if #platforms > 50 then
        local old = table.remove(platforms, 1)
        if old then old:Destroy() end
    end
end
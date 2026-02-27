-- LevelGenerator - FIXED: Don't delete spawn area platforms
print("[LevelGenerator] Starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Platform = require(ReplicatedStorage.Modules.PlatformModule)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local platformsFolder = Instance.new("Folder")
platformsFolder.Name = "Platforms"
platformsFolder.Parent = workspace

local lastPos = GameConfig.SPAWN
local platforms = {}
local spawnPlatform = nil

-- Starting platform (NEVER DELETE THIS)
spawnPlatform = Platform.Create(GameConfig.SPAWN, platformsFolder)
spawnPlatform.Size = Vector3.new(40, 1, 40)
spawnPlatform.Color = Color3.fromRGB(100, 255, 100)
spawnPlatform.Name = "SpawnPlatform"

-- Generate initial platforms
for i = 1, 40 do
    local gap = 10
    local xOffset = math.random(-3, 3)
    
    lastPos = lastPos + Vector3.new(xOffset, 0, -gap)
    
    local p = Platform.Create(lastPos, platformsFolder)
    p.Name = "Platform_" .. i
    
    -- Color code early platforms
    if i <= 10 then
        p.Color = Color3.fromRGB(150, 255, 150) -- Easy
    elseif i <= 20 then
        p.Color = Color3.fromRGB(150, 200, 255) -- Medium
    end
    
    table.insert(platforms, p)
end

print("[LevelGenerator] Created " .. #platforms .. " platforms")

-- Generate more platforms forever
while true do
    task.wait(0.3)
    
    -- Only keep platforms that are ahead of spawn (Z < 50)
    -- OR within 200 studs of the furthest player
    
    local furthestZ = 0
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local z = player.Character.HumanoidRootPart.Position.Z
            if z < furthestZ then
                furthestZ = z
            end
        end
    end
    
    -- Generate new platform
    local gap = 10
    local xOffset = math.random(-3, 3)
    lastPos = lastPos + Vector3.new(xOffset, 0, -gap)
    
    local p = Platform.Create(lastPos, platformsFolder)
    table.insert(platforms, p)
    
    -- Only remove platforms that are FAR behind (more than 100 studs behind furthest player)
    -- AND keep first 20 platforms for respawns
    while #platforms > 60 do
        local old = platforms[1]
        if old and old.Position.Z < furthestZ + 100 then
            -- Don't delete if it's a respawn platform (first 20)
            if old.Name ~= "SpawnPlatform" and tonumber(old.Name:match("%d+")) and tonumber(old.Name:match("%d+")) > 20 then
                old:Destroy()
                table.remove(platforms, 1)
            else
                break -- Stop deleting if we hit important platforms
            end
        else
            break
        end
    end
end
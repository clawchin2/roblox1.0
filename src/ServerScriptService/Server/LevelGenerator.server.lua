-- LevelGenerator - FIXED for respawn
print("[LevelGenerator] Starting...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Platform = require(ReplicatedStorage.Modules.PlatformModule)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local platformsFolder = Instance.new("Folder")
platformsFolder.Name = "Platforms"
platformsFolder.Parent = workspace

-- Keep track of all platforms
local platforms = {}

-- Create spawn platform (PERMANENT)
local spawn = Platform.Create(GameConfig.SPAWN, platformsFolder)
spawn.Size = Vector3.new(50, 1, 50)
spawn.Color = Color3.fromRGB(100, 255, 100)
spawn.Name = "Spawn"

-- Create path ahead
local function createPath()
    local pos = GameConfig.SPAWN
    
    for i = 1, 100 do -- Create 100 platforms
        pos = pos + Vector3.new(math.random(-3, 3), 0, -10)
        
        local p = Platform.Create(pos, platformsFolder)
        p.Name = "P" .. i
        
        -- Easy platforms first
        if i <= 20 then
            p.Color = Color3.fromRGB(150, 255, 150)
            p.Size = Vector3.new(14, 1, 14)
        elseif i <= 40 then
            p.Color = Color3.fromRGB(150, 200, 255)
        end
        
        table.insert(platforms, p)
    end
end

createPath()

print("[LevelGenerator] Created " .. #platforms .. " platforms")

-- Keep adding more as players go far
while true do
    task.wait(1)
    
    -- Find furthest player
    local furthest = 0
    for _, player in ipairs(game.Players:GetPlayers()) do
        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
            local z = -player.Character.HumanoidRootPart.Position.Z
            if z > furthest then
                furthest = z
            end
        end
    end
    
    -- Add platforms if needed (always keep 50 ahead of furthest player)
    while #platforms < (furthest / 10) + 50 do
        local last = platforms[#platforms]
        local pos = last.Position + Vector3.new(math.random(-3, 3), 0, -10)
        
        local p = Platform.Create(pos, platformsFolder)
        table.insert(platforms, p)
    end
end
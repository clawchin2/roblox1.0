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
    self.lastPlatformPos = GameConfig.SPAWN_POSITION
    self.active = false
    return self
end

function LevelGenerator:getDifficultySettings(distance)
    for i = #GameConfig.DIFFICULTY_STAGES, 1, -1 do
        if distance >= GameConfig.DIFFICULTY_STAGES[i].distance then
            return GameConfig.DIFFICULTY_STAGES[i]
        end
    end
    return GameConfig.DIFFICULTY_STAGES[1]
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

function LevelGenerator:spawnCoins(position, count)
    for i = 1, count do
        local coin = Instance.new("Part")
        coin.Name = "Coin"
        coin.Shape = Enum.PartType.Ball
        coin.Size = Vector3.new(2, 2, 2)
        coin.Color = Color3.fromRGB(255, 215, 0)
        coin.Material = Enum.Material.Neon
        coin.Anchored = true
        coin.CanCollide = false
        coin.Position = position + Vector3.new(math.random(-4, 4), 3 + i * 2, math.random(-4, 4))
        coin.Parent = self.platformFolder
        
        -- Spin animation
        task.spawn(function()
            while coin and coin.Parent do
                coin.CFrame = coin.CFrame * CFrame.Angles(0, math.rad(5), 0)
                task.wait(0.03)
            end
        end)
        
        -- Collection
        coin.Touched:Connect(function(hit)
            local player = game.Players:GetPlayerFromCharacter(hit:FindFirstAncestorOfClass("Model"))
            if player then
                -- Fire coin collected event
                local leaderstats = player:FindFirstChild("leaderstats")
                if leaderstats and leaderstats:FindFirstChild("Coins") then
                    leaderstats.Coins.Value = leaderstats.Coins.Value + 1
                end
                coin:Destroy()
            end
        end)
    end
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
    
    -- Spawn coins
    if settings.coinDensity and math.random() < 0.7 then
        self:spawnCoins(newPos, math.random(1, settings.coinDensity))
    end
    
    table.insert(self.platforms, platform)
    self.lastPlatformPos = newPos
    self.currentDistance = self.currentDistance + gap
    
    return platform
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

function LevelGenerator:start()
    self.active = true
    self.platformFolder = Instance.new("Folder")
    self.platformFolder.Name = "GeneratedLevel"
    self.platformFolder.Parent = workspace
    
    for i = 1, 15 do
        self:generateNextPlatform()
    end
    
    task.spawn(function()
        while self.active do
            local furthestZ = math.huge
            for _, player in ipairs(game.Players:GetPlayers()) do
                if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                    furthestZ = math.min(furthestZ, player.Character.HumanoidRootPart.Position.Z)
                end
            end
            
            while self.lastPlatformPos.Z > furthestZ - 200 do
                self:generateNextPlatform()
            end
            
            self:cleanupBehindPlayer(furthestZ)
            task.wait(0.5)
        end
    end)
end

function LevelGenerator:stop()
    self.active = false
    for _, platform in ipairs(self.platforms) do platform:destroy() end
    self.platforms = {}
    if self.platformFolder then self.platformFolder:Destroy() end
end

return LevelGenerator
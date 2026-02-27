-- Level Generator
-- Kid-friendly redesign with tutorial, visual guidance, and gradual difficulty

print("[LevelGenerator] Module loading...")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Platform = require(ReplicatedStorage.Modules.PlatformModule)
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

print("[LevelGenerator] Dependencies loaded")

local LevelGenerator = {}
LevelGenerator.__index = LevelGenerator

-- Tutorial configuration
local TUTORIAL_CONFIG = {
    -- First 5 platforms: super easy tutorial
    {
        gap = 4,           -- Tiny jump, impossible to miss
        xOffset = 0,       -- Straight line
        type = "static",
        message = "👋 Welcome! Jump to the next platform!",
        arrow = true,
        safetyNet = true,
    },
    {
        gap = 5,
        xOffset = 1,
        type = "static",
        message = "🌟 Great job! Keep going!",
        arrow = true,
        safetyNet = true,
    },
    {
        gap = 5,
        xOffset = -1,
        type = "static",
        message = "💪 You're doing amazing!",
        arrow = true,
        safetyNet = true,
    },
    {
        gap = 6,
        xOffset = 2,
        type = "static",
        message = "🏃 Jump a bit further now!",
        arrow = true,
        safetyNet = false,
    },
    {
        gap = 6,
        xOffset = -2,
        type = "static",
        message = "🎉 Tutorial complete! Have fun!",
        arrow = true,
        safetyNet = false,
    },
}

function LevelGenerator.new()
    print("[LevelGenerator] Creating new instance...")
    local self = setmetatable({}, LevelGenerator)
    self.platforms = {}
    self.checkpoints = {}
    self.currentDistance = 0
    self.platformIndex = 0
    -- Start at edge of baseplate - first platform very close
    self.lastPlatformPos = Vector3.new(0, 10, -18)
    self.active = false
    self.tutorialComplete = false
    print("[LevelGenerator] Instance created, starting position: " .. tostring(self.lastPlatformPos))
    return self
end

-- Create visual arrow pointing to next platform
function LevelGenerator:createArrow(parent, targetPos)
    local arrow = Instance.new("BillboardGui")
    arrow.Name = "DirectionArrow"
    arrow.Size = UDim2.new(0, 100, 0, 100)
    arrow.StudsOffset = Vector3.new(0, 3, 0)
    arrow.AlwaysOnTop = true
    arrow.Parent = parent
    
    local arrowImage = Instance.new("ImageLabel")
    arrowImage.Name = "Arrow"
    arrowImage.Size = UDim2.new(1, 0, 1, 0)
    arrowImage.BackgroundTransparency = 1
    arrowImage.Image = "rbxassetid://1386409285" -- Arrow decal
    arrowImage.ImageColor3 = Color3.fromRGB(255, 255, 0)
    arrowImage.ImageTransparency = 0.2
    arrowImage.Parent = arrow
    
    -- Point arrow toward target
    task.spawn(function()
        while arrow and arrow.Parent and targetPos do
            local currentPos = parent.Position
            local direction = (targetPos - currentPos).Unit
            local angle = math.atan2(direction.X, -direction.Z)
            arrowImage.Rotation = math.deg(angle) - 90
            task.wait(0.1)
        end
    end)
    
    return arrow
end

-- Create floating tutorial text
function LevelGenerator:createTutorialText(parent, text)
    local billboard = Instance.new("BillboardGui")
    billboard.Name = "TutorialText"
    billboard.Size = UDim2.new(0, 200, 0, 60)
    billboard.StudsOffset = Vector3.new(0, 4, 0)
    billboard.AlwaysOnTop = true
    billboard.Parent = parent
    
    local textLabel = Instance.new("TextLabel")
    textLabel.Name = "Text"
    textLabel.Size = UDim2.new(1, 0, 1, 0)
    textLabel.BackgroundTransparency = 0.3
    textLabel.BackgroundColor3 = Color3.fromRGB(0, 150, 255)
    textLabel.Text = text
    textLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    textLabel.TextScaled = true
    textLabel.Font = Enum.Font.GothamBold
    textLabel.TextStrokeTransparency = 0.5
    textLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    textLabel.Parent = billboard
    
    -- Animate the text
    task.spawn(function()
        while textLabel and textLabel.Parent do
            for i = 1, 10 do
                if textLabel and textLabel.Parent then
                    textLabel.Size = UDim2.new(1, i, 1, i)
                    task.wait(0.05)
                end
            end
            for i = 10, 1, -1 do
                if textLabel and textLabel.Parent then
                    textLabel.Size = UDim2.new(1, i, 1, i)
                    task.wait(0.05)
                end
            end
        end
    end)
    
    return billboard
end

-- Create checkpoint flag
function LevelGenerator:createCheckpoint(parent, checkpointNum)
    local flag = Instance.new("Model")
    flag.Name = "Checkpoint_" .. checkpointNum
    flag.Parent = parent
    
    -- Flag pole
    local pole = Instance.new("Part")
    pole.Name = "Pole"
    pole.Size = Vector3.new(0.5, 6, 0.5)
    pole.Position = parent.Position + Vector3.new(0, 3, 0)
    pole.Anchored = true
    pole.CanCollide = false
    pole.Color = Color3.fromRGB(150, 150, 150)
    pole.Material = Enum.Material.Metal
    pole.Parent = flag
    
    -- Flag cloth
    local cloth = Instance.new("Part")
    cloth.Name = "Flag"
    cloth.Size = Vector3.new(2, 1.5, 0.2)
    cloth.Position = parent.Position + Vector3.new(1.25, 4.5, 0)
    cloth.Anchored = true
    cloth.CanCollide = false
    cloth.Color = Color3.fromRGB(0, 200, 100)
    cloth.Material = Enum.Material.SmoothPlastic
    cloth.Parent = flag
    
    -- Checkpoint number
    local numberLabel = Instance.new("BillboardGui")
    numberLabel.Name = "CheckpointNumber"
    numberLabel.Size = UDim2.new(0, 50, 0, 50)
    numberLabel.StudsOffset = Vector3.new(0, 1.5, 0)
    numberLabel.AlwaysOnTop = true
    numberLabel.Parent = cloth
    
    local numText = Instance.new("TextLabel")
    numText.Size = UDim2.new(1, 0, 1, 0)
    numText.BackgroundTransparency = 1
    numText.Text = tostring(checkpointNum)
    numText.TextColor3 = Color3.fromRGB(255, 255, 255)
    numText.TextScaled = true
    numText.Font = Enum.Font.GothamBold
    numText.Parent = numberLabel
    
    table.insert(self.checkpoints, {
        number = checkpointNum,
        position = parent.Position,
        flag = flag
    })
    
    return flag
end

-- Spawn coins on a platform
function LevelGenerator:spawnCoins(platformPart, coinCount)
    if not platformPart or not platformPart.Parent then return end
    
    coinCount = coinCount or math.random(1, 3)
    local platformPos = platformPart.Position
    local platformSize = platformPart.Size
    
    for i = 1, coinCount do
        local coin = Instance.new("Part")
        coin.Name = "Coin"
        coin.Shape = Enum.PartType.Ball
        coin.Size = Vector3.new(2, 2, 2)
        
        -- Position: spread across platform X, at chest height (Y + 3)
        local xOffset = (math.random() - 0.5) * (platformSize.X - 4)
        local zOffset = (math.random() - 0.5) * (platformSize.Z - 4)
        coin.Position = platformPos + Vector3.new(xOffset, 3, zOffset)
        
        -- Visual properties
        coin.Color = Color3.fromRGB(255, 215, 0) -- Gold
        coin.Material = Enum.Material.Metal
        coin.Anchored = true
        coin.CanCollide = false
        coin.Transparency = 0.1
        
        -- Add point light for visibility
        local light = Instance.new("PointLight")
        light.Color = Color3.fromRGB(255, 215, 0)
        light.Brightness = 2
        light.Range = 5
        light.Parent = coin
        
        -- Set attributes for coin value
        coin:SetAttribute("CoinValue", 10)
        
        -- Parent to platform folder
        coin.Parent = self.platformFolder
        
        -- Spin animation
        task.spawn(function()
            while coin and coin.Parent do
                coin.CFrame = coin.CFrame * CFrame.Angles(0, math.rad(5), 0)
                task.wait(0.05)
            end
        end)
        
        print("[LevelGenerator] Spawned coin at " .. tostring(coin.Position))
    end
end

-- Create safety net (invisible floor below platform)
function LevelGenerator:createSafetyNet(position, size)
    local net = Instance.new("Part")
    net.Name = "SafetyNet"
    net.Size = Vector3.new(size.X * 2, 1, size.Z * 2)
    net.Position = position - Vector3.new(0, 8, 0) -- 8 studs below
    net.Anchored = true
    net.CanCollide = true
    net.Transparency = 1 -- Invisible
    net.Parent = self.platformFolder
    
    -- If player falls, teleport them back up
    net.Touched:Connect(function(hit)
        local char = hit:FindFirstAncestorOfClass("Model")
        if char and char:FindFirstChild("Humanoid") and char:FindFirstChild("HumanoidRootPart") then
            local hrp = char.HumanoidRootPart
            -- Find nearest checkpoint or spawn
            local checkpointPos = Vector3.new(0, 15, 0) -- Default spawn
            for _, cp in ipairs(self.checkpoints) do
                if cp.position.Z > hrp.Position.Z then
                    checkpointPos = cp.position + Vector3.new(0, 5, 0)
                    break
                end
            end
            hrp.CFrame = CFrame.new(checkpointPos)
        end
    end)
    
    return net
end

-- Create starting ramp from spawn to first platform
function LevelGenerator:createStartingRamp()
    print("[LevelGenerator] Creating starting ramp...")
    
    -- Main ramp
    local ramp = Instance.new("Part")
    ramp.Name = "StartRamp"
    ramp.Size = Vector3.new(12, 1, 10)
    ramp.Position = Vector3.new(0, 10, -13)
    ramp.Anchored = true
    ramp.Color = Color3.fromRGB(100, 255, 100)
    ramp.Material = Enum.Material.SmoothPlastic
    ramp.Parent = self.platformFolder
    
    -- Welcome sign
    local sign = Instance.new("BillboardGui")
    sign.Name = "WelcomeSign"
    sign.Size = UDim2.new(0, 300, 0, 100)
    sign.StudsOffset = Vector3.new(0, 4, 0)
    sign.AlwaysOnTop = true
    sign.Parent = ramp
    
    local signText = Instance.new("TextLabel")
    signText.Size = UDim2.new(1, 0, 1, 0)
    signText.BackgroundTransparency = 0.2
    signText.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
    signText.Text = "🏃 ENDLESS ESCAPE 🏃\nWalk forward to start!"
    signText.TextColor3 = Color3.fromRGB(255, 255, 255)
    signText.TextScaled = true
    signText.Font = Enum.Font.GothamBold
    signText.TextStrokeTransparency = 0.5
    signText.Parent = sign
    
    -- Create first checkpoint at spawn area
    self:createCheckpoint(ramp, 1)
    
    return ramp
end

function LevelGenerator:getDifficultySettings(distance)
    -- Kid-friendly difficulty curve
    local stages = {
        {distance = 0,    gapRange = {6, 8},   hazardChance = 0,   specialChance = 0,    coinDensity = 3},
        {distance = 100,  gapRange = {8, 12},  hazardChance = 0,   specialChance = 0.1,  coinDensity = 4},
        {distance = 250,  gapRange = {10, 15}, hazardChance = 0.1, specialChance = 0.15, coinDensity = 5},
        {distance = 500,  gapRange = {12, 18}, hazardChance = 0.2, specialChance = 0.2,  coinDensity = 6},
        {distance = 1000, gapRange = {14, 22}, hazardChance = 0.3, specialChance = 0.25, coinDensity = 7},
    }
    
    for i = #stages, 1, -1 do
        if distance >= stages[i].distance then
            return stages[i]
        end
    end
    return stages[1]
end

function LevelGenerator:selectPlatformType(settings, isTutorial)
    -- No hazards in tutorial
    if isTutorial then
        return Platform.Types.STATIC
    end
    
    local rand = math.random()
    if rand < settings.specialChance then
        -- Bounce is fun for kids, avoid moving/rotating early on
        local specials = {Platform.Types.BOUNCE, Platform.Types.STATIC}
        return specials[math.random(1, #specials)]
    elseif rand < settings.specialChance + settings.hazardChance then
        -- Introduce hazards gradually
        local hazards = {Platform.Types.FADING, Platform.Types.CRUMBLING}
        return hazards[math.random(1, #hazards)]
    end
    return Platform.Types.STATIC
end

function LevelGenerator:generateTutorialPlatform(index)
    local config = TUTORIAL_CONFIG[index]
    if not config then
        return nil
    end
    
    local xOffset = config.xOffset or 0
    -- Make path flow gently, not random zig-zag
    if index > 1 then
        local prevConfig = TUTORIAL_CONFIG[index - 1]
        -- Continue in same direction for smooth flow
        xOffset = prevConfig.xOffset + (math.random() > 0.5 and 1 or -1)
        xOffset = math.clamp(xOffset, -3, 3)
    end
    
    local newPos = self.lastPlatformPos + Vector3.new(xOffset, 0, -config.gap)
    
    -- Create platform
    local success, platform, part = pcall(function()
        return Platform.CreatePlatform(config.type, newPos, self.platformFolder)
    end)
    
    if success and platform and part then
        -- Add tutorial text
        if config.message then
            self:createTutorialText(part, config.message)
        end
        
        -- Add arrow pointing to next platform (if not last tutorial platform)
        if config.arrow and index < #TUTORIAL_CONFIG then
            local nextPos = newPos + Vector3.new(
                TUTORIAL_CONFIG[index + 1].xOffset or 0, 
                0, 
                -TUTORIAL_CONFIG[index + 1].gap
            )
            self:createArrow(part, nextPos)
        end
        
        -- Add safety net for early platforms
        if config.safetyNet then
            self:createSafetyNet(newPos, part.Size)
        end
        
        -- Make tutorial platforms visually distinct
        part.Color = Color3.fromRGB(100, 200, 255) -- Light blue for tutorial
        
        -- Spawn coins on tutorial platforms (fewer coins in tutorial)
        self:spawnCoins(part, 1)
        
        table.insert(self.platforms, platform)
        self.lastPlatformPos = newPos
        self.currentDistance = self.currentDistance + config.gap
        self.platformIndex = self.platformIndex + 1
        
        print("[LevelGenerator] Tutorial platform #" .. index .. " at " .. tostring(newPos))
        return platform
    else
        warn("[LevelGenerator] Failed to create tutorial platform: " .. tostring(platform))
        return nil
    end
end

function LevelGenerator:generateNextPlatform()
    self.platformIndex = self.platformIndex + 1
    local index = self.platformIndex
    
    -- Tutorial section (first 5 platforms)
    if index <= #TUTORIAL_CONFIG then
        return self:generateTutorialPlatform(index)
    end
    
    -- After tutorial
    if index == #TUTORIAL_CONFIG + 1 then
        self.tutorialComplete = true
        print("[LevelGenerator] Tutorial complete! Starting normal generation.")
        
        -- Create checkpoint after tutorial
        local checkpointPlatform = self.platforms[#self.platforms]
        if checkpointPlatform and checkpointPlatform.instance then
            self:createCheckpoint(checkpointPlatform.instance, 2)
        end
    end
    
    local settings = self:getDifficultySettings(self.currentDistance)
    
    -- Flow-based x-offset (smooth curves, not random)
    local xOffset
    if index <= 10 then
        -- Still easy, minimal side-to-side
        xOffset = math.random(-2, 2)
    elseif index <= 20 then
        -- Slightly more variation
        xOffset = math.random(-4, 4)
    else
        -- Normal variation but still flow-based
        xOffset = math.random(-6, 6)
    end
    
    -- Keep platforms from going too far from center
    local targetX = math.clamp(self.lastPlatformPos.X + xOffset, -15, 15)
    xOffset = targetX - self.lastPlatformPos.X
    
    local gap = math.random(settings.gapRange[1], settings.gapRange[2])
    local platformType = self:selectPlatformType(settings, false)
    
    local newPos = self.lastPlatformPos + Vector3.new(xOffset, 0, -gap)
    
    -- Occasional height variation after distance 200
    if self.currentDistance > 200 then
        newPos = newPos + Vector3.new(0, math.random(-1, 1), 0)
    end
    
    local success, platform, part = pcall(function()
        return Platform.CreatePlatform(platformType, newPos, self.platformFolder)
    end)
    
    if success and platform and part then
        -- Create checkpoint every 10 platforms
        if index % 10 == 0 then
            self:createCheckpoint(part, math.floor(index / 10) + 1)
        end
        
        -- Spawn coins on platform (more coins as difficulty increases)
        local settings = self:getDifficultySettings(self.currentDistance)
        local coinCount = math.random(1, math.min(settings.coinDensity, 5))
        self:spawnCoins(part, coinCount)
        
        table.insert(self.platforms, platform)
        self.lastPlatformPos = newPos
        self.currentDistance = self.currentDistance + gap
        
        print("[LevelGenerator] Platform #" .. index .. " at " .. tostring(newPos) .. " (gap: " .. gap .. ")")
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
    
    -- Create starting ramp
    self:createStartingRamp()
    
    -- Generate initial platforms (includes tutorial)
    print("[LevelGenerator] Generating initial platforms...")
    local count = 0
    for i = 1, 30 do
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
    self.checkpoints = {}
    if self.platformFolder then 
        self.platformFolder:Destroy() 
    end
    print("[LevelGenerator] Stopped")
end

print("[LevelGenerator] Module fully loaded and ready!")

return LevelGenerator

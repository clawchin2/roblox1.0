-- MilestoneManager.lua
-- Handles distance milestone celebrations with screen flash, popups, particles, and sound

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local SoundService = game:GetService("SoundService")
local Debris = game:GetService("Debris")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local MilestoneManager = {}
MilestoneManager.lastMilestone = 0
MilestoneManager.celebrating = false

-- Milestone configuration with escalating rewards
local MILESTONE_CONFIG = {
    [100] = {
        emoji = "🔥",
        title = "100M!",
        subtitle = "Keep going!",
        particleCount = 30,
        particleColor = Color3.fromRGB(255, 150, 0),
        flashColor = Color3.fromRGB(255, 200, 100),
        soundId = "rbxassetid://6780919178", -- Achievement sound
        duration = 2,
        scale = 1.0,
    },
    [250] = {
        emoji = "💎",
        title = "250M!",
        subtitle = "Amazing run!",
        particleCount = 50,
        particleColor = Color3.fromRGB(100, 200, 255),
        flashColor = Color3.fromRGB(150, 220, 255),
        soundId = "rbxassetid://6780919178",
        duration = 2.5,
        scale = 1.2,
    },
    [500] = {
        emoji = "👑",
        title = "500M!",
        subtitle = "You're a legend!",
        particleCount = 100,
        particleColor = Color3.fromRGB(255, 215, 0),
        flashColor = Color3.fromRGB(255, 240, 150),
        secondaryColor = Color3.fromRGB(255, 100, 200),
        soundId = "rbxassetid://6780919178",
        duration = 4,
        scale = 1.5,
        fireworks = true,
    },
    [750] = {
        emoji = "🌟",
        title = "750M!",
        subtitle = "Unstoppable!",
        particleCount = 75,
        particleColor = Color3.fromRGB(200, 100, 255),
        flashColor = Color3.fromRGB(220, 180, 255),
        soundId = "rbxassetid://6780919178",
        duration = 3,
        scale = 1.3,
    },
    [1000] = {
        emoji = "🏆",
        title = "1000M!",
        subtitle = "MASTER OF THE RUN!",
        particleCount = 150,
        particleColor = Color3.fromRGB(255, 215, 0),
        flashColor = Color3.fromRGB(255, 255, 200),
        secondaryColor = Color3.fromRGB(255, 50, 100),
        soundId = "rbxassetid://6780919178",
        duration = 5,
        scale = 1.8,
        fireworks = true,
    },
}

-- Create the milestone popup UI
function MilestoneManager.createPopup(config)
    local screenGui = Instance.new("ScreenGui")
    screenGui.Name = "MilestonePopup"
    screenGui.DisplayOrder = 100
    screenGui.Parent = playerGui
    
    -- Screen flash background
    local flash = Instance.new("Frame")
    flash.Name = "ScreenFlash"
    flash.Size = UDim2.new(1, 0, 1, 0)
    flash.BackgroundColor3 = config.flashColor
    flash.BackgroundTransparency = 0
    flash.BorderSizePixel = 0
    flash.Parent = screenGui
    
    -- Flash fade animation
    TweenService:Create(flash, TweenInfo.new(0.3, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        BackgroundTransparency = 1
    }):Play()
    
    -- Main popup container
    local popup = Instance.new("Frame")
    popup.Name = "Popup"
    popup.Size = UDim2.new(0, 400 * config.scale, 0, 200 * config.scale)
    popup.Position = UDim2.new(0.5, -200 * config.scale, 0.5, -100 * config.scale)
    popup.BackgroundTransparency = 1
    popup.Parent = screenGui
    
    -- Background glow
    local glow = Instance.new("ImageLabel")
    glow.Name = "Glow"
    glow.Size = UDim2.new(1.5, 0, 1.5, 0)
    glow.Position = UDim2.new(-0.25, 0, -0.25, 0)
    glow.BackgroundTransparency = 1
    glow.Image = "rbxassetid://4996891970" -- Glow decal
    glow.ImageColor3 = config.particleColor
    glow.ImageTransparency = 0.5
    glow.Parent = popup
    
    -- Scale animation for glow
    local glowTween = TweenService:Create(glow, TweenInfo.new(0.6, Enum.EasingStyle.Elastic, Enum.EasingDirection.Out), {
        Size = UDim2.new(2, 0, 2, 0),
        Position = UDim2.new(-0.5, 0, -0.5, 0),
        ImageTransparency = 0.8
    })
    glowTween:Play()
    
    -- Main emoji/icon
    local emojiLabel = Instance.new("TextLabel")
    emojiLabel.Name = "Emoji"
    emojiLabel.Size = UDim2.new(0, 100 * config.scale, 0, 100 * config.scale)
    emojiLabel.Position = UDim2.new(0.5, -50 * config.scale, 0, -20 * config.scale)
    emojiLabel.BackgroundTransparency = 1
    emojiLabel.Text = config.emoji
    emojiLabel.TextScaled = true
    emojiLabel.Font = Enum.Font.GothamBold
    emojiLabel.Parent = popup
    
    -- Title text
    local titleLabel = Instance.new("TextLabel")
    titleLabel.Name = "Title"
    titleLabel.Size = UDim2.new(1, 0, 0, 60 * config.scale)
    titleLabel.Position = UDim2.new(0, 0, 0, 70 * config.scale)
    titleLabel.BackgroundTransparency = 1
    titleLabel.Text = config.title
    titleLabel.TextColor3 = config.particleColor
    titleLabel.TextScaled = true
    titleLabel.Font = Enum.Font.GothamBlack
    titleLabel.TextStrokeTransparency = 0.5
    titleLabel.TextStrokeColor3 = Color3.fromRGB(0, 0, 0)
    titleLabel.Parent = popup
    
    -- Subtitle text
    local subtitleLabel = Instance.new("TextLabel")
    subtitleLabel.Name = "Subtitle"
    subtitleLabel.Size = UDim2.new(1, 0, 0, 40 * config.scale)
    subtitleLabel.Position = UDim2.new(0, 0, 0, 125 * config.scale)
    subtitleLabel.BackgroundTransparency = 1
    subtitleLabel.Text = config.subtitle
    subtitleLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    subtitleLabel.TextScaled = true
    subtitleLabel.Font = Enum.Font.GothamBold
    subtitleLabel.TextStrokeTransparency = 0.5
    subtitleLabel.Parent = popup
    
    -- Initial scale animation (pop in)
    popup.Size = UDim2.new(0, 0, 0, 0)
    local popInTween = TweenService:Create(popup, TweenInfo.new(0.4, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 400 * config.scale, 0, 200 * config.scale)
    })
    popInTween:Play()
    
    -- Pulse animation
    task.spawn(function()
        for i = 1, 3 do
            task.wait(0.3)
            if not popup.Parent then break end
            local pulse = TweenService:Create(popup, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 420 * config.scale, 0, 210 * config.scale)
    })
    pulse:Play()
    pulse.Completed:Wait()
    if not popup.Parent then break end
    local unpulse = TweenService:Create(popup, TweenInfo.new(0.2, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Size = UDim2.new(0, 400 * config.scale, 0, 200 * config.scale)
    })
    unpulse:Play()
        end
    end)
    
    -- Play sound
    MilestoneManager.playSound(config.soundId)
    
    -- Fade out and destroy
    task.delay(config.duration, function()
        if not screenGui.Parent then return end
        
        local fadeOut = TweenService:Create(popup, TweenInfo.new(0.5), {
            Position = UDim2.new(0.5, -200 * config.scale, 0, -150),
            BackgroundTransparency = 1
        })
        
        for _, child in ipairs(popup:GetDescendants()) do
            if child:IsA("TextLabel") then
                TweenService:Create(child, TweenInfo.new(0.3), {TextTransparency = 1}):Play()
            elseif child:IsA("ImageLabel") then
                TweenService:Create(child, TweenInfo.new(0.3), {ImageTransparency = 1}):Play()
            end
        end
        
        fadeOut:Play()
        fadeOut.Completed:Wait()
        screenGui:Destroy()
    end)
end

-- Play celebration sound
function MilestoneManager.playSound(soundId)
    local sound = Instance.new("Sound")
    sound.SoundId = soundId
    sound.Volume = 0.5
    sound.Parent = SoundService
    sound:Play()
    Debris:AddItem(sound, 3)
end

-- Create 3D particle burst at player position
function MilestoneManager.createParticleBurst(config, character)
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Create attachment for particles
    local attachment = Instance.new("Attachment")
    attachment.Position = Vector3.new(0, 0, 0)
    attachment.Parent = hrp
    
    -- Main particle emitter
    local particleEmitter = Instance.new("ParticleEmitter")
    particleEmitter.Color = ColorSequence.new(config.particleColor)
    particleEmitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 2),
        NumberSequenceKeypoint.new(0.5, 3),
        NumberSequenceKeypoint.new(1, 0)
    })
    particleEmitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.8, 0),
        NumberSequenceKeypoint.new(1, 1)
    })
    particleEmitter.Lifetime = NumberRange.new(1, 2)
    particleEmitter.Rate = 0
    particleEmitter.Speed = NumberRange.new(10, 25)
    particleEmitter.SpreadAngle = Vector2.new(180, 180)
    particleEmitter.Acceleration = Vector3.new(0, -20, 0)
    particleEmitter.RotSpeed = NumberRange.new(-180, 180)
    particleEmitter.LightEmission = 1
    particleEmitter.LightInfluence = 0
    particleEmitter.Texture = "rbxassetid://258128463" -- Sparkle texture
    particleEmitter.Parent = attachment
    
    -- Burst particles
    particleEmitter:Emit(config.particleCount)
    
    -- Secondary color if specified
    if config.secondaryColor then
        local secondaryEmitter = particleEmitter:Clone()
        secondaryEmitter.Color = ColorSequence.new(config.secondaryColor)
        secondaryEmitter.Parent = attachment
        secondaryEmitter:Emit(math.floor(config.particleCount * 0.5))
    end
    
    -- Cleanup
    task.delay(3, function()
        if attachment and attachment.Parent then
            attachment:Destroy()
        end
    end)
end

-- Create fireworks effect for major milestones
function MilestoneManager.createFireworks(config, character)
    if not config.fireworks then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local basePos = hrp.Position
    
    -- Launch multiple fireworks
    for i = 1, 5 do
        task.delay(i * 0.3, function()
            local offset = Vector3.new(
                math.random(-20, 20),
                math.random(10, 20),
                math.random(-20, 20)
            )
            MilestoneManager.launchFirework(basePos + offset, config.particleColor, config.secondaryColor)
        end)
    end
end

-- Launch a single firework
function MilestoneManager.launchFirework(position, color1, color2)
    -- Firework rocket
    local rocket = Instance.new("Part")
    rocket.Shape = Enum.PartType.Ball
    rocket.Size = Vector3.new(1, 1, 1)
    rocket.Position = position - Vector3.new(0, 10, 0)
    rocket.Color = color1
    rocket.Material = Enum.Material.Neon
    rocket.Anchored = true
    rocket.CanCollide = false
    rocket.Parent = workspace
    
    -- Trail
    local trail = Instance.new("Trail")
    trail.Color = ColorSequence.new(color1)
    trail.Lifetime = 0.5
    trail.WidthScale = NumberSequence.new(1)
    trail.Parent = rocket
    
    local attachment0 = Instance.new("Attachment")
    attachment0.Position = Vector3.new(0, 0.5, 0)
    attachment0.Parent = rocket
    
    local attachment1 = Instance.new("Attachment")
    attachment1.Position = Vector3.new(0, -0.5, 0)
    attachment1.Parent = rocket
    
    trail.Attachment0 = attachment0
    trail.Attachment1 = attachment1
    
    -- Launch animation
    local targetPos = position
    local tween = TweenService:Create(rocket, TweenInfo.new(0.8, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
        Position = targetPos
    })
    tween:Play()
    
    tween.Completed:Connect(function()
        -- Explosion
        rocket:Destroy()
        MilestoneManager.createExplosion(targetPos, color1, color2)
    end)
end

-- Create explosion particles
function MilestoneManager.createExplosion(position, color1, color2)
    local explosionPart = Instance.new("Part")
    explosionPart.Anchored = true
    explosionPart.CanCollide = false
    explosionPart.Transparency = 1
    explosionPart.Position = position
    explosionPart.Parent = workspace
    
    local attachment = Instance.new("Attachment")
    attachment.Parent = explosionPart
    
    local emitter = Instance.new("ParticleEmitter")
    emitter.Color = ColorSequence.new(color1)
    emitter.Size = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 1),
        NumberSequenceKeypoint.new(0.3, 4),
        NumberSequenceKeypoint.new(1, 0)
    })
    emitter.Transparency = NumberSequence.new({
        NumberSequenceKeypoint.new(0, 0),
        NumberSequenceKeypoint.new(0.5, 0.2),
        NumberSequenceKeypoint.new(1, 1)
    })
    emitter.Lifetime = NumberRange.new(0.5, 1.5)
    emitter.Rate = 0
    emitter.Speed = NumberRange.new(20, 40)
    emitter.SpreadAngle = Vector2.new(180, 180)
    emitter.Acceleration = Vector3.new(0, -30, 0)
    emitter.LightEmission = 1
    emitter.Texture = "rbxassetid://258128463"
    emitter.Parent = attachment
    
    emitter:Emit(50)
    
    -- Secondary color burst
    if color2 then
        local emitter2 = emitter:Clone()
        emitter2.Color = ColorSequence.new(color2)
        emitter2.Parent = attachment
        emitter2:Emit(30)
    end
    
    Debris:AddItem(explosionPart, 2)
end

-- Check for milestones and trigger celebrations
function MilestoneManager.checkMilestone(currentDistance, character)
    -- Find the highest milestone reached
    local highestMilestone = 0
    for milestone, _ in pairs(MILESTONE_CONFIG) do
        if currentDistance >= milestone and milestone > highestMilestone then
            highestMilestone = milestone
        end
    end
    
    -- Only celebrate if we've passed a new milestone
    if highestMilestone > MilestoneManager.lastMilestone then
        MilestoneManager.lastMilestone = highestMilestone
        
        local config = MILESTONE_CONFIG[highestMilestone]
        if config then
            print("[MilestoneManager] Celebrating milestone: " .. highestMilestone .. "m")
            MilestoneManager.celebrate(config, character)
        end
    end
end

-- Trigger full celebration
function MilestoneManager.celebrate(config, character)
    if MilestoneManager.celebrating then return end
    MilestoneManager.celebrating = true
    
    -- UI popup
    MilestoneManager.createPopup(config)
    
    -- Particle burst
    MilestoneManager.createParticleBurst(config, character)
    
    -- Fireworks for major milestones
    MilestoneManager.createFireworks(config, character)
    
    -- Reset celebrating flag after duration
    task.delay(config.duration, function()
        MilestoneManager.celebrating = false
    end)
end

-- Initialize milestone tracking
function MilestoneManager.init()
    print("[MilestoneManager] Initializing...")
    
    local character = player.Character or player.CharacterAdded:Wait()
    local hrp = character:WaitForChild("HumanoidRootPart")
    
    -- Wait for leaderstats
    local leaderstats = player:WaitForChild("leaderstats", 5)
    if not leaderstats then
        warn("[MilestoneManager] No leaderstats found")
        return
    end
    
    local scoreValue = leaderstats:WaitForChild("Score")
    
    -- Monitor distance changes
    local lastDistance = 0
    task.spawn(function()
        while character and character.Parent do
            task.wait(0.5)
            
            -- Get current distance from Score
            local currentDistance = scoreValue.Value
            
            -- Check for milestone
            if currentDistance > lastDistance then
                MilestoneManager.checkMilestone(currentDistance, character)
                lastDistance = currentDistance
            end
            
            -- Handle character respawn
            if not hrp or not hrp.Parent then
                character = player.Character
                if character then
                    hrp = character:WaitForChild("HumanoidRootPart", 2)
                end
            end
        end
    end)
    
    print("[MilestoneManager] Initialized and tracking milestones")
end

-- Reset milestones (e.g., on respawn)
function MilestoneManager.reset()
    MilestoneManager.lastMilestone = 0
    MilestoneManager.celebrating = false
    print("[MilestoneManager] Reset milestones")
end

return MilestoneManager

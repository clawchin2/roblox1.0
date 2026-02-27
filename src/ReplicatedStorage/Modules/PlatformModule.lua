-- Platform Module
-- Handles all platform types with collision and behavior logic

print("[PlatformModule] Loading...")

local Platform = {}
Platform.__index = Platform

Platform.Types = {
    STATIC = "static",
    MOVING = "moving",
    FADING = "fading",
    CRUMBLING = "crumbling",
    BOUNCE = "bounce",
    KILL = "kill",
    SLOW = "slow",
}

-- Debug visualization
Platform.DebugMode = false

local DEFAULT_CONFIG = {
    size = Vector3.new(12, 1, 12),
    material = Enum.Material.SmoothPlastic,
    color = Color3.fromRGB(120, 120, 120),
    fadeDelay = 1,
    moveSpeed = 5,
    moveDistance = 10,
    rotateSpeed = 1,
}

function Platform.new(config)
    local self = setmetatable({}, Platform)
    self.config = setmetatable(config or {}, {__index = DEFAULT_CONFIG})
    self.instance = nil
    self.connections = {}
    self.active = false
    return self
end

function Platform:create(parent)
    local part = Instance.new("Part")
    part.Name = "Platform_" .. (self.config.type or "base")
    part.Size = self.config.size
    part.Material = self.config.material
    part.Color = self.config.color
    part.Anchored = true
    
    -- ENSURE CanCollide is always true initially
    part.CanCollide = true
    part.CanQuery = true
    part.CanTouch = true
    
    -- Set collision group if needed
    part.CollisionGroup = "Default"
    
    -- Add debug visualization if enabled
    if Platform.DebugMode then
        local selectionBox = Instance.new("SelectionBox")
        selectionBox.Adornee = part
        selectionBox.Color3 = Color3.new(0, 1, 0)
        selectionBox.LineThickness = 0.05
        selectionBox.Parent = part
    end
    
    part.Parent = parent or workspace
    
    -- Setup specific platform type behaviors
    if self.config.type == Platform.Types.KILL then
        part.Color = Color3.fromRGB(255, 50, 50)
        part.Material = Enum.Material.Neon
        self:setupKillZone(part)
    elseif self.config.type == Platform.Types.BOUNCE then
        part.Color = Color3.fromRGB(50, 255, 100)
        part.Material = Enum.Material.ForceField
        part.CustomPhysicalProperties = PhysicalProperties.new(0, 0, 1.5, 0, 1)
        self:setupBounce(part)
    elseif self.config.type == Platform.Types.FADING then
        part.Color = Color3.fromRGB(255, 200, 100)
        self:setupFading(part)
    elseif self.config.type == Platform.Types.CRUMBLING then
        part.Color = Color3.fromRGB(139, 90, 43)
        part.Material = Enum.Material.Rock
        self:setupCrumbling(part)
    elseif self.config.type == Platform.Types.MOVING then
        self:setupMoving(part)
    elseif self.config.type == Platform.Types.ROTATING then
        self:setupRotating(part)
    elseif self.config.type == Platform.Types.STATIC then
        -- Static platforms - ensure they have debug visualization
        if Platform.DebugMode then
            local billboard = Instance.new("BillboardGui")
            billboard.Size = UDim2.new(0, 100, 0, 50)
            billboard.StudsOffset = Vector3.new(0, 2, 0)
            billboard.AlwaysOnTop = true
            
            local label = Instance.new("TextLabel")
            label.Size = UDim2.new(1, 0, 1, 0)
            label.BackgroundTransparency = 1
            label.TextColor3 = Color3.new(1, 1, 1)
            label.Text = "STATIC"
            label.TextSize = 14
            label.Parent = billboard
            
            billboard.Parent = part
        end
    end
    
    -- Final collision check
    if not part.CanCollide then
        warn("[PlatformModule] WARNING: Platform created with CanCollide=false, fixing...")
        part.CanCollide = true
    end
    
    self.instance = part
    self.active = true
    return part
end

function Platform:setupKillZone(part)
    local connection = part.Touched:Connect(function(hit)
        local char = hit:FindFirstAncestorOfClass("Model")
        if char and char:FindFirstChild("Humanoid") then
            char.Humanoid.Health = 0
        end
    end)
    table.insert(self.connections, connection)
end

function Platform:setupBounce(part)
    -- Already set CustomPhysicalProperties in create()
    -- Add bounce visual effect
    local attachment = Instance.new("Attachment")
    attachment.Position = Vector3.new(0, 0.5, 0)
    attachment.Parent = part
    
    if Platform.DebugMode then
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(0, 1, 0)
        label.Text = "BOUNCE"
        label.TextSize = 14
        label.Parent = billboard
        
        billboard.Parent = part
    end
end

function Platform:setupFading(part)
    local debounce = {}
    local connection = part.Touched:Connect(function(hit)
        local player = game.Players:GetPlayerFromCharacter(hit:FindFirstAncestorOfClass("Model"))
        if player and not debounce[player.UserId] then
            debounce[player.UserId] = true
            task.delay(self.config.fadeDelay, function()
                if part and part.Parent then
                    -- Fade out
                    for i = 1, 10 do
                        if part then 
                            part.Transparency = i / 10 
                            task.wait(0.05) 
                        end
                    end
                    -- Disable collision
                    part.CanCollide = false
                    -- Wait then restore
                    task.wait(2)
                    if part then 
                        part.CanCollide = true 
                        part.Transparency = 0 
                    end
                end
                debounce[player.UserId] = nil
            end)
        end
    end)
    table.insert(self.connections, connection)
end

function Platform:setupCrumbling(part)
    local connection = part.Touched:Connect(function(hit)
        local char = hit:FindFirstAncestorOfClass("Model")
        if char and char:FindFirstChild("Humanoid") then
            task.wait(0.3)
            if part and part.Parent then
                part.CanCollide = false
                -- Shake effect
                for i = 1, 5 do
                    if part then 
                        part.CFrame = part.CFrame * CFrame.new(math.random(-5,5)/100, 0, math.random(-5,5)/100) 
                        task.wait(0.05) 
                    end
                end
                -- Fall
                if part then 
                    part.Anchored = false 
                    part.CanCollide = true 
                end
            end
        end
    end)
    table.insert(self.connections, connection)
end

function Platform:setupMoving(part)
    local startPos = part.Position
    local direction = self.config.moveDirection or Vector3.new(1, 0, 0)
    local distance = self.config.moveDistance
    local speed = self.config.moveSpeed
    
    task.spawn(function()
        while part and part.Parent and self.active do
            local elapsed = 0
            local duration = distance / speed
            while elapsed < duration and part and part.Parent do
                elapsed = elapsed + task.wait()
                local alpha = elapsed / duration
                part.Position = startPos + direction * distance * math.sin(alpha * math.pi)
            end
        end
    end)
    
    if Platform.DebugMode then
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(0, 1, 1)
        label.Text = "MOVING"
        label.TextSize = 14
        label.Parent = billboard
        
        billboard.Parent = part
    end
end

function Platform:setupRotating(part)
    task.spawn(function()
        while part and part.Parent and self.active do
            part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(self.config.rotateSpeed), 0)
            task.wait(0.03)
        end
    end)
    
    if Platform.DebugMode then
        local billboard = Instance.new("BillboardGui")
        billboard.Size = UDim2.new(0, 100, 0, 50)
        billboard.StudsOffset = Vector3.new(0, 3, 0)
        billboard.AlwaysOnTop = true
        
        local label = Instance.new("TextLabel")
        label.Size = UDim2.new(1, 0, 1, 0)
        label.BackgroundTransparency = 1
        label.TextColor3 = Color3.new(1, 0, 1)
        label.Text = "ROTATING"
        label.TextSize = 14
        label.Parent = billboard
        
        billboard.Parent = part
    end
end

function Platform:destroy()
    self.active = false
    for _, conn in ipairs(self.connections) do 
        if conn then conn:Disconnect() end
    end
    self.connections = {}
    if self.instance then 
        self.instance:Destroy() 
        self.instance = nil 
    end
end

-- Static factory function
function Platform.CreatePlatform(platformType, position, parent)
    local config = {type = platformType}
    local platform = Platform.new(config)
    local part = platform:create(parent)
    if position then 
        part.Position = position 
    end
    return platform, part
end

-- Debug mode setter
function Platform.SetDebugMode(enabled)
    Platform.DebugMode = enabled
    print("[PlatformModule] Debug mode: " .. tostring(enabled))
end

print("[PlatformModule] Loaded successfully!")

return Platform

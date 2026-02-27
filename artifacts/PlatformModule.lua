-- Platform Module for Endless Escape
-- Modular platform system with hazard integration
-- Place in ReplicatedStorage.Modules

local Platform = {}
Platform.__index = Platform

-- Configuration
local DEFAULT_CONFIG = {
    size = Vector3.new(12, 1, 12),
    material = Enum.Material.SmoothPlastic,
    color = Color3.fromRGB(120, 120, 120),
    destroyOnTouch = false,
    moveSpeed = 0,
    moveDistance = 0,
    fadeAfter = 0, -- seconds before fading (0 = never)
    rotateSpeed = 0,
}

-- Platform Types
Platform.Types = {
    STATIC = "static",
    MOVING = "moving",
    FADING = "fading",
    ROTATING = "rotating",
    CRUMBLING = "crumbling",
    BOUNCE = "bounce",
    KILL = "kill", -- instant death
    SLOW = "slow", -- slows player
}

function Platform.new(config)
    local self = setmetatable({}, Platform)
    self.config = setmetmetatable(config or {}, {__index = DEFAULT_CONFIG})
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
    part.CanCollide = true
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    part.Parent = parent or workspace
    
    -- Add collision handler for special platforms
    if self.config.type == Platform.Types.KILL then
        part.Color = Color3.fromRGB(255, 50, 50)
        part.Material = Enum.Material.Neon
        self:setupKillZone(part)
    elseif self.config.type == Platform.Types.BOUNCE then
        part.Color = Color3.fromRGB(50, 255, 100)
        part.Material = Enum.Material.ForceField
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
    part.CustomPhysicalProperties = PhysicalProperties.new(
        0, -- density
        0, -- friction
        1.5, -- elasticity (bouncy!)
        0, -- friction weight
        1 -- elasticity weight
    )
end

function Platform:setupFading(part)
    local debounce = {}
    local connection = part.Touched:Connect(function(hit)
        local player = game.Players:GetPlayerFromCharacter(hit:FindFirstAncestorOfClass("Model"))
        if player and not debounce[player.UserId] then
            debounce[player.UserId] = true
            task.delay(self.config.fadeAfter or 1, function()
                if part and part.Parent then
                    -- Fade out
                    for i = 1, 10 do
                        if part then
                            part.Transparency = i / 10
                            task.wait(0.05)
                        end
                    end
                    part.CanCollide = false
                    task.wait(2)
                    -- Respawn
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
            task.wait(0.3) -- brief delay before crumbling
            if part and part.Parent then
                part.CanCollide = false
                part.Transparency = 0.5
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
    local distance = self.config.moveDistance or 10
    local speed = self.config.moveSpeed or 5
    
    task.spawn(function()
        while part and part.Parent and self.active do
            local elapsed = 0
            local duration = distance / speed
            -- Move forward
            while elapsed < duration and part and part.Parent do
                elapsed = elapsed + task.wait()
                local alpha = elapsed / duration
                part.Position = startPos + direction * distance * math.sin(alpha * math.pi)
            end
        end
    end)
end

function Platform:setupRotating(part)
    local speed = self.config.rotateSpeed or 1
    task.spawn(function()
        while part and part.Parent and self.active do
            part.CFrame = part.CFrame * CFrame.Angles(0, math.rad(speed), 0)
            task.wait(0.03)
        end
    end)
end

function Platform:destroy()
    self.active = false
    for _, conn in ipairs(self.connections) do
        conn:Disconnect()
    end
    self.connections = {}
    if self.instance then
        self.instance:Destroy()
        self.instance = nil
    end
end

-- Factory function for quick creation
function Platform.CreatePlatform(platformType, position, parent)
    local config = {type = platformType}
    local platform = Platform.new(config)
    local part = platform:create(parent)
    if position then
        part.Position = position
    end
    return platform, part
end

return Platform
--!strict
-- BackgroundManager.lua
-- Dynamic environment system that changes based on player distance
-- Location: ServerScriptService/Server/BackgroundManager.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Lighting = game:GetService("Lighting")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")
local Workspace = game:GetService("Workspace")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local BACKGROUND_CONFIG = {
	-- Update interval
	UPDATE_INTERVAL = 2, -- seconds
	
	-- Distance zones (in studs/meters)
	ZONES = {
		{
			name = "Floating Islands",
			minDist = 0,
			maxDist = 100,
			skyColor = Color3.fromRGB(135, 206, 235), -- Bright blue
			fogColor = Color3.fromRGB(200, 230, 255),
			fogStart = 100,
			fogEnd = 500,
			ambient = Color3.fromRGB(180, 180, 200),
			outdoorAmbient = Color3.fromRGB(150, 180, 220),
			colorShiftBottom = Color3.fromRGB(100, 150, 200),
			colorShiftTop = Color3.fromRGB(255, 255, 255),
			brightness = 2,
			cloudColor = Color3.fromRGB(255, 255, 255),
			particleType = "fireflies", -- fireflies, snow, ash, none
			particleColor = Color3.fromRGB(255, 255, 150),
			decorationTheme = "islands", -- islands, desert, ice, volcanic
		},
		{
			name = "Sunset Canyon",
			minDist = 100,
			maxDist = 300,
			skyColor = Color3.fromRGB(255, 150, 100), -- Orange/pink sunset
			fogColor = Color3.fromRGB(255, 180, 150),
			fogStart = 80,
			fogEnd = 400,
			ambient = Color3.fromRGB(200, 150, 120),
			outdoorAmbient = Color3.fromRGB(220, 160, 120),
			colorShiftBottom = Color3.fromRGB(200, 100, 80),
			colorShiftTop = Color3.fromRGB(255, 200, 150),
			brightness = 1.5,
			cloudColor = Color3.fromRGB(255, 200, 180),
			particleType = "none",
			particleColor = Color3.fromRGB(255, 200, 100),
			decorationTheme = "desert",
		},
		{
			name = "Aurora Peaks",
			minDist = 300,
			maxDist = 500,
			skyColor = Color3.fromRGB(20, 30, 80), -- Dark night
			fogColor = Color3.fromRGB(30, 40, 100),
			fogStart = 60,
			fogEnd = 350,
			ambient = Color3.fromRGB(50, 60, 120),
			outdoorAmbient = Color3.fromRGB(40, 50, 100),
			colorShiftBottom = Color3.fromRGB(100, 50, 150), -- Purple aurora
			colorShiftTop = Color3.fromRGB(50, 200, 255), -- Cyan aurora
			brightness = 0.8,
			cloudColor = Color3.fromRGB(100, 100, 150),
			particleType = "snow",
			particleColor = Color3.fromRGB(255, 255, 255),
			decorationTheme = "ice",
		},
		{
			name = "Volcanic Depths",
			minDist = 500,
			maxDist = 999999, -- Infinite
			skyColor = Color3.fromRGB(30, 20, 20), -- Dark stormy
			fogColor = Color3.fromRGB(50, 30, 30),
			fogStart = 40,
			fogEnd = 300,
			ambient = Color3.fromRGB(80, 40, 30),
			outdoorAmbient = Color3.fromRGB(60, 30, 20),
			colorShiftBottom = Color3.fromRGB(150, 50, 30), -- Lava glow
			colorShiftTop = Color3.fromRGB(80, 30, 20),
			brightness = 0.6,
			cloudColor = Color3.fromRGB(60, 50, 50),
			particleType = "ash",
			particleColor = Color3.fromRGB(100, 80, 70),
			decorationTheme = "volcanic",
		},
	},
	
	-- Milestone archways
	MILESTONES = {
		{ distance = 100, name = "Canyon Entrance", passed = false },
		{ distance = 250, name = "Frost Gate", passed = false },
		{ distance = 500, name = "Doom Portal", passed = false },
	},
	
	-- Lightning settings for volcanic zone
	LIGHTNING_CHANCE = 0.1, -- 10% chance per check in volcanic zone
	LIGHTNING_DURATION = 0.2,
}

-- ============================================================================
-- STATE
-- ============================================================================

local BackgroundManager = {}

local playerZones = {} -- Map of player UserId to current zone index
local playerMilestones = {} -- Map of player UserId to passed milestones
local activeDecorations = {} -- Map of player UserId to decoration folder
local activeParticles = {} -- Map of player UserId to particle emitter
local backgroundFolder = nil
local updateConnection = nil

-- ============================================================================
-- REMOTE EVENTS
-- ============================================================================

local BackgroundEvents = nil
local ZoneChangeEvent = nil
local MilestoneReachedEvent = nil

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Get zone for a distance
local function getZoneForDistance(distance: number): (number, any)
	for i, zone in ipairs(BACKGROUND_CONFIG.ZONES) do
		if distance >= zone.minDist and distance < zone.maxDist then
			return i, zone
		end
	end
	return 1, BACKGROUND_CONFIG.ZONES[1] -- Default to first zone
end

-- Smoothly tween lighting properties
local function tweenLighting(property: string, targetValue: any, duration: number)
	local current = Lighting[property]
	if current == nil then return end
	
	local tweenInfo = TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut)
	local tween = TweenService:Create(Lighting, tweenInfo, { [property] = targetValue })
	tween:Play()
end

-- ============================================================================
-- PARTICLE SYSTEMS
-- ============================================================================

local function createParticleSystem(player: Player, particleType: string, color: Color3)
	-- Clean up existing
	if activeParticles[player.UserId] then
		activeParticles[player.UserId]:Destroy()
		activeParticles[player.UserId] = nil
	end
	
	if particleType == "none" then return end
	
	local character = player.Character
	if not character then return end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	-- Create particle attachment
	local attachment = Instance.new("Attachment")
	attachment.Name = "BackgroundParticles"
	attachment.Position = Vector3.new(0, 10, -50) -- In front of player
	attachment.Parent = hrp
	
	local emitter = Instance.new("ParticleEmitter")
	emitter.Color = ColorSequence.new(color)
	emitter.Size = NumberSequence.new(0.5, 1.5)
	emitter.Transparency = NumberSequence.new(0.3, 1)
	emitter.Lifetime = NumberRange.new(3, 6)
	emitter.Rate = particleType == "snow" and 50 or 20
	emitter.Speed = NumberRange.new(2, 5)
	emitter.SpreadAngle = Vector2.new(30, 30)
	emitter.Rotation = NumberRange.new(0, 360)
	emitter.RotSpeed = NumberRange.new(-30, 30)
	emitter.Acceleration = particleType == "ash" and Vector3.new(0, 1, 0) or Vector3.new(0, -2, 0)
	emitter.Parent = attachment
	
	-- Configure based on type
	if particleType == "fireflies" then
		emitter.Texture = "rbxassetid://258128463" -- Sparkle
		emitter.Size = NumberSequence.new(0.3, 0.8)
		emitter.Brightness = 2
		emitter.Rate = 15
		emitter.Speed = NumberRange.new(1, 3)		emitter.Acceleration = Vector3.new(0, 0, 0)
	elseif particleType == "snow" then
		emitter.Texture = "rbxassetid://258128463" -- Snowflake-ish
		emitter.Size = NumberSequence.new(0.5, 1)
		emitter.Rate = 80
		emitter.Speed = NumberRange.new(5, 10)
		emitter.Acceleration = Vector3.new(0, -8, 0)
	elseif particleType == "ash" then
		emitter.Texture = "rbxassetid://288795586" -- Smoke
		emitter.Size = NumberSequence.new(1, 3)
		emitter.Rate = 40
		emitter.Color = ColorSequence.new(Color3.fromRGB(80, 70, 60), Color3.fromRGB(40, 35, 30))
		emitter.Speed = NumberRange.new(3, 8)
		emitter.Acceleration = Vector3.new(0, 2, 0) -- Rise up
	end
	
	activeParticles[player.UserId] = attachment
end

-- Update particle position to follow player
local function updateParticlePosition(player: Player)
	local attachment = activeParticles[player.UserId]
	if not attachment then return end
	
	local character = player.Character
	if not character then return end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	-- Update attachment position relative to player
	attachment.WorldPosition = hrp.Position + Vector3.new(0, 15, -30)
end

-- ============================================================================
-- DECORATION SYSTEM
-- ============================================================================

local function clearDecorations(player: Player)
	if activeDecorations[player.UserId] then
		activeDecorations[player.UserId]:Destroy()
		activeDecorations[player.UserId] = nil
	end
end

local function createFloatingIsland(position: Vector3, size: Vector3): Model
	local model = Instance.new("Model")
	
	-- Main island base
	local base = Instance.new("Part")
	base.Name = "IslandBase"
	base.Shape = Enum.PartType.Ball
	base.Size = size
	base.Position = position
	base.Anchored = true
	base.CanCollide = false
	base.Material = Enum.Material.Grass
	base.Color = Color3.fromRGB(100, 180, 100)
	base.Parent = model
	
	-- Grass top
	local grass = Instance.new("Part")
	grass.Name = "GrassTop"
	grass.Shape = Enum.PartType.Cylinder
	grass.Size = Vector3.new(size.X * 0.8, size.Y * 0.3, size.Z * 0.8)
	grass.CFrame = CFrame.new(position + Vector3.new(0, size.Y * 0.3, 0)) * CFrame.Angles(0, 0, math.rad(90))
	grass.Anchored = true
	grass.CanCollide = false
	grass.Material = Enum.Material.Grass
	grass.Color = Color3.fromRGB(120, 200, 80)
	grass.Parent = model
	
	-- Tree (simple)
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	trunk.Size = Vector3.new(2, 8, 2)
	trunk.Position = position + Vector3.new(0, size.Y * 0.5 + 4, 0)
	trunk.Anchored = true
	trunk.CanCollide = false
	trunk.Material = Enum.Material.Wood
	trunk.Color = Color3.fromRGB(139, 90, 43)
	trunk.Parent = model
	
	local leaves = Instance.new("Part")
	leaves.Name = "Leaves"
	leaves.Shape = Enum.PartType.Ball
	leaves.Size = Vector3.new(10, 10, 10)
	leaves.Position = position + Vector3.new(0, size.Y * 0.5 + 10, 0)
	leaves.Anchored = true
	leaves.CanCollide = false
	leaves.Material = Enum.Material.LeafyGrass
	leaves.Color = Color3.fromRGB(50, 150, 50)
	leaves.Parent = model
	
	return model
end

local function createRockFormation(position: Vector3, size: Vector3): Model
	local model = Instance.new("Model")
	
	local rock = Instance.new("Part")
	rock.Name = "Rock"
	rock.Shape = Enum.PartType.Block
	rock.Size = size
	rock.Position = position
	rock.Anchored = true
	rock.CanCollide = false
	rock.Material = Enum.Material.Rock
	rock.Color = Color3.fromRGB(160, 130, 100)
	rock.Parent = model
	
	-- Add some smaller rocks
	for i = 1, 3 do
		local smallRock = Instance.new("Part")
		smallRock.Shape = Enum.PartType.Ball
		smallRock.Size = Vector3.new(size.X * 0.3, size.Y * 0.3, size.Z * 0.3)
		smallRock.Position = position + Vector3.new(
			math.random(-20, 20),
			math.random(-10, 10),
			math.random(-20, 20)
		)
		smallRock.Anchored = true
		smallRock.CanCollide = false
		smallRock.Material = Enum.Material.Rock
		smallRock.Color = Color3.fromRGB(150, 120, 90)
		smallRock.Parent = model
	end
	
	return model
end

local function createIceFormation(position: Vector3, size: Vector3): Model
	local model = Instance.new("Model")
	
	local ice = Instance.new("Part")	ice.Name = "Ice"
	ice.Shape = Enum.PartType.Block
	ice.Size = size
	ice.Position = position
	ice.Anchored = true
	ice.CanCollide = false
	ice.Material = Enum.Material.Ice
	ice.Color = Color3.fromRGB(200, 230, 255)
	ice.Transparency = 0.3
	ice.Parent = model
	
	-- Crystal spikes
	for i = 1, 5 do
		local spike = Instance.new("Part")
		spike.Shape = Enum.PartType.Block
		spike.Size = Vector3.new(2, math.random(10, 25), 2)
		spike.CFrame = CFrame.new(position + Vector3.new(
			math.random(-15, 15),
			0,
			math.random(-15, 15)
		)) * CFrame.Angles(math.rad(math.random(-15, 15)), 0, math.rad(math.random(-15, 15)))
		spike.Anchored = true
		spike.CanCollide = false
		spike.Material = Enum.Material.Neon
		spike.Color = Color3.fromRGB(150, 220, 255)
		spike.Parent = model
	end
	
	return model
end

local function createVolcanicFormation(position: Vector3, size: Vector3): Model
	local model = Instance.new("Model")
	
	local volcano = Instance.new("Part")
	volcano.Name = "VolcanoBase"
	volcano.Shape = Enum.PartType.Ball
	volcano.Size = size
	volcano.Position = position
	volcano.Anchored = true
	volcano.CanCollide = false
	volcano.Material = Enum.Material.Rock
	volcano.Color = Color3.fromRGB(60, 40, 35)
	volcano.Parent = model
	
	-- Lava cracks (glowing parts)
	for i = 1, 4 do
		local lava = Instance.new("Part")
		lava.Shape = Enum.PartType.Block
		lava.Size = Vector3.new(size.X * 0.2, 1, size.Z * 0.2)
		lava.Position = position + Vector3.new(
			math.random(-size.X/3, size.X/3),
			size.Y/2,
			math.random(-size.Z/3, size.Z/3)
		)
		lava.Anchored = true
		lava.CanCollide = false
		lava.Material = Enum.Material.Neon
		lava.Color = Color3.fromRGB(255, 80, 30)
		lava.Parent = model
	end
	
	return model
end

local function spawnDecorations(player: Player, theme: string, playerPos: Vector3)
	clearDecorations(player)
	
	local folder = Instance.new("Folder")
	folder.Name = player.Name .. "_Decorations"
	folder.Parent = backgroundFolder
	activeDecorations[player.UserId] = folder
	
	-- Spawn decorations ahead of player
	for i = 1, 8 do
		local distance = 50 + (i * 40) -- 50m to 370m ahead
		local offsetX = math.random(-80, 80)
		local offsetY = math.random(-20, 40)
		local position = playerPos + Vector3.new(offsetX, offsetY, -distance)
		
		local decoration = nil
		local size = Vector3.new(
			math.random(15, 40),
			math.random(10, 30),
			math.random(15, 40)
		)
		
		if theme == "islands" then
			decoration = createFloatingIsland(position, size)
		elseif theme == "desert" then
			decoration = createRockFormation(position, size)
		elseif theme == "ice" then
			decoration = createIceFormation(position, size)
		elseif theme == "volcanic" then
			decoration = createVolcanicFormation(position, size)
		end
		
		if decoration then
			decoration.Parent = folder
			
			-- Add slow floating animation
			local floatOffset = math.random() * math.pi * 2
			task.spawn(function()
				while decoration and decoration.Parent do
					local time = tick()
					local newY = position.Y + math.sin(time + floatOffset) * 3
					local primaryPart = decoration:FindFirstChildOfClass("Part")
					if primaryPart then
						local delta = newY - primaryPart.Position.Y
						decoration:TranslateBy(Vector3.new(0, delta, 0))
					end
					task.wait(0.1)
				end
			end)
		end
	end
end

-- ============================================================================
-- MILESTONE SYSTEM
-- ============================================================================

local function createMilestoneArch(position: Vector3, name: string): Model
	local model = Instance.new("Model")
	model.Name = name .. "_Arch"
	
	-- Left pillar
	local leftPillar = Instance.new("Part")
	leftPillar.Name = "LeftPillar"
	leftPillar.Size = Vector3.new(8, 40, 8)
	leftPillar.Position = position + Vector3.new(-25, 20, 0)
	leftPillar.Anchored = true
	leftPillar.Material = Enum.Material.Stone
	leftPillar.Color = Color3.fromRGB(120, 120, 130)
	leftPillar.Parent = model
	
	-- Right pillar
	local rightPillar = Instance.new("Part")
	rightPillar.Name = "RightPillar"
	rightPillar.Size = Vector3.new(8, 40, 8)
	rightPillar.Position = position + Vector3.new(25, 20, 0)
	rightPillar.Anchored = true
	rightPillar.Material = Enum.Material.Stone
	rightPillar.Color = Color3.fromRGB(120, 120, 130)
	rightPillar.Parent = model
	
	-- Top arch
	local arch = Instance.new("Part")
	arch.Name = "Arch"
	arch.Size = Vector3.new(58, 8, 8)
	arch.Position = position + Vector3.new(0, 40, 0)
	arch.Anchored = true
	arch.Material = Enum.Material.Stone
	arch.Color = Color3.fromRGB(100, 100, 110)
	arch.Parent = model
	
	-- Glowing runes
	for i = 1, 5 do
		local rune = Instance.new("Part")
		rune.Name = "Rune_" .. i
		rune.Size = Vector3.new(4, 4, 2)
		rune.Position = position + Vector3.new(-20 + (i * 10), 30, 4)
		rune.Anchored = true
		rune.Material = Enum.Material.Neon
		rune.Color = Color3.fromRGB(100, 200, 255)
		rune.Parent = model
		
		-- Animate glow
		task.spawn(function()
			while rune and rune.Parent do
				for brightness = 0.5, 1, 0.05 do
					if not rune or not rune.Parent then break end
					rune.Transparency = 1 - brightness
					task.wait(0.05)
				end
				for brightness = 1, 0.5, -0.05 do
					if not rune or not rune.Parent then break end
					rune.Transparency = 1 - brightness
					task.wait(0.05)
				end
			end
		end)
	end
	
	return model
end

local function checkMilestones(player: Player, distance: number)
	if not playerMilestones[player.UserId] then
		playerMilestones[player.UserId] = {}
	end
	
	for _, milestone in ipairs(BACKGROUND_CONFIG.MILESTONES) do
		if distance >= milestone.distance and not playerMilestones[player.UserId][milestone.distance] then
			playerMilestones[player.UserId][milestone.distance] = true
			
			-- Create archway
			local character = player.Character
			if character then
				local hrp = character:FindFirstChild("HumanoidRootPart")
				if hrp then
					local arch = createMilestoneArch(
						hrp.Position + Vector3.new(0, 0, -milestone.distance + distance),
						milestone.name
					)
					arch.Parent = backgroundFolder
					
					-- Fire event to client
					MilestoneReachedEvent:FireClient(player, milestone.name, milestone.distance)
					
					print(string.format("[BackgroundManager] %s reached milestone: %s at %dm", 
						player.Name, milestone.name, milestone.distance))
				end
			end
		end
	end
end

-- ============================================================================
-- LIGHTNING EFFECT (Volcanic zone)
-- ============================================================================

local function triggerLightning()
	-- Flash the lighting
	local originalBrightness = Lighting.Brightness
	local originalAmbient = Lighting.Ambient
	
	Lighting.Brightness = 5
	Lighting.Ambient = Color3.fromRGB(255, 200, 150)
	
	task.wait(BACKGROUND_CONFIG.LIGHTNING_DURATION)
	
	Lighting.Brightness = originalBrightness
	Lighting.Ambient = originalAmbient
end

-- ============================================================================
-- ZONE TRANSITION
-- ============================================================================

local function transitionToZone(player: Player, zoneIndex: number, zone: any)
	local currentZone = playerZones[player.UserId]
	if currentZone == zoneIndex then return end -- Already in this zone
	
	playerZones[player.UserId] = zoneIndex
	
	print(string.format("[BackgroundManager] %s entered zone: %s", player.Name, zone.name))
	
	-- Tween lighting properties
	tweenLighting("Ambient", zone.ambient, 3)
	tweenLighting("OutdoorAmbient", zone.outdoorAmbient, 3)
	tweenLighting("ColorShift_Bottom", zone.colorShiftBottom, 3)
	tweenLighting("ColorShift_Top", zone.colorShiftTop, 3)
	tweenLighting("Brightness", zone.brightness, 3)
	tweenLighting("FogColor", zone.fogColor, 3)
	
	-- Update fog settings
	Lighting.FogStart = zone.fogStart
	Lighting.FogEnd = zone.fogEnd
	Lighting.FogEnabled = true
	
	-- Update particle system
	createParticleSystem(player, zone.particleType, zone.particleColor)
	
	-- Notify client
	ZoneChangeEvent:FireClient(player, zone.name, zone.minDist, zone.maxDist)
end

-- ============================================================================
-- MAIN UPDATE LOOP
-- ============================================================================

local function updatePlayerBackground(player: Player)
	local character = player.Character
	if not character then return end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local position = hrp.Position
	local distance = math.abs(position.Z) -- Distance from start
	
	-- Get current zone
	local zoneIndex, zone = getZoneForDistance(distance)
	
	-- Transition to zone
	transitionToZone(player, zoneIndex, zone)
	
	-- Update particle position
	updateParticlePosition(player)
	
	-- Check milestones
	checkMilestones(player, distance)
	
	-- Random lightning in volcanic zone
	if zone.decorationTheme == "volcanic" and math.random() < BACKGROUND_CONFIG.LIGHTNING_CHANCE then
		triggerLightning()
	end
	
	-- Respawn decorations periodically (every ~100 studs)
	if math.floor(distance / 100) > math.floor((playerZones[player.UserId .. "_lastDist"] or 0) / 100) then
		spawnDecorations(player, zone.decorationTheme, position)
	end
	playerZones[player.UserId .. "_lastDist"] = distance
end

local function startUpdateLoop()
	if updateConnection then return end
	
	task.spawn(function()
		while true do
			task.wait(BACKGROUND_CONFIG.UPDATE_INTERVAL)
			
			for _, player in ipairs(Players:GetPlayers()) do
				local success, err = pcall(function()
					updatePlayerBackground(player)
				end)
				if not success then
					warn("[BackgroundManager] Error updating background for " .. player.Name .. ": " .. tostring(err))
				end
			end
		end
	end)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function BackgroundManager:Init()
	print("[BackgroundManager] Initializing...")
	
	-- Create remote events
	BackgroundEvents = Instance.new("Folder")
	BackgroundEvents.Name = "BackgroundEvents"
	BackgroundEvents.Parent = ReplicatedStorage
	
	ZoneChangeEvent = Instance.new("RemoteEvent")
	ZoneChangeEvent.Name = "ZoneChange"
	ZoneChangeEvent.Parent = BackgroundEvents
	
	MilestoneReachedEvent = Instance.new("RemoteEvent")
	MilestoneReachedEvent.Name = "MilestoneReached"
	MilestoneReachedEvent.Parent = BackgroundEvents
	
	-- Create background folder in workspace
	backgroundFolder = Instance.new("Folder")
	backgroundFolder.Name = "BackgroundDecorations"
	backgroundFolder.Parent = Workspace
	
	-- Set initial lighting
	Lighting.Ambient = BACKGROUND_CONFIG.ZONES[1].ambient
	Lighting.OutdoorAmbient = BACKGROUND_CONFIG.ZONES[1].outdoorAmbient
	Lighting.FogColor = BACKGROUND_CONFIG.ZONES[1].fogColor
	Lighting.FogStart = BACKGROUND_CONFIG.ZONES[1].fogStart
	Lighting.FogEnd = BACKGROUND_CONFIG.ZONES[1].fogEnd
	Lighting.FogEnabled = true
	
	-- Start update loop
	startUpdateLoop()
	
	print("[BackgroundManager] Ready!")
end

function BackgroundManager:SetupPlayer(player: Player)
	playerZones[player.UserId] = nil
	playerMilestones[player.UserId] = {}
	
	-- Initial decoration spawn
	task.wait(2) -- Wait for character to load
	local character = player.Character
	if character then
		local hrp = character:FindFirstChild("HumanoidRootPart")
		if hrp then
			spawnDecorations(player, "islands", hrp.Position)
		end
	end
end

function BackgroundManager:CleanupPlayer(player: Player)
	clearDecorations(player)
	
	if activeParticles[player.UserId] then
		activeParticles[player.UserId]:Destroy()
		activeParticles[player.UserId] = nil
	end
	
	playerZones[player.UserId] = nil
	playerMilestones[player.UserId] = nil
end

return BackgroundManager

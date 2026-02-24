--!strict
-- ObstacleManager.lua
-- Server-side procedural infinite obstacle course generation
-- Location: ServerScriptService/Modules/ObstacleManager.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)

local ObstacleManager = {}

-- ============================================================================
-- TYPES
-- ============================================================================

export type SegmentType = "SpinningBlade" | "Crusher" | "LavaGap" | "FallingBlock" | "MovingWall" | "LaserBeam" | "SwingingAxe" | "SpikePlatform"

type SegmentData = {
	id: string,
	segmentType: SegmentType,
	startPosition: Vector3,
	endPosition: Vector3,
	length: number,
	parts: {BasePart},
	coins: {BasePart},
	killParts: {BasePart},
	cleanupFns: {() -> ()},
	checkpoint: BasePart?,
}

type PlayerRunData = {
	player: Player,
	currentDistance: number,
	lastCheckpointDist: number,
	lastCheckpointPos: Vector3,
	spawnedUpTo: number,
	activeSegmentIds: {string},
	seed: number,
}

-- ============================================================================
-- STATE
-- ============================================================================

local segments: {[string]: SegmentData} = {}
local playerRuns: {[number]: PlayerRunData} = {}
local partPool: {BasePart} = {}
local nextId = 0

-- Constants
local SPAWN_AHEAD = 300        -- Spawn segments this far ahead of player
local DESPAWN_BEHIND = 100     -- Remove segments this far behind player
local CHECKPOINT_INTERVAL = 200
local PLATFORM_WIDTH = 20

-- Segment configs: length, base difficulty, min distance to unlock
local SEGMENT_CONFIGS: {[SegmentType]: {length: number, diff: number, minDist: number, combo: boolean}} = {
	SpinningBlade  = { length = 40, diff = 3, minDist = 0,   combo = true },
	Crusher        = { length = 30, diff = 4, minDist = 100, combo = true },
	LavaGap        = { length = 35, diff = 2, minDist = 0,   combo = false },
	FallingBlock   = { length = 45, diff = 5, minDist = 200, combo = true },
	MovingWall     = { length = 50, diff = 6, minDist = 300, combo = true },
	LaserBeam      = { length = 40, diff = 7, minDist = 500, combo = true },
	SwingingAxe    = { length = 35, diff = 5, minDist = 400, combo = true },
	SpikePlatform  = { length = 30, diff = 4, minDist = 150, combo = true },
}

local ALL_TYPES: {SegmentType} = {
	"SpinningBlade", "Crusher", "LavaGap", "FallingBlock",
	"MovingWall", "LaserBeam", "SwingingAxe", "SpikePlatform",
}

-- ============================================================================
-- PART POOLING
-- ============================================================================

local function getPart(): BasePart
	if #partPool > 0 then
		local p = table.remove(partPool) :: BasePart
		p.Parent = workspace
		return p
	end
	local p = Instance.new("Part")
	p.Anchored = true
	p.CanCollide = true
	p.Material = Enum.Material.SmoothPlastic
	return p
end

local function recyclePart(p: BasePart)
	if #partPool >= 100 then
		p:Destroy()
		return
	end
	p.Parent = nil
	p:ClearAllChildren()
	p.Size = Vector3.new(1, 1, 1)
	p.Position = Vector3.new(0, -500, 0)
	p.Color = Color3.new(1, 1, 1)
	p.Transparency = 0
	p.CanCollide = true
	p.CanTouch = true
	table.insert(partPool, p)
end

-- ============================================================================
-- UTILITY
-- ============================================================================

local function genId(): string
	nextId += 1
	return "seg_" .. tostring(nextId)
end

local function coinColor(t: string): Color3
	if t == "Bronze" then return Color3.fromRGB(205, 127, 50)
	elseif t == "Silver" then return Color3.fromRGB(192, 192, 192)
	else return Color3.fromRGB(255, 215, 0) end
end

local function randomCoinType(): (string, number)
	local w = Config.Coins.SpawnWeights
	local total = w.Bronze + w.Silver + w.Gold
	local roll = math.random(1, total)
	if roll <= w.Bronze then return "Bronze", Config.Coins.Values.Bronze
	elseif roll <= w.Bronze + w.Silver then return "Silver", Config.Coins.Values.Silver
	else return "Gold", Config.Coins.Values.Gold end
end

-- Get available segment types for a given distance
local function getAvailableTypes(distance: number): {SegmentType}
	local available = {}
	for _, st in ipairs(ALL_TYPES) do
		if distance >= SEGMENT_CONFIGS[st].minDist then
			table.insert(available, st)
		end
	end
	return available
end

-- Difficulty multiplier based on distance
local function getDifficultyMult(distance: number): number
	if distance < 500 then return 1
	elseif distance < 1000 then return 1.5
	elseif distance < 2000 then return 2
	elseif distance < 5000 then return 3
	else return 4 end
end

-- ============================================================================
-- SEGMENT BUILDING HELPERS
-- ============================================================================

local function makeBase(startPos: Vector3, length: number): BasePart
	local base = getPart()
	base.Name = "SegmentBase"
	base.Size = Vector3.new(PLATFORM_WIDTH, 2, length)
	base.Position = startPos + Vector3.new(0, -1, length / 2)
	base.Color = Color3.fromRGB(80, 80, 80)
	base.Material = Enum.Material.Concrete
	base.Parent = workspace
	return base
end

local function makeKillPart(name: string, size: Vector3, pos: Vector3, color: Color3?): BasePart
	local p = getPart()
	p.Name = name
	p.Size = size
	p.Position = pos
	p.Color = color or Color3.fromRGB(255, 0, 0)
	p.Material = Enum.Material.Neon
	p:SetAttribute("KillPart", true)
	p.Parent = workspace
	return p
end

local function spawnCoins(seg: SegmentData, density: number)
	local count = math.floor(seg.length / 10 * density)
	local startZ = seg.startPosition.Z
	local step = seg.length / (count + 1)
	for i = 1, count do
		local z = startZ + step * i
		local ctype, cval = randomCoinType()
		local coin = getPart()
		coin.Name = "Coin_" .. ctype
		coin.Shape = Enum.PartType.Ball
		coin.Size = Vector3.new(2, 2, 2)
		coin.Position = Vector3.new(seg.startPosition.X + (math.random() - 0.5) * 12, 4, z)
		coin.Color = coinColor(ctype)
		coin.Material = Enum.Material.Metal
		coin.CanCollide = false
		coin:SetAttribute("CoinValue", cval)
		coin:SetAttribute("CoinType", ctype)
		coin.Parent = workspace
		table.insert(seg.coins, coin)
	end
end

local function makeCheckpoint(seg: SegmentData, pos: Vector3)
	local cp = getPart()
	cp.Name = "Checkpoint"
	cp.Size = Vector3.new(PLATFORM_WIDTH, 8, 1)
	cp.Position = pos + Vector3.new(0, 4, 0)
	cp.Color = Color3.fromRGB(0, 255, 100)
	cp.Material = Enum.Material.Neon
	cp.Transparency = 0.5
	cp.CanCollide = false
	cp:SetAttribute("Checkpoint", true)
	cp.Parent = workspace
	seg.checkpoint = cp
	table.insert(seg.parts, cp)
end

-- ============================================================================
-- SEGMENT GENERATORS (one per hazard type)
-- ============================================================================

local generators: {[SegmentType]: (Vector3, number) -> SegmentData} = {}

local function newSeg(stype: SegmentType, startPos: Vector3): SegmentData
	local cfg = SEGMENT_CONFIGS[stype]
	return {
		id = genId(),
		segmentType = stype,
		startPosition = startPos,
		endPosition = startPos + Vector3.new(0, 0, cfg.length),
		length = cfg.length,
		parts = {},
		coins = {},
		killParts = {},
		cleanupFns = {},
		checkpoint = nil,
	}
end

-- Helper: connect a Heartbeat animation, return cleanup function
local function animate(fn: (dt: number) -> boolean): () -> ()
	local conn: RBXScriptConnection
	conn = RunService.Heartbeat:Connect(function(dt)
		if fn(dt) then conn:Disconnect() end
	end)
	return function() conn:Disconnect() end
end

generators.SpinningBlade = function(startPos, diff)
	local seg = newSeg("SpinningBlade", startPos)
	table.insert(seg.parts, makeBase(startPos, seg.length))

	local center = startPos + Vector3.new(0, 4, seg.length / 2)
	local blade = makeKillPart("Blade", Vector3.new(14, 1, 2), center)
	table.insert(seg.killParts, blade)

	local speed = 2 + diff * 0.3
	local angle = 0
	table.insert(seg.cleanupFns, animate(function(dt)
		if not blade.Parent then return true end
		angle += dt * speed
		blade.CFrame = CFrame.new(center) * CFrame.Angles(0, angle, 0)
		return false
	end))

	spawnCoins(seg, 0.8)
	return seg
end

generators.Crusher = function(startPos, diff)
	local seg = newSeg("Crusher", startPos)
	table.insert(seg.parts, makeBase(startPos, seg.length))

	local positions = {
		startPos + Vector3.new(-5, 0, seg.length * 0.3),
		startPos + Vector3.new(5, 0, seg.length * 0.7),
	}
	for _, pos in ipairs(positions) do
		local crusher = makeKillPart("Crusher", Vector3.new(6, 3, 6), pos + Vector3.new(0, 18, 0))
		table.insert(seg.killParts, crusher)

		local speed = 4 + diff * 0.5
		local t = math.random() * 10
		table.insert(seg.cleanupFns, animate(function(dt)
			if not crusher.Parent then return true end
			t += dt * speed
			crusher.Position = Vector3.new(pos.X, 3 + 15 * (0.5 + 0.5 * math.sin(t)), pos.Z)
			return false
		end))
	end

	spawnCoins(seg, 0.7)
	return seg
end

generators.LavaGap = function(startPos, diff)
	local seg = newSeg("LavaGap", startPos)
	local gapSize = 12 + diff * 0.5
	local platLen = (seg.length - gapSize) / 2

	local p1 = getPart()
	p1.Name = "Platform1"
	p1.Size = Vector3.new(PLATFORM_WIDTH, 2, platLen)
	p1.Position = startPos + Vector3.new(0, -1, platLen / 2)
	p1.Color = Color3.fromRGB(80, 80, 80)
	p1.Material = Enum.Material.Concrete
	p1.Parent = workspace
	table.insert(seg.parts, p1)

	local p2 = getPart()
	p2.Name = "Platform2"
	p2.Size = Vector3.new(PLATFORM_WIDTH, 2, platLen)
	p2.Position = startPos + Vector3.new(0, -1, platLen + gapSize + platLen / 2)
	p2.Color = Color3.fromRGB(80, 80, 80)
	p2.Material = Enum.Material.Concrete
	p2.Parent = workspace
	table.insert(seg.parts, p2)

	local lava = makeKillPart("Lava", Vector3.new(PLATFORM_WIDTH, 1, gapSize + 2),
		startPos + Vector3.new(0, -2, seg.length / 2), Color3.fromRGB(255, 80, 0))
	table.insert(seg.killParts, lava)

	spawnCoins(seg, 0.6)
	return seg
end

generators.FallingBlock = function(startPos, diff)
	local seg = newSeg("FallingBlock", startPos)
	table.insert(seg.parts, makeBase(startPos, seg.length))

	local numBlocks = 2 + math.floor(diff / 3)
	for i = 1, numBlocks do
		local z = startPos.Z + seg.length * i / (numBlocks + 1)
		local x = startPos.X + (math.random() - 0.5) * 10
		local dropY = 30
		local block = makeKillPart("FallingBlock", Vector3.new(8, 8, 8),
			Vector3.new(x, dropY, z), Color3.fromRGB(100, 100, 100))
		block.Material = Enum.Material.Rock
		table.insert(seg.killParts, block)

		-- Warning indicator on ground
		local warn = getPart()
		warn.Name = "Warning"
		warn.Size = Vector3.new(8, 0.5, 8)
		warn.Position = Vector3.new(x, 0.1, z)
		warn.Color = Color3.fromRGB(255, 255, 0)
		warn.Material = Enum.Material.Neon
		warn.Transparency = 0.5
		warn.CanCollide = false
		warn.Parent = workspace
		table.insert(seg.parts, warn)

		local state = "wait"
		local timer = math.random() * 2
		local resetDelay = math.max(1.5, 3 - diff * 0.1)

		table.insert(seg.cleanupFns, animate(function(dt)
			if not block.Parent then return true end
			if state == "wait" then
				timer -= dt
				if timer <= 0 then
					state = "fall"
					warn.Color = Color3.fromRGB(255, 0, 0)
				end
			elseif state == "fall" then
				block.Position -= Vector3.new(0, (15 + diff * 2) * dt, 0)
				if block.Position.Y <= 2 then
					state = "reset"
					timer = resetDelay
					warn.Color = Color3.fromRGB(255, 255, 0)
				end
			elseif state == "reset" then
				timer -= dt
				if timer <= 0 then
					state = "wait"
					timer = 2 + math.random() * 2
					block.Position = Vector3.new(x, dropY, z)
				end
			end
			return false
		end))
	end

	spawnCoins(seg, 0.7)
	return seg
end

generators.MovingWall = function(startPos, diff)
	local seg = newSeg("MovingWall", startPos)
	table.insert(seg.parts, makeBase(startPos, seg.length))

	local numWalls = 1 + math.floor(diff / 4)
	for i = 1, numWalls do
		local z = startPos.Z + seg.length * (i - 0.5) / numWalls
		local xRange = math.max(4, 14 - diff * 0.5)
		local speed = 3 + diff * 0.5
		local wall = makeKillPart("Wall", Vector3.new(2, 12, seg.length / numWalls - 5),
			Vector3.new(startPos.X, 6, z), Color3.fromRGB(150, 50, 50))
		table.insert(seg.killParts, wall)

		local t = math.random() * 10
		table.insert(seg.cleanupFns, animate(function(dt)
			if not wall.Parent then return true end
			t += dt * speed
			wall.Position = Vector3.new(startPos.X + math.sin(t) * xRange, 6, z)
			return false
		end))
	end

	spawnCoins(seg, 0.6)
	return seg
end

generators.LaserBeam = function(startPos, diff)
	local seg = newSeg("LaserBeam", startPos)
	table.insert(seg.parts, makeBase(startPos, seg.length))

	local numLasers = 2 + math.floor(diff / 2)
	for i = 1, numLasers do
		local z = startPos.Z + seg.length * i / (numLasers + 1)
		local isHoriz = (i % 2 == 1)
		local laserSize = if isHoriz then Vector3.new(18, 0.5, 0.5) else Vector3.new(0.5, 8, 0.5)
		local laser = makeKillPart("Laser", laserSize,
			Vector3.new(startPos.X, 4, z), Color3.fromRGB(255, 0, 100))
		table.insert(seg.killParts, laser)

		-- Posts
		for _, xOff in ipairs({-10, 10}) do
			local post = getPart()
			post.Name = "LaserPost"
			post.Size = Vector3.new(2, 8, 2)
			post.Position = Vector3.new(startPos.X + xOff, 4, z)
			post.Color = Color3.fromRGB(60, 60, 80)
			post.Parent = workspace
			table.insert(seg.parts, post)
		end

		local speed = 2 + diff * 0.3
		local t = math.random() * 10
		if isHoriz then
			table.insert(seg.cleanupFns, animate(function(dt)
				if not laser.Parent then return true end
				t += dt * speed
				laser.Position = Vector3.new(startPos.X, 3 + math.sin(t) * 2, z)
				return false
			end))
		else
			local blinkTimer = 0
			local active = true
			table.insert(seg.cleanupFns, animate(function(dt)
				if not laser.Parent then return true end
				blinkTimer -= dt
				if blinkTimer <= 0 then
					active = not active
					blinkTimer = if active then 1.5 else math.max(0.3, 0.5 - diff * 0.05)
					laser.Transparency = if active then 0 else 1
					laser.CanTouch = active
				end
				return false
			end))
		end
	end

	spawnCoins(seg, 0.5)
	return seg
end

generators.SwingingAxe = function(startPos, diff)
	local seg = newSeg("SwingingAxe", startPos)
	table.insert(seg.parts, makeBase(startPos, seg.length))

	local numAxes = 2 + math.floor(diff / 3)
	for i = 1, numAxes do
		local z = startPos.Z + seg.length * i / (numAxes + 1)
		local pivotY = 14
		local chainLen = 8
		local pivotPos = Vector3.new(startPos.X, pivotY, z)

		local chain = getPart()
		chain.Name = "Chain"
		chain.Size = Vector3.new(0.5, chainLen, 0.5)
		chain.Color = Color3.fromRGB(80, 80, 80)
		chain.Material = Enum.Material.Metal
		chain.Parent = workspace
		table.insert(seg.parts, chain)

		local axe = makeKillPart("Axe", Vector3.new(6, 3, 2),
			pivotPos - Vector3.new(0, chainLen, 0), Color3.fromRGB(150, 150, 150))
		axe.Material = Enum.Material.Metal
		table.insert(seg.killParts, axe)

		local speed = 1.5 + diff * 0.2
		local swingAng = math.rad(30 + diff * 5)
		local t = math.random() * 10
		table.insert(seg.cleanupFns, animate(function(dt)
			if not axe.Parent then return true end
			t += dt * speed
			local angle = math.sin(t) * swingAng
			local endPos = pivotPos - Vector3.new(math.sin(angle) * chainLen, math.cos(angle) * chainLen, 0)
			axe.Position = endPos
			chain.Position = (pivotPos + endPos) / 2
			chain.CFrame = CFrame.lookAt(chain.Position, endPos) * CFrame.Angles(math.pi/2, 0, 0)
			return false
		end))
	end

	spawnCoins(seg, 0.6)
	return seg
end

generators.SpikePlatform = function(startPos, diff)
	local seg = newSeg("SpikePlatform", startPos)
	table.insert(seg.parts, makeBase(startPos, seg.length))

	-- Platforms that periodically become spikes
	local numPlats = 3 + math.floor(diff / 3)
	for i = 1, numPlats do
		local z = startPos.Z + seg.length * i / (numPlats + 1)
		local x = startPos.X + (math.random() - 0.5) * 8
		local spike = makeKillPart("Spike", Vector3.new(5, 0.3, 5),
			Vector3.new(x, 0.15, z), Color3.fromRGB(200, 50, 50))
		spike.Transparency = 1
		spike.CanTouch = false
		table.insert(seg.killParts, spike)

		-- Safe platform overlay
		local safe = getPart()
		safe.Name = "SafePlat"
		safe.Size = Vector3.new(5, 0.5, 5)
		safe.Position = Vector3.new(x, 0.25, z)
		safe.Color = Color3.fromRGB(100, 200, 100)
		safe.Material = Enum.Material.Neon
		safe.CanCollide = false
		safe.Parent = workspace
		table.insert(seg.parts, safe)

		local timer = 0
		local active = false
		local onDur = math.max(0.8, 1.5 - diff * 0.1)
		local offDur = math.max(1, 2.5 - diff * 0.15)

		table.insert(seg.cleanupFns, animate(function(dt)
			if not spike.Parent then return true end
			timer -= dt
			if timer <= 0 then
				active = not active
				timer = if active then onDur else offDur
				spike.Transparency = if active then 0 else 1
				spike.CanTouch = active
				safe.Color = if active then Color3.fromRGB(200, 50, 50) else Color3.fromRGB(100, 200, 100)
			end
			return false
		end))
	end

	spawnCoins(seg, 0.7)
	return seg
end

-- ============================================================================
-- CORE: SEGMENT SPAWNING & STREAMING
-- ============================================================================

-- Spawn a segment at a given position
function ObstacleManager:SpawnSegment(segType: SegmentType, startPos: Vector3, distance: number): SegmentData
	local diff = getDifficultyMult(distance) * SEGMENT_CONFIGS[segType].diff / 5
	diff = math.clamp(diff, 1, 10)

	local gen = generators[segType]
	if not gen then
		warn("[ObstacleManager] No generator for: " .. segType)
		return generators.SpinningBlade(startPos, diff)
	end

	local seg = gen(startPos, diff)

	-- Maybe add checkpoint
	if distance > 0 and distance % CHECKPOINT_INTERVAL < seg.length then
		makeCheckpoint(seg, startPos + Vector3.new(0, 0, 2))
	end

	segments[seg.id] = seg
	return seg
end

-- Remove a segment and recycle its parts
function ObstacleManager:DespawnSegment(segId: string)
	local seg = segments[segId]
	if not seg then return end

	-- Stop animations
	for _, fn in ipairs(seg.cleanupFns) do
		pcall(fn)
	end

	-- Recycle all parts
	for _, p in ipairs(seg.parts) do recyclePart(p) end
	for _, p in ipairs(seg.killParts) do
		p:SetAttribute("KillPart", nil)
		recyclePart(p)
	end
	for _, p in ipairs(seg.coins) do recyclePart(p) end
	if seg.checkpoint then recyclePart(seg.checkpoint) end

	segments[segId] = nil
end

-- ============================================================================
-- PLAYER RUN MANAGEMENT
-- ============================================================================

-- Start a new run for a player
function ObstacleManager:StartRun(player: Player, spawnPos: Vector3): PlayerRunData
	local userId = player.UserId

	-- Clean up old run if exists
	if playerRuns[userId] then
		ObstacleManager:EndRun(player)
	end

	local run: PlayerRunData = {
		player = player,
		currentDistance = 0,
		lastCheckpointDist = 0,
		lastCheckpointPos = spawnPos,
		spawnedUpTo = 0,
		activeSegmentIds = {},
		seed = math.random(1, 999999),
	}
	playerRuns[userId] = run

	-- Spawn initial segments
	ObstacleManager:UpdateStreaming(player, spawnPos)

	return run
end

-- Update streaming: spawn ahead, despawn behind
function ObstacleManager:UpdateStreaming(player: Player, playerPos: Vector3)
	local run = playerRuns[player.UserId]
	if not run then return end

	local playerZ = playerPos.Z
	run.currentDistance = playerZ - (run.lastCheckpointPos.Z - run.lastCheckpointDist)

	-- Spawn ahead
	while run.spawnedUpTo < playerZ + SPAWN_AHEAD do
		local available = getAvailableTypes(run.spawnedUpTo)
		local segType = available[math.random(1, #available)]
		local cfg = SEGMENT_CONFIGS[segType]

		local startPos = Vector3.new(0, 0, run.spawnedUpTo)
		local seg = ObstacleManager:SpawnSegment(segType, startPos, run.spawnedUpTo)

		table.insert(run.activeSegmentIds, seg.id)
		run.spawnedUpTo += cfg.length + math.random(5, 15) -- Gap between segments
	end

	-- Despawn behind
	local newActive = {}
	for _, segId in ipairs(run.activeSegmentIds) do
		local seg = segments[segId]
		if seg and seg.endPosition.Z < playerZ - DESPAWN_BEHIND then
			ObstacleManager:DespawnSegment(segId)
		else
			table.insert(newActive, segId)
		end
	end
	run.activeSegmentIds = newActive
end

-- End a player's run, clean up everything
function ObstacleManager:EndRun(player: Player)
	local run = playerRuns[player.UserId]
	if not run then return end

	for _, segId in ipairs(run.activeSegmentIds) do
		ObstacleManager:DespawnSegment(segId)
	end

	playerRuns[player.UserId] = nil
end

-- Get current run data
function ObstacleManager:GetRun(player: Player): PlayerRunData?
	return playerRuns[player.UserId]
end

-- ============================================================================
-- CLEANUP ON PLAYER LEAVE
-- ============================================================================

Players.PlayerRemoving:Connect(function(player)
	ObstacleManager:EndRun(player)
end)

-- ============================================================================
-- INIT
-- ============================================================================

function ObstacleManager:Init()
	print("[ObstacleManager] Initialized with " .. tostring(#ALL_TYPES) .. " hazard types")
end

return ObstacleManager

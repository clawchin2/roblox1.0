--!strict
-- GameManager.server.lua
-- Main server orchestrator for Endless Escape
-- Location: ServerScriptService/GameManager.server.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

-- Wait for shared modules
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))

-- Server modules
local Modules = script.Parent:WaitForChild("Modules")
local DataManager = require(Modules:WaitForChild("DataManager"))
local EconomyManager = require(Modules:WaitForChild("EconomyManager"))
local ShopManager = require(Modules:WaitForChild("ShopManager"))
local ObstacleManager = require(Modules:WaitForChild("ObstacleManager"))
local DailyRewards = require(Modules:WaitForChild("DailyRewards"))
local LuckySpin = require(Modules:WaitForChild("LuckySpin"))
local Leaderboard = require(Modules:WaitForChild("Leaderboard"))

-- ============================================================================
-- REMOTE EVENTS
-- ============================================================================

local GameEvents = Instance.new("Folder")
GameEvents.Name = "GameEvents"
GameEvents.Parent = ReplicatedStorage

local StartRunEvent = Instance.new("RemoteEvent")
StartRunEvent.Name = "StartRun"
StartRunEvent.Parent = GameEvents

local PlayerDiedEvent = Instance.new("RemoteEvent")
PlayerDiedEvent.Name = "PlayerDied"
PlayerDiedEvent.Parent = GameEvents

local RespawnEvent = Instance.new("RemoteEvent")
RespawnEvent.Name = "Respawn"
RespawnEvent.Parent = GameEvents

local DistanceUpdateEvent = Instance.new("RemoteEvent")
DistanceUpdateEvent.Name = "DistanceUpdate"
DistanceUpdateEvent.Parent = GameEvents

local DeathScreenDataEvent = Instance.new("RemoteEvent")
DeathScreenDataEvent.Name = "DeathScreenData"
DeathScreenDataEvent.Parent = GameEvents

local UseSkipAheadEvent = Instance.new("RemoteEvent")
UseSkipAheadEvent.Name = "UseSkipAhead"
UseSkipAheadEvent.Parent = GameEvents

local UseShieldEvent = Instance.new("RemoteEvent")
UseShieldEvent.Name = "UseShield"
UseShieldEvent.Parent = GameEvents

local CollectCoinEvent = Instance.new("RemoteEvent")
CollectCoinEvent.Name = "CollectCoin"
CollectCoinEvent.Parent = GameEvents

local LeaderboardUpdateEvent = Instance.new("RemoteEvent")
LeaderboardUpdateEvent.Name = "LeaderboardUpdate"
LeaderboardUpdateEvent.Parent = GameEvents

-- ============================================================================
-- PLAYER STATE
-- ============================================================================

type PlayerState = {
	inRun: boolean,
	currentDistance: number,
	personalBest: number,
	deathCount: number,
	deathsThisMinute: number,
	lastDeathTime: number,
	shieldActive: boolean,
	speedBoostActive: boolean,
	sessionPurchases: number,
	consecutiveSameObstacleDeath: number,
	lastObstacleType: string,
}

local playerStates: {[number]: PlayerState} = {}

-- Spawn position
local SPAWN_POS = Vector3.new(0, 5, 0)
local LOBBY_POS = Vector3.new(0, 5, -50)

-- ============================================================================
-- DEATH SCREEN CONTEXT (conversion triggers from Economy doc)
-- ============================================================================

local function getDeathScreenContext(state: PlayerState, distance: number): {[string]: any}
	local context: {[string]: any} = {
		distance = distance,
		personalBest = state.personalBest,
		showProducts = true,
		highlightProduct = nil,
		badge = nil,
	}

	-- Rule: First death ever — no products, just teach retry
	if state.deathCount <= 1 then
		context.showProducts = false
		return context
	end

	-- Rule: Died within 30s of start — just retry, don't monetize rage
	if distance < 50 then
		context.showProducts = false
		return context
	end

	-- Rule: Died within 50m of personal best → highlight Instant Revive
	if state.personalBest > 0 and distance >= state.personalBest - 50 then
		context.highlightProduct = "InstantRevive"
		context.badge = "SO CLOSE!"
	end

	-- Rule: Died at 900-999m range → highlight Skip Ahead
	if distance % 1000 >= 900 then
		context.highlightProduct = "SkipAhead"
		context.badge = "Almost there!"
	end

	-- Rule: 3+ deaths in under 2 minutes → highlight Shield
	if state.deathsThisMinute >= 3 then
		context.highlightProduct = "ShieldBubble"
	end

	-- Rule: Same obstacle killed them twice → highlight Speed Boost
	if state.consecutiveSameObstacleDeath >= 2 then
		context.highlightProduct = "SpeedBoost"
	end

	-- Rule: 1000m+ run → show all products (high value session)
	if distance >= 1000 then
		context.highlightProduct = context.highlightProduct or "ALL"
	end

	return context
end

-- ============================================================================
-- PLAYER SETUP
-- ============================================================================

local function setupPlayer(player: Player)
	-- Wait for data to load
	task.wait(2)

	local data = DataManager:GetData(player)
	if not data then
		warn("[GameManager] Failed to load data for " .. player.Name)
		return
	end

	playerStates[player.UserId] = {
		inRun = false,
		currentDistance = 0,
		personalBest = data.personalBest or 0,
		deathCount = 0,
		deathsThisMinute = 0,
		lastDeathTime = 0,
		shieldActive = false,
		speedBoostActive = false,
		sessionPurchases = 0,
		consecutiveSameObstacleDeath = 0,
		lastObstacleType = "",
	}

	-- Teleport to lobby
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart") :: BasePart
	hrp.CFrame = CFrame.new(LOBBY_POS)

	print("[GameManager] Player setup complete: " .. player.Name)
end

-- ============================================================================
-- RUN MANAGEMENT
-- ============================================================================

-- Player starts a run
local function onStartRun(player: Player)
	local state = playerStates[player.UserId]
	if not state then return end
	if state.inRun then return end -- Already running

	state.inRun = true
	state.currentDistance = 0

	-- Teleport to run start
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end
	hrp.CFrame = CFrame.new(SPAWN_POS)

	-- Start obstacle streaming
	ObstacleManager:StartRun(player, SPAWN_POS)

	print("[GameManager] Run started: " .. player.Name)
end

-- Player died (server-validated)
local function onPlayerDied(player: Player, obstacleType: string?)
	local state = playerStates[player.UserId]
	if not state or not state.inRun then return end

	local distance = state.currentDistance
	state.inRun = false
	state.deathCount += 1

	-- Track deaths per minute for conversion triggers
	local now = os.time()
	if now - state.lastDeathTime < 120 then
		state.deathsThisMinute += 1
	else
		state.deathsThisMinute = 1
	end
	state.lastDeathTime = now

	-- Track consecutive same-obstacle deaths
	if obstacleType and obstacleType == state.lastObstacleType then
		state.consecutiveSameObstacleDeath += 1
	else
		state.consecutiveSameObstacleDeath = 1
	end
	state.lastObstacleType = obstacleType or ""

	-- Update personal best
	if distance > state.personalBest then
		state.personalBest = distance
		DataManager:UpdateData(player, {"personalBest"}, distance)
	end

	-- Award coins for distance
	EconomyManager:AwardRunCoins(player, distance)
	
	-- Submit to leaderboard
	Leaderboard:SubmitDistance(player, distance)

	-- End obstacle streaming
	ObstacleManager:EndRun(player)

	-- Send death screen context to client
	local context = getDeathScreenContext(state, distance)
	DeathScreenDataEvent:FireClient(player, context)

	print(string.format("[GameManager] %s died at %.0fm (best: %.0fm)", 
		player.Name, distance, state.personalBest))
end

-- Player respawns (after death screen)
local function onRespawn(player: Player, useRevive: boolean)
	local state = playerStates[player.UserId]
	if not state then return end

	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	if useRevive then
		-- Check if they have an instant revive token
		local data = DataManager:GetData(player)
		if data and data._tempInstantRevive and data._tempInstantRevive.valid then
			data._tempInstantRevive.valid = false
			-- Respawn at last known position (handled by client sending position)
			print("[GameManager] " .. player.Name .. " used Instant Revive")
		else
			-- No revive — go to last checkpoint
			local run = ObstacleManager:GetRun(player)
			if run then
				hrp.CFrame = CFrame.new(run.lastCheckpointPos)
			else
				hrp.CFrame = CFrame.new(SPAWN_POS)
			end
		end
	else
		-- Normal respawn — last checkpoint or start
		hrp.CFrame = CFrame.new(SPAWN_POS) -- Simplified: restart from beginning
	end

	-- Start new run
	task.wait(0.5)
	onStartRun(player)
end

-- ============================================================================
-- COIN COLLECTION (server-validated)
-- ============================================================================

local function onCollectCoin(player: Player, coinPart: BasePart)
	-- Validate the coin exists and has value
	if not coinPart or not coinPart.Parent then return end
	local coinValue = coinPart:GetAttribute("CoinValue")
	local coinType = coinPart:GetAttribute("CoinType")
	if not coinValue or not coinType then return end

	-- Validate player is close enough (anti-exploit)
	local character = player.Character
	if not character then return end
	local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not hrp then return end

	local distance = (hrp.Position - coinPart.Position).Magnitude
	if distance > 15 then return end -- Too far away, likely exploit

	-- Award and destroy
	EconomyManager:AwardCoinCollected(player, coinType)
	coinPart:Destroy()
end

-- ============================================================================
-- DISTANCE TRACKING
-- ============================================================================

-- Server-side distance tracking loop
local function trackDistances()
	for userId, state in pairs(playerStates) do
		if state.inRun then
			local player = Players:GetPlayerByUserId(userId)
			if player and player.Character then
				local hrp = player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
				if hrp then
					-- Distance = Z position from spawn
					local newDist = math.max(0, hrp.Position.Z - SPAWN_POS.Z)
					
					-- Sanity check: no teleporting (anti-exploit)
					local delta = newDist - state.currentDistance
					if delta > 0 and delta < 50 then -- Max 50 studs per frame
						state.currentDistance = newDist
						
						-- Update streaming
						ObstacleManager:UpdateStreaming(player, hrp.Position)
						
						-- Send distance to client (throttled)
						if math.floor(newDist) % 10 == 0 then
							DistanceUpdateEvent:FireClient(player, math.floor(newDist))
						end
					elseif delta >= 50 then
						-- Suspicious movement — possible speed hack
						warn(string.format("[GameManager] Suspicious movement from %s: %.0f studs jump", 
							player.Name, delta))
					end
				end
			end
		end
	end
end

-- ============================================================================
-- KILL PART DETECTION
-- ============================================================================

local function setupKillDetection()
	-- Listen for character touches on kill parts
	workspace.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") and part:GetAttribute("KillPart") then
			part.Touched:Connect(function(hit)
				local character = hit.Parent
				if not character then return end
				local player = Players:GetPlayerFromCharacter(character)
				if not player then return end
				
				local state = playerStates[player.UserId]
				if not state or not state.inRun then return end
				
				-- Check for shield
				if state.shieldActive then
					state.shieldActive = false
					-- Shield absorbed the hit — notify client
					ReplicatedStorage:FindFirstChild("ShopEvents")
						:FindFirstChild("PurchaseSuccess")
						:FireClient(player, "ShieldUsed", { message = "Shield saved you!" })
					return
				end
				
				-- Kill the player
				local humanoid = character:FindFirstChildOfClass("Humanoid")
				if humanoid and humanoid.Health > 0 then
					humanoid.Health = 0
					onPlayerDied(player, part.Name)
				end
			end)
		end
	end)
end

-- ============================================================================
-- CHECKPOINT DETECTION
-- ============================================================================

local function setupCheckpointDetection()
	workspace.DescendantAdded:Connect(function(part)
		if part:IsA("BasePart") and part:GetAttribute("Checkpoint") then
			part.Touched:Connect(function(hit)
				local character = hit.Parent
				if not character then return end
				local player = Players:GetPlayerFromCharacter(character)
				if not player then return end
				
				local run = ObstacleManager:GetRun(player)
				if run then
					run.lastCheckpointPos = part.Position
					run.lastCheckpointDist = playerStates[player.UserId].currentDistance
				end
			end)
		end
	end)
end

-- ============================================================================
-- EVENT CONNECTIONS
-- ============================================================================

StartRunEvent.OnServerEvent:Connect(onStartRun)
RespawnEvent.OnServerEvent:Connect(function(player, useRevive)
	if typeof(useRevive) ~= "boolean" then useRevive = false end
	onRespawn(player, useRevive)
end)
CollectCoinEvent.OnServerEvent:Connect(onCollectCoin)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

print("[GameManager] Initializing Endless Escape...")

-- Init all modules
DataManager:Init()
EconomyManager:Init()
ShopManager:Init()
ObstacleManager:Init()
DailyRewards:Init()
LuckySpin:Init()
Leaderboard:Init()

-- Setup detection systems
setupKillDetection()
setupCheckpointDetection()

-- Distance tracking loop
RunService.Heartbeat:Connect(trackDistances)

-- Setup existing players
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(setupPlayer, player)
end

-- Setup new players
Players.PlayerAdded:Connect(function(player)
	task.spawn(setupPlayer, player)
end)

-- Cleanup on leave
Players.PlayerRemoving:Connect(function(player)
	playerStates[player.UserId] = nil
end)

print("[GameManager] Endless Escape ready!")

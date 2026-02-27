--!strict
-- GhostSystem.lua
-- Records and plays back player ghost runs for competitive racing
-- Location: ServerScriptService/Modules/GhostSystem.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local HttpService = game:GetService("HttpService")

local GhostSystem = {}

-- RemoteEvents
local GhostEvents = Instance.new("Folder")
GhostEvents.Name = "GhostEvents"
GhostEvents.Parent = ReplicatedStorage

local GhostDataEvent = Instance.new("RemoteEvent")
GhostDataEvent.Name = "GhostData"
GhostDataEvent.Parent = GhostEvents

local GhostPlaybackEvent = Instance.new("RemoteEvent")
GhostPlaybackEvent.Name = "GhostPlayback"
GhostPlaybackEvent.Parent = GhostEvents

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local RECORD_INTERVAL = 0.5 -- seconds between position recordings
local MAX_GHOST_DURATION = 300 -- 5 minutes max ghost recording
local MAX_GHOST_POINTS = math.floor(MAX_GHOST_DURATION / RECORD_INTERVAL)
local GHOST_TRANSPARENCY = 0.6
local GHOST_COLOR = Color3.fromRGB(150, 150, 255)

-- ============================================================================
-- DATA STORAGE
-- ============================================================================

-- In-memory ghost storage (userId -> ghost data)
local PlayerGhosts: {[number]: {positions: {Vector3}, timestamp: number, distance: number}} = {}
local ActiveRecordings: {[number]: {positions: {Vector3}, startTime: number, connection: RBXScriptConnection}} = {}
local ActiveGhosts: {[number]: {ghosts: {{model: Model, connection: RBXScriptConnection}}} = {} -- player -> their visible ghosts

-- ============================================================================
-- GHOST RECORDING
-- ============================================================================

-- Start recording a player's run
function GhostSystem:StartRecording(player: Player)
	local userId = player.UserId
	
	-- Stop any existing recording
	if ActiveRecordings[userId] then
		self:StopRecording(player)
	end
	
	local character = player.Character
	if not character then return end
	
	local hrp = character:FindFirstChild("HumanoidRootPart")
	if not hrp then return end
	
	local recording = {
		positions = {},
		startTime = os.clock(),
		connection = nil
	}
	
	-- Record position every interval
	recording.connection = task.spawn(function()
		while ActiveRecordings[userId] do
			local char = player.Character
			if char then
				local root = char:FindFirstChild("HumanoidRootPart")
				if root then
					table.insert(recording.positions, root.Position)
					
					-- Limit recording size
					if #recording.positions > MAX_GHOST_POINTS then
						table.remove(recording.positions, 1)
					end
				end
			end
			task.wait(RECORD_INTERVAL)
		end
	end)
	
	ActiveRecordings[userId] = recording
	print(string.format("[GhostSystem] Started recording for player %d", userId))
end

-- Stop recording and save if it's a new personal best
function GhostSystem:StopRecording(player: Player, finalDistance: number?): {positions: {Vector3}, distance: number}?
	local userId = player.UserId
	local recording = ActiveRecordings[userId]
	
	if not recording then return nil end
	
	-- Clean up
	ActiveRecordings[userId] = nil
	
	-- Only save if we have positions and a valid distance
	if #recording.positions < 10 then return nil end
	
	local distance = finalDistance or #recording.positions * RECORD_INTERVAL * 16 -- rough estimate
	
	local ghostData = {
		positions = recording.positions,
		timestamp = os.time(),
		distance = distance,
	}
	
	-- Store in memory (DataManager handles persistence)
	PlayerGhosts[userId] = ghostData
	
	print(string.format("[GhostSystem] Stopped recording for player %d, saved %d points", 
		userId, #recording.positions))
	
	return ghostData
end

-- ============================================================================
-- GHOST PLAYBACK
-- ============================================================================

-- Create a ghost model for playback
local function createGhostModel(playerName: string, isFriend: boolean): Model
	local ghost = Instance.new("Model")
	ghost.Name = isFriend and (playerName .. " (Friend)") or (playerName .. " (Ghost)")
	
	-- Create simple character representation
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Anchored = true
	hrp.CanCollide = false
	hrp.Transparency = GHOST_TRANSPARENCY
	hrp.Color = isFriend and Color3.fromRGB(100, 255, 100) or GHOST_COLOR
	hrp.Material = Enum.Material.Neon
	hrp.Parent = ghost
	
	local head = Instance.new("Part")
	head.Name = "Head"
	head.Size = Vector3.new(1, 1, 1)
	head.Anchored = true
	head.CanCollide = false
	head.Transparency = GHOST_TRANSPARENCY
	head.Color = hrp.Color
	head.Material = Enum.Material.Neon
	head.Parent = ghost
	
	local torso = Instance.new("Part")
	torso.Name = "Torso"
	torso.Size = Vector3.new(1, 2, 1)
	torso.Anchored = true
	torso.CanCollide = false
	torso.Transparency = GHOST_TRANSPARENCY
	torso.Color = hrp.Color
	torso.Material = Enum.Material.Neon
	torso.Parent = ghost
	
	-- Name tag
	local billboard = Instance.new("BillboardGui")
	billboard.Name = "NameTag"
	billboard.Size = UDim2.new(0, 100, 0, 30)
	billboard.StudsOffset = Vector3.new(0, 3, 0)
	billboard.AlwaysOnTop = true
	billboard.Parent = hrp
	
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, 0, 1, 0)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = ghost.Name
	nameLabel.TextColor3 = hrp.Color
	nameLabel.TextStrokeTransparency = 0
	nameLabel.TextScaled = true
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = billboard
	
	-- Trail effect
	local attachment0 = Instance.new("Attachment")
	attachment0.Position = Vector3.new(0, 0, -0.5)
	attachment0.Parent = hrp
	
	local attachment1 = Instance.new("Attachment")
	attachment1.Position = Vector3.new(0, 0, 0.5)
	attachment1.Parent = hrp
	
	local trail = Instance.new("Trail")
	trail.Color = ColorSequence.new(hrp.Color)
	trail.Transparency = NumberSequence.new(GHOST_TRANSPARENCY)
	trail.Lifetime = 0.5
	trail.WidthScale = NumberSequence.new(0.5)
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Parent = hrp
	
	ghost.PrimaryPart = hrp
	
	return ghost
end

-- Start ghost playback for a player
function GhostSystem:StartGhostPlayback(targetPlayer: Player, ghostOwnerId: number, ghostData: {positions: {Vector3}})
	if not ghostData or #ghostData.positions < 2 then return end
	
	-- Clean up existing ghosts for this player
	self:ClearGhosts(targetPlayer)
	
	local ghostModel = createGhostModel("Best Run", ghostOwnerId == targetPlayer.UserId)
	ghostModel.Parent = workspace
	
	local ghostInfo = {
		model = ghostModel,
		connection = nil,
	}
	
	if not ActiveGhosts[targetPlayer.UserId] then
		ActiveGhosts[targetPlayer.UserId] = {ghosts = {}}
	end
	table.insert(ActiveGhosts[targetPlayer.UserId].ghosts, ghostInfo)
	
	-- Animate ghost
	local positions = ghostData.positions
	local currentIndex = 1
	local startTime = os.clock()
	
	ghostInfo.connection = task.spawn(function()
		while currentIndex < #positions do
			local elapsed = os.clock() - startTime
			local targetIndex = math.min(math.floor(elapsed / RECORD_INTERVAL) + 1, #positions)
			
			if targetIndex > currentIndex then
				currentIndex = targetIndex
				local hrp = ghostModel:FindFirstChild("HumanoidRootPart")
				if hrp then
					local targetPos = positions[currentIndex]
					local prevPos = positions[currentIndex - 1] or targetPos
					
					-- Smooth interpolation
					local alpha = (elapsed % RECORD_INTERVAL) / RECORD_INTERVAL
					hrp.Position = prevPos:Lerp(targetPos, alpha)
					hrp.CFrame = CFrame.lookAt(hrp.Position, targetPos)
					
					-- Update other parts
					local head = ghostModel:FindFirstChild("Head")
					local torso = ghostModel:FindFirstChild("Torso")
					if head then head.Position = hrp.Position + Vector3.new(0, 1.5, 0) end
					if torso then torso.Position = hrp.Position end
				end
			end
			
			-- Stop if player died or left
			if not targetPlayer.Parent then break end
			
			RunService.Heartbeat:Wait()
		end
		
		-- Fade out and destroy
		if ghostModel.Parent then
			for i = 1, 10 do
				for _, part in ipairs(ghostModel:GetDescendants()) do
					if part:IsA("BasePart") then
						part.Transparency = 0.6 + (i * 0.04)
					end
				end
				task.wait(0.1)
			end
			ghostModel:Destroy()
		end
	end)
	
	-- Send to client for local effects
	GhostPlaybackEvent:FireClient(targetPlayer, ghostOwnerId, ghostData.positions)
	
	print(string.format("[GhostSystem] Started ghost playback for player %d (%d positions)", 
		targetPlayer.UserId, #positions))
end

-- Clear all ghosts for a player
function GhostSystem:ClearGhosts(player: Player)
	local ghostData = ActiveGhosts[player.UserId]
	if not ghostData then return end
	
	for _, ghost in ipairs(ghostData.ghosts) do
		if ghost.model and ghost.model.Parent then
			ghost.model:Destroy()
		end
		-- Connection is a spawned thread, it will die naturally
	end
	
	ActiveGhosts[player.UserId] = nil
end

-- ============================================================================
-- FRIEND GHOSTS
-- ============================================================================

-- Get friend's ghost data (simulated - in real implementation, fetch from server)
function GhostSystem:GetFriendGhost(friendUserId: number): {positions: {Vector3}}?
	return PlayerGhosts[friendUserId]
end

-- Show friend's ghost if available
function GhostSystem:ShowFriendGhost(player: Player, friendUserId: number, friendName: string)
	local ghostData = PlayerGhosts[friendUserId]
	if ghostData then
		self:StartGhostPlayback(player, friendUserId, ghostData)
		return true
	end
	return false
end

-- ============================================================================
-- SERIALIZATION (for DataManager integration)
-- ============================================================================

-- Serialize ghost data for storage
function GhostSystem:SerializeGhostData(ghostData: {positions: {Vector3}, timestamp: number, distance: number}): string
	local data = {
		timestamp = ghostData.timestamp,
		distance = ghostData.distance,
		positions = {},
	}
	
	-- Compress positions
	for _, pos in ipairs(ghostData.positions) do
		table.insert(data.positions, {pos.X, pos.Y, pos.Z})
	end
	
	return HttpService:JSONEncode(data)
end

-- Deserialize ghost data from storage
function GhostSystem:DeserializeGhostData(serialized: string): {positions: {Vector3}, timestamp: number, distance: number}?
	local success, data = pcall(function()
		return HttpService:JSONDecode(serialized)
	end)
	
	if not success or not data then return nil end
	
	local ghostData = {
		timestamp = data.timestamp,
		distance = data.distance,
		positions = {},
	}
	
	for _, pos in ipairs(data.positions) do
		table.insert(ghostData.positions, Vector3.new(pos[1], pos[2], pos[3]))
	end
	
	return ghostData
end

-- Get ghost data for a player (for DataManager)
function GhostSystem:GetGhostData(userId: number): {positions: {Vector3}, timestamp: number, distance: number}?
	return PlayerGhosts[userId]
end

-- Set ghost data (loaded from DataManager)
function GhostSystem:SetGhostData(userId: number, ghostData: {positions: {Vector3}, timestamp: number, distance: number})
	PlayerGhosts[userId] = ghostData
end

-- ============================================================================
-- REMOTE FUNCTIONS
-- ============================================================================

local GetGhostFunction = Instance.new("RemoteFunction")
GetGhostFunction.Name = "GetGhost"
GetGhostFunction.Parent = GhostEvents

GetGhostFunction.OnServerInvoke = function(player: Player, targetUserId: number?)
	local userId = targetUserId or player.UserId
	return PlayerGhosts[userId]
end

-- ============================================================================
-- PLAYER LIFECYCLE
-- ============================================================================

function GhostSystem:Init()
	-- Clean up when player leaves
	Players.PlayerRemoving:Connect(function(player)
		self:StopRecording(player)
		self:ClearGhosts(player)
		ActiveRecordings[player.UserId] = nil
		ActiveGhosts[player.UserId] = nil
	end)
	
	-- Auto-start recording when player spawns
	Players.PlayerAdded:Connect(function(player)
		player.CharacterAdded:Connect(function()
			-- Will be triggered by GameManager when run starts
		end)
	end)
	
	print("[GhostSystem] Initialized")
end

return GhostSystem

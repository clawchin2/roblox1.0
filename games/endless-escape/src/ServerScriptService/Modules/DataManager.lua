--!strict
-- DataManager.lua
-- DataStore wrapper with session locking, retry logic, and data versioning
-- Location: ServerScriptService/Modules/DataManager.lua

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

local Config = require(game.ReplicatedStorage.Shared.Config)

local DataManager = {}
DataManager.__index = DataManager

-- DataStore instances
local PlayerDataStore = DataStoreService:GetDataStore("PlayerData_v" .. Config.DataVersion)
local SessionLocks = {} -- In-memory session locks

-- Retry configuration
local RETRY_ATTEMPTS = 3
local RETRY_DELAY = 1 -- seconds between retries

-- Auto-save interval (seconds)
local AUTO_SAVE_INTERVAL = 60

-- ============================================================================
-- DEFAULT PLAYER DATA TEMPLATE
-- ============================================================================

local DEFAULT_DATA = {
	version = Config.DataVersion,
	coins = 0,
	personalBestDistance = 0,
	dailyStreak = {
		currentDay = 0,
		lastLogin = 0, -- Unix timestamp
	},
	ownedCosmetics = {}, -- {trailId = true, hatId = true}
	equippedCosmetics = {
		trail = nil,
		hat = nil,
	},
	purchasedGamepasses = {}, -- {gamepassId = true}
	stats = {
		totalRuns = 0,
		totalDeaths = 0,
		totalCoinsCollected = 0,
		totalDistance = 0,
	},
	dailyStats = {
		date = "", -- YYYY-MM-DD
		coinsEarned = 0,
	},
	inventory = {
		shieldBubbles = 0, -- Stored shields from streak rewards
	},
	spinData = {
		lastSpinTime = 0,
		storedSpins = 0,
	},
}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Deep copy a table
local function deepCopy<T>(original: T): T
	if typeof(original) ~= "table" then
		return original
	end
	local copy = {}
	for key, value in pairs(original) do
		copy[key] = deepCopy(value)
	end
	return copy :: any
end

-- Retry wrapper for DataStore operations
local function withRetry<T...>(operation: () -> T..., context: string): T...
	local lastError
	for attempt = 1, RETRY_ATTEMPTS do
		local success, result = pcall(operation)
		if success then
			return result
		end
		lastError = result
		warn(string.format("[DataManager] %s failed (attempt %d/%d): %s", 
			context, attempt, RETRY_ATTEMPTS, tostring(result)))
		if attempt < RETRY_ATTEMPTS then
			task.wait(RETRY_DELAY * attempt) -- Exponential backoff
		end
	end
	error(string.format("[DataManager] %s failed after %d attempts: %s", 
		context, RETRY_ATTEMPTS, tostring(lastError)))
end

-- Get current date string (YYYY-MM-DD)
local function getCurrentDate(): string
	return os.date("%Y-%m-%d")
end

-- Migrate data if version mismatch
local function migrateData(data: any): typeof(DEFAULT_DATA)
	if not data or typeof(data) ~= "table" then
		return deepCopy(DEFAULT_DATA)
	end
	
	-- Ensure all default fields exist
	for key, defaultValue in pairs(DEFAULT_DATA) do
		if data[key] == nil then
			data[key] = deepCopy(defaultValue)
		elseif typeof(defaultValue) == "table" and typeof(data[key]) == "table" then
			-- Deep merge nested tables
			for nestedKey, nestedDefault in pairs(defaultValue) do
				if data[key][nestedKey] == nil then
					data[key][nestedKey] = deepCopy(nestedDefault)
				end
			end
		end
	end
	
	-- Update version
	data.version = Config.DataVersion
	
	return data
end

-- ============================================================================
-- PLAYER DATA CACHE
-- ============================================================================

local PlayerData: {[number]: typeof(DEFAULT_DATA)} = {}
local PendingSaves: {[number]: boolean} = {}

-- ============================================================================
-- SESSION LOCKING
-- ============================================================================

-- Attempt to acquire session lock for a player
local function acquireSessionLock(userId: number): boolean
	if SessionLocks[userId] then
		return false -- Already locked by another server
	end
	SessionLocks[userId] = true
	return true
end

-- Release session lock
local function releaseSessionLock(userId: number)
	SessionLocks[userId] = nil
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

-- Load player data from DataStore
function DataManager:LoadData(player: Player): typeof(DEFAULT_DATA)
	local userId = player.UserId
	
	if PlayerData[userId] then
		return PlayerData[userId]
	end
	
	-- Acquire session lock
	if not acquireSessionLock(userId) then
		warn(string.format("[DataManager] Could not acquire session lock for player %d", userId))
		-- Return default data without saving
		local tempData = deepCopy(DEFAULT_DATA)
		PlayerData[userId] = tempData
		return tempData
	end
	
	-- Load from DataStore with retry
	local success, result = pcall(function()
		return withRetry(function()
			return PlayerDataStore:GetAsync(tostring(userId))
		end, string.format("LoadData(%d)", userId))
	end)
	
	if not success then
		warn(string.format("[DataManager] Failed to load data for player %d: %s", 
			userId, tostring(result)))
		-- Return default data
		local defaultData = deepCopy(DEFAULT_DATA)
		PlayerData[userId] = defaultData
		return defaultData
	end
	
	-- Migrate and cache data
	local data = migrateData(result)
	
	-- Check for daily reset
	local currentDate = getCurrentDate()
	if data.dailyStats.date ~= currentDate then
		data.dailyStats.date = currentDate
		data.dailyStats.coinsEarned = 0
	end
	
	-- Check streak
	local now = os.time()
	local hoursSinceLastLogin = (now - data.dailyStreak.lastLogin) / 3600
	if hoursSinceLastLogin > Config.DailyStreak.StreakWindow and hoursSinceLastLogin < 168 then
		-- Reset streak if more than 48 hours but less than a week
		data.dailyStreak.currentDay = 0
	end
	
	PlayerData[userId] = data
	return data
end

-- Save player data to DataStore
function DataManager:SaveData(player: Player, isFinal: boolean?): boolean
	local userId = player.UserId
	local data = PlayerData[userId]
	
	if not data then
		warn(string.format("[DataManager] No data to save for player %d", userId))
		return false
	end
	
	-- Check for session lock
	if not SessionLocks[userId] and not isFinal then
		warn(string.format("[DataManager] No session lock for player %d, skipping save", userId))
		return false
	end
	
	-- Mark pending save
	PendingSaves[userId] = true
	
	local success, errorMsg = pcall(function()
		withRetry(function()
			PlayerDataStore:SetAsync(tostring(userId), data)
		end, string.format("SaveData(%d)", userId))
	end)
	
	PendingSaves[userId] = nil
	
	if not success then
		warn(string.format("[DataManager] Failed to save data for player %d: %s", 
			userId, tostring(errorMsg)))
		return false
	end
	
	return true
end

-- Get player data (cached)
function DataManager:GetData(player: Player): typeof(DEFAULT_DATA)?
	return PlayerData[player.UserId]
end

-- Update a specific field in player data
function DataManager:UpdateData(player: Player, path: {string}, value: any): boolean
	local data = PlayerData[player.UserId]
	if not data then
		return false
	end
	
	-- Navigate the path
	local current = data
	for i = 1, #path - 1 do
		if typeof(current[path[i]]) ~= "table" then
			return false
		end
		current = current[path[i]]
	end
	
	-- Set the value
	current[path[#path]] = value
	return true
end

-- Get a specific field from player data
function DataManager:GetValue<T>(player: Player, path: {string}): T?
	local data = PlayerData[player.UserId]
	if not data then
		return nil
	end
	
	local current: any = data
	for _, key in ipairs(path) do
		if typeof(current) ~= "table" then
			return nil
		end
		current = current[key]
	end
	
	return current
end

-- Clear player data from cache (call on player leave)
function DataManager:ClearData(player: Player)
	local userId = player.UserId
	
	-- Wait for any pending saves
	if PendingSaves[userId] then
		local attempts = 0
		while PendingSaves[userId] and attempts < 10 do
			task.wait(0.1)
			attempts += 1
		end
	end
	
	PlayerData[userId] = nil
	releaseSessionLock(userId)
end

-- Check if player owns a specific cosmetic
function DataManager:OwnsCosmetic(player: Player, cosmeticId: string): boolean
	local owned = self:GetValue<{[string]: boolean}>(player, {"ownedCosmetics"})
	return owned and owned[cosmeticId] == true
end

-- Add a cosmetic to player's inventory
function DataManager:GiveCosmetic(player: Player, cosmeticId: string): boolean
	local owned = self:GetValue<{[string]: boolean}>(player, {"ownedCosmetics"})
	if owned then
		owned[cosmeticId] = true
		return self:UpdateData(player, {"ownedCosmetics"}, owned)
	end
	return false
end

-- Check if player owns a gamepass
function DataManager:OwnsGamepass(player: Player, gamepassId: number): boolean
	local owned = self:GetValue<{[number]: boolean}>(player, {"purchasedGamepasses"})
	return owned and owned[gamepassId] == true
end

-- Record gamepass purchase
function DataManager:RecordGamepassPurchase(player: Player, gamepassId: number): boolean
	local owned = self:GetValue<{[number]: boolean}>(player, {"purchasedGamepasses"})
	if owned then
		owned[gamepassId] = true
		return self:UpdateData(player, {"purchasedGamepasses"}, owned)
	end
	return false
end

-- Get daily coins earned
function DataManager:GetDailyCoinsEarned(player: Player): number
	local data = self:GetData(player)
	if not data then return 0 end
	
	-- Reset if new day
	local currentDate = getCurrentDate()
	if data.dailyStats.date ~= currentDate then
		data.dailyStats.date = currentDate
		data.dailyStats.coinsEarned = 0
		return 0
	end
	
	return data.dailyStats.coinsEarned
end

-- Add to daily coins earned
function DataManager:AddDailyCoins(player: Player, amount: number): boolean
	local data = self:GetData(player)
	if not data then return false end
	
	local currentDate = getCurrentDate()
	if data.dailyStats.date ~= currentDate then
		data.dailyStats.date = currentDate
		data.dailyStats.coinsEarned = 0
	end
	
	data.dailyStats.coinsEarned += amount
	return true
end

-- Get available spin count
function DataManager:GetAvailableSpins(player: Player): number
	local data = self:GetData(player)
	if not data then return 0 end
	
	local now = os.time()
	local timeSinceLastSpin = now - data.spinData.lastSpinTime
	local spinsToAdd = math.floor(timeSinceLastSpin / Config.LuckySpin.CooldownSeconds)
	
	local newStored = math.min(
		data.spinData.storedSpins + spinsToAdd,
		Config.LuckySpin.MaxStoredSpins
	)
	
	return newStored
end

-- Use a spin
function DataManager:UseSpin(player: Player): boolean
	local data = self:GetData(player)
	if not data then return false end
	
	local available = self:GetAvailableSpins(player)
	if available <= 0 then
		return false
	end
	
	local now = os.time()
	local timeSinceLastSpin = now - data.spinData.lastSpinTime
	local spinsToAdd = math.floor(timeSinceLastSpin / Config.LuckySpin.CooldownSeconds)
	
	data.spinData.storedSpins = math.min(
		data.spinData.storedSpins + spinsToAdd,
		Config.LuckySpin.MaxStoredSpins
	) - 1
	data.spinData.lastSpinTime = now
	
	return true
end

-- Update personal best distance
function DataManager:UpdatePersonalBest(player: Player, distance: number): boolean
	local currentBest = self:GetValue<number>(player, {"personalBestDistance"}) or 0
	if distance > currentBest then
		return self:UpdateData(player, {"personalBestDistance"}, distance)
	end
	return true -- Not an error, just no update needed
end

-- Increment statistics
function DataManager:IncrementStat(player: Player, statName: string, amount: number?): boolean
	local current = self:GetValue<number>(player, {"stats", statName}) or 0
	return self:UpdateData(player, {"stats", statName}, current + (amount or 1))
end

-- Add shield bubble to inventory
function DataManager:AddShieldBubble(player: Player, amount: number?): boolean
	local current = self:GetValue<number>(player, {"inventory", "shieldBubbles"}) or 0
	return self:UpdateData(player, {"inventory", "shieldBubbles"}, current + (amount or 1))
end

-- Use shield bubble from inventory
function DataManager:UseShieldBubble(player: Player): boolean
	local current = self:GetValue<number>(player, {"inventory", "shieldBubbles"}) or 0
	if current > 0 then
		return self:UpdateData(player, {"inventory", "shieldBubbles"}, current - 1)
	end
	return false
end

-- Get shield bubble count
function DataManager:GetShieldBubbleCount(player: Player): number
	return self:GetValue<number>(player, {"inventory", "shieldBubbles"}) or 0
end

-- Claim daily streak reward
function DataManager:ClaimDailyStreak(player: Player): (boolean, {coins: number, item: string?}?)
	local data = self:GetData(player)
	if not data then return false, nil end
	
	local now = os.time()
	local hoursSinceLastClaim = (now - data.dailyStreak.lastLogin) / 3600
	
	-- Can only claim once per day (24 hours)
	if hoursSinceLastClaim < 20 then
		return false, nil -- Too soon
	end
	
	-- Check if streak broken
	if hoursSinceLastClaim > Config.DailyStreak.StreakWindow then
		data.dailyStreak.currentDay = 0
	end
	
	-- Advance streak
	data.dailyStreak.currentDay = math.min(
		data.dailyStreak.currentDay + 1,
		Config.DailyStreak.MaxDay
	)
	data.dailyStreak.lastLogin = now
	
	-- Get reward
	local reward = Config.DailyStreak.Rewards[data.dailyStreak.currentDay]
	if reward then
		-- Add coins
		data.coins += reward.coins
		
		-- Give item if applicable
		if reward.item then
			if reward.item == "ShieldBubble" then
				data.inventory.shieldBubbles += 1
			end
		end
		
		return true, reward
	end
	
	return false, nil
end

-- ============================================================================
-- LIFECYCLE HOOKS
-- ============================================================================

-- Initialize DataManager
function DataManager:Init()
	-- Player joining
	Players.PlayerAdded:Connect(function(player)
		self:LoadData(player)
		
		-- Save data periodically while player is in game
		local connection
		connection = task.spawn(function()
			while player.Parent do
				task.wait(AUTO_SAVE_INTERVAL)
				if player.Parent then
					self:SaveData(player)
				end
			end
		end)
	end)
	
	-- Player leaving
	Players.PlayerRemoving:Connect(function(player)
		self:SaveData(player, true) -- Final save
		self:ClearData(player)
	end)
	
	-- Game shutdown handling
	game:BindToClose(function()
		local startTime = os.clock()
		local players = Players:GetPlayers()
		
		-- Save all player data
		for _, player in ipairs(players) do
			task.spawn(function()
				self:SaveData(player, true)
			end)
		end
		
		-- Wait for saves to complete (max 5 seconds)
		while os.clock() - startTime < 5 do
			local allSaved = true
			for _, player in ipairs(players) do
				if PendingSaves[player.UserId] then
					allSaved = false
					break
				end
			end
			if allSaved then break end
			RunService.Heartbeat:Wait()
		end
	end)
	
	print("[DataManager] Initialized")
end

return DataManager
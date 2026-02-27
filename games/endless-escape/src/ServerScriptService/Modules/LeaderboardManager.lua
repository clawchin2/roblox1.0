--!strict
-- LeaderboardManager.lua
-- Enhanced leaderboard with global, friends, and personal stats
-- Uses OrderedDataStore for rankings and MemoryStore for weekly resets
-- Location: ServerScriptService/Modules/LeaderboardManager.lua

local DataStoreService = game:GetService("DataStoreService")
local MemoryStoreService = game:GetService("MemoryStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

local LeaderboardManager = {}

-- RemoteEvents & RemoteFunctions
local LeaderboardEvents = Instance.new("Folder")
LeaderboardEvents.Name = "LeaderboardManagerEvents"
LeaderboardEvents.Parent = ReplicatedStorage

local LeaderboardUpdateEvent = Instance.new("RemoteEvent")
LeaderboardUpdateEvent.Name = "LeaderboardUpdate"
LeaderboardUpdateEvent.Parent = LeaderboardEvents

local AchievementUnlockedEvent = Instance.new("RemoteEvent")
AchievementUnlockedEvent.Name = "AchievementUnlocked"
AchievementUnlockedEvent.Parent = LeaderboardEvents

local GetLeaderboardFunction = Instance.new("RemoteFunction")
GetLeaderboardFunction.Name = "GetLeaderboard"
GetLeaderboardFunction.Parent = LeaderboardEvents

local GetFriendsLeaderboardFunction = Instance.new("RemoteFunction")
GetFriendsLeaderboardFunction.Name = "GetFriendsLeaderboard"
GetFriendsLeaderboardFunction.Parent = LeaderboardEvents

local GetPersonalStatsFunction = Instance.new("RemoteFunction")
GetPersonalStatsFunction.Name = "GetPersonalStats"
GetPersonalStatsFunction.Parent = LeaderboardEvents

-- ============================================================================
-- DATA STORES
-- ============================================================================

-- OrderedDataStores for rankings
local GlobalDistanceStore = DataStoreService:GetOrderedDataStore("EED_GlobalDistance_v1")
local WeeklyDistanceStore = DataStoreService:GetOrderedDataStore("EED_WeeklyDistance_v1")

-- MemoryStore for weekly reset tracking
local WeeklyResetStore = MemoryStoreService:GetSortedMap("WeeklyReset_v1")

-- ============================================================================
-- CONFIGURATION
-- ============================================================================

local TOP_N = 100 -- Global leaderboard size
local WEEKLY_TOP_N = 50 -- Weekly leaderboard size
local CACHE_REFRESH_INTERVAL = 300 -- 5 minutes
local WEEKLY_RESET_DAY = 1 -- Sunday (1 = Sunday in Lua os.date)
local WEEKLY_RESET_HOUR = 0 -- Midnight

-- Achievement definitions
local ACHIEVEMENTS = {
	First100m = {
		id = "First100m",
		name = "First 100m",
		description = "Reach 100 meters",
		icon = "rbxassetid://0",
		requirement = {type = "distance", value = 100},
	},
	CoinCollector = {
		id = "CoinCollector",
		name = "Coin Collector",
		description = "Collect 1,000 coins",
		icon = "rbxassetid://0",
		requirement = {type = "coins", value = 1000},
	},
	MarathonRunner = {
		id = "MarathonRunner",
		name = "Marathon Runner",
		description = "Reach 500 meters",
		icon = "rbxassetid://0",
		requirement = {type = "distance", value = 500},
	},
	Persistent = {
		id = "Persistent",
		name = "Persistent",
		description = "Die 100 times",
		icon = "rbxassetid://0",
		requirement = {type = "deaths", value = 100},
	},
}

-- ============================================================================
-- CACHE
-- ============================================================================

local globalCache: {{userId: number, name: string, distance: number, timestamp: number}} = {}
local weeklyCache: {{userId: number, name: string, distance: number, timestamp: number}} = {}
local lastCacheUpdate = 0

-- ============================================================================
-- WEEKLY RESET LOGIC
-- ============================================================================

local function getWeekStart(): number
	local now = os.time()
	local date = os.date("*t", now)
	local daysSinceSunday = date.wday - 1
	local secondsSinceSunday = daysSinceSunday * 86400 + date.hour * 3600 + date.min * 60 + date.sec
	return now - secondsSinceSunday
end

local function shouldResetWeekly(): boolean
	local currentWeekStart = getWeekStart()
	local success, storedWeekStart = pcall(function()
		return WeeklyResetStore:GetAsync("current_week")
	end)
	
	if not success or not storedWeekStart then
		-- Initialize
		pcall(function()
			WeeklyResetStore:SetAsync("current_week", currentWeekStart, 86400 * 7)
		end)
		return false
	end
	
	return currentWeekStart > (storedWeekStart :: number)
end

local function performWeeklyReset()
	print("[LeaderboardManager] Performing weekly reset...")
	
	-- Backup weekly to history
	local success, weeklyData = pcall(function()
		return WeeklyDistanceStore:GetSortedAsync(false, WEEKLY_TOP_N)
	end)
	
	if success then
		local weekKey = "week_" .. tostring(os.time())
		local historyData = {}
		for _, entry in ipairs(weeklyData:GetCurrentPage()) do
			table.insert(historyData, {
				userId = tonumber(entry.key),
				distance = entry.value,
			})
		end
		
		-- Store in regular DataStore for history
		local historyStore = DataStoreService:GetDataStore("EED_WeeklyHistory_v1")
		pcall(function()
			historyStore:SetAsync(weekKey, historyData)
		end)
	end
	
	-- Clear weekly store
	local success2, keys = pcall(function()
		return WeeklyDistanceStore:GetSortedAsync(false, 1000)
	end)
	
	if success2 and keys then
		for _, entry in ipairs(keys:GetCurrentPage()) do
			pcall(function()
				WeeklyDistanceStore:RemoveAsync(entry.key)
			end)
		end
	end
	
	-- Update reset timestamp
	local currentWeekStart = getWeekStart()
	pcall(function()
		WeeklyResetStore:SetAsync("current_week", currentWeekStart, 86400 * 7)
	end)
	
	-- Clear cache
	weeklyCache = {}
	
	print("[LeaderboardManager] Weekly reset complete")
end

-- ============================================================================
-- LEADERBOARD OPERATIONS
-- ============================================================================

-- Submit a distance score
function LeaderboardManager:SubmitDistance(player: Player, distance: number, timestamp: number?)
	local userId = player.UserId
	local ts = timestamp or os.time()
	
	-- Check for weekly reset
	if shouldResetWeekly() then
		performWeeklyReset()
	end
	
	-- Update global if better
	local success, currentGlobal = pcall(function()
		return GlobalDistanceStore:GetAsync(userId)
	end)
	
	if not success or not currentGlobal or distance > currentGlobal then
		pcall(function()
			GlobalDistanceStore:SetAsync(userId, distance)
		end)
	end
	
	-- Update weekly (always records this week's best)
	local success2, currentWeekly = pcall(function()
		return WeeklyDistanceStore:GetAsync(userId)
	end)
	
	if not success2 or not currentWeekly or distance > currentWeekly then
		pcall(function()
			WeeklyDistanceStore:SetAsync(userId, distance)
		end)
	end
	
	-- Refresh cache
	self:RefreshCache()
end

-- Refresh leaderboard cache
function LeaderboardManager:RefreshCache()
	local now = os.time()
	if now - lastCacheUpdate < 60 then return end -- Min 1 min between refreshes
	
	lastCacheUpdate = now
	
	-- Refresh global
	local success, pages = pcall(function()
		return GlobalDistanceStore:GetSortedAsync(false, TOP_N)
	end)
	
	if success then
		globalCache = {}
		for _, entry in ipairs(pages:GetCurrentPage()) do
			local userId = tonumber(entry.key)
			local name = "Unknown"
			pcall(function()
				name = Players:GetNameFromUserIdAsync(userId)
			end)
			table.insert(globalCache, {
				userId = userId,
				name = name,
				distance = entry.value,
				timestamp = os.time(),
			})
		end
	end
	
	-- Refresh weekly
	local success2, weeklyPages = pcall(function()
		return WeeklyDistanceStore:GetSortedAsync(false, WEEKLY_TOP_N)
	end)
	
	if success2 then
		weeklyCache = {}
		for _, entry in ipairs(weeklyPages:GetCurrentPage()) do
			local userId = tonumber(entry.key)
			local name = "Unknown"
			pcall(function()
				name = Players:GetNameFromUserIdAsync(userId)
			end)
			table.insert(weeklyCache, {
				userId = userId,
				name = name,
				distance = entry.value,
				timestamp = os.time(),
			})
		end
	end
	
	-- Broadcast to all players
	LeaderboardUpdateEvent:FireAllClients({
		global = globalCache,
		weekly = weeklyCache,
		resetTime = getWeekStart() + 604800, -- Next Sunday
	})
end

-- Get player's global rank
function LeaderboardManager:GetPlayerRank(player: Player): (number?, number?)
	local userId = player.UserId
	
	local success, rank = pcall(function()
		return GlobalDistanceStore:GetRankAsync(userId)
	end)
	
	local success2, distance = pcall(function()
		return GlobalDistanceStore:GetAsync(userId)
	end)
	
	return success and rank or nil, success2 and distance or nil
end

-- Get player's weekly rank
function LeaderboardManager:GetPlayerWeeklyRank(player: Player): (number?, number?)
	local userId = player.UserId
	
	local success, rank = pcall(function()
		return WeeklyDistanceStore:GetRankAsync(userId)
	end)
	
	local success2, distance = pcall(function()
		return WeeklyDistanceStore:GetAsync(userId)
	end)
	
	return success and rank or nil, success2 and distance or nil
end

-- ============================================================================
-- FRIENDS LEADERBOARD
-- ============================================================================

function LeaderboardManager:GetFriendsLeaderboard(player: Player): {{userId: number, name: string, distance: number, isOnline: boolean, isPlayer: boolean}}
	local results = {}
	
	-- Add self first
	local playerDistance = 0
	pcall(function()
		playerDistance = GlobalDistanceStore:GetAsync(player.UserId) or 0
	end)
	
	table.insert(results, {
		userId = player.UserId,
		name = player.Name,
		distance = playerDistance,
		isOnline = true,
		isPlayer = true,
	})
	
	-- Get friends
	local success, friends = pcall(function()
		return Players:GetFriendsAsync(player.UserId)
	end)
	
	if success and friends then
		for _, friend in ipairs(friends) do
			local friendDistance = 0
			pcall(function()
				friendDistance = GlobalDistanceStore:GetAsync(friend.Id) or 0
			end)
			
			-- Check if online (simplified - would need presence API in production)
			local isOnline = false
			for _, p in ipairs(Players:GetPlayers()) do
				if p.UserId == friend.Id then
					isOnline = true
					break
				end
			end
			
			table.insert(results, {
				userId = friend.Id,
				name = friend.Username,
				distance = friendDistance,
				isOnline = isOnline,
				isPlayer = false,
			})
		end
	end
	
	-- Sort by distance
	table.sort(results, function(a, b)
		return a.distance > b.distance
	end)
	
	return results
end

-- ============================================================================
-- PERSONAL STATS
-- ============================================================================

function LeaderboardManager:GetPersonalStats(player: Player, dataManager): {[string]: any}
	local data = dataManager:GetData(player)
	if not data then return {} end
	
	local globalRank, globalBest = self:GetPlayerRank(player)
	local weeklyRank, weeklyBest = self:GetPlayerWeeklyRank(player)
	
	return {
		-- Distance stats
		bestDistanceEver = data.personalBestDistance or 0,
		bestDistanceWeekly = weeklyBest or 0,
		globalRank = globalRank,
		weeklyRank = weeklyRank,
		
		-- Run stats
		totalRuns = data.stats.totalRuns or 0,
		totalDeaths = data.stats.totalDeaths or 0,
		totalCoinsCollected = data.stats.totalCoinsCollected or 0,
		totalDistance = data.stats.totalDistance or 0,
		
		-- Time played (would need to be tracked)
		timePlayed = data.stats.timePlayed or 0,
		
		-- Achievements
		achievements = data.achievements or {},
	}
end

-- ============================================================================
-- ACHIEVEMENTS
-- ============================================================================

-- Check and award achievements
function LeaderboardManager:CheckAchievements(player: Player, dataManager): {string}
	local data = dataManager:GetData(player)
	if not data then return {} end
	
	local unlocked = {}
	local playerAchievements = data.achievements or {}
	
	for achievementId, achievement in pairs(ACHIEVEMENTS) do
		if not playerAchievements[achievementId] then
			local shouldUnlock = false
			
			if achievement.requirement.type == "distance" then
				if (data.personalBestDistance or 0) >= achievement.requirement.value then
					shouldUnlock = true
				end
			elseif achievement.requirement.type == "coins" then
				if (data.stats.totalCoinsCollected or 0) >= achievement.requirement.value then
					shouldUnlock = true
				end
			elseif achievement.requirement.type == "deaths" then
				if (data.stats.totalDeaths or 0) >= achievement.requirement.value then
					shouldUnlock = true
				end
			end
			
			if shouldUnlock then
				playerAchievements[achievementId] = {
					unlockedAt = os.time(),
					achievement = achievement,
				}
				table.insert(unlocked, achievementId)
				
				-- Fire client event
				AchievementUnlockedEvent:FireClient(player, achievement)
				
				print(string.format("[LeaderboardManager] Player %d unlocked achievement: %s", 
					player.UserId, achievement.name))
			end
		end
	end
	
	-- Update data
	if #unlocked > 0 then
		dataManager:UpdateData(player, {"achievements"}, playerAchievements)
	end
	
	return unlocked
end

-- Get all achievements with player progress
function LeaderboardManager:GetAllAchievements(player: Player, dataManager): {{id: string, name: string, description: string, unlocked: boolean, progress: number, target: number}}
	local data = dataManager:GetData(player)
	if not data then return {} end
	
	local results = {}
	local playerAchievements = data.achievements or {}
	
	for achievementId, achievement in pairs(ACHIEVEMENTS) do
		local unlocked = playerAchievements[achievementId] ~= nil
		local progress = 0
		
		if achievement.requirement.type == "distance" then
			progress = math.min(data.personalBestDistance or 0, achievement.requirement.value)
		elseif achievement.requirement.type == "coins" then
			progress = math.min(data.stats.totalCoinsCollected or 0, achievement.requirement.value)
		elseif achievement.requirement.type == "deaths" then
			progress = math.min(data.stats.totalDeaths or 0, achievement.requirement.value)
		end
		
		table.insert(results, {
			id = achievementId,
			name = achievement.name,
			description = achievement.description,
			icon = achievement.icon,
			unlocked = unlocked,
			progress = progress,
			target = achievement.requirement.value,
		})
	end
	
	return results
end

-- ============================================================================
-- REMOTE FUNCTION HANDLERS
-- ============================================================================

GetLeaderboardFunction.OnServerInvoke = function(player: Player)
	return {
		global = globalCache,
		weekly = weeklyCache,
		playerRank = LeaderboardManager:GetPlayerRank(player),
		playerWeeklyRank = LeaderboardManager:GetPlayerWeeklyRank(player),
		resetTime = getWeekStart() + 604800,
	}
end

-- ============================================================================
-- INIT
-- ============================================================================

function LeaderboardManager:Init(dataManager)
	self._dataManager = dataManager
	
	-- Initial cache load
	self:RefreshCache()
	
	-- Periodic refresh
	task.spawn(function()
		while true do
			task.wait(CACHE_REFRESH_INTERVAL)
			self:RefreshCache()
		end
	end)
	
	-- Weekly reset check (every hour)
	task.spawn(function()
		while true do
			task.wait(3600)
			if shouldResetWeekly() then
				performWeeklyReset()
			end
		end
	end)
	
	print("[LeaderboardManager] Initialized")
end

return LeaderboardManager

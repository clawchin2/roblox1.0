--!strict
-- Leaderboard.lua
-- Server-side leaderboard with OrderedDataStore
-- Location: ServerScriptService/Modules/Leaderboard.lua

local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Leaderboard = {}

-- DataStores
local DistanceStore = DataStoreService:GetOrderedDataStore("EndlessEscape_Distance")
local WeeklyStore = DataStoreService:GetOrderedDataStore("EndlessEscape_Distance_Weekly")

-- RemoteEvents
local LeaderboardEvents = Instance.new("Folder")
LeaderboardEvents.Name = "LeaderboardEvents"
LeaderboardEvents.Parent = ReplicatedStorage

local LeaderboardUpdateEvent = Instance.new("RemoteEvent")
LeaderboardUpdateEvent.Name = "LeaderboardUpdate"
LeaderboardUpdateEvent.Parent = LeaderboardEvents

-- ============================================================================
-- DATA
-- ============================================================================

local TOP_N = 100 -- Track top 100 globally
local WEEKLY_RESET_DAY = 1 -- Monday

-- In-memory cache
local topPlayers: {{userId: number, name: string, distance: number}} = {}
local weeklyTop: {{userId: number, name: string, distance: number}} = {}

-- ============================================================================
-- SAVE/LOAD
-- ============================================================================

function Leaderboard:SubmitDistance(player: Player, distance: number)
	local userId = player.UserId
	
	-- Update only if better
	local success, currentBest = pcall(function()
		return DistanceStore:GetAsync(userId)
	end)
	
	if success and (not currentBest or distance > currentBest) then
		pcall(function()
			DistanceStore:SetAsync(userId, distance)
		end)
	end
	
	-- Weekly (always update, tracks best this week)
	pcall(function()
		WeeklyStore:SetAsync(userId, distance)
	end)
	
	-- Refresh cache
	Leaderboard:RefreshCache()
end

-- ============================================================================
-- CACHE MANAGEMENT
-- ============================================================================

function Leaderboard:RefreshCache()
	-- Get top global
	local success, pages = pcall(function()
		return DistanceStore:GetSortedAsync(false, TOP_N)
	end)
	
	if success then
		topPlayers = {}
		local data = pages:GetCurrentPage()
		for _, entry in ipairs(data) do
			local userId = tonumber(entry.key)
			local name = "Unknown"
			pcall(function()
				name = Players:GetNameFromUserIdAsync(userId)
			end)
			table.insert(topPlayers, {
				userId = userId,
				name = name,
				distance = entry.value,
			})
		end
	end
	
	-- Get weekly top
	local success2, weeklyPages = pcall(function()
		return WeeklyStore:GetSortedAsync(false, 10)
	end)
	
	if success2 then
		weeklyTop = {}
		local data = weeklyPages:GetCurrentPage()
		for _, entry in ipairs(data) do
			local userId = tonumber(entry.key)
			local name = "Unknown"
			pcall(function()
				name = Players:GetNameFromUserIdAsync(userId)
			end)
			table.insert(weeklyTop, {
				userId = userId,
				name = name,
				distance = entry.value,
			})
		end
	end
	
	-- Broadcast update to all players
	LeaderboardUpdateEvent:FireAllClients({
		global = topPlayers,
		weekly = weeklyTop,
	})
end

-- ============================================================================
-- PLAYER QUERIES
-- ============================================================================

function Leaderboard:GetRank(player: Player): number?
	local userId = player.UserId
	local distance = 0
	pcall(function()
		distance = DistanceStore:GetAsync(userId) or 0
	end)
	
	if distance == 0 then return nil end
	
	local success, rank = pcall(function()
		return DistanceStore:GetRankAsync(userId)
	end)
	
	return success and rank or nil
end

function Leaderboard:GetNearbyPlayers(player: Player): {{name: string, distance: number, isPlayer: boolean}}
	local userId = player.UserId
	local results = {}
	
	-- Get player's distance
	local playerDist = 0
	pcall(function()
		playerDist = DistanceStore:GetAsync(userId) or 0
	end)
	
	-- Find nearby in global list
	for i, entry in ipairs(topPlayers) do
		if math.abs(entry.distance - playerDist) < 500 or i <= 20 then
			table.insert(results, {
				name = entry.name,
				distance = entry.distance,
				isPlayer = entry.userId == userId,
			})
		end
		if #results >= 20 then break end
	end
	
	return results
end

-- ============================================================================
-- WEEKLY RESET
-- ============================================================================

local function shouldResetWeekly(): boolean
	local now = os.date("*t", os.time())
	return now.wday == WEEKLY_RESET_DAY and now.hour < 2 -- Reset early Monday
end

local function resetWeekly()
	-- Clear weekly store
	local success = pcall(function()
		WeeklyStore:RemoveAsync("_lastReset")
	end)
	
	if success then
		print("[Leaderboard] Weekly leaderboard reset")
		Leaderboard:RefreshCache()
	end
end

-- Check periodically
spawn(function()
	while true do
		task.wait(3600) -- Check every hour
		if shouldResetWeekly() then
			resetWeekly()
		end
	end
end)

-- ============================================================================
-- REMOTE FUNCTIONS
-- ============================================================================

local GetLeaderboardFunction = Instance.new("RemoteFunction")
GetLeaderboardFunction.Name = "GetLeaderboard"
GetLeaderboardFunction.Parent = LeaderboardEvents

GetLeaderboardFunction.OnServerInvoke = function(player: Player)
	return {
		global = topPlayers,
		weekly = weeklyTop,
		nearby = Leaderboard:GetNearbyPlayers(player),
		rank = Leaderboard:GetRank(player),
	}
end

-- ============================================================================
-- INIT
-- ============================================================================

function Leaderboard:Init()
	-- Initial cache load
	Leaderboard:RefreshCache()
	
	-- Refresh every 5 minutes
	spawn(function()
		while true do
			task.wait(300)
			Leaderboard:RefreshCache()
		end
	end)
	
	print("[Leaderboard] Initialized")
end

return Leaderboard

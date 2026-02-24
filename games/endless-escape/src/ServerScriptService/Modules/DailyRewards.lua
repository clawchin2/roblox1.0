--!strict
-- DailyRewards.lua
-- Daily login streak system with escalating rewards
-- Location: ServerScriptService/Modules/DailyRewards.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local DataManager = require(script.Parent.DataManager)
local EconomyManager = require(script.Parent.EconomyManager)

local DailyRewards = {}

-- RemoteEvents
local DailyEvents = Instance.new("Folder")
DailyEvents.Name = "DailyEvents"
DailyEvents.Parent = ReplicatedStorage

local StreakUpdatedEvent = Instance.new("RemoteEvent")
StreakUpdatedEvent.Name = "StreakUpdated"
StreakUpdatedEvent.Parent = DailyEvents

local RewardClaimedEvent = Instance.new("RemoteEvent")
RewardClaimedEvent.Name = "RewardClaimed"
RewardClaimedEvent.Parent = DailyEvents

-- ============================================================================
-- STREAK REWARDS TABLE
-- ============================================================================

local STREAK_REWARDS = {
	[1] = { coins = 50,  item = nil },
	[2] = { coins = 75,  item = nil },
	[3] = { coins = 100, item = nil },
	[4] = { coins = 150, item = nil },
	[5] = { coins = 200, item = nil },
	[6] = { coins = 250, item = nil },
	[7] = { coins = 300, item = "ShieldBubble" }, -- Free shield on day 7!
}

-- ============================================================================
-- CORE LOGIC
-- ============================================================================

-- Check if a new day has started since last login
local function isNewDay(lastLogin: number): boolean
	if lastLogin == 0 then return true end
	local now = os.time()
	local lastDate = os.date("*t", lastLogin)
	local nowDate = os.date("*t", now)
	return nowDate.yday ~= lastDate.yday or nowDate.year ~= lastDate.year
end

-- Check if streak should reset (missed a day)
local function shouldResetStreak(lastLogin: number): boolean
	if lastLogin == 0 then return false end
	local diff = os.time() - lastLogin
	return diff > 86400 * 2 -- More than 2 days = reset
end

-- Process daily login for a player
function DailyRewards:ProcessLogin(player: Player): {claimed: boolean, day: number, reward: {coins: number, item: string?}?}
	local data = DataManager:GetData(player)
	if not data then
		return { claimed = false, day = 0, reward = nil }
	end

	local streakData = data.streak or { day = 0, lastLogin = 0 }
	local lastLogin = streakData.lastLogin or 0

	-- Not a new day — already claimed
	if not isNewDay(lastLogin) then
		StreakUpdatedEvent:FireClient(player, {
			day = streakData.day,
			claimed = true,
			nextReward = STREAK_REWARDS[math.min(streakData.day + 1, 7)],
		})
		return { claimed = false, day = streakData.day, reward = nil }
	end

	-- Check if streak resets
	if shouldResetStreak(lastLogin) then
		streakData.day = 0
	end

	-- Advance streak
	streakData.day = math.min(streakData.day + 1, 7)
	if streakData.day > 7 then
		streakData.day = 1 -- Wrap around after day 7
	end
	streakData.lastLogin = os.time()

	-- Save streak data
	DataManager:UpdateData(player, {"streak"}, streakData)

	-- Get reward for today
	local reward = STREAK_REWARDS[streakData.day]
	if not reward then
		reward = STREAK_REWARDS[1] -- Fallback
	end

	-- Grant coins
	if reward.coins > 0 then
		EconomyManager:AddCoins(player, reward.coins, "streak_reward")
	end

	-- Grant item (day 7 shield)
	if reward.item == "ShieldBubble" then
		DataManager:AddShieldBubble(player, 1)
	end

	-- Notify client
	RewardClaimedEvent:FireClient(player, {
		day = streakData.day,
		coins = reward.coins,
		item = reward.item,
		nextReward = STREAK_REWARDS[math.min(streakData.day + 1, 7)],
	})

	StreakUpdatedEvent:FireClient(player, {
		day = streakData.day,
		claimed = true,
	})

	print(string.format("[DailyRewards] Player %d claimed Day %d: %d coins%s",
		player.UserId, streakData.day, reward.coins,
		reward.item and (" + " .. reward.item) or ""))

	return { claimed = true, day = streakData.day, reward = reward }
end

-- Get streak info for UI
function DailyRewards:GetStreakInfo(player: Player): {day: number, claimed: boolean, rewards: typeof(STREAK_REWARDS)}
	local data = DataManager:GetData(player)
	if not data or not data.streak then
		return { day = 0, claimed = false, rewards = STREAK_REWARDS }
	end

	return {
		day = data.streak.day,
		claimed = not isNewDay(data.streak.lastLogin or 0),
		rewards = STREAK_REWARDS,
	}
end

-- RemoteFunction for client queries
local GetStreakFunction = Instance.new("RemoteFunction")
GetStreakFunction.Name = "GetStreakInfo"
GetStreakFunction.Parent = DailyEvents

GetStreakFunction.OnServerInvoke = function(player: Player)
	return DailyRewards:GetStreakInfo(player)
end

-- ============================================================================
-- INIT
-- ============================================================================

function DailyRewards:Init()
	-- Process login for all current players
	for _, player in ipairs(Players:GetPlayers()) do
		task.spawn(function()
			task.wait(2) -- Wait for data to load
			DailyRewards:ProcessLogin(player)
		end)
	end

	-- Process login for new players
	Players.PlayerAdded:Connect(function(player)
		task.wait(3) -- Wait for data to load
		DailyRewards:ProcessLogin(player)
	end)

	print("[DailyRewards] Initialized")
end

return DailyRewards

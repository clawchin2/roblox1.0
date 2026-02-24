--!strict
-- EconomyManager.lua
-- All currency operations with server-authoritative validation
-- Location: ServerScriptService/Modules/EconomyManager.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local DataManager = require(script.Parent.DataManager)

local EconomyManager = {}

-- RemoteEvents for client communication
local EconomyEvents = Instance.new("Folder")
EconomyEvents.Name = "EconomyEvents"
EconomyEvents.Parent = ReplicatedStorage

local CoinAddedEvent = Instance.new("RemoteEvent")
CoinAddedEvent.Name = "CoinAdded"
CoinAddedEvent.Parent = EconomyEvents

local CoinsSpentEvent = Instance.new("RemoteEvent")
CoinsSpentEvent.Name = "CoinsSpent"
CoinsSpentEvent.Parent = EconomyEvents

local DailyCapReachedEvent = Instance.new("RemoteEvent")
DailyCapReachedEvent.Name = "DailyCapReached"
DailyCapReachedEvent.Parent = EconomyEvents

-- ============================================================================
-- VALIDATION CONSTANTS
-- ============================================================================

-- Sanity check limits
local MAX_REASONABLE_COINS_PER_MINUTE = 200 -- Suspicious if higher
local MAX_SINGLE_COIN_ADD = 1000 -- No single add should exceed this
local MAX_COIN_SPEND = 10000 -- Sanity check for purchases

-- Tracking for rate limiting
local SessionCoinTracking: {[number]: {lastCheck: number, coinsThisMinute: number, violations: number}} = {}

-- ============================================================================
-- UTILITY FUNCTIONS
-- ============================================================================

-- Check if player is exploiting (rate limit / sanity check)
local function validateCoinOperation(player: Player, amount: number, isAdd: boolean): (boolean, string?)
	local userId = player.UserId
	local now = os.time()
	
	-- Sanity check: negative amounts
	if amount <= 0 then
		return false, "Invalid amount"
	end
	
	-- Sanity check: single transaction too large
	if isAdd and amount > MAX_SINGLE_COIN_ADD then
		warn(string.format("[EconomyManager] Suspicious coin add: %d coins for player %d", 
			amount, userId))
		return false, "Amount exceeds single transaction limit"
	end
	
	if not isAdd and amount > MAX_COIN_SPEND then
		return false, "Amount exceeds spend limit"
	end
	
	-- Rate limiting check
	if not SessionCoinTracking[userId] then
		SessionCoinTracking[userId] = {
			lastCheck = now,
			coinsThisMinute = 0,
			violations = 0,
		}
	end
	
	local tracking = SessionCoinTracking[userId]
	
	-- Reset minute counter if minute has passed
	if now - tracking.lastCheck >= 60 then
		tracking.lastCheck = now
		tracking.coinsThisMinute = 0
	end
	
	-- Check rate limit for adds
	if isAdd then
		tracking.coinsThisMinute += amount
		if tracking.coinsThisMinute > MAX_REASONABLE_COINS_PER_MINUTE then
			tracking.violations += 1
			warn(string.format("[EconomyManager] Rate limit violation for player %d (violation #%d)", 
				userId, tracking.violations))
			
			-- Auto-kick on repeated violations (likely exploit)
			if tracking.violations >= 3 then
				player:Kick("Exploit detected: Coin farming")
				return false, "Exploit detected"
			end
			
			return false, "Rate limit exceeded"
		end
	end
	
	return true, nil
end

-- ============================================================================
-- COIN EARNING
-- ============================================================================

--[[
	Add coins to a player with full validation
	Returns: success (boolean), amountAdded (number), reason (string?)
	
	Sources:
	- "coin_collected" - Picked up from course
	- "streak_reward" - Daily login bonus
	- "spin_reward" - Lucky spin prize
	- "dev_product" - Purchased coin pack
	- "milestone" - Distance milestone reward
]]
function EconomyManager:AddCoins(player: Player, amount: number, source: string): (boolean, number, string?)
	-- Validate inputs
	if typeof(amount) ~= "number" then
		return false, 0, "Invalid amount type"
	end
	
	amount = math.floor(amount) -- Only whole coins
	
	if amount <= 0 then
		return false, 0, "Amount must be positive"
	end
	
	-- Check for exploit patterns
	local valid, errorMsg = validateCoinOperation(player, amount, true)
	if not valid then
		return false, 0, errorMsg
	end
	
	-- Check daily earning cap (soft cap)
	local dailyEarned = DataManager:GetDailyCoinsEarned(player)
	local remainingCap = Config.Coins.DailyEarnCap - dailyEarned
	
	local amountToAdd = amount
	local capWasHit = false
	
	if remainingCap <= 0 then
		-- Soft cap already reached - only allow purchased coins
		if source ~= "dev_product" and source ~= "streak_reward" then
			-- Notify client that cap is reached
			DailyCapReachedEvent:FireClient(player, dailyEarned)
			return false, 0, "Daily earning cap reached"
		end
	elseif amount > remainingCap then
		-- Partial add - hit the cap
		amountToAdd = remainingCap
		capWasHit = true
	end
	
	-- Get current coins and add
	local currentCoins = DataManager:GetValue<number>(player, {"coins"}) or 0
	local newTotal = currentCoins + amountToAdd
	
	-- Update data
	local success = DataManager:UpdateData(player, {"coins"}, newTotal)
	if not success then
		return false, 0, "Failed to update data"
	end
	
	-- Track daily earnings (unless purchased)
	if source ~= "dev_product" then
		DataManager:AddDailyCoins(player, amountToAdd)
	end
	
	-- Update total collected stat
	DataManager:IncrementStat(player, "totalCoinsCollected", amountToAdd)
	
	-- Notify client
	CoinAddedEvent:FireClient(player, amountToAdd, newTotal, source)
	
	-- Notify if cap was hit
	if capWasHit then
		DailyCapReachedEvent:FireClient(player, dailyEarned + amountToAdd)
	end
	
	return true, amountToAdd, nil
end

-- Award coins for collected coin on course
function EconomyManager:AwardCoinCollected(player: Player, coinType: string): (boolean, number)
	local value = Config.Coins.Values[coinType]
	if not value then
		return false, 0
	end
	
	-- Check for 2x Coins gamepass
	if DataManager:OwnsGamepass(player, Config.Gamepasses.DoubleCoins.id) then
		value *= 2
	end
	
	return EconomyManager:AddCoins(player, value, "coin_collected")
end

-- Calculate coins earned for distance traveled
function EconomyManager:CalculateDistanceCoins(distance: number): number
	local coins = 0
	
	for _, range in ipairs(Config.Coins.EarnRates) do
		if distance > range.min then
			local rangeDistance = math.min(distance, range.max) - range.min
			local rangeSegments = rangeDistance / 100
			local avgCoinsPerSegment = (range.minCoins + range.maxCoins) / 2
			coins += rangeSegments * avgCoinsPerSegment
		end
	end
	
	return math.floor(coins)
end

-- Award coins for completing a run (distance-based)
function EconomyManager:AwardRunCoins(player: Player, distance: number): (boolean, number)
	local coins = EconomyManager:CalculateDistanceCoins(distance)
	
	-- Check for 2x Coins gamepass
	if DataManager:OwnsGamepass(player, Config.Gamepasses.DoubleCoins.id) then
		coins *= 2
	end
	
	return EconomyManager:AddCoins(player, coins, "run_complete")
end

-- ============================================================================
-- COIN SPENDING
-- ============================================================================

--[[
	Spend coins from a player
	Returns: success (boolean), remainingBalance (number?), error (string?)
	
	Purchase types:
	- "cosmetic" - Buy trail/hat
	- "spin" - Buy extra spin
]]
function EconomyManager:SpendCoins(player: Player, amount: number, purchaseType: string): (boolean, number?, string?)
	-- Validate inputs
	if typeof(amount) ~= "number" or amount <= 0 then
		return false, nil, "Invalid amount"
	end
	
	amount = math.floor(amount)
	
	-- Sanity check
	if amount > MAX_COIN_SPEND then
		return false, nil, "Amount exceeds maximum"
	end
	
	-- Get current balance
	local currentCoins = DataManager:GetValue<number>(player, {"coins"}) or 0
	
	-- Check sufficient funds
	if currentCoins < amount then
		return false, currentCoins, "Insufficient coins"
	end
	
	-- Deduct coins
	local newBalance = currentCoins - amount
	local success = DataManager:UpdateData(player, {"coins"}, newBalance)
	
	if not success then
		return false, currentCoins, "Failed to update data"
	end
	
	-- Notify client
	CoinsSpentEvent:FireClient(player, amount, newBalance, purchaseType)
	
	return true, newBalance, nil
end

-- Buy a cosmetic item
function EconomyManager:PurchaseCosmetic(player: Player, cosmeticId: string): (boolean, string?)
	-- Check if already owned
	if DataManager:OwnsCosmetic(player, cosmeticId) then
		return false, "Already owned"
	end
	
	-- Get cosmetic info
	local cosmetic = Config.CosmeticsById[cosmeticId]
	if not cosmetic then
		return false, "Invalid cosmetic"
	end
	
	-- Attempt purchase
	local success, newBalance, errorMsg = EconomyManager:SpendCoins(
		player, 
		cosmetic.cost, 
		"cosmetic_" .. cosmeticId
	)
	
	if not success then
		return false, errorMsg or "Purchase failed"
	end
	
	-- Grant cosmetic
	DataManager:GiveCosmetic(player, cosmeticId)
	
	return true, nil
end

-- Buy an extra spin
function EconomyManager:PurchaseSpin(player: Player): (boolean, number?, string?)
	local cost = Config.LuckySpin.AdditionalSpinCost
	
	local success, newBalance, errorMsg = EconomyManager:SpendCoins(
		player,
		cost,
		"extra_spin"
	)
	
	if not success then
		return false, nil, errorMsg
	end
	
	-- Add spin to stored spins
	local data = DataManager:GetData(player)
	if data then
		data.spinData.storedSpins = math.min(
			data.spinData.storedSpins + 1,
			Config.LuckySpin.MaxStoredSpins
		)
	end
	
	return true, newBalance, nil
end

-- ============================================================================
-- BALANCE QUERIES
-- ============================================================================

-- Get player's current coin balance
function EconomyManager:GetBalance(player: Player): number
	return DataManager:GetValue<number>(player, {"coins"}) or 0
end

-- Check if player can afford something
function EconomyManager:CanAfford(player: Player, amount: number): boolean
	return EconomyManager:GetBalance(player) >= amount
end

-- Get daily earnings info
function EconomyManager:GetDailyEarningsInfo(player: Player): {earned: number, cap: number, remaining: number}
	local earned = DataManager:GetDailyCoinsEarned(player)
	local cap = Config.Coins.DailyEarnCap
	
	return {
		earned = earned,
		cap = cap,
		remaining = math.max(0, cap - earned),
	}
end

-- ============================================================================
-- REMOTE FUNCTION HANDLERS (CLIENT REQUESTS)
-- ============================================================================

-- RemoteFunction for balance queries
local GetBalanceFunction = Instance.new("RemoteFunction")
GetBalanceFunction.Name = "GetBalance"
GetBalanceFunction.Parent = EconomyEvents

GetBalanceFunction.OnServerInvoke = function(player: Player): number
	return EconomyManager:GetBalance(player)
end

-- RemoteFunction for daily earnings info
local GetDailyInfoFunction = Instance.new("RemoteFunction")
GetDailyInfoFunction.Name = "GetDailyEarningsInfo"
GetDailyInfoFunction.Parent = EconomyEvents

GetDailyInfoFunction.OnServerInvoke = function(player: Player)
	return EconomyManager:GetDailyEarningsInfo(player)
end

-- ============================================================================
-- CLEANUP
-- ============================================================================

-- Clean up session tracking when player leaves
Players.PlayerRemoving:Connect(function(player)
	SessionCoinTracking[player.UserId] = nil
end)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function EconomyManager:Init()
	print("[EconomyManager] Initialized")
end

return EconomyManager
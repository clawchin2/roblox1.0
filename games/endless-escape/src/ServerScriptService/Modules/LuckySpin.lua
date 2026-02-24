--!strict
-- LuckySpin.lua
-- Server-side lucky spin wheel logic
-- Location: ServerScriptService/Modules/LuckySpin.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Config = require(ReplicatedStorage.Shared.Config)
local DataManager = require(script.Parent.DataManager)
local EconomyManager = require(script.Parent.EconomyManager)

local LuckySpin = {}

-- RemoteEvents
local SpinEvents = Instance.new("Folder")
SpinEvents.Name = "SpinEvents"
SpinEvents.Parent = ReplicatedStorage

local SpinResultEvent = Instance.new("RemoteEvent")
SpinResultEvent.Name = "SpinResult"
SpinResultEvent.Parent = SpinEvents

local SpinAvailableEvent = Instance.new("RemoteEvent")
SpinAvailableEvent.Name = "SpinAvailable"
SpinAvailableEvent.Parent = SpinEvents

-- ============================================================================
-- SPIN PRIZE TABLE
-- ============================================================================

-- Prize definitions with weights (must sum to 100 for simplicity)
local PRIZES = {
	{ id = "coins_10",    type = "coins", value = 10,    weight = 35, display = "10 🪙" },
	{ id = "coins_25",    type = "coins", value = 25,    weight = 25, display = "25 🪙" },
	{ id = "coins_50",    type = "coins", value = 50,    weight = 15, display = "50 🪙" },
	{ id = "trail_basic", type = "trail", value = "Fire", weight = 12, display = "🔥 Fire Trail (24h)", duration = 86400 },
	{ id = "trail_rare",  type = "trail", value = "Ice",  weight = 8,  display = "❄️ Ice Trail (24h)", duration = 86400 },
	{ id = "coins_100",   type = "coins", value = 100,   weight = 4,  display = "100 🪙" },
	{ id = "coins_250",   type = "coins", value = 250,   weight = 1,  display = "250 🪙 🎉" },
}

-- Build cumulative weight table for efficient selection
local cumulativeWeights: {{weight: number, prize: typeof(PRIZES[1])}} = {}
local totalWeight = 0
for _, prize in ipairs(PRIZES) do
	totalWeight += prize.weight
	table.insert(cumulativeWeights, { weight = totalWeight, prize = prize })
end

-- ============================================================================
-- SPIN LOGIC
-- ============================================================================

-- Get or initialize player spin data
local function getSpinData(player: Player)
	local data = DataManager:GetData(player)
	if not data then return nil end
	
	if not data.spinData then
		data.spinData = {
			lastFreeSpin = 0,
			storedSpins = Config.LuckySpin.MaxStoredSpins, -- Start with max free spins
			tempTrails = {}, -- Active temporary trails
		}
	end
	
	return data.spinData
end

-- Check if free spin is available
function LuckySpin:CanSpinFree(player: Player): boolean
	local spinData = getSpinData(player)
	if not spinData then return false end
	
	-- Has stored spins
	if spinData.storedSpins > 0 then
		return true
	end
	
	-- Check if 4 hours passed since last free spin
	local now = os.time()
	local timeSinceLast = now - (spinData.lastFreeSpin or 0)
	return timeSinceLast >= Config.LuckySpin.CooldownSeconds
end

-- Get time until next free spin
function LuckySpin:GetTimeUntilFreeSpin(player: Player): number
	local spinData = getSpinData(player)
	if not spinData then return 0 end
	
	-- Has stored spins available
	if spinData.storedSpins > 0 then
		return 0
	end
	
	local now = os.time()
	local timeSinceLast = now - (spinData.lastFreeSpin or 0)
	local remaining = Config.LuckySpin.CooldownSeconds - timeSinceLast
	
	return math.max(0, remaining)
end

-- Get current spin availability info
function LuckySpin:GetSpinInfo(player: Player): {
	canSpinFree: boolean,
	storedSpins: number,
	maxStored: number,
	timeUntilFree: number,
	canBuySpin: boolean,
	spinCost: number,
	currentCoins: number
}
	local spinData = getSpinData(player)
	local canFree = LuckySpin:CanSpinFree(player)
	local timeUntil = LuckySpin:GetTimeUntilFreeSpin(player)
	local balance = EconomyManager:GetBalance(player)
	
	return {
		canSpinFree = canFree,
		storedSpins = spinData and spinData.storedSpins or 0,
		maxStored = Config.LuckySpin.MaxStoredSpins,
		timeUntilFree = timeUntil,
		canBuySpin = balance >= Config.LuckySpin.AdditionalSpinCost,
		spinCost = Config.LuckySpin.AdditionalSpinCost,
		currentCoins = balance,
	}
end

-- Select random prize based on weights
local function selectPrize(): typeof(PRIZES[1])
	local roll = math.random(1, totalWeight)
	
	for _, entry in ipairs(cumulativeWeights) do
		if roll <= entry.weight then
			return entry.prize
		end
	end
	
	return PRIZES[1] -- Fallback
end

-- Grant a prize to player
local function grantPrize(player: Player, prize: typeof(PRIZES[1])): boolean
	if prize.type == "coins" then
		local success = EconomyManager:AddCoins(player, prize.value, "spin_reward")
		return success
		
	elseif prize.type == "trail" then
		-- Grant temporary trail
		local spinData = getSpinData(player)
		if spinData then
			local trailId = prize.value:lower() .. "_trail_temp"
			spinData.tempTrails[trailId] = {
				trailType = prize.value,
				expiresAt = os.time() + (prize.duration or 86400),
			}
		end
		return true
	end
	
	return false
end

-- Perform a spin
function LuckySpin:Spin(player: Player, useCoins: boolean): {success: boolean, prize: typeof(PRIZES[1])?, error: string?}
	local spinData = getSpinData(player)
	if not spinData then
		return { success = false, prize = nil, error = "Data not loaded" }
	end
	
	-- Determine if spin is allowed
	local canFree = LuckySpin:CanSpinFree(player)
	
	if not canFree then
		-- Must use coins
		if not useCoins then
			return { success = false, prize = nil, error = "Free spin not available" }
		end
		
		-- Try to spend coins
		local success, _, err = EconomyManager:PurchaseSpin(player)
		if not success then
			return { success = false, prize = nil, error = err or "Insufficient coins" }
		end
	else
		-- Use free spin
		if spinData.storedSpins > 0 then
			spinData.storedSpins -= 1
		else
			spinData.lastFreeSpin = os.time()
		end
	end
	
	-- Select and grant prize
	local prize = selectPrize()
	local granted = grantPrize(player, prize)
	
	if not granted then
		return { success = false, prize = nil, error = "Failed to grant prize" }
	end
	
	-- Notify client
	SpinResultEvent:FireClient(player, {
		prizeId = prize.id,
		prizeType = prize.type,
		value = prize.value,
		display = prize.display,
		wasFree = not useCoins,
		remainingSpins = spinData.storedSpins,
		timeUntilNextFree = LuckySpin:GetTimeUntilFreeSpin(player),
	})
	
	return { success = true, prize = prize, error = nil }
end

-- Refill stored spins (called on timer or by daily rewards)
function LuckySpin:RefillStoredSpins(player: Player)
	local spinData = getSpinData(player)
	if not spinData then return end
	
	local oldStored = spinData.storedSpins
	spinData.storedSpins = math.min(
		spinData.storedSpins + 1,
		Config.LuckySpin.MaxStoredSpins
	)
	
	if spinData.storedSpins > oldStored then
		SpinAvailableEvent:FireClient(player, {
			storedSpins = spinData.storedSpins,
			maxStored = Config.LuckySpin.MaxStoredSpins,
		})
	end
end

-- Clean up expired temp trails
function LuckySpin:CleanExpiredTrails(player: Player)
	local spinData = getSpinData(player)
	if not spinData or not spinData.tempTrails then return end
	
	local now = os.time()
	local expired = {}
	
	for trailId, trailData in pairs(spinData.tempTrails) do
		if trailData.expiresAt <= now then
			table.insert(expired, trailId)
		end
	end
	
	for _, trailId in ipairs(expired) do
		spinData.tempTrails[trailId] = nil
	end
	
	return #expired
end

-- Get active temporary trails
function LuckySpin:GetActiveTempTrails(player: Player): {[string]: {trailType: string, expiresAt: number}}
	local spinData = getSpinData(player)
	if not spinData then return {} end
	
	LuckySpin:CleanExpiredTrails(player)
	return spinData.tempTrails or {}
end

-- ============================================================================
-- REMOTE FUNCTIONS
-- ============================================================================

-- Get spin info
local GetSpinInfoFunction = Instance.new("RemoteFunction")
GetSpinInfoFunction.Name = "GetSpinInfo"
GetSpinInfoFunction.Parent = SpinEvents

GetSpinInfoFunction.OnServerInvoke = function(player: Player)
	return LuckySpin:GetSpinInfo(player)
end

-- Request a spin
local RequestSpinFunction = Instance.new("RemoteFunction")
RequestSpinFunction.Name = "RequestSpin"
RequestSpinFunction.Parent = SpinEvents

RequestSpinFunction.OnServerInvoke = function(player: Player, useCoins: boolean)
	if typeof(useCoins) ~= "boolean" then useCoins = false end
	return LuckySpin:Spin(player, useCoins)
end

-- ============================================================================
-- PERIODIC REFILL SYSTEM
-- ============================================================================

-- Track last refill time per player
local lastRefillCheck: {[number]: number} = {}

-- Check and refill spins periodically
local function checkRefills()
	local now = os.time()
	for _, player in ipairs(Players:GetPlayers()) do
		local userId = player.UserId
		local lastCheck = lastRefillCheck[userId] or 0
		
		-- Only check every 5 minutes per player
		if now - lastCheck >= 300 then
			lastRefillCheck[userId] = now
			
			local spinData = getSpinData(player)
			if spinData then
				-- Check if free spin is available and add to stored
				local timeSinceLast = now - (spinData.lastFreeSpin or 0)
				if timeSinceLast >= Config.LuckySpin.CooldownSeconds and spinData.storedSpins < Config.LuckySpin.MaxStoredSpins then
					LuckySpin:RefillStoredSpins(player)
				end
				
				-- Clean expired trails
				LuckySpin:CleanExpiredTrails(player)
			end
		end
	end
end

-- Start periodic check
spawn(function()
	while true do
		task.wait(60) -- Check every minute
		checkRefills()
	end
end)

-- ============================================================================
-- INIT
-- ============================================================================

function LuckySpin:Init()
	print("[LuckySpin] Initialized with " .. tostring(#PRIZES) .. " prizes")
end

return LuckySpin

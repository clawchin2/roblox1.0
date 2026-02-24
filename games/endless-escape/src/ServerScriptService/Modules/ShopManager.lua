--!strict
-- ShopManager.lua
-- MarketplaceService integration for dev products and gamepasses
-- Location: ServerScriptService/Modules/ShopManager.lua
--
-- Handles:
-- - Developer product purchases (ProcessReceipt)
-- - Gamepass ownership checks and purchases
-- - Idempotent receipt processing with duplicate prevention

local MarketplaceService = game:GetService("MarketplaceService")
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Config = require(ReplicatedStorage.Shared.Config)
local DataManager = require(script.Parent.DataManager)
local EconomyManager = require(script.Parent.EconomyManager)

local ShopManager = {}

-- ============================================================================
-- RECEIPT TRACKING DATASTORE
-- ============================================================================

-- Separate DataStore for receipt tracking (prevents duplicate processing)
local ReceiptDataStore = DataStoreService:GetDataStore("ProcessedReceipts_v1")

-- In-memory cache of recently processed receipts (5 minute TTL)
local ProcessedReceipts: {[string]: number} = {} -- receiptId -> timestamp
local RECEIPT_CACHE_TTL = 300 -- 5 minutes

-- ============================================================================
-- REMOTE EVENTS
-- ============================================================================

local ShopEvents = Instance.new("Folder")
ShopEvents.Name = "ShopEvents"
ShopEvents.Parent = ReplicatedStorage

local ProductPurchasedEvent = Instance.new("RemoteEvent")
ProductPurchasedEvent.Name = "ProductPurchased"
ProductPurchasedEvent.Parent = ShopEvents

local GamepassPurchasedEvent = Instance.new("RemoteEvent")
GamepassPurchasedEvent.Name = "GamepassPurchased"
GamepassPurchasedEvent.Parent = ShopEvents

-- ============================================================================
-- RECEIPT TRACKING (IDEMPOTENCY)
-- ============================================================================

-- Check if receipt has already been processed
local function isReceiptProcessed(receiptId: string): boolean
	-- Check in-memory cache first
	local cachedTime = ProcessedReceipts[receiptId]
	if cachedTime and (os.time() - cachedTime) < RECEIPT_CACHE_TTL then
		return true
	end
	
	-- Check DataStore
	local success, result = pcall(function()
		return ReceiptDataStore:GetAsync(receiptId)
	end)
	
	if success and result then
		-- Cache the result
		ProcessedReceipts[receiptId] = os.time()
		return true
	end
	
	return false
end

-- Mark receipt as processed
local function markReceiptProcessed(receiptId: string, playerId: number, productId: number): boolean
	local success, errorMsg = pcall(function()
		ReceiptDataStore:SetAsync(receiptId, {
			processedAt = os.time(),
			playerId = playerId,
			productId = productId,
		})
	end)
	
	if success then
		ProcessedReceipts[receiptId] = os.time()
		return true
	else
		warn(string.format("[ShopManager] Failed to mark receipt %s as processed: %s", 
			receiptId, tostring(errorMsg)))
		return false
	end
end

-- Clean up old cache entries periodically
local function cleanReceiptCache()
	local now = os.time()
	for receiptId, timestamp in pairs(ProcessedReceipts) do
		if (now - timestamp) > RECEIPT_CACHE_TTL then
			ProcessedReceipts[receiptId] = nil
		end
	end
end

-- ============================================================================
-- DEVELOPER PRODUCT HANDLERS
-- ============================================================================

-- Handle Shield Bubble purchase
local function grantShieldBubble(player: Player, productKey: string): boolean
	local success = DataManager:AddShieldBubble(player, 1)
	if success then
		ProductPurchasedEvent:FireClient(player, productKey, "Shield Bubble added to inventory")
	end
	return success
end

-- Handle Speed Boost purchase (applies immediately if in run)
local function grantSpeedBoost(player: Player, productKey: string): boolean
	-- Store speed boost in session data for game logic to apply
	local data = DataManager:GetData(player)
	if not data then return false end
	
	-- Create or get pending boosts
	if not data._session then
		data._session = {}
	end
	if not data._session.pendingBoosts then
		data._session.pendingBoosts = {}
	end
	
	-- Add speed boost to pending
	table.insert(data._session.pendingBoosts, {
		type = "speed",
		duration = Config.DevProducts.SpeedBoost.duration,
		multiplier = Config.DevProducts.SpeedBoost.speedMultiplier,
		grantedAt = os.time(),
	})
	
	ProductPurchasedEvent:FireClient(player, productKey, "Speed Boost ready to use!")
	return true
end

-- Handle Skip Ahead purchase
local function grantSkipAhead(player: Player, productKey: string): boolean
	local data = DataManager:GetData(player)
	if not data then return false end
	
	-- Create or get pending boosts
	if not data._session then
		data._session = {}
	end
	if not data._session.pendingBoosts then
		data._session.pendingBoosts = {}
	end
	
	-- Add skip ahead to pending
	table.insert(data._session.pendingBoosts, {
		type = "skip",
		obstaclesToSkip = Config.DevProducts.SkipAhead.obstaclesToSkip,
		grantedAt = os.time(),
	})
	
	ProductPurchasedEvent:FireClient(player, productKey, "Skip Ahead ready to use!")
	return true
end

-- Handle Instant Revive purchase
local function grantInstantRevive(player: Player, productKey: string): boolean
	local data = DataManager:GetData(player)
	if not data then return false end
	
	-- Create or get pending boosts
	if not data._session then
		data._session = {}
	end
	if not data._session.pendingBoosts then
		data._session.pendingBoosts = {}
	end
	
	-- Add revive to pending
	table.insert(data._session.pendingBoosts, {
		type = "revive",
		grantedAt = os.time(),
	})
	
	ProductPurchasedEvent:FireClient(player, productKey, "Instant Revive ready!")
	return true
end

-- Handle Coin Pack purchases
local function grantCoinPack(player: Player, productKey: string, coinAmount: number): boolean
	local success, amountAdded, errorMsg = EconomyManager:AddCoins(player, coinAmount, "dev_product")
	if success then
		ProductPurchasedEvent:FireClient(player, productKey, string.format("+%d Coins!", amountAdded))
	end
	return success
end

-- ============================================================================
-- PRODUCT DISPATCH TABLE
-- ============================================================================

local ProductHandlers: {[string]: (player: Player, productKey: string) -> boolean} = {
	ShieldBubble = function(player, productKey)
		return grantShieldBubble(player, productKey)
	end,
	SpeedBoost = function(player, productKey)
		return grantSpeedBoost(player, productKey)
	end,
	SkipAhead = function(player, productKey)
		return grantSkipAhead(player, productKey)
	end,
	InstantRevive = function(player, productKey)
		return grantInstantRevive(player, productKey)
	end,
	CoinPackSmall = function(player, productKey)
		return grantCoinPack(player, productKey, Config.DevProducts.CoinPackSmall.coins)
	end,
	CoinPackMedium = function(player, productKey)
		return grantCoinPack(player, productKey, Config.DevProducts.CoinPackMedium.coins)
	end,
	CoinPackLarge = function(player, productKey)
		return grantCoinPack(player, productKey, Config.DevProducts.CoinPackLarge.coins)
	end,
}

-- ============================================================================
-- PROCESS RECEIPT (MAIN ENTRY POINT)
-- ============================================================================

--[[
	ProcessReceipt callback for MarketplaceService
	This is the ONLY place where developer product purchases are handled
	MUST return Enum.ProductPurchaseDecision.PurchaseGranted or .NotProcessedYet
	
	Idempotent: Safe to call multiple times, tracks processed receipts
]]
local function processReceipt(receiptInfo: {PlayerId: number, ProductId: number, PurchaseId: string})
	local playerId = receiptInfo.PlayerId
	local productId = receiptInfo.ProductId
	local receiptId = receiptInfo.PurchaseId
	
	-- Get player
	local player = Players:GetPlayerByUserId(playerId)
	if not player then
		-- Player left, defer processing
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	-- Check if already processed (idempotency check)
	if isReceiptProcessed(receiptId) then
		-- Already processed, grant without giving items
		return Enum.ProductPurchaseDecision.PurchaseGranted
	end
	
	-- Get product key from Config
	local productKey = Config.ProductIdToKey[productId]
	if not productKey then
		warn(string.format("[ShopManager] Unknown product ID: %d", productId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	-- Get handler
	local handler = ProductHandlers[productKey]
	if not handler then
		warn(string.format("[ShopManager] No handler for product: %s (ID: %d)", productKey, productId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	-- Try to grant the product
	local grantSuccess = handler(player, productKey)
	
	if not grantSuccess then
		-- Failed to grant, try again later
		warn(string.format("[ShopManager] Failed to grant product %s to player %d", 
			productKey, playerId))
		return Enum.ProductPurchaseDecision.NotProcessedYet
	end
	
	-- Mark as processed (idempotency)
	local markSuccess = markReceiptProcessed(receiptId, playerId, productId)
	if not markSuccess then
		-- Receipt tracking failed, but we granted the product
		-- This is acceptable - better to give item twice than not at all
		-- (Roblox handles duplicate receipts anyway)
		warn(string.format("[ShopManager] Receipt %s processed but tracking failed", receiptId))
	end
	
	-- Log analytics
	print(string.format("[ShopManager] Product purchased: %s by %s", 
		productKey, player.Name))
	
	return Enum.ProductPurchaseDecision.PurchaseGranted
end

-- ============================================================================
-- GAMEPASS HANDLING
-- ============================================================================

--[[
	Check if a player owns a specific gamepass
	Returns: boolean (owns or not)
]]
function ShopManager:PlayerOwnsGamepass(player: Player, gamepassId: number): boolean
	-- Check cached data first
	if DataManager:OwnsGamepass(player, gamepassId) then
		return true
	end
	
	-- Check with MarketplaceService
	local success, owns = pcall(function()
		return MarketplaceService:UserOwnsGamePassAsync(player.UserId, gamepassId)
	end)
	
	if success and owns then
		-- Cache the ownership
		DataManager:RecordGamepassPurchase(player, gamepassId)
		return true
	end
	
	return false
end

--[[
	Check all gamepasses for a player
	Returns: table of gamepassId -> boolean
]]
function ShopManager:GetPlayerGamepasses(player: Player): {[number]: boolean}
	local result = {}
	
	for key, gamepassData in pairs(Config.Gamepasses) do
		if gamepassData.id > 0 then
			result[gamepassData.id] = self:PlayerOwnsGamepass(player, gamepassData.id)
		end
	end
	
	return result
end

--[[
	Check if player has 2x Coins gamepass
]]
function ShopManager:HasDoubleCoins(player: Player): boolean
	return self:PlayerOwnsGamepass(player, Config.Gamepasses.DoubleCoins.id)
end

--[[
	Check if player has Radio gamepass
]]
function ShopManager:HasRadio(player: Player): boolean
	return self:PlayerOwnsGamepass(player, Config.Gamepasses.Radio.id)
end

--[[
	Check if player has VIP Trail gamepass
]]
function ShopManager:HasVIPTrail(player: Player): boolean
	return self:PlayerOwnsGamepass(player, Config.Gamepasses.VIPTrail.id)
end

-- ============================================================================
-- PROMPT PURCHASES
-- ============================================================================

--[[
	Prompt player to purchase a developer product
]]
function ShopManager:PromptProductPurchase(player: Player, productId: number)
	local success, errorMsg = pcall(function()
		MarketplaceService:PromptProductPurchase(player, productId)
	end)
	
	if not success then
		warn(string.format("[ShopManager] Failed to prompt product purchase: %s", tostring(errorMsg)))
	end
end

--[[
	Prompt player to purchase a gamepass
]]
function ShopManager:PromptGamepassPurchase(player: Player, gamepassId: number)
	local success, errorMsg = pcall(function()
		MarketplaceService:PromptGamePassPurchase(player, gamepassId)
	end)
	
	if not success then
		warn(string.format("[ShopManager] Failed to prompt gamepass purchase: %s", tostring(errorMsg)))
	end
end

--[[
	Prompt specific product by key
]]
function ShopManager:PromptProductByKey(player: Player, productKey: string)
	local product = Config.DevProducts[productKey]
	if product and product.id > 0 then
		self:PromptProductPurchase(player, product.id)
	else
		warn(string.format("[ShopManager] Invalid product key or unset ID: %s", productKey))
	end
end

--[[
	Prompt specific gamepass by key
]]
function ShopManager:PromptGamepassByKey(player: Player, gamepassKey: string)
	local gamepass = Config.Gamepasses[gamepassKey]
	if gamepass and gamepass.id > 0 then
		self:PromptGamepassPurchase(player, gamepass.id)
	else
		warn(string.format("[ShopManager] Invalid gamepass key or unset ID: %s", gamepassKey))
	end
end

-- ============================================================================
-- GAMEPASS PURCHASE HANDLING (PromptGamePassPurchaseFinished)
-- ============================================================================

local function onGamepassPurchaseFinished(player: Player, gamepassId: number, wasPurchased: boolean)
	if not wasPurchased then return end
	
	-- Find the gamepass key
	local gamepassKey = nil
	for key, data in pairs(Config.Gamepasses) do
		if data.id == gamepassId then
			gamepassKey = key
			break
		end
	end
	
	if not gamepassKey then
		warn(string.format("[ShopManager] Unknown gamepass purchased: %d", gamepassId))
		return
	end
	
	-- Record the purchase
	DataManager:RecordGamepassPurchase(player, gamepassId)
	
	-- Notify client
	GamepassPurchasedEvent:FireClient(player, gamepassKey)
	
	-- Log
	print(string.format("[ShopManager] Gamepass purchased: %s by %s", 
		gamepassKey, player.Name))
end

-- ============================================================================
-- REMOTE FUNCTIONS (CLIENT QUERIES)
-- ============================================================================

-- RemoteFunction for gamepass ownership check
local OwnsGamepassFunction = Instance.new("RemoteFunction")
OwnsGamepassFunction.Name = "OwnsGamepass"
OwnsGamepassFunction.Parent = ShopEvents

OwnsGamepassFunction.OnServerInvoke = function(player: Player, gamepassId: number): boolean
	return ShopManager:PlayerOwnsGamepass(player, gamepassId)
end

-- RemoteFunction for all gamepasses
local GetGamepassesFunction = Instance.new("RemoteFunction")
GetGamepassesFunction.Name = "GetGamepasses"
GetGamepassesFunction.Parent = ShopEvents

GetGamepassesFunction.OnServerInvoke = function(player: Player)
	return ShopManager:GetPlayerGamepasses(player)
end

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function ShopManager:Init()
	-- Set up ProcessReceipt callback (only one can exist per game)
	MarketplaceService.ProcessReceipt = processReceipt
	
	-- Listen for gamepass purchase completions
	MarketplaceService.PromptGamePassPurchaseFinished:Connect(onGamepassPurchaseFinished)
	
	-- Periodic cache cleanup
	task.spawn(function()
		while true do
			task.wait(60) -- Clean every minute
			cleanReceiptCache()
		end
	end)
	
	print("[ShopManager] Initialized")
end

return ShopManager
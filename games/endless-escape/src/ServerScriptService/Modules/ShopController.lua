--!strict
-- ShopController.lua
-- Centralized shop system for cosmetic purchases and preview management
-- Location: ServerScriptService/Modules/ShopController.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local Config = require(ReplicatedStorage.Shared.Config)
local DataManager = require(script.Parent.DataManager)
local EconomyManager = require(script.Parent.EconomyManager)

local ShopController = {}

-- ============================================================================
-- REMOTE EVENTS & FUNCTIONS
-- ============================================================================

local ShopRemotes = Instance.new("Folder")
ShopRemotes.Name = "ShopRemotes"
ShopRemotes.Parent = ReplicatedStorage

-- Client -> Server: Purchase request
local PurchaseCosmeticEvent = Instance.new("RemoteEvent")
PurchaseCosmeticEvent.Name = "PurchaseCosmetic"
PurchaseCosmeticEvent.Parent = ShopRemotes

-- Client -> Server: Equip item
local EquipItemEvent = Instance.new("RemoteEvent")
EquipItemEvent.Name = "EquipItem"
EquipItemEvent.Parent = ShopRemotes

-- Server -> Client: Purchase result
local PurchaseResultEvent = Instance.new("RemoteEvent")
PurchaseResultEvent.Name = "PurchaseResult"
PurchaseResultEvent.Parent = ShopRemotes

-- Client -> Server: Get inventory
local GetInventoryFunction = Instance.new("RemoteFunction")
GetInventoryFunction.Name = "GetInventory"
GetInventoryFunction.Parent = ShopRemotes

-- Client -> Server: Preview item (server validates)
local PreviewItemEvent = Instance.new("RemoteEvent")
PreviewItemEvent.Name = "PreviewItem"
PreviewItemEvent.Parent = ShopRemotes

-- Server -> Client: Update preview to other players
local PreviewUpdateEvent = Instance.new("RemoteEvent")
PreviewUpdateEvent.Name = "PreviewUpdate"
PreviewUpdateEvent.Parent = ShopRemotes

-- ============================================================================
-- INVENTORY MANAGEMENT
-- ============================================================================

--[[
	Get full inventory data for a player
	Returns: {
		ownedCosmetics = {id = true, ...},
		equipped = {trail = id, skin = id},
		coins = number
	}
]]
function ShopController:GetInventory(player: Player): {[string]: any}
	local data = DataManager:GetData(player)
	if not data then
		return {
			ownedCosmetics = {},
			equipped = {trail = nil, skin = nil},
			coins = 0,
		}
	end
	
	return {
		ownedCosmetics = data.ownedCosmetics,
		equipped = data.equippedCosmetics,
		coins = data.coins,
	}
end

--[[
	Check if player owns a specific cosmetic
]]
function ShopController:OwnsCosmetic(player: Player, cosmeticId: string): boolean
	return DataManager:OwnsCosmetic(player, cosmeticId)
end

--[[
	Purchase a cosmetic item with coins
]]
function ShopController:PurchaseCosmetic(player: Player, cosmeticId: string): (boolean, string?)
	-- Validate cosmetic exists
	local cosmetic = Config.CosmeticsById[cosmeticId]
	if not cosmetic then
		return false, "Invalid item"
	end
	
	-- Check if already owned
	if self:OwnsCosmetic(player, cosmeticId) then
		return false, "Already owned"
	end
	
	-- Attempt to spend coins
	local success, newBalance, errorMsg = EconomyManager:SpendCoins(
		player,
		cosmetic.cost,
		"cosmetic_" .. cosmeticId
	)
	
	if not success then
		return false, errorMsg or "Not enough coins"
	end
	
	-- Grant the cosmetic
	local granted = DataManager:GiveCosmetic(player, cosmeticId)
	if not granted then
		-- Refund if grant failed
		EconomyManager:AddCoins(player, cosmetic.cost, "refund")
		return false, "Failed to grant item"
	end
	
	-- Auto-equip on purchase
	self:EquipCosmetic(player, cosmeticId)
	
	return true, nil
end

--[[
	Equip a cosmetic item (trail or skin)
]]
function ShopController:EquipCosmetic(player: Player, cosmeticId: string): boolean
	local cosmetic = Config.CosmeticsById[cosmeticId]
	if not cosmetic then return false end
	
	-- Check ownership
	if not self:OwnsCosmetic(player, cosmeticId) then
		return false
	end
	
	-- Update equipped cosmetics
	local data = DataManager:GetData(player)
	if not data then return false end
	
	if cosmetic.type == "trail" then
		data.equippedCosmetics.trail = cosmeticId
	elseif cosmetic.type == "skin" then
		data.equippedCosmetics.skin = cosmeticId
	end
	
	-- Notify other players of the equip
	PreviewUpdateEvent:FireAllClients(player.UserId, cosmetic.type, cosmeticId)
	
	return true
end

--[[
	Unequip a cosmetic type
]]
function ShopController:UnequipCosmetic(player: Player, cosmeticType: string): boolean
	local data = DataManager:GetData(player)
	if not data then return false end
	
	if cosmeticType == "trail" then
		data.equippedCosmetics.trail = nil
	elseif cosmeticType == "skin" then
		data.equippedCosmetics.skin = nil
	end
	
	PreviewUpdateEvent:FireAllClients(player.UserId, cosmeticType, nil)
	return true
end

-- ============================================================================
-- PREVIEW SYSTEM (Try Before You Buy)
-- ============================================================================

-- Active previews: playerUserId -> {cosmeticId, originalValue, timestamp}
local ActivePreviews: {[number]: {cosmeticId: string, originalSkin: Color3?, timestamp: number}} = {}

--[[
	Start previewing an item (client sees it, not permanent)
]]
function ShopController:StartPreview(player: Player, cosmeticId: string): boolean
	local cosmetic = Config.CosmeticsById[cosmeticId]
	if not cosmetic then return false end
	
	-- Store current state for revert
	local data = DataManager:GetData(player)
	if not data then return false end
	
	local character = player.Character
	if not character then return false end
	
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if not humanoid then return false end
	
	-- Store original state
	local originalSkin = nil
	if cosmetic.type == "skin" then
		local bodyColors = character:FindFirstChild("Body Colors")
		if bodyColors then
			originalSkin = bodyColors.HeadColor3
		end
	end
	
	ActivePreviews[player.UserId] = {
		cosmeticId = cosmeticId,
		originalSkin = originalSkin,
		timestamp = os.time(),
	}
	
	-- Apply preview
	self:ApplyPreviewToCharacter(player, cosmetic)
	
	return true
end

--[[
	Cancel preview and revert to original
]]
function ShopController:CancelPreview(player: Player): boolean
	local preview = ActivePreviews[player.UserId]
	if not preview then return false end
	
	local character = player.Character
	if character then
		-- Revert skin color if applicable
		if preview.originalSkin then
			local bodyColors = character:FindFirstChild("Body Colors")
			if bodyColors then
				bodyColors.HeadColor3 = preview.originalSkin
				bodyColors.TorsoColor3 = preview.originalSkin
				bodyColors.LeftArmColor3 = preview.originalSkin
				bodyColors.RightArmColor3 = preview.originalSkin
				bodyColors.LeftLegColor3 = preview.originalSkin
				bodyColors.RightLegColor3 = preview.originalSkin
			end
		end
		
		-- Remove trail preview
		local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
		if humanoidRootPart then
			local previewTrail = humanoidRootPart:FindFirstChild("PreviewTrail")
			if previewTrail then
				previewTrail:Destroy()
			end
		end
	end
	
	-- Restore equipped cosmetics
	local data = DataManager:GetData(player)
	if data then
		local equippedTrail = data.equippedCosmetics.trail
		local equippedSkin = data.equippedCosmetics.skin
		
		if equippedTrail then
			local trailCosmetic = Config.CosmeticsById[equippedTrail]
			if trailCosmetic then
				self:ApplyCosmeticToCharacter(player, trailCosmetic)
			end
		end
		
		if equippedSkin then
			local skinCosmetic = Config.CosmeticsById[equippedSkin]
			if skinCosmetic then
				self:ApplySkinToCharacter(player, skinCosmetic.color)
			end
		end
	end
	
	ActivePreviews[player.UserId] = nil
	return true
end

--[[
	Apply a cosmetic to character (permanent equipped version)
]]
function ShopController:ApplyCosmeticToCharacter(player: Player, cosmetic): boolean
	local character = player.Character
	if not character then return false end
	
	if cosmetic.type == "trail" then
		return self:ApplyTrailToCharacter(player, cosmetic)
	elseif cosmetic.type == "skin" then
		return self:ApplySkinToCharacter(player, cosmetic.color)
	end
	
	return false
end

--[[
	Apply preview to character (temporary)
]]
function ShopController:ApplyPreviewToCharacter(player: Player, cosmetic): boolean
	if cosmetic.type == "trail" then
		return self:ApplyTrailToCharacter(player, cosmetic, true)
	elseif cosmetic.type == "skin" then
		return self:ApplySkinToCharacter(player, cosmetic.color)
	end
	return false
end

--[[
	Apply trail effect to character
]]
function ShopController:ApplyTrailToCharacter(player: Player, trailData, isPreview: boolean?): boolean
	local character = player.Character
	if not character then return false end
	
	local humanoidRootPart = character:FindFirstChild("HumanoidRootPart")
	if not humanoidRootPart then return false end
	
	-- Remove existing trails
	for _, child in ipairs(humanoidRootPart:GetChildren()) do
		if child:IsA("Trail") then
			child:Destroy()
		end
	end
	
	-- Create trail attachment points
	local attachment0 = Instance.new("Attachment")
	attachment0.Name = isPreview and "PreviewTrailAttachment0" or "TrailAttachment0"
	attachment0.Position = Vector3.new(0, -1, 0.5)
	attachment0.Parent = humanoidRootPart
	
	local attachment1 = Instance.new("Attachment")
	attachment1.Name = isPreview and "PreviewTrailAttachment1" or "TrailAttachment1"
	attachment1.Position = Vector3.new(0, -1, -0.5)
	attachment1.Parent = humanoidRootPart
	
	-- Create trail
	local trail = Instance.new("Trail")
	trail.Name = isPreview and "PreviewTrail" or "EquippedTrail"
	trail.Attachment0 = attachment0
	trail.Attachment1 = attachment1
	trail.Color = ColorSequence.new(trailData.color)
	trail.Lifetime = 0.5
	trail.WidthScale = NumberSequence.new(0.5)
	trail.Transparency = NumberSequence.new(0.3)
	trail.Parent = humanoidRootPart
	
	return true
end

--[[
	Apply skin color to character
]]
function ShopController:ApplySkinToCharacter(player: Player, color: Color3): boolean
	local character = player.Character
	if not character then return false end
	
	local bodyColors = character:FindFirstChild("Body Colors")
	if not bodyColors then
		-- Create BodyColors if it doesn't exist
		bodyColors = Instance.new("BodyColors")
		bodyColors.Parent = character
	end
	
	bodyColors.HeadColor3 = color
	bodyColors.TorsoColor3 = color
	bodyColors.LeftArmColor3 = color
	bodyColors.RightArmColor3 = color
	bodyColors.LeftLegColor3 = color
	bodyColors.RightLegColor3 = color
	
	return true
end

--[[
	Get equipped cosmetics for a player (for spawning)
]]
function ShopController:GetEquippedCosmetics(player: Player): {trail: string?, skin: string?}
	local data = DataManager:GetData(player)
	if not data then
		return {trail = nil, skin = nil}
	end
	
	return {
		trail = data.equippedCosmetics.trail,
		skin = data.equippedCosmetics.skin,
	}
end

--[[
	Apply all equipped cosmetics to character (call on spawn)
]]
function ShopController:ApplyEquippedCosmetics(player: Player): boolean
	local equipped = self:GetEquippedCosmetics(player)
	
	if equipped.trail then
		local trailData = Config.CosmeticsById[equipped.trail]
		if trailData then
			self:ApplyTrailToCharacter(player, trailData)
		end
	end
	
	if equipped.skin then
		local skinData = Config.CosmeticsById[equipped.skin]
		if skinData then
			self:ApplySkinToCharacter(player, skinData.color)
		end
	end
	
	return true
end

-- ============================================================================
-- DEV PRODUCT PURCHASE PROMPTS
-- ============================================================================

function ShopController:PromptDevProduct(player: Player, productKey: string)
	local product = Config.DevProducts[productKey]
	if not product then
		warn("[ShopController] Unknown product key: " .. productKey)
		return
	end
	
	if product.id == 0 then
		warn("[ShopController] Product not configured: " .. productKey)
		return
	end
	
	MarketplaceService:PromptProductPurchase(player, product.id)
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

-- Handle purchase requests from client
PurchaseCosmeticEvent.OnServerEvent:Connect(function(player: Player, cosmeticId: string)
	local success, errorMsg = ShopController:PurchaseCosmetic(player, cosmeticId)
	
	local cosmetic = Config.CosmeticsById[cosmeticId]
	
	PurchaseResultEvent:FireClient(player, {
		success = success,
		cosmeticId = cosmeticId,
		cosmeticName = cosmetic and cosmetic.name or "Unknown",
		error = errorMsg,
	})
end)

-- Handle equip requests
EquipItemEvent.OnServerEvent:Connect(function(player: Player, cosmeticId: string, action: string)
	if action == "equip" then
		local success = ShopController:EquipCosmetic(player, cosmeticId)
		PurchaseResultEvent:FireClient(player, {
			success = success,
			cosmeticId = cosmeticId,
			action = "equipped",
		})
	elseif action == "unequip" then
		local cosmetic = Config.CosmeticsById[cosmeticId]
		if cosmetic then
			local success = ShopController:UnequipCosmetic(player, cosmetic.type)
			PurchaseResultEvent:FireClient(player, {
				success = success,
				cosmeticId = cosmeticId,
				action = "unequipped",
			})
		end
	elseif action == "preview" then
		ShopController:StartPreview(player, cosmeticId)
	elseif action == "cancel_preview" then
		ShopController:CancelPreview(player)
	end
end)

-- Handle inventory requests
GetInventoryFunction.OnServerInvoke = function(player: Player)
	return ShopController:GetInventory(player)
end

-- Handle preview requests
PreviewItemEvent.OnServerEvent:Connect(function(player: Player, cosmeticId: string, action: string)
	if action == "start" then
		ShopController:StartPreview(player, cosmeticId)
	elseif action == "cancel" then
		ShopController:CancelPreview(player)
	end
end)

-- Apply cosmetics when character spawns
Players.PlayerAdded:Connect(function(player: Player)
	player.CharacterAdded:Connect(function(character: Model)
		-- Wait for character to fully load
		task.wait(0.5)
		ShopController:ApplyEquippedCosmetics(player)
	end)
end)

-- ============================================================================
-- INITIALIZATION
-- ============================================================================

function ShopController:Init()
	print("[ShopController] Initialized")
	
	-- Apply cosmetics to existing players (hot reload)
	for _, player in ipairs(Players:GetPlayers()) do
		if player.Character then
			ShopController:ApplyEquippedCosmetics(player)
		end
	end
end

return ShopController
--!strict
-- ShopUI.lua
-- Client-side cosmetic shop interface
-- Location: StarterPlayerScripts/Modules/ShopUI.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage.Shared.Config)

-- RemoteEvents
local EconomyEvents = ReplicatedStorage:WaitForChild("EconomyEvents")
local GetBalance = EconomyEvents:WaitForChild("GetBalance") :: RemoteFunction
local ShopEvents = ReplicatedStorage:WaitForChild("ShopEvents")
local GamepassOwnedEvent = ShopEvents:WaitForChild("GamepassOwned")

local ShopUI = {}

-- ============================================================================
-- UI CREATION
-- ============================================================================

local screenGui = player.PlayerGui:FindFirstChild("EndlessEscapeUI") :: ScreenGui
if not screenGui then
	screenGui = Instance.new("ScreenGui")
	screenGui.Name = "EndlessEscapeUI"
	screenGui.ResetOnSpawn = false
	screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	screenGui.Parent = player.PlayerGui
end

-- Main shop frame
local shopFrame = Instance.new("Frame")
shopFrame.Name = "CosmeticShop"
shopFrame.Size = UDim2.new(0, 500, 0, 450)
shopFrame.Position = UDim2.new(0.5, -250, 0.5, -225)
shopFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
shopFrame.BorderSizePixel = 0
shopFrame.Visible = false
shopFrame.ZIndex = 100
shopFrame.Parent = screenGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 16)
corner.Parent = shopFrame

local stroke = Instance.new("UIStroke")
stroke.Color = Color3.fromRGB(80, 80, 160)
stroke.Thickness = 3
stroke.Parent = shopFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 50)
title.Position = UDim2.new(0, 0, 0, 15)
title.BackgroundTransparency = 1
title.Text = "🛍️ COSMETIC SHOP"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.TextSize = 28
title.Font = Enum.Font.GothamBlack
title.ZIndex = 101
title.Parent = shopFrame

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "Close"
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 10)
closeBtn.BackgroundTransparency = 1
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
closeBtn.TextSize = 28
closeBtn.Font = Enum.Font.GothamBold
closeBtn.ZIndex = 101
closeBtn.Parent = shopFrame

-- Coin display
local coinDisplay = Instance.new("TextLabel")
coinDisplay.Name = "CoinDisplay"
coinDisplay.Size = UDim2.new(0, 200, 0, 35)
coinDisplay.Position = UDim2.new(0, 20, 0, 20)
coinDisplay.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
coinDisplay.Text = "🪙 0"
coinDisplay.TextColor3 = Color3.fromRGB(255, 215, 0)
coinDisplay.TextSize = 20
coinDisplay.Font = Enum.Font.GothamBold
bcoinDisplay.ZIndex = 101
coinDisplay.Parent = shopFrame

local coinCorner = Instance.new("UICorner")
coinCorner.CornerRadius = UDim.new(0, 8)
coinCorner.Parent = coinDisplay

-- Tab buttons (Trails / Hats)
local trailsTab = Instance.new("TextButton")
trailsTab.Name = "TrailsTab"
trailsTab.Size = UDim2.new(0, 120, 0, 35)
trailsTab.Position = UDim2.new(0, 30, 0, 70)
trailsTab.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
trailsTab.Text = "Trails"
trailsTab.TextColor3 = Color3.new(1, 1, 1)
trailsTab.TextSize = 16
trailsTab.Font = Enum.Font.GothamBold
trailsTab.ZIndex = 101
trailsTab.Parent = shopFrame

local hatsTab = Instance.new("TextButton")
hatsTab.Name = "HatsTab"
hatsTab.Size = UDim2.new(0, 120, 0, 35)
hatsTab.Position = UDim2.new(0, 160, 0, 70)
hatsTab.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
hatsTab.Text = "Hats"
hatsTab.TextColor3 = Color3.fromRGB(180, 180, 180)
hatsTab.TextSize = 16
hatsTab.Font = Enum.Font.GothamBold
hatsTab.ZIndex = 101
hatsTab.Parent = shopFrame

local tabCorner1 = Instance.new("UICorner")
tabCorner1.CornerRadius = UDim.new(0, 8)
tabCorner1.Parent = trailsTab

local tabCorner2 = Instance.new("UICorner")
tabCorner2.CornerRadius = UDim.new(0, 8)
tabCorner2.Parent = hatsTab

-- Scrolling item list
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "ItemList"
scrollFrame.Size = UDim2.new(1, -40, 0, 320)
scrollFrame.Position = UDim2.new(0, 20, 0, 115)
scrollFrame.BackgroundColor3 = Color3.fromRGB(25, 25, 45)
scrollFrame.BorderSizePixel = 0
scrollFrame.ScrollBarThickness = 6
scrollFrame.ZIndex = 101
scrollFrame.Parent = shopFrame

local scrollCorner = Instance.new("UICorner")
scrollCorner.CornerRadius = UDim.new(0, 12)
scrollCorner.Parent = scrollFrame

-- Grid layout
local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 130, 0, 140)
gridLayout.CellPadding = UDim2.new(0, 10, 0, 10)
gridLayout.SortOrder = Enum.SortOrder.Name
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Center
gridLayout.Parent = scrollFrame

-- ============================================================================
-- STATE
-- ============================================================================

local currentTab = "Trails"
local currentCoins = 0
local ownedItems: {[string]: boolean} = {}

-- ============================================================================
-- ITEM CREATION
-- ============================================================================

local function createItemCard(itemId: string, item: typeof(Config.Cosmetics.Trails.Fire)): Frame
	local card = Instance.new("Frame")
	card.Name = itemId
	card.Size = UDim2.new(0, 130, 0, 140)
	card.BackgroundColor3 = Color3.fromRGB(50, 50, 80)
	card.BorderSizePixel = 0
	card.ZIndex = 102
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 10)
	cardCorner.Parent = card
	
	-- Preview area (colored square representing the item)
	local preview = Instance.new("Frame")
	preview.Name = "Preview"
	preview.Size = UDim2.new(0, 80, 0, 60)
	preview.Position = UDim2.new(0.5, -40, 0, 15)
	preview.BorderSizePixel = 0
	preview.ZIndex = 103
	preview.Parent = card
	
	local previewCorner = Instance.new("UICorner")
	previewCorner.CornerRadius = UDim.new(0, 8)
	previewCorner.Parent = preview
	
	-- Set color based on item type
	if item.type == "trail" then
		if itemId == "fire" then
			preview.BackgroundColor3 = Color3.fromRGB(255, 100, 50)
		elseif itemId == "ice" then
			preview.BackgroundColor3 = Color3.fromRGB(100, 200, 255)
		elseif itemId == "lightning" then
			preview.BackgroundColor3 = Color3.fromRGB(255, 255, 100)
		elseif itemId == "galaxy" then
			preview.BackgroundColor3 = Color3.fromRGB(150, 100, 255)
		elseif itemId == "ghost" then
			preview.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
		elseif itemId == "golden" then
			preview.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
		else
			preview.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
		end
	else -- hat
		preview.BackgroundColor3 = Color3.fromRGB(180, 120, 80)
	end
	
	-- Glow effect for owned items
	local glow = Instance.new("UIStroke")
	glow.Color = Color3.fromRGB(100, 255, 100)
	glow.Thickness = 0 -- Hidden by default
	glow.Parent = card
	
	-- Name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, -10, 0, 25)
	nameLabel.Position = UDim2.new(0, 5, 0, 80)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = item.name
	nameLabel.TextColor3 = Color3.new(1, 1, 1)
	nameLabel.TextSize = 14
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.TextWrapped = true
	nameLabel.ZIndex = 103
	nameLabel.Parent = card
	
	-- Price button
	local buyBtn = Instance.new("TextButton")
	buyBtn.Name = "BuyBtn"
	buyBtn.Size = UDim2.new(0, 110, 0, 25)
	buyBtn.Position = UDim2.new(0.5, -55, 0, 108)
	buyBtn.BackgroundColor3 = Color3.fromRGB(0, 150, 80)
	buyBtn.Text = tostring(item.cost) .. " 🪙"
	buyBtn.TextColor3 = Color3.new(1, 1, 1)
	buyBtn.TextSize = 14
	buyBtn.Font = Enum.Font.GothamBold
	buyBtn.ZIndex = 103
	buyBtn.Parent = card
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 6)
	btnCorner.Parent = buyBtn
	
	-- Check if owned and update display
	if ownedItems[itemId] then
		buyBtn.Text = "OWNED"
		buyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
		buyBtn.AutoButtonColor = false
		glow.Thickness = 2
	elseif currentCoins < item.cost then
		buyBtn.BackgroundColor3 = Color3.fromRGB(150, 50, 50)
	end
	
	-- Click handler
	buyBtn.MouseButton1Click:Connect(function()
		if ownedItems[itemId] then return end
		
		-- Attempt purchase via server
		local success = pcall(function()
			-- This would call a remote function in full implementation
			-- For now, simulate
			if currentCoins >= item.cost then
				currentCoins -= item.cost
				ownedItems[itemId] = true
				
				-- Update UI
				buyBtn.Text = "OWNED"
				buyBtn.BackgroundColor3 = Color3.fromRGB(80, 80, 80)
				buyBtn.AutoButtonColor = false
				glow.Thickness = 2
				coinDisplay.Text = "🪙 " .. tostring(currentCoins)
				
				-- Show success popup
				ShopUI:ShowPurchasePopup(item.name)
			end
		end)
	end)
	
	return card
end

-- ============================================================================
-- POPULATE SHOP
-- ============================================================================

local function clearItems()
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
end

local function populateTrails()
	clearItems()
	for itemId, item in pairs(Config.Cosmetics.Trails) do
		local card = createItemCard(itemId, item)
		card.Parent = scrollFrame
	end
end

local function populateHats()
	clearItems()
	for itemId, item in pairs(Config.Cosmetics.Hats) do
		local card = createItemCard(itemId, item)
		card.Parent = scrollFrame
	end
end

local function refreshDisplay()
	if currentTab == "Trails" then
		populateTrails()
	else
		populateHats()
	end
end

-- ============================================================================
-- GAMEPASSES SECTION
-- ============================================================================

local function createGamepassSection()
	local gpFrame = Instance.new("Frame")
	gpFrame.Name = "Gamepasses"
	gpFrame.Size = UDim2.new(1, -40, 0, 120)
	gpFrame.Position = UDim2.new(0, 20, 1, -130)
	gpFrame.BackgroundColor3 = Color3.fromRGB(35, 35, 60)
	gpFrame.BorderSizePixel = 0
	gpFrame.ZIndex = 101
	gpFrame.Parent = shopFrame
	
	local gpCorner = Instance.new("UICorner")
	gpCorner.CornerRadius = UDim.new(0, 10)
	gpCorner.Parent = gpFrame
	
	local gpTitle = Instance.new("TextLabel")
	gpTitle.Size = UDim2.new(1, 0, 0, 25)
	gpTitle.Position = UDim2.new(0, 0, 0, 5)
	gpTitle.BackgroundTransparency = 1
	gpTitle.Text = "💎 GAMEPASSES"
	gpTitle.TextColor3 = Color3.fromRGB(200, 150, 255)
	gpTitle.TextSize = 16
	gpTitle.Font = Enum.Font.GothamBold
	gpTitle.ZIndex = 102
	gpTitle.Parent = gpFrame
	
	-- 2x Coins
	local doubleCoins = Instance.new("TextButton")
	doubleCoins.Size = UDim2.new(0, 140, 0, 45)
	doubleCoins.Position = UDim2.new(0, 15, 0, 35)
	doubleCoins.BackgroundColor3 = Color3.fromRGB(80, 60, 120)
	doubleCoins.Text = "2x Coins\n99 R$"
	doubleCoins.TextColor3 = Color3.new(1, 1, 1)
	doubleCoins.TextSize = 14
	doubleCoins.Font = Enum.Font.GothamBold
	doubleCoins.ZIndex = 102
	doubleCoins.Parent = gpFrame
	
	local dcCorner = Instance.new("UICorner")
	dcCorner.CornerRadius = UDim.new(0, 8)
	dcCorner.Parent = doubleCoins
	
	-- VIP
	local vipBtn = Instance.new("TextButton")
	vipBtn.Size = UDim2.new(0, 140, 0, 45)
	vipBtn.Position = UDim2.new(0, 170, 0, 35)
	vipBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 60)
	vipBtn.Text = "VIP Trail\n149 R$"
	vipBtn.TextColor3 = Color3.new(1, 1, 1)
	vipBtn.TextSize = 14
	vipBtn.Font = Enum.Font.GothamBold
	vipBtn.ZIndex = 102
	vipBtn.Parent = gpFrame
	
	local vipCorner = Instance.new("UICorner")
	vipCorner.CornerRadius = UDim.new(0, 8)
	vipCorner.Parent = vipBtn
	
	-- Radio
	local radioBtn = Instance.new("TextButton")
	radioBtn.Size = UDim2.new(0, 140, 0, 45)
	radioBtn.Position = UDim2.new(0, 15, 0, 85)
	radioBtn.BackgroundColor3 = Color3.fromRGB(60, 80, 120)
	radioBtn.Text = "Radio\n49 R$"
	radioBtn.TextColor3 = Color3.new(1, 1, 1)
	radioBtn.TextSize = 14
	radioBtn.Font = Enum.Font.GothamBold
	radioBtn.ZIndex = 102
	radioBtn.Parent = gpFrame
	
	local radioCorner = Instance.new("UICorner")
	radioCorner.CornerRadius = UDim.new(0, 8)
	radioCorner.Parent = radioBtn
	
	-- Click handlers (prompt purchase)
	doubleCoins.MouseButton1Click:Connect(function()
		local MarketplaceService = game:GetService("MarketplaceService")
		MarketplaceService:PromptGamePassPurchase(player, Config.Gamepasses.DoubleCoins.id)
	end)
	
	vipBtn.MouseButton1Click:Connect(function()
		local MarketplaceService = game:GetService("MarketplaceService")
		MarketplaceService:PromptGamePassPurchase(player, Config.Gamepasses.VIPTrail.id)
	end)
	
	radioBtn.MouseButton1Click:Connect(function()
		local MarketplaceService = game:GetService("MarketplaceService")
		MarketplaceService:PromptGamePassPurchase(player, Config.Gamepasses.Radio.id)
	end)
end

createGamepassSection()

-- ============================================================================
-- POPUP
-- ============================================================================

local popupFrame = Instance.new("Frame")
popupFrame.Name = "PurchasePopup"
popupFrame.Size = UDim2.new(0, 250, 0, 100)
popupFrame.Position = UDim2.new(0.5, -125, 0.5, -50)
popupFrame.BackgroundColor3 = Color3.fromRGB(40, 100, 60)
popupFrame.BorderSizePixel = 0
popupFrame.Visible = false
popupFrame.ZIndex = 200
popupFrame.Parent = shopFrame

local popupCorner = Instance.new("UICorner")
popupCorner.CornerRadius = UDim.new(0, 12)
popupCorner.Parent = popupFrame

local popupText = Instance.new("TextLabel")
popupText.Size = UDim2.new(1, 0, 0, 60)
popupText.Position = UDim2.new(0, 0, 0, 10)
popupText.BackgroundTransparency = 1
popupText.Text = "Purchased!"
popupText.TextColor3 = Color3.new(1, 1, 1)
popupText.TextSize = 20
popupText.Font = Enum.Font.GothamBold
popupText.ZIndex = 201
popupText.Parent = popupFrame

local popupClose = Instance.new("TextButton")
popupClose.Size = UDim2.new(0, 80, 0, 25)
popupClose.Position = UDim2.new(0.5, -40, 1, -35)
popupClose.BackgroundColor3 = Color3.fromRGB(60, 150, 80)
popupClose.Text = "OK"
popupClose.TextColor3 = Color3.new(1, 1, 1)
popupClose.TextSize = 14
popupClose.Font = Enum.Font.GothamBold
popupClose.ZIndex = 201
popupClose.Parent = popupFrame

local pcCorner = Instance.new("UICorner")
pcCorner.CornerRadius = UDim.new(0, 6)
pcCorner.Parent = popupClose

function ShopUI:ShowPurchasePopup(itemName: string)
	popupText.Text = "✓ " .. itemName .. " purchased!"
	popupFrame.Visible = true
	
	task.delay(2, function()
		popupFrame.Visible = false
	end)
end

popupClose.MouseButton1Click:Connect(function()
	popupFrame.Visible = false
end)

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

trailsTab.MouseButton1Click:Connect(function()
	currentTab = "Trails"
	trailsTab.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
	trailsTab.TextColor3 = Color3.new(1, 1, 1)
	hatsTab.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
	hatsTab.TextColor3 = Color3.fromRGB(180, 180, 180)
	populateTrails()
end)

hatsTab.MouseButton1Click:Connect(function()
	currentTab = "Hats"
	hatsTab.BackgroundColor3 = Color3.fromRGB(60, 60, 100)
	hatsTab.TextColor3 = Color3.new(1, 1, 1)
	trailsTab.BackgroundColor3 = Color3.fromRGB(40, 40, 70)
	trailsTab.TextColor3 = Color3.fromRGB(180, 180, 180)
	populateHats()
end)

closeBtn.MouseButton1Click:Connect(function()
	shopFrame.Visible = false
end)

-- Gamepass purchase feedback
GamepassOwnedEvent.OnClientEvent:Connect(function(passType, data)
	ShopUI:ShowPurchasePopup(passType .. " unlocked!")
end)

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function ShopUI:Show()
	currentCoins = GetBalance:InvokeServer()
	coinDisplay.Text = "🪙 " .. tostring(currentCoins)
	refreshDisplay()
	shopFrame.Visible = true
end

function ShopUI:Hide()
	shopFrame.Visible = false
end

function ShopUI:Toggle()
	if shopFrame.Visible then
		ShopUI:Hide()
	else
		ShopUI:Show()
	end
end

-- Initial population
populateTrails()

return ShopUI

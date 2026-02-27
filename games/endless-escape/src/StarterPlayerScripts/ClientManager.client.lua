--!strict
-- ClientManager.client.lua
-- Main client controller: UI, input, death screen, HUD
-- Location: StarterPlayerScripts/ClientManager.client.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local StarterGui = game:GetService("StarterGui")

local player = Players.LocalPlayer
local Config = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Config"))
local SoundManager = require(ReplicatedStorage:WaitForChild("Modules"):WaitForChild("SoundManager"))

-- Wait for remote events
local GameEvents = ReplicatedStorage:WaitForChild("GameEvents")
local StartRunEvent = GameEvents:WaitForChild("StartRun")
local RespawnEvent = GameEvents:WaitForChild("Respawn")
local DistanceUpdateEvent = GameEvents:WaitForChild("DistanceUpdate")
local DeathScreenDataEvent = GameEvents:WaitForChild("DeathScreenData")
local CollectCoinEvent = GameEvents:WaitForChild("CollectCoin")

local EconomyEvents = ReplicatedStorage:WaitForChild("EconomyEvents")
local CoinAddedEvent = EconomyEvents:WaitForChild("CoinAdded")
local CoinsSpentEvent = EconomyEvents:WaitForChild("CoinsSpent")

local ShopEvents = ReplicatedStorage:WaitForChild("ShopEvents")
local PurchaseSuccessEvent = ShopEvents:WaitForChild("PurchaseSuccess")

local DailyEvents = ReplicatedStorage:WaitForChild("DailyEvents")
local RewardClaimedEvent = DailyEvents:WaitForChild("RewardClaimed")

-- ============================================================================
-- STATE
-- ============================================================================

local isInRun = false
local currentDistance = 0
local personalBest = 0
local coins = 0
local deathScreenVisible = false

-- ============================================================================
-- UI CREATION
-- ============================================================================

local screenGui = Instance.new("ScreenGui")
screenGui.Name = "EndlessEscapeUI"
screenGui.ResetOnSpawn = false
screenGui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
screenGui.Parent = player.PlayerGui

-- === HUD (always visible during run) ===

local hudFrame = Instance.new("Frame")
hudFrame.Name = "HUD"
hudFrame.Size = UDim2.new(1, 0, 0, 80)
hudFrame.Position = UDim2.new(0, 0, 0, 0)
hudFrame.BackgroundTransparency = 1
hudFrame.Visible = false
hudFrame.Parent = screenGui

-- Distance counter (big, center top)
local distLabel = Instance.new("TextLabel")
distLabel.Name = "Distance"
distLabel.Size = UDim2.new(0, 300, 0, 60)
distLabel.Position = UDim2.new(0.5, -150, 0, 10)
distLabel.BackgroundTransparency = 1
distLabel.Text = "0m"
distLabel.TextColor3 = Color3.new(1, 1, 1)
distLabel.TextSize = 48
distLabel.Font = Enum.Font.GothamBlack
distLabel.TextStrokeTransparency = 0.3
distLabel.Parent = hudFrame

-- Personal best (smaller, below distance)
local bestLabel = Instance.new("TextLabel")
bestLabel.Name = "Best"
bestLabel.Size = UDim2.new(0, 200, 0, 20)
bestLabel.Position = UDim2.new(0.5, -100, 0, 60)
bestLabel.BackgroundTransparency = 1
bestLabel.Text = "Best: 0m"
bestLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
bestLabel.TextSize = 16
bestLabel.Font = Enum.Font.Gotham
bestLabel.TextStrokeTransparency = 0.5
bestLabel.Parent = hudFrame

-- Coins (top right)
local coinLabel = Instance.new("TextLabel")
coinLabel.Name = "Coins"
coinLabel.Size = UDim2.new(0, 150, 0, 40)
coinLabel.Position = UDim2.new(1, -160, 0, 15)
coinLabel.BackgroundTransparency = 1
coinLabel.Text = "🪙 0"
coinLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinLabel.TextSize = 28
coinLabel.Font = Enum.Font.GothamBold
coinLabel.TextXAlignment = Enum.TextXAlignment.Right
coinLabel.TextStrokeTransparency = 0.3
coinLabel.Parent = hudFrame

-- === DEATH SCREEN ===

local deathFrame = Instance.new("Frame")
deathFrame.Name = "DeathScreen"
deathFrame.Size = UDim2.new(1, 0, 1, 0)
deathFrame.BackgroundColor3 = Color3.new(0, 0, 0)
deathFrame.BackgroundTransparency = 0.3
deathFrame.Visible = false
deathFrame.ZIndex = 10
deathFrame.Parent = screenGui

-- "YOU DIED" title
local diedTitle = Instance.new("TextLabel")
diedTitle.Size = UDim2.new(0, 400, 0, 60)
diedTitle.Position = UDim2.new(0.5, -200, 0.1, 0)
diedTitle.BackgroundTransparency = 1
diedTitle.Text = "💀 YOU DIED!"
diedTitle.TextColor3 = Color3.fromRGB(255, 80, 80)
diedTitle.TextSize = 48
diedTitle.Font = Enum.Font.GothamBlack
diedTitle.ZIndex = 11
diedTitle.Parent = deathFrame

-- Distance on death
local deathDistLabel = Instance.new("TextLabel")
deathDistLabel.Size = UDim2.new(0, 300, 0, 30)
deathDistLabel.Position = UDim2.new(0.5, -150, 0.18, 0)
deathDistLabel.BackgroundTransparency = 1
deathDistLabel.Text = "Distance: 0m"
deathDistLabel.TextColor3 = Color3.new(1, 1, 1)
deathDistLabel.TextSize = 24
deathDistLabel.Font = Enum.Font.GothamBold
deathDistLabel.ZIndex = 11
deathDistLabel.Parent = deathFrame

-- Badge (e.g. "SO CLOSE!")
local badgeLabel = Instance.new("TextLabel")
badgeLabel.Name = "Badge"
badgeLabel.Size = UDim2.new(0, 300, 0, 30)
badgeLabel.Position = UDim2.new(0.5, -150, 0.23, 0)
badgeLabel.BackgroundTransparency = 1
badgeLabel.Text = ""
badgeLabel.TextColor3 = Color3.fromRGB(255, 200, 0)
badgeLabel.TextSize = 22
badgeLabel.Font = Enum.Font.GothamBold
badgeLabel.ZIndex = 11
badgeLabel.Parent = deathFrame

-- Product buttons container
local productsFrame = Instance.new("Frame")
productsFrame.Name = "Products"
productsFrame.Size = UDim2.new(0, 400, 0, 250)
productsFrame.Position = UDim2.new(0.5, -200, 0.32, 0)
productsFrame.BackgroundTransparency = 1
productsFrame.ZIndex = 11
productsFrame.Parent = deathFrame

-- Helper: create product button
local function createProductButton(name: string, icon: string, price: number, yPos: number, row: number): TextButton
	local btn = Instance.new("TextButton")
	btn.Name = name
	btn.Size = UDim2.new(0, 185, 0, 70)
	btn.Position = UDim2.new(row == 1 and 0 or 0.5, row == 1 and 0 or 10, 0, yPos)
	btn.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
	btn.Text = icon .. "\n" .. tostring(price) .. " R$"
	btn.TextColor3 = Color3.new(1, 1, 1)
	btn.TextSize = 22
	btn.Font = Enum.Font.GothamBold
	btn.ZIndex = 12
	btn.Parent = productsFrame
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = btn
	
	local stroke = Instance.new("UIStroke")
	stroke.Color = Color3.fromRGB(80, 80, 160)
	stroke.Thickness = 2
	stroke.Parent = btn
	
	return btn
end

-- Row 1: Shield + Speed (15R each)
local shieldBtn = createProductButton("Shield", "🛡️", 15, 0, 1)
local speedBtn = createProductButton("Speed", "⚡", 15, 0, 2)

-- Row 2: Skip + Revive (25R each)
local skipBtn = createProductButton("Skip", "🏃", 25, 80, 1)
local reviveBtn = createProductButton("Revive", "💀", 25, 80, 2)

-- Row 3: Coin pack (small, centered)
local coinPackBtn = Instance.new("TextButton")
coinPackBtn.Name = "CoinPack"
coinPackBtn.Size = UDim2.new(0, 380, 0, 40)
coinPackBtn.Position = UDim2.new(0, 10, 0, 165)
coinPackBtn.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
coinPackBtn.Text = "🪙 50 Coins — 5 R$"
coinPackBtn.TextColor3 = Color3.fromRGB(200, 200, 200)
coinPackBtn.TextSize = 18
coinPackBtn.Font = Enum.Font.Gotham
coinPackBtn.ZIndex = 12
coinPackBtn.Parent = productsFrame
local coinCorner = Instance.new("UICorner")
coinCorner.CornerRadius = UDim.new(0, 8)
coinCorner.Parent = coinPackBtn

-- "No thanks" dismiss button (small, bottom)
local dismissBtn = Instance.new("TextButton")
dismissBtn.Name = "Dismiss"
dismissBtn.Size = UDim2.new(0, 150, 0, 30)
dismissBtn.Position = UDim2.new(0.5, -75, 0.85, 0)
dismissBtn.BackgroundTransparency = 1
dismissBtn.Text = "No thanks →"
dismissBtn.TextColor3 = Color3.fromRGB(120, 120, 120)
dismissBtn.TextSize = 14
dismissBtn.Font = Enum.Font.Gotham
dismissBtn.ZIndex = 12
dismissBtn.Parent = deathFrame

-- === LOBBY / START BUTTON ===

local lobbyFrame = Instance.new("Frame")
lobbyFrame.Name = "Lobby"
lobbyFrame.Size = UDim2.new(1, 0, 1, 0)
lobbyFrame.BackgroundTransparency = 1
lobbyFrame.Visible = true
lobbyFrame.ZIndex = 5
lobbyFrame.Parent = screenGui

local startBtn = Instance.new("TextButton")
startBtn.Name = "Start"
startBtn.Size = UDim2.new(0, 300, 0, 80)
startBtn.Position = UDim2.new(0.5, -150, 0.7, 0)
startBtn.BackgroundColor3 = Color3.fromRGB(0, 180, 80)
startBtn.Text = "▶ PLAY"
startBtn.TextColor3 = Color3.new(1, 1, 1)
startBtn.TextSize = 36
startBtn.Font = Enum.Font.GothamBlack
startBtn.ZIndex = 6
startBtn.Parent = lobbyFrame
local startCorner = Instance.new("UICorner")
startCorner.CornerRadius = UDim.new(0, 16)
startCorner.Parent = startBtn

-- Title
local titleLabel = Instance.new("TextLabel")
titleLabel.Size = UDim2.new(0, 500, 0, 80)
titleLabel.Position = UDim2.new(0.5, -250, 0.15, 0)
titleLabel.BackgroundTransparency = 1
titleLabel.Text = "ENDLESS ESCAPE"
titleLabel.TextColor3 = Color3.new(1, 1, 1)
titleLabel.TextSize = 56
titleLabel.Font = Enum.Font.GothamBlack
titleLabel.TextStrokeTransparency = 0
titleLabel.ZIndex = 6
titleLabel.Parent = lobbyFrame

-- === COIN POPUP (shows +coins earned) ===

local function showCoinPopup(amount: number, source: string)
	local popup = Instance.new("TextLabel")
	popup.Size = UDim2.new(0, 200, 0, 30)
	popup.Position = UDim2.new(0.5, -100, 0.4, 0)
	popup.BackgroundTransparency = 1
	popup.Text = "+ " .. tostring(amount) .. " 🪙"
	popup.TextColor3 = Color3.fromRGB(255, 215, 0)
	popup.TextSize = 24
	popup.Font = Enum.Font.GothamBold
	popup.TextStrokeTransparency = 0.3
	popup.ZIndex = 20
	popup.Parent = screenGui

	local tween = TweenService:Create(popup, TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out), {
		Position = UDim2.new(0.5, -100, 0.3, 0),
		TextTransparency = 1,
		TextStrokeTransparency = 1,
	})
	tween:Play()
	tween.Completed:Connect(function()
		popup:Destroy()
	end)
end

-- ============================================================================
-- EVENT HANDLERS
-- ============================================================================

-- Start run
startBtn.MouseButton1Click:Connect(function()
	lobbyFrame.Visible = false
	hudFrame.Visible = true
	isInRun = true
	currentDistance = 0
	distLabel.Text = "0m"
	StartRunEvent:FireServer()
end)

-- Lucky Spin button (in lobby)
local spinBtn = Instance.new("TextButton")
spinBtn.Name = "SpinBtn"
spinBtn.Size = UDim2.new(0, 200, 0, 50)
spinBtn.Position = UDim2.new(0.5, -100, 0.7, 90)
spinBtn.BackgroundColor3 = Color3.fromRGB(120, 80, 180)
spinBtn.Text = "🎰 Lucky Spin"
spinBtn.TextColor3 = Color3.new(1, 1, 1)
spinBtn.TextSize = 20
spinBtn.Font = Enum.Font.GothamBold
spinBtn.ZIndex = 6
spinBtn.Parent = lobbyFrame
local spinCorner = Instance.new("UICorner")
spinCorner.CornerRadius = UDim.new(0, 12)
spinCorner.Parent = spinBtn

-- Load modules
local LuckySpinUI = require(script.Parent:WaitForChild("Modules"):WaitForChild("LuckySpinUI"))
local ShopUI = require(script.Parent:WaitForChild("Modules"):WaitForChild("ShopUI"))
local LeaderboardUI = require(script.Parent:WaitForChild("Modules"):WaitForChild("LeaderboardUI"))

spinBtn.MouseButton1Click:Connect(function()
	LuckySpinUI:Show()
end)

-- Shop button
local shopBtn = Instance.new("TextButton")
shopBtn.Name = "ShopBtn"
shopBtn.Size = UDim2.new(0, 200, 0, 50)
shopBtn.Position = UDim2.new(0.5, -100, 0.7, 150)
shopBtn.BackgroundColor3 = Color3.fromRGB(180, 120, 60)
shopBtn.Text = "🛍️ Shop"
shopBtn.TextColor3 = Color3.new(1, 1, 1)
shopBtn.TextSize = 20
shopBtn.Font = Enum.Font.GothamBold
shopBtn.ZIndex = 6
shopBtn.Parent = lobbyFrame
local shopCorner = Instance.new("UICorner")
shopCorner.CornerRadius = UDim.new(0, 12)
shopCorner.Parent = shopBtn

shopBtn.MouseButton1Click:Connect(function()
	ShopUI:Show()
end)

-- Leaderboard button
local lbBtn = Instance.new("TextButton")
lbBtn.Name = "LeaderboardBtn"
lbBtn.Size = UDim2.new(0, 200, 0, 50)
lbBtn.Position = UDim2.new(0.5, -100, 0.7, 210)
lbBtn.BackgroundColor3 = Color3.fromRGB(80, 100, 180)
lbBtn.Text = "🏆 Leaderboard"
lbBtn.TextColor3 = Color3.new(1, 1, 1)
lbBtn.TextSize = 20
lbBtn.Font = Enum.Font.GothamBold
lbBtn.ZIndex = 6
lbBtn.Parent = lobbyFrame
local lbCorner = Instance.new("UICorner")
lbCorner.CornerRadius = UDim.new(0, 12)
lbCorner.Parent = lbBtn

lbBtn.MouseButton1Click:Connect(function()
	LeaderboardUI:Show()
end)

-- Distance updates from server
DistanceUpdateEvent.OnClientEvent:Connect(function(distance: number)
	currentDistance = distance
	distLabel.Text = tostring(math.floor(distance)) .. "m"
	
	-- Check for milestone sounds
	SoundManager:CheckMilestones(distance)
end)

-- Death screen
DeathScreenDataEvent.OnClientEvent:Connect(function(context)
	deathScreenVisible = true
	deathFrame.Visible = true
	hudFrame.Visible = false
	isInRun = false
	
	-- Reset milestone tracking for next run
	SoundManager:ResetMilestones()

	deathDistLabel.Text = "Distance: " .. tostring(math.floor(context.distance)) .. "m"
	
	if context.distance > personalBest then
		personalBest = context.distance
		bestLabel.Text = "Best: " .. tostring(math.floor(personalBest)) .. "m"
		badgeLabel.Text = "🏆 NEW PERSONAL BEST!"
	elseif context.badge then
		badgeLabel.Text = context.badge
	else
		badgeLabel.Text = ""
	end

	productsFrame.Visible = context.showProducts

	-- Highlight specific product
	if context.highlightProduct then
		-- Reset all buttons
		shieldBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
		speedBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
		skipBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
		reviveBtn.BackgroundColor3 = Color3.fromRGB(40, 40, 80)

		-- Highlight the recommended one
		local highlights: {[string]: TextButton} = {
			ShieldBubble = shieldBtn,
			SpeedBoost = speedBtn,
			SkipAhead = skipBtn,
			InstantRevive = reviveBtn,
		}
		local btn = highlights[context.highlightProduct]
		if btn then
			btn.BackgroundColor3 = Color3.fromRGB(60, 60, 140)
		end
	end
end)

-- Dismiss death screen → respawn
dismissBtn.MouseButton1Click:Connect(function()
	deathFrame.Visible = false
	hudFrame.Visible = true
	deathScreenVisible = false
	RespawnEvent:FireServer(false)
end)

-- Revive button → respawn with revive
reviveBtn.MouseButton1Click:Connect(function()
	-- Prompt Roblox purchase
	local MarketplaceService = game:GetService("MarketplaceService")
	MarketplaceService:PromptProductPurchase(player, Config.DevProducts.InstantRevive.id)
end)

-- Other product buttons → prompt purchase
shieldBtn.MouseButton1Click:Connect(function()
	local MarketplaceService = game:GetService("MarketplaceService")
	MarketplaceService:PromptProductPurchase(player, Config.DevProducts.ShieldBubble.id)
end)

speedBtn.MouseButton1Click:Connect(function()
	local MarketplaceService = game:GetService("MarketplaceService")
	MarketplaceService:PromptProductPurchase(player, Config.DevProducts.SpeedBoost.id)
end)

skipBtn.MouseButton1Click:Connect(function()
	local MarketplaceService = game:GetService("MarketplaceService")
	MarketplaceService:PromptProductPurchase(player, Config.DevProducts.SkipAhead.id)
end)

coinPackBtn.MouseButton1Click:Connect(function()
	local MarketplaceService = game:GetService("MarketplaceService")
	MarketplaceService:PromptProductPurchase(player, Config.DevProducts.CoinPackSmall.id)
end)

-- Purchase success → close death screen and respawn
PurchaseSuccessEvent.OnClientEvent:Connect(function(productType, data)
	if productType == "InstantRevive" then
		deathFrame.Visible = false
		hudFrame.Visible = true
		deathScreenVisible = false
		RespawnEvent:FireServer(true)
	elseif productType == "ShieldUsed" then
		showCoinPopup(0, "Shield saved you!")
	end
end)

-- Coin updates
CoinAddedEvent.OnClientEvent:Connect(function(amount, total, source)
	coins = total
	coinLabel.Text = "🪙 " .. tostring(total)
	if amount > 0 then
		showCoinPopup(amount, source)
	end
end)

CoinsSpentEvent.OnClientEvent:Connect(function(amount, newBalance)
	coins = newBalance
	coinLabel.Text = "🪙 " .. tostring(newBalance)
end)

-- Daily reward popup
RewardClaimedEvent.OnClientEvent:Connect(function(data)
	local popup = Instance.new("TextLabel")
	popup.Size = UDim2.new(0, 350, 0, 50)
	popup.Position = UDim2.new(0.5, -175, 0.3, 0)
	popup.BackgroundColor3 = Color3.fromRGB(40, 40, 80)
	popup.Text = string.format("🔥 Day %d Streak! +%d coins%s", 
		data.day, data.coins, data.item and (" + " .. data.item) or "")
	popup.TextColor3 = Color3.fromRGB(255, 215, 0)
	popup.TextSize = 20
	popup.Font = Enum.Font.GothamBold
	popup.ZIndex = 25
	popup.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 12)
	corner.Parent = popup

	task.delay(4, function()
		local tween = TweenService:Create(popup, TweenInfo.new(1), {
			TextTransparency = 1,
			BackgroundTransparency = 1,
		})
		tween:Play()
		tween.Completed:Connect(function() popup:Destroy() end)
	end)
end)

-- ============================================================================
-- MOBILE JUMP (tap anywhere = jump)
-- ============================================================================

UserInputService.TouchTap:Connect(function()
	if not isInRun then return end
	if deathScreenVisible then return end
	local character = player.Character
	if not character then return end
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.Jump = true
	end
end)

-- Space bar jump (already default, but ensure it works)
UserInputService.InputBegan:Connect(function(input, processed)
	if processed then return end
	if not isInRun then return end
	if input.KeyCode == Enum.KeyCode.Space then
		local character = player.Character
		if not character then return end
		local humanoid = character:FindFirstChildOfClass("Humanoid")
		if humanoid then
			humanoid.Jump = true
		end
	end
end)

-- ============================================================================
-- COIN TOUCH DETECTION (client sends to server for validation)
-- ============================================================================

local function setupCoinCollection()
	local character = player.Character or player.CharacterAdded:Wait()
	local hrp = character:WaitForChild("HumanoidRootPart")
	
	hrp.Touched:Connect(function(part)
		if part.Name:sub(1, 5) == "Coin_" and part:GetAttribute("CoinValue") then
			CollectCoinEvent:FireServer(part)
		end
	end)
end

-- Setup on spawn
player.CharacterAdded:Connect(function()
	task.wait(1)
	setupCoinCollection()
end)
if player.Character then
	task.spawn(setupCoinCollection)
end

-- ============================================================================
-- INIT
-- ============================================================================

-- Fetch initial balance
local getBalance = EconomyEvents:WaitForChild("GetBalance") :: RemoteFunction
coins = getBalance:InvokeServer()
coinLabel.Text = "🪙 " .. tostring(coins)

-- Initialize SoundManager (client mode)
SoundManager:Init(false) -- false = client mode

print("[ClientManager] UI initialized with SoundManager")

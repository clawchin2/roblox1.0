-- Main UI Controller
-- Handles HUD, death screen with delayed monetization, shop

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Get RemoteEvents
local remotes = ReplicatedStorage:WaitForChild("GameRemotes")
local playerDiedEvent = remotes:WaitForChild("PlayerDied")
local requestRespawnEvent = remotes:WaitForChild("RequestRespawn")

-- State
local currentDistance = 0
local deathData = nil

-- Create Main UI
local mainUI = Instance.new("ScreenGui")
mainUI.Name = "MainUI"
mainUI.Parent = playerGui

-- ==================== HUD FRAME ====================
local hudFrame = Instance.new("Frame")
hudFrame.Name = "HUD"
hudFrame.Size = UDim2.new(1, 0, 1, 0)
hudFrame.BackgroundTransparency = 1
hudFrame.Parent = mainUI

-- Distance Display
local distanceLabel = Instance.new("TextLabel")
distanceLabel.Name = "DistanceLabel"
distanceLabel.Size = UDim2.new(0, 200, 0, 50)
distanceLabel.Position = UDim2.new(0.5, -100, 0, 20)
distanceLabel.BackgroundTransparency = 0.3
distanceLabel.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
distanceLabel.Text = "0m"
distanceLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
distanceLabel.TextScaled = true
distanceLabel.Font = Enum.Font.GothamBold
distanceLabel.Parent = hudFrame

-- Coins Display
local coinsFrame = Instance.new("Frame")
coinsFrame.Name = "CoinsFrame"
coinsFrame.Size = UDim2.new(0, 150, 0, 40)
coinsFrame.Position = UDim2.new(1, -160, 0, 20)
coinsFrame.BackgroundTransparency = 0.3
coinsFrame.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
coinsFrame.Parent = hudFrame

local coinsIcon = Instance.new("TextLabel")
coinsIcon.Name = "Icon"
coinsIcon.Size = UDim2.new(0, 30, 1, 0)
coinsIcon.BackgroundTransparency = 1
coinsIcon.Text = "🪙"
coinsIcon.TextScaled = true
coinsIcon.Parent = coinsFrame

local coinsLabel = Instance.new("TextLabel")
coinsLabel.Name = "CoinsLabel"
coinsLabel.Size = UDim2.new(1, -30, 1, 0)
coinsLabel.Position = UDim2.new(0, 30, 0, 0)
coinsLabel.BackgroundTransparency = 1
coinsLabel.Text = "0"
coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
coinsLabel.TextScaled = true
coinsLabel.Font = Enum.Font.GothamBold
coinsLabel.Parent = coinsFrame

-- Shop Button - Always visible and functional
local shopButton = Instance.new("TextButton")
shopButton.Name = "ShopButton"
shopButton.Size = UDim2.new(0, 100, 0, 40)
shopButton.Position = UDim2.new(1, -110, 0, 70)
shopButton.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
shopButton.Text = "SHOP"
shopButton.TextColor3 = Color3.fromRGB(255, 255, 255)
shopButton.TextScaled = true
shopButton.Font = Enum.Font.GothamBold
shopButton.Parent = hudFrame

-- ==================== SHOP FRAME ====================
local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.Size = UDim2.new(0, 500, 0, 400)
shopFrame.Position = UDim2.new(0.5, -250, 0.5, -200)
shopFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
shopFrame.Visible = false
shopFrame.Parent = mainUI

local shopTitle = Instance.new("TextLabel")
shopTitle.Name = "Title"
shopTitle.Size = UDim2.new(1, 0, 0, 50)
shopTitle.BackgroundTransparency = 1
shopTitle.Text = "SHOP"
shopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
shopTitle.TextScaled = true
shopTitle.Font = Enum.Font.GothamBold
shopTitle.Parent = shopFrame

local closeButton = Instance.new("TextButton")
closeButton.Name = "CloseButton"
closeButton.Size = UDim2.new(0, 40, 0, 40)
closeButton.Position = UDim2.new(1, -50, 0, 5)
closeButton.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
closeButton.Text = "X"
closeButton.TextColor3 = Color3.fromRGB(255, 255, 255)
closeButton.TextScaled = true
closeButton.Parent = shopFrame

-- Trails List
local trailsLabel = Instance.new("TextLabel")
trailsLabel.Name = "TrailsLabel"
trailsLabel.Size = UDim2.new(1, 0, 0, 30)
trailsLabel.Position = UDim2.new(0, 0, 0, 60)
trailsLabel.BackgroundTransparency = 1
trailsLabel.Text = "TRAILS"
trailsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
trailsLabel.TextScaled = true
trailsLabel.Parent = shopFrame

local trailsList = Instance.new("ScrollingFrame")
trailsList.Name = "TrailsList"
trailsList.Size = UDim2.new(1, -20, 0, 120)
trailsList.Position = UDim2.new(0, 10, 0, 100)
trailsList.BackgroundTransparency = 0.5
trailsList.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
trailsList.ScrollBarThickness = 5
trailsList.Parent = shopFrame

-- Skins List
local skinsLabel = Instance.new("TextLabel")
skinsLabel.Name = "SkinsLabel"
skinsLabel.Size = UDim2.new(1, 0, 0, 30)
skinsLabel.Position = UDim2.new(0, 0, 0, 230)
skinsLabel.BackgroundTransparency = 1
skinsLabel.Text = "SKINS"
skinsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
skinsLabel.TextScaled = true
skinsLabel.Parent = shopFrame

local skinsList = Instance.new("ScrollingFrame")
skinsList.Name = "SkinsList"
skinsList.Size = UDim2.new(1, -20, 0, 120)
skinsList.Position = UDim2.new(0, 10, 0, 270)
skinsList.BackgroundTransparency = 0.5
skinsList.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
skinsList.ScrollBarThickness = 5
skinsList.Parent = shopFrame

-- ==================== DEATH SCREEN ====================
local deathScreen = Instance.new("Frame")
deathScreen.Name = "DeathScreen"
deathScreen.Size = UDim2.new(1, 0, 1, 0)
deathScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
deathScreen.BackgroundTransparency = 0.4
deathScreen.Visible = false
deathScreen.Parent = mainUI

-- Main container for death screen content
local deathContent = Instance.new("Frame")
deathContent.Name = "DeathContent"
deathContent.Size = UDim2.new(0, 500, 0, 500)
deathContent.Position = UDim2.new(0.5, -250, 0.5, -250)
deathContent.BackgroundTransparency = 1
deathContent.Parent = deathScreen

-- "You Died" text
local deathText = Instance.new("TextLabel")
deathText.Name = "DeathText"
deathText.Size = UDim2.new(1, 0, 0, 80)
deathText.Position = UDim2.new(0, 0, 0, 0)
deathText.BackgroundTransparency = 1
deathText.Text = "YOU DIED"
deathText.TextColor3 = Color3.fromRGB(255, 100, 100)
deathText.TextScaled = true
deathText.Font = Enum.Font.GothamBold
deathText.Parent = deathContent

-- Distance display - "You ran: Xm"
local distanceDisplay = Instance.new("TextLabel")
distanceDisplay.Name = "DistanceDisplay"
distanceDisplay.Size = UDim2.new(1, 0, 0, 50)
distanceDisplay.Position = UDim2.new(0, 0, 0, 90)
distanceDisplay.BackgroundTransparency = 1
distanceDisplay.Text = "You ran: 0m"
distanceDisplay.TextColor3 = Color3.fromRGB(255, 255, 255)
distanceDisplay.TextScaled = true
distanceDisplay.Font = Enum.Font.GothamBold
distanceDisplay.Parent = deathContent

-- Best distance display
local bestDistanceDisplay = Instance.new("TextLabel")
bestDistanceDisplay.Name = "BestDistanceDisplay"
bestDistanceDisplay.Size = UDim2.new(1, 0, 0, 30)
bestDistanceDisplay.Position = UDim2.new(0, 0, 0, 145)
bestDistanceDisplay.BackgroundTransparency = 1
bestDistanceDisplay.Text = "Best: 0m"
bestDistanceDisplay.TextColor3 = Color3.fromRGB(200, 200, 200)
bestDistanceDisplay.TextScaled = true
bestDistanceDisplay.Font = Enum.Font.GothamMedium
bestDistanceDisplay.Parent = deathContent

-- Encouragement message (for new players)
local encouragementFrame = Instance.new("Frame")
encouragementFrame.Name = "EncouragementFrame"
encouragementFrame.Size = UDim2.new(1, 0, 0, 150)
encouragementFrame.Position = UDim2.new(0, 0, 0, 190)
encouragementFrame.BackgroundTransparency = 1
encouragementFrame.Visible = false
encouragementFrame.Parent = deathContent

local encouragementText = Instance.new("TextLabel")
encouragementText.Name = "EncouragementText"
encouragementText.Size = UDim2.new(1, 0, 0, 60)
encouragementText.Position = UDim2.new(0, 0, 0, 0)
encouragementText.BackgroundTransparency = 1
encouragementText.Text = "Keep practicing! You'll get further!"
encouragementText.TextColor3 = Color3.fromRGB(100, 255, 150)
encouragementText.TextScaled = true
encouragementText.Font = Enum.Font.GothamBold
encouragementText.Parent = encouragementFrame

local tipText = Instance.new("TextLabel")
tipText.Name = "TipText"
tipText.Size = UDim2.new(1, 0, 0, 40)
tipText.Position = UDim2.new(0, 0, 0, 70)
tipText.BackgroundTransparency = 1
tipText.Text = "Tip: Hold space longer for bigger jumps"
tipText.TextColor3 = Color3.fromRGB(200, 200, 255)
tipText.TextScaled = true
tipText.Font = Enum.Font.GothamMedium
tipText.Parent = encouragementFrame

-- BIG TRY AGAIN button (center, primary action)
local tryAgainButton = Instance.new("TextButton")
tryAgainButton.Name = "TryAgainButton"
tryAgainButton.Size = UDim2.new(0, 300, 0, 70)
tryAgainButton.Position = UDim2.new(0.5, -150, 0, 100)
tryAgainButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
tryAgainButton.Text = "TRY AGAIN"
tryAgainButton.TextColor3 = Color3.fromRGB(0, 0, 0)
tryAgainButton.TextScaled = true
tryAgainButton.Font = Enum.Font.GothamBold
encouragementFrame.Parent = deathContent

-- Shop frame (for experienced players - below the fold)
local shopOptionsFrame = Instance.new("Frame")
shopOptionsFrame.Name = "ShopOptionsFrame"
shopOptionsFrame.Size = UDim2.new(1, 0, 0, 200)
shopOptionsFrame.Position = UDim2.new(0, 0, 0, 190)
shopOptionsFrame.BackgroundTransparency = 1
shopOptionsFrame.Visible = false
shopOptionsFrame.Parent = deathContent

local shopHeader = Instance.new("TextLabel")
shopHeader.Name = "ShopHeader"
shopHeader.Size = UDim2.new(1, 0, 0, 30)
shopHeader.Position = UDim2.new(0, 0, 0, 0)
shopHeader.BackgroundTransparency = 1
shopHeader.Text = "Need a boost?"
shopHeader.TextColor3 = Color3.fromRGB(255, 200, 100)
shopHeader.TextScaled = true
shopHeader.Font = Enum.Font.GothamBold
shopHeader.Parent = shopOptionsFrame

-- Revive button
local reviveButton = Instance.new("TextButton")
reviveButton.Name = "ReviveButton"
reviveButton.Size = UDim2.new(0, 200, 0, 50)
reviveButton.Position = UDim2.new(0.5, -100, 0, 50)
reviveButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
reviveButton.Text = "REVIVE (25 R$)"
reviveButton.TextColor3 = Color3.fromRGB(0, 0, 0)
reviveButton.TextScaled = true
reviveButton.Font = Enum.Font.GothamBold
reviveButton.Parent = shopOptionsFrame

-- Coin pack button
local coinPackButton = Instance.new("TextButton")
coinPackButton.Name = "CoinPackButton"
coinPackButton.Size = UDim2.new(0, 200, 0, 40)
coinPackButton.Position = UDim2.new(0.5, -100, 0, 110)
coinPackButton.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
coinPackButton.Text = "Get Coins (49 R$)"
coinPackButton.TextColor3 = Color3.fromRGB(0, 0, 0)
coinPackButton.TextScaled = true
coinPackButton.Font = Enum.Font.GothamBold
coinPackButton.Parent = shopOptionsFrame

-- Regular respawn button (for shop view)
local respawnButton = Instance.new("TextButton")
respawnButton.Name = "RespawnButton"
respawnButton.Size = UDim2.new(0, 200, 0, 40)
respawnButton.Position = UDim2.new(0.5, -100, 0, 160)
respawnButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
respawnButton.Text = "RESPAWN"
respawnButton.TextColor3 = Color3.fromRGB(0, 0, 0)
respawnButton.TextScaled = true
respawnButton.Font = Enum.Font.GothamBold
respawnButton.Parent = shopOptionsFrame

-- Fix parent references (they got misplaced)
encouragementFrame.Parent = deathContent
tryAgainButton.Parent = encouragementFrame

-- ==================== FUNCTIONS ====================

-- Update distance display in HUD
local function updateDistance(distance)
    currentDistance = distance
    distanceLabel.Text = tostring(math.floor(distance)) .. "m"
end

-- Show death screen with appropriate content
local function showDeathScreen(data)
    deathData = data
    
    -- Update displays
    distanceDisplay.Text = "You ran: " .. tostring(data.distance) .. "m"
    bestDistanceDisplay.Text = "Best: " .. tostring(data.furthestDistance) .. "m"
    
    -- Show appropriate content based on player experience
    if data.showShop then
        -- Experienced player - show shop options
        encouragementFrame.Visible = false
        shopOptionsFrame.Visible = true
        shopOptionsFrame.Parent = deathContent
    else
        -- New player - show encouragement
        encouragementFrame.Visible = true
        shopOptionsFrame.Visible = false
    end
    
    -- Show death screen
    deathScreen.Visible = true
    hudFrame.Visible = false
    
    -- Animate in
    deathScreen.BackgroundTransparency = 1
    TweenService:Create(deathScreen, TweenInfo.new(0.3), {BackgroundTransparency = 0.4}):Play()
end

-- Hide death screen
local function hideDeathScreen()
    deathScreen.Visible = false
    hudFrame.Visible = true
end

-- Handle respawn
local function respawnPlayer()
    hideDeathScreen()
    requestRespawnEvent:FireServer()
end

-- ==================== EVENT HANDLERS ====================

-- Shop button - always opens shop
shopButton.MouseButton1Click:Connect(function()
    shopFrame.Visible = true
end)

closeButton.MouseButton1Click:Connect(function()
    shopFrame.Visible = false
end)

-- Death screen buttons
tryAgainButton.MouseButton1Click:Connect(respawnPlayer)
respawnButton.MouseButton1Click:Connect(respawnPlayer)

reviveButton.MouseButton1Click:Connect(function()
    print("[UI] Revive requested")
    -- TODO: Implement purchase flow
    respawnPlayer()
end)

coinPackButton.MouseButton1Click:Connect(function()
    print("[UI] Coin pack requested")
    -- TODO: Implement purchase flow
end)

-- Server event - player died
playerDiedEvent.OnClientEvent:Connect(function(data)
    print("[UI] Player died event received:", data.distance .. "m", "ShowShop:", data.showShop)
    showDeathScreen(data)
end)

-- Connect to character for distance tracking
local function setupDistanceTracking()
    local character = player.Character
    if not character then return end
    
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    local startZ = hrp.Position.Z
    
    local connection
    connection = game:GetService("RunService").Heartbeat:Connect(function()
        if not hrp or not hrp.Parent then
            if connection then connection:Disconnect() end
            return
        end
        
        local distance = math.abs(startZ - hrp.Position.Z)
        updateDistance(distance)
    end)
end

-- Setup on character spawn
player.CharacterAdded:Connect(function()
    hideDeathScreen()
    task.wait(0.5)
    setupDistanceTracking()
end)

-- Initial setup
if player.Character then
    setupDistanceTracking()
end

print("[UI] Main UI initialized with delayed monetization")

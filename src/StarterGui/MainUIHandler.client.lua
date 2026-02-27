-- Main UI Controller
-- Handles HUD, death screen, shop

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

-- Create Main UI
local mainUI = Instance.new("ScreenGui")
mainUI.Name = "MainUI"
mainUI.Parent = playerGui

-- HUD Frame
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
distanceLabel.BackgroundTransparency = 0.5
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
coinsFrame.BackgroundTransparency = 0.5
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

-- Shop Button
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

-- Shop Frame
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
trailsLabel.Size = UDim2.new(1, 0, 0, 30)
trailsLabel.Position = UDim2.new(0, 0, 0, 60)
trailsLabel.BackgroundTransparency = 1
trailsLabel.Text = "TRAILS"
trailsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
trailsLabel.TextScaled = true
shopFrame.Parent = shopFrame

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
skinsLabel.Size = UDim2.new(1, 0, 0, 30)
skinsLabel.Position = UDim2.new(0, 0, 0, 230)
skinsLabel.BackgroundTransparency = 1
skinsLabel.Text = "SKINS"
skinsLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
skinsLabel.TextScaled = true
shopFrame.Parent = shopFrame

local skinsList = Instance.new("ScrollingFrame")
skinsList.Name = "SkinsList"
skinsList.Size = UDim2.new(1, -20, 0, 120)
skinsList.Position = UDim2.new(0, 10, 0, 270)
skinsList.BackgroundTransparency = 0.5
skinsList.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
skinsList.ScrollBarThickness = 5
skinsList.Parent = shopFrame

-- Death Screen
local deathScreen = Instance.new("Frame")
deathScreen.Name = "DeathScreen"
deathScreen.Size = UDim2.new(1, 0, 1, 0)
deathScreen.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
deathScreen.BackgroundTransparency = 0.5
deathScreen.Visible = false
deathScreen.Parent = mainUI

local deathText = Instance.new("TextLabel")
deathText.Name = "DeathText"
deathText.Size = UDim2.new(0, 400, 0, 60)
deathText.Position = UDim2.new(0.5, -200, 0.35, 0)
deathText.BackgroundTransparency = 1
deathText.Text = "YOU DIED"
deathText.TextColor3 = Color3.fromRGB(255, 100, 100)
deathText.TextScaled = true
deathText.Font = Enum.Font.GothamBold
deathText.Parent = deathScreen

local distanceText = Instance.new("TextLabel")
distanceText.Name = "DistanceText"
distanceText.Size = UDim2.new(0, 400, 0, 50)
distanceText.Position = UDim2.new(0.5, -200, 0.45, 0)
distanceText.BackgroundTransparency = 1
distanceText.Text = "You ran 0m!"
distanceText.TextColor3 = Color3.fromRGB(255, 255, 255)
distanceText.TextScaled = true
distanceText.Font = Enum.Font.GothamBold
distanceText.Parent = deathScreen

local reviveButton = Instance.new("TextButton")
reviveButton.Name = "ReviveButton"
reviveButton.Size = UDim2.new(0, 200, 0, 50)
reviveButton.Position = UDim2.new(0.5, -100, 0.6, 0)
reviveButton.BackgroundColor3 = Color3.fromRGB(100, 255, 100)
reviveButton.Text = "REVIVE (25 R$)"
reviveButton.TextColor3 = Color3.fromRGB(0, 0, 0)
reviveButton.TextScaled = true
reviveButton.Font = Enum.Font.GothamBold
reviveButton.Parent = deathScreen

local respawnButton = Instance.new("TextButton")
respawnButton.Name = "RespawnButton"
respawnButton.Size = UDim2.new(0, 200, 0, 50)
respawnButton.Position = UDim2.new(0.5, -100, 0.7, 0)
respawnButton.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
respawnButton.Text = "RESPAWN"
respawnButton.TextColor3 = Color3.fromRGB(0, 0, 0)
respawnButton.TextScaled = true
respawnButton.Font = Enum.Font.GothamBold
respawnButton.Parent = deathScreen

-- Handle death screen visibility and distance display
local function showDeathScreen(distance)
    distanceText.Text = "You ran " .. tostring(math.floor(distance)) .. "m!"
    deathScreen.Visible = true
end

local function hideDeathScreen()
    deathScreen.Visible = false
end

-- Listen for character death
player.CharacterAdded:Connect(function(character)
    hideDeathScreen()
    
    local humanoid = character:WaitForChild("Humanoid")
    humanoid.Died:Connect(function()
        -- Get final distance from leaderstats
        local leaderstats = player:FindFirstChild("leaderstats")
        local distance = 0
        if leaderstats then
            local score = leaderstats:FindFirstChild("Score")
            if score then
                distance = score.Value
            end
        end
        showDeathScreen(distance)
    end)
end)

-- Handle respawn button
respawnButton.MouseButton1Click:Connect(function()
    hideDeathScreen()
    -- Respawn character
    if player.Character then
        local humanoid = player.Character:FindFirstChild("Humanoid")
        if humanoid then
            humanoid.Health = 0
        end
    end
end)

-- Handle revive button (placeholder - would trigger Robux purchase)
reviveButton.MouseButton1Click:Connect(function()
    print("[UI] Revive requested - would trigger purchase flow")
    -- In a real implementation, this would use MarketplaceService to prompt purchase
    -- For now, just respawn
    hideDeathScreen()
end)

print("[UI] Main UI initialized")
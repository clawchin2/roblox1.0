-- Shop Controller - FIXED VERSION
-- Working shop with DevProducts

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

print("[ShopController] Loading...")

-- Shop data with REAL DevProduct IDs
local SHOP_ITEMS = {
    trails = {
        {id = "fire", name = "Fire Trail", price = 500, devProductId = 1742371243, color = Color3.fromRGB(255, 100, 0)},
        {id = "ice", name = "Ice Trail", price = 500, devProductId = 1742371244, color = Color3.fromRGB(100, 200, 255)},
        {id = "rainbow", name = "Rainbow Trail", price = 1000, devProductId = 1742371245, color = nil},
    },
    skins = {
        {id = "speedster", name = "Speedster", price = 750, devProductId = 1742371246, speedBonus = 2},
        {id = "jumper", name = "Jumper", price = 750, devProductId = 1742371247, jumpBonus = 10},
    },
    coinPacks = {
        {id = "small", name = "100 Coins", robuxPrice = 49, devProductId = 1742371248, coins = 100},
        {id = "medium", name = "250 Coins", robuxPrice = 99, devProductId = 1742371249, coins = 250},
        {id = "large", name = "600 Coins", robuxPrice = 199, devProductId = 1742371250, coins = 600},
    }
}

-- Owned items (would use DataStore in production)
local ownedItems = {trails = {}, skins = {}}
local equipped = {trail = nil, skin = nil}

-- Get remote events
local ShopEvents = ReplicatedStorage:FindFirstChild("ShopEvents")
if not ShopEvents then
    ShopEvents = Instance.new("Folder")
    ShopEvents.Name = "ShopEvents"
    ShopEvents.Parent = ReplicatedStorage
end

local PurchaseRequest = ShopEvents:FindFirstChild("PurchaseRequest")
local EquipRequest = ShopEvents:FindFirstChild("EquipRequest")

-- Purchase with coins
local function purchaseWithCoins(itemType, itemId, price)
    local leaderstats = player:FindFirstChild("leaderstats")
    if not leaderstats then return false end
    
    local coins = leaderstats:FindFirstChild("Coins")
    if not coins then return false end
    
    if coins.Value >= price then
        -- Deduct coins
        PurchaseRequest:FireServer(itemType, itemId, price)
        
        -- Mark as owned
        if itemType == "trail" then
            ownedItems.trails[itemId] = true
        elseif itemType == "skin" then
            ownedItems.skins[itemId] = true
        end
        
        return true
    else
        print("[ShopController] Not enough coins!")
        return false
    end
end

-- Purchase with Robux
local function purchaseWithRobux(item)
    if not item.devProductId then
        print("[ShopController] No DevProduct ID for " .. item.name)
        return
    end
    
    MarketplaceService:PromptProductPurchase(player, item.devProductId)
end

-- Equip item
local function equipItem(itemType, itemId)
    equipped[itemType] = itemId
    EquipRequest:FireServer(itemType, itemId)
    print("[ShopController] Equipped " .. itemType .. ": " .. itemId)
end

-- Create shop UI
local function createShopUI()
    local playerGui = player:WaitForChild("PlayerGui")
    
    -- Find existing shop frame
    local mainUI = playerGui:FindFirstChild("MainUI")
    if not mainUI then return end
    
    local shopFrame = mainUI:FindFirstChild("ShopFrame")
    if not shopFrame then return end
    
    -- Clear existing
    for _, child in ipairs(shopFrame:GetChildren()) do
        if child:IsA("TextButton") or child:IsA("Frame") then
            child:Destroy()
        end
    end
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Name = "ShopTitle"
    title.Size = UDim2.new(1, 0, 0, 50)
    title.BackgroundTransparency = 1
    title.Text = "🛒 SHOP"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextScaled = true
    title.Font = Enum.Font.GothamBold
    title.Parent = shopFrame
    
    -- Coin display
    local leaderstats = player:FindFirstChild("leaderstats")
    local coinText = "Coins: 0"
    if leaderstats then
        local coins = leaderstats:FindFirstChild("Coins")
        if coins then
            coinText = "Coins: " .. coins.Value
        end
    end
    
    local coinDisplay = Instance.new("TextLabel")
    coinDisplay.Name = "CoinDisplay"
    coinDisplay.Size = UDim2.new(0, 200, 0, 30)
    coinDisplay.Position = UDim2.new(0.5, -100, 0, 60)
    coinDisplay.BackgroundColor3 = Color3.fromRGB(0, 0, 0)
    coinDisplay.BackgroundTransparency = 0.5
    coinDisplay.Text = coinText
    coinDisplay.TextColor3 = Color3.fromRGB(255, 215, 0)
    coinDisplay.TextScaled = true
    coinDisplay.Font = Enum.Font.GothamBold
    coinDisplay.Parent = shopFrame
    
    -- Update coin display
    if leaderstats then
        local coins = leaderstats:FindFirstChild("Coins")
        if coins then
            coins.Changed:Connect(function(newVal)
                coinDisplay.Text = "Coins: " .. newVal
            end)
        end
    end
    
    -- Trails section
    local trailsLabel = Instance.new("TextLabel")
    trailsLabel.Size = UDim2.new(1, 0, 0, 30)
    trailsLabel.Position = UDim2.new(0, 0, 0, 100)
    trailsLabel.BackgroundTransparency = 1
    trailsLabel.Text = "TRAILS"
    trailsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    trailsLabel.TextScaled = true
    trailsLabel.Font = Enum.Font.GothamBold
    trailsLabel.Parent = shopFrame
    
    -- Trail buttons
    for i, trail in ipairs(SHOP_ITEMS.trails) do
        local btn = Instance.new("TextButton")
        btn.Name = "Trail_" .. trail.id
        btn.Size = UDim2.new(0, 120, 0, 80)
        btn.Position = UDim2.new(0, 20 + (i-1) * 130, 0, 140)
        btn.BackgroundColor3 = trail.color or Color3.fromRGB(255, 255, 255)
        btn.Text = trail.name .. "\n" .. trail.price .. " coins"
        btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamBold
        btn.Parent = shopFrame
        
        btn.MouseButton1Click:Connect(function()
            if ownedItems.trails[trail.id] then
                equipItem("trail", trail.id)
                btn.Text = trail.name .. "\n[EQUIPPED]"
            else
                if purchaseWithCoins("trail", trail.id, trail.price) then
                    btn.Text = trail.name .. "\n[OWNED]"
                end
            end
        end)
    end
    
    -- Coin packs section
    local packsLabel = Instance.new("TextLabel")
    packsLabel.Size = UDim2.new(1, 0, 0, 30)
    packsLabel.Position = UDim2.new(0, 0, 0, 240)
    packsLabel.BackgroundTransparency = 1
    packsLabel.Text = "COIN PACKS (Robux)"
    packsLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
    packsLabel.TextScaled = true
    packsLabel.Font = Enum.Font.GothamBold
    packsLabel.Parent = shopFrame
    
    -- Coin pack buttons
    for i, pack in ipairs(SHOP_ITEMS.coinPacks) do
        local btn = Instance.new("TextButton")
        btn.Name = "Pack_" .. pack.id
        btn.Size = UDim2.new(0, 120, 0, 60)
        btn.Position = UDim2.new(0, 20 + (i-1) * 130, 0, 280)
        btn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
        btn.Text = pack.name .. "\n" .. pack.robuxPrice .. " R$"
        btn.TextColor3 = Color3.fromRGB(0, 0, 0)
        btn.TextScaled = true
        btn.Font = Enum.Font.GothamBold
        btn.Parent = shopFrame
        
        btn.MouseButton1Click:Connect(function()
            purchaseWithRobux(pack)
        end)
    end
    
    -- Close button
    local closeBtn = Instance.new("TextButton")
    closeBtn.Name = "CloseButton"
    closeBtn.Size = UDim2.new(0, 100, 0, 40)
    closeBtn.Position = UDim2.new(0.5, -50, 1, -50)
    closeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    closeBtn.Text = "CLOSE"
    closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
    closeBtn.TextScaled = true
    closeBtn.Font = Enum.Font.GothamBold
    closeBtn.Parent = shopFrame
    
    closeBtn.MouseButton1Click:Connect(function()
        shopFrame.Visible = false
    end)
end

-- Initialize
local function init()
    task.wait(2) -- Wait for UI to load
    createShopUI()
    print("[ShopController] Shop UI created!")
end

task.spawn(init)

print("[ShopController] Loaded!")

return {purchaseWithCoins = purchaseWithCoins, equipItem = equipItem}
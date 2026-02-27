-- Shop Controller
-- Client-side shop UI handling with server communication

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local MarketplaceService = game:GetService("MarketplaceService")

local player = Players.LocalPlayer
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

-- RemoteEvents (will be created if they don't exist)
local ShopEvents = ReplicatedStorage:FindFirstChild("ShopEvents")
if not ShopEvents then
    ShopEvents = Instance.new("Folder")
    ShopEvents.Name = "ShopEvents"
    ShopEvents.Parent = ReplicatedStorage
end

local PurchaseRequest = ShopEvents:FindFirstChild("PurchaseRequest")
if not PurchaseRequest then
    PurchaseRequest = Instance.new("RemoteEvent")
    PurchaseRequest.Name = "PurchaseRequest"
    PurchaseRequest.Parent = ShopEvents
end

local EquipRequest = ShopEvents:FindFirstChild("EquipRequest")
if not EquipRequest then
    EquipRequest = Instance.new("RemoteEvent")
    EquipRequest.Name = "EquipRequest"
    EquipRequest.Parent = ShopEvents
end

local ShopController = {}
ShopController.ui = nil
ShopController.ownedItems = {trails = {}, skins = {}}
ShopController.equipped = {trail = nil, skin = nil}
ShopController.coins = 0

function ShopController.init()
    print("[ShopController] Initializing...")
    
    -- Wait for UI
    local playerGui = player:WaitForChild("PlayerGui")
    ShopController.ui = playerGui:WaitForChild("MainUI")
    
    local shopButton = ShopController.ui:WaitForChild("ShopButton")
    local shopFrame = ShopController.ui:WaitForChild("ShopFrame")
    local closeButton = shopFrame:WaitForChild("CloseButton")
    
    -- Setup shop button
    shopButton.MouseButton1Click:Connect(function()
        shopFrame.Visible = true
        ShopController.updateCoinDisplay()
        ShopController.populateShop()
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        shopFrame.Visible = false
    end)
    
    -- Listen for coin updates from leaderstats
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        local coinsStat = leaderstats:FindFirstChild("Coins")
        if coinsStat then
            ShopController.coins = coinsStat.Value
            coinsStat.Changed:Connect(function(newValue)
                ShopController.coins = newValue
                ShopController.updateCoinDisplay()
            end)
        end
    end
    
    -- Also check when leaderstats is added
    player.ChildAdded:Connect(function(child)
        if child.Name == "leaderstats" then
            local coinsStat = child:WaitForChild("Coins")
            if coinsStat then
                ShopController.coins = coinsStat.Value
                coinsStat.Changed:Connect(function(newValue)
                    ShopController.coins = newValue
                    ShopController.updateCoinDisplay()
                end)
            end
        end
    end)
    
    print("[ShopController] Initialized with " .. ShopController.coins .. " coins")
end

function ShopController.updateCoinDisplay()
    -- Update coin display in HUD if it exists
    local hudFrame = ShopController.ui:FindFirstChild("HUD")
    if hudFrame then
        local coinsFrame = hudFrame:FindFirstChild("CoinsFrame")
        if coinsFrame then
            local coinsLabel = coinsFrame:FindFirstChild("CoinsLabel")
            if coinsLabel then
                coinsLabel.Text = tostring(ShopController.coins)
            end
        end
    end
    
    -- Also update shop frame title with coins
    local shopFrame = ShopController.ui:FindFirstChild("ShopFrame")
    if shopFrame then
        local title = shopFrame:FindFirstChild("Title")
        if title then
            title.Text = "SHOP - " .. ShopController.coins .. " COINS"
        end
    end
end

function ShopController.populateShop()
    local shopFrame = ShopController.ui.ShopFrame
    local trailsList = shopFrame:WaitForChild("TrailsList")
    local skinsList = shopFrame:WaitForChild("SkinsList")
    
    -- Clear existing
    for _, child in ipairs(trailsList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    for _, child in ipairs(skinsList:GetChildren()) do
        if child:IsA("TextButton") then child:Destroy() end
    end
    
    -- Populate trails
    for _, trail in ipairs(GameConfig.SHOP_ITEMS.TRAILS) do
        local button = Instance.new("TextButton")
        button.Name = trail.id
        button.Size = UDim2.new(0, 120, 0, 100)
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        button.Text = ""
        button.Parent = trailsList
        
        -- Trail name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = trail.name
        nameLabel.TextColor3 = trail.color or Color3.fromRGB(255, 255, 255)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Parent = button
        
        -- Price
        local priceLabel = Instance.new("TextLabel")
        priceLabel.Size = UDim2.new(1, 0, 0.3, 0)
        priceLabel.Position = UDim2.new(0, 0, 0.4, 0)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = tostring(trail.price) .. " coins"
        priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        priceLabel.TextScaled = true
        priceLabel.Font = Enum.Font.Gotham
        priceLabel.Parent = button
        
        -- Status (owned/equipped/buy)
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = "StatusLabel"
        statusLabel.Size = UDim2.new(1, 0, 0.3, 0)
        statusLabel.Position = UDim2.new(0, 0, 0.7, 0)
        statusLabel.BackgroundTransparency = 1
        
        if ShopController.equipped.trail == trail.id then
            statusLabel.Text = "EQUIPPED"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            button.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
        elseif ShopController.ownedItems.trails[trail.id] then
            statusLabel.Text = "OWNED - CLICK TO EQUIP"
            statusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
        else
            statusLabel.Text = "CLICK TO BUY"
            statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        statusLabel.TextScaled = true
        statusLabel.Font = Enum.Font.Gotham
        statusLabel.Parent = button
        
        button.MouseButton1Click:Connect(function()
            ShopController.handleTrailClick(trail, button)
        end)
    end
    
    -- Populate skins
    for _, skin in ipairs(GameConfig.SHOP_ITEMS.SKINS) do
        local button = Instance.new("TextButton")
        button.Name = skin.id
        button.Size = UDim2.new(0, 120, 0, 100)
        button.BackgroundColor3 = Color3.fromRGB(60, 60, 70)
        button.Text = ""
        button.Parent = skinsList
        
        -- Skin name
        local nameLabel = Instance.new("TextLabel")
        nameLabel.Size = UDim2.new(1, 0, 0.4, 0)
        nameLabel.BackgroundTransparency = 1
        nameLabel.Text = skin.name
        nameLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        nameLabel.TextScaled = true
        nameLabel.Font = Enum.Font.GothamBold
        nameLabel.Parent = button
        
        -- Price
        local priceLabel = Instance.new("TextLabel")
        priceLabel.Size = UDim2.new(1, 0, 0.3, 0)
        priceLabel.Position = UDim2.new(0, 0, 0.4, 0)
        priceLabel.BackgroundTransparency = 1
        priceLabel.Text = tostring(skin.price) .. " coins"
        priceLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
        priceLabel.TextScaled = true
        priceLabel.Font = Enum.Font.Gotham
        priceLabel.Parent = button
        
        -- Status
        local statusLabel = Instance.new("TextLabel")
        statusLabel.Name = "StatusLabel"
        statusLabel.Size = UDim2.new(1, 0, 0.3, 0)
        statusLabel.Position = UDim2.new(0, 0, 0.7, 0)
        statusLabel.BackgroundTransparency = 1
        
        if ShopController.equipped.skin == skin.id then
            statusLabel.Text = "EQUIPPED"
            statusLabel.TextColor3 = Color3.fromRGB(100, 255, 100)
            button.BackgroundColor3 = Color3.fromRGB(40, 80, 40)
        elseif ShopController.ownedItems.skins[skin.id] then
            statusLabel.Text = "OWNED - CLICK TO EQUIP"
            statusLabel.TextColor3 = Color3.fromRGB(100, 200, 255)
        else
            statusLabel.Text = "CLICK TO BUY"
            statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
        end
        statusLabel.TextScaled = true
        statusLabel.Font = Enum.Font.Gotham
        statusLabel.Parent = button
        
        button.MouseButton1Click:Connect(function()
            ShopController.handleSkinClick(skin, button)
        end)
    end
end

function ShopController.handleTrailClick(trail, button)
    -- If already owned, equip it
    if ShopController.ownedItems.trails[trail.id] then
        ShopController.equipTrail(trail.id)
        ShopController.populateShop() -- Refresh UI
        return
    end
    
    -- Try to purchase
    if ShopController.coins >= trail.price then
        print("[ShopController] Purchasing trail:", trail.name)
        PurchaseRequest:FireServer("trail", trail.id, trail.price)
        
        -- Optimistically update (server will correct if needed)
        ShopController.ownedItems.trails[trail.id] = true
        ShopController.coins = ShopController.coins - trail.price
        ShopController.updateCoinDisplay()
        ShopController.equipTrail(trail.id)
        ShopController.populateShop()
    else
        print("[ShopController] Not enough coins for trail:", trail.name)
        -- Show "Not enough coins" feedback
        local statusLabel = button:FindFirstChild("StatusLabel")
        if statusLabel then
            local originalText = statusLabel.Text
            statusLabel.Text = "NOT ENOUGH COINS!"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            task.delay(1, function()
                if statusLabel then
                    statusLabel.Text = originalText
                    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end)
        end
    end
end

function ShopController.handleSkinClick(skin, button)
    -- If already owned, equip it
    if ShopController.ownedItems.skins[skin.id] then
        ShopController.equipSkin(skin.id)
        ShopController.populateShop() -- Refresh UI
        return
    end
    
    -- Try to purchase
    if ShopController.coins >= skin.price then
        print("[ShopController] Purchasing skin:", skin.name)
        PurchaseRequest:FireServer("skin", skin.id, skin.price)
        
        -- Optimistically update
        ShopController.ownedItems.skins[skin.id] = true
        ShopController.coins = ShopController.coins - skin.price
        ShopController.updateCoinDisplay()
        ShopController.equipSkin(skin.id)
        ShopController.populateShop()
    else
        print("[ShopController] Not enough coins for skin:", skin.name)
        -- Show "Not enough coins" feedback
        local statusLabel = button:FindFirstChild("StatusLabel")
        if statusLabel then
            local originalText = statusLabel.Text
            statusLabel.Text = "NOT ENOUGH COINS!"
            statusLabel.TextColor3 = Color3.fromRGB(255, 100, 100)
            task.delay(1, function()
                if statusLabel then
                    statusLabel.Text = originalText
                    statusLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
                end
            end)
        end
    end
end

function ShopController.equipTrail(trailId)
    print("[ShopController] Equipping trail:", trailId)
    ShopController.equipped.trail = trailId
    EquipRequest:FireServer("trail", trailId)
    
    -- Create trail effect on character
    local character = player.Character
    if character then
        local hrp = character:FindFirstChild("HumanoidRootPart")
        if hrp then
            -- Remove old trail
            local oldTrail = hrp:FindFirstChild("ShopTrail")
            if oldTrail then oldTrail:Destroy() end
            
            -- Create new trail
            local trail = Instance.new("Trail")
            trail.Name = "ShopTrail"
            
            -- Find trail config
            local trailConfig = nil
            for _, t in ipairs(GameConfig.SHOP_ITEMS.TRAILS) do
                if t.id == trailId then
                    trailConfig = t
                    break
                end
            end
            
            if trailConfig then
                trail.Color = ColorSequence.new(trailConfig.color or Color3.fromRGB(255, 255, 255))
                trail.Lifetime = 0.5
                trail.WidthScale = NumberSequence.new(0.5)
                
                local attachment0 = Instance.new("Attachment")
                attachment0.Position = Vector3.new(0, 1, 0)
                attachment0.Parent = hrp
                
                local attachment1 = Instance.new("Attachment")
                attachment1.Position = Vector3.new(0, -1, 0)
                attachment1.Parent = hrp
                
                trail.Attachment0 = attachment0
                trail.Attachment1 = attachment1
                trail.Parent = hrp
            end
        end
    end
end

function ShopController.equipSkin(skinId)
    print("[ShopController] Equipping skin:", skinId)
    ShopController.equipped.skin = skinId
    EquipRequest:FireServer("skin", skinId)
    
    -- Apply skin to character
    local character = player.Character
    if character then
        local humanoid = character:FindFirstChild("Humanoid")
        if humanoid then
            -- Find skin config
            local skinConfig = nil
            for _, s in ipairs(GameConfig.SHOP_ITEMS.SKINS) do
                if s.id == skinId then
                    skinConfig = s
                    break
                end
            end
            
            if skinConfig then
                -- Apply skin color/effects
                for _, part in ipairs(character:GetDescendants()) do
                    if part:IsA("BasePart") and part.Name ~= "HumanoidRootPart" then
                        part.Color = Color3.fromRGB(255, 200, 100) -- Speedster orange
                    end
                end
            end
        end
    end
end

return ShopController

-- Shop Controller
-- Client-side shop UI handling

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local player = Players.LocalPlayer
local GameConfig = require(ReplicatedStorage.Modules.GameConfig)

local ShopController = {}
ShopController.ui = nil

function ShopController.init()
    -- Wait for UI
    local playerGui = player:WaitForChild("PlayerGui")
    ShopController.ui = playerGui:WaitForChild("MainUI")
    
    local shopButton = ShopController.ui:WaitForChild("ShopButton")
    local shopFrame = ShopController.ui:WaitForChild("ShopFrame")
    local closeButton = shopFrame:WaitForChild("CloseButton")
    
    shopButton.MouseButton1Click:Connect(function()
        shopFrame.Visible = true
        ShopController.populateShop()
    end)
    
    closeButton.MouseButton1Click:Connect(function()
        shopFrame.Visible = false
    end)
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
        button.Size = UDim2.new(0, 100, 0, 100)
        button.Text = trail.name .. "\n" .. trail.price .. " coins"
        button.Parent = trailsList
        
        button.MouseButton1Click:Connect(function()
            ShopController.purchaseTrail(trail)
        end)
    end
    
    -- Populate skins
    for _, skin in ipairs(GameConfig.SHOP_ITEMS.SKINS) do
        local button = Instance.new("TextButton")
        button.Name = skin.id
        button.Size = UDim2.new(0, 100, 0, 100)
        button.Text = skin.name .. "\n" .. skin.price .. " coins"
        button.Parent = skinsList
        
        button.MouseButton1Click:Connect(function()
            ShopController.purchaseSkin(skin)
        end)
    end
end

function ShopController.purchaseTrail(trail)
    print("Purchasing trail:", trail.name)
    -- TODO: Server-side purchase validation
end

function ShopController.purchaseSkin(skin)
    print("Purchasing skin:", skin.name)
    -- TODO: Server-side purchase validation
end

return ShopController
-- UI - FIXED to receive single table from server
local player = game.Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Wait for HatchEvent
local hatchEvent = ReplicatedStorage:WaitForChild("HatchEvent", 10)
if not hatchEvent then
    warn("[UI] HatchEvent not found!")
end

-- Error notification
function showError(message)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 300, 0, 60)
    frame.Position = UDim2.new(0.5, -150, 0.5, -100)
    frame.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 10)
    frame.Parent = gui
    
    local label = Instance.new("TextLabel")
    label.Size = UDim2.new(1, 0, 1, 0)
    label.BackgroundTransparency = 1
    label.Text = tostring(message)
    label.TextColor3 = Color3.fromRGB(255, 255, 255)
    label.TextSize = 20
    label.Font = Enum.Font.GothamBold
    label.Parent = frame
    
    task.delay(3, function()
        frame:Destroy()
    end)
end

-- Hatch success popup
function showHatchPopup(petData)
    local frame = Instance.new("Frame")
    frame.Size = UDim2.new(0, 350, 0, 250)
    frame.Position = UDim2.new(0.5, -175, 0.5, -125)
    frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
    frame.ZIndex = 100
    Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 20)
    frame.Parent = gui
    
    -- Title
    local title = Instance.new("TextLabel")
    title.Size = UDim2.new(1, 0, 0, 40)
    title.BackgroundTransparency = 1
    title.Text = "🎉 YOU HATCHED!"
    title.TextColor3 = Color3.fromRGB(255, 215, 0)
    title.TextSize = 28
    title.Font = Enum.Font.GothamBold
    title.Parent = frame
    
    -- Pet name
    local name = Instance.new("TextLabel")
    name.Size = UDim2.new(1, 0, 0, 50)
    name.Position = UDim2.new(0, 0, 0, 50)
    name.BackgroundTransparency = 1
    name.Text = petData.name or "Unknown"
    name.TextSize = 32
    name.Font = Enum.Font.GothamBold
    
    -- Rarity color
    local rarityColors = {
        Common = Color3.fromRGB(169, 169, 169),
        Uncommon = Color3.fromRGB(0, 255, 0),
        Rare = Color3.fromRGB(0, 100, 255),
        Epic = Color3.fromRGB(150, 0, 255),
        Legendary = Color3.fromRGB(255, 215, 0)
    }
    name.TextColor3 = rarityColors[petData.rarity] or Color3.fromRGB(255, 255, 255)
    name.Parent = frame
    
    -- Rarity label
    local rarity = Instance.new("TextLabel")
    rarity.Size = UDim2.new(1, 0, 0, 30)
    rarity.Position = UDim2.new(0, 0, 0, 100)
    rarity.BackgroundTransparency = 1
    rarity.Text = petData.rarity or "Unknown"
    rarity.TextColor3 = name.TextColor3
    rarity.TextSize = 22
    rarity.Font = Enum.Font.Gotham
    rarity.Parent = frame
    
    -- Stats
    local stats = Instance.new("TextLabel")
    stats.Size = UDim2.new(1, 0, 0, 30)
    stats.Position = UDim2.new(0, 0, 0, 140)
    stats.BackgroundTransparency = 1
    stats.Text = "Speed: " .. (petData.speed or 0) .. " | Coins: x" .. (petData.coins or 1)
    stats.TextColor3 = Color3.fromRGB(255, 255, 255)
    stats.TextSize = 18
    stats.Font = Enum.Font.Gotham
    stats.Parent = frame
    
    -- Close button
    local close = Instance.new("TextButton")
    close.Size = UDim2.new(0, 150, 0, 40)
    close.Position = UDim2.new(0.5, -75, 1, -55)
    close.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
    close.Text = "AWESOME!"
    close.TextSize = 20
    close.Font = Enum.Font.GothamBold
    Instance.new("UICorner", close).CornerRadius = UDim.new(0, 10)
    close.Parent = frame
    
    close.MouseButton1Click:Connect(function()
        frame:Destroy()
    end)
    
    -- Auto close after 5 seconds
    task.delay(5, function()
        if frame and frame.Parent then
            frame:Destroy()
        end
    end)
end

-- Listen for hatch results - SINGLE TABLE FORMAT
if hatchEvent then
    hatchEvent.OnClientEvent:Connect(function(data)
        print("[UI] Received hatch data: " .. tostring(data.success))
        
        if not data or typeof(data) ~= "table" then
            showError("Invalid response from server")
            return
        end
        
        if data.success then
            showHatchPopup(data)
        else
            showError(data.error or "Hatch failed")
        end
    end)
end

-- Create main UI
local screen = Instance.new("ScreenGui")
screen.Name = "GameUI"
screen.ResetOnSpawn = false
screen.Parent = gui

-- Coins display
local coinsFrame = Instance.new("Frame")
coinsFrame.Size = UDim2.new(0, 200, 0, 50)
coinsFrame.Position = UDim2.new(0.5, -100, 0, 20)
coinsFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
coinsFrame.BorderSizePixel = 0
Instance.new("UICorner", coinsFrame).CornerRadius = UDim.new(0, 10)
coinsFrame.Parent = screen

local coinsText = Instance.new("TextLabel")
coinsText.Name = "CoinsText"
coinsText.Size = UDim2.new(1, -40, 1, 0)
coinsText.Position = UDim2.new(0, 40, 0, 0)
coinsText.BackgroundTransparency = 1
coinsText.Text = "0"
coinsText.TextColor3 = Color3.fromRGB(0, 0, 0)
coinsText.TextSize = 32
coinsText.Font = Enum.Font.GothamBold
coinsText.Parent = coinsFrame

-- Update coins
game:GetService("RunService").Heartbeat:Connect(function()
    local stats = player:FindFirstChild("leaderstats")
    if stats then
        local coins = stats:FindFirstChild("Coins")
        if coins then
            coinsText.Text = tostring(coins.Value)
        end
    end
end)

-- Shop button
local shopBtn = Instance.new("TextButton")
shopBtn.Size = UDim2.new(0, 120, 0, 45)
shopBtn.Position = UDim2.new(1, -140, 1, -60)
shopBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
shopBtn.Text = "🥚 SHOP"
shopBtn.TextSize = 20
shopBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", shopBtn).CornerRadius = UDim.new(0, 10)
shopBtn.Parent = screen

-- Shop frame
local shopFrame = Instance.new("Frame")
shopFrame.Size = UDim2.new(0, 350, 0, 400)
shopFrame.Position = UDim2.new(0.5, -175, 0.5, -200)
shopFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
shopFrame.Visible = false
Instance.new("UICorner", shopFrame).CornerRadius = UDim.new(0, 15)
shopFrame.Parent = screen

-- Title
local title = Instance.new("TextLabel")
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "EGG SHOP"
title.TextColor3 = Color3.fromRGB(255, 255, 255)
title.TextSize = 28
title.Font = Enum.Font.GothamBold
title.Parent = shopFrame

-- Close
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 35, 0, 35)
closeBtn.Position = UDim2.new(1, -45, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.Text = "X"
closeBtn.TextSize = 20
closeBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 8)
closeBtn.Parent = shopFrame

closeBtn.MouseButton1Click:Connect(function()
    shopFrame.Visible = false
end)

-- Egg buttons
local eggs = {
    {Name = "Basic Egg", Id = "basic_egg", Cost = 100, Color = Color3.fromRGB(150, 150, 150)},
    {Name = "Fantasy Egg", Id = "fantasy_egg", Cost = 500, Color = Color3.fromRGB(100, 150, 255)},
    {Name = "Mythic Egg", Id = "mythic_egg", Cost = 2000, Color = Color3.fromRGB(255, 100, 255)}
}

for i, egg in ipairs(eggs) do
    local btn = Instance.new("TextButton")
    btn.Size = UDim2.new(0, 300, 0, 80)
    btn.Position = UDim2.new(0.5, -150, 0, 70 + (i-1) * 100)
    btn.BackgroundColor3 = egg.Color
    btn.Text = egg.Name .. "\n🪙 " .. egg.Cost
    btn.TextSize = 20
    btn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 12)
    btn.Parent = shopFrame
    
    btn.MouseButton1Click:Connect(function()
        if hatchEvent then
            print("[UI] Buying: " .. egg.Id)
            -- Close shop before hatching
            shopFrame.Visible = false
            -- Small delay for shop to close before server response
            task.wait(0.1)
            hatchEvent:FireServer(egg.Id)
        else
            showError("Hatch system not ready")
        end
    end)
end

-- Toggle shop
shopBtn.MouseButton1Click:Connect(function()
    shopFrame.Visible = not shopFrame.Visible
end)

print("[UI] Ready")

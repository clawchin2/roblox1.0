-- UI - Pet Simulator Interface
local player = game.Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

-- Remove old UI
local old = gui:FindFirstChild("PetUI")
if old then old:Destroy() end

-- Main UI
local screen = Instance.new("ScreenGui")
screen.Name = "PetUI"
screen.ResetOnSpawn = false
screen.Parent = gui

-- Coins Display (Top Center)
local coinsFrame = Instance.new("Frame")
coinsFrame.Size = UDim2.new(0, 250, 0, 60)
coinsFrame.Position = UDim2.new(0.5, -125, 0, 20)
coinsFrame.BackgroundColor3 = Color3.fromRGB(255, 215, 0)
coinsFrame.BorderSizePixel = 0
Instance.new("UICorner", coinsFrame).CornerRadius = UDim.new(0, 15)
coinsFrame.Parent = screen

local coinsIcon = Instance.new("TextLabel")
coinsIcon.Size = UDim2.new(0, 40, 1, 0)
coinsIcon.Position = UDim2.new(0, 10, 0, 0)
coinsIcon.BackgroundTransparency = 1
coinsIcon.Text = "🪙"
coinsIcon.TextSize = 30
coinsIcon.Parent = coinsFrame

local coinsText = Instance.new("TextLabel")
coinsText.Name = "CoinsText"
coinsText.Size = UDim2.new(1, -60, 1, 0)
coinsText.Position = UDim2.new(0, 50, 0, 0)
coinsText.BackgroundTransparency = 1
coinsText.Text = "0"
coinsText.TextColor3 = Color3.fromRGB(0, 0, 0)
coinsText.TextSize = 36
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

-- Egg Shop Button
local shopBtn = Instance.new("TextButton")
shopBtn.Name = "ShopButton"
shopBtn.Size = UDim2.new(0, 150, 0, 50)
shopBtn.Position = UDim2.new(1, -170, 1, -70)
shopBtn.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
shopBtn.Text = "🥚 EGGS"
shopBtn.TextSize = 24
shopBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", shopBtn).CornerRadius = UDim.new(0, 10)
shopBtn.Parent = screen

-- Egg Shop Frame
local shopFrame = Instance.new("Frame")
shopFrame.Name = "ShopFrame"
shopFrame.Size = UDim2.new(0, 400, 0, 500)
shopFrame.Position = UDim2.new(0.5, -200, 0.5, -250)
shopFrame.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
shopFrame.Visible = false
Instance.new("UICorner", shopFrame).CornerRadius = UDim.new(0, 20)
shopFrame.Parent = screen

-- Shop Title
local shopTitle = Instance.new("TextLabel")
shopTitle.Size = UDim2.new(1, 0, 0, 60)
shopTitle.BackgroundTransparency = 1
shopTitle.Text = "🥚 EGG SHOP"
shopTitle.TextColor3 = Color3.fromRGB(255, 255, 255)
shopTitle.TextSize = 32
shopTitle.Font = Enum.Font.GothamBold
shopTitle.Parent = shopFrame

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 100)
closeBtn.Text = "X"
closeBtn.TextSize = 24
closeBtn.Font = Enum.Font.GothamBold
Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)
closeBtn.Parent = shopFrame

closeBtn.MouseButton1Click:Connect(function()
    shopFrame.Visible = false
end)

-- Egg buttons
local eggPrices = {100, 500, 2000}
local eggNames = {"Basic Egg", "Fantasy Egg", "Mythic Egg"}
local eggIds = {"basic_egg", "fantasy_egg", "mythic_egg"}

for i = 1, 3 do
    local eggBtn = Instance.new("TextButton")
    eggBtn.Size = UDim2.new(0, 350, 0, 100)
    eggBtn.Position = UDim2.new(0.5, -175, 0, 80 + (i-1) * 120)
    
    if i == 1 then
        eggBtn.BackgroundColor3 = Color3.fromRGB(150, 150, 150)
    elseif i == 2 then
        eggBtn.BackgroundColor3 = Color3.fromRGB(100, 150, 255)
    else
        eggBtn.BackgroundColor3 = Color3.fromRGB(255, 100, 255)
    end
    
    eggBtn.Text = eggNames[i] .. "\n🪙 " .. eggPrices[i]
    eggBtn.TextSize = 24
    eggBtn.Font = Enum.Font.GothamBold
    Instance.new("UICorner", eggBtn).CornerRadius = UDim.new(0, 15)
    eggBtn.Parent = shopFrame
    
    eggBtn.MouseButton1Click:Connect(function()
        -- Fire remote event to hatch
        local ReplicatedStorage = game:GetService("ReplicatedStorage")
        local hatchEvent = ReplicatedStorage:FindFirstChild("HatchEvent")
        if hatchEvent then
            hatchEvent:FireServer(eggIds[i])
        end
    end)
end

-- Toggle shop
shopBtn.MouseButton1Click:Connect(function()
    shopFrame.Visible = not shopFrame.Visible
end)

-- Instructions
local instructions = Instance.new("TextLabel")
instructions.Size = UDim2.new(0, 400, 0, 40)
instructions.Position = UDim2.new(0.5, -200, 1, -50)
instructions.BackgroundTransparency = 1
instructions.Text = "👆 Click ground to earn coins!"
instructions.TextColor3 = Color3.fromRGB(255, 255, 255)
instructions.TextSize = 20
instructions.Font = Enum.Font.Gotham
instructions.Parent = screen

print("[UI] Loaded")
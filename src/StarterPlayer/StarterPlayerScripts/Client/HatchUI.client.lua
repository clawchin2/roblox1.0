-- Hatch Results UI
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local player = Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")

-- Listen for hatch results
local hatchEvent = ReplicatedStorage:WaitForChild("HatchEvent")

hatchEvent.OnClientEvent:Connect(function(result, data)
    if result == "success" then
        -- Show hatch success UI
        local pet = data
        
        local frame = Instance.new("Frame")
        frame.Size = UDim2.new(0, 400, 0, 300)
        frame.Position = UDim2.new(0.5, -200, 0.5, -150)
        frame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
        frame.ZIndex = 100
        Instance.new("UICorner", frame).CornerRadius = UDim.new(0, 20)
        frame.Parent = gui
        
        -- Title
        local title = Instance.new("TextLabel")
        title.Size = UDim2.new(1, 0, 0, 50)
        title.BackgroundTransparency = 1
        title.Text = "🎉 YOU HATCHED!"
        title.TextColor3 = Color3.fromRGB(255, 215, 0)
        title.TextSize = 32
        title.Font = Enum.Font.GothamBold
        title.ZIndex = 101
        title.Parent = frame
        
        -- Pet name
        local name = Instance.new("TextLabel")
        name.Size = UDim2.new(1, 0, 0, 60)
        name.Position = UDim2.new(0, 0, 0, 60)
        name.BackgroundTransparency = 1
        name.Text = pet.name
        name.TextSize = 40
        name.Font = Enum.Font.GothamBold
        name.ZIndex = 101
        
        -- Color by rarity
        if pet.rarity == "Common" then
            name.TextColor3 = Color3.fromRGB(169, 169, 169)
        elseif pet.rarity == "Uncommon" then
            name.TextColor3 = Color3.fromRGB(0, 255, 0)
        elseif pet.rarity == "Rare" then
            name.TextColor3 = Color3.fromRGB(0, 100, 255)
        elseif pet.rarity == "Epic" then
            name.TextColor3 = Color3.fromRGB(150, 0, 255)
        elseif pet.rarity == "Legendary" then
            name.TextColor3 = Color3.fromRGB(255, 215, 0)
        end
        name.Parent = frame
        
        -- Rarity
        local rarity = Instance.new("TextLabel")
        rarity.Size = UDim2.new(1, 0, 0, 40)
        rarity.Position = UDim2.new(0, 0, 0, 120)
        rarity.BackgroundTransparency = 1
        rarity.Text = pet.rarity
        rarity.TextColor3 = name.TextColor3
        rarity.TextSize = 28
        rarity.Font = Enum.Font.Gotham
        rarity.ZIndex = 101
        rarity.Parent = frame
        
        -- Stats
        local stats = Instance.new("TextLabel")
        stats.Size = UDim2.new(1, 0, 0, 40)
        stats.Position = UDim2.new(0, 0, 0, 170)
        stats.BackgroundTransparency = 1
        stats.Text = "Speed: " .. pet.speed .. " | Coins: x" .. pet.coins
        stats.TextColor3 = Color3.fromRGB(255, 255, 255)
        stats.TextSize = 20
        stats.Font = Enum.Font.Gotham
        stats.ZIndex = 101
        stats.Parent = frame
        
        -- Close button
        local close = Instance.new("TextButton")
        close.Size = UDim2.new(0, 200, 0, 50)
        close.Position = UDim2.new(0.5, -100, 1, -70)
        close.BackgroundColor3 = Color3.fromRGB(100, 200, 100)
        close.Text = "AWESOME!"
        close.TextSize = 24
        close.Font = Enum.Font.GothamBold
        close.ZIndex = 101
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
        
    elseif result == "fail" then
        -- Show error
        print("Hatch failed: " .. data)
    end
end)

print("[HatchUI] Ready - Listening for hatch events...")

-- Debug: Test the connection
hatchEvent.OnClientEvent:Connect(function(result, data)
    print("[HatchUI] Received event: " .. tostring(result))
end)
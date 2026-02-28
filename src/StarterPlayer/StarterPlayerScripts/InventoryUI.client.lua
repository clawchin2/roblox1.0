-- InventoryUI.client.lua
-- Pet inventory grid system

local player = game.Players.LocalPlayer
local gui = player:WaitForChild("PlayerGui")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

print("[InventoryUI] Loading...")

-- Create main inventory screen
local inventoryGui = Instance.new("ScreenGui")
inventoryGui.Name = "InventoryUI"
inventoryGui.ResetOnSpawn = false
inventoryGui.Enabled = false
inventoryGui.Parent = gui

-- Main frame
local mainFrame = Instance.new("Frame")
mainFrame.Name = "MainFrame"
mainFrame.Size = UDim2.new(0, 700, 0, 500)
mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
mainFrame.BorderSizePixel = 0
mainFrame.Parent = inventoryGui

local corner = Instance.new("UICorner")
corner.CornerRadius = UDim.new(0, 20)
corner.Parent = mainFrame

-- Title
local title = Instance.new("TextLabel")
title.Name = "Title"
title.Size = UDim2.new(1, 0, 0, 50)
title.BackgroundTransparency = 1
title.Text = "🎒 MY PETS"
title.TextColor3 = Color3.fromRGB(255, 215, 0)
title.TextSize = 28
title.Font = Enum.Font.GothamBold
title.Parent = mainFrame

-- Close button
local closeBtn = Instance.new("TextButton")
closeBtn.Name = "CloseButton"
closeBtn.Size = UDim2.new(0, 40, 0, 40)
closeBtn.Position = UDim2.new(1, -50, 0, 10)
closeBtn.BackgroundColor3 = Color3.fromRGB(255, 80, 80)
closeBtn.Text = "✕"
closeBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
closeBtn.TextSize = 20
closeBtn.Font = Enum.Font.GothamBold
closeBtn.Parent = mainFrame

local closeCorner = Instance.new("UICorner")
closeCorner.CornerRadius = UDim.new(0, 10)
closeCorner.Parent = closeBtn

closeBtn.MouseButton1Click:Connect(function()
	inventoryGui.Enabled = false
end)

-- Pet count display
local petCount = Instance.new("TextLabel")
petCount.Name = "PetCount"
petCount.Size = UDim2.new(0, 200, 0, 30)
petCount.Position = UDim2.new(0, 20, 0, 55)
petCount.BackgroundTransparency = 1
petCount.Text = "Pets: 0/50"
petCount.TextColor3 = Color3.fromRGB(200, 200, 200)
petCount.TextSize = 16
petCount.Font = Enum.Font.Gotham
petCount.TextXAlignment = Enum.TextXAlignment.Left
petCount.Parent = mainFrame

-- Filter buttons
local filterFrame = Instance.new("Frame")
filterFrame.Name = "FilterFrame"
filterFrame.Size = UDim2.new(1, -40, 0, 35)
filterFrame.Position = UDim2.new(0, 20, 0, 90)
filterFrame.BackgroundTransparency = 1
filterFrame.Parent = mainFrame

local filters = {"All", "Common", "Uncommon", "Rare", "Epic", "Legendary"}
local rarityColors = {
	All = Color3.fromRGB(150, 150, 150),
	Common = Color3.fromRGB(169, 169, 169),
	Uncommon = Color3.fromRGB(0, 255, 0),
	Rare = Color3.fromRGB(0, 100, 255),
	Epic = Color3.fromRGB(150, 0, 255),
	Legendary = Color3.fromRGB(255, 215, 0)
}

local currentFilter = "All"

for i, filter in ipairs(filters) do
	local btn = Instance.new("TextButton")
	btn.Name = filter .. "Filter"
	btn.Size = UDim2.new(0, 90, 1, 0)
	btn.Position = UDim2.new(0, (i-1) * 100, 0, 0)
	btn.BackgroundColor3 = rarityColors[filter]
	btn.Text = filter
	btn.TextColor3 = Color3.fromRGB(0, 0, 0)
	btn.TextSize = 14
	btn.Font = Enum.Font.GothamBold
	btn.Parent = filterFrame
	
	local btnCorner = Instance.new("UICorner")
	btnCorner.CornerRadius = UDim.new(0, 8)
	btnCorner.Parent = btn
	
	btn.MouseButton1Click:Connect(function()
		currentFilter = filter
		updateInventoryDisplay()
		
		-- Highlight selected
		for _, child in ipairs(filterFrame:GetChildren()) do
			if child:IsA("TextButton") then
				child.BackgroundTransparency = 0.5
			end
		end
		btn.BackgroundTransparency = 0
	end)
end

-- Scroll frame for pet grid
local scrollFrame = Instance.new("ScrollingFrame")
scrollFrame.Name = "PetGrid"
scrollFrame.Size = UDim2.new(1, -40, 1, -170)
scrollFrame.Position = UDim2.new(0, 20, 0, 135)
scrollFrame.BackgroundTransparency = 1
scrollFrame.ScrollBarThickness = 8
scrollFrame.ScrollBarImageColor3 = Color3.fromRGB(100, 100, 100)
scrollFrame.Parent = mainFrame

-- Grid layout
local gridLayout = Instance.new("UIGridLayout")
gridLayout.CellSize = UDim2.new(0, 150, 0, 180)
gridLayout.CellPadding = UDim2.new(0, 15, 0, 15)
gridLayout.HorizontalAlignment = Enum.HorizontalAlignment.Left
gridLayout.SortOrder = Enum.SortOrder.LayoutOrder
gridLayout.Parent = scrollFrame

-- Function to create pet card
local function createPetCard(petId, petData)
	local card = Instance.new("Frame")
	card.Name = "PetCard_" .. petId
	card.Size = UDim2.new(0, 150, 0, 180)
	card.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
	card.BorderSizePixel = 0
	
	local cardCorner = Instance.new("UICorner")
	cardCorner.CornerRadius = UDim.new(0, 12)
	cardCorner.Parent = card
	
	-- Rarity border
	local rarityColor = rarityColors[petData.Rarity] or Color3.fromRGB(150, 150, 150)
	local border = Instance.new("UIStroke")
	border.Color = rarityColor
	border.Thickness = 3
	border.Parent = card
	
	-- Pet icon (placeholder circle)
	local icon = Instance.new("Frame")
	icon.Name = "Icon"
	icon.Size = UDim2.new(0, 80, 0, 80)
	icon.Position = UDim2.new(0.5, -40, 0, 15)
	icon.BackgroundColor3 = rarityColor
	icon.BorderSizePixel = 0
	icon.Parent = card
	
	local iconCorner = Instance.new("UICorner")
	iconCorner.CornerRadius = UDim.new(1, 0)
	iconCorner.Parent = icon
	
	-- Pet name
	local nameLabel = Instance.new("TextLabel")
	nameLabel.Name = "Name"
	nameLabel.Size = UDim2.new(1, -10, 0, 25)
	nameLabel.Position = UDim2.new(0, 5, 0, 100)
	nameLabel.BackgroundTransparency = 1
	nameLabel.Text = petData.Template or "Unknown"
	nameLabel.TextColor3 = rarityColor
	nameLabel.TextSize = 16
	nameLabel.Font = Enum.Font.GothamBold
	nameLabel.Parent = card
	
	-- Power stat
	local powerLabel = Instance.new("TextLabel")
	powerLabel.Name = "Power"
	powerLabel.Size = UDim2.new(1, -10, 0, 20)
	powerLabel.Position = UDim2.new(0, 5, 0, 125)
	powerLabel.BackgroundTransparency = 1
	powerLabel.Text = "⚡ " .. (petData.Power or 0)
	powerLabel.TextColor3 = Color3.fromRGB(200, 200, 200)
	powerLabel.TextSize = 14
	powerLabel.Font = Enum.Font.Gotham
	powerLabel.Parent = card
	
	-- Coins multiplier
	local coinsLabel = Instance.new("TextLabel")
	coinsLabel.Name = "Coins"
	coinsLabel.Size = UDim2.new(1, -10, 0, 20)
	coinsLabel.Position = UDim2.new(0, 5, 0, 145)
	coinsLabel.BackgroundTransparency = 1
	coinsLabel.Text = "🪙 x" .. (petData.Coins or 1)
	coinsLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	coinsLabel.TextSize = 14
	coinsLabel.Font = Enum.Font.Gotham
	coinsLabel.Parent = card
	
	-- Click to select
	local clickBtn = Instance.new("TextButton")
	clickBtn.Name = "ClickArea"
	clickBtn.Size = UDim2.new(1, 0, 1, 0)
	clickBtn.BackgroundTransparency = 1
	clickBtn.Text = ""
	clickBtn.Parent = card
	
	clickBtn.MouseButton1Click:Connect(function()
		print("[InventoryUI] Selected pet: " .. petId)
		-- TODO: Show pet details popup
	end)
	
	-- Hover effect
	clickBtn.MouseEnter:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)}):Play()
	end)
	
	clickBtn.MouseLeave:Connect(function()
		TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)}):Play()
	end)
	
	return card
end

-- Function to update inventory display
local function updateInventoryDisplay()
	-- Clear current
	for _, child in ipairs(scrollFrame:GetChildren()) do
		if child:IsA("Frame") then
			child:Destroy()
		end
	end
	
	-- Get player data
	local leaderstats = player:FindFirstChild("leaderstats")
	if not leaderstats then return end
	
	-- For now, show placeholder data
	-- In real implementation, get from server
	local testPets = {
		{id = "pet_1", Template = "Tiny Dragon", Rarity = "Common", Power = 10, Coins = 1},
		{id = "pet_2", Template = "Baby Unicorn", Rarity = "Common", Power = 12, Coins = 1},
		{id = "pet_3", Template = "Fire Fox", Rarity = "Uncommon", Power = 20, Coins = 2},
	}
	
	local count = 0
	for _, pet in ipairs(testPets) do
		if currentFilter == "All" or pet.Rarity == currentFilter then
			local card = createPetCard(pet.id, pet)
			card.Parent = scrollFrame
			count = count + 1
		end
	end
	
	petCount.Text = "Pets: " .. count .. "/50"
	
	-- Update canvas size
	local rows = math.ceil(count / 4)
	scrollFrame.CanvasSize = UDim2.new(0, 0, 0, rows * 195 + 20)
end

-- Inventory button in main UI
local function createInventoryButton()
	local mainUI = gui:WaitForChild("GameUI", 10)
	if not mainUI then
		warn("[InventoryUI] GameUI not found!")
		return
	end
	
	local invBtn = Instance.new("TextButton")
	invBtn.Name = "InventoryButton"
	invBtn.Size = UDim2.new(0, 120, 0, 45)
	invBtn.Position = UDim2.new(0, 20, 1, -60)
	invBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
	invBtn.Text = "🎒 PETS"
	invBtn.TextSize = 18
	invBtn.Font = Enum.Font.GothamBold
	invBtn.Parent = mainUI
	
	local invCorner = Instance.new("UICorner")
	invCorner.CornerRadius = UDim.new(0, 10)
	invCorner.Parent = invBtn
	
	invBtn.MouseButton1Click:Connect(function()
		inventoryGui.Enabled = true
		updateInventoryDisplay()
		
		-- Animate opening
		mainFrame.Position = UDim2.new(0.5, -350, 0.5, -150)
		mainFrame.Size = UDim2.new(0, 700, 0, 400)
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Position = UDim2.new(0.5, -350, 0.5, -250),
			Size = UDim2.new(0, 700, 0, 500)
		}):Play()
	end)
	
	print("[InventoryUI] PETS button created!")
end

-- Wait for main UI then add button
if gui:FindFirstChild("GameUI") then
	createInventoryButton()
else
	-- Keep checking until GameUI exists
	task.spawn(function()
		local attempts = 0
		while attempts < 30 do
			if gui:FindFirstChild("GameUI") then
				createInventoryButton()
				return
			end
			attempts = attempts + 1
			task.wait(0.5)
		end
		warn("[InventoryUI] GameUI never found after 15 seconds")
	end)
end

print("[InventoryUI] Ready - Press 🎒 PETS button to open inventory")

return inventoryGui
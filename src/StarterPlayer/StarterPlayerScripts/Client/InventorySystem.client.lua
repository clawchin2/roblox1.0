-- InventorySystem.client.lua
-- Working inventory that shows ACTUAL hatched pets

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

print("[InventorySystem] Loading...")

-- ============================================
-- CONFIG
-- ============================================

-- Creature Images (Upload to Roblox and paste IDs here)
local CREATURE_IMAGES = {
	["Tiny Dragon"] = "rbxassetid://82027454638424",
	["Baby Unicorn"] = "rbxassetid://119581593087587",
	["Mini Griffin"] = "rbxassetid://114284266997339",
	["Fire Fox"] = "rbxassetid://114120834456818",
	["Ice Wolf"] = "rbxassetid://107644592223933",
	["Thunder Bird"] = "rbxassetid://119968731691178",
	["Phoenix"] = "rbxassetid://76964569512289",
	["Kraken"] = "rbxassetid://95763933606222",
	["Cerberus"] = "rbxassetid://85427973646431",
	["Hydra"] = "rbxassetid://80293685199042",
	["Chimera"] = "rbxassetid://104654764297240",
	["Ancient Dragon"] = "rbxassetid://0",
	["World Serpent"] = "rbxassetid://0",
}

local RARITY_COLORS = {
	All = Color3.fromRGB(150, 150, 150),
	Common = Color3.fromRGB(169, 169, 169),
	Uncommon = Color3.fromRGB(0, 255, 0),
	Rare = Color3.fromRGB(0, 100, 255),
	Epic = Color3.fromRGB(150, 0, 255),
	Legendary = Color3.fromRGB(255, 215, 0)
}

-- ============================================
-- PLAYER DATA
-- ============================================

local playerPets = {} -- Store actual hatched pets here

-- ============================================
-- CREATE INVENTORY UI
-- ============================================

local function createInventoryUI()
	local gameUI = playerGui:WaitForChild("GameUI", 5)
	if not gameUI then
		warn("[InventorySystem] GameUI not found!")
		return nil
	end
	
	-- Main inventory screen
	local invGui = Instance.new("ScreenGui")
	invGui.Name = "InventorySystem"
	invGui.ResetOnSpawn = false
	invGui.Enabled = false
	invGui.Parent = playerGui
	
	-- Main frame
	local mainFrame = Instance.new("Frame")
	mainFrame.Name = "MainFrame"
	mainFrame.Size = UDim2.new(0, 700, 0, 500)
	mainFrame.Position = UDim2.new(0.5, -350, 0.5, -250)
	mainFrame.BackgroundColor3 = Color3.fromRGB(30, 30, 40)
	mainFrame.BorderSizePixel = 0
	mainFrame.Parent = invGui
	
	Instance.new("UICorner", mainFrame).CornerRadius = UDim.new(0, 20)
	
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
	
	-- Pet count
	local petCount = Instance.new("TextLabel")
	petCount.Name = "PetCount"
	petCount.Size = UDim2.new(0, 200, 0, 30)
	petCount.Position = UDim2.new(0, 20, 0, 55)
	petCount.BackgroundTransparency = 1
	petCount.Text = "Pets: 0"
	petCount.TextColor3 = Color3.fromRGB(200, 200, 200)
	petCount.TextSize = 16
	petCount.Font = Enum.Font.Gotham
	petCount.TextXAlignment = Enum.TextXAlignment.Left
	petCount.Parent = mainFrame
	
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
	
	Instance.new("UICorner", closeBtn).CornerRadius = UDim.new(0, 10)
	
	closeBtn.MouseButton1Click:Connect(function()
		invGui.Enabled = false
	end)
	
	-- Filter buttons
	local filterFrame = Instance.new("Frame")
	filterFrame.Name = "FilterFrame"
	filterFrame.Size = UDim2.new(1, -40, 0, 35)
	filterFrame.Position = UDim2.new(0, 20, 0, 90)
	filterFrame.BackgroundTransparency = 1
	filterFrame.Parent = mainFrame
	
	local filters = {"All", "Common", "Uncommon", "Rare", "Epic", "Legendary"}
	local filterButtons = {}
	local currentFilter = "All"
	
	for i, filter in ipairs(filters) do
		local btn = Instance.new("TextButton")
		btn.Name = filter .. "Filter"
		btn.Size = UDim2.new(0, 100, 1, 0)
		btn.Position = UDim2.new(0, (i-1) * 110, 0, 0)
		btn.BackgroundColor3 = RARITY_COLORS[filter]
		btn.Text = filter
		btn.TextColor3 = Color3.fromRGB(0, 0, 0)
		btn.TextSize = 14
		btn.Font = Enum.Font.GothamBold
		btn.Parent = filterFrame
		
		Instance.new("UICorner", btn).CornerRadius = UDim.new(0, 8)
		
		filterButtons[filter] = btn
		
		btn.MouseButton1Click:Connect(function()
			currentFilter = filter
			updateDisplay()
			
			-- Update button transparency
			for _, b in pairs(filterButtons) do
				b.BackgroundTransparency = 0.5
			end
			btn.BackgroundTransparency = 0
		end)
	end
	
	-- Set default
	filterButtons["All"].BackgroundTransparency = 0
	
	-- Scroll frame for pets
	local scrollFrame = Instance.new("ScrollingFrame")
	scrollFrame.Name = "PetGrid"
	scrollFrame.Size = UDim2.new(1, -40, 1, -145)
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
	
	-- Empty state message
	local emptyLabel = Instance.new("TextLabel")
	emptyLabel.Name = "EmptyLabel"
	emptyLabel.Size = UDim2.new(1, 0, 0, 100)
	emptyLabel.Position = UDim2.new(0, 0, 0.5, -50)
	emptyLabel.BackgroundTransparency = 1
	emptyLabel.Text = "No pets yet!\n🥚 Hatch an egg to get started"
	emptyLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
	emptyLabel.TextSize = 20
	emptyLabel.Font = Enum.Font.GothamBold
	emptyLabel.Visible = false
	emptyLabel.Parent = scrollFrame
	
	-- Function to create pet card
	local function createPetCard(petData, index)
		local card = Instance.new("Frame")
		card.Name = "PetCard_" .. petData.id
		card.Size = UDim2.new(0, 150, 0, 180)
		card.BackgroundColor3 = Color3.fromRGB(40, 40, 50)
		card.BorderSizePixel = 0
		card.LayoutOrder = index
		card:SetAttribute("IsPetCard", true)
		
		Instance.new("UICorner", card).CornerRadius = UDim.new(0, 12)
		
		local rarityColor = RARITY_COLORS[petData.rarity] or RARITY_COLORS.Common
		
		-- Rarity border
		local border = Instance.new("UIStroke")
		border.Color = rarityColor
		border.Thickness = 3
		border.Parent = card
		
		-- Pet icon container (colored circle background)
		local icon = Instance.new("Frame")
		icon.Name = "Icon"
		icon.Size = UDim2.new(0, 80, 0, 80)
		icon.Position = UDim2.new(0.5, -40, 0, 15)
		icon.BackgroundColor3 = rarityColor
		icon.BorderSizePixel = 0
		icon.Parent = card
		
		Instance.new("UICorner", icon).CornerRadius = UDim.new(1, 0)
		
		-- Creature 2D Image
		local petImage = Instance.new("ImageLabel")
		petImage.Name = "PetImage"
		petImage.Size = UDim2.new(1, 0, 1, 0)
		petImage.BackgroundTransparency = 1
		petImage.Image = CREATURE_IMAGES[petData.name] or ""
		petImage.ScaleType = Enum.ScaleType.Fit
		petImage.Parent = icon
		
		Instance.new("UICorner", petImage).CornerRadius = UDim.new(1, 0)
		
		-- Pet name
		local nameLabel = Instance.new("TextLabel")
		nameLabel.Name = "Name"
		nameLabel.Size = UDim2.new(1, -10, 0, 25)
		nameLabel.Position = UDim2.new(0, 5, 0, 100)
		nameLabel.BackgroundTransparency = 1
		nameLabel.Text = petData.name or "Unknown"
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
		powerLabel.Text = "⚡ " .. (petData.power or 0)
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
		coinsLabel.Text = "🪙 x" .. (petData.coins or 1)
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
		
		local hoverTween = nil
		clickBtn.MouseEnter:Connect(function()
			if hoverTween then hoverTween:Cancel() end
			hoverTween = TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(50, 50, 60)})
			hoverTween:Play()
		end)
		
		clickBtn.MouseLeave:Connect(function()
			if hoverTween then hoverTween:Cancel() end
			hoverTween = TweenService:Create(card, TweenInfo.new(0.2), {BackgroundColor3 = Color3.fromRGB(40, 40, 50)})
			hoverTween:Play()
		end)
		
		clickBtn.MouseButton1Click:Connect(function()
			print("[Inventory] Selected pet: " .. petData.name)
		end)
		
		return card
	end
	
	-- UPDATE DISPLAY FUNCTION (defined here, called by filters)
	function updateDisplay()
		-- Clear existing pet cards safely
		for _, child in ipairs(scrollFrame:GetChildren()) do
			if child:GetAttribute("IsPetCard") then
				child:Destroy()
			end
		end
		
		-- Count pets matching filter
		local count = 0
		for i, pet in ipairs(playerPets) do
			if currentFilter == "All" or pet.rarity == currentFilter then
				local card = createPetCard(pet, i)
				card.Parent = scrollFrame
				count = count + 1
			end
		end
		
		-- Update pet count
		petCount.Text = "Pets: " .. count .. "/50"
		
		-- Show/hide empty state
		if count == 0 then
			emptyLabel.Visible = true
			scrollFrame.CanvasSize = UDim2.new(0, 0, 0, 0)
		else
			emptyLabel.Visible = false
			-- Use grid layout's actual content size
			scrollFrame.CanvasSize = UDim2.new(0, 0, 0, gridLayout.AbsoluteContentSize.Y + 20)
		end
	end
	
	-- PETS BUTTON (in GameUI)
	local petsBtn = Instance.new("TextButton")
	petsBtn.Name = "PetsButton"
	petsBtn.Size = UDim2.new(0, 120, 0, 45)
	petsBtn.Position = UDim2.new(0, 20, 0, 80)
	petsBtn.BackgroundColor3 = Color3.fromRGB(100, 100, 255)
	petsBtn.Text = "🎒 PETS"
	petsBtn.TextColor3 = Color3.fromRGB(255, 255, 255)
	petsBtn.TextSize = 20
	petsBtn.Font = Enum.Font.GothamBold
	petsBtn.Parent = gameUI
	
	Instance.new("UICorner", petsBtn).CornerRadius = UDim.new(0, 10)
	
	petsBtn.MouseButton1Click:Connect(function()
		updateDisplay()
		invGui.Enabled = true
		
		-- Animate opening
		mainFrame.Position = UDim2.new(0.5, -350, 0.5, -150)
		mainFrame.Size = UDim2.new(0, 700, 0, 400)
		TweenService:Create(mainFrame, TweenInfo.new(0.3, Enum.EasingStyle.Back), {
			Position = UDim2.new(0.5, -350, 0.5, -250),
			Size = UDim2.new(0, 700, 0, 500)
		}):Play()
	end)
	
	print("[InventorySystem] UI created successfully!")
	
	return invGui
end

-- ============================================
-- ADD PET WHEN HATCHED
-- ============================================

local function addHatchedPet(petData)
	print("[InventorySystem] Adding pet: " .. petData.name)
	
	table.insert(playerPets, {
		id = petData.id or ("pet_" .. #playerPets + 1),
		name = petData.name or "Unknown",
		rarity = petData.rarity or "Common",
		power = petData.speed or 0, -- Using speed as power
		coins = petData.coins or 1
	})
	
	print("[InventorySystem] Now have " .. #playerPets .. " pets")
end

-- ============================================
-- CONNECT TO HATCH EVENT
-- ============================================

task.spawn(function()
	-- Wait for HatchUI to load first
	task.wait(3)
	
	-- Create the inventory UI
	local invGui = createInventoryUI()
	if not invGui then
		warn("[InventorySystem] Failed to create UI!")
		return
	end
	
	-- Listen for hatch events
	local hatchEvent = ReplicatedStorage:WaitForChild("HatchEvent", 10)
	if hatchEvent then
		hatchEvent.OnClientEvent:Connect(function(data)
			if data and data.success then
				-- Pet was hatched! Add to inventory
				addHatchedPet({
					id = data.id,
					name = data.name,
					rarity = data.rarity,
					speed = data.speed,
					coins = data.coins
				})
			end
		end)
		print("[InventorySystem] Connected to hatch events!")
	else
		warn("[InventorySystem] Could not find HatchEvent!")
	end
end)

print("[InventorySystem] Loaded!")
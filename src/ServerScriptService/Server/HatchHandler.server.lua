-- HatchHandler.server.lua
-- Handles egg hatching mechanics and pet distribution
-- FIXED: Race condition - event created at module load time

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local HttpService = game:GetService("HttpService")

print("[HatchHandler] Initializing...")

-- ============================================
-- CONFIGURATION (From Expert Knowledge)
-- ============================================

-- Pet definitions with rarities
local PETS = {
	-- Common pets (50% chance)
	{
		id = "dog",
		name = "Dog",
		rarity = "Common",
		weight = 50,
		stats = {speed = 5, jump = 0, coins = 1.1},
		color = Color3.fromRGB(169, 169, 169)
	},
	{
		id = "cat",
		name = "Cat",
		rarity = "Common",
		weight = 50,
		stats = {speed = 3, jump = 2, coins = 1.1},
		color = Color3.fromRGB(169, 169, 169)
	},
	
	-- Uncommon pets (30% chance)
	{
		id = "rabbit",
		name = "Rabbit",
		rarity = "Uncommon",
		weight = 30,
		stats = {speed = 8, jump = 5, coins = 1.25},
		color = Color3.fromRGB(0, 255, 0)
	},
	{
		id = "fox",
		name = "Fox",
		rarity = "Uncommon",
		weight = 30,
		stats = {speed = 10, jump = 3, coins = 1.3},
		color = Color3.fromRGB(0, 255, 0)
	},
	
	-- Rare pets (15% chance)
	{
		id = "dragon",
		name = "Baby Dragon",
		rarity = "Rare",
		weight = 15,
		stats = {speed = 12, jump = 8, coins = 1.5},
		color = Color3.fromRGB(0, 100, 255)
	},
	{
		id = "unicorn",
		name = "Unicorn",
		rarity = "Rare",
		weight = 15,
		stats = {speed = 15, jump = 10, coins = 1.6},
		color = Color3.fromRGB(0, 100, 255)
	},
	
	-- Legendary pets (5% chance)
	{
		id = "phoenix",
		name = "Phoenix",
		rarity = "Legendary",
		weight = 5,
		stats = {speed = 20, jump = 15, coins = 2.0},
		color = Color3.fromRGB(255, 215, 0)
	}
}

-- Rarity configuration
local RARITY_COLORS = {
	Common = Color3.fromRGB(169, 169, 169),    -- Gray
	Uncommon = Color3.fromRGB(0, 255, 0),      -- Green
	Rare = Color3.fromRGB(0, 100, 255),        -- Blue
	Legendary = Color3.fromRGB(255, 215, 0)    -- Gold
}

-- Egg prices
local EGG_PRICES = {
	basic = 100,
	rare = 500,
	legendary = 1500
}

-- ============================================
-- REMOTE EVENT SETUP (FIXED)
-- ============================================

-- FIXED: Ensure event exists at module load, not in function
local hatchEvent = ReplicatedStorage:FindFirstChild("HatchEvent") or Instance.new("RemoteEvent")
hatchEvent.Name = "HatchEvent"
hatchEvent.Parent = ReplicatedStorage

local hatchRequestEvent = ReplicatedStorage:FindFirstChild("HatchRequest") or Instance.new("RemoteEvent")
hatchRequestEvent.Name = "HatchRequest"
hatchRequestEvent.Parent = ReplicatedStorage

print("[HatchHandler] RemoteEvents created successfully")

-- ============================================
-- HELPER FUNCTIONS
-- ============================================

-- Weighted random selection (from Expert Knowledge)
local function rollPet()
	local totalWeight = 0
	for _, pet in ipairs(PETS) do
		totalWeight = totalWeight + pet.weight
	end
	
	local random = math.random(1, totalWeight)
	local current = 0
	
	for _, pet in ipairs(PETS) do
		current = current + pet.weight
		if random <= current then
			return pet
		end
	end
	
	return PETS[1] -- Fallback
end

-- Get egg price
local function getEggPrice(eggType)
	return EGG_PRICES[eggType] or EGG_PRICES.basic
end

-- Get player coins
local function getPlayerCoins(player)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then
			return coins.Value
		end
	end
	return 0
end

-- Deduct coins from player
local function deductCoins(player, amount)
	local leaderstats = player:FindFirstChild("leaderstats")
	if leaderstats then
		local coins = leaderstats:FindFirstChild("Coins")
		if coins then
			coins.Value = math.max(0, coins.Value - amount)
			return true
		end
	end
	return false
end

-- Get rarity color
local function getRarityColor(rarity)
	return RARITY_COLORS[rarity] or Color3.fromRGB(255, 255, 255)
end

-- ============================================
-- MAIN HATCH FUNCTION
-- ============================================

local function hatchEgg(player, eggType)
	print("[HatchHandler] " .. player.Name .. " requested to hatch " .. (eggType or "basic") .. " egg")
	
	-- Validate player
	if not player or not player.Parent then
		warn("[HatchHandler] Invalid player")
		return
	end
	
	-- Get egg price
	local price = getEggPrice(eggType)
	
	-- Check if player has enough coins
	local currentCoins = getPlayerCoins(player)
	if currentCoins < price then
		print("[HatchHandler] " .. player.Name .. " doesn't have enough coins (has " .. currentCoins .. ", needs " .. price .. ")")
		hatchEvent:FireClient(player, nil, "Not enough coins! Need " .. price .. " coins.")
		return
	end
	
	-- Deduct coins
	if not deductCoins(player, price) then
		warn("[HatchHandler] Failed to deduct coins from " .. player.Name)
		return
	end
	
	-- Roll for pet
	local pet = rollPet()
	
	-- Create pet data
	local petData = {
		id = pet.id,
		name = pet.name,
		rarity = pet.rarity,
		stats = pet.stats,
		hatchedAt = os.time()
	}
	
	-- Store equipped pet
	player:SetAttribute("EquippedPet", pet.id)
	player:SetAttribute("EquippedPetName", pet.name)
	player:SetAttribute("EquippedPetRarity", pet.rarity)
	
	-- Serialize stats to attribute
	local statsJson = HttpService:JSONEncode(pet.stats)
	player:SetAttribute("EquippedPetStats", statsJson)
	
	-- Add to pet collection
	local existingPets = player:GetAttribute("PetCollection") or ""
	local newEntry = pet.id .. ":" .. tostring(os.time()) .. ";"
	player:SetAttribute("PetCollection", existingPets .. newEntry)
	
	print("[HatchHandler] " .. player.Name .. " hatched " .. pet.name .. " (" .. pet.rarity .. ")!")
	
	-- Prepare client data
	local clientPetData = {
		id = pet.id,
		name = pet.name,
		rarity = pet.rarity,
		rarityColor = {
			r = getRarityColor(pet.rarity).R,
			g = getRarityColor(pet.rarity).G,
			b = getRarityColor(pet.rarity).B
		},
		stats = pet.stats,
		message = "Congratulations! You hatched a " .. pet.rarity .. " pet!"
	}
	
	-- Fire event to client
	hatchEvent:FireClient(player, clientPetData)
	
	-- Spawn pet follower
	spawnPetForPlayer(player, pet)
end

-- ============================================
-- PET FOLLOWING SYSTEM (From Expert Knowledge)
-- ============================================

local activePets = {}

function spawnPetForPlayer(player, petData)
	if not player or not player.Character then
		return
	end
	
	-- Remove existing pet if any
	if activePets[player] then
		activePets[player]:Destroy()
		activePets[player] = nil
	end
	
	-- Create simple pet model
	local petModel = Instance.new("Model")
	petModel.Name = petData.name
	
	-- Create pet part (basic sphere for now)
	local petPart = Instance.new("Part")
	petPart.Name = "PetBody"
	petPart.Size = Vector3.new(2, 2, 2)
	petPart.Shape = Enum.PartType.Ball
	petPart.Color = getRarityColor(petData.rarity)
	petPart.Material = Enum.Material.SmoothPlastic
	petPart.CanCollide = false
	petPart.Parent = petModel
	
	-- Set primary part
	petModel.PrimaryPart = petPart
	
	-- Add BodyPosition for smooth following
	local bodyPos = Instance.new("BodyPosition")
	bodyPos.MaxForce = Vector3.new(4000, 4000, 4000)
	bodyPos.D = 100
	bodyPos.P = 10000
	bodyPos.Parent = petPart
	
	-- Add BodyGyro for rotation
	local bodyGyro = Instance.new("BodyGyro")
	bodyGyro.MaxTorque = Vector3.new(4000, 4000, 4000)
	bodyGyro.D = 100
	bodyGyro.P = 10000
	bodyGyro.Parent = petPart
	
	-- Parent to workspace
	petModel.Parent = workspace
	
	-- Store reference
	activePets[player] = petModel
	
	-- Start following loop
	task.spawn(function()
		while activePets[player] == petModel and player.Parent do
			local success, err = pcall(function()
				if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
					local hrp = player.Character.HumanoidRootPart
					
					-- Calculate position behind player (3 studs back)
					local offset = Vector3.new(2, 0, 2)
					local targetPos = hrp.Position + (hrp.CFrame.LookVector * -3) + offset
					
					bodyPos.Position = targetPos
					bodyGyro.CFrame = CFrame.new(petPart.Position, hrp.Position)
				end
			end)
			
			if not success then
				warn("[HatchHandler] Pet follow error: " .. tostring(err))
			end
			
			task.wait(0.1)
		end
	end)
	
	print("[HatchHandler] Spawned " .. petData.name .. " pet for " .. player.Name)
end

-- ============================================
-- CLEANUP HANDLERS
-- ============================================

-- Clean up pet when player leaves
Players.PlayerRemoving:Connect(function(player)
	if activePets[player] then
		activePets[player]:Destroy()
		activePets[player] = nil
		print("[HatchHandler] Cleaned up pet for " .. player.Name)
	end
end)

-- Clean up pet when character resets
Players.PlayerAdded:Connect(function(player)
	player.CharacterRemoving:Connect(function()
		if activePets[player] then
			activePets[player]:Destroy()
			activePets[player] = nil
		end
	end)
end)

-- ============================================
-- EVENT HANDLERS
-- ============================================

hatchRequestEvent.OnServerEvent:Connect(function(player, eggType)
	hatchEgg(player, eggType)
end)

print("[HatchHandler] Ready! HatchEvent and HatchRequest events are available.")

return {
	PETS = PETS,
	rollPet = rollPet,
	hatchEgg = hatchEgg,
	getRarityColor = getRarityColor,
	spawnPetForPlayer = spawnPetForPlayer
}

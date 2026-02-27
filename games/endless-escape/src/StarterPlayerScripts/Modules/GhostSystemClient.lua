--!strict
-- GhostSystemClient.lua
-- Client-side ghost rendering and "Beat Your Best" UI
-- Location: StarterPlayerScripts/Modules/GhostSystemClient.lua

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local playerGui = player:WaitForChild("PlayerGui")

local GhostSystemClient = {}

-- RemoteEvents
local GhostEvents = ReplicatedStorage:WaitForChild("GhostEvents")
local GhostPlaybackEvent = GhostEvents:WaitForChild("GhostPlayback")

-- ============================================================================
-- UI CREATION
-- ============================================================================

local function createGhostUI()
	local screenGui = Instance.new("ScreenGui")
	screenGui.Name = "GhostUI"
	screenGui.ResetOnSpawn = false
	screenGui.Parent = playerGui
	
	-- "Beat Your Best!" label
	local beatLabel = Instance.new("TextLabel")
	beatLabel.Name = "BeatBestLabel"
	beatLabel.Size = UDim2.new(0, 300, 0, 40)
	beatLabel.Position = UDim2.new(0.5, -150, 0.15, 0)
	beatLabel.BackgroundTransparency = 1
	beatLabel.Text = "BEAT YOUR BEST!"
	beatLabel.TextColor3 = Color3.fromRGB(255, 215, 0)
	beatLabel.TextStrokeTransparency = 0
	beatLabel.TextStrokeColor3 = Color3.fromRGB(200, 150, 0)
	beatLabel.TextScaled = true
	beatLabel.Font = Enum.Font.GothamBlack
	beatLabel.Visible = false
	beatLabel.Parent = screenGui
	
	-- Add glow effect
	local glow = Instance.new("UIStroke")
	glow.Name = "Glow"
	glow.Thickness = 3
	glow.Color = Color3.fromRGB(255, 255, 0)
	glow.Transparency = 0.5
	glow.Parent = beatLabel
	
	-- Ghost distance indicator
	local ghostIndicator = Instance.new("Frame")
	ghostIndicator.Name = "GhostIndicator"
	ghostIndicator.Size = UDim2.new(0, 200, 0, 60)
	ghostIndicator.Position = UDim2.new(0.5, -100, 0.2, 0)
	ghostIndicator.BackgroundColor3 = Color3.fromRGB(30, 30, 50)
	ghostIndicator.BackgroundTransparency = 0.3
	ghostIndicator.BorderSizePixel = 0
	ghostIndicator.Visible = false
	ghostIndicator.Parent = screenGui
	
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(0, 10)
	corner.Parent = ghostIndicator
	
	local ghostIcon = Instance.new("TextLabel")
	ghostIcon.Name = "Icon"
	ghostIcon.Size = UDim2.new(0, 40, 0, 40)
	ghostIcon.Position = UDim2.new(0, 10, 0.5, -20)
	ghostIcon.BackgroundTransparency = 1
	ghostIcon.Text = "👻"
	ghostIcon.TextScaled = true
	ghostIcon.Parent = ghostIndicator
	
	local ghostName = Instance.new("TextLabel")
	ghostName.Name = "GhostName"
	ghostName.Size = UDim2.new(1, -60, 0, 20)
	ghostName.Position = UDim2.new(0, 55, 0, 5)
	ghostName.BackgroundTransparency = 1
	ghostName.Text = "Your Best"
	ghostName.TextColor3 = Color3.fromRGB(150, 150, 255)
	ghostName.TextXAlignment = Enum.TextXAlignment.Left
	ghostName.Font = Enum.Font.GothamBold
	ghostName.TextSize = 16
	ghostName.Parent = ghostIndicator
	
	local ghostDistance = Instance.new("TextLabel")
	ghostDistance.Name = "GhostDistance"
	ghostDistance.Size = UDim2.new(1, -60, 0, 20)
	ghostDistance.Position = UDim2.new(0, 55, 0, 30)
	ghostDistance.BackgroundTransparency = 1
	ghostDistance.Text = "0m"
	ghostDistance.TextColor3 = Color3.fromRGB(255, 255, 255)
	ghostDistance.TextXAlignment = Enum.TextXAlignment.Left
	ghostDistance.Font = Enum.Font.Gotham
	ghostDistance.TextSize = 14
	ghostDistance.Parent = ghostIndicator
	
	-- Distance comparison bar
	local comparisonBar = Instance.new("Frame")
	comparisonBar.Name = "ComparisonBar"
	comparisonBar.Size = UDim2.new(0, 300, 0, 30)
	comparisonBar.Position = UDim2.new(0.5, -150, 0.85, 0)
	comparisonBar.BackgroundColor3 = Color3.fromRGB(40, 40, 40)
	comparisonBar.BorderSizePixel = 0
	comparisonBar.Visible = false
	comparisonBar.Parent = screenGui
	
	local barCorner = Instance.new("UICorner")
	barCorner.CornerRadius = UDim.new(0, 15)
	barCorner.Parent = comparisonBar
	
	-- Player progress
	local playerBar = Instance.new("Frame")
	playerBar.Name = "PlayerBar"
	playerBar.Size = UDim2.new(0.5, 0, 1, 0)
	playerBar.Position = UDim2.new(0, 0, 0, 0)
	playerBar.BackgroundColor3 = Color3.fromRGB(0, 200, 100)
	playerBar.BorderSizePixel = 0
	playerBar.Parent = comparisonBar
	
	local playerCorner = Instance.new("UICorner")
	playerCorner.CornerRadius = UDim.new(0, 15)
	playerCorner.Parent = playerBar
	
	-- Ghost progress
	local ghostBar = Instance.new("Frame")
	ghostBar.Name = "GhostBar"
	ghostBar.Size = UDim2.new(0.5, 0, 1, 0)
	ghostBar.Position = UDim2.new(0.5, 0, 0, 0)
	ghostBar.BackgroundColor3 = Color3.fromRGB(150, 150, 255)
	ghostBar.BorderSizePixel = 0
	ghostBar.Parent = comparisonBar
	
	local ghostCorner = Instance.new("UICorner")
	ghostCorner.CornerRadius = UDim.new(0, 15)
	ghostCorner.Parent = ghostBar
	
	-- Labels
	local playerLabel = Instance.new("TextLabel")
	playerLabel.Name = "PlayerLabel"
	playerLabel.Size = UDim2.new(0.5, 0, 1, 0)
	playerLabel.BackgroundTransparency = 1
	playerLabel.Text = "YOU"
	playerLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	playerLabel.Font = Enum.Font.GothamBold
	playerLabel.TextSize = 14
	playerLabel.Parent = comparisonBar
	
	local ghostLabel = Instance.new("TextLabel")
	ghostLabel.Name = "GhostLabel"
	ghostLabel.Size = UDim2.new(0.5, 0, 1, 0)
	ghostLabel.Position = UDim2.new(0.5, 0, 0, 0)
	ghostLabel.BackgroundTransparency = 1
	ghostLabel.Text = "GHOST"
	ghostLabel.TextColor3 = Color3.fromRGB(255, 255, 255)
	ghostLabel.Font = Enum.Font.GothamBold
	ghostLabel.TextSize = 14
	ghostLabel.Parent = comparisonBar
	
	return {
		screenGui = screenGui,
		beatLabel = beatLabel,
		ghostIndicator = ghostIndicator,
		ghostName = ghostName,
		ghostDistance = ghostDistance,
		comparisonBar = comparisonBar,
		playerBar = playerBar,
		ghostBar = ghostBar,
	}
end

-- ============================================================================
-- GHOST RENDERING
-- ============================================================================

local ghostModel: Model?
local ghostTrail: Trail?
local currentGhostPositions: {Vector3}?
local ghostPlaybackConnection: RBXScriptConnection?

local function createClientGhostModel(isFriend: boolean): Model
	local ghost = Instance.new("Model")
	ghost.Name = isFriend and "FriendGhost" or "PersonalGhost"
	
	local hrp = Instance.new("Part")
	hrp.Name = "HumanoidRootPart"
	hrp.Size = Vector3.new(2, 2, 1)
	hrp.Anchored = true
	hrp.CanCollide = false
	hrp.Transparency = 0.6
	hrp.Color = isFriend and Color3.fromRGB(100, 255, 100) or Color3.fromRGB(150, 150, 255)
	hrp.Material = Enum.Material.Neon
	hrp.Parent = ghost
	
	-- Trail
	local att0 = Instance.new("Attachment")
	att0.Position = Vector3.new(0, 0, -0.5)
	att0.Parent = hrp
	
	local att1 = Instance.new("Attachment")
	att1.Position = Vector3.new(0, 0, 0.5)
	att1.Parent = hrp
	
	local trail = Instance.new("Trail")
	trail.Color = ColorSequence.new(hrp.Color)
	trail.Transparency = NumberSequence.new(0.6)
	trail.Lifetime = 1
	trail.WidthScale = NumberSequence.new(1)
	trail.Attachment0 = att0
	trail.Attachment1 = att1
	trail.Parent = hrp
	
	ghost.PrimaryPart = hrp
	ghost.Parent = workspace
	
	return ghost
end

local function startGhostPlayback(positions: {Vector3}, ghostOwnerId: number)
	-- Clean up existing ghost
	if ghostPlaybackConnection then
		ghostPlaybackConnection:Disconnect()
		ghostPlaybackConnection = nil
	end
	if ghostModel then
		ghostModel:Destroy()
		ghostModel = nil
	end
	
	if #positions < 2 then return end
	
	local isOwnGhost = ghostOwnerId == player.UserId
	ghostModel = createClientGhostModel(not isOwnGhost)
	currentGhostPositions = positions
	
	local ui = createGhostUI()
	ui.beatLabel.Visible = isOwnGhost
	ui.ghostIndicator.Visible = true
	ui.comparisonBar.Visible = true
	
	-- Animate ghost
	local startTime = os.clock()
	local recordInterval = 0.5
	local totalDuration = #positions * recordInterval
	local bestDistance = (#positions - 1) * 8 -- Rough estimate
	
	ghostPlaybackConnection = RunService.Heartbeat:Connect(function()
		if not ghostModel or not ghostModel.Parent then return end
		
		local elapsed = os.clock() - startTime
		local currentIndex = math.min(math.floor(elapsed / recordInterval) + 1, #positions)
		
		if currentIndex >= #positions then
			-- Ghost finished
			ui.beatLabel.Visible = false
			return
		end
		
		local hrp = ghostModel:FindFirstChild("HumanoidRootPart")
		if hrp and positions[currentIndex] then
			local targetPos = positions[currentIndex]
			local nextPos = positions[currentIndex + 1] or targetPos
			local alpha = (elapsed % recordInterval) / recordInterval
			
			hrp.Position = targetPos:Lerp(nextPos, alpha)
			hrp.CFrame = CFrame.lookAt(hrp.Position, nextPos)
			
			-- Update ghost distance UI
			local ghostDist = math.floor((currentIndex - 1) * 8)
			ui.ghostDistance.Text = tostring(ghostDist) .. "m"
			
			-- Update comparison bar
			local playerDist = 0 -- Would get from distance tracker
			local totalDist = math.max(playerDist, ghostDist, bestDistance)
			if totalDist > 0 then
				ui.playerBar.Size = UDim2.new(playerDist / totalDist, 0, 1, 0)
				ui.ghostBar.Size = UDim2.new(ghostDist / totalDist, 0, 1, 0)
				ui.ghostBar.Position = UDim2.new(playerDist / totalDist, 0, 0, 0)
			end
		end
	end)
end

-- ============================================================================
-- PUBLIC API
-- ============================================================================

function GhostSystemClient:Init()
	-- Listen for ghost playback events from server
	GhostPlaybackEvent.OnClientEvent:Connect(function(ghostOwnerId: number, positions: {Vector3})
		startGhostPlayback(positions, ghostOwnerId)
	end)
	
	-- Clean up on death
	local function onCharacterAdded(character: Model)
		local humanoid = character:WaitForChild("Humanoid")
		humanoid.Died:Connect(function()
			if ghostPlaybackConnection then
				ghostPlaybackConnection:Disconnect()
				ghostPlaybackConnection = nil
			end
			if ghostModel then
				ghostModel:Destroy()
				ghostModel = nil
			end
			
			-- Hide UI
			local ghostUI = playerGui:FindFirstChild("GhostUI")
			if ghostUI then
				ghostUI:Destroy()
			end
		end)
	end
	
	if player.Character then
		onCharacterAdded(player.Character)
	end
	player.CharacterAdded:Connect(onCharacterAdded)
	
	print("[GhostSystemClient] Initialized")
end

return GhostSystemClient

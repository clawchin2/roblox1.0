-- DEBUG TEST SCRIPT
-- Run this in Roblox Studio Command Bar to test if systems work

print("=== DEBUG TEST ===")

-- Test 1: Check leaderstats
for _, player in ipairs(game.Players:GetPlayers()) do
    print("Player: " .. player.Name)
    local leaderstats = player:FindFirstChild("leaderstats")
    if leaderstats then
        print("  Leaderstats found")
        local score = leaderstats:FindFirstChild("Score")
        local coins = leaderstats:FindFirstChild("Coins")
        print("  Score: " .. (score and score.Value or "N/A"))
        print("  Coins: " .. (coins and coins.Value or "N/A"))
    else
        print("  ERROR: No leaderstats!")
    end
end

-- Test 2: Check GeneratedLevel folder
local genLevel = workspace:FindFirstChild("GeneratedLevel")
if genLevel then
    print("\nGeneratedLevel folder found")
    print("  Platforms: " .. tostring(#genLevel:GetChildren()))
    local coinCount = 0
    for _, child in ipairs(genLevel:GetChildren()) do
        if child.Name == "Coin" then
            coinCount = coinCount + 1
        end
    end
    print("  Coins: " .. coinCount)
else
    print("\nERROR: GeneratedLevel folder not found!")
end

-- Test 3: Check workspace for coins
print("\nAll Coins in workspace:")
for _, obj in ipairs(workspace:GetDescendants()) do
    if obj.Name == "Coin" and obj:IsA("BasePart") then
        print("  Coin at " .. tostring(obj.Position))
    end
end

-- Test 4: Manually add coins to test
print("\n=== Adding test coin ===")
local testCoin = Instance.new("Part")
testCoin.Name = "Coin"
testCoin.Shape = Enum.PartType.Ball
testCoin.Size = Vector3.new(3, 3, 3)
testCoin.Position = Vector3.new(0, 15, -10)
testCoin.Color = Color3.fromRGB(255, 215, 0)
testCoin.Material = Enum.Material.Neon
testCoin.Anchored = true
testCoin.CanCollide = false
testCoin:SetAttribute("CoinValue", 10)
testCoin.Parent = workspace
print("Test coin created at " .. tostring(testCoin.Position))

print("\n=== DEBUG TEST COMPLETE ===")
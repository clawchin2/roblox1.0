-- Hatch Handler - FIXED argument matching
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create RemoteEvent ONCE
local hatchEvent = ReplicatedStorage:FindFirstChild("HatchEvent")
if not hatchEvent then
    hatchEvent = Instance.new("RemoteEvent")
    hatchEvent.Name = "HatchEvent"
    hatchEvent.Parent = ReplicatedStorage
end

-- Valid egg types and prices
local EGG_PRICES = {
    ["basic_egg"] = 100,
    ["fantasy_egg"] = 500,
    ["mythic_egg"] = 2000
}

-- Handle hatch requests
hatchEvent.OnServerEvent:Connect(function(player, eggType)
    print("[Hatch] Request from " .. player.Name .. " for " .. tostring(eggType))
    
    -- Validate
    if not eggType or type(eggType) ~= "string" then
        hatchEvent:FireClient(player, {success = false, error = "Invalid egg type"})
        return
    end
    
    local price = EGG_PRICES[eggType]
    if not price then
        hatchEvent:FireClient(player, {success = false, error = "Unknown egg: " .. eggType})
        return
    end
    
    -- Check _G.HatchEgg exists
    if not _G.HatchEgg then
        hatchEvent:FireClient(player, {success = false, error = "Hatch system not ready"})
        return
    end
    
    -- Call hatch function
    local pet, errorMsg = _G.HatchEgg(player, eggType)
    
    if pet then
        -- Send success data as SINGLE TABLE
        hatchEvent:FireClient(player, {
            success = true,
            name = pet.name,
            rarity = pet.rarity,
            id = pet.id,
            speed = pet.speed,
            coins = pet.coins
        })
        print("[Hatch] SUCCESS: " .. player.Name .. " got " .. pet.name)
    else
        -- Send error as SINGLE TABLE
        hatchEvent:FireClient(player, {
            success = false,
            error = errorMsg or "Hatch failed"
        })
        print("[Hatch] FAIL: " .. player.Name .. " - " .. tostring(errorMsg))
    end
end)
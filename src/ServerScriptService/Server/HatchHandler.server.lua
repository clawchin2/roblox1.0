-- Hatch Handler - WITHOUT CreatureModels dependency
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create remote event
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
        -- Just notify client - NO visual spawning for now
        hatchEvent:FireClient(player, {
            success = true,
            name = pet.name,
            rarity = pet.rarity,
            id = pet.id,
            speed = pet.speed,
            coins = pet.coins,
            eggType = eggType
        })
        print("[Hatch] SUCCESS: " .. player.Name .. " got " .. pet.name .. " (coins: " .. tostring(pet.coins) .. ")")
    else
        hatchEvent:FireClient(player, {
            success = false,
            error = errorMsg or "Hatch failed"
        })
        print("[Hatch] FAIL: " .. player.Name .. " - " .. tostring(errorMsg))
    end
end)

print("[Hatch] Ready - CreatureModels disabled for now")
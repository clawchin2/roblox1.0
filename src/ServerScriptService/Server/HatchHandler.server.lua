-- Hatch Event Handler
local ReplicatedStorage = game:GetService("ReplicatedStorage")

-- Create remote event
local hatchEvent = Instance.new("RemoteEvent")
hatchEvent.Name = "HatchEvent"
hatchEvent.Parent = ReplicatedStorage

-- Handle hatch requests
hatchEvent.OnServerEvent:Connect(function(player, eggType)
    print("[Server] Hatch request from " .. player.Name .. " for " .. eggType)
    
    local pet, error = _G.HatchEgg(player, eggType)
    
    if pet then
        -- Send pet data as simple values (tables don't replicate well)
        local petData = {
            name = pet.name,
            rarity = pet.rarity,
            id = pet.id,
            speed = pet.speed,
            coins = pet.coins
        }
        hatchEvent:FireClient(player, "success", petData)
        print("[Server] " .. player.Name .. " hatched " .. pet.name .. " (" .. pet.rarity .. ")")
    else
        hatchEvent:FireClient(player, "fail", error)
        print("[Server] Hatch failed for " .. player.Name .. ": " .. error)
    end
end)
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
        -- Tell client what they got
        hatchEvent:FireClient(player, "success", pet)
        print("[Server] " .. player.Name .. " hatched " .. pet.name .. " (" .. pet.rarity .. ")")
    else
        hatchEvent:FireClient(player, "fail", error)
        print("[Server] Hatch failed for " .. player.Name .. ": " .. error)
    end
end)
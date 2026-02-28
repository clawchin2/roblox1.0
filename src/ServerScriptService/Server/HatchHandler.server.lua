-- Hatch Handler - with visual pet spawning
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Create remote event
local hatchEvent = ReplicatedStorage:FindFirstChild("HatchEvent")
if not hatchEvent then
    hatchEvent = Instance.new("RemoteEvent")
    hatchEvent.Name = "HatchEvent"
    hatchEvent.Parent = ReplicatedStorage
end

-- Load CreatureModels
local CreatureModels = require(ReplicatedStorage.Modules.CreatureModels)

-- Spawn visual pet
local function spawnVisualPet(player, petTemplate)
    print("[Hatch] Spawning visual pet: " .. petTemplate)
    
    local modelFunc = nil
    
    -- Map template names to model functions
    if petTemplate == "Tiny Dragon" then
        modelFunc = CreatureModels.TinyDragon
    elseif petTemplate == "Baby Unicorn" then
        modelFunc = CreatureModels.BabyUnicorn
    elseif petTemplate == "Mini Griffin" then
        modelFunc = CreatureModels.MiniGriffin
    elseif petTemplate == "Fire Fox" then
        modelFunc = CreatureModels.FireFox
    else
        -- Default to dragon for now
        modelFunc = CreatureModels.TinyDragon
    end
    
    if modelFunc then
        local pet = modelFunc()
        local char = player.Character
        if char then
            local hrp = char:FindFirstChild("HumanoidRootPart")
            if hrp then
                pet:SetPrimaryPartCFrame(hrp.CFrame * CFrame.new(3, 0, 3))
                pet.Parent = workspace
                print("[Hatch] Pet spawned and visible!")
                
                -- Make it follow player (simple version)
                task.spawn(function()
                    while pet and pet.Parent do
                        task.wait(0.1)
                        if player.Character and player.Character:FindFirstChild("HumanoidRootPart") then
                            local playerPos = player.Character.HumanoidRootPart.Position
                            local petPos = pet.PrimaryPart.Position
                            local targetPos = playerPos + Vector3.new(3, 0, 3)
                            pet:SetPrimaryPartCFrame(CFrame.new(petPos:Lerp(targetPos, 0.1)))
                        end
                    end
                end)
                
                return pet
            end
        end
    end
    return nil
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
        -- Spawn the 3D model!
        spawnVisualPet(player, pet.name)
        
        -- Send success to client
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
        hatchEvent:FireClient(player, {
            success = false,
            error = errorMsg or "Hatch failed"
        })
        print("[Hatch] FAIL: " .. player.Name .. " - " .. tostring(errorMsg))
    end
end)

print("[Hatch] Ready with visual pet spawning")
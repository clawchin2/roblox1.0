-- CreatureModels.lua
-- 3D pet models built from Roblox parts
-- Based on the 2D concept art images

local CreatureModels = {}

-- Helper function to create a part
local function createPart(name, size, color, position, shape)
    local part = Instance.new("Part")
    part.Name = name
    part.Size = size
    part.Color = color
    part.Position = position
    part.Shape = shape or Enum.PartType.Ball
    part.Material = Enum.Material.SmoothPlastic
    part.TopSurface = Enum.SurfaceType.Smooth
    part.BottomSurface = Enum.SurfaceType.Smooth
    return part
end

-- 1. TINY DRAGON (Common) - Red baby dragon
function CreatureModels.TinyDragon()
    local model = Instance.new("Model")
    model.Name = "TinyDragon"
    
    -- Body (red sphere)
    local body = createPart("Body", Vector3.new(2, 2, 2), Color3.fromRGB(220, 60, 40), Vector3.new(0, 0, 0))
    body.Parent = model
    
    -- Belly (cream sphere)
    local belly = createPart("Belly", Vector3.new(1.2, 1.2, 0.5), Color3.fromRGB(255, 220, 180), Vector3.new(0, -0.3, 0.8))
    belly.Parent = model
    
    -- Eyes (black spheres)
    local leftEye = createPart("LeftEye", Vector3.new(0.5, 0.5, 0.3), Color3.fromRGB(30, 30, 30), Vector3.new(-0.5, 0.4, 0.9))
    leftEye.Parent = model
    local rightEye = createPart("RightEye", Vector3.new(0.5, 0.5, 0.3), Color3.fromRGB(30, 30, 30), Vector3.new(0.5, 0.4, 0.9))
    rightEye.Parent = model
    
    -- Eye shine (white)
    local leftShine = createPart("LeftShine", Vector3.new(0.15, 0.15, 0.1), Color3.fromRGB(255, 255, 255), Vector3.new(-0.45, 0.5, 1.05))
    leftShine.Parent = model
    local rightShine = createPart("RightShine", Vector3.new(0.15, 0.15, 0.1), Color3.fromRGB(255, 255, 255), Vector3.new(0.55, 0.5, 1.05))
    rightShine.Parent = model
    
    -- Horns (orange cones)
    local leftHorn = createPart("LeftHorn", Vector3.new(0.3, 0.6, 0.3), Color3.fromRGB(255, 180, 60), Vector3.new(-0.6, 1.2, 0))
    leftHorn.Shape = Enum.PartType.Cone
    leftHorn.Parent = model
    local rightHorn = createPart("RightHorn", Vector3.new(0.3, 0.6, 0.3), Color3.fromRGB(255, 180, 60), Vector3.new(0.6, 1.2, 0))
    rightHorn.Shape = Enum.PartType.Cone
    rightHorn.Parent = model
    
    -- Wings (orange flat parts)
    local leftWing = createPart("LeftWing", Vector3.new(1.5, 0.1, 1), Color3.fromRGB(255, 160, 50), Vector3.new(-1.2, 0.2, -0.3))
    leftWing.Parent = model
    local rightWing = createPart("RightWing", Vector3.new(1.5, 0.1, 1), Color3.fromRGB(255, 160, 50), Vector3.new(1.2, 0.2, -0.3))
    rightWing.Parent = model
    
    -- Feet (cream small spheres)
    local leftFoot = createPart("LeftFoot", Vector3.new(0.5, 0.3, 0.6), Color3.fromRGB(255, 220, 180), Vector3.new(-0.6, -1, 0.3))
    leftFoot.Parent = model
    local rightFoot = createPart("RightFoot", Vector3.new(0.5, 0.3, 0.6), Color3.fromRGB(255, 220, 180), Vector3.new(0.6, -1, 0.3))
    rightFoot.Parent = model
    
    -- Fire breath (orange/yellow parts)
    local fire1 = createPart("Fire1", Vector3.new(0.4, 0.4, 0.8), Color3.fromRGB(255, 200, 50), Vector3.new(0, -0.1, 1.5))
    fire1.Material = Enum.Material.Neon
    fire1.Parent = model
    local fire2 = createPart("Fire2", Vector3.new(0.3, 0.3, 0.6), Color3.fromRGB(255, 100, 30), Vector3.new(0.1, -0.2, 2))
    fire2.Material = Enum.Material.Neon
    fire2.Parent = model
    
    -- Set PrimaryPart
    model.PrimaryPart = body
    
    return model
end

-- 2. BABY UNICORN (Common) - Pink/white with golden horn
function CreatureModels.BabyUnicorn()
    local model = Instance.new("Model")
    model.Name = "BabyUnicorn"
    
    -- Body (white sphere)
    local body = createPart("Body", Vector3.new(2, 1.8, 2.2), Color3.fromRGB(255, 240, 245), Vector3.new(0, 0, 0))
    body.Parent = model
    
    -- Head (white sphere)
    local head = createPart("Head", Vector3.new(1.6, 1.5, 1.4), Color3.fromRGB(255, 240, 245), Vector3.new(0, 0.5, 1.2))
    head.Parent = model
    
    -- Horn (golden cylinder)
    local horn = createPart("Horn", Vector3.new(0.15, 0.8, 0.15), Color3.fromRGB(255, 215, 0), Vector3.new(0, 1.4, 1.4))
    horn.Shape = Enum.PartType.Cylinder
    horn.Material = Enum.Material.Metal
    horn.Parent = model
    
    -- Horn spiral (lighter gold)
    local hornSpiral = createPart("HornSpiral", Vector3.new(0.2, 0.6, 0.2), Color3.fromRGB(255, 235, 100), Vector3.new(0, 1.3, 1.4))
    hornSpiral.Shape = Enum.PartType.Cylinder
    hornSpiral.Material = Enum.Material.Metal
    hornSpiral.Parent = model
    
    -- Mane (pink parts)
    local mane1 = createPart("Mane1", Vector3.new(0.8, 0.8, 0.4), Color3.fromRGB(255, 180, 200), Vector3.new(0, 1.2, 0.3))
    mane1.Parent = model
    local mane2 = createPart("Mane2", Vector3.new(0.6, 0.6, 0.4), Color3.fromRGB(255, 160, 190), Vector3.new(0, 1, -0.2))
    mane2.Parent = model
    
    -- Tail (pink)
    local tail = createPart("Tail", Vector3.new(0.5, 0.8, 0.5), Color3.fromRGB(255, 180, 200), Vector3.new(0, 0.2, -1.3))
    tail.Parent = model
    
    -- Eyes (black)
    local leftEye = createPart("LeftEye", Vector3.new(0.35, 0.35, 0.2), Color3.fromRGB(30, 30, 30), Vector3.new(-0.4, 0.6, 1.9))
    leftEye.Parent = model
    local rightEye = createPart("RightEye", Vector3.new(0.35, 0.35, 0.2), Color3.fromRGB(30, 30, 30), Vector3.new(0.4, 0.6, 1.9))
    rightEye.Parent = model
    
    -- Eye shine
    local leftShine = createPart("LeftShine", Vector3.new(0.12, 0.12, 0.1), Color3.fromRGB(255, 255, 255), Vector3.new(-0.35, 0.68, 2))
    leftShine.Parent = model
    local rightShine = createPart("RightShine", Vector3.new(0.12, 0.12, 0.1), Color3.fromRGB(255, 255, 255), Vector3.new(0.45, 0.68, 2))
    rightShine.Parent = model
    
    -- Cheeks (pink)
    local leftCheek = createPart("LeftCheek", Vector3.new(0.25, 0.15, 0.1), Color3.fromRGB(255, 180, 190), Vector3.new(-0.6, 0.3, 1.8))
    leftCheek.Parent = model
    local rightCheek = createPart("RightCheek", Vector3.new(0.25, 0.15, 0.1), Color3.fromRGB(255, 180, 190), Vector3.new(0.6, 0.3, 1.8))
    rightCheek.Parent = model
    
    -- Hooves (pink)
    local leftFront = createPart("LeftFront", Vector3.new(0.4, 0.4, 0.4), Color3.fromRGB(255, 180, 200), Vector3.new(-0.5, -0.9, 0.6))
    leftFront.Parent = model
    local rightFront = createPart("RightFront", Vector3.new(0.4, 0.4, 0.4), Color3.fromRGB(255, 180, 200), Vector3.new(0.5, -0.9, 0.6))
    rightFront.Parent = model
    
    model.PrimaryPart = body
    return model
end

-- 3. MINI GRIFFIN (Common) - Yellow/cream lion-bird
function CreatureModels.MiniGriffin()
    local model = Instance.new("Model")
    model.Name = "MiniGriffin"
    
    -- Body (lion part - yellow/cream)
    local body = createPart("Body", Vector3.new(1.8, 1.6, 2), Color3.fromRGB(255, 230, 180), Vector3.new(0, 0, 0))
    body.Parent = model
    
    -- Head (eagle part - lighter)
    local head = createPart("Head", Vector3.new(1.4, 1.3, 1.2), Color3.fromRGB(255, 245, 200), Vector3.new(0, 0.6, 1.3))
    head.Parent = model
    
    -- Beak (yellow cone)
    local beak = createPart("Beak", Vector3.new(0.3, 0.3, 0.6), Color3.fromRGB(255, 200, 50), Vector3.new(0, 0.3, 2))
    beak.Shape = Enum.PartType.Cone
    beak.Parent = model
    
    -- Eyes (black)
    local leftEye = createPart("LeftEye", Vector3.new(0.3, 0.3, 0.15), Color3.fromRGB(30, 30, 30), Vector3.new(-0.35, 0.7, 1.9))
    leftEye.Parent = model
    local rightEye = createPart("RightEye", Vector3.new(0.3, 0.3, 0.15), Color3.fromRGB(30, 30, 30), Vector3.new(0.35, 0.7, 1.9))
    rightEye.Parent = model
    
    -- Wings (cream flat)
    local leftWing = createPart("LeftWing", Vector3.new(1.3, 0.1, 0.9), Color3.fromRGB(255, 245, 200), Vector3.new(-1, 0.3, -0.2))
    leftWing.Parent = model
    local rightWing = createPart("RightWing", Vector3.new(1.3, 0.1, 0.9), Color3.fromRGB(255, 245, 200), Vector3.new(1, 0.3, -0.2))
    rightWing.Parent = model
    
    -- Tail (lion tail)
    local tail = createPart("Tail", Vector3.new(0.3, 0.3, 0.8), Color3.fromRGB(255, 230, 180), Vector3.new(0, 0.2, -1.4))
    tail.Parent = model
    
    -- Ears (pointed)
    local leftEar = createPart("LeftEar", Vector3.new(0.25, 0.4, 0.2), Color3.fromRGB(255, 200, 120), Vector3.new(-0.5, 1.2, 1))
    leftEar.Parent = model
    local rightEar = createPart("RightEar", Vector3.new(0.25, 0.4, 0.2), Color3.fromRGB(255, 200, 120), Vector3.new(0.5, 1.2, 1))
    rightEar.Parent = model
    
    -- Paws (yellow)
    local leftPaw = createPart("LeftPaw", Vector3.new(0.4, 0.3, 0.5), Color3.fromRGB(255, 200, 100), Vector3.new(-0.5, -0.85, 0.6))
    leftPaw.Parent = model
    local rightPaw = createPart("RightPaw", Vector3.new(0.4, 0.3, 0.5), Color3.fromRGB(255, 200, 100), Vector3.new(0.5, -0.85, 0.6))
    rightPaw.Parent = model
    
    -- Cheeks (pink)
    local leftCheek = createPart("LeftCheek", Vector3.new(0.2, 0.15, 0.1), Color3.fromRGB(255, 180, 170), Vector3.new(-0.5, 0.4, 1.8))
    leftCheek.Parent = model
    local rightCheek = createPart("RightCheek", Vector3.new(0.2, 0.15, 0.1), Color3.fromRGB(255, 180, 170), Vector3.new(0.5, 0.4, 1.8))
    rightCheek.Parent = model
    
    model.PrimaryPart = body
    return model
end

-- 4. FIRE FOX (Uncommon) - Orange with flames
function CreatureModels.FireFox()
    local model = Instance.new("Model")
    model.Name = "FireFox"
    
    -- Body (orange)
    local body = createPart("Body", Vector3.new(1.6, 1.4, 2.2), Color3.fromRGB(255, 100, 40), Vector3.new(0, 0, 0))
    body.Parent = model
    
    -- Head (orange)
    local head = createPart("Head", Vector3.new(1.3, 1.2, 1.1), Color3.fromRGB(255, 100, 40), Vector3.new(0, 0.7, 1.3))
    head.Parent = model
    
    -- Ears (pointed with fire tips)
    local leftEar = createPart("LeftEar", Vector3.new(0.35, 0.7, 0.25), Color3.fromRGB(200, 50, 30), Vector3.new(-0.4, 1.4, 1.1))
    leftEar.Shape = Enum.PartType.Cone
    leftEar.Parent = model
    local rightEar = createPart("RightEar", Vector3.new(0.35, 0.7, 0.25), Color3.fromRGB(200, 50, 30), Vector3.new(0.4, 1.4, 1.1))
    rightEar.Shape = Enum.PartType.Cone
    rightEar.Parent = model
    
    -- Ear fire (neon orange)
    local leftFire = createPart("LeftFire", Vector3.new(0.25, 0.5, 0.2), Color3.fromRGB(255, 150, 50), Vector3.new(-0.4, 1.8, 1.1))
    leftFire.Material = Enum.Material.Neon
    leftFire.Parent = model
    local rightFire = createPart("RightFire", Vector3.new(0.25, 0.5, 0.2), Color3.fromRGB(255, 150, 50), Vector3.new(0.4, 1.8, 1.1))
    rightFire.Material = Enum.Material.Neon
    rightFire.Parent = model
    
    -- Eyes (glowing yellow/orange)
    local leftEye = createPart("LeftEye", Vector3.new(0.25, 0.25, 0.12), Color3.fromRGB(255, 200, 50), Vector3.new(-0.3, 0.8, 1.85))
    leftEye.Material = Enum.Material.Neon
    leftEye.Parent = model
    local rightEye = createPart("RightEye", Vector3.new(0.25, 0.25, 0.12), Color3.fromRGB(255, 200, 50), Vector3.new(0.3, 0.8, 1.85))
    rightEye.Material = Enum.Material.Neon
    rightEye.Parent = model
    
    -- Tail (large with fire)
    local tail1 = createPart("Tail1", Vector3.new(0.8, 0.8, 1.2), Color3.fromRGB(255, 100, 40), Vector3.new(0, 0.3, -1.5))
    tail1.Parent = model
    local tail2 = createPart("Tail2", Vector3.new(1, 1, 1.5), Color3.fromRGB(255, 120, 50), Vector3.new(0, 0.5, -2.5))
    tail2.Material = Enum.Material.Neon
    tail2.Parent = model
    
    -- Body markings (darker orange)
    local marking = createPart("Marking", Vector3.new(0.6, 0.1, 0.8), Color3.fromRGB(180, 60, 30), Vector3.new(0, 0.71, 0.5))
    marking.Parent = model
    
    -- Paws
    local leftPaw = createPart("LeftPaw", Vector3.new(0.35, 0.25, 0.4), Color3.fromRGB(150, 40, 30), Vector3.new(-0.4, -0.75, 0.7))
    leftPaw.Parent = model
    local rightPaw = createPart("RightPaw", Vector3.new(0.35, 0.25, 0.4), Color3.fromRGB(150, 40, 30), Vector3.new(0.4, -0.75, 0.7))
    rightPaw.Parent = model
    
    model.PrimaryPart = body
    return model
end

-- More creatures will be added...

print("[CreatureModels] Loaded 4 creature models")

return CreatureModels
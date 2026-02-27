-- Main Server Script
-- Initializes all server systems

print("")
print("=" .. string.rep("=", 50))
print("[SERVER] Endless Escape Server Starting...")
print("=" .. string.rep("=", 50))
print("")

task.wait(0.5)

-- List what's in ServerScriptService
print("[SERVER] Checking ServerScriptService contents...")
for _, child in ipairs(script.Parent:GetChildren()) do
    print("[SERVER] Found: " .. child.Name .. " (" .. child.ClassName .. ")")
end

-- Load LevelGenerator
print("[SERVER] Loading LevelGenerator...")
local LevelGeneratorModule = script.Parent:FindFirstChild("LevelGeneratorModule")

if not LevelGeneratorModule then
    warn("[SERVER] CRITICAL: LevelGeneratorModule not found in ServerScriptService!")
    -- Try to find it with different name
    for _, child in ipairs(script.Parent:GetChildren()) do
        if child.Name:lower():find("level") then
            print("[SERVER] Found potential match: " .. child.Name)
            LevelGeneratorModule = child
            break
        end
    end
end

if not LevelGeneratorModule then
    warn("[SERVER] Cannot find LevelGenerator at all!")
    return
end

print("[SERVER] Found LevelGeneratorModule at: " .. LevelGeneratorModule:GetFullName())

local success, LevelGenerator = pcall(function()
    return require(LevelGeneratorModule)
end)

if not success then
    warn("[SERVER] CRITICAL ERROR: Could not load LevelGenerator!")
    warn("[SERVER] Error: " .. tostring(LevelGenerator))
    return
end

print("[SERVER] LevelGenerator loaded successfully!")

-- Start generation
print("[SERVER] Starting LevelGenerator...")
local genSuccess, genError = pcall(function()
    local generator = LevelGenerator.new()
    generator:start()
    _G.LevelGenerator = generator
end)

if not genSuccess then
    warn("[SERVER] CRITICAL ERROR: LevelGenerator failed to start!")
    warn("[SERVER] Error: " .. tostring(genError))
    return
end

print("[SERVER] LevelGenerator started successfully!")

print("")
print("=" .. string.rep("=", 50))
print("[SERVER] Server initialization COMPLETE!")
print("[SERVER] Platforms should be visible in workspace!")
print("=" .. string.rep("=", 50))
print("")
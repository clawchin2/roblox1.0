-- Main Server Script - Simplified
-- Just starts LevelGenerator

print("[MainScript] Starting...")

task.wait(0.5)

-- Load LevelGenerator
local levelModule = script.Parent:FindFirstChild("LevelGeneratorModule")
if not levelModule then
    warn("[MainScript] LevelGeneratorModule not found!")
    return
end

local success, LevelGenerator = pcall(function()
    return require(levelModule)
end)

if not success then
    warn("[MainScript] Could not load LevelGenerator: " .. tostring(LevelGenerator))
    return
end

-- Start
local genSuccess, genErr = pcall(function()
    local generator = LevelGenerator.new()
    generator:start()
    _G.LevelGenerator = generator
end)

if genSuccess then
    print("[MainScript] LevelGenerator started successfully!")
else
    warn("[MainScript] LevelGenerator failed: " .. tostring(genErr))
end

print("[MainScript] Complete")
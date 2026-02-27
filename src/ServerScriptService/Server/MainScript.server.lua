-- Main Server Script
-- Initializes all server systems

print("")
print("=" .. string.rep("=", 50))
print("[SERVER] Endless Escape Server Starting...")
print("=" .. string.rep("=", 50))
print("")

-- Wait a moment for game to initialize
print("[SERVER] Waiting for game...")
task.wait(1)

-- Load LevelGenerator
print("[SERVER] Loading LevelGenerator module...")
local success, LevelGenerator = pcall(function()
    return require(script.Parent.LevelGeneratorModule)
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

-- Load GameManager
print("[SERVER] Loading GameManager...")
local gmSuccess, gmError = pcall(function()
    require(script.Parent.GameManager)
end)

if not gmSuccess then
    warn("[SERVER] Warning: GameManager error: " .. tostring(gmError))
else
    print("[SERVER] GameManager loaded!")
end

print("")
print("=" .. string.rep("=", 50))
print("[SERVER] Server initialization COMPLETE!")
print("[SERVER] Platforms should be visible in workspace!")
print("=" .. string.rep("=", 50))
print("")
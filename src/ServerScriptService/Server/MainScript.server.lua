-- Main Server Script
-- Initializes all server systems

print("[SERVER] ==========================================")
print("[SERVER] Endless Escape Server Starting...")
print("[SERVER] ==========================================")

-- Load and run modules
local success, err = pcall(function()
    -- Load LevelGenerator first (platform generation)
    local LevelGenerator = require(script.Parent.LevelGenerator)
    print("[SERVER] LevelGenerator module loaded")
    
    -- Create and start generator
    local generator = LevelGenerator.new()
    generator:start()
    print("[SERVER] LevelGenerator started!")
    
    -- Store for other scripts
    _G.LevelGenerator = generator
end)

if not success then
    warn("[SERVER] FAILED to start LevelGenerator: " .. tostring(err))
else
    print("[SERVER] LevelGenerator running successfully!")
end

-- Load GameManager for player handling
local success2, err2 = pcall(function()
    local GameManager = require(script.Parent.GameManager)
    print("[SERVER] GameManager loaded")
end)

if not success2 then
    warn("[SERVER] GameManager error: " .. tostring(err2))
end

print("[SERVER] ==========================================")
print("[SERVER] Server initialization complete!")
print("[SERVER] ==========================================")
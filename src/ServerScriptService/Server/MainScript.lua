-- Main Server Script
-- Initializes all server systems

print("[SERVER] ==========================================")
print("[SERVER] Endless Escape Server Starting...")
print("[SERVER] ==========================================")

-- Wait for game to be ready
if not game:IsLoaded() then
    game.Loaded:Wait()
end

print("[SERVER] Game loaded, initializing...")

-- Load modules with error handling
local success, GameManager = pcall(function()
    return require(script.Parent.GameManager)
end)

if success then
    print("[SERVER] GameManager loaded successfully!")
else
    warn("[SERVER] FAILED to load GameManager!")
end

print("[SERVER] ==========================================")
print("[SERVER] Server initialization complete!")
print("[SERVER] ==========================================")
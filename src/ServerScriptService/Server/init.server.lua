-- Main Server Script
-- Initializes all server systems

print("[Server] Starting Endless Escape server...")
print("[Server] ServerScriptService location:", script.Parent:GetFullName())

local success, err = pcall(function()
    require(script.Parent.GameManager)
end)

if success then
    print("[Server] Endless Escape server initialized successfully!")
else
    warn("[Server] Failed to initialize:", err)
end
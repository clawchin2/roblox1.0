-- Main Script - Entry point
print("[MainScript] Starting...")

local ServerStorage = game:GetService("ServerScriptService")

-- Start LevelGenerator
local LevelGen = require(ServerStorage.LevelGeneratorModule)
local generator = LevelGen.new()
generator:start()

print("[MainScript] Started")
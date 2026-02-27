-- Main Client Script
-- Initializes all client systems

local CameraController = require(script.Parent.CameraController)
local DistanceTracker = require(script.Parent.DistanceTracker)
local ShopController = require(script.Parent.ShopController)

-- Initialize systems
CameraController.init()
DistanceTracker.init()
ShopController.init()

print("[Client] Endless Escape client initialized")
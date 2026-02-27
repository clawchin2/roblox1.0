-- Distance Tracker - DISABLED (Server handles this now)
-- GameManager.server.lua updates leaderstats.Score every 0.5 seconds

print("[DistanceTracker] Server-side tracking active - client tracker disabled")

local DistanceTracker = {}
DistanceTracker.init = function() end
return DistanceTracker
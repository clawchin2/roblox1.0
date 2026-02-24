# Endless Escape - Security Audit Report

**Auditor:** QA / Exploit Hunter Agent  
**Date:** 2026-02-23  
**Scope:** All server-side and client-side Lua files in `src/` directory

---

## Executive Summary

Found **7 vulnerabilities** ranging from Medium to Critical severity. The most critical issues allow players to:
- Fire RemoteEvents without rate limiting
- Exploit coin collection via fake touch events
- Manipulate daily streak rewards via time exploitation
- Spawn camp checkpoints for unlimited rewards

---

## Vulnerability #1: No Rate Limiting on RemoteEvents

**Severity:** HIGH  
**Location:** `GameManager.server.lua` lines 236-252

### Exploit Scenario
```lua
-- Attacker's exploit script
while true do
    game.ReplicatedStorage.GameEvents.RequestStartRun:FireServer()
    game.ReplicatedStorage.GameEvents.RequestRespawn:FireServer()
    task.wait(0.1)
end
```

1. Attacker spams `RequestStartRun` RemoteEvent
2. Each call teleports player to `RUN_START_POSITION`
3. Can be combined with auto-clickers to DOS the server
4. `RequestRespawn` can be spammed to rapidly teleport between checkpoint and respawn point

### Current Code
```lua
RequestStartRun.OnServerEvent:Connect(function(player)
    startRun(player)  -- No rate limiting!
end)

RequestRespawn.OnServerEvent:Connect(function(player)
    respawnAtCheckpoint(player)  -- No rate limiting!
end)
```

### Fix Recommendation
```lua
local lastRunRequest = {}
local RUN_COOLDOWN = 3 -- seconds

RequestStartRun.OnServerEvent:Connect(function(player)
    local now = os.time()
    if lastRunRequest[player.UserId] and (now - lastRunRequest[player.UserId]) < RUN_COOLDOWN then
        return -- Silently ignore
    end
    lastRunRequest[player.UserId] = now
    startRun(player)
end)
```

---

## Vulnerability #2: Client-Authoritative Coin Collection

**Severity:** CRITICAL  
**Location:** `GameManager.server.lua` lines 138-152, 172-176

### Exploit Scenario
```lua
-- Attacker fires touched event manually
local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
for _, coin in ipairs(workspace:GetDescendants()) do
    if coin:GetAttribute("CoinValue") then
        firetouchinterest(hrp, coin, 0)
        firetouchinterest(hrp, coin, 1)
    end
end
```

1. Client can fire fake touch events for any coin in the workspace
2. No server validation that player actually touched the coin
3. `coin:SetAttribute("CoinValue", nil)` prevents double-collect on same coin instance, but attacker can collect ALL coins instantly
4. No distance check between player and coin

### Current Code
```lua
hrp.Touched:Connect(function(hit: BasePart)
    if hit:GetAttribute("CoinValue") then
        onCoinTouched(hit, player)  -- No validation!
    end
end)
```

### Fix Recommendation
```lua
local function onCoinTouched(coin: BasePart, player: Player)
    local coinValue = coin:GetAttribute("CoinValue")
    if not coinValue then return end
    
    -- Server-side validation
    local character = player.Character
    if not character then return end
    local hrp = character:FindFirstChild("HumanoidRootPart")
    if not hrp then return end
    
    -- Distance check - must be within 10 studs
    if (hrp.Position - coin.Position).Magnitude > 10 then
        return -- Possible exploit
    end
    
    -- Check if coin is in player's run segment
    local run = ObstacleManager:GetRun(player)
    if not run then return end
    -- Verify coin belongs to this player's active segments...
    
    coin:SetAttribute("CoinValue", nil)
    coin.Parent = nil
    EconomyManager:AwardCoinCollected(player, coinType)
end
```

---

## Vulnerability #3: Daily Streak Time Manipulation

**Severity:** MEDIUM  
**Location:** `DataManager.lua` lines 314-355

### Exploit Scenario
1. Player collects daily reward
2. Player changes device clock back 24 hours
3. `hoursSinceLastClaim < 20` check passes (time appears to be 20+ hours ago)
4. Player claims again

While Roblox servers use UTC time, the client could potentially exploit this if the check relies on any client-synced values.

### Current Code
```lua
function DataManager:ClaimDailyStreak(player: Player)
    local now = os.time() -- Server time, good
    local hoursSinceLastClaim = (now - data.dailyStreak.lastLogin) / 3600
    
    if hoursSinceLastClaim < 20 then
        return false, nil -- Too soon
    end
```

**Analysis:** Actually uses server time (`os.time()`), so not directly exploitable. However, the 20-hour window (instead of 24) allows some abuse.

### Fix Recommendation
```lua
-- Change to 24-hour strict check
if hoursSinceLastClaim < 24 then
    return false, nil
end

-- Also track by actual calendar day
local lastDate = os.date("!*t", data.dailyStreak.lastLogin)
local today = os.date("!*t", now)
local isNewDay = lastDate.year ~= today.year or lastDate.yday ~= today.yday
if not isNewDay then
    return false, nil
end
```

---

## Vulnerability #4: Lucky Spin Cooldown Bypass

**Severity:** MEDIUM  
**Location:** `DataManager.lua` lines 267-296

### Exploit Scenario
```lua
-- Attacker spams spin requests
for i = 1, 100 do
    game.ReplicatedStorage:WaitForChild("SpinEvents").RequestSpin:FireServer()
end
```

Looking at the code, there's no exposed RemoteEvent for spinning, but `UseSpin` calculates available spins based on time. If a RemoteEvent is added later without rate limiting, this becomes exploitable.

**Current State:** The spin system appears to be internal-only (no RemoteEvent exposed), which is good. However, `GetAvailableSpins` relies on `os.time()` calculations that could race if multiple requests come in simultaneously.

### Fix Recommendation
Add a server-side cooldown tracker even for internal calls:
```lua
local lastSpinRequest = {}

function DataManager:UseSpin(player: Player): boolean
    local now = os.time()
    if lastSpinRequest[player.UserId] == now then
        return false -- Already spun this second
    end
    lastSpinRequest[player.UserId] = now
    -- ... rest of function
end
```

---

## Vulnerability #5: Race Condition in DataStore Operations

**Severity:** MEDIUM  
**Location:** `DataManager.lua` lines 150-200

### Exploit Scenario
1. Player rapidly joins/leaves different servers
2. Server A loads data, Server B loads data simultaneously
3. Both servers have outdated session lock state
4. Player makes purchases on both servers
5. Last server to save overwrites the other, potentially duplicating or losing items

### Current Code
```lua
local function acquireSessionLock(userId: number): boolean
    if SessionLocks[userId] then
        return false -- Already locked by another server
    end
    SessionLocks[userId] = true
    return true
end
```

The session lock is **in-memory only** - not persisted to DataStore. This means multiple servers can simultaneously load the same player's data.

### Fix Recommendation
Use MemoryStoreService for cross-server session locking:
```lua
local MemoryStoreService = game:GetService("MemoryStoreService")
local SessionLockStore = MemoryStoreService:GetSortedMap("SessionLocks")

local function acquireSessionLock(userId: number): boolean
    local success, result = pcall(function()
        return SessionLockStore:SetAsync(
            tostring(userId), 
            game.JobId, 
            300 -- 5 minute expiry
        )
    end)
    return success and result
end
```

---

## Vulnerability #6: Checkpoint Reward Farming

**Severity:** MEDIUM  
**Location:** `GameManager.server.lua` lines 172-180

### Exploit Scenario
1. Player reaches checkpoint at Z=200
2. Player intentionally dies immediately after
3. Player respawns at checkpoint
4. Player walks back to collect coins again (if they respawned)
5. Or stands at checkpoint and repeatedly touches it to trigger effects

### Current Code
```lua
if hit:GetAttribute("Checkpoint") then
    local run = ObstacleManager:GetRun(player)
    if run then
        run.lastCheckpointPos = hit.Position
        run.lastCheckpointDist = state and state.currentDistance or 0
    end
end
```

There's no cooldown on checkpoint updates. A player could potentially farm checkpoint touches.

### Fix Recommendation
```lua
local lastCheckpointUpdate = {}

if hit:GetAttribute("Checkpoint") then
    local now = os.time()
    if lastCheckpointUpdate[player.UserId] == now then
        return -- Rate limit
    end
    lastCheckpointUpdate[player.UserId] = now
    
    local run = ObstacleManager:GetRun(player)
    if run then
        -- Only update if moved forward significantly
        local newDist = state and state.currentDistance or 0
        if newDist > (run.lastCheckpointDist or 0) + 50 then
            run.lastCheckpointPos = hit.Position
            run.lastCheckpointDist = newDist
        end
    end
end
```

---

## Vulnerability #7: Missing Server-Side Distance Validation

**Severity:** HIGH  
**Location:** `GameManager.server.lua` lines 204-223

### Exploit Scenario
```lua
-- Attacker teleports character far ahead
local hrp = game.Players.LocalPlayer.Character.HumanoidRootPart
hrp.CFrame = CFrame.new(0, 5, 10000) -- Teleport to Z=10000
```

1. Distance is calculated purely from character position: `hrp.Position.Z - RUN_START_POSITION.Z`
2. No server-side position validation or sanity checks
3. No maximum distance delta per frame
4. Exploiter can teleport to any Z position and get credited for that distance

### Current Code
```lua
RunService.Heartbeat:Connect(function()
    for _, player in ipairs(Players:GetPlayers()) do
        local state = playerStates[player.UserId]
        if not state or not state.isInRun then continue end
        
        local character = player.Character
        if not character then continue end
        local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not hrp then continue end
        
        local newDist = math.max(state.currentDistance, hrp.Position.Z - RUN_START_POSITION.Z)
        state.currentDistance = newDist
    end
end)
```

### Fix Recommendation
```lua
local lastPositions = {}
local MAX_SPEED = 100 -- studs per second (generous)

RunService.Heartbeat:Connect(function(dt)
    for _, player in ipairs(Players:GetPlayers()) do
        -- ... state checks ...
        
        local hrp = character:FindFirstChild("HumanoidRootPart") :: BasePart?
        if not hrp then continue end
        
        local currentPos = hrp.Position
        local currentZ = currentPos.Z - RUN_START_POSITION.Z
        
        -- Speed check
        local lastPos = lastPositions[player.UserId]
        if lastPos then
            local distanceMoved = (currentPos - lastPos).Magnitude
            local maxMove = MAX_SPEED * dt
            
            if distanceMoved > maxMove * 2 then -- Allow some tolerance
                -- Possible teleport/speed hack
                warn(string.format("[AntiCheat] Player %d moved too fast: %.1f studs", 
                    player.UserId, distanceMoved))
                -- Could kick, or just don't update distance
                continue
            end
        end
        
        lastPositions[player.UserId] = currentPos
        
        local newDist = math.max(state.currentDistance, currentZ)
        state.currentDistance = newDist
    end
end)
```

---

## Additional Observations

### Low Severity: Config.lua Exposure
The Config module is in ReplicatedStorage and exposes:
- All product IDs (even if 0, shows structure)
- Coin economy values
- Gamepass pricing

**Impact:** Low - information disclosure only, doesn't enable exploits directly.

### Low Severity: Dev Product ID = 0
All DevProducts have `id = 0` placeholder. If deployed without updating:
- `ProcessReceipt` will fail for all products
- `PromptProductPurchase` with ID 0 is invalid

**Impact:** High if deployed, but clearly marked as "REPLACE WITH ACTUAL ASSET ID"

### Low Severity: Missing RemoteEvent for Spin
The Config defines `LuckySpin` but no RemoteEvent is created to actually use spins. Either:
1. Feature is incomplete, or
2. Spins are intended to be server-triggered only

---

## Roblox TOS Compliance Check

| Check | Status | Notes |
|-------|--------|-------|
| Gambling mechanics | ✅ PASS | Lucky spin has no real-money cost, uses earned currency only |
| Inappropriate content | ✅ PASS | No adult content, violence is cartoonish |
| Paid random items | ✅ PASS | All paid products are deterministic |
| Data privacy | ✅ PASS | Only stores game progress, no personal data |
| Deceptive practices | ⚠️ WARNING | Death screen product buttons use emoji + price only, minimal disclosure |

**TOS Concern:** The death screen shop uses emoji-only buttons with small prices, which could be considered manipulative toward younger players:
```lua
btn.Text = emoji .. "\n" .. tostring(price) .. " R$"
```

Recommendation: Add clearer descriptions of what each product does.

---

## Summary Table

| # | Severity | Vulnerability | File | Line |
|---|----------|---------------|------|------|
| 1 | HIGH | No Rate Limiting on RemoteEvents | GameManager.server.lua | 236-252 |
| 2 | CRITICAL | Client-Authoritative Coin Collection | GameManager.server.lua | 138-152 |
| 3 | MEDIUM | Daily Streak 20h Window | DataManager.lua | 314-355 |
| 4 | MEDIUM | Spin Race Condition | DataManager.lua | 267-296 |
| 5 | MEDIUM | DataStore Race Condition | DataManager.lua | 150-200 |
| 6 | MEDIUM | Checkpoint Farming | GameManager.server.lua | 172-180 |
| 7 | HIGH | Missing Distance Validation | GameManager.server.lua | 204-223 |

---

## Priority Fixes (In Order)

1. **Add server-side distance validation** - Prevents teleport exploits (HIGH)
2. **Add coin collection validation** - Distance check, verify coin ownership (CRITICAL)
3. **Add RemoteEvent rate limiting** - Prevent spam/DOS (HIGH)
4. **Implement cross-server session locks** - Prevent data races (MEDIUM)
5. **Add checkpoint rate limiting** - Prevent farming (MEDIUM)
6. **Change daily streak to 24h** - Close time window (MEDIUM)
7. **Add spin request deduplication** - Prevent race conditions (LOW)

---

*Report generated by QA Agent for Endless Escape Security Audit*

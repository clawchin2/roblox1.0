# Endless Escape — Deployment Guide
**Date:** 2026-02-23 | **Status:** READY FOR DEPLOYMENT

---

## 📋 Pre-Flight Checklist

Before starting, ensure you have:
- [ ] Roblox Studio installed and updated
- [ ] Roblox account with verified email
- [ ] Roblox group created (for game ownership)
- [ ] At least 100 Robux for initial gamepass/asset uploads

---

## Step 1: Create New Roblox Game

1. Open **Roblox Studio**
2. Click **New** → **Baseplate** (or "Obby" template if you want terrain reference)
3. Save to Roblox: **File → Publish to Roblox As...**
4. Choose your group or personal account
5. Name: **"Endless Escape"**
6. Description: (copy from below)
```
🏃 Run as far as you can in this endless obstacle course!
💀 Dodge deadly traps: spinning blades, falling rocks, laser beams, and more
🪙 Collect coins to buy awesome trails and hats
🎰 Spin the lucky wheel for free prizes every 4 hours
🔥 How far can YOU go?

Controls: Tap/Click to jump. That's it!

Next update: Pets and trading coming soon!
```
7. Genre: **Adventure**
8. Devices: **Phone, Tablet, Desktop, Console**
9. Click **Create**

---

## Step 2: Set Up Roblox Services

### A. Enable Required Services

1. In Studio, go to **Home → Game Settings**
2. **Security:**
   - ✅ Enable HTTP Requests (for analytics if needed later)
   - ✅ Enable Studio Access to API
3. **Permissions:**
   - ✅ Third Party Sales (for gamepasses)
   - ✅ Allow HTTP Requests
4. **Avatar:** Set to **R15** (required for animations)

### B. Create DataStores

1. Go to **View → Data Stores** (or press Alt+6)
2. Studio automatically creates DataStores when scripts run
3. No manual setup needed

---

## Step 3: Copy Scripts to Roblox

### File Structure to Create in Studio

```
ServerScriptService/
  GameManager (Script)          ← PASTE GameManager.server.lua contents
  Modules/ (Folder)
    Config (ModuleScript)       ← PASTE Config.lua contents
    DataManager (ModuleScript)  ← PASTE DataManager.lua
    EconomyManager (ModuleScript) ← PASTE EconomyManager.lua
    ShopManager (ModuleScript)  ← PASTE ShopManager.lua
    ObstacleManager (ModuleScript) ← PASTE ObstacleManager.lua
    DailyRewards (ModuleScript) ← PASTE DailyRewards.lua
    LuckySpin (ModuleScript)    ← PASTE LuckySpin.lua
    Leaderboard (ModuleScript)  ← PASTE Leaderboard.lua

ReplicatedStorage/
  Shared/ (Folder)
    Config (ModuleScript)       ← PASTE Config.lua contents (same as server)

StarterPlayerScripts/
  ClientManager (LocalScript)   ← PASTE ClientManager.client.lua
  Modules/ (Folder)
    LuckySpinUI (ModuleScript)  ← PASTE LuckySpinUI.lua
    ShopUI (ModuleScript)       ← PASTE ShopUI.lua
    LeaderboardUI (ModuleScript) ← PASTE LeaderboardUI.lua
```

### Copy-Paste Instructions

1. For each file in `/data/.openclaw/workspace/games/endless-escape/src/`
2. Copy the entire contents
3. In Studio, right-click parent → **Insert Object** → appropriate type
4. Paste into the script editor
5. Name exactly as shown above

---

## Step 4: Configure Config.lua

**CRITICAL:** Update the asset IDs in Config.lua:

```lua
Config.DevProducts = {
    ShieldBubble = { id = 0, ... },  -- ← REPLACE WITH REAL ASSET ID
    SpeedBoost = { id = 0, ... },    -- ← REPLACE WITH REAL ASSET ID
    -- etc...
}

Config.Gamepasses = {
    DoubleCoins = { id = 0, ... },   -- ← REPLACE WITH REAL ASSET ID
    VIPTrail = { id = 0, ... },      -- ← REPLACE WITH REAL ASSET ID
    Radio = { id = 0, ... },         -- ← REPLACE WITH REAL ASSET ID
}
```

### How to Get Real Asset IDs

See Step 5 below — you need to create the products first, then copy their IDs back into Config.

---

## Step 5: Create Developer Products

1. In Studio: **Home → Game Settings → Monetization → Developer Products**
2. Click **Add Product** for each:

| Product | Price | Description |
|---------|-------|-------------|
| Shield Bubble | 15 | Survive one hit! |
| Speed Boost | 15 | Go 1.5x faster for 10 seconds |
| Skip Ahead | 25 | Skip the next 3 obstacles |
| Instant Revive | 25 | Respawn exactly where you died |
| 50 Coins | 5 | Pocket change coin pack |
| 150 Coins | 15 | Small coin pack |
| 500 Coins | 49 | Big coin pack |

3. After creating each, copy the **Product ID** number
4. Paste into Config.lua

---

## Step 6: Create Gamepasses

1. In Studio: **Home → Game Settings → Monetization → Passes**
2. Click **Create Pass** for each:

| Pass | Price | Icon | Description |
|------|-------|------|-------------|
| 2x Coins | 99 | 💰 | Earn double coins forever! |
| VIP Trail | 149 | 🌈 | Rainbow trail + VIP chat tag |
| Radio | 49 | 🎵 | Play music in-game |

3. For each pass:
   - Upload icon (128×128, use prompts from ASSETS.md)
   - Copy the **Pass ID** from URL or settings
   - Paste into Config.lua

---

## Step 7: Upload Game Icon & Thumbnail

1. Go to **Roblox.com → Create → Decals** (or use Toolbox in Studio)
2. Upload:
   - Game Icon (512×512) — use prompt from ASSETS.md
   - Thumbnail (1920×1080) — use prompt from ASSETS.md
3. In Studio: **Home → Game Settings → Basic Info**
4. Set Game Icon and Thumbnail

---

## Step 8: Configure Game Settings

### Basic Info
- **Name:** Endless Escape
- **Description:** (from Step 1)
- **Max Players:** 50 (start high for algorithm boost)
- **Allow Copying:** NO (protect your code)

### Permissions
- **Chat:** Allowed
- **Gear:** None (prevents gear exploits)
- **Third Party Sales:** Enabled

### Avatar
- **Avatar Type:** R15
- **Animation:** Choose running/jumping animations

### Security
- **Private Servers:** Optional (50 Robux)
- **VIP Servers:** Can help generate initial revenue

---

## Step 9: Test Everything

### Solo Test (You)
1. Press **F5** to play
2. Test:
   - [ ] Jump works (space/tap)
   - [ ] Coins spawn and collect
   - [ ] Death triggers death screen
   - [ ] Shield purchase works
   - [ ] Revive works
   - [ ] Distance tracked correctly
   - [ ] Personal best saves
   - [ ] Daily reward day 1 claims
   - [ ] Lucky spin works
   - [ ] Shop opens and shows items
   - [ ] Leaderboard shows your score

### Friend Test (Critical)
1. Publish: **File → Publish to Roblox**
2. Set game to **Friends Only** or **Private**
3. Have 2-3 friends join
4. Test:
   - [ ] Multiple players see each other
   - [ ] Leaderboard shows all players
   - [ ] No server lag with 3+ players
   - [ ] Purchases work for friends

---

## Step 10: Go Public

1. **File → Publish to Roblox**
2. Go to **Roblox.com → Create → Games**
3. Click **Endless Escape**
4. Change visibility: **Public**
5. Click **Save**

### Algorithm Optimization (Day 1-3)

**Hour 1-6:**
- Get 10+ friends to play for 5+ minutes each
- This boosts "retention" metric for algorithm

**Day 1-3:**
- Share on social media (TikTok, Twitter, Discord)
- Goal: 100+ visits in first 24 hours
- Roblox algorithm favors games with fast early growth

---

## Post-Launch Checklist

### Day 1
- [ ] Check DataStore for errors (View → Developer Console)
- [ ] Monitor purchase success rate (should be >95%)
- [ ] Check average session length (target: 8+ minutes)
- [ ] Respond to any Discord/social comments

### Week 1
- [ ] Review economy metrics (see ECONOMY.md section 6)
- [ ] Check for exploit reports
- [ ] First content update (new trail or hat)
- [ ] Consider TikTok/YouTube creator outreach

### Month 1
- [ ] If <100 CCU: Analyze why, consider reskin per strategy
- [ ] If >500 CCU: Scale up, add pets/battle pass
- [ ] Full economy audit and rebalance if needed

---

## Emergency Contacts

If game breaks:
1. Set to **Private** immediately
2. Check Developer Console for errors
3. Fix in Studio → republish
4. Common issues:
   - Config.lua has wrong asset IDs
   - ModuleScript named wrong (case-sensitive!)
   - DataStore limits hit (wait and retry)

---

## 🚀 DEPLOYMENT COMPLETE

Your game is now live!

**Next milestone:** 100 concurrent players
**Next feature:** Pets (if metrics look good)

Good luck Chinmaya! 🎮

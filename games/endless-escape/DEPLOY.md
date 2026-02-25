# Endless Escape — Quick Deploy Guide
**Roblox Studio 0.709+ Compatible | Last Updated: Feb 2025**

---

## 🚀 Option 1: Rojo Sync (Recommended for Developers)

### Prerequisites
- Install [Rojo](https://rojo.space/): `cargo install rojo` or download from [releases](https://github.com/rojo-rbx/rojo/releases)
- Roblox Studio 0.709.0.7090870 or newer

### Steps

1. **Open terminal in game folder:**
   ```bash
   cd games/endless-escape
   ```

2. **Start Rojo:**
   ```bash
   rojo serve
   ```

3. **In Roblox Studio:**
   - Install [Rojo plugin](https://www.roblox.com/library/6410904330/Rojo)
   - Click **Connect** (default: localhost:34872)
   - Click **Sync** → all scripts auto-import

4. **Configure game settings** (see Step 2 below)

---

## 📁 Option 2: Manual Copy-Paste

### Step 1: Create Place

1. Open **Roblox Studio 0.709+**
2. **New** → **Baseplate**
3. **File** → **Publish to Roblox As...**
4. Name: **"Endless Escape"**
5. Set: Genre=Adventure, Max Players=50

### Step 2: Create Folder Structure

In Studio, create this hierarchy (right-click → **Insert Object**):

```
ServerScriptService/
  └── GameManager (Script) - Paste GameManager.server.lua
  └── Modules (Folder)
      ├── DataManager (ModuleScript) - Paste DataManager.lua
      ├── EconomyManager (ModuleScript) - Paste EconomyManager.lua
      ├── ShopManager (ModuleScript) - Paste ShopManager.lua
      ├── ObstacleManager (ModuleScript) - Paste ObstacleManager.lua
      ├── DailyRewards (ModuleScript) - Paste DailyRewards.lua
      ├── LuckySpin (ModuleScript) - Paste LuckySpin.lua
      └── Leaderboard (ModuleScript) - Paste Leaderboard.lua

ReplicatedStorage/
  └── Shared (Folder)
      └── Config (ModuleScript) - Paste Config.lua

StarterPlayer/
  └── StarterPlayerScripts/
      ├── ClientManager (LocalScript) - Paste ClientManager.client.lua
      └── Modules (Folder)
          ├── LuckySpinUI (ModuleScript) - Paste LuckySpinUI.lua
          ├── ShopUI (ModuleScript) - Paste ShopUI.lua
          └── LeaderboardUI (ModuleScript) - Paste LeaderboardUI.lua
```

### Step 3: Enable Services

**Home → Game Settings:**
- ✅ **Enable HTTP Requests** (Security tab)
- ✅ **Studio Access to API Services** (Security tab)
- ✅ **Avatar Type: R15** (Avatar tab)

---

## 💰 Step 4: Create Monetization

### Developer Products (Game Settings → Monetization → Developer Products)

| Product Name | Price | Asset ID (fill after creation) |
|-------------|-------|-------------------------------|
| Shield Bubble | 15 Robux | `Config.DevProducts.ShieldBubble.id` |
| Speed Boost | 15 Robux | `Config.DevProducts.SpeedBoost.id` |
| Skip Ahead | 25 Robux | `Config.DevProducts.SkipAhead.id` |
| Instant Revive | 25 Robux | `Config.DevProducts.InstantRevive.id` |
| Coin Pack Small | 5 Robux | `Config.DevProducts.CoinPackSmall.id` |
| Coin Pack Medium | 15 Robux | `Config.DevProducts.CoinPackMedium.id` |
| Coin Pack Large | 49 Robux | `Config.DevProducts.CoinPackLarge.id` |

**After creating each product:**
1. Copy the Product ID number
2. Open `ReplicatedStorage/Shared/Config`
3. Find the product in `Config.DevProducts`
4. Replace `id = 0` with the actual ID

### Gamepasses (Game Settings → Monetization → Passes)

| Pass Name | Price | Asset ID |
|-----------|-------|----------|
| 2x Coins | 99 Robux | `Config.Gamepasses.DoubleCoins.id` |
| VIP Trail | 149 Robux | `Config.Gamepasses.VIPTrail.id` |
| Radio | 49 Robux | `Config.Gamepasses.Radio.id` |

---

## ✅ Step 5: Quick Test Checklist

Press **F5** to play:

- [ ] Click **PLAY** button → teleports to start
- [ ] Jump (Space/Tap) works
- [ ] Run forward, obstacles spawn
- [ ] Collect coins → coin counter updates
- [ ] Die → death screen shows
- [ ] Distance tracked correctly
- [ ] Personal best saves after death

**Test purchases (only works in published game):**
- [ ] Shield purchase prompts
- [ ] Revive works

---

## 🔧 Common Issues

| Issue | Fix |
|-------|-----|
| "Config is not a valid member" | Check Config.lua is in `ReplicatedStorage/Shared/` |
| "Attempt to index nil" on DataManager | Ensure all modules are in correct folders |
| Purchases not working | Product IDs must be set in Config.lua (not 0) |
| UI not showing | Check StarterPlayerScripts → ClientManager is a LocalScript |
| Infinite yield on WaitForChild | Restart Studio, check folder structure matches exactly |

---

## 📦 File Structure Reference

```
games/endless-escape/
├── default.project.json      ← Rojo project file
├── DEPLOY.md                 ← This file
├── README.md                 ← Game documentation
├── src/
│   ├── ReplicatedStorage/
│   │   └── Shared/
│   │       └── Config.lua    ← ALL game balance values
│   ├── ServerScriptService/
│   │   ├── GameManager.server.lua
│   │   └── Modules/
│   │       ├── DataManager.lua
│   │       ├── EconomyManager.lua
│   │       ├── ShopManager.lua
│   │       ├── ObstacleManager.lua
│   │       ├── DailyRewards.lua
│   │       ├── LuckySpin.lua
│   │       └── Leaderboard.lua
│   └── StarterPlayerScripts/
│       ├── ClientManager.client.lua
│       └── Modules/
│           ├── LuckySpinUI.lua
│           ├── ShopUI.lua
│           └── LeaderboardUI.lua
```

---

## 🎮 After Deployment

1. **File → Publish to Roblox**
2. Go to [Roblox Creator Dashboard](https://create.roblox.com)
3. Set game **Public**
4. Share link with friends for testing
5. Monitor analytics in Creator Dashboard

---

**Need help?** Check the full documentation in `/docs` or ask in Discord.

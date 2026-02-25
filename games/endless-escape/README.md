# Endless Escape

A high-retention endless runner for Roblox with smart monetization and engaging progression systems.

## 🎮 Game Overview

**Genre:** Endless Runner / Obstacle Course  
**Target Audience:** Kids/Teens (8-16)  
**Monetization:** Micro-transactions (impulse purchases), Gamepasses  
**Session Length:** 3-10 minutes per run

### Core Loop
1. Click **PLAY** → Start running automatically
2. Jump over/dodge obstacles
3. Collect coins along the way
4. Die → See distance + death screen offers
5. Spend coins on cosmetics OR buy power-ups to go further
6. Come back tomorrow for daily rewards

---

## 📁 Project Structure

```
games/endless-escape/
├── default.project.json      # Rojo project configuration
├── DEPLOY.md                 # Deployment guide
├── README.md                 # This file
├── SCOPE.md                  # Feature scope & roadmap
├── ECONOMY.md                # Economy balancing
├── ASSETS.md                 # Asset generation prompts
├── src/
│   ├── ReplicatedStorage/
│   │   └── Shared/
│   │       └── Config.lua    # All tunable values
│   ├── ServerScriptService/
│   │   ├── GameManager.server.lua    # Main orchestrator
│   │   └── Modules/
│   │       ├── DataManager.lua       # DataStore wrapper
│   │       ├── EconomyManager.lua    # Currency ops
│   │       ├── ShopManager.lua       # Monetization
│   │       ├── ObstacleManager.lua   # Procedural generation
│   │       ├── DailyRewards.lua      # Login streaks
│   │       ├── LuckySpin.lua         # Prize wheel
│   │       └── Leaderboard.lua       # Rankings
│   └── StarterPlayerScripts/
│       ├── ClientManager.client.lua  # UI controller
│       └── Modules/
│           ├── LuckySpinUI.lua       # Spin wheel UI
│           ├── ShopUI.lua            # Cosmetic shop UI
│           └── LeaderboardUI.lua     # Leaderboard UI
```

---

## 🚀 Quick Start

### For Development (Rojo)
```bash
cd games/endless-escape
rojo serve
# In Studio: Rojo plugin → Connect → Sync
```

### For Production
See [DEPLOY.md](DEPLOY.md) for full deployment instructions.

---

## 💰 Monetization Strategy

### Developer Products (Impulse Purchases)
| Product | Price | Use Case |
|---------|-------|----------|
| Shield Bubble | 15R | High-frustration deaths |
| Speed Boost | 15R | Same obstacle death x2 |
| Skip Ahead | 25R | Near-milestone (900m+) |
| Instant Revive | 25R | Near personal best |
| Coin Packs | 5-49R | Skip grind |

### Gamepasses (Permanent)
| Pass | Price | Benefit |
|------|-------|---------|
| 2x Coins | 99R | Permanent earning boost |
| VIP Trail | 149R | Visual status + rainbow trail |
| Radio | 49R | Music player |

### Conversion Triggers
The death screen intelligently highlights products based on context:
- First death ever → No products (learn to play)
- Died <50m → Just retry
- Died near personal best → Highlight Revive
- 900-999m range → Highlight Skip Ahead
- 3+ deaths in 2 min → Highlight Shield

---

## 📊 Key Metrics to Track

1. **Day 1 Retention** - Target: 40%+
2. **Average Session Length** - Target: 8+ minutes
3. **Purchase Conversion** - Target: 3-5%
4. **ARPU** (Avg Revenue Per User) - Target: 15-25 Robux
5. **D7 Retention** - Target: 15%+

---

## 🛠️ Tech Stack

- **Roblox Studio 0.709+**
- **Rojo** (optional, for external editing)
- **DataStore** (player data persistence)
- **OrderedDataStore** (leaderboards)
- **MarketplaceService** (monetization)

---

## 🔒 Anti-Exploit Measures

- Server-authoritative coin earning
- Distance validation (max 50 studs/frame)
- Rate limiting on coin collection
- Receipt tracking for purchases (idempotent)
- Session locking for data saves

---

## 📝 Changelog

### v1.0 (Current)
- Core endless runner gameplay
- 8 obstacle types with procedural generation
- Complete monetization system
- Daily rewards + lucky spin
- Leaderboards (global + weekly)
- Cosmetic shop (trails + hats)

### v1.1 (Planned)
- Pet system
- Battle pass
- Trading

---

**Built for Chinmaya's Roblox monetization pipeline.**

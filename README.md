# 🐉 Creature Simulator

A fantasy pet collection game inspired by Pet Simulator X. Click to earn coins, hatch eggs, and collect legendary creatures!

## 🎮 How to Play

1. **Click the green platform** to earn coins
2. **Open the Egg Shop** (bottom right button)
3. **Buy eggs** with your coins
4. **Hatch creatures** of different rarities
5. **Collect them all!**

## 🥚 Eggs

| Egg | Price | Rarities |
|-----|-------|----------|
| Basic Egg | 100 coins | Common, Uncommon, Rare |
| Fantasy Egg | 500 coins | Uncommon, Rare, Epic |
| Mythic Egg | 2000 coins | Rare, Epic, Legendary |

## 🐲 Creatures (16 Total)

**Common (50% chance):**
- Tiny Dragon
- Baby Unicorn
- Mini Griffin

**Uncommon (30% chance):**
- Fire Fox
- Ice Wolf
- Thunder Bird

**Rare (15% chance):**
- Phoenix
- Kraken
- Cerberus

**Epic (4% chance):**
- Hydra
- Chimera

**Legendary (1% chance):**
- Ancient Dragon
- World Serpent

## 💰 Monetization (Coming Soon)

- DevProducts for coin packs
- Gamepasses for multipliers
- Trading system
- Pet evolution

## 🚀 Status

**Currently Working:**
- ✅ Click to earn coins
- ✅ Coin display UI
- ✅ Egg shop
- ✅ Hatching system
- ✅ Rarity system
- ✅ Hatch animation

**Coming Next:**
- Pets following you
- Pet inventory
- Pet stats display
- Trading
- Evolution

## 📁 File Structure

```
src/
├── ReplicatedStorage/Modules/
│   ├── GameConfig.lua      # Settings, creatures, eggs
│   └── PetSystem.lua       # Hatching logic
├── ServerScriptService/
│   ├── GameManager.server.lua    # Core game logic
│   └── HatchHandler.server.lua   # Egg hatching handler
└── StarterPlayer/StarterPlayerScripts/Client/
    ├── UI.client.lua       # Main UI (coins, shop)
    └── HatchUI.client.lua  # Hatch animation
```

## 🔧 Build

```bash
rojo build default.project.json -o CreatureSimulator.rbxl
```

Or download from GitHub Actions.

---

*Fantasy pet simulator with gacha mechanics*
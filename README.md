# Endless Escape 🎮

A high-intensity endless runner obstacle course for Roblox. Jump, dodge, and survive through procedurally generated challenges.

## Features

- 🏃 **Procedural Generation** - Infinite platforms, no two runs are the same
- ☠️ **Multiple Hazards** - Kill zones, fading platforms, crumbling blocks, moving platforms
- 🪙 **Coin Economy** - Collect coins to unlock cosmetics
- 🛒 **Shop System** - Trails and skins with stat bonuses
- 💀 **Revive System** - Micro-transaction relief at death moments
- 📊 **Leaderboards** - Compete for distance

## Quick Start

### Option 1: Rojo Workflow (Recommended)

1. **Install Rojo**:
   ```bash
   cargo install rojo
   # or
   npm install -g rojo
   ```

2. **Clone this repo**:
   ```bash
   git clone https://github.com/YOUR_USERNAME/EndlessEscape.git
   cd EndlessEscape
   ```

3. **Start Rojo**:
   ```bash
   rojo serve
   ```

4. **Connect in Roblox Studio**:
   - Install [Rojo Plugin](https://www.roblox.com/library/4048317705)
   - Click "Connect"
   - Accept changes

### Option 2: Manual Import

1. Create a new Roblox place
2. Create folders matching the `src/` structure
3. Copy-paste each script into the correct location
4. Set `init.server.lua` to Script type
5. Set `init.client.lua` to LocalScript type
6. Set `LoadingScreen.lua` to LocalScript in ReplicatedFirst

## Project Structure

```
EndlessEscape/
├── default.project.json          # Rojo configuration
├── src/
│   ├── ReplicatedStorage/
│   │   └── Modules/
│   │       ├── PlatformModule.lua    # Platform behaviors
│   │       ├── GameConfig.lua        # Balance settings
│   │       └── Utils.lua             # Helper functions
│   ├── ReplicatedFirst/
│   │   └── LoadingScreen.lua         # Loading UI
│   ├── ServerScriptService/
│   │   └── Server/
│   │       ├── init.server.lua       # Entry point
│   │       ├── GameManager.lua       # Player data & state
│   │       └── LevelGenerator.lua    # Procedural generation
│   ├── StarterPlayer/
│   │   └── StarterPlayerScripts/
│   │       └── Client/
│   │           ├── init.client.lua   # Client entry
│   │           ├── CameraController.lua
│   │           ├── DistanceTracker.lua
│   │           └── ShopController.lua
│   ├── StarterGui/
│   │   └── MainUIHandler.client.lua  # UI system
│   └── Workspace/
│       └── Lobby/
│           └── LobbyModel.lua
```

## Platform Types

| Type | Color | Behavior |
|------|-------|----------|
| Static | Gray | Basic platform |
| Moving | Blue | Oscillates side-to-side |
| Fading | Yellow | Disappears 1s after touch |
| Crumbling | Brown | Shakes then falls |
| Bounce | Green | Launch pad |
| Kill | Red | Instant death |

## Monetization

The game uses a **micro-relief** model optimized for kid/teen engagement:

- **Revive** (25 R$) - Continue from death point
- **Skip** (15 R$) - Bypass difficult section  
- **Coin Packs** - 49/99/199 R$ tiers
- **Cosmetics** - Trails and skins via in-game coins

## Configuration

Edit `GameConfig.lua` to balance:

```lua
-- Difficulty curve
GameConfig.DIFFICULTY_STAGES = {
    {distance = 0,    gapRange = {8, 12},  hazardChance = 0.1},
    {distance = 100,  gapRange = {10, 16}, hazardChance = 0.2},
    -- Add more stages...
}

-- Prices
GameConfig.REVIVE_COST = 25
GameConfig.COIN_PACK_SMALL = 49
```

## Development Roadmap

- [ ] Multiplayer racing mode
- [ ] Daily challenges
- [ ] Season pass system
- [ ] Mobile optimizations
- [ ] Sound effects & music

## License

MIT - Feel free to use and modify for your own games.

---

Built for the Roblox platform. Ship fast, iterate faster. 🚀
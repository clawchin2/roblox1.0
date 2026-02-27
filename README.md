# Endless Escape 🎮

A high-intensity endless runner obstacle course for Roblox. Jump, dodge, and survive through procedurally generated challenges.

## 🎯 Current Status

| Feature | Status | Notes |
|---------|--------|-------|
| Baseplate Spawn | ✅ Working | Green 50x50 platform at start |
| Platform Generation | ✅ Working | 25+ platforms generate ahead |
| Player Movement | ✅ Working | Standard Roblox physics |
| Camera | ✅ Working | Default camera (follow mode coming) |
| Server Scripts | ✅ Working | LevelGenerator + GameManager active |
| UI/HUD | ✅ Basic | Score and coin counters visible |
| Shop System | 🔄 In Progress | UI visible, functionality pending |
| Death/Respawn | ✅ Working | 3 second respawn delay |
| Data Persistence | ⏳ Disabled | Requires API services enabled |

## 🏗️ Development Team & Agent Responsibilities

### 1. Server/Gameplay Agent
**Responsible for:**
- `LevelGenerator.lua` - Procedural platform generation
- `GameManager.server.lua` - Player lifecycle, leaderstats, respawn
- `PlatformModule.lua` - Platform behaviors (kill, fade, bounce, move, etc.)
- Server-side game logic and state management

**Current Priority:** Ensure platforms generate correctly and player spawns safely

### 2. Build/Integration Agent  
**Responsible for:**
- `default.project.json` - Rojo project configuration
- `.github/workflows/publish.yml` - CI/CD pipeline
- Build validation and artifact generation
- Ensuring all scripts make it into .rbxl file correctly

**Current Priority:** Verify Script vs LocalScript types are correct in builds

### 3. Client/UI Agent
**Responsible for:**
- `CameraController.lua` - Smooth follow camera
- `DistanceTracker.lua` - Score/distance calculation
- `ShopController.lua` - Shop UI and purchase handling
- `MainUIHandler.client.lua` - HUD, death screens, buttons

**Current Priority:** Fix camera to follow player properly

### 4. Design/QA Agent
**Responsible for:**
- Visual polish and color schemes
- Difficulty balancing
- Playtesting and bug reports
- Game feel and pacing

**Current Priority:** Test full game loop from spawn to death

## 🎮 Platform Types

| Type | Color | Behavior |
|------|-------|----------|
| Static | Gray | Basic platform |
| Moving | Blue | Oscillates side-to-side |
| Fading | Yellow | Disappears 1s after touch |
| Crumbling | Brown | Shakes then falls |
| Bounce | Green | Launch pad |
| Kill | Red | Instant death |

## 🚀 Quick Start

### Download & Play (No Setup Required)

1. Go to **GitHub Actions** tab in this repo
2. Click the latest successful workflow run
3. Download `EndlessEscape-Game` artifact
4. Extract and open `EndlessEscape.rbxl` in Roblox Studio
5. Press F5 to play!

### Development Setup (Rojo)

```bash
# Install Rojo
cargo install rojo

# Clone repo
git clone https://github.com/clawchin2/roblox1.0.git
cd roblox1.0

# Start Rojo
rojo serve

# In Roblox Studio: Install Rojo plugin → Connect
```

## 📁 Project Structure

```
EndlessEscape/
├── default.project.json          # Rojo configuration
├── .github/workflows/
│   └── publish.yml               # Auto-build workflow
├── src/
│   ├── ReplicatedStorage/Modules/
│   │   ├── PlatformModule.lua    # Platform behaviors
│   │   ├── GameConfig.lua        # Balance settings
│   │   └── Utils.lua
│   ├── ServerScriptService/
│   │   ├── MainScript.server.lua # Server entry point
│   │   ├── GameManager.server.lua # Player management
│   │   └── LevelGenerator.lua    # Procedural generation
│   ├── StarterPlayer/Client/
│   │   ├── init.client.lua
│   │   ├── CameraController.lua
│   │   ├── DistanceTracker.lua
│   │   └── ShopController.lua
│   ├── StarterGui/
│   │   └── MainUIHandler.client.lua
│   └── Workspace/Lobby/
└── README.md
```

## 💰 Monetization Strategy

**Micro-relief model** optimized for kid/teen engagement:

| Product | Cost | Description |
|---------|------|-------------|
| Revive | 25 R$ | Continue from death point |
| Skip | 15 R$ | Bypass difficult section |
| Coin Pack (Small) | 49 R$ | 100 coins |
| Coin Pack (Medium) | 99 R$ | 250 coins |
| Coin Pack (Large) | 199 R$ | 600 coins |

## ⚙️ Configuration

Edit `GameConfig.lua`:

```lua
-- Spawn position
GameConfig.SPAWN_POSITION = Vector3.new(0, 15, 0)

-- Difficulty stages
GameConfig.DIFFICULTY_STAGES = {
    {distance = 0,    gapRange = {8, 12},  hazardChance = 0.1},
    {distance = 100,  gapRange = {10, 16}, hazardChance = 0.2},
    {distance = 250,  gapRange = {12, 20}, hazardChance = 0.35},
}

-- Monetization
GameConfig.REVIVE_COST = 25
GameConfig.SKIP_COST = 15
```

## 🐛 Known Issues

1. **Camera** - Currently default, needs smooth follow implementation
2. **Data Store** - Disabled until API services enabled on Roblox
3. **Shop** - UI visible but purchases not functional yet

## 📝 License

MIT - Feel free to use and modify.

---

**Built for the Roblox platform. Ship fast, iterate faster.** 🚀

*Repository: https://github.com/clawchin2/roblox1.0*
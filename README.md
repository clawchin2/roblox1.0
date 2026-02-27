# Endless Escape 🎮

A high-intensity endless runner obstacle course for Roblox. Jump, dodge, and survive through procedurally generated challenges.

## 🚨 CURRENT REVAMP IN PROGRESS

**Specialist agents are currently redesigning the game for better playability:**

| Agent | Status | Focus |
|-------|--------|-------|
| 🎮 Game Designer | 🔄 Active | Tutorial, onboarding, level flow |
| 🎨 UI Designer | 🔄 Active | Visual overhaul, animations, colors |
| 🧪 Player Tester | 🔄 Active | Friction points, UX issues |
| ⚙️ Gameplay Engineer | 🔄 Active | Camera, physics, safety nets |

**Goal:** Make the game playable by a 10-year-old within 5 seconds of opening.

## 🎯 Current Status

| Feature | Status | Notes |
|---------|--------|-------|
| Baseplate Spawn | ✅ Working | Green 50x50 platform at start |
| Platform Generation | ✅ Working | 25+ platforms generate ahead |
| First Jump | 🔧 Being Fixed | Currently too far, agents working on it |
| Player Movement | ✅ Working | Standard Roblox physics |
| Camera | 🔧 Being Fixed | Default → Smooth follow |
| Server Scripts | ✅ Working | LevelGenerator + GameManager active |
| UI/HUD | 🔧 Being Redesigned | Professional polish in progress |
| Tutorial System | 🆕 Adding | Visual arrows, instructions |
| Safety/Checkpoints | 🆕 Adding | No more infinite falling |
| Shop System | 🔄 In Progress | UI visible, functionality pending |

## 🏗️ Development Team & Agent Responsibilities

### 🎮 Game Designer Agent
**Responsible for:**
- Tutorial/onboarding experience
- Level flow and pacing
- Difficulty curve design
- Player guidance systems (arrows, signs)

**Files:**
- `LevelGenerator.lua` - Platform placement and spacing
- Tutorial overlay systems

### 🎨 UI/UX Designer Agent
**Responsible for:**
- Visual polish and theming
- Animation and feedback
- Button styling and colors
- HUD clarity and readability

**Files:**
- `MainUIHandler.client.lua`
- `TutorialUI.lua` (new)
- Color schemes and gradients

### ⚙️ Gameplay Engineer Agent
**Responsible for:**
- Camera controller (smooth follow)
- Physics and collision
- Safety systems (anti-fall)
- Checkpoint system
- Performance optimization

**Files:**
- `CameraController.lua`
- `GameManager.server.lua`
- Safety/respawn logic

### 🧪 Player Tester Agent
**Responsible for:**
- User experience testing
- Friction point identification
- Playability reports
- Accessibility checks

**Output:**
- `PLAYER_FEEDBACK.md`
- Issue prioritization
- UX recommendations

### 🔧 Build Integration Agent (Main)
**Responsible for:**
- Rojo configuration
- GitHub Actions workflows
- Build validation
- Release management

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
│   │   ├── ShopController.lua
│   │   └── TutorialUI.lua        # 🆕 Tutorial system
│   ├── StarterGui/
│   │   └── MainUIHandler.client.lua
│   └── Workspace/Lobby/
├── PLAYER_FEEDBACK.md            # 🆕 UX testing reports
└── README.md
```

## 🎮 Platform Types

| Type | Color | Behavior |
|------|-------|----------|
| Static | Gray | Basic platform |
| Moving | Blue | Oscillates side-to-side |
| Fading | Yellow | Disappears 1s after touch |
| Crumbling | Brown | Shakes then falls |
| Bounce | Green | Launch pad |
| Kill | Red | Instant death |

## 🎨 Design Principles (Being Implemented)

1. **Immediate Clarity** - Player knows what to do in 3 seconds
2. **Visual Guidance** - Arrows and signs show the way
3. **Gradual Difficulty** - Easy start, ramp up slowly
4. **Safety First** - Checkpoints prevent frustration
5. **Juicy Feedback** - Every action has visual/audio response
6. **Kid-Friendly** - Bright colors, big buttons, clear text

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

## 📝 License

MIT - Feel free to use and modify.

---

**Built for the Roblox platform. Ship fast, iterate faster.** 🚀

*Repository: https://github.com/clawchin2/roblox1.0*
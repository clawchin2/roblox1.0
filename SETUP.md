# Endless Escape - Setup Guide

## Option 1: Git Clone + Rojo (Fastest)

1. Clone to local:
   ```bash
   git clone https://github.com/YOUR_USERNAME/EndlessEscape.git
   cd EndlessEscape
   ```

2. Install Rojo:
   ```bash
   # macOS/Linux
   cargo install rojo
   
   # Windows
   npm install -g rojo
   ```

3. Start Rojo server:
   ```bash
   rojo serve
   ```

4. In Roblox Studio:
   - Install the [Rojo plugin](https://www.roblox.com/library/4048317705/Rojo)
   - Press "Connect" in the plugin
   - Done! Changes sync automatically

## Option 2: Download ZIP + Manual Setup

1. Download ZIP from GitHub
2. Extract to a folder
3. Create new Roblox place
4. Create these folders in Explorer:
   - ReplicatedStorage/Modules
   - ReplicatedStorage/Events/GameEvents
   - ServerScriptService/Server
   - StarterPlayer/StarterPlayerScripts/Client
   - StarterGui
   - ReplicatedFirst
5. Copy-paste each `.lua` file to matching folder
6. Set script types:
   - `init.server.lua` → Script
   - `init.client.lua` → LocalScript  
   - `LoadingScreen.lua` → LocalScript (in ReplicatedFirst)
   - `MainUIHandler.client.lua` → LocalScript

## First Run

1. Press F5 to playtest
2. Your character spawns at origin
3. Platforms generate automatically ahead of you
4. Jump across gaps, avoid red kill zones
5. Collect gold coins
6. Press "SHOP" to view cosmetics

## Publishing to Roblox

1. File → Publish to Roblox As...
2. Create new game
3. Configure game settings
4. Enable Studio Access to API Services (for data stores)
5. Publish!

## Next Steps

1. Set up Developer Products for monetization
2. Configure game passes for premium features
3. Customize platform colors in `PlatformModule.lua`
4. Adjust difficulty in `GameConfig.lua`
5. Add your own platform types

## Troubleshooting

**Platforms not spawning?**
- Check ServerScriptService for errors
- Verify LevelGenerator is required by GameManager

**UI not showing?**
- Check StarterGui scripts are LocalScripts
- Verify no errors in client output

**Data not saving?**
- Enable API Services in Game Settings
- Test in actual Roblox, not just Studio
# CI/CD Setup Guide

Auto-deploy your code to Roblox on every push to `main`.

---

## 🔑 Step 1: Get Roblox Open Cloud API Key

1. Go to [Roblox Creator Dashboard](https://create.roblox.com/)
2. Click your profile (top right) → **Settings**
3. Go to **API Keys** tab
4. Click **Create API Key**
5. Fill in:
   - **Name:** `EndlessEscape-Deploy`
   - **Expiration:** 1 year (or your preference)
   - **Scope:** Select your game universe
   - **Operations:** 
     - ✅ `universe-places:write`
     - ✅ `universe-places:read`
6. **Copy the API key** (you'll only see it once!)

---

## 🎮 Step 2: Get Your Place IDs

### Universe ID
1. Go to [Creator Dashboard](https://create.roblox.com/dashboard/creations)
2. Click your game
3. Look at the URL: `https://create.roblox.com/dashboard/creations/experiences/UNIVERSE_ID/...`
4. Copy the **UNIVERSE_ID** number

### Place ID
1. In the same page, click **Places** on the left
2. Click your main place
3. Look at the URL: `https://create.roblox.com/dashboard/creations/experiences/.../places/PLACE_ID`
4. Copy the **PLACE_ID** number

---

## 🔐 Step 3: Add Secrets to GitHub

1. Go to your GitHub repo: `github.com/clawchin2/roblox1.0`
2. Click **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret** for each:

| Secret Name | Value |
|------------|-------|
| `ROBLOX_API_KEY` | Your API key from Step 1 |
| `ROBLOX_PLACE_ID` | Your place ID from Step 2 |
| `ROBLOX_UNIVERSE_ID` | Your universe ID from Step 2 |

---

## 🚀 How Deployment Works

### Automatic (on push to main)
```
git push origin main
↓
GitHub Actions triggers
↓
Rojo builds place file
↓
Uploads to Roblox via Open Cloud API
↓
Game updated automatically
```

### Manual (choose environment)
1. Go to GitHub repo → **Actions** tab
2. Click **Deploy to Roblox** workflow
3. Click **Run workflow**
4. Choose:
   - `development` - Safe testing
   - `production` - Live game

---

## 📁 What Gets Deployed

The workflow builds from `games/endless-escape/`:
- All server scripts (ServerScriptService)
- All client scripts (StarterPlayerScripts)
- Config module (ReplicatedStorage)

**Not included** (must set up manually in Studio):
- Terrain/geometry
- UI assets/images
- Audio
- Models

---

## ⚠️ Important Notes

### Before First Deploy
1. **Create the place first** in Roblox Studio and publish it
2. **Set up Developer Products** in the live place (they have different IDs)
3. **Configure Gamepasses** in the live place
4. Then connect the GitHub deployment

### Code vs Assets
- ✅ **Code**: Auto-deployed via GitHub
- ❌ **Assets**: Must be added in Studio manually (or use rbxmx imports)

### Testing Strategy
```
Local Testing → Rojo sync (localhost)
    ↓
Staging Testing → Manual workflow run (dev environment)
    ↓
Production → Auto-deploy on push to main
```

---

## 🐛 Troubleshooting

| Issue | Solution |
|-------|----------|
| "Invalid API key" | Check secret is saved correctly, regenerate if needed |
| "Place not found" | Verify PLACE_ID is correct (not universe ID) |
| "Permission denied" | Ensure API key has `universe-places:write` scope |
| Build fails | Check `default.project.json` syntax |
| Scripts not updating | Verify file paths in project.json match actual paths |

---

## 🔧 Alternative: Local Build

Test the build locally before pushing:

```bash
cd games/endless-escape

# Install Rojo (one time)
cargo install rojo

# Build place file
rojo build default.project.json --output EndlessEscape.rbxlx

# Open in Studio
# File → Open from File → Select EndlessEscape.rbxlx
```

---

## 📊 Deployment Status

Check deployment status in GitHub:
1. Repo → **Actions** tab
2. Click latest workflow run
3. View logs for each step

Successful deployment shows:
```
✅ Deployment successful!
Place ID: 123456789
Commit: abc123...
Author: clawchin2
```

---

**You're now set up for automatic deployment!** 🎉

Every push to `main` will automatically update your Roblox game.

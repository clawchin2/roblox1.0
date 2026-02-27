# GitHub Actions Setup for Endless Escape

## Required Secrets

Go to your GitHub repo → Settings → Secrets and variables → Actions → New repository secret

Add these secrets:

### 1. ROBLOX_API_KEY
Get from [Roblox Creator Dashboard](https://create.roblox.com/dashboard/credentials)
- Create API Key
- Add these permissions:
  - `universe:places:publish` - Publish places
  - `universe:places:update` - Update places
- Add your universe to the key

### 2. ROBLOX_UNIVERSE_ID
Found in Creator Dashboard → Your Experience → Settings
- Format: `1234567890`

### 3. ROBLOX_PLACE_ID
Found in Roblox Studio:
- Game Settings → Basic Info
- Or URL: `roblox.com/games/PLACE_ID/...`

### 4. DISCORD_WEBHOOK (Optional)
For deployment notifications:
- Discord Server → Channel Settings → Integrations → Webhooks → New Webhook
- Copy webhook URL

## How It Works

On every push to `main`:
1. ✅ Builds the .rbxl file from source
2. ✅ Publishes directly to your Roblox place
3. ✅ Creates artifacts for download
4. 🏷️ Creates GitHub Release (if commit has `[release]`)

## Manual Deploy

You can also trigger manually:
1. Go to Actions tab in GitHub
2. Select "Build and Publish to Roblox"
3. Click "Run workflow"
4. Choose environment (dev/prod)

## Versioning

- Auto-increments: Every push = new version
- GitHub Releases: Add `[release]` to commit message
- Roblox Version History: Check Creator Dashboard

## Troubleshooting

**"Authentication failed"**
→ Check ROBLOX_API_KEY is correct and has right permissions

**"Universe not found"**
→ Verify ROBLOX_UNIVERSE_ID matches your experience

**"Place not found"**
→ Check ROBLOX_PLACE_ID is correct

## Alternative: Cookie Auth (Legacy)

If Open Cloud doesn't work, you can use cookie-based auth:

1. Get your .ROBLOSECURITY cookie (from browser dev tools)
2. Add as secret: `ROBLOX_COOKIE`
3. Uncomment the cookie-based publish step in the workflow

⚠️ **Warning:** Cookies expire! Prefer Open Cloud API keys.
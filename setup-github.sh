# GitHub Setup Script for Endless Escape
# Run this after creating a new GitHub repo

echo "Setting up Endless Escape GitHub repository..."

# Initialize git if not already done
if [ ! -d ".git" ]; then
    git init
fi

# Add all files
git add .

# Initial commit
git commit -m "Initial commit: Endless Escape base game

Features:
- Procedural platform generation
- 6 platform types (static, moving, fading, crumbling, bounce, kill)
- Coin collection system
- Shop with trails and skins
- Micro-relief monetization (revive 25R$, skip 15R$)
- Smooth camera follow
- Loading screen
- Data persistence

Ready for Roblox Studio via Rojo."

# Add remote (replace with your actual repo URL)
# git remote add origin https://github.com/YOUR_USERNAME/EndlessEscape.git

echo ""
echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Create a new repository on GitHub (don't initialize with README)"
echo "2. Run: git remote add origin https://github.com/YOUR_USERNAME/EndlessEscape.git"
echo "3. Run: git push -u origin main"
echo "4. Install Rojo: cargo install rojo  (or npm install -g rojo)"
echo "5. Run: rojo serve"
echo "6. Open Roblox Studio, install Rojo plugin, connect"
echo ""
echo "Game is ready to play!"
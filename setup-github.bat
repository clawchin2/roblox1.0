@echo off
echo Setting up Endless Escape GitHub repository...

REM Initialize git if not already done
if not exist ".git\" (
    git init
)

REM Add all files
git add .

REM Initial commit
git commit -m "Initial commit: Endless Escape base game"

echo.
echo Setup complete!
echo.
echo Next steps:
echo 1. Create a new repository on GitHub (don't initialize with README)
echo 2. Run: git remote add origin https://github.com/YOUR_USERNAME/EndlessEscape.git
echo 3. Run: git push -u origin main
echo 4. Install Rojo: npm install -g rojo
echo 5. Run: rojo serve
echo 6. Open Roblox Studio, install Rojo plugin, connect
echo.
echo Game is ready to play!
pause
#!/bin/bash
# git-push.sh — Quick push script for Endless Escape updates
# Usage: ./git-push.sh "Your commit message"

cd /data/.openclaw/workspace

if [ -z "$1" ]; then
    echo "Usage: ./git-push.sh \"Your commit message\""
    exit 1
fi

git add -A
git commit -m "$1"
git push origin main

echo "✅ Pushed to https://github.com/clawchin2/roblox1.0"

# 🎯 DAY 1 GOAL PROPOSAL

**From:** Designer Agent  
**To:** Chinmaya (User)  
**Date:** 2026-02-27  
**Status:** ⏳ AWAITING APPROVAL

---

## 📋 PROPOSED GOAL FOR TODAY

### **Goal: Fix Critical Bugs & Add Pet Following**

**Priority:** 🔴 CRITICAL (Must fix before any other features)

**Why This First:**
- Current game has no visual feedback when hatching
- Players don't know what pet they got
- No pet following = game feels empty
- These bugs block ALL future development

---

## 🎯 SPECIFIC TASKS (In Order)

### Task 1: Fix Hatch UI (2 hours)
**Problem:** Hatch animation doesn't appear when buying egg  
**Solution:** 
- Debug why hatch popup isn't showing
- Ensure pet data passes correctly from server to client
- Make popup appear center screen with pet name, rarity, stats
- Add rarity color coding (gray/green/blue/purple/gold)

**Success Criteria:**
- Buy egg → see popup within 1 second
- Popup shows correct pet name
- Rarity color matches (Common=gray, Legendary=gold)
- Click "AWESOME!" to close

---

### Task 2: Pet Follows Player (3 hours)
**Problem:** No pet appears after hatching  
**Solution:**
- Create pet model that spawns next to player
- Pet follows player using BodyPosition or CFrame
- Pet stays 3-5 studs behind player
- Smooth following (not teleporting)

**Success Criteria:**
- After hatching, pet appears next to player
- Pet follows when player walks
- Pet stays visible and doesn't disappear
- Multiple pets can follow (if you hatch multiple)

---

### Task 3: Show Equipped Pet (1 hour)
**Problem:** Player doesn't know which pet is active  
**Solution:**
- Add small pet icon + name in corner of screen
- Shows currently equipped pet
- Updates when you hatch new pet (auto-equip)

**Success Criteria:**
- UI shows "Equipped: [Pet Name]"
- Updates automatically after hatch
- Shows pet rarity color

---

## 📊 ESTIMATED TIME
- **Total:** 6 hours
- **Coder work:** 4 hours
- **Testing + QA:** 2 hours

---

## ✅ APPROVAL REQUIRED

**Chinmaya, reply with one of:**

1. **"APPROVE: Fix hatch UI and add pet following"** → Coder starts immediately
2. **"MODIFY: [your changes]"** → I adjust the goal
3. **"REJECT"** → We discuss different approach

---

## 🔄 WHAT HAPPENS AFTER APPROVAL

1. **You say APPROVE**
2. **Coder** implements (6 hours)
3. **Tester** downloads and tests
4. **QA** verifies quality
5. If issues → Back to Coder
6. If perfect → Update tracker, plan Day 2

---

## 📁 FILES TO BE MODIFIED

- `src/StarterPlayer/StarterPlayerScripts/Client/HatchUI.client.lua`
- `src/ServerScriptService/Server/HatchHandler.server.lua`  
- `src/StarterPlayer/StarterPlayerScripts/Client/PetFollow.client.lua` (NEW)
- `src/StarterPlayer/StarterPlayerScripts/Client/UI.client.lua`

---

## 🎮 REFERENCE: Pet Simulator X

**How they do it:**
- Big shiny popup when egg hatches
- Pet immediately appears and follows
- Pet has idle animation (bouncing, floating)
- Rarity shown by glow color around pet

**We'll simplify:**
- Static popup (no fancy animation yet)
- Basic follow (no idle animation yet)
- Color by rarity ✓

---

**Ready for your approval!** 🚀
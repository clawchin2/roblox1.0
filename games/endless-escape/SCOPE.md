# Endless Escape — Game Scope Document
**Version:** 1.0 | **Date:** 2026-02-23 | **Author:** Game Designer Agent

---

## Core Loop

Player spawns on a moving conveyor-style platform pulling them toward hazards. They tap/click to jump and dodge randomized obstacles (spinning blades, falling blocks, lava gaps, crushers). Death is instant, frequent (every 10-30 seconds for average player), and resets them to the last checkpoint — but checkpoints are spaced far apart. A **distance counter** is the only score. After death, a 3-second respawn screen shows a "Skip Ahead" button (20 Robux) and a "Shield" button (15 Robux). The player can dismiss and retry free, but the buttons are big, bright, and one-tap. The further you go, the more hazards layer on, so spending feels rational ("I was SO close"). There is no win state — the course is procedurally infinite.

---

## Monetization Plan

### Dev Products (Impulse Buys — Repeatable)
| Product | Price | Effect |
|---|---|---|
| **Skip Ahead** | 20 Robux | Teleport past next 3 obstacles from death point |
| **Shield Bubble** | 15 Robux | Survive 1 hit (gold shimmer effect, visible to others) |
| **Speed Boost** | 15 Robux | 10 seconds of 1.5x speed (skip slow hazard sections) |
| **Instant Revive** | 25 Robux | Respawn exactly where you died (no checkpoint reset) |
| **Lucky Coin** (x100) | 10 Robux | In-game currency for cosmetics only (soft currency sink) |

### Gamepasses (One-Time)
| Pass | Price | Effect |
|---|---|---|
| **2x Coins** | 99 Robux | Double coin drops forever |
| **VIP Trail** | 149 Robux | Rainbow trail + VIP chat tag + exclusive lobby area |
| **Radio** | 49 Robux | Play audio in-game (social flex) |

### Key Design Rules
- Death screen shows dev products with **big colorful buttons**, no text needed — icons only
- Products are deliberately cheap to reduce purchase friction (15-25 Robux = pocket change)
- Shield Bubble is visible to other players → social proof → "I want that too"
- No pay-to-win — spending saves time/frustration, never locks content

---

## Retention Hooks

1. **Daily Streak Bonus** — Log in daily → escalating coin rewards (days 1-7, resets on miss). Day 7 = free Shield Bubble. Visible streak counter on screen.
2. **Distance Leaderboard** — Global + friends. Resets weekly. Top 10 get exclusive temporary trail.
3. **Lucky Spin** — Free spin every 4 hours (coins, trails, rare pets that follow you). Creates check-in cadence.
4. **Seasonal Obstacles** — Swap hazard skins (Valentine's hearts, Halloween pumpkins) to re-trigger curiosity. Zero code change, just asset swaps.
5. **"Beat Your Best"** — Personal best distance shown at spawn. Simple but powerful for kids.
6. **Rebirth System** — At distance milestones (1000, 5000, 10000), earn a prestige star. Stars shown next to name. Resets distance. Completionists grind forever.

---

## MVP Feature List (Build Order)

1. **Conveyor/runner base system** — Player on auto-scrolling platform, jump to dodge. Server-authoritative movement.
2. **Obstacle module system** — Modular hazard segments (blade, crusher, lava gap, falling block, moving wall). Min 8 unique types. Randomly sequenced per run.
3. **Death + respawn system** — Instant kill on touch, ragdoll death animation, 3-second respawn screen with purchase buttons.
4. **Distance counter** — Server-tracked, displayed as big number top-center. Personal best saved.
5. **Checkpoint system** — Auto-checkpoints every ~200 distance units. Visual flag marker.
6. **Dev product integration** — Skip Ahead, Shield Bubble, Speed Boost, Instant Revive, Lucky Coins. All functional on death screen.
7. **Gamepass integration** — 2x Coins, VIP Trail, Radio. Check on join, apply perks.
8. **Coin drops** — Coins scattered on the course. Collected on touch. Saved per player (DataStore).
9. **Daily streak system** — Login detection, escalating rewards, streak counter UI.
10. **Leaderboard** — Global + personal best. OrderedDataStore. Billboard at spawn.
11. **Lucky Spin** — Simple UI wheel. Timer-gated. Cosmetic rewards.
12. **Cosmetics shop** — Trails + hats purchasable with coins. Purely visual.
13. **Lobby/spawn area** — Simple hub with leaderboard, shop, and portal to start run.
14. **Thumbnail + icon + metadata** — Game page assets, description, social tags.

---

## What to Skip in v1

- **Multiplayer race mode** — Add in v1.1 if retention is good. Adds complexity.
- **Pets** — Classic Roblox money printer but scope-heavy. v2 feature.
- **Battle Pass / Season Pass** — Needs content pipeline. Add after week 2 data.
- **Trading** — Exploit magnet. Never in v1.
- **Custom obstacle creator (UGC)** — Cool for retention, complex to build. v2+.
- **Friend invite rewards** — Good for growth but not MVP.
- **Rebirth system** — Listed in retention hooks but can ship in week 2 patch. Not day 1.
- **Audio/Radio gamepass** — Low priority, add post-launch.

---

## Revenue Estimate (Conservative)

**Comparable games:** Death Run, Obby But You're on a Bike, Speed Run 4 — all in the 10K-50K CCU range at peak with significant Robux revenue.

**Assumptions (first 30 days):**
- 100 CCU average (target floor)
- ~2,400 unique daily players
- 5% conversion rate on dev products (frustrated buyers)
- Average purchase: 18 Robux
- 1.2 purchases per converting player per session
- 1.5 sessions per day for returning players

**Monthly projection:**
- 2,400 players/day × 5% × 18 Robux × 1.2 = **2,592 Robux/day**
- 30 days = **~77,760 Robux/month**
- At 0.0035 USD/Robux (DevEx rate) = **~$272/month at 100 CCU**

**If we hit 500 CCU:** ~$1,360/month
**If we hit 1,000 CCU:** ~$2,720/month
**Gamepass revenue (additive):** +20-40% on top of dev products

**Break-even:** Immediate (zero production cost with AI agents). Every Robux is profit.

**Upside scenario:** If the game catches algorithm placement (Roblox Discover page), CCU can spike 10-50x for days. One viral moment = months of revenue. The death/frustration loop is inherently shareable (rage clips → TikTok → organic growth).

---

## Technical Notes for Coding Agent

- **Server-authoritative** distance tracking and purchases. Never trust the client.
- **DataStoreService** for persistence (coins, streaks, personal best, purchases).
- **MarketplaceService** for all Robux transactions. Use `ProcessReceipt` callback properly — this is where money is made, do NOT get this wrong.
- **Modular obstacle segments** — each is a self-contained module with entry/exit points. Server picks random sequence per run. Makes infinite course trivial.
- **No ReadingRequired™** — All UI is icons + numbers + colors. No paragraphs. No tutorials. Kid lands in game, sees platform, starts running. Death teaches mechanics.
- **Mobile-first** — 60%+ of Roblox players are on mobile. One-button controls (tap = jump). Death screen buttons must be fat finger-friendly.
- **Performance budget** — Keep Part count low. Stream obstacles in/out. Target 30fps on low-end mobile.

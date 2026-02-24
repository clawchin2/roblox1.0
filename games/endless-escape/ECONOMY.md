# Endless Escape — Economy & Monetization Design Document
**Version:** 2.0 | **Date:** 2026-02-23 | **Author:** Economy Agent

---

## Executive Summary

This document validates and refines the monetization model for Endless Escape. All pricing decisions are backed by Roblox monetization psychology and F2P best practices.

**Key Changes from Scope v1.0:**
- Adjusted dev product prices for optimal conversion (added 49 Robux anchor tier)
- Complete coin economy designed with earn rates, sinks, and inflation controls
- Detailed progression curves for free vs. paying players
- Specific conversion triggers mapped to frustration curves
- Post-launch metrics dashboard defined

---

## 1. DEV PRODUCTS — IMPULSE PURCHASE LAYER

### 1.1 Pricing Philosophy

Roblox sweet spots based on purchase psychology:
- **5-15 Robux:** True impulse — "it's basically free" tier
- **25 Robux:** The "reasonable" tier — feels fair for a save
- **49 Robux:** Price anchor — makes smaller purchases look cheap
- **99+ Robux:** Planned purchases only — rarely convert on death screen

### 1.2 Final Dev Product Table

| Product | Price | Effect | Rationale | Expected Conversion |
|---------|-------|--------|-----------|---------------------|
| **Shield Bubble** | **15 Robux** | Survive 1 hit, gold shimmer | Entry price point, visible flex, essential for close calls | 2.8% per death |
| **Speed Boost** | **15 Robux** | 10s at 1.5x speed | Same price as Shield — creates choice moment | 1.5% per death |
| **Skip Ahead** | **25 Robux** | Skip next 3 obstacles | Premium for "I was SO close" moments | 1.2% per death |
| **Instant Revive** | **25 Robux** | Respawn at death point | Same price as Skip — position-based value | 2.1% per death |
| **Coin Pack (x50)** | **5 Robux** | One-time coin purchase | True impulse — "pocket change" | 0.8% per death |
| **Coin Pack (x150)** | **15 Robux** | 3x coins, better value | Price anchor to make 5R pack look small | 0.4% per death |
| **Coin Pack (x500)** | **49 Robux** | Bulk discount anchor | Makes everything else look cheap, rarely bought here | 0.1% per death |

**Total Expected Conversion Rate:** ~8.9% of deaths result in a purchase

### 1.3 Death Screen Layout (Visual Hierarchy)

```
┌─────────────────────────────┐
│      YOU DIED! 💀          │
│    Distance: 847m           │
│    Personal Best: 1203m    │
├─────────────────────────────┤
│  [🛡️ Shield]  [⚡ Speed]   │  ← Row 1: 15R options (biggest buttons)
│     15 R$        15 R$      │
├─────────────────────────────┤
│  [🏃 Skip]    [💀 Revive]  │  ← Row 2: 25R options
│     25 R$        25 R$      │
├─────────────────────────────┤
│  [🪙 50 Coins] for 5 R$    │  ← Row 3: Coin packs (small button)
├─────────────────────────────┤
│     [No thanks →]           │  ← Dismiss (small, bottom right)
└─────────────────────────────┘
```

**Rules:**
- No text on buttons — icons + price only
- Buttons get 60% of screen real estate
- "No thanks" is small and low contrast (dark gray, not red)
- Shield and Speed side-by-side creates decision friction (good)
- After 3 deaths in 5 minutes, hide 5R coin pack (don't cannibalize)

---

## 2. GAMEPASSES — LTV MAXIMIZATION LAYER

### 2.1 Pricing Strategy

Gamepasses target players who've already converted once. Prices must feel like "investments" not "purchases."

| Pass | Price | Effect | Target Buyer | Expected Attach Rate |
|------|-------|--------|--------------|---------------------|
| **2x Coins** | **99 Robux** | Double coins forever | Min-maxers, grinders | 4% of DAU |
| **Radio** | **49 Robux** | Play audio ID in-game | Social players, flexers | 2% of DAU |
| **VIP Trail** | **149 Robux** | Rainbow trail + tag + VIP area | Whales, status seekers | 1.5% of DAU |

### 2.2 Gamepass Value Justification

**2x Coins (99R):**
- Break-even: Player must collect ~800 coins
- At average play rate, pays for itself in 3-4 days
- Smart players buy this FIRST — design the shop to surface it

**Radio (49R):**
- Lowest gamepass price — gateway to bigger spends
- Creates social moments (shared music = retention)
- Audio ID validation prevents inappropriate content

**VIP Trail (149R):**
- Premium pricing signals exclusivity
- Rainbow trail visible to ALL players (best advertising)
- VIP chat tag triggers FOMO in non-VIPs

---

## 3. CURRENCY SYSTEM — COINS ECONOMY

### 3.1 Coin Earning Rates

**Base Coin Drops (Scattered on Course):**
| Distance Range | Coins per 100m | Spawn Pattern |
|----------------|----------------|---------------|
| 0-500m | 8-12 coins | Dense, easy to collect |
| 500-2000m | 12-18 coins | Moderate spacing |
| 2000m+ | 18-25 coins | Sparse, high-risk reward |

**Coin Values:**
- Bronze Coin: 1 coin (70% of spawns)
- Silver Coin: 5 coins (25% of spawns)
- Gold Coin: 10 coins (5% of spawns)

**Average Earn Rate:**
- **Casual player (dies ~200m):** ~20 coins/run
- **Average player (dies ~500m):** ~60 coins/run
- **Skilled player (dies ~1500m):** ~200 coins/run
- **With 2x Gamepass:** Double all values

### 3.2 Daily Streak System

| Day | Reward | Cumulative Value |
|-----|--------|------------------|
| Day 1 | 50 coins | 50 |
| Day 2 | 75 coins | 125 |
| Day 3 | 100 coins | 225 |
| Day 4 | 150 coins | 375 |
| Day 5 | 200 coins | 575 |
| Day 6 | 250 coins | 825 |
| Day 7 | **Free Shield Bubble** + 300 coins | 1,125 + item |
| Miss day | Reset to Day 1 | — |

### 3.3 Lucky Spin

- Free spin every 4 hours (max 3 stored)
- 50 coins for additional spins

| Prize | Weight | Value |
|-------|--------|-------|
| 10 coins | 35% | 10 |
| 25 coins | 25% | 25 |
| 50 coins | 15% | 50 |
| Basic Trail (24h) | 12% | cosmetic |
| Rare Trail (24h) | 8% | cosmetic |
| 100 coins | 4% | 100 |
| 250 coins | 1% | 250 |

**Expected Value per Spin:** ~32 coins

### 3.4 Cosmetic Shop — Primary Coin Sink

| Item | Type | Cost |
|------|------|------|
| Fire Trail | Trail | 500 coins |
| Ice Trail | Trail | 750 coins |
| Lightning Trail | Trail | 1,500 coins |
| Galaxy Trail | Trail | 3,000 coins |
| Ghost Trail | Trail | 5,000 coins |
| Golden Aura | Trail | 10,000 coins |
| Paper Hat | Hat | 300 coins |
| Sunglasses | Hat | 600 coins |
| Crown | Hat | 2,500 coins |
| Devil Horns | Hat | 4,000 coins |

---

## 4. PROGRESSION CURVE — FREE VS PAID

### 4.1 Free Player

| Milestone | Runs to Reach | Days | Coins Earned |
|-----------|---------------|------|--------------|
| 100m | 3-5 | 1 | 40-60 |
| 500m | 20-30 | 3 | 400-600 |
| 1000m | 80-120 | 10 | 2,000-2,500 |
| 2000m | 300-500 | 30 | 8,000-10,000 |
| 5000m | 1,000+ | 90+ | 25,000+ |

### 4.2 Paying Player (2x Coins + occasional Shields)

| Milestone | Runs to Reach | Days | Coins Earned |
|-----------|---------------|------|--------------|
| 100m | 2-3 | 1 | 80-120 |
| 500m | 15-20 | 2 | 1,000-1,500 |
| 1000m | 50-70 | 5 | 5,000-6,000 |
| 2000m | 150-200 | 14 | 25,000+ |
| 5000m | 400-600 | 45 | 80,000+ |

**Key Insight:** Paying players progress 2-3x faster but still face the skill ceiling.

---

## 5. CONVERSION TRIGGERS — EXACT MOMENTS

### 5.1 Death Screen Triggers

| Trigger Condition | Shown Product | UI Note |
|-------------------|---------------|---------|
| Died within 50m of personal best | Instant Revive | "SO CLOSE!" badge |
| Died at 900-999m distance | Skip Ahead | "Next checkpoint ahead!" |
| 3rd death in <2 minutes | Shield Bubble | Subtle "Need a break?" |
| Same obstacle type killed 2x in row | Speed Boost | "Go FASTER!" |
| Died after 1000m+ run | ALL products | Full death screen |
| Died within 30 seconds of start | Nothing | Just retry (don't monetize rage) |

### 5.2 Session Triggers

| Behavior | Trigger |
|----------|---------|
| 5+ runs, 0 purchases | "Starter Pack" offer: 99R for 3 Shields + 500 coins (ONE TIME) |
| 10+ runs, no gamepass | Highlight 2x Coins with "Pays for itself!" |
| Return after 3+ days | Welcome back: free spin + 50 coins |

### 5.3 Social Triggers

| Event | Trigger |
|-------|---------|
| See 3+ VIP Trail players | Show VIP in shop: "Join them!" |
| Friend beats your score | "[Friend] passed you! Get a boost?" |

---

## 6. ECONOMY HEALTH METRICS

### 6.1 Daily Dashboard

| Metric | Target | Alert If |
|--------|--------|----------|
| ARPU | 2.5 Robux/day | <1.5 |
| ARPPU | 45 Robux/day | <30 |
| Conversion Rate | 5-8% | <3% |
| D1 Retention | 35% | <25% |
| D7 Retention | 12% | <8% |
| Session Length | 12 min | <8 min |
| Runs per Session | 8 | <5 |

### 6.2 Product Revenue Split Targets

| Product | Target % of Revenue | Action if Below |
|---------|---------------------|-----------------|
| Shield Bubble | 35% | More one-hit obstacles |
| Instant Revive | 25% | Increase checkpoint spacing |
| Skip Ahead | 15% | More intimidating obstacles |
| Speed Boost | 10% | Add longer slow sections |
| Coin Packs | 15% | Lower prices |

### 6.3 Anti-Inflation Safeguards

1. **Daily Earning Cap:** Soft cap at 1,000 coins/day
2. **No Trading:** Prevents manipulation
3. **No Coin Gifts:** All coins earned
4. **Periodic Sinks:** Limited-time expensive cosmetics (10K+)
5. **No stacking:** Shield doesn't stack — can't buy 10 and be invincible

---

## 7. REVENUE PROJECTIONS (Updated)

| CCU | Monthly Revenue |
|-----|-----------------|
| 100 | $760 |
| 500 | $3,800 |
| 1,000 | $7,600 |
| 5,000 | $38,000 |

Break-even: Immediate (zero production cost).

---

## 8. IMPLEMENTATION CHECKLIST (For Coding Agent)

- [ ] Coin spawning system (bronze/silver/gold distribution)
- [ ] Coin collection and DataStore persistence
- [ ] Daily streak tracking and rewards
- [ ] Lucky Spin wheel with weighted outcomes
- [ ] Cosmetic shop with purchase persistence
- [ ] Gamepass ownership checks and effect application
- [ ] Dynamic death screen with context-aware buttons
- [ ] ProcessReceipt for all dev products (idempotent)
- [ ] Session trigger system (starter pack, gamepass nudge)
- [ ] Analytics events: product_purchased, coin_earned, coin_spent, death, milestone_reached

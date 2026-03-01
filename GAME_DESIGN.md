# Endless Escape - Game Design Document

**Target:** ₹30L–₹1Cr/month revenue  
**Strategy:** High-volume, fast iteration (10-14 day cycles)  
**Core Loop:** Hatch → Collect → Evolve → Compete → Spend

---

## 🎮 Core Mechanics

### Creature Evolution System (REVISED)

Instead of merging 3 different pets, **each creature evolves into its own advanced form**:

| Stage 1 (Baby) | → | Stage 2 (Teen) | → | Stage 3 (Adult) | → | Stage 4 (Legendary) |
|----------------|---|----------------|---|-----------------|---|---------------------|
| Tiny Dragon | → | Dragon | → | Great Dragon | → | Ancient Dragon |
| Baby Unicorn | → | Unicorn | → | Royal Unicorn | → | Celestial Unicorn |
| Mini Griffin | → | Griffin | → | Imperial Griffin | → | Mythic Griffin |
| Fire Fox | → | Flame Fox | → | Inferno Fox | → | Volcanic Fox |
| Ice Wolf | → | Frost Wolf | → | Glacier Wolf | → | Arctic Wolf |
| Thunder Bird | → | Storm Bird | → | Tempest Bird | → | Thunderbird King |
| Phoenix | → | Firebird | → | Sunbird | → | Eternal Phoenix |
| Kraken | → | Sea Beast | → | Ocean Lord | → | Abyssal Kraken |
| Cerberus | → | Hellhound | → | Underworld Guard | → | Cerberus Alpha |
| Hydra | → | Multi-Head | → | Hydra Emperor | → | World Hydra |
| Chimera | → | Beast | → | Chimera Lord | → | Primordial Chimera |

**Evolution Requirements:**
- Stage 1 → 2: Collect 3 of same creature + 100 coins
- Stage 2 → 3: Collect 3 of Stage 2 + 500 coins
- Stage 3 → 4: Collect 3 of Stage 3 + 2000 coins

**Visual Evolution:**
- Each stage gets bigger, more detailed, cooler animations
- Stage 4 has unique aura/particles
- Name changes (e.g., "Tiny Dragon" → "Ancient Dragon")

---

## 💰 Monetization Mechanics

### Tier 1: Core Revenue (Implement First)

#### 1. Variable Reward Schedule
- **Current:** 50% Common, 30% Uncommon, 15% Rare, 4% Epic, 1% Legendary
- **Add:** "Near Miss" animation when close to rare
- **Psychology:** Dopamine loop - chase the next big win

#### 2. Evolution System (Replaces Merge)
- **Core Loop:** Hatch → Collect 3 same → Evolve → Repeat
- **Failed Evolution:** 20% chance to fail
- **Revenue:** Pay 25 Robux to guarantee success
- **Visual:** Stunning evolution animation with particles

#### 3. Daily/Session Limits
- **Free Limit:** 10 hatches/day
- **Skip:** 49 Robux for "Unlimited Hatches 1 Hour"
- **Psychology:** "Just one more hatch to evolve my dragon..."

#### 4. Battle Pass (Seasonal)
- **Price:** 299 Robux per 30-day season
- **Free Track:** Basic pets, small coin packs
- **Premium Track:** 
  - Exclusive Stage 4 pet (only available here)
  - 2x coins forever
  - Special legendary trail
  - Unique name tag color

---

### Tier 2: Revenue Boosters

#### 5. Auto-Hatch / Auto-Farm
- **Price:** 99 Robux for 1 hour
- **What:** Automatically hatches eggs while AFK
- **Why:** Players hate grinding, love progress
- **From Pet Simulator:** Their #1 seller

#### 6. Lucky Boosts (Consumables)
| Item | Price | Effect | When to Show |
|------|-------|--------|--------------|
| Lucky Potion | 25 Robux | 2x Rare+ chance (10 min) | After 5 Commons |
| Super Lucky | 99 Robux | 5x Rare+ chance (30 min) | After 10 Commons |
| Epic Boost | 149 Robux | Guaranteed Rare+ next hatch | After failed evolution |

#### 7. Inventory Expansion
- **Free:** 20 slots
- **Purchase:** 49 Robux per 10 additional slots
- **Why:** Hoarding instinct - players won't delete pets

#### 8. Trading System
- **Feature:** Player-to-player trading
- **Revenue:** Trade lock - pay 25 Robux to unlock instantly
- **Viral:** Players bring friends to trade = organic growth

---

### Tier 3: Psychology Hooks

#### 9. Leaderboards (Weekly Reset)
- **Categories:** 
  - Distance run
  - Coins collected
  - Creatures hatched
  - Evolution level
- **Prizes:** Top 10 get exclusive skin (unobtainable elsewhere)
- **Reset:** Every Sunday (creates urgency)

#### 10. Collection Book
- **Visual:** Album showing all evolution lines
- **Progress:** "72/100 collected (72%)"
- **Completion Bonus:** Special badge + exclusive pet
- **Why:** Completionists spend hundreds to fill gaps

#### 11. Social Proof / Showing Off
- **Equipped pet follows player** in lobby
- **Name tags** showing "12 Legendaries Owned"
- **Global announcements:** "🔥 Player evolved to Ancient Dragon!"
- **Lobby displays:** Show off your Stage 4 pets

#### 12. Limited Time Events
- **Frequency:** Every weekend
- **Exclusive:** Stage 4 variants only available during event
- **Scarcity:** "Only 48 hours left!"
- **FOMO:** Drives impulse purchases

---

## 📊 Revenue Projections

| Feature | Implementation | Monthly Revenue Impact |
|---------|---------------|----------------------|
| Evolution System | Week 1 | +40% retention |
| Battle Pass | Week 2 | +₹5L recurring |
| Auto-Hatch | Week 3 | +₹3L |
| Lucky Boosts | Week 4 | +₹2L |
| Trading + Inventory | Week 5 | +₹2L |
| Events | Week 6+ | +₹4L per event |

**Target:** ₹30L-₹1Cr/month

---

## 🛠️ Technical Implementation Priority

### Phase 1 (Week 1-2): Core Loop
- [ ] Evolution system backend
- [ ] Evolution UI (drag 3 creatures → evolve)
- [ ] Evolution animation sequence
- [ ] Failed evolution + boost option

### Phase 2 (Week 3-4): Retention
- [ ] Battle Pass system
- [ ] Daily quest system
- [ ] Leaderboards

### Phase 3 (Week 5-6): Monetization
- [ ] Auto-hatch system
- [ ] Lucky boost store
- [ ] Inventory expansion

### Phase 4 (Week 7-8): Social
- [ ] Trading system
- [ ] Collection book
- [ ] Event framework

---

## 🎨 Art Requirements

### Egg Images
- Basic Egg (grey/brown)
- Fantasy Egg (blue/purple)
- Mythic Egg (gold/red)

### Creature Evolution Stages
Each creature needs 4 stages:
1. Stage 1: Baby form (cute, small)
2. Stage 2: Teen form (developing features)
3. Stage 3: Adult form (full size, detailed)
4. Stage 4: Legendary form (glowing, particles, massive)

**Total:** 11 creatures × 4 stages = 44 unique models/images

---

## 📝 Notes

### Why Evolution > Merge?
- **Emotional connection:** Players bond with "their" dragon
- **Progression clarity:** Clear path from baby to god
- **Collection value:** Keeping lower stages for collection book
- **Storytelling:** Each pet has a journey

### Key Metrics to Track
- Day 1/7/30 retention
- Average hatches per session
- Evolution attempt success rate
- Revenue per daily active user (RPU)
- Trading volume (if implemented)

---

**Last Updated:** 2025-03-01  
**Next Review:** After Phase 1 implementation

# Damage roll and second Uncommons Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Every ranged gun hit rolls its damage by one layered, per-round rule, and every caliber
gets a second Uncommon round with text and an icon.

**Architecture:** A new `DamageRoll.reds` resolves roll values per ammo record (round, faction,
family, global flats; cached) and draws a factor; a `@wrapMethod` on
`DamageSystem.CalculateDamageVariants` applies it to ranged hits, finding the loaded round with the
lookup `ApplyAmmoOnHit` already uses (extracted to `AOData.LoadedAmmo`). The data layer learns
several rounds per tier, which this spec needs for two Uncommons and the next specs need for four
Rares and four Epics.

**Tech Stack:** redscript, TweakXL YAML, CET Lua harness (`tools/snippets`), Blender render
pipeline (`tools/render`), `tools/icons`.

**Spec:** `docs/superpowers/specs/2026-10-28-damage-roll-uncommons-design.md`

## Global Constraints

- Default roll 0.90 to 1.01; dud and hot off (chance 0, mult 1). Layers: round, faction, family,
  global; first found wins.
- Melee keeps vanilla's player-only roll; grenades and other non-gun hits stay unrolled;
  `projectionPipeline` hits are skipped.
- Uncommon rounds: one perk, one quirk, no armor penetration bonus.
- Common rounds carry no stat changes of their own.
- Item text voice: slang names with caliber prefix, short plain gun-counter text, effect line
  after a blank line; run anti-ai-writing on any changed text.
- Never run Windows tools under system wine; deploy only with the game stopped
  (`tools/linux/restart-game.sh --kill`, `tools/linux/deploy.sh`, `tools/linux/restart-game.sh`).
- Commits end with the session trailer.

## Review Focus

1. NPC hits on V with an unmanaged gun (turret, drone, mounted HMG): must roll on the global
   default, not crash on a missing caliber. Test in Task 5 (`roll.sh` case "turret-like":
   `DebugRollFor` on `Ammo.Standard` returns the global values).
2. A save loaded mid-fight with an NPC that rolled an Uncommon before the save: `GunAmmo` falls
   back to the Common round; the roll must still resolve (Common's values). Covered by Task 4's
   "unknown or Common ammo resolves to global" case.
3. Shotgun pellets: the roll runs per pellet hit, so Birdshot's spread of results is per pellet,
   not per shot. Expected and fine; Task 5 checks a shotgun hit rolls within range per pellet.
4. Uncommon share with one of two rounds missing for a caliber (12ga has Slugs and Birdshot, but
   a future caliber may have one): the tier's share goes whole to the rounds that exist. Test in
   Task 3 (`DebugTierAmmo` on a test caliber with one Uncommon).
5. The `CaliberForWeapon` cache must not keep a weapon's caliber across a TweakDB reload of the
   mod's flats: cache lives in the scriptable system (reset per game session). Test in Task 4
   (cached and uncached lookups agree for every gun in `records.lua`'s list).

---

### Task 1: Probes

**Files:**
- Create: `tools/snippets/calibers/rig.lua` (shared test rig)
- Modify: `docs/CATALOG.md` ("Mechanics checked for this lineup")

**Interfaces:**
- Produces: `rig.lua` defines globals `RIG.setup(gunRecord)` (equip and draw the gun on V, spawn
  `Character.AO_Test_Plain_Unity`, freeze it with `SetIndividualTimeDilation(..., 0.0001, ...)`,
  make it invulnerable with `GodModeSystem:AddGodMode(..., Invulnerable, ...)`, teleport V 5 m in
  front of it facing it; returns false on the first call while the NPC loads),
  `RIG.fireV(n)` (n `AIWeapon.Fire` shots from V at the NPC's chest, one per call),
  `RIG.fireNpc(n)` (the NPC's gun at V: unfreeze for the call or fire with the NPC as owner),
  `RIG.teardown()`. Hooks `CalculateDamageVariants` once (`ObserveBefore`/`ObserveAfter`) and
  records `{pre, post, instigatorIsPlayer, targetIsPlayer}` per hit in `RIG.hits`.
- Produces for later tasks, as rulings in the ledger: how the tooltip min/max are derived; the
  stamina-per-shot stat (or none); how smart reach is shortened (or none).

- [ ] **Step 1: Write `rig.lua` and confirm V's hits roll 0.90 to 1.10 (vanilla, RED baseline)**

Run: `tools/snippets/calibers/check.sh calibers/rig.lua` with `PRE="RIG_SELFTEST=true;"` (run twice:
the first spawns). The self-test fires 30 V shots and prints `PASS`/`FAIL` for "30 V hits",
"ratios within 0.90..1.10", "NPC hit on V seen and unrolled (ratio 1.0)".
Expected: 3 PASS. NPC hits on V are unrolled (vanilla).

- [ ] **Step 2: Tooltip probe.** Search `reference/catalog/stats.tsv` and TweakDB (CET:
`TweakDB:GetRecord`) for modifiers whose `statType` is `BaseStats.EffectiveDamagePerHitMin` /
`Max`; read them on the Lexington. Record which record holds the 0.9 and 1.1 factors.

- [ ] **Step 3: Stamina probe.** Search `StatType.hpp` (RED4ext SDK) and `reference/scripts` for
a per-shot stamina stat (vanilla `PowerMod2`'s "+stamina cost per bullet"). Read its TweakDB
modifier. Record the stat name or "none".

- [ ] **Step 4: Smart reach probe.** On a drawn Yukimura with 10mm Seekers, read
`MaximumRange`, `Range`, `EffectiveRange`, `SmartGunPlayerProjectileVelocity` and the projectile
record's lifetime; fire at the frozen NPC from 5 m and 40 m with each halved in turn (temporary
`StatsSystem` modifier) and log hits. Record which stat stops the rocket short, or "none" (then
Short-Fuse uses a shorter lock range: `SmartGunTargetableDistance`-style stat found here).

- [ ] **Step 5: Write the findings into `docs/CATALOG.md` and ledger them as `Task 1: Ruling:`
lines. Commit.**

```bash
git add tools/snippets/calibers/rig.lua docs/CATALOG.md
git commit -m "Probes: tooltip damage range, stamina per shot, smart reach; shared hit rig"
```

### Task 2: Second Uncommon rounds (records, effects, text)

**Files:**
- Modify: `src/tweaks/AmmoOverhaul/power_{9mm,45,12mm,556,762,127,12ga,4ga}.yaml`,
  `tech_{light,heavy}.yaml`, `smart_{10,20,25}.yaml`, `src/scripts/AmmoOverhaul/Localization.reds`
- Create: `tools/snippets/calibers/uncommon2.lua`, `tools/snippets/calibers/uncommon2.sh`
- Modify: `tools/snippets/calibers/records.lua` (ROUNDS gains the 13)

**Interfaces:**
- Produces records (ammo, selector, `UIIcon`) per caliber, ammo `$base` the caliber's Common ammo
  as the Mushrooms rounds do; `selectors`, `selectorAmmo`, `selectorTiers` gain the round at tier 1:

| Caliber | Ammo | Selector | Icon / atlas part |
|---|---|---|---|
| 9mm | `Ammo.AO_9mm_PlusP` | `Items.AO_Feed_9mm_PlusP` | `AO_9mm_PlusP` / `ao_9mm_plusp` |
| .45 | `Ammo.AO_45_PlusP` | `Items.AO_Feed_45_PlusP` | `AO_45_PlusP` |
| 12mm | `Ammo.AO_12mm_PlusP` | `Items.AO_Feed_12mm_PlusP` | `AO_12mm_PlusP` |
| 5.56 | `Ammo.AO_556_PlusP` | `Items.AO_Feed_556_PlusP` | `AO_556_PlusP` |
| 7.62 | `Ammo.AO_762_PlusP` | `Items.AO_Feed_762_PlusP` | `AO_762_PlusP` |
| 12.7 | `Ammo.AO_127_PlusP` | `Items.AO_Feed_127_PlusP` | `AO_127_PlusP` |
| 12ga | `Ammo.AO_12ga_Birdshot` | `Items.AO_Feed_12ga_Birdshot` | `AO_12ga_Birdshot` |
| 4ga | `Ammo.AO_4ga_Birdshot` | `Items.AO_Feed_4ga_Birdshot` | `AO_4ga_Birdshot` |
| 5mm rail | `Ammo.AO_TLight_Bricks` | `Items.AO_Feed_5mm_Bricks` | `AO_5mm_Bricks` |
| Heavy rail | `Ammo.AO_THeavy_Bricks` | `Items.AO_Feed_Heavy_Bricks` | `AO_Heavy_Bricks` |
| 10mm | `Ammo.AO_S10_ShortFuse` | `Items.AO_Feed_10mm_ShortFuse` | `AO_10mm_ShortFuse` |
| 20mm | `Ammo.AO_S20_ShortFuse` | `Items.AO_Feed_20mm_ShortFuse` | `AO_20mm_ShortFuse` |
| 25mm | `Ammo.AO_S25_ShortFuse` | `Items.AO_Feed_25mm_ShortFuse` | `AO_25mm_ShortFuse` |

  (Match existing prefixes per caliber where they differ, e.g. the 5mm rail's existing ammo IDs.)
- Text keys: names `AO-Ammo-<caliber>-PlusP` / `-Birdshot` / `-Bricks` / `-ShortFuse`; shared
  descriptions `AO-Ammo-PlusP-Desc`, `AO-Ammo-Birdshot-Desc`, `AO-Ammo-4ga-Birdshot-Desc`,
  `AO-Ammo-Bricks-Desc`, `AO-Ammo-ShortFuse-Desc`, with the spec's text and the effect line fixed
  by Task 1's rulings.

Selector effects (all `ConstantStatModifier` Multiplier unless noted):
- +P: `DamagePerHit` 1.1; `EffectiveRange` 1.15; `RecoilKickMin`, `RecoilKickMax` 1.25 (as 4ga
  Slugs' recoil); stamina stat from Task 1 (Additive, value as vanilla PowerMod2's) or none.
- Birdshot: `ProjectilesPerShot` via `CombinedStatModifier` Additive, refStat
  `ProjectilesPerShotBase`, refObject Root, value 1.0 (12ga, doubles) / 1.5 (4ga); the 8
  `Spread{,Ads}{Default,Max}{X,Y}` stats 1.6 (12ga) / 2.0 (4ga); `CanWeaponIgnoreArmor` Additive
  -0.5; `HitReactionFactor` 1.5.
- Bricks: `DamagePerHit` 1.15; `ChargeTime` 1.3.
- Short-Fuse: `DamagePerHit` 1.2; the reach stat from Task 1 at 0.5 (or the lock-range stat).

- [ ] **Step 1: Extend `records.lua` ROUNDS with the 13 rounds (name, the caliber's Common weight,
selector, the caliber's price multiplier). Write `uncommon2.lua`/`uncommon2.sh`** on the
`slugs.sh` pattern: for Lexington (9mm), Crusher (12ga), Carnage (4ga), Omaha (5mm rail),
Yukimura (10mm), draw, fit the Common selector, store stats, fit the second Uncommon, check
ratios: +P damage 1.1, `EffectiveRange` 1.15, `RecoilKickMax` 1.25; Birdshot
`ProjectilesPerShot` x2 (Crusher) and x2.5 (Carnage), `SpreadDefaultX` 1.6 / 2.0,
`DamagePerHit` x1.0 (the shot's total is unchanged); Bricks damage 1.15, `ChargeTime` 1.3;
Short-Fuse damage 1.2 and the reach stat 0.5.

- [ ] **Step 2: Run both. Expected: FAIL** (records.lua: 13 missing rounds; uncommon2.sh: no
selector).

- [ ] **Step 3: Add the records, effects and text.**

- [ ] **Step 4: Deploy (game stopped), restart, run.** Expected: records.lua all PASS,
uncommon2.sh all PASS, `slugs.sh` and `slice/uncommon.sh` still all PASS.

- [ ] **Step 5: Commit.**

### Task 3: Several rounds per tier

**Files:**
- Modify: `src/scripts/AmmoOverhaul/AOData.reds` (tier lookups),
  `src/scripts/AmmoOverhaul/AmmoDistribution.reds` (spread and pick),
  `src/scripts/AmmoOverhaul/NpcAmmo.reds` (`RollUncommon`),
  `src/scripts/AmmoOverhaul/AmmoFeedSystem.reds` (debug hook)
- Modify tests: `tools/snippets/calibers/distribution.lua`, `tools/snippets/slice/vendors.lua`,
  `tools/snippets/calibers/npc.lua` as needed

**Interfaces:**
- Produces: `AOData.SelectorsForTier(caliber: String, tier: Int32) -> array<TweakDBID>`,
  `AOData.AmmosForTier(caliber: String, tier: Int32) -> array<TweakDBID>`. `SelectorForTier` and
  `AmmoForTier` are removed; every caller uses the arrays.
- `AmmoDistribution.Spread`: a tier's weight is split evenly across `AmmosForTier`; `Pick`: weighted
  tier, then a uniform round within it. `TierWeights` counts a tier when it has any round.
- `NpcAmmo.RollUncommon`: on a hit, picks one of `SelectorsForTier(caliber, 1)` uniformly.
- `AmmoFeedSystem.DebugTierAmmo(caliber: String, tier: Int32) -> String`: the tier's ammo IDs,
  space-separated.

- [ ] **Step 1: Write the tests.** `distribution.lua`: for HandgunAmmo split of 10000, 9mm
Mushrooms and 9mm +P each get half of 9mm's Uncommon count (±1); same for 12ga Slugs/Birdshot
from ShotgunAmmo; `DebugPick` over 4000 draws returns both Uncommons of a caliber, each within
±25% of the other. `DebugTierAmmo("Power_9mm", 1)` lists both. `npc.lua`: with the roll forced on
(existing switch), 20 test Unity NPCs carry both .45 Uncommons between them.

- [ ] **Step 2: Run. Expected: FAIL** (second Uncommon gets nothing).

- [ ] **Step 3: Implement.**

- [ ] **Step 4: Run `distribution.lua`, `slice/vendors.lua`, `calibers/npc.sh`, `slice/npc.sh`.**
Expected: all PASS (update `vendors.lua` numbers only where the split changes them, as a ledgered
ruling).

- [ ] **Step 5: Commit.**

### Task 4: Roll values (resolver, draw, caches)

**Files:**
- Create: `src/scripts/AmmoOverhaul/DamageRoll.reds`
- Modify: `src/tweaks/AmmoOverhaul/core.yaml` (global flats), `src/tweaks/AmmoOverhaul/test.yaml`
  (test round), `src/scripts/AmmoOverhaul/AOData.reds` (`LoadedAmmo`, cached
  `CaliberForWeapon`), `src/scripts/AmmoOverhaul/AmmoFeedSystem.reds` (debug hooks; `ApplyAmmoOnHit`
  uses `LoadedAmmo`)
- Create: `tools/snippets/calibers/roll.lua`

**Interfaces:**
- Flats (float): global `AmmoOverhaul.roll.min` 0.90, `.max` 1.01, `.dudChance` 0, `.dudMult`
  1, `.hotChance` 0, `.hotMult` 1. Family `AmmoOverhaul.roll.<Power|Tech|Smart>.<value>`, faction
  `AmmoOverhaul.roll.<faction>.<value>` (faction from the string flat `<ammo>.aoFaction`), round
  `<ammo>.roll<Min|Max|DudChance|DudMult|HotChance|HotMult>`. Per damage type (Physical, Thermal,
  Electric, Chemical), the type is appended to the name: `<ammo>.rollMinThermal`,
  `AmmoOverhaul.roll.<layer>.minThermal`, `AmmoOverhaul.roll.minThermal`. A type falls back to the
  whole-hit value of the same layer chain when no layer sets it. Ledger this naming as a ruling
  (the spec wrote `rollMin.Thermal`).
- `public struct AORoll { min, max, dudChance, dudMult, hotChance, hotMult: Float }`
- `DamageRoll.Values(ammo: TweakDBID, family: String, damageType: String) -> AORoll` (damageType
  "" for the whole hit); unset is read as `TweakDBInterface.GetFloat(id, -1.0) < 0`.
- `DamageRoll.Draw(r: AORoll) -> Float`: dud if `RandF() < dudChance`, else hot if
  `RandF() < hotChance`, else `RandRangeF(min, max)`.
- Cache: `AmmoFeedSystem` holds the resolved `AORoll` per (ammo, type) and the caliber per weapon
  record; `AOData.CaliberForWeapon` reads through it (computing on a miss).
- `AOData.LoadedAmmo(instigator: ref<GameObject>, weapon: ref<WeaponObject>) -> TweakDBID`: the
  NPC's `NpcAmmo.GunAmmo`, V's `SelectedAmmo`, or the weapon record's ammo for unmanaged guns.
- Debug: `AmmoFeedSystem.DebugRollFor(ammo: String, damageType: String) -> String` ("min max dudC
  dudM hotC hotM") and `DebugRollDraws(ammo: String, damageType: String, n: Int32) -> String`
  ("min max mean duds hots").
- Test round in `test.yaml`: `Ammo.AO_Test_Roll` ($base `Ammo.AO_45_Ball`) with rollMin 0.5,
  rollMax 0.6, rollDudChance 0.2, rollDudMult 0.1, rollHotChance 0.2, rollHotMult 3.0,
  rollMinThermal 2.0, rollMaxThermal 2.0; `Ammo.AO_Test_RollFaction` with aoFaction "AOTest" and
  `AmmoOverhaul.roll.AOTest.min` 0.7 / `.max` 0.8; a test family layer is checked by setting
  `AmmoOverhaul.roll.Tech.min` in the test via `TweakDB:SetFlat` and restoring it.

- [ ] **Step 1: Write `roll.lua`:** `DebugRollFor("Ammo.AO_45_Ball","")` = 0.90 1.01 0 1 0 1;
for `Ammo.Standard` the same; `Ammo.AO_Test_Roll` = its values; its "Thermal" = 2.0 2.0 and its
"Physical" falls back to the round's 0.5 0.6; `AO_Test_RollFaction` = 0.7 0.8; Tech family set to
0.95 makes `Ammo.AO_TLight_Slug` 0.95 (cache cleared by the debug call's `fresh` path: give
`DebugRollFor` a third bool `fresh`); `DebugRollDraws("Ammo.AO_45_Ball","",5000)`: min ≥ 0.90,
max ≤ 1.01, mean 0.955±0.01, 0 duds, 0 hots; for `AO_Test_Roll`: duds 20%±3, hots 16%±3 (0.8 ×
0.2), others within 0.5..0.6. Cached `CaliberForWeapon` agrees with a fresh lookup for every gun
in `records.lua`'s GUNS.

- [ ] **Step 2: Run. Expected: FAIL** (no `DebugRollFor`).

- [ ] **Step 3: Implement.**

- [ ] **Step 4: Run `roll.lua`, `records.lua`, `slice/uncommon.sh`.** Expected: all PASS.

- [ ] **Step 5: Commit.**

### Task 5: The roll hook

**Files:**
- Modify: `src/scripts/AmmoOverhaul/Hooks.reds` (`@wrapMethod(DamageSystem)
  private final func CalculateDamageVariants(hitEvent: ref<gameHitEvent>) -> Void`)
- Create: `tools/snippets/calibers/roll.sh` (uses `rig.lua`)

**Interfaces:**
- Consumes: `DamageRoll.Values`, `DamageRoll.Draw`, `AOData.LoadedAmmo`, cache (Task 4).
- Behaviour: `projectionPipeline` → return. A gun hit (`attackData.GetWeapon()` defined and
  ranged, attack type not melee) → don't call `wrappedMethod`; draw the whole-hit factor and
  `MultAttackValue(factor)`, except damage types with their own values get
  `MultAttackValue(typeFactor, type)` instead. Anything else → `wrappedMethod(hitEvent)`.

- [ ] **Step 1: Write `roll.sh`:** with `rig.lua`: 30 V shots with .45 Ball on a Unity: every
ratio in 0.90..1.01 and at least one below 0.95; 20 NPC shots on V: ratios in 0.90..1.01 and not
all 1.0; with `Ammo.AO_Test_Roll` given as V's feed (test selector `Items.AO_Feed_Test_Roll` in
`test.yaml`), 30 shots show ratios in {≈0.1x, 0.5..0.6, ≈3.0x}; a Crusher shot's pellet hits each
roll within 0.90..1.01.

- [ ] **Step 2: Run. Expected: FAIL** (V ratios reach 1.10; NPC ratios all 1.0).

- [ ] **Step 3: Implement the wrap.**

- [ ] **Step 4: Run `roll.sh`, then `slice/uncommon.sh`, `calibers/slugs.sh`, `calibers/npc.sh`.**
Expected: all PASS.

- [ ] **Step 5: Commit.**

### Task 6: Tooltip damage range

**Files:** per Task 1's tooltip ruling: the TweakDB record holding vanilla's 0.9 / 1.1 factors
(override in `core.yaml` to 0.90 / 1.01) and, only if a round sets its own `rollMin/Max`, a
selector stat modifier. No shipped round sets one in this spec, so the test uses the test round.

- [ ] **Step 1: Test in `roll.lua`:** on the drawn Unity, `EffectiveDamagePerHitMin` /
`EffectiveDamagePerHit` = 0.90 ±0.005 and `Max` / it = 1.01 ±0.005.
- [ ] **Step 2: Run. Expected: FAIL** (Max ratio 1.10).
- [ ] **Step 3: Implement the override.**
- [ ] **Step 4: Run.** Expected: PASS.
- [ ] **Step 5: Commit.**

### Task 7: Icons

**Files:** `tools/render/render.py` (ROUNDS gains the 13; styles), `tools/icons/make_icons.py`
(NAMES gains the 13; `ATLAS = (1024, 2048)`, `COLS = 6`), YAML `UIIcon` entries (Task 2 named
them), `art/icons/*.png`, `src/archive/AmmoOverhaul.archive`, `tools/snippets/calibers/icons.lua`.

Looks: +P is the Ball round with a red headstamp ring and a red box stripe ("+P"); Birdshot a
12ga/4ga shell in light green with a star crimp ("BIRDSHOT"); Bricks the rail slug in dark
gunmetal, thicker, box stripe orange ("BRICKS"); Short-Fuse the seeker with a short motor and a
fatter warhead, box stripe red ("SHORT-FUSE").

- [ ] **Step 1: Extend `icons.lua` with the 13 rounds and selectors.** Run. Expected: FAIL.
- [ ] **Step 2: Render the 13** (`render.py --only ...`), show the user a contact sheet, adjust
until they approve.
- [ ] **Step 3: Build the atlas and archive** (`tools/icons/build.sh`), deploy, run `icons.lua`.
Expected: all PASS.
- [ ] **Step 4: Commit.**

### Task 8: Docs and full suite

**Files:** `docs/DESIGN.md` (damage roll section; Uncommon list; distribution with several rounds
per tier), `docs/CATALOG.md` ("Built" table gains the second Uncommons), `docs/TESTING.md` (new
checks: `rig.lua`, `roll.lua`, `roll.sh`, `uncommon2.sh`; hands-on: Birdshot vs a group,
Short-Fuse at range, a Very Hard fight).

- [ ] **Step 1: Update the docs.**
- [ ] **Step 2: Full suite** (the v1 suite script's list plus `roll.lua`, `roll.sh`,
`uncommon2.sh`, `lootdupe.lua`, `lootcap.lua`). Expected: all PASS except `slice/section.lua`
(needs a person).
- [ ] **Step 3: Commit.**

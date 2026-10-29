# Rare and Epic Rounds, Slice 1: Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the tier groundwork (prices, shares, sources, NPC rank rolls), a per-round hit-data mechanism applied to V and NPC hits alike, and the 91 Rare and Epic rounds of slice 1 with text and icons.

**Architecture:** Rounds are data: an ammo item and a selector part per round in the caliber's YAML, appended to the caliber's `selectors` / `selectorAmmo` / `selectorTiers` lists with tier 2 (Rare) or 3 (Epic). Handling stats are selector stat modifiers (as the Uncommons); everything else a round does on a hit is per-ammo flats (`aoEffects`, `aoShare`, `aoMachineBonus`, `aoNonlethal`, the existing `roll*`) read by the two hit hooks for every ranged gun hit. Distribution code is already tier-generic; it gets new caps and shares. The NPC roll grows from "Uncommon or not" to "Epic, else Rare, else Uncommon".

**Tech Stack:** redscript (`src/scripts/AmmoOverhaul`), TweakXL YAML (`src/tweaks/AmmoOverhaul`), CET Lua tests (`tools/snippets`), Blender icon renders (`tools/render`), atlas build (`tools/icons`).

**Spec:** `docs/superpowers/specs/2026-10-29-rare-epic-slice1-design.md` (roster, starting values, tiers, testing). Values in this plan come from it; where they differ, the spec wins.

## Global Constraints

- NPCs and V follow the same rules: hit data is applied in the hooks for every instigator. A handling stat that does nothing on NPC guns and can't be made up in the hooks moves its round to slice 2 (ledger it). Range and spread on NPC guns are a known gap (V-only).
- Common rounds stay vanilla. No automatic ammo switching.
- Rare: one small drawback. Epic: no drawback. Flechettes ignore no armor. No cover piercing, no area damage, no shock/EMP on Power rounds.
- Prices: Uncommon x2, Rare x4, Epic x8 of the caliber's Common round. Weight: the Common round's.
- Tier shares (Common, Uncommon, Rare, Epic): Power 0.80 0.14 0.05 0.01; Tech 0.70 0.22 0.07 0.01; Smart 0.86 0.10 0.035 0.005.
- Gun shops sell up to Rare; other vendors Common only; loot any tier.
- NPC factors (Uncommon / Rare / Epic; 0 = not allowed): Trash, Weak 0.5 / 0 / 0; Normal 1 / 0 / 0; Rare, Officer 1.5 / 1.5 / 0; Elite 2 / 2 / 2; Boss 2 / 3 / 4.
- Item text: slang names, plain gun-counter descriptions, no invented lore, effect lines after a blank line in the existing format ("+20% damage. Armor is 50% more effective against it.").
- One game instance: every compile, deploy and in-game run goes through `tools/linux/game-lock.sh`; never deploy while the game runs (`restart-game.sh --kill`, `deploy.sh`, `restart-game.sh`). Never use system wine; never grim; never move the mouse. Close the game when done.
- Testing: new mechanisms and major changes only (spec "Testing"); in-game checks batched into the sessions this plan names. Offline `tools/linux/check.sh` before every deploy.
- Commits end with `Claude-Session: https://claude.ai/code/session_01JwJvEAYGPc2WFWAem67MMf`.

## Review Focus

1. A Rare/Epic round with a status effect fired by an NPC at V: the effect lands on V the same as on an NPC (Task 2 live check, both directions).
2. A round's damage share or machine bonus fired by V must not stack with a stat on V's gun doing the same (Task 2: share and bonus come only from flats, never from selector stats; records check asserts no selector carries `ThermalDamage`/`ChemicalDamage`/`ElectricDamage`/`BonusDamageAgainstMechanicals` modifiers).
3. Old saves and the hidden selector sync: new selectors appear on the mod screen once their ammo is held, and nothing else changes for held Uncommons (Task 1: sync count unchanged in `sync.sh`'s bounded-sync check after the tier lists grow).
4. Vendors restocking with the new cap: a gun shop never lists an Epic (Task 1 static check over `DebugSpread` with the gun-shop cap).
5. The 4ga Slug knockdown keeps working after the on-hit data moves to `aoEffects` (Task 2 static check).

---

### Task 1: Tier groundwork

**Files:**
- Modify: `src/tweaks/AmmoOverhaul/core.yaml` (shares, NPC factors, price records)
- Modify: every caliber YAML's Uncommon ammo records (append the Uncommon price multiplier)
- Modify: `src/scripts/AmmoOverhaul/AOData.reds`, `NpcAmmo.reds`, `Vendors.reds`, `LootConvert.reds`
- Test: `tools/snippets/calibers/tiers.lua` (new, static), `tools/snippets/calibers/distribution.lua`

**Interfaces:**
- Produces: price records `Price.AO_Uncommon` (Multiplier 2), `Price.AO_Rare` (4), `Price.AO_Epic` (8), appended to an ammo record's `buyPrice` and `sellPrice`.
- Produces: `AOData.NpcTierFactor(rarity: String, tier: Int32) -> Float` (tier 1 reads `AmmoOverhaul.npcUncommonFactor.<rarity>`, 2 `npcRareFactor`, 3 `npcEpicFactor`; missing = 0). `AOData.NpcUncommonFactor` stays (tests set its flats).
- Produces: `NpcAmmo.RollRound(npc: ref<NPCPuppet>, gun: ItemID) -> Int32` replacing `RollUncommon`: tries tier 3, then 2, then 1, each with chance `min(1, TierShare(family, t) * NpcTierFactor(rarity, t))`, picking one of that tier's selectors at random (`NpcAmmo.PickTier(caliber, tier)` replacing `PickUncommon`); returns the tier given, 0 for none. The rest of RollUncommon's body (feed-slot check, stat copy via `ToModifier`, `aoUncommonGuns`/`aoUncommonAmmo` bookkeeping, log) is unchanged.
- Produces: `AmmoFeedSystem.DebugTierPick(caliber: String, rarity: String, n: Int32) -> String` ("tier=count;..." over n rolls of the chance logic without a puppet).
- Vendor cap: gun shop maxTier 2 (`Vendors.reds:33`); loot maxTier 3 (`LootConvert.reds:31`).

- [ ] **Step 1: Write `tiers.lua`** (static, `check`/`report` from `slice/common.lua`):
  - shares: each family's `AmmoOverhaul.shares.<family>` has 4 entries summing to 1 (±0.001) and equals the Global Constraints values;
  - price: `RPGManager.CalculateBuyPrice(p, id, 1.0)` of every Uncommon ammo = 2 x its caliber's Common (`AOData` default ammo), within 1 for rounding;
  - vendor cap: `sys:DebugSpread("Ammo.HandgunAmmo", 100000, 2)` lists no tier-3 ammo and (once Task 3 lands) some tier-2 ammo; `DebugSpread(..., 0)` only Common;
  - NPC factors: `DebugTierPick("Power_9mm", r, 20000)` gives 0 tier-2/3 for Trash, Weak, Normal; 0 tier-3 for Rare and Officer; tier-3 > 0 for Elite and Boss once Epic rounds exist (Task 4); Boss tier-3 count ≈ 2x Elite's (±30%).
- [ ] **Step 2: Implement** the flats, price records, `NpcTierFactor`, `RollRound`/`PickTier`, caps, `DebugTierPick`. Update `distribution.lua` where it hard-codes two tiers. Offline: `tools/linux/game-lock.sh tools/linux/check.sh` → no errors.
- [ ] **Step 3: Commit** ("Tiers: Rare and Epic shares, prices, vendor/loot caps, NPC rank rolls"). The in-game run of `tiers.lua` happens in Session A (Task 2).

### Task 2: Per-round hit data

**Files:**
- Modify: `src/scripts/AmmoOverhaul/AOData.reds` (readers), `AmmoFeedSystem.reds` (`ApplyAmmoOnHit`, `RollGunHit`)
- Modify: `src/tweaks/AmmoOverhaul/power_4ga.yaml` (Slug knockdown moves to `aoEffects`; `AmmoOverhaul.ammoEffects` and `AOData.OnHitEffect` removed)
- Modify: `src/tweaks/AmmoOverhaul/test.yaml` (test round `Ammo.AO_Test_HitData` with selector `Items.AO_Feed_Test_HitData` on 9mm, like `AO_Test_Roll`)
- Test: `tools/snippets/calibers/hitdata.lua` (static), `tools/snippets/calibers/hitdata.sh` (live, rig)

**Interfaces (flats on the ammo record; all optional):**
- `<ammo>.aoEffects: [TweakDBID]` status effects; `<ammo>.aoEffectChances: [Float]` same length (missing entry = 1.0).
- `<ammo>.aoShareType: String` one of `Thermal`, `Chemical`, `Electric`; `<ammo>.aoShare: Float` 0..1, the fraction of the hit's Physical damage moved to that type.
- `<ammo>.aoMachineBonus: Float` (default 1.0) damage factor when the target is a machine.
- `<ammo>.aoNonlethal: Bool` (default false).
- Readers: `AOData.HitEffects(ammo: TweakDBID, out chances: array<Float>) -> array<TweakDBID>`, `AOData.DamageShare(ammo: TweakDBID, out damageType: gamedataDamageType) -> Float`, `AOData.MachineBonus(ammo: TweakDBID) -> Float`, `AOData.IsNonlethal(ammo: TweakDBID) -> Bool`, `AOData.IsMachine(target: ref<GameObject>) -> Bool` (a drone or mechanical puppet, or a vehicle).
- Application, for every ranged gun hit whatever the instigator: `ApplyAmmoOnHit` adds each effect with its chance and, if nonlethal, `attackData.AddFlag(hitFlag.Nonlethal, n"AmmoOverhaul")`; `RollGunHit` moves the share of Physical to the share type and multiplies every type by the machine bonus when `AOData.IsMachine(hitEvent.target)`. These are never selector stats (Review Focus 2).
- Test round values: effects `[BaseStatusEffect.Burning]` chance `[1.0]`, share Thermal 0.5, machine bonus 2.0, nonlethal true.

- [ ] **Step 1: Write `hitdata.lua`** (static): the readers return the test round's values; `Ammo.AO_4ga_Slug` gives `[BaseStatusEffect.Knockdown]` chance 1.0 (Review Focus 5); an unmanaged ammo gives no effects, share 0, bonus 1.0, not nonlethal.
- [ ] **Step 2: Write `hitdata.sh`** (live, rig.lua; V fires the 9mm test round at the rig NPC, then a test ganger carrying it fires at V):
  - the target has `Burning` after a hit, both directions;
  - per hit, Thermal ≈ Physical (share 0.5) in the logged per-type values, both directions;
  - V's hit on a drone (spawn `Character.*` drone the rig can hold; record its ID in the script) is ≈ 2x V's hit on the human, after dividing out the roll;
  - an NPC killed by the test round is unconscious, not dead (`IsDefeated`/`IsUnconscious` style check on the target puppet).
- [ ] **Step 3: Implement** readers and hook changes; migrate the 4ga Slug; add the test round. Offline compile clean.
- [ ] **Step 4: Session A** (one locked session: kill, deploy, restart): run `check.sh calibers/tiers.lua calibers/hitdata.lua`, then `hitdata.sh`, then `slice/npcdrop.sh` and `calibers/sync.sh` (regression for Review Focus 3/5 neighbours). Expected: all PASS except the tier checks that wait for Tasks 3-4 (they say so in their text). Fix and rerun failures inside the session.
- [ ] **Step 5: Commit** ("Hit data: per-round effects, damage share, machine bonus, non-lethal for every shooter").

### Task 3: Power Rares

**Files:** `src/tweaks/AmmoOverhaul/power_{9mm,45,12mm,556,762,127}.yaml`, `src/scripts/AmmoOverhaul/Localization.reds`, `tools/render/render.py` (ROUNDS and LOOK entries only)

**Interfaces:**
- Consumes: Task 1 price records (`Price.AO_Rare`), Task 2 flats.
- Produces, per caliber in the spec roster: ammo `Ammo.AO_<cal>_<Load>` (base the caliber's Common ammo record, `quality: Quality.Rare`, weight as the Common round, `buyPrice`/`sellPrice` + `Price.AO_Rare`), selector `Items.AO_Feed_<cal>_<Load>` (as that caliber's Uncommon selector, `quality: Quality.Rare`, tags incl. `HideInBackpackUI`), appended to the caliber's three selector lists with tier 2, text keys `AO-Ammo-<cal>-<Load>` (+ a shared `AO-Ammo-<Load>-Desc` where every caliber's text is the same, as Mushrooms), icon `UIIcon.AO_<cal>_<Load>` / art name `<cal>-<load>` (lowercase). `<cal>` is the tag the caliber already uses in its IDs (`9mm`, `45`, `12mm`, `556`, `762`, `127`). Loads: `SteelCore`, `Incendiary`, `Subsonic`, `Bouncers`, `Rubber`, `Hardcast`, `BallisticTip`.
- Values: spec "Starting values, Power, Rare". Armor pen through `CanWeaponIgnoreArmor` as the Uncommons do; damage factor as a `DamagePerHit` Multiplier; Incendiary's burn and Thermal share, Rubber's non-lethal and flinch effect through Task 2 flats; Subsonic through `WeaponNoise` (Multiplier, quieter) and `CanSilentKill` 1; Bouncers through `RicochetChance` 0.3 / `RicochetCount` 1; Hardcast's stagger as an `aoEffects` entry (`BaseStatusEffect.HitReactionStagger` or the stagger effect the game uses, chance 0.25); Ballistic tip through `EffectiveRange` Multiplier 1.4.

- [ ] **Step 1:** Add the records, list entries, text, and render entries (one LOOK per load, same box in every caliber). Text per Global Constraints.
- [ ] **Step 2:** Offline compile clean (`Localization.reds`). YAML is checked in game in Session B.
- [ ] **Step 3: Commit** ("Power Rares: Steel-core AP, Incendiary, Subsonic, Bouncers, Rubber, Hardcast, Ballistic tip").

### Task 4: Power Epics

Same shape as Task 3 with `Quality.Epic`, `Price.AO_Epic`, tier 3. Loads: `Penetrator` (9mm, .45, 5.56 only: ignores 60% of armor, nothing else), `Match` (roll flats `rollMin` 0.98, `rollMax` 1.06, `rollDudChance` 0, `rollHotChance` 0; spread and sway Multipliers 0.7), `Toxin` (poison 0.25, Chemical share 0.3), `Shredders` (bleed 0.3, `HitDismembermentFactor` x2), `HEI` (12.7 only: machine bonus 1.5, burn 0.2, no area). Roster per spec. Commit ("Power Epics").

### Task 5: Shotgun Rares and Epics

Files `power_12ga.yaml`, `power_4ga.yaml`, `Localization.reds`, `render.py`. Loads: 12ga Rare `Flechette`, `Beanbag`, `DragonLight`; 12ga Epic `Dragon`, `Frag12`, `FlechetteLong`; 4ga Rare `Flare`, `Riot`, `Flechette`; 4ga Epic `Dragon`, `Thermite`. Values per spec "Shotguns"; one-projectile rounds reuse the Slugs' pellet modifiers (combined -1 x base plus constant +1) so the NPC pellet ratio stays right; Flechettes carry no armor pen; burn effects `BaseStatusEffect.Burning` (light) and `MediumBurning` (Epic Dragon's breath, Thermite); Flare's blind `BaseStatusEffect.ShortBlind`; knockdown `BaseStatusEffect.Knockdown`. Commit ("Shotgun Rares and Epics").

### Task 6: Tech Rares and Epics

Files `tech_light.yaml`, `tech_heavy.yaml`, `Localization.reds`, `render.py`. Loads: Rare `Ferro` (`RicochetChance` 0.4, `RicochetCount` 2, damage 0.9), `SplitSlug` (3 projectiles via the pellet pattern, wider spread, `TechPierceEnabled` 0), `Feedback` (`BulletMagnetismDefaultAngle` +2, damage 0.9); Epic `DUPen` (lower `TechPierceChargeLevel`, `TechPierceDamageFactor` x1.5, ignores 50% of armor), `ToxicScatter` (5 projectiles, poison 0.25), `Superconductor` (`FullAutoOnFullCharge` 1), `EMPCap` (EMP effect chance 0.3, Electric share 0.3). Commit ("Tech Rares and Epics").

### Task 7: Smart Rares and Epics

Files `smart_{10,20,25}.yaml`, `Localization.reds`, `render.py`. Loads: Rare `EMP`, `Incendiary`, `Chem` (effect chance 0.25, share 0.3 of Electric / Thermal / Chemical, damage 0.9), `Flash` (blind 0.3, damage 0.8); Epic `Hunter` (`SmartGunAdsMaxLockedTargets` +2, `BonusSmartGunTimeToLock` for x0.5 lock time, `SmartGunHitProbability` +0.2, `SmartGunPlayerProjectileVelocity` x1.3), `HackCarrier` (`CyberwareMalfunction` 0.15 and `WeaponMalfunction` 0.15), `ShapedCharge` (ignores 50% of armor, machine bonus 1.5). Commit ("Smart Rares and Epics").

### Task 8: Records check and handling-stat audit (Session B)

**Files:**
- Modify: `tools/snippets/calibers/records.lua` (generic checks extended to tiers 2 and 3), `tools/snippets/calibers/parity-stats.lua` + `parity.sh` (new stat cases)
- Modify: `docs/DESIGN.md` (stat audit rows, hit data section), `docs/CATALOG.md` (Built section), `docs/TESTING.md`

- [ ] **Step 1:** `records.lua`, for every tier-2/3 selector: ammo exists with the tier's quality, price ratio 4 / 8 (±1), weight equals the Common round's, text keys resolve (not the key string), icon part exists, selector tagged `HideInBackpackUI` and `AO_AmmoSelector`, no selector carries a damage-type or mechanical-bonus stat modifier (Review Focus 2), every `aoEffects` entry is a valid status effect record and `aoEffectChances` matches its length, `aoShareType` is one of the three.
- [ ] **Step 2:** `parity-stats.lua` cases for each stat type new in Tasks 3-7 (`RicochetChance`, `RicochetCount`, `WeaponNoise`, `CanSilentKill`, `HitDismembermentFactor`, `BulletMagnetismDefaultAngle`, `TechPierceChargeLevel`, `TechPierceDamageFactor`, `FullAutoOnFullCharge`, the smart lock and velocity stats), on an NPC gun in hand with the round forced (raise that tier's NPC factor flats to 10 for the run, as `parity.sh` does for Uncommon).
- [ ] **Step 3: Session B** (one locked session): kill, deploy, restart; `check.sh calibers/records.lua calibers/tiers.lua calibers/hitdata.lua calibers/vanilla.lua`; `parity.sh`. Fix YAML errors found by the load and rerun. Each audit result goes in DESIGN's stat audit as works / irrelevant (reason) / fails. A failing stat with no hook fix: move its rounds to slice 2 (remove them from the lists; ledger a ruling).
- [ ] **Step 4:** Docs: DESIGN (hit data, tiers, audit), CATALOG (Built), TESTING (new scripts). Commit ("Rare/Epic records check, NPC stat audit, docs").

### Task 9: Icons (Session C)

**Files:** `tools/icons/make_icons.py` (NAMES, ATLAS (2048, 2048), COLS 12), `art/icons/*.png`, `art/build/*`, `src/archive/AmmoOverhaul.archive`, the `UIIcon.AO_*` records in the caliber YAMLs.

- [ ] **Step 1:** Render the new rounds (`python3 tools/render/render.py --only <names>`), add them to NAMES, grow the atlas, `tools/icons/build.sh`.
- [ ] **Step 2:** `python3 tools/icons/check_parts.py` → every `UIIcon` part has a cell. Session C: deploy, restart, `check.sh calibers/icons.lua`; one `game-shot.sh` of a gun's mod screen with a Rare and an Epic held, read to confirm the icons draw.
- [ ] **Step 3: Commit** ("Rare and Epic icons"). Close the game.

### Task 10: User playtest hand-off

- [ ] Give the user a short checklist (one per mechanism: burn from an NPC, non-lethal, a machine bonus on a drone, a Superconductor full-auto, a Hunter lock, gun-shop stock with Rares and no Epics) and the deferred list. The full suite runs before a release, not here.

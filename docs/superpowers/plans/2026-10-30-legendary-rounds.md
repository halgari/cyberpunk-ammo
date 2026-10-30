# Legendary rounds, first set (13 rounds) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the Legendary tier and 13 Legendary rounds: Gatecrasher (12.7, 7.62), Cook-off
(9mm, .45, 12mm, 5.56, 7.62), Kebab (5mm, Heavy), Lockout (10mm, 20mm, 25mm) and Heartseeker
(12ga). Bouncing Betty (4ga) waits for its probe. The mod goes from 135 rounds to 148.

**Architecture:** The rounds come from `tools/rounds/rounds.py` as a new tier 4. Gatecrasher,
Kebab and Lockout are stats and hit data only. Cook-off is a new hit flat (`aoCookOff`) read by
the hit code: a kill marks the body and `NPCPuppet.OnDeath` sets off `Attacks.Explosion` there; a
hit on V sets off V's charged grenade on V. Heartseeker is a new hit flat (`aoRangedAttack`): the
player's shot (`WeaponTransition.GetDesiredAttackRecord`) and the NPC's shot
(`AIWeapon.SetAttackBasedOnTimeDilation`) take the smart package instead of the gun's, the gun
gets the smart lock stats from the selector, and the dynamic tags `Smart` and `SmartWeapon` while
the round is fitted. NPC rank rolls, container rolls and the quarter-size stack are new tier code.

**Tech Stack:** TweakXL yaml, redscript (`check.sh`), Python generators, Blender renders, CET Lua.

**Spec:** `docs/superpowers/specs/2026-10-29-legendary-rounds-design.md`

## Global Constraints

- One game instance; all game work through `tools/linux/game-lock.sh`. Order: `restart-game.sh
  --kill`, `deploy.sh`, `restart-game.sh`. Shut the game down when done.
- GE-Proton via `tools/linux/*.sh` only; never system wine, grim or ydotool. `game-shot.sh` only
  while the user isn't playing.
- NPCs and V follow the same rules. Common rounds stay vanilla. No automatic ammo switching.
- No crafting of Legendary rounds: no recipe, no recipe item. Disassembly as the other tiers.
- Price x16 of the Common round. Never sold by any vendor.
- NPC roll: Elite 3%, Boss and MaxTac 10%, before the Epic roll; other ranks never.
- Containers that already hold Epic rounds: 0.2% per ammo stack to be the caliber's Legendary.
- A Legendary stack is a quarter of the Epic stack it replaces, rounded up.
- Item text: slang names, plain gun-counter text, effect lines after a blank line.
- Generated blocks are never edited by hand.
- Commits end with `Claude-Session: https://claude.ai/code/session_01JwJvEAYGPc2WFWAem67MMf`.
  Branch `legendary`; no push, merge or release.

## Review Focus

- **Cook-off chains.** A Cook-off blast that kills a second NPC must not set off another blast
  (the blast is not a ranged hit). Task 2's check kills with a blast nearby.
- **Cook-off on V with no grenade or no charge.** Nothing happens and nothing errors. Task 2.
- **Heartseeker on a gun without the round.** Swapping the round out takes the smart tags and
  the smart attack off the gun; a plain Buckshot shot afterwards is a normal hitscan shot. Task 3.
- **Legendary never at a vendor or as a recipe.** `tiers.lua` and `crafting.lua` cover it. Task 1.
- **Shares unchanged.** The four existing shares stay as they are; the fifth is 0. Task 1.

---

### Task 1: The tier and the records

**Files:** `tools/rounds/rounds.py`, `tools/crafting/crafting.py` (+ test), `core.yaml`
(fifth share, Legendary NPC chances, container chance, `AmmoOverhaul.LockoutJam`),
`NpcAmmo.reds` (`RollTier`, loot quarter), `LootConvert.reds`, `AOData.reds`
(`LegendaryChance`, `CaliberForAmmo`), regenerated caliber yaml, localization, art json, refs;
checks `records.lua`, `tiers.lua`.

**Interfaces:**
- Produces records `Ammo.AO_<ammo>_<Load>` / `Items.AO_Feed_<sel>_<Load>` for loads
  `Gatecrasher`, `CookOff`, `Kebab`, `Lockout`, `Heartseeker`, tier 4, quality Legendary.
- Produces hit flats `<ammo>.aoCookOff: true` and `<ammo>.aoRangedAttack: "Attacks.SmartBulletHighPackage"`.
- Produces `AOData.CookOff(ammo) -> Bool`, `AOData.RangedAttack(ammo) -> TweakDBID`,
  `AOData.LegendaryChance(rarity) -> Float`, `AOData.CaliberForAmmo(ammo) -> String`.

- [ ] Step 1: extend `records.lua` with a Legendary block: 13 tier-4 rounds; quality Legendary;
  price x16 of Common; no `aoRecipe`; Gatecrasher `CanWeaponIgnoreArmor` 1 and
  `DamageFalloffDisabled` 1; Kebab `TechPierceDamageFactor` x0; Lockout effect
  `AmmoOverhaul.LockoutJam` chance 1 with 4 s duration; Heartseeker `aoRangedAttack`,
  `SmartGunHitProbability` 1, one projectile. Extend `tiers.lua`: five shares with the fifth 0,
  Legendary prices x16, vendors never list tier 4, NPC roll gives tier 4 only to Elite (3%), Boss
  and MaxTac (10%). Run them on the current deploy: FAIL.
- [ ] Step 2: generator: `LEGENDARY = 4`, `PRICE[4] = 8`, quality, the five kinds, hit flats
  `cookoff` and `ranged_attack`. Crafting: tier 4 gets scrap flats and no recipe or cost.
- [ ] Step 3: script: `RollTier` rolls tier 4 first with `LegendaryChance`; `LootConvert` rolls
  0.2% per stack in a container with an Epic; Legendary stacks quartered (container and NPC loot).
- [ ] Step 4: run generators, `pytest tools/crafting`, `check.sh`; deploy; checks pass.
- [ ] Step 5: commit `feat: Legendary tier and the first 13 Legendary rounds (records)`.

### Task 2: Cook-off

**Files:** `AmmoFeedSystem.reds` (`ApplyAmmoOnHit` marks; new `CookOff` class in
`CookOff.reds`), `NpcAmmo.reds` `OnDeath` hook; live check `tools/snippets/calibers/legendary.sh`.

- [ ] Step 1: write the Cook-off part of `legendary.sh`: V kills a rig NPC with 5.56 Cook-off: a
  blast (a second NPC next to it loses health) and no second blast from that kill; an NPC's
  Cook-off hit on V with a frag and a full charge takes one charge off and hurts V; with the charge
  gone the next hit does nothing. Run: FAIL.
- [ ] Step 2: implement: `ApplyAmmoOnHit` marks the NPC target (`aoCookOffAt`, `aoCookOffBy`);
  `OnDeath` within 0.5 s of the mark queues the blast (next frame, `DelaySystem`). A hit on V
  queues V's grenade (`EquipmentSystem.GetData(V).GetActiveGadget()`, its record's `attack`)
  plus `Attacks.Explosion` when the `GrenadesCharges` pool holds a charge, and takes the charge.
- [ ] Step 3: run: PASS. Commit `feat: Cook-off blasts`.

### Task 3: Heartseeker

**Files:** `Heartseeker.reds` (attack overrides, dynamic tags), `legendary.sh`.

- [ ] Step 1: write the Heartseeker part: a Tactician with Heartseeker fires a smart projectile
  that hits a rig NPC off the crosshair line (homes); the gun has the tags while fitted and not
  after a swap to Buckshot; damage on an unarmored NPC recorded. Run: FAIL.
- [ ] Step 2: implement the overrides and tags; if the lock needs `HasSmartLink` on V, add it
  while the round is fitted and drawn (and take it off).
- [ ] Step 3: run: PASS. If homing can't be made per round, stop the round and write down why.
  Commit `feat: Heartseeker smart slug`.

### Task 4: Kebab, Lockout, Gatecrasher live checks

- [ ] `legendary.sh`: Lockout hit jams the rig NPC's gun (`WeaponMalfunction`-tagged effect on it)
  and an NPC's Lockout hit jams V's; Kebab charged shot through two NPCs in line, recording each
  one's loss; Gatecrasher stats on an NPC gun rolled to it. PASS; commit.

### Task 5: Icons and the Legendary look

- [ ] Legendary look (orange/gold box) in the generator; render the 13 icons with
  `tools/render/render.py --only ...` small and `nice -n 19`; contact sheet in the scratchpad;
  `tools/icons/build.sh`; `check_parts.py` 148 parts. Commit.

### Task 6: Docs

- [ ] 135 -> 148 in README, NEXUS, CATALOG, DESIGN; Legendary rounds listed, Bouncing Betty
  "coming"; CHANGELOG unreleased entry; TESTING playtest steps for the five kinds. Banner grid
  for 148. Commit.

### Final review

Package against `ping-penetrator`; one fresh review on the most capable model; fix Critical and
Important with tests; ledger minors.

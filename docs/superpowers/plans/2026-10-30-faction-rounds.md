# Faction rounds, NPC side: implementation plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 26 faction rounds (9 kinds) that a Maelstrom, Scavenger or Arasaka NPC can roll, fire and drop.

**Architecture:** The generator gains tiers 5 (faction Rare), 6 (faction Epic), 7 (faction Common) and a
`faction=` field. General lists match tiers exactly, so these stay out of them. `NpcAmmo.RollRound` gains a
faction roll between Legendary and the general tiers. New per-shot and on-kill effects live in a new
`FactionRounds.reds`.

**Tech Stack:** Python generators, TweakXL YAML, redscript, CET Lua live checks.

**Spec:** `docs/superpowers/specs/2026-10-30-faction-rounds-design.md` (read Decisions at the end)

## Global Constraints

- Faction rounds ship after 0.5.0: no release files, no release branch, no push.
- Turf gun shops are out of this pass: the shop list isn't approved.
- No effect may edit a shared weapon record at runtime or change other guns or NPCs as a side effect
  (the lesson from Heartseeker). Stats go on the one gun, as every other round. Kansatsu must not use
  the evolution switch. A round that needs one stops and is flagged.
- Effects use engine behaviour: stats, status effects, the hit code. No scripted fakes.
- NPCs and V follow the same rules. Parts-pullers is the one exception, user-approved.
- Item text: slang names, plain gun-counter text, no invented lore, effect lines after a blank line.
- Names carry [Mael], [Scav], [Ara]. No crafting, no containers, no recipes.
- Windows tools run through `tools/linux/*.sh` only. No game use until the release suite is finished;
  check `tools/linux/game-lock.sh` first. Icon renders wait for that too.
- `reference` and `tools/wolvenkit*` show as untracked symlinks in this worktree: add files by path.

## Review Focus

- A faction round on a gun V loots: V can select it and it behaves as it did on the NPC (`records.lua` lists
  the round; `faction.sh` fits one).
- An NPC of another faction, or none, never rolls a faction round (`DebugFactionPick`, Task 3).
- A Parts-pullers kill on an NPC with no ammo noted (melee, or dry) still leaves the parts (Task 3,
  `EvaluateLootQuality` and the delayed top-up both look at the mark).
- A knockout, or a later hit by something else, leaves no parts (the mark clears on any other hit, as Cook-off).
- A full-auto Redliner rolls the jam on each shot, and a jam clears after 3 s (`faction.sh`).

---

### Task 1: Generator and records

**Files:** `tools/rounds/rounds.py`, `tools/crafting/crafting.py`, `tools/crafting/test_crafting.py`,
create `tools/rounds/test_rounds.py`, `src/tweaks/AmmoOverhaul/core.yaml`, generated files.

**Produces:** tiers 5, 6, 7 in `selectorTiers`; flats `<ammo>.aoFaction`, `<ammo>.aoSelfJam` (Float),
`<ammo>.aoPartsPuller` (Bool); `AmmoOverhaul.factionOf.*`, `npcFactionChance.*`, `npcFactionEpicChance.*`,
`roll.Scavengers.*`, `partsPullerGive`; status effect `AmmoOverhaul.RedlinerJam`.

- [ ] Write `test_rounds.py`: 26 faction rounds, per-kind calibers and tiers from the spec; every name ends in
      its tag; Reloads price 0.25 (half Common); no kind uses `ranged_attack`. Run: fails.
- [ ] Extend `test_crafting.py`: tiers 5, 6, 7 keep scrap flats, write `aoRecipe: ""`, make no recipe and no cost
      record. Run: fails.
- [ ] Add the tiers, `faction=` and the nine kinds to `rounds.py`; `LEGENDARY` skip in `crafting.py` becomes
      `NO_RECIPE`; add the flats to `core.yaml`. Rolls for `roll.Scavengers`: min 0.70, max 1.15, dud 8% x0.25,
      hot 5% x1.5. Kata roll 0.99 to 1.01.
- [ ] Run both generators and the Python tests: pass. Commit.

### Task 2: Offline checks of the records

**Files:** `tools/snippets/calibers/records.lua`, `tiers.lua`, `crafting.lua`.

- [ ] `records.lua`: QUAL and PRICE gain 5, 6, 7 (7 is Common, x0.5); tier 7 is checked though it is below Rare
      quality; faction rounds have `aoFaction`.
- [ ] `crafting.lua`: the Legendary branch covers tiers 4 and up.
- [ ] `tiers.lua`: tiers 5 to 7 aren't in a general list, which the exact-tier byTier table already gives; assert it.
- [ ] Commit with Task 3 if nothing can run yet (these need the game).

### Task 3: NPC roll, self-jam, Parts-pullers

**Files:** create `src/scripts/AmmoOverhaul/FactionRounds.reds`; modify `AOData.reds`, `NpcAmmo.reds`,
`MuleKick.reds`, `AmmoFeedSystem.reds`.

**Produces:**
- `AOData.FactionOf(npc: ref<NPCPuppet>) -> String`, `AOData.FactionChance(rarity: String, epic: Bool) -> Float`,
  `AOData.SelectorsForFaction(caliber, faction, tier) -> array<TweakDBID>`, `AOData.SelfJam(ammo) -> Float`,
  `AOData.PartsPuller(ammo) -> Bool`.
- `NpcAmmo.RollFaction(caliber, rarity, faction) -> TweakDBID`, `NpcAmmo.RollSelector(caliber, rarity, faction) -> TweakDBID`.
- `FactionRounds.OnShot(shooter, ammo)`, `.MarkParts(target, ammo)`, `.ClearParts(target)`, `.OnDeath(npc)`, `.GiveParts(npc)`.
- `AmmoFeedSystem.DebugFactionPick(caliber, rarity, faction, n) -> String`.

- [ ] Implement. Order in `RollSelector`: Legendary, faction (Epic chance, then Rare; Rare picks from tiers 5
      and 7 alike), general tiers.
- [ ] Self-jam: V from `ShootEvents.OnEnter`, NPCs from `NpcAmmo.TakeShot` after the rounds are taken.
- [ ] Parts: mark on a hit by V, cleared by any other hit, read at death within 0.5 s, given with the loot.
- [ ] Run `tools/linux/check.sh`: no build failures. Commit.

### Task 4: Live checks, written now, run when the game is free

**Files:** create `tools/snippets/calibers/faction.sh`.

- [ ] One check per mechanism from the spec's Testing section, modelled on `legendary.sh`. Commit.
- [ ] Probe Kansatsu's instant lock; on failure keep the fallback already built (lock time x0.5, tag). No
      evolution switch.
- [ ] Check the affiliation spelling and run `faction.sh`.

### Task 5: Art

- [ ] Arasaka hard case first, Maelstrom and Scav prototypes, contact sheet to the user before all 26.
- [ ] Banner grid, docs, catalog, Nexus page text. CHANGELOG under Unreleased only.

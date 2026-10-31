# Quickhack Rounds Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 117 smart rounds (39 kinds on 10mm, 20mm and 25mm) carrying 11 quickhacks, crafted from the matching quickhack, sold in shops and carried by NPCs.

**Architecture:** Rounds are generated from a `HACKS` table in `tools/rounds/rounds.py` with own tier codes 10 to 13. Every hack effect goes through the existing rank path in `FactionRounds`, extended with a "Never" tough rule and a blast. New `HackRounds.reds` holds the NPC roll, netrunner drop and shop stock. `tools/crafting/crafting.py` writes a per-round cost with the quickhack as an ingredient.

**Tech Stack:** Python generator with pytest, redscript, TweakXL yaml, CET Lua live checks, Blender and PIL.

**Spec:** `docs/superpowers/specs/2026-10-31-quickhack-rounds-design.md`

## Global Constraints

- Branch `quickhack-rounds`, on unmerged `faction-rounds-3`. No push, no merge, no release.
- Every commit ends: `Claude-Session: https://claude.ai/code/session_01JwJvEAYGPc2WFWAem67MMf`
- Generated blocks are never edited by hand. Run `python3 tools/rounds/rounds.py`, then `python3 tools/crafting/crafting.py`.
- Game: never deploy while it runs. Order, all through `tools/linux/game-lock.sh bash -c '...'`: `tools/linux/restart-game.sh --kill`, `tools/linux/deploy.sh`, `tools/linux/restart-game.sh`. Check `game_running` from `tools/linux/common.sh` first; if it's running and not yours, it's the user's: stop. Shut the game down when done.
- Windows tools run on GE-Proton through `tools/linux/*.sh`, never bare wine.
- Never `git add -A tools`; add explicit paths. `reference`, `tools/wolvenkit`, `tools/wolvenkit-win` stay untracked.
- Public text (`CHANGELOG.md`, `README.md`, `docs/NEXUS.md`) names no Legendary round beyond Pump N Dump and Kebab. No markdown tables in docs.
- Nothing a round does may touch other guns through a shared record.

## Review Focus

- A cloud reaching V or a quest NPC: V gets nothing and a guarded NPC isn't poisoned. Test in Task 2.
- A Contagion cloud hitting another NPC mustn't start a new cloud, or one shot chains through a crowd. Test in Task 2.
- A batch of 3 boxes with 3 copies held costs 3, and a batch with 2 copies held is refused by the recipe screen. Test in Task 5.
- A body carrying a hack round never gives a load sheet, since hack rounds have none to teach. Test in Task 3.
- An existing save learns the hack recipes on load, as Common recipes are. Test in Task 5.

---

### Task 1: The rounds

**Files:**
- Modify: `tools/rounds/rounds.py`, `tools/rounds/test_rounds.py`
- Generated: `src/tweaks/AmmoOverhaul/smart_10.yaml`, `smart_20.yaml`, `smart_25.yaml`, `src/scripts/AmmoOverhaul/LocalizationRounds.reds`, `tools/render/rounds_tiers.json`, `tools/rounds/refs.txt`

**Interfaces:**
- Produces: tier codes `HACK_UNCOMMON, HACK_RARE, HACK_EPIC, HACK_LEGENDARY = 10, 11, 12, 13`; ammo `Ammo.AO_S10_Hack<Name><N>` with N 1 to 4 for Uncommon to Legendary (`<Name>`: Optics, Sonic, Contagion, Cyberware, Short, Cripple, Overheat, Glitch, Burnout, Psycho, Grenade); flats `<ammo>.aoHackProgram` (the quickhack's record name), and the rank flats with `aoRankToughFrom` "Never" or "Boss", no `aoRankPlayer`, and `aoRankBlast` on Contagion and Detonate Grenade.

- [ ] **Step 1: Write the failing tests** in `test_rounds.py`:

```python
def hack_rounds():
    return [(t, k) for t, k in rounds.rounds() if k.get("hack")]

def test_hack_round_counts():
    assert len(hack_rounds()) == 117
    assert {t for t, _ in hack_rounds()} == {"10mm", "20mm", "25mm"}

def test_hack_names_and_qualities():
    t, k = next((t, k) for t, k in hack_rounds() if k["load"] == "HackOptics1" and t == "10mm")
    assert rounds.title(t, k) == "10mm Reboot Optics [Hack]"
    assert rounds.QUALITY[k["tier"]] == "Uncommon"

def test_hack_chances():
    by = {k["load"]: k["hit"]["rank"]["chance"] for _, k in hack_rounds()}
    assert [by[f"HackOptics{n}"] for n in (1, 2, 3, 4)] == [0.10, 0.15, 0.20, 0.25]
    assert [by[f"HackContagion{n}"] for n in (1, 2, 3, 4)] == [0.04, 0.06, 0.08, 0.10]
    assert by["HackBurnout2"] == 0.06 and by["HackShort4"] == 0.10

def test_hack_flats():
    y = rounds.round_yaml(*next((t, k) for t, k in hack_rounds() if k["load"] == "HackPsycho4"))
    assert 'aoHackProgram: "Items.MadnessLvl4Program"' in y
    assert 'aoRankEffect: "AmmoOverhaul.MadnessHack"' in y
    assert 'aoRankToughFrom: "Boss"' in y
    assert "aoRankPlayer" not in y

def test_hack_icons_shared_across_calibers():
    assert len({rounds.ids(t, k)["icon"] for t, k in hack_rounds()}) == 39
```

- [ ] **Step 2: Run:** `cd tools/rounds && python3 -m pytest -q test_rounds.py`. Expected: the five new tests FAIL.

- [ ] **Step 3: Implement in `rounds.py`.**
  - `HACKS`, a table of (name, title, verb, list of (tier, program, effect)), from the spec's lists. `Items.<x>Program` records per the spec's "The hacks". Verbs: "blind the target", "deafen the target", "poison the target and whoever's close", "make the target's cyberware fail", "overload the target's systems", "cripple the target's legs", "burn the target", "jam the target's weapon", "burn out the target's brain", "drive the target mad", "blow up the target".
  - Expand it into `KINDS` entries with `load=f"Hack{name}{n}"`, `hack=True`, `calibers=["10mm","20mm","25mm"]`, `stats=[]`, and `desc=f"Carries a {title} payload.\n\n{pct}% chance per shot to {verb}."`
  - `hit=dict(rank=dict(effect=..., chance=..., tough_from="Boss" for Cyberpsychosis else "Never"))`, plus `blast=`: Contagion `AmmoOverhaul.HackCloud1` to `4` by tier, Detonate Grenade `AmmoOverhaul.HackBlast` at Epic and `AmmoOverhaul.HackBlastBig` at Legendary. Detonate Grenade's effect is `BaseStatusEffect.WasQuickHacked`, a harmless marker every vanilla hack applies.
  - `rank["player"]` becomes optional in `round_yaml`, and `rank.get("blast")` writes `aoRankBlast`. `k["program"]` writes `aoHackProgram`.
  - `title()` adds `[Hack]`. `ids()` gives hack kinds `icon=f"AO_{load}"`, `part=f"ao_{load.lower()}"`, `art=f"hack-{load.lower()}"`, shared by the calibers. The UIIcon block is written once per kind.
  - QUALITY, PRICE and any tier check gain 10 to 13 with the values of Uncommon, Rare, Epic, Legendary.

- [ ] **Step 4: Run** `python3 tools/rounds/rounds.py`, `cd tools/rounds && python3 -m pytest -q test_rounds.py`, then `tools/linux/check.sh`. Expected: the generator prints "315 rounds" (198 plus 117), all tests pass, compile succeeds.

- [ ] **Step 5: Commit** `git add tools/rounds src/tweaks/AmmoOverhaul src/scripts/AmmoOverhaul/LocalizationRounds.reds tools/render/rounds_tiers.json`, message `feat: 117 quickhack rounds`.

### Task 2: On hit

**Files:**
- Modify: `src/scripts/AmmoOverhaul/FactionRounds.reds`, `src/tweaks/AmmoOverhaul/core.yaml`
- Create: `tools/snippets/calibers/quickhack.sh`

**Interfaces:**
- Consumes: Task 1's flats.
- Produces: `FactionRounds.RankResult` honouring `aoRankToughFrom` "Never" (tough only if mechanical or guarded); records `AmmoOverhaul.MadnessHack`, `AmmoOverhaul.HackCloud1` to `4`, `AmmoOverhaul.HackBlast`, `AmmoOverhaul.HackBlastBig`; `quickhack.sh` with parts added by later tasks.

- [ ] **Step 1: Write `quickhack.sh`** on `npc-lib.sh`, reusing `faction.sh`'s helpers (copy `vs`, `frail`, `rankchance`, `carrier`, `npcshoot`, `despawn`). Parts: `effects` (one tier of each hack with chance forced to 1.0 on a Normal: the status is on the NPC), `overheat` (a live hit at tier 4 costs health over 5 seconds), `boss` (Cyberpsychosis does nothing on a Boss, Reboot Optics lands), `guarded` (an Immortal NPC gets no Short Circuit), `onv` (an NPC's Reboot Optics adds no status to V), `cloud` (Contagion at 1.0 poisons a second NPC 2 m off; V within range isn't poisoned; an Immortal NPC isn't; exactly 1 cloud per shot, counted from the log), `grenade` (Detonate Grenade's blast damages the target and a neighbour).

- [ ] **Step 2: Run it:** deploy per Global Constraints, then `tools/linux/game-lock.sh tools/snippets/calibers/quickhack.sh`. Expected: FAIL on `boss`, `cloud`, `grenade`.

- [ ] **Step 3: Implement.**
  - `RankResult`: "Never" skips the Boss and MaxTac test. Guarded NPCs and machines then get nothing from any hack round, not only the ones that kill, because all of them share this path. That's a narrow widening of the spec, kept for one simple rule.
  - The rank branch of the hit hook: when an effect lands and `AOData.RankRecord(ammo, "aoRankBlast")` is valid, `FactionRounds.Blast(instigator, puppet, blast)`, logging `"hack blast"`.
  - `FactionRounds.Cloud`: when the attack has `aoCloudHack`, add no effect to V or a guarded target. It keeps returning true.
  - `core.yaml`: `MadnessHack`, base `BaseStatusEffect.MandessLevel4`, 30 second duration, as `AmmoOverhaul.JujuMadness` is built. `HackCloud1` to `4`, as `ClapCloud`, ranges 2, 3, 4, 5 m, each `aoCloudEffect` the tier's `ContagionPoison` record, `aoCloudHack: true`. `HackBlast`, range 3, `HackBlastBig`, range 5, on `Attacks.ChimeraPowerMod_BulletExplosion` with health damage as `ScrapBlast` at 0.25 and 0.5.

- [ ] **Step 4: Run** `tools/linux/check.sh`, deploy, run `quickhack.sh`. Expected: all PASS. If `overheat` still fails, change Overheat's four rank effects to `BaseStatusEffect.Burning` in `HACKS`, rerun the generators, and tell the user.

- [ ] **Step 5: Commit** `git add src/scripts/AmmoOverhaul/FactionRounds.reds src/tweaks/AmmoOverhaul/core.yaml tools/snippets/calibers/quickhack.sh`, message `feat: quickhack rounds on hit`.

### Task 3: NPCs

**Files:**
- Create: `src/scripts/AmmoOverhaul/HackRounds.reds`
- Modify: `src/scripts/AmmoOverhaul/NpcAmmo.reds`, `AmmoDistribution.reds`, `AOData.reds`, `src/tweaks/AmmoOverhaul/core.yaml`, `tools/snippets/calibers/quickhack.sh`, `tools/snippets/calibers/tiers.lua`, `distribution.lua` where counts change

**Interfaces:**
- Produces: `HackRounds.Roll(caliber: String, rarity: String) -> TweakDBID`, `HackRounds.IsNetrunner(npc: ref<NPCPuppet>) -> Bool`, `HackRounds.Drop(npc: ref<NPCPuppet>) -> Void`, `AOData.IsHackTier(tier: Int32) -> Bool`.

- [ ] **Step 1: Add parts to `quickhack.sh`:** `rolls` (via `DebugFactionPick`-style `DebugHackPick(caliber, rarity, n)` at 8000 picks: Normal 3% within 1 point, Boss 12% within 2, Normal no tier 12 or 13, Elite Legendary about 1 in 10 of its rolls, a 9mm gun gets none, and the general smart lists hold no tier 10 to 13), `drop` (a Lexington netrunner at chance 1.0 has hack rounds on the body; a plain NPC doesn't), `nosheet` (with `recipeDropFactor` 1.0, a body holding `Ammo.AO_S10_HackOptics1` gives no recipe item).

- [ ] **Step 2: Run them.** Expected: FAIL (no `DebugHackPick`, no drop).

- [ ] **Step 3: Implement.**
  - `core.yaml`: `AmmoOverhaul.npcHackChance.Normal: 0.03`, `Officer: 0.05`, `Elite: 0.08`, `Boss: 0.12`, `MaxTac: 0.12`; `AmmoOverhaul.hackDropStack: 10`.
  - `Roll`: only for Smart family calibers, chance first, as `FactionRounds.Roll`. On Elite, Boss and MaxTac 1 in 10 takes tier 13. Otherwise a random selector of tiers 10, 11, and 12 from Officer up.
  - `NpcAmmo.RollSelector`: after Legendary, before the faction roll, `HackRounds.Roll`.
  - `IsNetrunner`: `TweakDBInterface.GetCharacterRecord(npc.GetRecordID()).ArchetypeData().Type().Type()` is `NetrunnerT1`, `T2` or `T3`.
  - `Drop`: called once from `NpcAmmo.TopUpLoot` after `aoLootGiven` is set, for a netrunner: roll with a random smart caliber, give `hackDropStack` of the ammo.
  - `RecipeRoll`: invalid for hack tiers, by `AOData.SelectorTier` or a flat `aoHackProgram` check.
  - `AmmoFeedSystem.DebugHackPick`, as `DebugFactionPick`.

- [ ] **Step 4: Run** `tools/linux/check.sh`, deploy, `quickhack.sh rolls drop nosheet`, `CET_T=240 FROZEN_AFTER=240 tools/snippets/calibers/check.sh calibers/tiers.lua`, `check.sh calibers/distribution.lua`. Expected: all pass, updating counts these hold only where the new rounds change them.

- [ ] **Step 5: Commit** explicit paths, message `feat: NPCs carry and netrunners drop hack rounds`.

### Task 4: Shops

**Files:**
- Modify: `src/scripts/AmmoOverhaul/HackRounds.reds`, `Vendors.reds`, `src/tweaks/AmmoOverhaul/core.yaml`, `tools/snippets/calibers/quickhack.sh`

**Interfaces:**
- Produces: `HackRounds.ShopStock(vendor: TweakDBID, gunshop: Bool) -> array<AOStack>`.

- [ ] **Step 1: Add part `shops`** to `quickhack.sh`: `DebugHackStock` at `hackShopChance` 1.0 over 200 builds. A gun shop (`Vendors.wat_nid_gunsmith_01`) lists tiers 10 and 11 only, `Vendors.wat_kab_netrunner_01` lists 10 to 12, `Vendors.wat_kab_ripperdoc_01` lists nothing, and none lists tier 13.

- [ ] **Step 2: Run it.** Expected: FAIL.

- [ ] **Step 3: Implement.** `core.yaml`: `<vendor>.aoHackShop: true` for `wbr_jpn_netrunner_01`, `wbr_jpn_netrunner_02`, `cz_stadium_netrunner_01`, `wat_lch_netrunner_01`, `cz_con_netrunner_01`, `wat_kab_netrunner_01`, `hey_rey_netrunner_01`; `AmmoOverhaul.hackShopChance: 0.5`; `AmmoOverhaul.hackShopStack: 15`. `ShopStock` returns 1 or 2 random stacks past the chance. `AOSplitAmmo` adds them after the turf block, using a stack built from `template`. If a netrunner vendor's stock has no ammo stack, `template` is empty: build the `SItemStack` from `ItemID.FromTDBID` alone and check it shows in the shop.

- [ ] **Step 4: Run** check, deploy, `quickhack.sh shops`. Expected: PASS.

- [ ] **Step 5: Commit** explicit paths, message `feat: hack rounds in gun shops and netrunner vendors`.

### Task 5: Crafting

**Files:**
- Modify: `tools/crafting/crafting.py`, `src/scripts/AmmoOverhaul/Crafting.reds`, `tools/snippets/calibers/quickhack.sh`, `tools/snippets/calibers/crafting.sh` if its counts change
- Generated: smart yaml blocks, `zz_crafting_costs.yaml`, `LocalizationRecipes.reds`

**Interfaces:**
- Consumes: `<ammo>.aoHackProgram`.
- Produces: `Crafting.AO_Cost_Hack_<short>` per round; `aoRecipe` set as Common rounds', never handed out.

- [ ] **Step 1: Add parts** to `quickhack.sh`: `known` (a fresh load has `KnowsRecipe` for `Ammo.AO_S10_HackOptics1`), `craft` (with `Items.BlindLvl1Program`: 1 held, 1 craft leaves 0; 5 held, 1 craft leaves 4; 5 held, batch of 3 leaves 2; 2 held, `HasIngredients` for a batch of 3 is false; a hack installed in the deck stays in the deck; output is a box of rounds), `scrap` (breaking a box down gives components and no program).

- [ ] **Step 2: Run them.** Expected: FAIL.

- [ ] **Step 3: Implement.**
  - `crafting.py`: tiers 10 to 13 map to base tiers 1 to 4. `MATERIAL`, `QUALITY`, `DIVISOR`, `TIER_PRICE` gain a Legendary entry (`Items.LegendaryMaterial1`, `Legendary`, 5, 16). A hack round's cost is its own `CraftingPackage` with the tier's components and `ingredient: <aoHackProgram>`, amount 1. They stay out of `NO_RECIPE`, keep a recipe item for `GetAmmoBulletAmount`, tagged without `AO_Recipe` so no list hands them out.
  - `AOAddCommonRecipes`: also tiers 10 to 13.
  - `@wrapMethod(CraftingSystem) private final func CraftItem(target: wref<GameObject>, itemRecord: ref<Item_Record>, amount: Int32, opt ammoBulletAmount: Int32) -> wref<gameItemData>`: for a round with `aoHackProgram`, read the program's count before, call through, and `GiveItem` the amount removed beyond `amount`.

- [ ] **Step 4: Run** `python3 tools/crafting/crafting.py`, check, deploy, `quickhack.sh known craft scrap`, `tools/snippets/calibers/crafting.sh`, `check.sh calibers/records.lua`. Expected: all pass, and records.lua finds `Items.LegendaryMaterial1` and every program.

- [ ] **Step 5: Commit** explicit paths, message `feat: quickhack rounds crafted from the quickhack`.

### Task 6: Art

**Files:**
- Modify: `tools/render/scene.py`, `tools/render/faction_art.py`, `tools/render/render.py`, `tools/render/faction_textures.sh`, `tools/icons/make_icons.py`, `tools/icons/check_parts.py`
- Generated: `art/icons/hack-*.png`, `src/archive/AmmoOverhaul.archive`

**Interfaces:**
- Consumes: `rounds_tiers.json` entries with `art=hack-<load>`.

- [ ] **Step 1: Extract** the game's quickhack icon sheet in `faction_textures.sh`, finding its path from a program's `iconPath` record. Game textures stay out of the repo.

- [ ] **Step 2: Build two forms** in `scene.py`: `hack_cart`, a data cartridge coloured by rarity with the hack's mark, and `hack_legend`, the Legendary's own object. Render one of each at 48 samples into the scratchpad. **Stop and send the sheet to the user. No full render before approval.**

- [ ] **Step 3: Render all 39** with `nice -n 19`, game off.

- [ ] **Step 4: Build and check.** `tools/icons/build.sh`, `python3 tools/icons/check_parts.py`. Expected: `276 cells, 0 overlapping`. Update the `(237 used)` comment.

- [ ] **Step 5: Commit** explicit paths, message `art: quickhack rounds`.

### Task 7: Docs and the whole run

**Files:**
- Modify: `CHANGELOG.md`, `README.md`, `docs/NEXUS.md`, `docs/CATALOG.md`, `docs/TESTING.md`, `docs/MECHANICS.md`, the spec's Status, `tools/testkit/init.lua`

- [ ] **Step 1: Docs.** Counts 237 to 354. A family paragraph in public text, naming no Legendary. CATALOG section. TESTING: `quickhack.sh` parts and a field list (each hack's feel, Short Circuit and Contagion balance, shops opened live, a netrunner's body). MECHANICS: per-tier hack effects, program double removal, installed hacks as deck parts, `SuicideWithGrenade` needs a grenade, archetype `NetrunnerT*`. Field kit: `isFieldRound` includes hack rounds at one tier, and quickhack copies for crafting.

- [ ] **Step 2: Run** `quickhack.sh` whole, `tiers.lua`, `records.lua`, `distribution.lua`, `icons.lua`, `crafting.sh`, `test_rounds.py`, then shut the game down. Expected: 0 FAIL.

- [ ] **Step 3: Commit** explicit paths, message `docs: quickhack rounds`.

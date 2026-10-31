# Faction Rounds 2 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add 25 faction rounds (10 kinds) for Tyger Claws, Valentinos, 6th Street, Militech and the Animals, taking the mod from 175 rounds to 200.

**Architecture:** Rounds are rows in `KINDS` in `tools/rounds/rounds.py`, which generates the tweaks, text and art entries. Three new optional ammo flats drive new hit behaviour in `FactionRounds.reds`, called from `AmmoFeedSystem.ApplyAmmoOnHit`. Art forms are already committed; this plan renders them for real.

**Tech Stack:** Python generator with pytest, redscript, TweakXL yaml, CET Lua live checks, Blender and PIL.

**Spec:** `docs/superpowers/specs/2026-10-31-faction-rounds-2-design.md`, with the binding rules of `docs/superpowers/specs/2026-10-30-faction-rounds-design.md`.

## Global Constraints

- Branch `faction-rounds-2`, on top of unmerged `faction-rounds`. No push, no merge, no release.
- Every commit ends: `Claude-Session: https://claude.ai/code/session_01JwJvEAYGPc2WFWAem67MMf`
- Generated blocks are never edited by hand. Run `python3 tools/rounds/rounds.py`, then `python3 tools/crafting/crafting.py`.
- Game: never deploy while it runs. Order: `tools/linux/restart-game.sh --kill`, `tools/linux/deploy.sh`, `tools/linux/restart-game.sh`. Move it to workspace 10 and stop it when done. In-game runs go through `tools/linux/game-lock.sh`.
- Never check `pgrep -f`; use `game_running` from `tools/linux/common.sh`. Windows tools run on GE-Proton through `tools/linux/*.sh`, never bare wine.
- NPCs and V follow the same rules; where an effect can't mean the same on V, the round's text says what it does. No script faking a weapon, no shared-record changes at runtime.
- Item text as in the spec, verbatim. Public docs name no Legendary but Pump N Dump and Kebab.
- Test new mechanisms only; the full suite waits for release.
- Blender runs under `nice -n 19`, never while the user plays.

## Review Focus

- A Cease and Desist shotgun blast: 30% is per shot, not per pellet, and one blast applies one stagger.
- A headshot that kills: the burn on a dying target causes no error and no stuck effect.
- Blocked, deflected or friendly-fire hits: no burn, stagger or knockdown, the same gate as Cook-off.
- Boss and MaxTac targets: Cease and Desist does nothing, Leg Day staggers; Elites still stagger from both.
- Hits on non-puppets (a turret, a car, a device): nothing happens and nothing errors.

---

### Task 1: The rounds in the generator

**Files:**
- Modify: `tools/rounds/rounds.py`, `tools/rounds/test_rounds.py`, `src/tweaks/AmmoOverhaul/core.yaml`
- Generated: caliber yamls, `LocalizationRounds.reds`, `tools/render/rounds_tiers.json`, `tools/rounds/refs.txt`, crafting flats

**Interfaces:**
- Produces: `hit` keys `head_effect` (str) writing `aoHeadEffect`, `head_fallback` (float) writing `aoHeadFallback`, `legs` (float) writing `aoLegChance`, `pumped` (bool) writing `aoPumped`, `stop` (float) writing `aoStopChance`; kind key `price` (number) overriding `PRICE[tier]`.
- Produces: faction keys `TygerClaws`, `Valentinos`, `SixthStreet`, `Militech`, `Animals`.

- [ ] **Step 1: Write the failing tests** in `test_rounds.py`

Add to `SPEC`, and to `TAGS` the five tags `[Tyger]`, `[Val]`, `[6th]`, `[Mil]`, `[Animal]`:

```python
"ShinobiSeconds": ("TygerClaws", FACTION_UNCOMMON, {"9mm", "45"}),
"Tanto": ("TygerClaws", FACTION_RARE, {"9mm", "45", "12mm"}),
"GoldTips": ("Valentinos", FACTION_RARE, {"45", "12mm"}),
"SantaMuerte": ("Valentinos", FACTION_EPIC, {"45", "12mm"}),
"Surplus": ("SixthStreet", FACTION_UNCOMMON, {"9mm", "45", "12mm"}),
"FourthOfJuly": ("SixthStreet", FACTION_RARE, {"9mm", "12mm", "10mm"}),
"MilSpec": ("Militech", FACTION_RARE, {"9mm", "762", "5mm"}),
"CeaseAndDesist": ("Militech", FACTION_EPIC, {"762", "12ga"}),
"ProteinLoads": ("Animals", FACTION_RARE, {"12mm", "5mm", "Heavy"}),
"LegDay": ("Animals", FACTION_EPIC, {"12mm", "Heavy"}),
```

Rename `test_twenty_six_rounds_as_specified` to `test_faction_rounds_as_specified`, asserting `len(faction_rounds()) == 51`. Add:

```python
def test_second_batch_flats():
    by = {(t, k["load"]): round_yaml(t, k) for t, k in faction_rounds()}
    assert 'Ammo.AO_45_SantaMuerte.aoHeadEffect: "BaseStatusEffect.Burning"' in by["45", "SantaMuerte"]
    assert "Ammo.AO_762_CeaseAndDesist.aoStopChance: 0.3" in by["762", "CeaseAndDesist"]
    assert "Ammo.AO_12mm_LegDay.aoLegChance: 0.2" in by["12mm", "LegDay"]
    assert "Ammo.AO_9mm_ShinobiSeconds.rollDudChance: 0.05" in by["9mm", "ShinobiSeconds"]
    assert "Ammo.AO_9mm_ShinobiSeconds.rollDudMult: 0.25" in by["9mm", "ShinobiSeconds"]
    assert "Ammo.AO_TLight_MilSpec.rollMin: 0.95" in by["5mm", "MilSpec"]


def test_gold_tips_sell_for_half_again_the_rare_price():
    y = round_yaml("45", next(k for t, k in faction_rounds() if k["load"] == "GoldTips"))
    assert y.count("value: 3\n") == 2
```

- [ ] **Step 2: Run them to see them fail**

Run: `cd tools/rounds && python3 -m pytest test_rounds.py -q`
Expected: FAIL on `test_faction_rounds_as_specified`, `test_second_batch_flats`, `test_gold_tips_...`.

- [ ] **Step 3: Implement in `rounds.py`**

Add the five tags to `FACTION_TAG`. Write the four `hit` flats in `round_yaml`; add `head_effect` to `write_refs`. Make `price_yaml(tier, price=None)` use `price` when given and pass `k.get("price")`; the comment above the ammo prints the same value. Leave `art` off these kinds' colours (`FACTION_ROUND` in `render.py` sets them).

Add ten kinds after Shinobi, with `desc` copied verbatim from the spec. `NARROW = dict(rollMin=0.95, rollMax=1.05, rollDudChance=0.0, rollHotChance=0.0)`.

- ShinobiSeconds, title "Shinobi Seconds", `stats=[add("CanSilentKill", 1.0)] + damage(0.85)`, `hit=dict(roll=dict(rollDudChance=0.05, rollDudMult=0.25))`
- Tanto, `stats=[add("CritChance", 0.10)]`, `hit=dict(effects=[("BaseStatusEffect.Bleeding", 0.25)])`
- GoldTips, title "Gold Tips", `stats=[add("CritChance", 0.15), add("CritDamage", 0.30)] + recoil(1.20)`, `price=3`
- SantaMuerte, title "Santa Muerte", `stats=[add("HeadshotDamageMultiplier", 0.5)]`, `hit=dict(head_effect=BURN)`
- Surplus, `stats=recoil(0.90)`, `hit=dict(roll=NARROW)`
- FourthOfJuly, title "Fourth of July", `stats=[]`, `hit=dict(effects=[("AmmoOverhaul.PingTag", 1.0), (BURN, 0.10)])`
- MilSpec, title "Mil-Spec", `stats=armor(0.25) + recoil(0.85)`, `hit=dict(roll=NARROW)`
- CeaseAndDesist, title "Cease and Desist", `stats=armor(0.50) + damage(0.90)`, `hit=dict(stop=0.30)`
- ProteinLoads, title "Protein Loads", `stats=[]`, `hit=dict(pumped=True)`
- LegDay, title "Leg Day", `stats=recoil(1.80)`, `hit=dict(legs=0.20)`

Pick `look` pairs for each from its box's colours. In `core.yaml`, after the Arasaka line:

```yaml
AmmoOverhaul.factionOf.TygerClaws: "TygerClaws"
AmmoOverhaul.factionOf.Valentinos: "Valentinos"
AmmoOverhaul.factionOf.SixthStreet: "SixthStreet"
AmmoOverhaul.factionOf.Militech: "Militech"
AmmoOverhaul.factionOf.Animals: "Animals"
```

- [ ] **Step 4: Run tests and generators**

Run: `cd tools/rounds && python3 -m pytest test_rounds.py -q && cd ../.. && python3 tools/rounds/rounds.py && python3 tools/crafting/crafting.py && python3 -m pytest tools/crafting/test_crafting.py -q`
Expected: all PASS; `rounds.py` prints a count 25 higher than a run on the branch's previous commit.

- [ ] **Step 5: Commit**

```bash
git add tools/rounds src/tweaks/AmmoOverhaul src/scripts/AmmoOverhaul/LocalizationRounds.reds tools/render/rounds_tiers.json tools/crafting
git commit -m "feat: 25 rounds for Tyger Claws, Valentinos, 6th Street, Militech, Animals"
```

### Task 2: Headshot, stop and floor hits

**Files:**
- Modify: `src/scripts/AmmoOverhaul/AOData.reds`, `FactionRounds.reds`, `AmmoFeedSystem.reds`, `src/tweaks/AmmoOverhaul/test.yaml`
- Modify: `tools/snippets/calibers/faction.sh`

**Interfaces:**
- Consumes: the flats from Task 1.
- Produces: `AOData.HeadEffect(ammo: TweakDBID) -> TweakDBID`, `AOData.HeadFallback(ammo) -> Float`, `AOData.LegChance(ammo) -> Float`, `AOData.Pumped(ammo) -> Bool`, `AOData.StopChance(ammo) -> Float`, each following `AOData.SelfJam`; `FactionRounds.OnHit(attackData: ref<AttackData>, target: ref<GameObject>, ammo: TweakDBID, pellets: Int32) -> Void`.

- [ ] **Step 1: Write the failing live checks**

Add `Character.AO_Test_<Tyger|Val|Six|Mil|Animal>_Unity` to `test.yaml`, as `AO_Test_Ara_Unity`, with `affiliation: Factions.<key>`. To `faction.sh` add these parts, also in its default list:
- `affiliation2`: each of the five spawns and `DebugFactionOf` returns its key.
- `headfx`: with Santa Muerte fed, 12 chest shots apply 0 `BaseStatusEffect.Burning`; head shots apply exactly as many as head-flagged hits (the aim code from the probe, in the rig's `aim` with a pitch at the `Head` slot; add it to `rig.lua` as `RIG.fireHead()`).
- `stops`: with `aoStopChance` set to 1.0 by `TweakDB:SetFlat` on a Cease and Desist 7.62 gun, a Normal NPC takes `BaseStatusEffect.ForceStagger`, an Elite takes it, a Boss (`Character.ma_wat_kab_08_cyberpsycho`) doesn't. On a Crusher at 1.0, one blast counts one application.
- `legs`: with `aoLegChance` at 1.0, a Normal NPC takes `BaseStatusEffect.CrippledLeg`, an Elite `ForceStagger`, V `Knockdown` and never `CrippledLeg`.
- `pumped`: killing with Protein Loads puts one stack of `AmmoOverhaul.Pumped` on V with a gun out and raises `MaxSpeed` and lowers reload time; three kills stack to three and a fourth does not; an NPC's kill of another NPC buffs that NPC.
- `crits`: with Gold Tips and Ball, 100 hits each on an Immortal NPC, the share of `hitFlag.CriticalHit` hits rises by at least 8 points. Ranks come from `NPCPuppet.GetNPCRarity`, not the record's name: that Elite record reported Normal in the probe, so the check first prints the rank and uses `AOData` flats to pick a true Elite if needed.

- [ ] **Step 2: Deploy and watch them fail**

Run: `tools/linux/game-lock.sh bash -c 'tools/linux/restart-game.sh --kill; tools/linux/deploy.sh && tools/linux/restart-game.sh && tools/snippets/calibers/faction.sh affiliation2 headfx stops legs pumped crits'`
Expected: `affiliation2` PASS (Task 1 did that); `headfx`, `stops`, `legs`, `pumped` FAIL, no effects applied. Record what `crits` shows.

- [ ] **Step 3: Implement**

`FactionRounds.OnHit`, called in `ApplyAmmoOnHit` beside the Mule Kick call, under `!gated`, before the early return on empty effects, for every ammo:
- Target must cast to `ScriptedPuppet`, or return.
- `head := AOData.HeadEffect(ammo)`: if valid and `attackData.HasFlag(hitFlag.Headshot)`, or the target is V and `RandF() < AOData.HeadFallback(ammo)`, add it through `AOData.PlayerEffect` on V.
- Stop and legs roll `AOData.PelletChance(chance, pellets)`, gated per shot per target by the Mule Kick field `aoMuleKickAt`, so pellets of a shot give one effect. Legs adds `BaseStatusEffect.CrippledLeg` to Trash through Officer, `ForceStagger` to Elite, Boss and MaxTac, and `Knockdown` to V. Stop adds `BaseStatusEffect.ForceStagger` unless the rarity is `Boss` or `MaxTac`.

Move the `pellets` line in `ApplyAmmoOnHit` above the call.

Pumped: define `AmmoOverhaul.Pumped` in `core.yaml` (MaxDuration 10, 3 stacks, `MaxSpeed` AdditiveMultiplier 0.06, `ReloadTimeBonus` -0.10), copying the shape of `BaseStatusEffect.Sovereign_Speed_Buff`. Mark the target with the shooter and time as `MarkParts` does, for any shooter, and in `OnDeath` apply it to the shooter if the death is within 0.5 s.

- [ ] **Step 4: Decide the three engine questions from live results**

- **Headshots on V:** log hits on V with `hitFlag.Headshot` over at least 100 NPC hits. If none are flagged, set `head_fallback=0.10` on SantaMuerte and rerun Task 1's generators. If some are, leave it off.
- **Stagger on V:** apply `ForceStagger` to V and look for a reaction. If none, use a stagger record that moves V if one exists; if none does, change Cease and Desist's spec line and text to say hits on you do nothing extra, and tell the user.
- **Crits:** if `crits` fails, gun stats don't reach the roll. Replace the `CritChance` stat with a flat `aoCritChance` set through `attackData.SetAdditionalCritChance` in a `CalculateDamageVariants`-stage hook, and report `CritDamage` to the user before changing its text.

- [ ] **Step 5: Run to green**

Run: same as Step 2, plus `tools/linux/check.sh` first.
Expected: compile clean, every part PASS, exit 0. Then run `tools/snippets/calibers/faction.sh kansatsu chrome` to confirm old rounds behave.

- [ ] **Step 6: Commit**

```bash
git add src tools/snippets/calibers tools/rounds tools/render/rounds_tiers.json
git commit -m "feat: headshot, stop and floor hits for the second faction rounds"
```

### Task 3: Final icons

**Files:**
- Modify: `tools/icons/make_icons.py` (comment: 200 used), `art/icons/*.png`, `src/archive/AmmoOverhaul.archive`

**Interfaces:**
- Consumes: `rounds_tiers.json` from Task 1, with art names `<caliber>-<load>` in lower case. `faction_form`'s Santa Muerte test is `name.endswith("santamuerte")`.

- [ ] **Step 1: Render all 25**

Run: `nice -n 19 python3 tools/render/render.py --only <the 25 names>`
Expected: 25 new PNGs in `art/icons`; 175 older ones unchanged in `git status`.

- [ ] **Step 2: Check them**

Build a contact sheet in the scratchpad and read it. Check every caliber of each box, especially those not yet rendered: 9mm and 12mm in the lacquer box, .45 in the cigar box's Gold Tips, 12mm and .45 in the crate, and 12ga Cease and Desist in the case. Send it to the user with SendUserFile.

- [ ] **Step 3: Build the atlas**

Run: `tools/icons/build.sh`, with the game off, then the Step 2 command of Task 2 with `tools/snippets/calibers/icons.lua` through `cet.sh -f`.
Expected: every part resolves; the check counts 200 rounds' icons.

- [ ] **Step 4: Commit**

```bash
git add art/icons tools/icons src/archive
git commit -m "art: icons for the second faction rounds, atlas for 200"
```

### Task 4: Record checks

**Files:**
- Modify only what the checks expose. Expected counts in `tools/snippets/calibers/records.lua`, `distribution.lua`, `tiers.lua`.

- [ ] **Step 1: Run the data checks**

Run through `game-lock.sh`, with the Task 3 build deployed: `cet.sh -f` on `records.lua`, `distribution.lua`, `tiers.lua`, and `tools/snippets/calibers/crafting.sh`.
Expected: all pass with no new failures; any hard-coded count from 175 moves to 200.

- [ ] **Step 2: Give the field kit**

Press the kit's button through `GetMod("AOTestKit")` and confirm the message counts 51 rounds, and that a Nova holds Leg Day after a swap. `FIELD_GUNS` already covers these calibers.

- [ ] **Step 3: Stop the game and commit**

```bash
tools/linux/restart-game.sh --kill
git add tools/snippets/calibers
git commit -m "test: record checks at 200 rounds"
```

### Task 5: Docs and handoff to the field test

**Files:**
- Modify: `CHANGELOG.md`, `README.md`, `docs/NEXUS.md`, `docs/CATALOG.md`, `docs/DESIGN.md`, `docs/TESTING.md`, `docs/FACTIONS.md`, `docs/MECHANICS.md`, `docs/IDEAS.md`, the spec's Status line

- [ ] **Step 1: Write them**

- Round counts move from 175 to 200; the Unreleased changelog gains the five factions.
- `TESTING.md`: a manual line per kind, in the style of its Redliners line: Protein Loads pump on kills, Leg Day cripples, Cease and Desist on return fire, Fourth of July tags, Santa Muerte burns on headshots only.
- `MECHANICS.md`: the probe results from memory `faction-batch2-probes.md`: headshot flag, blind effects and numbers, per-target quickhack cost, no tracer visuals.
- `IDEAS.md`: Zombie Powder and Backdoor with those results, held for a Voodoo Boys release.
- Spec status: built, with any Task 2 Step 4 outcome written in.

- [ ] **Step 2: Scan and commit**

Run: `grep -rn "175" README.md CHANGELOG.md docs/NEXUS.md tools/icons/make_icons.py`
Expected: only historic changelog lines.

```bash
git add CHANGELOG.md README.md docs
git commit -m "docs: the second faction rounds"
```

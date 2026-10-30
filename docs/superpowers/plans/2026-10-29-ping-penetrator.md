# Ping rounds and cover-piercing Penetrators Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add five rounds: Ping (Rare; 7.62, 12.7) and a cover-piercing Penetrator (Epic; 12mm,
7.62, 12.7). This takes the mod from 130 rounds to 135.

**Architecture:** Every Rare and Epic round comes from one table in `tools/rounds/rounds.py`;
the crafting generator (`tools/crafting/crafting.py`) runs after it. The Penetrator is the
existing `Penetrator` kind with three more calibers and per-caliber stats and text. Ping is a
new kind whose on-hit effect is a new status effect record, `AmmoOverhaul.PingTag`, based on
`BaseStatusEffect.KyubiMyersTag` with a 5 s duration. NPC guns already get a selector's stat
modifiers at runtime (`NpcAmmo.reds`, `AddModifier`), and NPC hits already run the on-hit
effects, so neither round needs new script code.

**Tech Stack:** TweakXL yaml, redscript (`check.sh` compile), Python generators, Blender icon
renders, CET Lua checks run in the game.

**Spec:** `docs/superpowers/specs/2026-10-29-ping-penetrator-design.md`

## Global Constraints

- **The game:**
  - One instance. All game work goes through `tools/linux/game-lock.sh <cmd>`.
  - Never deploy while the game runs. The order is `tools/linux/restart-game.sh --kill`, then
    `tools/linux/deploy.sh`, then `tools/linux/restart-game.sh`.
  - Shut the game down (`restart-game.sh --kill`) when you're done with it.
  - The user may be playing. Before any step that spawns NPCs or draws guns, ask the
    controller (the parent session).
- **Tools:**
  - Windows tools run on GE-Proton through `tools/linux/*.sh`. Never use system wine.
  - Never use grim.
  - Never move the mouse (no ydotool).
  - `game-shot.sh` moves the game window to a hidden screen. Don't use it while the user plays.
- **Damage rules:**
  - NPCs and V follow the same rules.
  - Common rounds stay vanilla.
  - No automatic ammo switching.
- **Item text:** slang names, plain gun-counter descriptions, no invented lore; the effect lines
  after a blank line. Use the spec's text verbatim.
- **Generated blocks:** never edit them by hand. Edit `tools/rounds/rounds.py` and rerun it,
  then rerun `tools/crafting/crafting.py`.
- **Testing:** test new mechanisms only. The full suite runs before release, not here.
- **Git:**
  - Commit messages end with
    `Claude-Session: https://claude.ai/code/session_01JwJvEAYGPc2WFWAem67MMf`.
  - Work on branch `ping-penetrator`.
  - Never push or merge without the user's go-ahead.

## Review Focus

- **Penetrator on NPCs.** An NPC's gun given the 12mm, 7.62 or 12.7 Penetrator carries
  `TechPierceEnabled` 1. If the stat landed on V's selector but not on NPC guns, NPCs would
  break the same-rules principle. Task 3 checks it.
- **Ping on V.** When an NPC hits V with a Ping round, the tag goes on V with no script error,
  and no stuck outline is left on V. Task 3 applies it to V and reads the log.
- **Penetrator text.** The 9mm, .45 and 5.56 Penetrator keep their armor-only stats and text
  (`AO-Ammo-Penetrator-Desc`). The three new calibers get their own text key. Task 1 checks it.
- **The tag wears off.** `AmmoOverhaul.PingTag` is gone about 5 s after a hit. If it inherited
  the 15 s from Hawk's tag, it would be wrong. Task 1 checks the record; Task 3 checks it live.
- **The Ping drawback.** The selector carries `damage(0.90)` and nothing else. In particular it
  has no `WeaponNoise`, which was an earlier idea that got dropped. Task 1 checks it.

---

### Task 1: Records: generator entries, the PingTag effect, static checks

**Files:**
- Modify: `tools/rounds/rounds.py` (the `KINDS` table)
- Modify: `src/tweaks/AmmoOverhaul/core.yaml` (a hand-written `AmmoOverhaul.PingTag` record)
- Regenerated:
  - `src/tweaks/AmmoOverhaul/power_12mm.yaml`, `power_762.yaml`, `power_127.yaml`
  - `src/scripts/AmmoOverhaul/LocalizationRounds.reds` and `LocalizationRecipes.reds`
  - `tools/render/rounds_tiers.json` and `tools/rounds/refs.txt`
- Test: `tools/snippets/calibers/records.lua` and `tools/snippets/calibers/hitdata.lua`, plus
  `tools/crafting/test_crafting.py` if it pins counts

**Interfaces:**
- **Produces records:**
  - `Ammo.AO_12mm_Penetrator`, `Ammo.AO_762_Penetrator` and `Ammo.AO_127_Penetrator`, each with
    a selector `Items.AO_Feed_<sel>_Penetrator`;
  - `Ammo.AO_762_Ping` and `Ammo.AO_127_Ping`, each with a selector `Items.AO_Feed_<sel>_Ping`;
  - `AmmoOverhaul.PingTag`.
- **Produces art entries:** in `rounds_tiers.json`, `12mm-penetrator`, `762-penetrator`,
  `127-penetrator`, `762-ping` and `127-ping`. Task 2 renders these.

- [ ] **Step 1: Write the failing checks**
  - In `records.lua`:
    - change `check("91 Rare and Epic rounds listed", ... == 91` to `96`;
    - add `check("Rare count", counted[2] == <old Rare + 2>)` and
      `check("Epic count", counted[3] == <old Epic + 3>)`. Read the old split from a run of the
      current check's message.
  - Also in `records.lua`, for each of the three new Penetrator selectors:
    - stat sums `TechPierceEnabled` = 1, `TechPierceChargeLevel` multiplier 0 and
      `TechPierceDamageFactor` = +0.5;
    - armor pen as the 9mm Penetrator;
    - description key `AO-Ammo-<loc>-Penetrator-Desc`.
  - Also in `records.lua`, for `Items.AO_Feed_9mm_Penetrator`: no `TechPierceEnabled` modifier,
    and description key `AO-Ammo-Penetrator-Desc`.
  - In `hitdata.lua`:
    - for `Ammo.AO_762_Ping` and `Ammo.AO_127_Ping`: `DebugHitData` contains
      `effects=AmmoOverhaul.PingTag:1;`;
    - their selectors' only stat modifier is `DamagePerHit` x0.90;
    - `AmmoOverhaul.PingTag` exists, its duration modifier's value is 5, and its gameplay tags
      include `AutoTag`.

- [ ] **Step 2: Run them to verify they fail**
  - Run `tools/linux/game-lock.sh tools/snippets/calibers/check.sh calibers/records.lua
    calibers/hitdata.lua` on the current deploy. The game must be running; start it with
    `restart-game.sh` if it isn't.
  - Expected: FAIL on the count and on the missing records.

- [ ] **Step 3: Add the rounds**
  - Add `"12mm", "762", "127"` to the `Penetrator` kind's `calibers`. Give each of the three a
    `per_caliber` entry:
    - `stats=armor(0.60) + [add("TechPierceEnabled", 1.0), mult("TechPierceChargeLevel", 0.0),
      add("TechPierceDamageFactor", 0.5)]`;
    - `desc="Tungsten-core rounds. They punch through armor and thin cover.\n\nIgnores 60% of
      armor. Goes through thin cover at half damage."`.
  - Add a `Ping` kind in the Power Rare block, right after `BallisticTip`:
    - `load="Ping"`, `title="Ping"`, `tier=RARE`, `calibers=["762", "127"]`;
    - `stats=damage(0.90)`;
    - `hit=dict(effects=[("AmmoOverhaul.PingTag", 1.0)])`;
    - `art={'tip': 'teal', 'tipfrac': 0.35}`;
    - a `look` with a teal band;
    - `desc="Rounds with a tag chip in the nose. Whatever they hit shows up on your optics for
      a few seconds, through walls.\n\nTargets hit show through walls for 5 seconds. -10%
      damage."`.
  - In `core.yaml`, add `AmmoOverhaul.PingTag` with `$base: BaseStatusEffect.KyubiMyersTag` and
    a `duration` whose value is 5. Copy the shape of the base's
    `BaseStatusEffect.KyubiMyersTag_inline0` duration record, with its stat modifier set to 5.
  - If `per_caliber` can't override `stats`, extend `rounds()` so it can, and ledger the
    change.

- [ ] **Step 4: Regenerate and compile**
  - Run `python3 tools/rounds/rounds.py` (expected: `96 rounds`).
  - Run `python3 tools/crafting/crafting.py`, then `python3 -m pytest tools/crafting -q`
    (expected: pass; update pinned counts only where they count rounds).
  - Run `tools/linux/check.sh` (expected: exit 0).

- [ ] **Step 5: Deploy and verify the checks pass**
  - `restart-game.sh --kill`, `deploy.sh`, then `restart-game.sh`.
  - Run `tools/linux/game-lock.sh tools/snippets/calibers/check.sh calibers/records.lua
    calibers/hitdata.lua calibers/tiers.lua calibers/crafting.lua calibers/distribution.lua`.
  - Expected: all pass, with no regressions in the tier shares, prices, recipes or shop splits.

- [ ] **Step 6: Commit**
  - `git add` the files above and commit with the message
    `feat: Ping rounds and cover-piercing Penetrators (records)`.

### Task 2: Icons

**Files:**
- Create: `art/icons/12mm-penetrator.png`, `762-penetrator.png`, `127-penetrator.png`,
  `762-ping.png` and `127-ping.png`
- Modify: `src/archive/AmmoOverhaul.archive`, through `tools/icons/build.sh`
- Test: `tools/snippets/calibers/icons.lua` and `tools/icons/check_parts.py`

**Interfaces:**
- **Consumes:** Task 1's art entries.
- **Produces:** icon parts `AO_12mm_Penetrator`, `AO_762_Penetrator`, `AO_127_Penetrator`,
  `AO_762_Ping` and `AO_127_Ping` in the atlas.

- [ ] **Step 1: Run the failing checks**
  - Run `python3 tools/icons/check_parts.py`.
  - Expected: FAIL, five parts missing.

- [ ] **Step 2: Render the icons and rebuild the archive**
  - Run `python3 tools/render/render.py --only
    12mm-penetrator,762-penetrator,127-penetrator,762-ping,127-ping` with the default samples,
    on the GPU (OptiX).
  - Don't render while an in-game check runs. A CPU render made the game close once.
  - Look at each png (Read) before going on: the tip color, the name on the box, and no
    clipping.
  - Then run `tools/icons/build.sh`.

- [ ] **Step 3: Verify the checks pass**
  - Run `python3 tools/icons/check_parts.py` (expected: 135 parts, PASS).
  - Kill the game, deploy, restart, then run `game-lock.sh tools/snippets/calibers/check.sh
    calibers/icons.lua` (expected: PASS).

- [ ] **Step 4: Commit**
  - Commit with the message `feat: icons for Ping and the new Penetrators`.

### Task 3: Live mechanism checks

**Files:**
- Create: `tools/snippets/calibers/ping.sh` (modelled on `hitdata.sh` and `npc-lib.sh`)
- Modify: `tools/snippets/calibers/suite.sh`, so it runs `ping.sh`

**Interfaces:**
- **Consumes:** Task 1's records. Uses the rig helpers in `npc-lib.sh` and `rig.lua` as
  `hitdata.sh` does.

- [ ] **Step 1: Write `ping.sh`**
  - **V hits the frozen rig NPC with an Ajax loaded with 7.62 Ping.** Expected:
    - right after the hit, `StatusEffectSystem.ObjectHasStatusEffect(npc,
      'AmmoOverhaul.PingTag')` is true (read it a frame later: the first read in the same frame
      returns false);
    - 7 s later it's false.
  - **A ganger fires 7.62 Ping at V, using the test kit as `hitdata.sh` does.** Expected:
    - V gets `AmmoOverhaul.PingTag`;
    - the newest redscript and CET logs show no new error during the run.
  - **An NPC is given a gun with `Items.AO_Feed_762_Penetrator`, through the NPC tier path
    `npc.sh` uses.** Expected: the stats system reads `TechPierceEnabled` = 1 on that gun.
  - **Optional:** put a car between the rig NPC and V. Spawn it as the probe did:
    `DynamicEntitySpec` with `recordID 'Vehicle.v_standard2_archer_hella_player'`, side-on,
    tagged and deleted after. Check that a Penetrator NPC shot reaches V. If the frozen NPC
    won't fire without line of sight, ledger a ruling and rely on the stat check and the
    user's probe.
  - Exit 1 on any FAIL.

- [ ] **Step 2: Run it**
  - Ask the controller whether the user is playing. Then run
    `tools/linux/game-lock.sh tools/snippets/calibers/ping.sh`.
  - Expected: PASS.
  - If tagging V errors or leaves a stuck outline: skip `PingTag` for the player in the hit
    code (`AOData.HitEffects` or the player swap in `Hooks.reds`), add a check for that, and
    ledger it.

- [ ] **Step 3: Shut the game down and commit**
  - `restart-game.sh --kill`, then commit with the message `test: live checks for Ping and the
    new Penetrators`.

### Task 4: Banner, docs and playtest steps

**Files:**
- Modify: `tools/render/banner.py` (`COLS, ROWS = 15, 9`, and the docstring)
- Regenerate: `art/banner/background-4k.png`, `main-4k.png` and `main-4k.jpg`
- Modify: `docs/CATALOG.md`, `docs/DESIGN.md`, `README.md`, `docs/NEXUS.md`, `CHANGELOG.md`
  and `docs/TESTING.md`

- [ ] **Step 1: Rebuild the banner**
  - Render the 8K title first, because the 8K files are git-ignored:
    `blender -b -P tools/render/title.py -- art/banner/title-8k.png`.
  - Then run `python3 tools/render/banner.py --title art/banner/title-8k.png`.
  - Expected: the assert passes (135 icons in 135 cells). Look at `main-4k.png` before going on.

- [ ] **Step 2: Update the docs**
  - Change 130 to 135 everywhere the round count appears (`grep -rn "130" README.md docs/NEXUS.md
    docs/CATALOG.md docs/DESIGN.md`).
  - Add the five rounds to the round lists and the NEXUS spoiler.
  - In NEXUS "Coming next", keep Legendary and faction ammo.
  - Add a `CHANGELOG.md` entry under an unreleased heading.
  - Add playtest steps 30–32 to `docs/TESTING.md`:
    - a Penetrator goes through a car with an Ajax and a Grad, and the 5.56 one doesn't;
    - a Ping hit outlines the target through walls for about 5 s;
    - an NPC Ping hit on V does nothing strange.
  - Keep NEXUS.md's plain voice: no slogans, no taglines.

- [ ] **Step 3: Commit**
  - Commit with the message `docs: 135 rounds, Ping and the new Penetrators`.

### Final review

Package the branch with
`superpowers/skills/subagent-driven-development/scripts/review-package` against `master`, then
run one fresh review on the most capable model. Fix Critical and Important findings with tests,
and ledger the minor ones. Report to the controller:
- the commits;
- the test results;
- the rulings and the deferred minors;
- that nothing is pushed.

# Free Ammo Loading and NPC Damage Parity Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** The player picks any held round on a gun's mod screen for any number of guns (selectors hidden and kept in sync), and NPC shots get their round's damage multiplier like V's.

**Architecture:** A new `SelectorSync.reds` keeps exactly one loose, `HideInBackpackUI`-tagged selector per held ammo type (fitted ones untouched), synced a frame after ammo/selector inventory events, on attach and on mod-screen open. NPC parity multiplies NPC gun hits in the existing `RollGunHit` hook by a per-ammo damage factor read from the round's selector record.

**Tech Stack:** redscript (2.50), TweakXL YAML, CET Lua test snippets driven by bash (`tools/snippets`), GE-Proton for redscript-cli.

**Spec:** `docs/superpowers/specs/2026-10-28-free-loading-npc-damage-design.md`

## Global Constraints

- Never use system wine or the game's prefix; Windows tools run via `tools/linux/*.sh` (GE-Proton, own prefix).
- One game instance. Every compile (`check.sh`), deploy, game restart and in-game test runs inside `tools/linux/game-lock.sh` (Task 0). Never deploy while the game runs: `restart-game.sh --kill`, `deploy.sh`, `restart-game.sh`.
- Never move the user's mouse; never screenshot with grim; use `tools/linux/game-shot.sh` only.
- Common rounds stay vanilla. No automatic ammo switching, ever: a fitted round that runs out stays fitted at 0.
- Selectors: tag `HideInBackpackUI`, never `HideInUI`. Weight 0, prices empty. Never in loot, vendor stock or crafting.
- Player hits are never multiplied by the damage factor (already in V's gun stats).
- Test output: `PASS <text>` / `FAIL <text>` lines and a `== <name>: N pass, M fail` summary (`slice/common.lua` `check`/`report`).
- Commits end with `Claude-Session: https://claude.ai/code/session_01JwJvEAYGPc2WFWAem67MMf`.
- Item text voice: plain gun-counter language, no invented lore (only if a task adds text; none planned).

## Review Focus

1. A gun with a fitted selector sold, dropped or stashed: the fitted selector leaves with it; the loose count per held type stays exactly 1 (Task 3 test "fitted selectors are not counted").
2. The four vanilla ammo items are Common rounds (`Ammo.HandgunAmmo` = 9mm Ball etc.): holding them must give the Common selector (Task 3 test "vanilla handgun ammo gives the 9mm Ball selector").
3. Bulk ammo pickup or purchase (many events in one frame) runs one sync, not one per event, and never loops on its own events (Task 3 test "sync count bounded").
4. Non-player instigators with guns the mod doesn't manage (turrets, drones, vehicle guns): factor 1.0 (Task 1 test "unmanaged ammo factor 1.0").
5. An NPC whose preset fits a selector (test gangers): factor from that selector, gun stats not doubled (Task 1 test via `Character.AO_Test_Ganger_9mm_Mushrooms`: `AmmoDamageFactor(LoadedAmmo)` = 1.2).

---

### Task 0: Parallel infrastructure (controller, before dispatch)

**Files:**
- Create: `tools/linux/game-lock.sh`, `tools/linux/worktree-setup.sh`

- [ ] `game-lock.sh <command...>`: runs the command under `flock` on `${TMPDIR:-/tmp}/ammo-overhaul-game.lock` (waits, prints "waiting for game lock" once), from the caller's checkout. All game/compile work goes through it.
- [ ] `worktree-setup.sh <worktree>`: symlinks the git-ignored build inputs from the main checkout into a worktree: `reference/`, `tools/redscript-cli.exe`, `tools/wolvenkit`, `tools/wolvenkit-win`, `tools/linux/launch-lutris.sh`.
- [ ] Verify: in a fresh worktree, `tools/linux/game-lock.sh tools/linux/check.sh` compiles. Commit.

### Task 1: NPC damage parity

**Files:**
- Modify: `src/scripts/AmmoOverhaul/AOData.reds` (factor lookup), `src/scripts/AmmoOverhaul/AmmoFeedSystem.reds` (`RollGunHit`, cache, debug), `docs/DESIGN.md` (parity section, stat audit; remove the Known-gaps bullet about NPC `DamagePerHit` 0)
- Test: `tools/snippets/calibers/parity.lua` (static), `tools/snippets/calibers/parity.sh` (live)

**Interfaces:**
- Produces: `AOData.SelectorForAmmo(ammo: TweakDBID) -> TweakDBID` (first selector across all calibers whose `selectorAmmo` entry is `ammo`; invalid if none). `AOData.AmmoDamageFactor(ammo: TweakDBID) -> Float` (product of `DamagePerHit` `Multiplier` constant modifiers on that selector; 1.0 if none). `AmmoFeedSystem.DamageFactor(ammo: TweakDBID) -> Float` (cached, keyed like `m_calibers`). `AmmoFeedSystem.DebugDamageFactor(ammo: String) -> String`.

- [ ] **Step 1: Write `parity.lua`** (run with `tools/snippets/calibers/check.sh calibers/parity.lua`):
  - `DebugDamageFactor` equals, within 0.001: `Ammo.AO_S10_Dumbfire` 1.8, `Ammo.AO_S20_Dumbfire` 1.8, `Ammo.AO_S25_Dumbfire` 1.8, `Ammo.AO_9mm_HollowPoint` 1.2, `Ammo.AO_4ga_Slug` 1.3, `Ammo.AO_45_Ball` 1.0, `Ammo.HandgunAmmo` 1.0, and an unmanaged ammo `Ammo.Special_Missile` (or any non-AO ammo record) 1.0 ("unmanaged ammo factor 1.0").
  - For every caliber's tier-1 ammo, factor equals the product of its selector's `DamagePerHit` Multiplier values read in Lua (generic, so future rounds are covered).
  - The test ganger `Character.AO_Test_Ganger_9mm_Mushrooms`, spawned, reports `LoadedAmmo` factor 1.2 and its gun's `DamagePerHit` stat still 0 (no double application).
- [ ] **Step 2: Run, expect FAIL** (`DebugDamageFactor` doesn't exist → runtime error lines count as FAIL).
- [ ] **Step 3: Implement** the Produces block; in `RollGunHit`, when `instigator` is not the player (`!instigator.IsPlayer()`), multiply every `MultAttackValue` factor by `system.DamageFactor(ammo)`.
- [ ] **Step 4: Write `parity.sh`** (live, gating): reuse `rig.lua`'s NPC-shoots-V phase with a 9mm Lexington ganger forced to Mushrooms (respawn until it carries `Ammo.AO_9mm_HollowPoint`, as `slice/npcdrop.sh` does; restore `npcUncommonFactor` flats after). PASS when ≥ 10 NPC hits on V and every ratio is in 1.2 × [0.898, 1.012]; a second phase with the roll factor off (factor 0 → Common round) gives ratios in [0.898, 1.012]. And a V phase: V's Mushrooms hits on the NPC stay in [0.898, 1.012] ("V's Uncommon hits are not multiplied twice").
- [ ] **Step 5: Run both under the lock** after deploy: `tools/linux/game-lock.sh bash -c 'tools/linux/restart-game.sh --kill; tools/linux/deploy.sh && tools/linux/restart-game.sh && tools/snippets/calibers/all-pass.sh "tools/snippets/calibers/check.sh calibers/parity.lua" tools/snippets/calibers/parity.sh'`. Expected: all PASS.
- [ ] **Step 6: Stat audit** in `docs/DESIGN.md`: list every stat type any selector modifies (read from the YAML) with how it reaches NPCs (measured on an NPC gun by an existing/new check, fixed in the hook, or irrelevant with reason). Any stat found broken like damage gets the same hook treatment plus a check in `parity.lua`.
- [ ] **Step 7: Commit.**

### Task 2: Hidden selectors

**Files:**
- Modify: every selector record in `src/tweaks/AmmoOverhaul/{power_*,tech_*,smart_*}.yaml` (tags, weight), `src/scripts/AmmoOverhaul/Hooks.reds` only if a screen needs a filter
- Test: `tools/snippets/calibers/hidden.lua`

**Interfaces:**
- Produces: every record listed in any `AmmoOverhaul.<cal>.selectors` has tags `itemPart`, `AO_AmmoSelector`, `HideInBackpackUI`, not `HideInUI`, and `Weight` stat 0 on a spawned item. `AOData.IsSelector(item: ItemID) -> Bool` (tag `AO_AmmoSelector`) for any filter wraps.

- [ ] **Step 1: Write `hidden.lua`**: for every caliber's selectors: has `HideInBackpackUI`, lacks `HideInUI`, empty buy/sell price lists. Give V one `Items.AO_Feed_9mm_Mushrooms`: its Weight stat reads 0; the backpack's data path excludes it (`InventoryDataManagerV2` backpack list or `backpack_main` filter by tag, whichever the code can call); `InventoryDataManagerV2.GetPlayerInventoryPartsForItemRef` for a held Lexington's feed slot includes it (mod screen still sees it); the vendor sell list for a vendor (`Vendors.reds` test helpers or `MarketSystem`/`VendorDataManager` list) excludes it; the crafting/dismantle list excludes it.
- [ ] **Step 2: Run under the lock, expect FAIL** on the tag/weight checks.
- [ ] **Step 3: Implement**: add `HideInBackpackUI` to every selector's `tags`; set weight 0 (a `Weight` stat modifier override on the selector if `Items.Part` gives weight). For each screen still listing a selector, wrap that screen's list builder to drop `AO_AmmoSelector` items.
- [ ] **Step 4: Run under the lock** (deploy first, as Task 1 Step 5). Expected: all PASS; also `check.sh calibers/records.lua` still all PASS.
- [ ] **Step 5: Commit.**

### Task 3: Selector sync

**Files:**
- Create: `src/scripts/AmmoOverhaul/SelectorSync.reds` (all sync code and its hooks/events, so it doesn't collide with Tasks 1-2)
- Test: `tools/snippets/calibers/sync.lua`, `tools/snippets/calibers/sync.sh`

**Interfaces:**
- Consumes: `AOData.Calibers()`, `AOData.Selectors(caliber)`, `AOData.SelectorAmmo(caliber, selector)`, `AOData.SelectedAmmo`.
- Produces: `public class SelectorSync` with `static func Request(player: ref<PlayerPuppet>) -> Void` (schedule a coalesced sync next frame; no-op if one is pending) and `static func Run(player: ref<PlayerPuppet>) -> Int32` (apply the rule now; returns items added + removed). `AmmoFeedSystem.DebugSyncCount() -> Int32` (syncs run since attach) and `DebugLooseSelectors() -> String` ("<selector>=<n> ..." for loose selectors in V's inventory).

- [ ] **Step 1: Write `sync.lua` / `sync.sh`** (one CET call per state change; wait ≥ 1 s between give and check). Checks:
  - "new ammo adds its selector": give 30 `Ammo.AO_9mm_HollowPoint` → exactly 1 loose `Items.AO_Feed_9mm_Mushrooms`.
  - "ammo at 0 removes it": remove all of it → 0 loose.
  - "vanilla handgun ammo gives the 9mm Ball selector": hold `Ammo.HandgunAmmo` → 1 loose `Items.AO_Feed_9mm_Ball`.
  - "same round on two guns": two Lexingtons; install the loose Mushrooms selector on gun A (`ItemModificationSystem` install, as `tools/snippets/set-feed.lua`); after sync 1 loose again; install it on gun B; both guns' `SelectedAmmo` = `Ammo.AO_9mm_HollowPoint`; 1 loose.
  - "fitted selectors are not counted": with Mushrooms fitted on A and B, loose Mushrooms = 1.
  - "run out keeps the round": remove all Mushrooms ammo; gun A still has `Items.AO_Feed_9mm_Mushrooms` fitted, `SelectedAmmo` unchanged, `SelectedAmmoCount` 0; 0 loose.
  - "removing the round loads Common": remove gun B's feed part → `SelectedAmmo` = `Ammo.HandgunAmmo` (9mm's default).
  - "old-save cleanup": give 3 extra loose `Items.AO_Feed_9mm_Ball` and 2 `Items.AO_Feed_45_Mushrooms` with no .45 Mushrooms held → after sync 1 and 0.
  - "sync count bounded": `DebugSyncCount` delta over giving 10 ammo types in one call is ≤ 3.
  - "open mod screen refreshes": open the mod screen on a Lexington (hub menu `inventory_screen`, then the weapon), give `Ammo.AO_9mm_PlusP`, read the feed slot's choice list from the open chooser (`InventoryDataManagerV2.GetPlayerInventoryPartsForItemRef`) → includes `Items.AO_Feed_9mm_PlusP`; close with `ForceCloseHubMenuEvent`. If the chooser's list doesn't refresh, the implementation triggers its refresh after a sync.
- [ ] **Step 2: Run under the lock, expect FAIL** (no sync exists: no selector appears).
- [ ] **Step 3: Implement** `SelectorSync.reds`: rule per spec; triggers: player `ItemAddedEvent`/`ItemChangedEvent` (wrap the player's handlers) for items tagged `AO_Ammo` or `AO_AmmoSelector`, `AmmoFeedSystem.OnPlayerAttach`, mod screen open (`InventoryWeaponItemChooser` or the screen's init). Run next frame via `DelaySystem` (`DelayCallback`, 0.0 s or `QueueTick`), one pending at a time; a sync that changes nothing schedules nothing.
- [ ] **Step 4: Run under the lock** (deploy first). Expected: all PASS; `tools/snippets/slice/uncommon.sh` and `calibers/uncommon2.sh` still pass (they hand out selectors themselves; adapt them only if the sync now trims what they give, and ledger it).
- [ ] **Step 5: Commit.**

### Task 4: Integration (controller, after Tasks 1-3)

- [ ] Merge the three task branches into `free-loading`; resolve conflicts.
- [ ] `suite.sh`: add `calibers/parity.lua`, `parity.sh`, `hidden.lua`, `sync.sh` as gating steps.
- [ ] `docs/DESIGN.md`: "Selectors" section for the sync and hiding (Task 1 already wrote parity); `docs/TESTING.md`: new checks.
- [ ] Full suite on a fresh restart, all gating PASS. Commit.

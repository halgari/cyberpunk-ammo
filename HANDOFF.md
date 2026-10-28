# Ammo Overhaul: handoff (2026-10-27)

> **Historical.** This is the snapshot from the move off the Windows VM, when the mod used a
> hidden ammo pool; that design was dropped. Current design: `docs/DESIGN.md`. Current dev loop
> (Linux, Lutris/GE-Proton): `docs/TESTING.md`. The setup notes below for the frameworks, the
> test save and the CET harness still apply; the status, open problems and the file appendix
> don't.

Moved off the vmctl VM (Intel Arc SR-IOV share: the game's GPU crashes kept taking down the
Looking Glass display driver). Everything needed to continue is in this repo except the large or
third-party bits listed under "Setting up a new machine".

## Where the proof of concept stands

Target: Lexington only, one ammo-feed slot, FMJ (vanilla `Ammo.HandgunAmmo`) and 9mm Incendiary.

Verified in game (2.50 / exe 3.0.88):

- TweakXL loads `poc_9mm.yaml` cleanly; `AmmoFeedTweak` repoints all 63 Lexington variants
  (player and NPC) at `Ammo.AO_Pool_Power_9mm` and adds the feed slot to their blueprints.
- The "Ammo Feed" slot shows in the mod screen; only the two selectors fit, and they don't fit
  the vanilla mod slots. Slot label now comes from the slot record's `localizedName`
  (`UIItemsHelper.GetSlotName`/`GetEmptySlotName` wraps) instead of the generic "Mod".
- Switching feeds swaps which stack the HUD/reload uses: FMJ and no-feed both show the normal
  9mm count and reload from it; Incendiary shows the incendiary count; an empty selected stack
  can't be reloaded.
- On-hit: incendiary hits set enemies on fire.

Fixed during testing (all in `AmmoFeedSystem.reds`):

- Reloading a save (e.g. after dying) attaches the new player before the old one detaches; the
  detach handler used to wipe the new state. It now ignores players it isn't tracking.
- Reconcile used a "queued" flag + `DelayCallbackNextFrame`. A queued callback got dropped
  (while the mod screen had the game paused) and the flag then blocked every later reconcile:
  the pool froze at 0 and nothing could be loaded. Now debounced: each event cancels the pending
  `DelayCallback(cb, 0.0, false)` and queues a fresh one.

## Open problems (next steps)

1. **Confirm when the engine takes ammo out of the inventory.** The design assumes per shot (so
   the inventory count includes loaded rounds and emptying the magazine "returns" them). The
   last run hinted it may be on reload instead: after swapping Incendiary -> FMJ the auto-reload
   took 15 normal rounds (336 -> 321) and the 5 incendiary rounds were gone. Test: with FMJ,
   note HUD mag/reserve and inventory `Ammo.HandgunAmmo`, fire 3 shots, read again.
   - If per reload: `EmptyMagazine` must give unfired rounds back to the stack they were loaded
     from (`LoadedAmmo(weaponID)` already knows which), and the reconcile's "pool went down =
     fired" reading is really "pool went down = loaded into a magazine".
2. **Factory magazine on first sight.** A newly spawned gun comes with a full free magazine.
   `SetLoaded` trusts that a weapon seen for the first time is loaded with its current
   selection, so installing Incendiary before ever drawing a new gun gave 20 free "incendiary"
   rounds. Fix: on first sight, if the selection isn't the default ammo (or the stack has fewer
   rounds than the magazine), empty the magazine.
3. `ModLog` output wasn't found in any log; diagnostics so far were read live via the CET harness.
4. `docs/DESIGN.md`'s data-model section still describes the old `ao*` flats on weapon records;
   the data now lives in standalone `AmmoOverhaul.*` flats (see `poc_9mm.yaml`, `AOData.reds`).
5. NPC weapons share the pool record. Harmless today (NPCs don't use inventory ammo; reloads are
   free), but relevant to the NPC-ammo plans (see DESIGN.md / chat notes: `AIAmmoCountCond`,
   `AISubActionReloadWeapon`, loot via `dropsAmmoOnDeathChance`, faction via `Affiliation()`).

## Repo layout

- `src/tweaks/AmmoOverhaul/poc_9mm.yaml`: records plus `AmmoOverhaul.*` settings (calibers,
  pools, selectors, on-hit effects). Data-driven: adding a caliber/ammo type should only need YAML.
- `src/scripts/AmmoOverhaul/`: `AOData` (settings access), `AmmoFeedTweak` (TweakDB patching at
  load), `AmmoFeedSystem` (pool reconcile + on-hit), `Hooks` (wraps), `Localization` (Codeware).
- `tools/package.ps1 [-Deploy]`: builds `dist/AmmoOverhaul.zip`; `-Deploy` copies into the game.
- `tools/check.ps1`: offline compile check with redscript-cli.
- `tools/cet.ps1` + `tools/harness/init.lua`: run Lua in the live game (`.\cet.ps1 'print(1)'`).
- `tools/dev-install.ps1 [-Remove]`: dev helpers: intro skip, autoload of a named save
  (`tools/dev-scripts`), the CET harness, and a desktop shortcut with `--launcher-skip -skipStartScreen`.
- `tools/restart-game.ps1`: kill + relaunch + wait until a save is loaded. Launches via an
  interactive scheduled task (needed on the VM where the agent shell was session 0; harmless locally).
- `tools/collect-logs.ps1`: zips game/framework logs to the Desktop.

All scripts default to `C:\Program Files\GOG Galaxy\Games\Cyberpunk 2077`; pass `-GameDir` otherwise.

## Setting up a new machine

Every file in this repo is reproduced in full in the appendix at the end of this document, so
the doc alone is enough to recreate the project: create each file at the path in its heading.
Write them as UTF-8 **without a BOM** (redscript rejects a BOM).

### 1. Game and frameworks

Cyberpunk 2077 2.50 (GOG; exe 3.0.88) with Phantom Liberty, plus these versions, all extracted
into the game folder (`tools/installed-frameworks.tsv` lists every file each one installed):

| Framework | Version | Source |
|---|---|---|
| RED4ext | 1.31.0 | github.com/WopsS/RED4ext releases |
| redscript | 0.5.32 | github.com/jac3km4/redscript releases |
| TweakXL | 1.12.0 | github.com/psiberx/cp2077-tweak-xl releases |
| ArchiveXL | 1.28.1 | github.com/psiberx/cp2077-archive-xl releases |
| Codeware | 1.21.1 | github.com/psiberx/cp2077-codeware releases |
| Cyber Engine Tweaks | 1.38.1 | github.com/maximegmd/CyberEngineTweaks releases |

For the offline compile check (`tools/check.ps1`), also (gitignored, not in the appendix):

- `tools/redscript-cli.exe`: the `redscript-cli` asset of the same redscript 0.5.32 release.
- `reference/final.redscripts.vanilla`: a copy of the unmodded `r6/cache/final.redscripts`.
  Once redscript is installed, the original is kept as `r6/cache/final.redscripts.bk`.
- `reference/scripts/` (optional): the decompiled vanilla scripts, for reading and grepping only.
  Any 2.x-era dump works.

### 2. Build and deploy the mod

```powershell
.\tools\check.ps1            # offline compile check (needs the two gitignored files above)
.\tools\package.ps1 -Deploy  # dist\AmmoOverhaul.zip + copies r6\scripts\AmmoOverhaul and r6\tweaks\AmmoOverhaul into the game
```

All scripts default to `C:\Program Files\GOG Galaxy\Games\Cyberpunk 2077`; pass `-GameDir "<path>"` otherwise.

### 3. The test save

- Source: Nexus Mods, Cyberpunk 2077 mod **5285** ("vanilla" save collection), file
  **"Corpo F"** (game 2.21; archive `Corpo F-5285-2-21-1750632856.7z`). Unmodded, Easy difficulty.
- Inside it, use the folder **`Corpo\Act 2 After Heroes (suggested)`**: Corpo, female, level 11,
  right after the heist, quest "meet with Takemura". It's a good spot: you're free to roam and
  have handgun ammo. (`Corpo\Act 2 Wake Up` is a level-10 save from just before; it was installed
  as `ManualSave-901` as a spare.)
- Copy that folder (it holds `sav.dat`, `metadata.9.json`, `screenshot.png`) into
  `%USERPROFILE%\Saved Games\CD Projekt Red\Cyberpunk 2077\` and **rename it `ManualSave-900`**.
  The game lists any `ManualSave-<n>` folder; 900 just keeps clear of your own saves. Loading a
  2.21 save in 2.50 is fine.

### 4. Boot straight into the save (dev helpers)

```powershell
.\tools\dev-install.ps1          # install
.\tools\dev-install.ps1 -Remove  # uninstall all of it
```

This installs four things:

1. `r6\scripts\AODev\NoIntroVideos.reds`: skips the logo and intro videos. Copied verbatim from
   Nexus mod **533** "No Intro Videos", file "No Intro Videos - redscript" v0.8 (file id 124614).
   It needs Codeware.
2. `r6\scripts\AODev\AODevAutoload.reds`: as soon as the main menu has listed the saves, it
   loads the one whose name contains `ManualSave-900` (falling back to the newest). It only fires
   once per game launch, so going back to the main menu doesn't reload. Change the target in
   `AODevAutoloadTarget()`. It's adapted from the optional "Autoload Latest Save" file (v0.4,
   file id 60078) of the same Nexus mod 533; that one always loads the newest save.
3. The CET harness mod (`bin\x64\plugins\cyber_engine_tweaks\mods\AOHarness\init.lua`), see
   below.
4. A desktop shortcut **"Cyberpunk 2077 (dev)"** running `bin\x64\Cyberpunk2077.exe --launcher-skip -skipStartScreen`.
   `--launcher-skip` bypasses the REDlauncher and `-skipStartScreen` skips the "press any key /
   Breaching" screen. **Launch from this shortcut**: starting from GOG Galaxy doesn't pass the
   arguments, unless you add them under Galaxy -> game -> Manage installation -> Configure ->
   Additional launch arguments.

Net effect: double-click the shortcut and you land in the save with no input, in about 30-60 s.

`tools/restart-game.ps1` scripts the whole loop: it kills the game, relaunches it, and waits
until a save is loaded and the harness answers. It launches through an interactive scheduled
task because on the VM the agent's shell was in session 0. Locally,
`Start-Process` on the shortcut would do the same.

### 5. Driving the game from a script: the CET harness

`tools/harness/init.lua` is a tiny CET mod. Every 0.5 s it checks `cmd.lua` in its folder. When
the first line (`-- id: <x>`) changes, it runs the rest of the file and appends the output to
`out.log` between `@@begin <x>` / `@@end <x>`. Inside the code, `print` writes there, and
returned values are printed as `=> value`. `tools/cet.ps1` wraps this:

```powershell
.\tools\cet.ps1 'return Game.GetPlayer() ~= nil'
.\tools\cet.ps1 -File snippet.lua -TimeoutSec 30
.\tools\cet.ps1 -Install   # (re)deploy the harness; takes effect on the next launch (or CET "Reload all mods")
```

It only runs while the game window is updating: a paused or unfocused game, or a loading screen,
gives "no response". Anything that can write that folder can run code in the game, so keep it
dev-only.

Snippets used during testing (paste into `.\tools\cet.ps1 @' ... '@` or the CET console):

```lua
-- Is a save actually loaded? (the main menu has its own player puppet, so check pre-game)
return tostring(Game.GetSystemRequestsHandler():IsPreGame()) .. " " .. tostring(Game.GetPlayer() ~= nil)
-- "false true" = in a save. Give OnPlayerAttach another ~15-20 s after that.
```

```lua
-- Give the test kit
Game.AddToInventory("Items.Preset_Lexington_Default", 1)
Game.AddToInventory("Ammo.AO_9mm_Incendiary", 5)
Game.AddToInventory("Items.AO_Feed_9mm_FMJ", 1)
Game.AddToInventory("Items.AO_Feed_9mm_Incendiary", 1)
```

```lua
-- Ammo counts + the feed system's internal state
local ts = Game.GetTransactionSystem(); local p = Game.GetPlayer()
local function count(id) return ts:GetItemQuantity(p, ItemID.FromTDBID(TweakDBID.new(id))) end
print("handgun", count("Ammo.HandgunAmmo"), "incend", count("Ammo.AO_9mm_Incendiary"), "pool", count("Ammo.AO_Pool_Power_9mm"))
local w = p:GetActiveWeapon()
if w then print("weapon", TDBID.ToStringDEBUG(w:GetItemID().id), "mag", WeaponObject.GetMagazineAmmoCount(w), "ammoType", TDBID.ToStringDEBUG(WeaponObject.GetAmmoType(w).id)) end
print(Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem"))
-- player:NULL / pools:Array[] = not attached (yet). reconcileQueued/pending stuck = reconcile not running.
```

```lua
-- Every ammo / AO item in the inventory. Parts carry random seeds, so GetItemQuantity(FromTDBID)
-- reports 0 for them; list them instead
local ts = Game.GetTransactionSystem(); local p = Game.GetPlayer()
local ok, items = ts:GetItemList(p)
for _,d in ipairs(items) do
  local n = TDBID.ToStringDEBUG(d:GetID().id)
  if n:find("Ammo") or n:find("AO_") or n:find("Lexington") then print(n, d:GetQuantity()) end
end
```

```lua
-- TweakDB patch check: Lexington variants on the pool, blueprint has the feed slot, records exist
print("calibers", TweakDB:GetFlat("AmmoOverhaul.calibers"))
print("lex ammo", TweakDB:GetFlat("Items.Preset_Lexington_Default.ammo"))
local n = 0
for _,r in ipairs(TweakDB:GetRecords("gamedataWeaponItem_Record")) do
  local a = r:Ammo()
  if a and a:GetID() == TweakDBID.new("Ammo.AO_Pool_Power_9mm") then n = n + 1 end
end
print("weapons on pool", n)   -- 63 on 2.50
local root = TweakDB:GetRecord("Items.Preset_Lexington_Default"):Blueprint():RootElement()
for _,c in ipairs(root:ChildElements()) do local s = c:Slot(); print("  slot", s and s:GetID().value) end
print("records", TweakDB:GetRecord("Ammo.AO_Pool_Power_9mm") ~= nil, TweakDB:GetRecord("Ammo.AO_9mm_Incendiary") ~= nil, TweakDB:GetRecord("AttachmentSlots.AO_AmmoFeed_Power_9mm") ~= nil)
```

```lua
-- Localization check (Codeware). Slot labels resolve via the slot record's localizedName
print(GetLocalizedTextByKey("AO-Slot-AmmoFeed"))                                                         -- Ammo Feed
print(GetLocalizedText(TweakDB:GetRecord("AttachmentSlots.AO_AmmoFeed_Power_9mm"):LocalizedName()))      -- Ammo Feed
print(GetLocalizedText(UIItemsHelper.GetSlotName(TweakDBID.new("AttachmentSlots.AO_AmmoFeed_Power_9mm"), gamedataItemType.Prt_Mod, gamedataEquipmentArea.Invalid)))
```

```lua
-- Force a reconcile by hand (what the debounced DelayCallback does)
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
local cb = NewObject("AmmoOverhaul.AmmoFeedReconcileCallback"); cb.system = sys
Game.GetDelaySystem():DelayCallbackNextFrame(cb)
```

### 6. Other machine settings used on the VM

- To survive the 6 GiB VRAM share, `%LOCALAPPDATA%\CD Projekt Red\Cyberpunk 2077\UserSettings.json`
  was lowered: 30 FPS cap, Medium textures/LOD/GI, Low shadows/SSR/SSS/AO/decals/mirrors,
  anisotropy 4, contact shadows and facial tangents off. A local GPU won't need this.

Gotchas learned: write files without a BOM (redscript chokes); TweakXL rejects unknown
properties on existing record types; wait for `IsPreGame() == false` *and* a few more seconds
before expecting `OnPlayerAttach` (the main menu has its own player puppet).

## Appendix: every file in the repo

Paths are relative to the repo root. `.reds` is tagged as Swift purely for highlighting.

### `.gitignore`

```text
# Decompiled vanilla scripts and game binaries (CDPR content, regenerable)
reference/
tools/*.exe
dist/
```

### `src/tweaks/AmmoOverhaul/poc_9mm.yaml`

```yaml
# Proof of concept: one caliber (Power 9mm), one gun family (Lexington), two ammo types.
#
# How the pieces fit:
#   - Each caliber has a hidden pool ammo item. The scriptable tweak (AmmoFeedTweak.reds) points
#     every weapon carrying one of the caliber's weaponTags at the pool (its `ammo` flat) and at a
#     clone of its blueprint with the caliber's feed slot added.
#   - The player picks the loaded ammo by installing a selector part in that feed slot. Each
#     selector maps to a real ammo stack; an empty slot falls back to defaultAmmo.
#   - At runtime AmmoFeedSystem keeps the pool's quantity equal to the selected stack and removes
#     whatever the engine consumes from the pool from that stack.
#
# TweakXL rejects unknown properties on existing record types, so the mod's own settings live in
# the AmmoOverhaul.* flats below, keyed by short names, rather than on the item records.

# --- Mod settings ------------------------------------------------------------------------------

AmmoOverhaul.calibers: ["Power_9mm"]

AmmoOverhaul.Power_9mm.pool: "Ammo.AO_Pool_Power_9mm"
AmmoOverhaul.Power_9mm.weaponTags: ["Lexington"]
AmmoOverhaul.Power_9mm.feedSlot: "AttachmentSlots.AO_AmmoFeed_Power_9mm"
AmmoOverhaul.Power_9mm.feedElement: "Items.AO_AmmoFeed_Power_9mm_Element"
AmmoOverhaul.Power_9mm.defaultAmmo: "Ammo.HandgunAmmo"
# Parallel lists: selector part -> ammo stack it feeds. FMJ is vanilla handgun ammo, so loot
# and vendors keep working.
AmmoOverhaul.Power_9mm.selectors: ["Items.AO_Feed_9mm_FMJ", "Items.AO_Feed_9mm_Incendiary"]
AmmoOverhaul.Power_9mm.selectorAmmo: ["Ammo.HandgunAmmo", "Ammo.AO_9mm_Incendiary"]

AmmoOverhaul.ammoEffects: ["Incendiary_9mm"]

AmmoOverhaul.Incendiary_9mm.ammo: "Ammo.AO_9mm_Incendiary"
AmmoOverhaul.Incendiary_9mm.effect: "BaseStatusEffect.Burning"
AmmoOverhaul.Incendiary_9mm.chance: 1.0

# --- Feed slot -------------------------------------------------------------------------------

AttachmentSlots.AO_AmmoFeed_Power_9mm:
  $base: AttachmentSlots.Power_Handgun_WeaponMod1
  entitySlotName: AO_AmmoFeed_Power_9mm
  unlockedBy: Common
  localizedName: LocKey#AO-Slot-AmmoFeed

# No quality prereq, so the slot exists on every quality of the gun.
Items.AO_AmmoFeed_Power_9mm_Element:
  $type: ItemBlueprintElement
  slot: AttachmentSlots.AO_AmmoFeed_Power_9mm

# --- Hidden engine pool ------------------------------------------------------------------------

Ammo.AO_Pool_Power_9mm:
  $base: Ammo.HandgunAmmo
  displayName: LocKey#AO-Ammo-Pool-9mm
  localizedDescription: LocKey#AO-Ammo-Pool-9mm
  # Deliberately not tagged Ammo/HandgunAmmo, so tag-based ammo counts don't see it twice.
  tags: [AO_AmmoPool, HideInUI, HideInBackpackUI, SkipActivityLog, SkipActivityLogOnLoot, SkipActivityLogOnRemove]
  buyPrice: []
  sellPrice: []
  # Larger than any variant stack so the mirror never clips.
  statModifiers:
    - $type: ConstantStatModifier
      statType: BaseStats.Quantity
      modifierType: Additive
      value: 9998

# --- Ammo variants -----------------------------------------------------------------------------

Ammo.AO_9mm_Incendiary:
  $base: Ammo.HandgunAmmo
  displayName: LocKey#AO-Ammo-9mm-Incendiary
  localizedDescription: LocKey#AO-Ammo-9mm-Incendiary-Desc
  tags: [Ammo, ShowStackPrice, AO_Ammo]

# --- Selector parts ----------------------------------------------------------------------------

Items.AO_Feed_9mm_FMJ:
  $base: Items.Part
  displayName: LocKey#AO-Feed-9mm-FMJ
  localizedDescription: LocKey#AO-Feed-9mm-FMJ-Desc
  itemType: ItemType.Prt_Magazine
  quality: Quality.Common
  iconPath: mod_generic
  placementSlots: [AttachmentSlots.AO_AmmoFeed_Power_9mm]
  tags: [itemPart, AO_AmmoSelector]
  buyPrice: []
  sellPrice: []

Items.AO_Feed_9mm_Incendiary:
  $base: Items.Part
  displayName: LocKey#AO-Feed-9mm-Incendiary
  localizedDescription: LocKey#AO-Feed-9mm-Incendiary-Desc
  itemType: ItemType.Prt_Magazine
  quality: Quality.Common
  iconPath: mod_generic
  placementSlots: [AttachmentSlots.AO_AmmoFeed_Power_9mm]
  tags: [itemPart, AO_AmmoSelector]
  buyPrice: []
  sellPrice: []
```

### `src/scripts/AmmoOverhaul/AOData.reds`

```swift
module AmmoOverhaul

// Reads the mod's settings from TweakDB. Everything about calibers, slots and ammo types lives in
// the AmmoOverhaul.* flats in r6/tweaks/AmmoOverhaul; nothing here is specific to a gun or ammo
// type. Settings are keyed by short names (AmmoOverhaul.<caliber>.<field>) because TweakXL
// doesn't allow extra properties on existing record types.
public abstract class AOData {

  private static func Key(name: String, field: String) -> TweakDBID {
    return TDBID.Create("AmmoOverhaul." + name + "." + field);
  }

  // Record references are written as quoted strings, but accept foreign keys too in case
  // TweakXL types them that way.
  private static func GetID(path: TweakDBID) -> TweakDBID {
    let value: String = TweakDBInterface.GetString(path, "");
    if StrLen(value) > 0 {
      return TDBID.Create(value);
    }
    return TweakDBInterface.GetForeignKey(path, TDBID.None());
  }

  private static func GetIDs(path: TweakDBID) -> array<TweakDBID> {
    let ids: array<TweakDBID>;
    for value in TweakDBInterface.GetStringArray(path) {
      ArrayPush(ids, TDBID.Create(value));
    }
    if ArraySize(ids) == 0 {
      ids = TweakDBInterface.GetForeignKeyArray(path);
    }
    return ids;
  }

  private static func GetNames(path: TweakDBID) -> array<CName> {
    let names: array<CName>;
    for value in TweakDBInterface.GetStringArray(path) {
      ArrayPush(names, StringToName(value));
    }
    if ArraySize(names) == 0 {
      names = TweakDBInterface.GetCNameArray(path);
    }
    return names;
  }

  private static func GetStrings(path: TweakDBID) -> array<String> {
    let values: array<String> = TweakDBInterface.GetStringArray(path);
    if ArraySize(values) == 0 {
      for name in TweakDBInterface.GetCNameArray(path) {
        ArrayPush(values, NameToString(name));
      }
    }
    return values;
  }

  // Appends ".<field>" to a record ID, for reading a record's own flats.
  public static func Flat(record: TweakDBID, field: String) -> TweakDBID {
    let path: TweakDBID = record;
    TDBID.Append(path, TDBID.Create("." + field));
    return path;
  }

  // --- Calibers ------------------------------------------------------------------------------

  public static func Calibers() -> array<String> {
    return AOData.GetStrings(t"AmmoOverhaul.calibers");
  }

  public static func Pool(caliber: String) -> TweakDBID {
    return AOData.GetID(AOData.Key(caliber, "pool"));
  }

  public static func Pools() -> array<TweakDBID> {
    let pools: array<TweakDBID>;
    for caliber in AOData.Calibers() {
      ArrayPush(pools, AOData.Pool(caliber));
    }
    return pools;
  }

  // The caliber whose pool this is, or "" if it isn't one.
  public static func CaliberOfPool(pool: TweakDBID) -> String {
    if TDBID.IsValid(pool) {
      for caliber in AOData.Calibers() {
        if AOData.Pool(caliber) == pool {
          return caliber;
        }
      }
    }
    return "";
  }

  public static func WeaponTags(caliber: String) -> array<CName> {
    return AOData.GetNames(AOData.Key(caliber, "weaponTags"));
  }

  public static func FeedElement(caliber: String) -> TweakDBID {
    return AOData.GetID(AOData.Key(caliber, "feedElement"));
  }

  public static func FeedSlot(caliber: String) -> TweakDBID {
    return AOData.GetID(AOData.Key(caliber, "feedSlot"));
  }

  public static func DefaultAmmo(pool: TweakDBID) -> TweakDBID {
    let caliber: String = AOData.CaliberOfPool(pool);
    return StrLen(caliber) > 0 ? AOData.GetID(AOData.Key(caliber, "defaultAmmo")) : TDBID.None();
  }

  // The ammo stack a selector part feeds, or an invalid ID if it isn't one of this caliber's.
  public static func SelectorAmmo(caliber: String, selector: TweakDBID) -> TweakDBID {
    let selectors: array<TweakDBID> = AOData.GetIDs(AOData.Key(caliber, "selectors"));
    let ammo: array<TweakDBID> = AOData.GetIDs(AOData.Key(caliber, "selectorAmmo"));
    let i: Int32 = 0;
    while i < ArraySize(selectors) && i < ArraySize(ammo) {
      if selectors[i] == selector {
        return ammo[i];
      }
      i += 1;
    }
    return TDBID.None();
  }

  public static func IsPool(ammo: TweakDBID) -> Bool {
    return StrLen(AOData.CaliberOfPool(ammo)) > 0;
  }

  // The pool a weapon record draws from, or an invalid ID if the weapon isn't managed.
  public static func PoolForWeapon(weapon: TweakDBID) -> TweakDBID {
    let record: ref<WeaponItem_Record> = TweakDBInterface.GetWeaponItemRecord(weapon);
    if !IsDefined(record) || !IsDefined(record.Ammo()) {
      return TDBID.None();
    }
    let ammo: TweakDBID = record.Ammo().GetID();
    return AOData.IsPool(ammo) ? ammo : TDBID.None();
  }

  public static func FeedSlots() -> array<TweakDBID> {
    let slots: array<TweakDBID>;
    for caliber in AOData.Calibers() {
      ArrayPush(slots, AOData.FeedSlot(caliber));
    }
    return slots;
  }

  public static func IsFeedSlot(slot: TweakDBID) -> Bool {
    let slots: array<TweakDBID> = AOData.FeedSlots();
    return TDBID.IsValid(slot) && ArrayContains(slots, slot);
  }

  public static func AppendFeedSlots(out slots: array<TweakDBID>) -> Void {
    for slot in AOData.FeedSlots() {
      if !ArrayContains(slots, slot) {
        ArrayPush(slots, slot);
      }
    }
  }

  // The ammo stack selected by the part in the weapon's feed slot; the caliber's default ammo
  // when the slot is empty. Invalid when nothing is selected and there is no default.
  public static func SelectedAmmo(owner: ref<GameObject>, weaponID: ItemID, pool: TweakDBID) -> TweakDBID {
    let caliber: String = AOData.CaliberOfPool(pool);
    if StrLen(caliber) == 0 {
      return TDBID.None();
    }
    let itemData: wref<gameItemData> = GameInstance.GetTransactionSystem(owner.GetGame()).GetItemData(owner, weaponID);
    let slot: TweakDBID = AOData.FeedSlot(caliber);
    let part: InnerItemData;
    let ammo: TweakDBID;
    if IsDefined(itemData) && itemData.HasPartInSlot(slot) {
      itemData.GetItemPart(part, slot);
      ammo = AOData.SelectorAmmo(caliber, ItemID.GetTDBID(InnerItemData.GetItemID(part)));
      if TDBID.IsValid(ammo) {
        return ammo;
      }
    }
    return AOData.GetID(AOData.Key(caliber, "defaultAmmo"));
  }

  // --- Ammo effects --------------------------------------------------------------------------

  // The on-hit status effect of an ammo type and its chance, or an invalid ID if it has none.
  public static func OnHitEffect(ammo: TweakDBID, out chance: Float) -> TweakDBID {
    for name in AOData.GetStrings(t"AmmoOverhaul.ammoEffects") {
      if AOData.GetID(AOData.Key(name, "ammo")) == ammo {
        chance = TweakDBInterface.GetFloat(AOData.Key(name, "chance"), 1.0);
        return AOData.GetID(AOData.Key(name, "effect"));
      }
    }
    return TDBID.None();
  }
}
```

### `src/scripts/AmmoOverhaul/AmmoFeedTweak.reds`

```swift
module AmmoOverhaul

// Runs once while TweakDB loads, after the YAML is applied. For every caliber, finds the weapons
// carrying one of its weaponTags, points their ammo at the caliber's pool and gives them a clone
// of their blueprint with the caliber's feed slot added. Cloning each weapon's own blueprint keeps
// the NoMuzzle/NoScope/Collectible variants intact.
public class AmmoFeedTweak extends ScriptableTweak {

  private let m_sourceBlueprints: array<TweakDBID>;
  private let m_elements: array<TweakDBID>;
  private let m_clones: array<TweakDBID>;

  protected cb func OnApply() -> Void {
    let weapons: array<ref<TweakDBRecord>> = TweakDBInterface.GetRecords(n"gamedataWeaponItem_Record");
    let calibers: array<String> = AOData.Calibers();
    ModLog(n"AmmoOverhaul", IntToString(ArraySize(calibers)) + " caliber(s), " + IntToString(ArraySize(weapons)) + " weapon records");
    for caliber in calibers {
      this.ApplyCaliber(caliber, weapons);
    }
  }

  private func ApplyCaliber(caliber: String, weapons: array<ref<TweakDBRecord>>) -> Void {
    let pool: TweakDBID = AOData.Pool(caliber);
    let tags: array<CName> = AOData.WeaponTags(caliber);
    let element: TweakDBID = AOData.FeedElement(caliber);
    let patched: Int32 = 0;
    if !TDBID.IsValid(pool) || ArraySize(tags) == 0 {
      ModLog(n"AmmoOverhaul", "caliber " + caliber + ": missing pool or weaponTags, skipped");
      return;
    }
    for record in weapons {
      let weapon: ref<WeaponItem_Record> = record as WeaponItem_Record;
      if IsDefined(weapon) && AmmoFeedTweak.HasAnyTag(weapon, tags) {
        let id: TweakDBID = weapon.GetID();
        TweakDBManager.SetFlat(AOData.Flat(id, "ammo"), ToVariant(pool));
        let blueprint: TweakDBID = TweakDBInterface.GetForeignKey(AOData.Flat(id, "blueprint"), TDBID.None());
        if TDBID.IsValid(blueprint) && TDBID.IsValid(element) {
          TweakDBManager.SetFlat(AOData.Flat(id, "blueprint"), ToVariant(this.WithElement(blueprint, element)));
        }
        TweakDBManager.UpdateRecord(id);
        patched += 1;
      }
    }
    ModLog(n"AmmoOverhaul", "caliber " + caliber + ": patched " + IntToString(patched) + " weapon records" + (TDBID.IsValid(element) ? "" : " (no feed element)"));
  }

  private static func HasAnyTag(weapon: ref<WeaponItem_Record>, tags: array<CName>) -> Bool {
    for tag in tags {
      if weapon.TagsContains(tag) {
        return true;
      }
    }
    return false;
  }

  // Returns a blueprint identical to `blueprint` whose root element also holds `element`.
  private func WithElement(blueprint: TweakDBID, element: TweakDBID) -> TweakDBID {
    let i: Int32 = 0;
    while i < ArraySize(this.m_sourceBlueprints) {
      if this.m_sourceBlueprints[i] == blueprint && this.m_elements[i] == element {
        return this.m_clones[i];
      }
      i += 1;
    }
    // Clone IDs only need to be unique; they are derived from the source plus a per-clone index.
    let suffix: String = "AO_" + IntToString(ArraySize(this.m_clones));
    let root: TweakDBID = TweakDBInterface.GetForeignKey(AOData.Flat(blueprint, "rootElement"), TDBID.None());
    let newRoot: TweakDBID = AOData.Flat(root, suffix);
    TweakDBManager.CloneRecord(newRoot, root);
    let children: array<TweakDBID> = TweakDBInterface.GetForeignKeyArray(AOData.Flat(root, "childElements"));
    ArrayPush(children, element);
    TweakDBManager.SetFlat(AOData.Flat(newRoot, "childElements"), ToVariant(children));
    TweakDBManager.UpdateRecord(newRoot);

    let newBlueprint: TweakDBID = AOData.Flat(blueprint, suffix);
    TweakDBManager.CloneRecord(newBlueprint, blueprint);
    TweakDBManager.SetFlat(AOData.Flat(newBlueprint, "rootElement"), ToVariant(newRoot));
    TweakDBManager.UpdateRecord(newBlueprint);

    ArrayPush(this.m_sourceBlueprints, blueprint);
    ArrayPush(this.m_elements, element);
    ArrayPush(this.m_clones, newBlueprint);
    return newBlueprint;
  }
}
```

### `src/scripts/AmmoOverhaul/AmmoFeedSystem.reds`

```swift
module AmmoOverhaul

// Keeps each hidden ammo pool equal to the ammo stack it currently stands in for, and moves
// whatever the engine does to the pool onto that stack.
//
// The engine only knows the weapon's `ammo` record (the pool): it consumes from it, refuses to
// reload when it's empty, and the HUD shows it. Rather than tracking individual events, Reconcile
// compares the pool's quantity with the value it last set:
//   - pool went down: the engine consumed rounds, remove the same from the mirrored stack;
//   - pool went up: something granted the weapon's ammo (e.g. loot), add it to the default stack;
// then sets the pool to the quantity of the stack the active weapon has selected.
//
// A magazine holds one ammo type. When a weapon's selection no longer matches what it was loaded
// with, its magazine is emptied (the unfired rounds were never consumed, so they stay in the old
// stack) and the next reload loads the new type.
public class AmmoFeedSystem extends ScriptableSystem {

  private let m_player: wref<PlayerPuppet>;
  private let m_callback: ref<AmmoFeedInventoryCallback>;
  private let m_listener: ref<InventoryScriptListener>;
  private let m_pendingReconcile: DelayID;
  private let m_hasPendingReconcile: Bool;

  // Per pool, parallel to m_pools. m_expected is -1 until the pool has been set at least once.
  private let m_pools: array<TweakDBID>;
  private let m_expected: array<Int32>;
  private let m_mirrored: array<TweakDBID>;
  private let m_hasMirror: array<Bool>;

  // Per weapon: the ammo its magazine was loaded with.
  private let m_weapons: array<ItemID>;
  private let m_loaded: array<TweakDBID>;

  public static func Get(game: GameInstance) -> ref<AmmoFeedSystem> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"AmmoOverhaul.AmmoFeedSystem") as AmmoFeedSystem;
  }

  public static func Notify(game: GameInstance) -> Void {
    let system: ref<AmmoFeedSystem> = AmmoFeedSystem.Get(game);
    if IsDefined(system) {
      system.QueueReconcile();
    }
  }

  private final func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
    // The request's owner is the player; the player system may not report it yet at this point.
    this.Attach(request.owner as PlayerPuppet);
  }

  private final func Attach(player: ref<PlayerPuppet>) -> Void {
    if !IsDefined(player) || player == this.m_player {
      return;
    }
    this.m_player = player;
    this.m_hasPendingReconcile = false;
    this.m_pools = AOData.Pools();
    ArrayClear(this.m_expected);
    ArrayClear(this.m_mirrored);
    ArrayClear(this.m_hasMirror);
    for pool in this.m_pools {
      ArrayPush(this.m_expected, -1);
      ArrayPush(this.m_mirrored, TDBID.None());
      ArrayPush(this.m_hasMirror, false);
    }
    ArrayClear(this.m_weapons);
    ArrayClear(this.m_loaded);
    this.m_callback = new AmmoFeedInventoryCallback();
    this.m_callback.system = this;
    this.m_listener = GameInstance.GetTransactionSystem(player.GetGame()).RegisterInventoryListener(player, this.m_callback);
    AmmoFeedSystem.Log("attached, " + IntToString(ArraySize(this.m_pools)) + " pool(s)");
    this.QueueReconcile();
  }

  private final func OnPlayerDetach(request: ref<PlayerDetachRequest>) -> Void {
    let player: ref<GameObject> = request.owner;
    // Loading a save (e.g. after dying) attaches the new player before the old one detaches;
    // only tear down for the player being tracked.
    if IsDefined(this.m_player) && player != this.m_player {
      return;
    }
    if IsDefined(player) && IsDefined(this.m_listener) {
      GameInstance.GetTransactionSystem(player.GetGame()).UnregisterInventoryListener(player, this.m_listener);
    }
    this.m_listener = null;
    this.m_callback = null;
    this.m_player = null;
  }

  // Inventory callbacks and weapon events can fire many times per frame, and changing the
  // inventory from inside an inventory callback is asking for trouble, so batch into a deferred
  // call. Debounced rather than guarded by a "queued" flag: the engine can drop a queued callback
  // (seen while the mod screen pauses the game), and a flag would then block every later reconcile.
  public final func QueueReconcile() -> Void {
    if !IsDefined(this.m_player) {
      return;
    }
    let delays: ref<DelaySystem> = GameInstance.GetDelaySystem(this.m_player.GetGame());
    if this.m_hasPendingReconcile {
      delays.CancelCallback(this.m_pendingReconcile);
    }
    let callback: ref<AmmoFeedReconcileCallback> = new AmmoFeedReconcileCallback();
    callback.system = this;
    this.m_pendingReconcile = delays.DelayCallback(callback, 0.0, false);
    this.m_hasPendingReconcile = true;
  }

  public final func Reconcile() -> Void {
    this.m_hasPendingReconcile = false;
    let player: ref<PlayerPuppet> = this.m_player;
    if !IsDefined(player) {
      return;
    }
    let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(player.GetGame());

    let activePool: TweakDBID = TDBID.None();
    let activeAmmo: TweakDBID = TDBID.None();
    let weapon: wref<WeaponObject> = ScriptedPuppet.GetWeaponRight(player);
    if IsDefined(weapon) {
      let weaponID: ItemID = weapon.GetItemID();
      activePool = AOData.PoolForWeapon(ItemID.GetTDBID(weaponID));
      if TDBID.IsValid(activePool) {
        activeAmmo = AOData.SelectedAmmo(player, weaponID, activePool);
        if this.SetLoaded(weaponID, activeAmmo) {
          this.EmptyMagazine(weapon);
        }
      }
    }

    let changed: Bool = false;
    let i: Int32 = 0;
    while i < ArraySize(this.m_pools) {
      if this.ReconcilePool(i, ts, player, activePool, activeAmmo) {
        changed = true;
      }
      i += 1;
    }
    if changed {
      AmmoFeedSystem.RefreshHud(player);
    }
  }

  private final func ReconcilePool(i: Int32, ts: ref<TransactionSystem>, player: ref<PlayerPuppet>, activePool: TweakDBID, activeAmmo: TweakDBID) -> Bool {
    let pool: TweakDBID = this.m_pools[i];
    let poolItem: ItemID = ItemID.CreateQuery(pool);
    let actual: Int32 = ts.GetItemQuantity(player, poolItem);
    let expected: Int32 = this.m_expected[i];
    let changed: Bool = false;

    // 1. Move what happened to the pool onto a real stack. Losses come out of the stack the pool
    //    was standing in for (the engine fired it). Gains are generic ammo the game granted for
    //    the weapon (e.g. loot rolled from its ammo record), so they become the default ammo
    //    rather than whatever special type happens to be selected.
    if expected >= 0 && actual < expected && this.m_hasMirror[i] {
      let mirrored: TweakDBID = this.m_mirrored[i];
      if TDBID.IsValid(mirrored) {
        ts.RemoveItem(player, ItemID.CreateQuery(mirrored), expected - actual);
      }
      AmmoFeedSystem.Log("consumed " + IntToString(expected - actual) + " of " + TDBID.ToStringDEBUG(mirrored));
      changed = true;
    } else {
      if expected >= 0 && actual > expected {
        let fallback: TweakDBID = AOData.DefaultAmmo(pool);
        let target: TweakDBID = TDBID.IsValid(fallback) ? fallback : this.m_mirrored[i];
        if TDBID.IsValid(target) {
          ts.GiveItem(player, ItemID.CreateQuery(target), actual - expected);
        }
        AmmoFeedSystem.Log("gained " + IntToString(actual - expected) + " -> " + TDBID.ToStringDEBUG(target));
        changed = true;
      }
    }

    // 2. Retarget to the active weapon's selection, if it uses this pool.
    if pool == activePool {
      if !this.m_hasMirror[i] || this.m_mirrored[i] != activeAmmo {
        AmmoFeedSystem.Log("pool now mirrors " + TDBID.ToStringDEBUG(activeAmmo));
      }
      this.m_mirrored[i] = activeAmmo;
      this.m_hasMirror[i] = true;
    }
    if !this.m_hasMirror[i] {
      // Nothing known to mirror yet (e.g. just loaded, weapon holstered); leave the pool alone.
      // Gains were already converted above, and get trimmed once the pool mirrors something.
      this.m_expected[i] = actual;
      return changed;
    }

    // 3. Make the pool match the mirrored stack.
    let desired: Int32 = TDBID.IsValid(this.m_mirrored[i]) ? ts.GetItemQuantity(player, ItemID.CreateQuery(this.m_mirrored[i])) : 0;
    if desired > actual {
      ts.GiveItem(player, poolItem, desired - actual);
      changed = true;
    } else {
      if desired < actual {
        ts.RemoveItem(player, poolItem, actual - desired);
        changed = true;
      }
    }
    this.m_expected[i] = desired;
    return changed;
  }

  // Records what the weapon is loaded with. Returns true when that differs from what it was
  // loaded with before, i.e. the magazine holds the wrong type and must be emptied.
  private final func SetLoaded(weaponID: ItemID, ammo: TweakDBID) -> Bool {
    let i: Int32 = 0;
    while i < ArraySize(this.m_weapons) {
      if this.m_weapons[i] == weaponID {
        if this.m_loaded[i] == ammo {
          return false;
        }
        AmmoFeedSystem.Log("selection changed " + TDBID.ToStringDEBUG(this.m_loaded[i]) + " -> " + TDBID.ToStringDEBUG(ammo));
        this.m_loaded[i] = ammo;
        return true;
      }
      i += 1;
    }
    // First time we see this weapon (new game session): trust that it's loaded with its selection.
    ArrayPush(this.m_weapons, weaponID);
    ArrayPush(this.m_loaded, ammo);
    return false;
  }

  public final func LoadedAmmo(weaponID: ItemID) -> TweakDBID {
    let i: Int32 = 0;
    while i < ArraySize(this.m_weapons) {
      if this.m_weapons[i] == weaponID {
        return this.m_loaded[i];
      }
      i += 1;
    }
    return TDBID.None();
  }

  private final func EmptyMagazine(weapon: ref<WeaponObject>) -> Void {
    let count: Uint32 = WeaponObject.GetMagazineAmmoCount(weapon);
    if count == 0u {
      return;
    }
    let evt: ref<SetAmmoCountEvent> = new SetAmmoCountEvent();
    evt.ammoTypeID = WeaponObject.GetAmmoType(weapon);
    evt.count = 0u;
    weapon.QueueEvent(evt);
    AmmoFeedSystem.Log("emptied magazine (" + IntToString(Cast<Int32>(count)) + " rounds stay in the old stack)");
  }

  private static func RefreshHud(player: ref<PlayerPuppet>) -> Void {
    let bb: ref<IBlackboard> = GameInstance.GetBlackboardSystem(player.GetGame()).Get(GetAllBlackboardDefs().UI_EquipmentData);
    bb.SetBool(GetAllBlackboardDefs().UI_EquipmentData.ammoLooted, true);
    bb.SignalBool(GetAllBlackboardDefs().UI_EquipmentData.ammoLooted);
  }

  public static func Log(message: String) -> Void {
    ModLog(n"AmmoOverhaul", message);
  }

  // Applies the on-hit effect of the ammo loaded in the weapon that fired. Called from the
  // damage pipeline before vanilla applies the attack's status effects, so vanilla's
  // blocked/friendly/immunity checks still apply to ours.
  public static func ApplyAmmoOnHit(hitEvent: ref<gameHitEvent>) -> Void {
    let attackData: ref<AttackData> = hitEvent.attackData;
    if !IsDefined(attackData) {
      return;
    }
    let instigator: ref<GameObject> = attackData.GetInstigator();
    if !IsDefined(instigator) || !instigator.IsPlayer() {
      return;
    }
    if !AttackData.IsRangedOrDirect(attackData.GetAttackType()) || AttackData.IsDoT(attackData) {
      return;
    }
    let weapon: ref<WeaponObject> = attackData.GetWeapon();
    if !IsDefined(weapon) {
      return;
    }
    let weaponID: ItemID = weapon.GetItemID();
    let pool: TweakDBID = AOData.PoolForWeapon(ItemID.GetTDBID(weaponID));
    if !TDBID.IsValid(pool) {
      return;
    }
    let ammo: TweakDBID = TDBID.None();
    let system: ref<AmmoFeedSystem> = AmmoFeedSystem.Get(instigator.GetGame());
    if IsDefined(system) {
      ammo = system.LoadedAmmo(weaponID);
    }
    if !TDBID.IsValid(ammo) {
      ammo = AOData.SelectedAmmo(instigator, weaponID, pool);
    }
    if !TDBID.IsValid(ammo) {
      return;
    }
    let chance: Float;
    let effect: TweakDBID = AOData.OnHitEffect(ammo, chance);
    if !TDBID.IsValid(effect) {
      return;
    }
    if RandF() < chance {
      attackData.AddStatusEffect(effect, 1.0);
    }
  }
}

public class AmmoFeedReconcileCallback extends DelayCallback {
  public let system: wref<AmmoFeedSystem>;

  public func Call() -> Void {
    if IsDefined(this.system) {
      this.system.Reconcile();
    }
  }
}

public class AmmoFeedInventoryCallback extends InventoryScriptCallback {
  public let system: wref<AmmoFeedSystem>;

  public func OnItemAdded(item: ItemID, itemData: wref<gameItemData>, flaggedAsSilent: Bool) -> Void {
    this.OnAmmoMaybeChanged(item);
  }

  public func OnItemRemoved(item: ItemID, difference: Int32, currentQuantity: Int32) -> Void {
    this.OnAmmoMaybeChanged(item);
  }

  public func OnItemQuantityChanged(item: ItemID, diff: Int32, total: Uint32, flaggedAsSilent: Bool) -> Void {
    this.OnAmmoMaybeChanged(item);
  }

  // A selector installed into or removed from a weapon.
  public func OnPartAdded(item: ItemID, partID: ItemID) -> Void {
    this.QueueReconcile();
  }

  public func OnPartRemoved(partID: ItemID, formerItemID: ItemID) -> Void {
    this.QueueReconcile();
  }

  private func OnAmmoMaybeChanged(item: ItemID) -> Void {
    let record: ref<Item_Record> = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(item));
    if IsDefined(record) && IsDefined(record.ItemType()) && Equals(record.ItemType().Type(), gamedataItemType.Con_Ammo) {
      this.QueueReconcile();
    }
  }

  private func QueueReconcile() -> Void {
    if IsDefined(this.system) {
      this.system.QueueReconcile();
    }
  }
}
```

### `src/scripts/AmmoOverhaul/Hooks.reds`

```swift
module AmmoOverhaul

// --- Ammo sync triggers ----------------------------------------------------------------------

// A weapon was spawned (drawn); the pool may need to stand in for a different stack now.
@wrapMethod(WeaponObject)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  AmmoFeedSystem.Notify(this.GetGame());
  return result;
}

// Sent after every shot and every reload.
@wrapMethod(WeaponObject)
protected cb func OnAmmoStateChangeEvent(evt: ref<AmmoStateChangeEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  if IsDefined(evt.weaponOwner) && evt.weaponOwner.IsPlayer() {
    AmmoFeedSystem.Notify(this.GetGame());
  }
  return result;
}

// --- On-hit ammo effects ---------------------------------------------------------------------

@wrapMethod(DamageSystem)
private final func ProcessStatusEffects(hitEvent: ref<gameHitEvent>) -> Void {
  AmmoFeedSystem.ApplyAmmoOnHit(hitEvent);
  wrappedMethod(hitEvent);
}

// --- Weapon mod screen -----------------------------------------------------------------------
// The mod screens intersect the slots an item really has with these hardcoded lists, so the
// feed slots must be on them to show up at all.

@wrapMethod(InventoryDataManagerV2)
public final static func GetAttachmentSlotsForInventory() -> array<TweakDBID> {
  let slots: array<TweakDBID> = wrappedMethod();
  AOData.AppendFeedSlots(slots);
  return slots;
}

@wrapMethod(UIInventoryItemModsStaticData)
public final static func GetAttachmentSlots(itemType: gamedataItemType) -> array<TweakDBID> {
  let slots: array<TweakDBID> = wrappedMethod(itemType);
  AOData.AppendFeedSlots(slots);
  return slots;
}

// Selectors are swapped freely; vanilla only lets scopes, muzzles and iconic mods come off.
@wrapMethod(RPGManager)
public final static func CanPartBeUnequipped(data: InventoryItemData, slotId: TweakDBID) -> Bool {
  if AOData.IsFeedSlot(slotId) {
    return true;
  }
  return wrappedMethod(data, slotId);
}

// Slot labels come from the slot record's localizedName (a LocKey# string the UI can resolve);
// unknown slots would otherwise fall back to the generic "Mod" label of their item type.
@wrapMethod(UIItemsHelper)
public final static func GetEmptySlotName(slotId: TweakDBID) -> String {
  if AOData.IsFeedSlot(slotId) {
    return TweakDBInterface.GetAttachmentSlotRecord(slotId).LocalizedName();
  }
  return wrappedMethod(slotId);
}

@wrapMethod(UIItemsHelper)
public final static func GetSlotName(slotID: TweakDBID, itemType: gamedataItemType, equipmentArea: gamedataEquipmentArea) -> String {
  if AOData.IsFeedSlot(slotID) {
    return TweakDBInterface.GetAttachmentSlotRecord(slotID).LocalizedName();
  }
  return wrappedMethod(slotID, itemType, equipmentArea);
}
```

### `src/scripts/AmmoOverhaul/Localization.reds`

```swift
module AmmoOverhaul.Localization
import Codeware.Localization.*

// Text for the LocKey#AO-* keys used in the tweaks, served through Codeware.
public class AmmoOverhaulLocalizationProvider extends ModLocalizationProvider {
  public func GetPackage(language: CName) -> ref<ModLocalizationPackage> {
    switch language {
      case n"en-us":
        return new AmmoOverhaulEnglish();
      default:
        return null;
    }
  }

  public func GetFallback() -> CName {
    return n"en-us";
  }
}

public class AmmoOverhaulEnglish extends ModLocalizationPackage {
  protected func DefineTexts() -> Void {
    this.Text("AO-Slot-AmmoFeed", "Ammo Feed");
    this.Text("AO-Ammo-Pool-9mm", "9mm (loaded type)");
    this.Text("AO-Ammo-9mm-Incendiary", "9mm Incendiary Rounds");
    this.Text("AO-Ammo-9mm-Incendiary-Desc", "Phosphorus-cored pistol rounds. Sets targets on fire.");
    this.Text("AO-Feed-9mm-FMJ", "Ammo Feed: 9mm FMJ");
    this.Text("AO-Feed-9mm-FMJ-Desc", "Feeds standard full-metal-jacket handgun ammo.");
    this.Text("AO-Feed-9mm-Incendiary", "Ammo Feed: 9mm Incendiary");
    this.Text("AO-Feed-9mm-Incendiary-Desc", "Feeds 9mm incendiary rounds. Switching types empties the magazine; unfired rounds go back to their stack.");
  }
}
```

### `tools/harness/init.lua`

```lua
-- AOHarness: dev-only CET mod that lets tools/cet.ps1 run Lua inside the running game.
--
-- tools/cet.ps1 writes cmd.lua into this folder with a first line "-- id: <n>". Every half
-- second the harness checks it; when the id is new it runs the code and appends the result to
-- out.log between "@@begin <n>" and "@@end <n>" markers. Inside the code, print() goes to out.log.
-- Not for shipping: anything that can write this folder can run code in the game.

local poll = 0
local lastId = nil

local function append(text)
    local f = io.open("out.log", "a")
    if f then
        f:write(text, "\n")
        f:close()
    end
end

local function render(v)
    if type(v) == "userdata" or type(v) == "table" then
        local ok, s = pcall(function() return GameDump(v) end)
        if ok and s then return s end
    end
    return tostring(v)
end

local function capture(...)
    local parts = {}
    for i = 1, select("#", ...) do
        parts[#parts + 1] = render((select(i, ...)))
    end
    append(table.concat(parts, "\t"))
end

-- Commands share the mod's globals (no custom environment: CET's sandbox is picky about
-- load/setfenv); print is swapped for the duration of the command instead.
local function execute(code)
    local fn, err = (loadstring or load)(code)
    if not fn then
        append("compile error: " .. tostring(err))
        return
    end
    local results = { pcall(fn) }
    if not results[1] then
        append("runtime error: " .. tostring(results[2]))
    else
        for i = 2, #results do append("=> " .. render(results[i])) end
    end
end

local function run(id, code)
    append("@@begin " .. id)
    local originalPrint = print
    print = capture
    local ok, err = pcall(execute, code)
    print = originalPrint
    if not ok then append("harness error: " .. tostring(err)) end
    append("@@end " .. id)
end

registerForEvent("onInit", function()
    -- Skip whatever command was left over from a previous session.
    local f = io.open("cmd.lua", "r")
    if f then
        lastId = (f:read("*l") or ""):match("^%-%- id: (%S+)")
        f:close()
    end
    append("@@ready " .. os.date("%Y-%m-%d %H:%M:%S"))
end)

registerForEvent("onUpdate", function(dt)
    poll = poll + dt
    if poll < 0.5 then return end
    poll = 0
    local f = io.open("cmd.lua", "r")
    if not f then return end
    local first = f:read("*l") or ""
    local id = first:match("^%-%- id: (%S+)")
    if not id or id == lastId then
        f:close()
        return
    end
    local code = f:read("*a") or ""
    f:close()
    lastId = id
    run(id, code)
end)
```

### `tools/cet.ps1`

```powershell
# Runs Lua inside the running game through the AOHarness CET mod and prints the result.
#   .\cet.ps1 'print(Game.GetPlayer():GetLevel())'
#   .\cet.ps1 -File snippet.lua
#   .\cet.ps1 -Install        # (re)deploys the harness mod; takes effect on next game launch
param(
    [Parameter(Position = 0)][string]$Code,
    [string]$File,
    [int]$TimeoutSec = 15,
    [switch]$Install,
    [string]$GameDir = "C:\Program Files\GOG Galaxy\Games\Cyberpunk 2077"
)
$ErrorActionPreference = 'Stop'
$mod = Join-Path $GameDir 'bin\x64\plugins\cyber_engine_tweaks\mods\AOHarness'

if ($Install) {
    New-Item -ItemType Directory -Force $mod | Out-Null
    Copy-Item (Join-Path $PSScriptRoot 'harness\init.lua') $mod -Force
    Write-Output "installed $mod"
    return
}

if ($File) { $Code = Get-Content $File -Raw }
if (-not $Code) { throw 'no code given' }
if (-not (Get-Process Cyberpunk2077 -ErrorAction SilentlyContinue)) { throw 'game is not running' }

$id = [Guid]::NewGuid().ToString('N').Substring(0, 8)
$out = Join-Path $mod 'out.log'
$offset = if (Test-Path $out) { (Get-Item $out).Length } else { 0 }
$utf8 = New-Object Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $mod 'cmd.lua'), "-- id: $id`n$Code`n", $utf8)

$deadline = (Get-Date).AddSeconds($TimeoutSec)
while ((Get-Date) -lt $deadline) {
    if ((Test-Path $out) -and (Get-Item $out).Length -gt $offset) {
        $text = [IO.File]::ReadAllText($out, $utf8)
        $begin = $text.IndexOf("@@begin $id")
        $end = $text.IndexOf("@@end $id")
        if ($begin -ge 0 -and $end -gt $begin) {
            $body = $text.Substring($begin + "@@begin $id".Length, $end - $begin - "@@begin $id".Length)
            Write-Output $body.Trim()
            return
        }
    }
    Start-Sleep -Milliseconds 250
}
throw "no response within $TimeoutSec s (game paused/unfocused, still loading, or harness not installed?)"
```

### `tools/dev-scripts/AODevAutoload.reds`

```swift
// Dev only: when the main menu has listed the saves, load the test save straight away.
// Based on DJ_Kovrik's "Autoload Latest Save" (Nexus 533), but loads a named save so the test
// always starts from the same clean state. Falls back to the newest save if the target is
// missing. Delete r6/scripts/AODev to turn it off.

// Folder name of the save to load (Saved Games/CD Projekt Red/Cyberpunk 2077/<name>).
public func AODevAutoloadTarget() -> String = "ManualSave-900"

@addField(SingleplayerMenuGameController)
private let m_aoDevAutoloaded: Bool;

@wrapMethod(SingleplayerMenuGameController)
protected cb func OnSavesForLoadReady(saves: array<String>) -> Bool {
  let result: Bool = wrappedMethod(saves);
  if this.m_aoDevAutoloaded || ArraySize(saves) == 0 {
    return result;
  }
  // Only once per game launch: returning to the main menu later shouldn't reload.
  this.m_aoDevAutoloaded = true;
  if AODevAutoloadState.Done() {
    return result;
  }
  AODevAutoloadState.MarkDone();
  let index: Int32 = 0;
  let i: Int32 = 0;
  while i < ArraySize(saves) {
    if StrContains(saves[i], AODevAutoloadTarget()) {
      index = i;
      break;
    }
    i += 1;
  }
  ModLog(n"AODev", "autoload " + saves[index] + " (index " + IntToString(index) + " of " + IntToString(ArraySize(saves)) + ", first: " + saves[0] + ")");
  this.GetSystemRequestsHandler().LoadSavedGame(index);
  return result;
}

// Remembers across menu instances that this launch already autoloaded once.
public class AODevAutoloadState extends ScriptableService {
  private let m_done: Bool;

  public static func Done() -> Bool {
    let state: ref<AODevAutoloadState> = GameInstance.GetScriptableServiceContainer().GetService(n"AODevAutoloadState") as AODevAutoloadState;
    return IsDefined(state) && state.m_done;
  }

  public static func MarkDone() -> Void {
    let state: ref<AODevAutoloadState> = GameInstance.GetScriptableServiceContainer().GetService(n"AODevAutoloadState") as AODevAutoloadState;
    if IsDefined(state) {
      state.m_done = true;
    }
  }
}
```

### `tools/dev-scripts/NoIntroVideos.reds`

```swift
@if(!ModuleExists("Codeware"))
public native class SplashScreenLoadingScreenLogicController extends ILoadingLogicController {
  public native let logosTrainAnimation: CName;
  public native let localizedMessageAnimation: CName;
  public native let gameIntroAnimation: CName;
  public native let longLogosTrainAnimation: CName;

  protected cb func OnInitialize() -> Bool {
    this.logosTrainAnimation = n"after_skip_pressed";
    this.localizedMessageAnimation = n"after_skip_pressed";
    this.gameIntroAnimation = n"after_skip_pressed";
    this.longLogosTrainAnimation = n"after_skip_pressed";
  }
}

@if(ModuleExists("Codeware"))
@addMethod(ILoadingLogicController)
protected cb func OnInitialize() -> Bool {
  if this.IsA(n"inkSplashScreenLoadingScreenLogicController") {
    let controller: ref<SplashScreenLoadingScreenLogicController> = this as SplashScreenLoadingScreenLogicController;
    controller.logosTrainAnimation = n"after_skip_pressed";
    controller.localizedMessageAnimation = n"after_skip_pressed";
    controller.gameIntroAnimation = n"after_skip_pressed";
    controller.longLogosTrainAnimation = n"after_skip_pressed";
  };
}
```

### `tools/dev-install.ps1`

```powershell
# Installs (or with -Remove, removes) the dev-only helpers: intro skip, autoload of the test
# save, the AOHarness CET console, and a desktop shortcut that skips the start screen.
param(
    [string]$GameDir = "C:\Program Files\GOG Galaxy\Games\Cyberpunk 2077",
    [switch]$Remove
)
$ErrorActionPreference = 'Stop'
$scripts = Join-Path $GameDir 'r6\scripts\AODev'
$shortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Cyberpunk 2077 (dev).lnk'

if ($Remove) {
    Remove-Item $scripts -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $GameDir 'bin\x64\plugins\cyber_engine_tweaks\mods\AOHarness') -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $shortcut -ErrorAction SilentlyContinue
    Write-Output 'dev helpers removed'
    return
}

New-Item -ItemType Directory -Force $scripts | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'dev-scripts\*.reds') $scripts -Force
& (Join-Path $PSScriptRoot 'cet.ps1') -Install -GameDir $GameDir

$shell = New-Object -ComObject WScript.Shell
$lnk = $shell.CreateShortcut($shortcut)
$lnk.TargetPath = Join-Path $GameDir 'bin\x64\Cyberpunk2077.exe'
$lnk.Arguments = '--launcher-skip -skipStartScreen'
$lnk.WorkingDirectory = Join-Path $GameDir 'bin\x64'
$lnk.Save()
Write-Output "installed dev helpers; shortcut: $shortcut"
```

### `tools/restart-game.ps1`

```powershell
# Dev only: kills Cyberpunk 2077 (if running) and relaunches it in the logged-in user's desktop
# session, then waits until the AOHarness answers (the dev autoload brings it straight into the save).
# A plain Start-Process from a service/SSH shell would run the game in session 0, invisible and
# without a display, so the launch goes through an interactive scheduled task instead.
param(
    [string]$GameDir = "C:\Program Files\GOG Galaxy\Games\Cyberpunk 2077",
    [int]$TimeoutSec = 240,
    [switch]$NoWait
)
$ErrorActionPreference = 'Stop'
$task = 'AODevLaunchCyberpunk'
$exe = Join-Path $GameDir 'bin\x64\Cyberpunk2077.exe'

$running = Get-Process Cyberpunk2077 -ErrorAction SilentlyContinue
if ($running) {
    $running | Stop-Process -Force
    $running | Wait-Process -Timeout 30 -ErrorAction SilentlyContinue
}

$action = New-ScheduledTaskAction -Execute $exe -Argument '--launcher-skip -skipStartScreen' -WorkingDirectory (Split-Path $exe)
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive
Register-ScheduledTask -TaskName $task -Action $action -Principal $principal -Force | Out-Null
Start-ScheduledTask -TaskName $task
Write-Output 'game launching'
if ($NoWait) { return }

$deadline = (Get-Date).AddSeconds($TimeoutSec)
while ((Get-Date) -lt $deadline) {
    Start-Sleep 10
    if (-not (Get-Process Cyberpunk2077 -ErrorAction SilentlyContinue)) { continue }
    try {
        # The main menu has a player puppet too; only a loaded save is out of pre-game.
        $r = & (Join-Path $PSScriptRoot 'cet.ps1') 'return tostring(Game.GetSystemRequestsHandler():IsPreGame()) .. " " .. tostring(Game.GetPlayer() ~= nil)' -TimeoutSec 5 -GameDir $GameDir
        if ($r -match '=> false true') {
            # Scriptable systems get OnPlayerAttach a few seconds after pre-game ends.
            Start-Sleep 15
            Write-Output 'in game'
            return
        }
    } catch { }
}
throw "game not in a save after $TimeoutSec s"
```

### `tools/check.ps1`

```powershell
# Compile-checks the mod's redscript against the vanilla 2.5 bundle plus the framework
# scripts, the same inputs the game's scc uses at launch. Needs reference/final.redscripts.vanilla
# (a copy of the unmodded r6/cache/final.redscripts) and tools/redscript-cli.exe.
param(
    [string]$GameDir = "C:\Program Files\GOG Galaxy\Games\Cyberpunk 2077"
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$bundle = Join-Path $root 'reference\final.redscripts.vanilla'
$out = Join-Path ([IO.Path]::GetTempPath()) 'ammo-overhaul-check.redscripts'

$src = @(Join-Path $root 'src\scripts')
foreach ($plugin in 'TweakXL', 'ArchiveXL', 'Codeware') {
    $dir = Join-Path $GameDir "red4ext\plugins\$plugin\Scripts"
    if (Test-Path $dir) { $src += $dir }
}

$cliArgs = @('compile', '-b', $bundle, '-o', $out)
foreach ($s in $src) { $cliArgs += @('-s', $s) }
& (Join-Path $PSScriptRoot 'redscript-cli.exe') @cliArgs
if ($LASTEXITCODE -ne 0) { throw "redscript compile failed ($LASTEXITCODE)" }
Remove-Item $out -ErrorAction SilentlyContinue
```

### `tools/package.ps1`

```powershell
# Builds dist/AmmoOverhaul.zip laid out relative to the game root, so it can be extracted
# into any Cyberpunk 2077 install (or a mod manager). With -Deploy, also copies the files
# into the local game directory.
param(
    [string]$GameDir = "C:\Program Files\GOG Galaxy\Games\Cyberpunk 2077",
    [switch]$Deploy
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$dist = Join-Path $root 'dist'
$stage = Join-Path $dist 'stage'
$zip = Join-Path $dist 'AmmoOverhaul.zip'

Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
$layout = @{
    'src\scripts' = 'r6\scripts'
    'src\tweaks'  = 'r6\tweaks'
}
foreach ($from in $layout.Keys) {
    $dst = Join-Path $stage $layout[$from]
    New-Item -ItemType Directory -Force $dst | Out-Null
    Copy-Item (Join-Path $root "$from\*") $dst -Recurse
}

Remove-Item $zip -ErrorAction SilentlyContinue
& (Join-Path $PSScriptRoot 'zip.ps1') -Source $stage -Destination $zip
# The test guide and log collector travel next to the zip, not inside the game folder.
Copy-Item (Join-Path $root 'docs\TESTING.md'), (Join-Path $PSScriptRoot 'collect-logs.ps1'), (Join-Path $PSScriptRoot 'zip.ps1') $dist
Write-Output "built $zip"

if ($Deploy) {
    # Replace the mod's own folders wholesale so deleted source files don't linger in the game.
    foreach ($dir in 'r6\scripts\AmmoOverhaul', 'r6\tweaks\AmmoOverhaul') {
        Remove-Item (Join-Path $GameDir $dir) -Recurse -Force -ErrorAction SilentlyContinue
    }
    Copy-Item (Join-Path $stage '*') $GameDir -Recurse -Force
    Write-Output "deployed to $GameDir"
}
```

### `tools/zip.ps1`

```powershell
# Zips a directory with forward-slash entry names. Windows PowerShell's Compress-Archive and
# .NET Framework's CreateFromDirectory write backslashes, which some mod managers mis-extract.
param(
    [Parameter(Mandatory)][string]$Source,
    [Parameter(Mandatory)][string]$Destination
)
$ErrorActionPreference = 'Stop'
Add-Type -AssemblyName System.IO.Compression, System.IO.Compression.FileSystem
$Source = (Resolve-Path $Source).Path.TrimEnd('\')
$archive = [IO.Compression.ZipFile]::Open($Destination, 'Create')
try {
    foreach ($file in Get-ChildItem $Source -Recurse -File) {
        $name = $file.FullName.Substring($Source.Length + 1).Replace('\', '/')
        [IO.Compression.ZipFileExtensions]::CreateEntryFromFile($archive, $file.FullName, $name) | Out-Null
    }
}
finally {
    $archive.Dispose()
}
```

### `tools/collect-logs.ps1`

```powershell
# Zips every log the mod and its frameworks write, for sending back after a test session.
# Run from any machine: .\collect-logs.ps1 -GameDir "D:\Games\Cyberpunk 2077"
# Needs zip.ps1 next to it.
param(
    [string]$GameDir = "C:\Program Files\GOG Galaxy\Games\Cyberpunk 2077",
    [string]$Out = (Join-Path ([Environment]::GetFolderPath('Desktop')) 'AmmoOverhaul-logs.zip')
)
$ErrorActionPreference = 'Stop'
$GameDir = $GameDir.TrimEnd('\')
$stage = Join-Path ([IO.Path]::GetTempPath()) 'AmmoOverhaul-logs'
Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $stage | Out-Null
foreach ($dir in 'r6\logs', 'red4ext\logs', 'red4ext\plugins', 'bin\x64\plugins\cyber_engine_tweaks') {
    $src = Join-Path $GameDir $dir
    if (-not (Test-Path $src)) { continue }
    foreach ($log in Get-ChildItem $src -Recurse -File -Filter *.log) {
        $dst = Join-Path $stage $log.FullName.Substring($GameDir.Length + 1)
        New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
        Copy-Item $log.FullName $dst
    }
}
Remove-Item $Out -ErrorAction SilentlyContinue
& (Join-Path $PSScriptRoot 'zip.ps1') -Source $stage -Destination $Out
Write-Output "wrote $Out"
```

### `tools/installed-frameworks.tsv`

```text
red4ext	bin\x64\winmm.dll
red4ext	red4ext\LICENSE.txt
red4ext	red4ext\RED4ext.dll
red4ext	red4ext\THIRD_PARTY_LICENSES.txt
tweakxl	red4ext\plugins\TweakXL\LICENSE
tweakxl	red4ext\plugins\TweakXL\THIRD_PARTY_LICENSES
tweakxl	red4ext\plugins\TweakXL\TweakXL.dll
tweakxl	red4ext\plugins\TweakXL\Data\ExtraFlats.dat
tweakxl	red4ext\plugins\TweakXL\Data\InheritanceMap.dat
tweakxl	red4ext\plugins\TweakXL\Scripts\TweakXL.Global.reds
tweakxl	red4ext\plugins\TweakXL\Scripts\TweakXL.reds
archivexl	r6\config\redsUserHints\ArchiveXL.toml
archivexl	red4ext\plugins\ArchiveXL\ArchiveXL.dll
archivexl	red4ext\plugins\ArchiveXL\ArchiveXL.yaml
archivexl	red4ext\plugins\ArchiveXL\LICENSE
archivexl	red4ext\plugins\ArchiveXL\THIRD_PARTY_LICENSES
archivexl	red4ext\plugins\ArchiveXL\Bundle\ArchiveXL.archive
archivexl	red4ext\plugins\ArchiveXL\Bundle\Migration.xl
archivexl	red4ext\plugins\ArchiveXL\Bundle\PhotoModeScope.xl
archivexl	red4ext\plugins\ArchiveXL\Bundle\PlayerBaseScope.xl
archivexl	red4ext\plugins\ArchiveXL\Bundle\PlayerCustomizationBeardFix.xl
archivexl	red4ext\plugins\ArchiveXL\Bundle\PlayerCustomizationBeardScope.xl
archivexl	red4ext\plugins\ArchiveXL\Bundle\PlayerCustomizationBrowsFix.xl
archivexl	red4ext\plugins\ArchiveXL\Bundle\PlayerCustomizationBrowsPatch.xl
archivexl	red4ext\plugins\ArchiveXL\Bundle\PlayerCustomizationBrowsScope.xl
archivexl	red4ext\plugins\ArchiveXL\Bundle\PlayerCustomizationEyesFix.xl
archivexl	red4ext\plugins\ArchiveXL\Bundle\PlayerCustomizationEyesPatch.xl
archivexl	red4ext\plugins\ArchiveXL\Bundle\PlayerCustomizationEyesScope.xl
archivexl	red4ext\plugins\ArchiveXL\Bundle\PlayerCustomizationHairFix.xl
archivexl	red4ext\plugins\ArchiveXL\Bundle\PlayerCustomizationHairPatch.xl
archivexl	red4ext\plugins\ArchiveXL\Bundle\PlayerCustomizationHairScope.xl
archivexl	red4ext\plugins\ArchiveXL\Bundle\PlayerCustomizationLashesFix.xl
archivexl	red4ext\plugins\ArchiveXL\Bundle\PlayerCustomizationLashesPatch.xl
archivexl	red4ext\plugins\ArchiveXL\Bundle\PlayerCustomizationLashesScope.xl
archivexl	red4ext\plugins\ArchiveXL\Bundle\PlayerCustomizationScope.xl
archivexl	red4ext\plugins\ArchiveXL\Bundle\QuestBaseScope.xl
archivexl	red4ext\plugins\ArchiveXL\Bundle\VisualTags.xl
archivexl	red4ext\plugins\ArchiveXL\Scripts\ArchiveXL.DynamicAppearance.reds
archivexl	red4ext\plugins\ArchiveXL\Scripts\ArchiveXL.Global.reds
archivexl	red4ext\plugins\ArchiveXL\Scripts\ArchiveXL.reds
codeware	red4ext\plugins\Codeware\Codeware.dll
codeware	red4ext\plugins\Codeware\LICENSE
codeware	red4ext\plugins\Codeware\THIRD_PARTY_LICENSES
codeware	red4ext\plugins\Codeware\Data\KnownHashes.txt
codeware	red4ext\plugins\Codeware\Scripts\Codeware.Global.reds
codeware	red4ext\plugins\Codeware\Scripts\Codeware.Localization.reds
codeware	red4ext\plugins\Codeware\Scripts\Codeware.reds
codeware	red4ext\plugins\Codeware\Scripts\Codeware.UI.reds
codeware	red4ext\plugins\Codeware\Scripts\Codeware.UI.TextInput.reds
cet	bin\x64\global.ini
cet	bin\x64\LICENSE
cet	bin\x64\version.dll
cet	bin\x64\plugins\cyber_engine_tweaks.asi
cet	bin\x64\plugins\cyber_engine_tweaks\ThirdParty_LICENSES
cet	bin\x64\plugins\cyber_engine_tweaks\fonts\materialdesignicons.ttf
cet	bin\x64\plugins\cyber_engine_tweaks\fonts\NotoSans-Regular.ttf
cet	bin\x64\plugins\cyber_engine_tweaks\fonts\NotoSansJP-Regular.otf
cet	bin\x64\plugins\cyber_engine_tweaks\fonts\NotoSansKR-Regular.otf
cet	bin\x64\plugins\cyber_engine_tweaks\fonts\NotoSansMono-Regular.ttf
cet	bin\x64\plugins\cyber_engine_tweaks\fonts\NotoSansSC-Regular.otf
cet	bin\x64\plugins\cyber_engine_tweaks\fonts\NotoSansTC-Regular.otf
cet	bin\x64\plugins\cyber_engine_tweaks\fonts\NotoSansThai-Regular.ttf
cet	bin\x64\plugins\cyber_engine_tweaks\scripts\IconGlyphs\icons.lua
cet	bin\x64\plugins\cyber_engine_tweaks\scripts\json\json.lua
cet	bin\x64\plugins\cyber_engine_tweaks\scripts\json\LICENSE
cet	bin\x64\plugins\cyber_engine_tweaks\scripts\json\README.md
cet	bin\x64\plugins\cyber_engine_tweaks\tweakdb\tweakdbstr.kark
cet	bin\x64\plugins\cyber_engine_tweaks\tweakdb\usedhashes.kark
redscript	engine\config\base\scripts.ini
redscript	engine\tools\scc.exe
redscript	engine\tools\scc_lib.dll
redscript	r6\config\cybercmd\scc.toml
```

### `docs/DESIGN.md`

```markdown
# Ammo Overhaul: design notes

Target: Cyberpunk 2077 2.50 (exe 3.0.88.46235). Overall goal and family/caliber/rarity plan: see
the original handoff. This file records how the proof of concept works and why.

## Layout

- `src/tweaks/AmmoOverhaul/*.yaml`: all data (TweakXL). Pools, feed slots, ammo variants, selectors.
- `src/scripts/AmmoOverhaul/*.reds`: generic logic, with nothing specific to one gun or ammo type.
  - `AOData.reds`: reads the custom `ao*` flats.
  - `AmmoFeedTweak.reds`: load-time weapon patching (ScriptableTweak).
  - `AmmoFeedSystem.reds`: runtime pool mirroring and the on-hit effect.
  - `Hooks.reds`: wraps of vanilla functions.
  - `Localization.reds`: text, served through Codeware.
- `tools/check.ps1`: compiles the scripts against the vanilla bundle, offline.
  `tools/package.ps1 [-Deploy]`: builds `dist/`.
- `reference/` (gitignored): decompiled 2.50 scripts. Vanilla `.tweak` sources ship with the
  game under `tools/redmod/tweaks`.

## Data model

- **Pool:** a hidden ammo item per family+caliber (`Ammo.AO_Pool_Power_9mm`), listed in
  `AmmoOverhaul.pools`. Its flats:
  - `aoWeaponTags`: weapons carrying any of these tags use this pool.
  - `aoFeedSlot` / `aoFeedElement`: the slot that selects the ammo, and its blueprint element.
  - `aoDefaultAmmo`: what an empty slot fires. Leave it out to make an empty slot mean
    "can't fire".
- **Feed slot:** one per family+caliber. Selectors' `placementSlots` name it, so the slot itself
  enforces "same family and caliber".
- **Selector:** a part (`Items.Part` base, `ItemType.Prt_Magazine`) whose `aoAmmo` names the real
  ammo stack.
- **Ammo variant:** a normal ammo item. `aoOnHitEffect` and `aoOnHitChance` give it an on-hit
  status effect.

## Why these choices

- **Weapons are patched in script, not YAML:** TweakDB stores each record's values directly, so
  `Base_Lexington` changes don't reach its presets. The tweak finds weapons by tag and clones each
  one's *own* blueprint, so the NoMuzzle, NoScope and Collectible variants keep their layout.
- **Selectors are `Prt_Magazine`, not a weapon-mod type:** vanilla weapon-mod types can't be
  removed, can't be swapped on non-iconic guns, and are destroyed when replaced
  (`RPGManager.CanPartBeUnequipped`, `ItemModificationSystem.InstallItemPart`). Muzzle and scope
  types get filtered out of the candidate list. `Prt_Magazine` is only special-cased for UI labels.
- **The slot element has no quality prereq, and the slot is `unlockedBy: Common`:** otherwise the
  slot is hidden on low-quality guns.
- **Mod screen wraps:** the mod screens intersect each item's real slots with hardcoded lists
  (`InventoryDataManagerV2.GetAttachmentSlotsForInventory`,
  `UIInventoryItemModsStaticData.GetAttachmentSlots`), so feed slots are appended there.
- **Pool sync compares totals, not events:** from the HUD math (`reserve = total - ammoCurrent`)
  it looks like the inventory count includes loaded rounds and is consumed per shot. Comparing the
  pool's total with the last value set works whether consumption happens per shot or per reload.
  The logs will show which.
- **One type per magazine:** when a weapon's selection no longer matches what it was loaded with,
  its magazine is emptied. Under the per-shot model those rounds were never taken from the old
  stack, so nothing is lost. If the logs show per-reload consumption instead, the magazine count
  must be refunded to the old stack at that point.
- **On-hit hook is `DamageSystem.ProcessStatusEffects`:** the effect is added to the attack data
  before vanilla applies the attack's status effects, so vanilla's blocked, friendly and immunity
  checks still apply to it.

## Known gaps

- Dual wield: the pool follows the right-hand weapon only.
- Inventory UI: there's no ammo panel entry for new ammo types yet; the HUD reserve is the only
  place the count shows.
- Pool items granted before the first sync after loading are absorbed without being converted.
- If the selected stack drops below what's in the magazine (e.g. you sell loaded rounds), the
  magazine can still fire them. The fix is to clamp the magazine to the stack, but that's only
  correct under the per-shot model, so it waits until the logs confirm that model.
- The selector icon is the generic mod icon. There is no crafting or loot yet; test items come
  from the CET console.
```

### `docs/TESTING.md`

````markdown
# Ammo Overhaul PoC: test guide

## Install

Needs Cyberpunk 2077 2.50 (exe 3.0.88.46235) with RED4ext 1.31, TweakXL 1.12, ArchiveXL 1.28,
Codeware 1.21, CET 1.38 and redscript 0.5.32 or newer of each.

Extract `AmmoOverhaul.zip` into the game folder (the one containing `bin` and `r6`). It only adds
`r6\scripts\AmmoOverhaul` and `r6\tweaks\AmmoOverhaul`. Delete those two folders to uninstall.
Uninstalling with ammo loaded is safe: the hidden pool item just becomes inert.

## Get the test items (CET console)

Load a save with a free inventory slot, open the CET overlay, then in the Console tab:

```lua
Game.AddToInventory("Items.Preset_Lexington_Default", 1)
Game.AddToInventory("Items.AO_Feed_9mm_FMJ", 1)
Game.AddToInventory("Items.AO_Feed_9mm_Incendiary", 1)
Game.AddToInventory("Ammo.HandgunAmmo", 50)
Game.AddToInventory("Ammo.AO_9mm_Incendiary", 30)
```

Use a newly spawned Lexington: a Lexington already in an old save may keep its old slot layout.

Quick data check. These should print `Ammo.AO_Pool_Power_9mm` and a blueprint that isn't
`Items.Base_Power_Handgun_Blueprint`:

```lua
print(TweakDB:GetFlat("Items.Preset_Lexington_Default.ammo"))
print(TweakDB:GetFlat("Items.Preset_Lexington_Default.blueprint"))
```

Pool quantity, for the checks below:

```lua
print(Game.GetTransactionSystem():GetItemQuantity(Game.GetPlayer(), ItemID.CreateQuery(TweakDBID.new("Ammo.AO_Pool_Power_9mm"))))
```

## What to check

Equip the new Lexington and draw it.

1. **Default ammo.** With the feed slot empty, the HUD reserve shows your handgun ammo, and
   firing uses up `Ammo.HandgunAmmo`.
2. **Slot shows.** In Inventory → the Lexington → mods, there's an "Ammo Feed" slot. It's empty
   at first and labelled "Ammo Feed: standard rounds".
3. **Only matching selectors.** Clicking the slot lists only the two "Ammo Feed: 9mm …" items,
   no vanilla mods. Vanilla mod slots don't list the selectors.
4. **Swap and remove.** Install FMJ, then swap it for Incendiary, then remove it. Each change
   should work, and a replaced selector should go back to the inventory instead of disappearing.
5. **Switching types empties the magazine.** Fire a few FMJ rounds, then switch to Incendiary.
   On closing the menu the magazine should be empty and the reserve should show 30. The unfired
   FMJ rounds should still be in the FMJ count.
6. **Consumes the selected type.** Fire incendiary rounds: `Ammo.AO_9mm_Incendiary` goes down by
   the same amount, and FMJ doesn't change.
7. **Can't fire when empty.** Use up all 30 incendiary rounds. The gun shouldn't reload, even
   though you still have FMJ. Switch back to FMJ and it reloads.
8. **On-hit effect.** Shoot an enemy with incendiary rounds: they catch fire on every hit
   (chance 1.0 for this test). FMJ rounds don't set them on fire.
9. **Picking up ammo.** Loot handgun ammo while the incendiary selector is installed. The new
   rounds should end up in the FMJ count, not inflate the incendiary count.
10. **Save and load.** Save with the incendiary selector installed and a part-used magazine, then
    reload. The counts should be unchanged and the gun should still fire incendiary rounds.

For each check, note pass or fail and what you saw, especially the counts.

## Logs

Afterwards, run `collect-logs.ps1 -GameDir "<your game folder>"` (keep `zip.ps1` next to it; it writes
`AmmoOverhaul-logs.zip` to the desktop) and send the zip. Lines from this mod are tagged
`AmmoOverhaul`: weapons patched at startup, then `consumed`, `gained`, `pool now mirrors`,
`selection changed` and `emptied magazine` during play.
````

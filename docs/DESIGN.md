# Ammo Overhaul: design notes

Target: Cyberpunk 2077 2.50 (exe 3.0.88.46235). Goal: ammo locked by family (Power/Tech/Smart)
and caliber, special ammo chosen per gun with a feed part, ammo as real carried weight, and NPCs
that carry and use up real ammo. This file records how the proof of concept works and why.

## Layout

- `src/tweaks/AmmoOverhaul/*.yaml`: all data (TweakXL). `core.yaml` has the mod settings and
  vanilla ammo weights; one file per caliber (`power_9mm.yaml`, `tech_light.yaml`,
  `smart_10.yaml`) has its feed slot, ammo items, selectors and settings; `test.yaml` has test
  enemies.
- `src/scripts/AmmoOverhaul/*.reds`: generic logic, with nothing specific to one gun or ammo type.
  - `AOData.reds`: reads the `AmmoOverhaul.*` settings.
  - `AmmoFeedTweak.reds`: load-time TweakDB patching (ScriptableTweak).
  - `AmmoFeedSystem.reds`: the player's per-gun ammo, unloading on a selector change, on-hit effects.
  - `NativeAmmo.reds` + `Native.reds`: per-gun ammo through the native plugin.
  - `NpcAmmo.reds`: NPC ammo stock, consumption, running dry, loot.
  - `Hooks.reds`: wraps of vanilla functions for the player side and the UI.
  - `Localization.reds`: text, served through Codeware.
- `native/AmmoOverhaul/`: the RED4ext plugin (C++). `native/AOProbe/` is a research probe, not
  part of the mod.
- `tools/linux/`: build, compile check, deploy and the in-game harness (see `docs/TESTING.md`).
- `reference/` (gitignored): decompiled 2.50 scripts (`reference/scripts`, the one to search) and
  the vanilla script bundle the compile check uses.

## Data model

TweakXL rejects unknown properties on existing record types, so the mod's settings live in
standalone `AmmoOverhaul.*` flats keyed by short names (read by `AOData.reds`):

- `AmmoOverhaul.calibers`: caliber names (`Power_9mm`, `Tech_Light`, `Smart_10`).
- Per caliber, `AmmoOverhaul.<caliber>.*`:
  - `weaponTags`: weapons carrying any of these tags belong to the caliber.
  - `feedSlot` / `feedElement`: the slot that selects the ammo, and its blueprint element.
  - `defaultAmmo`: the ammo an empty slot takes (the caliber's cheap standard round). The
    caliber's weapon records are set to it.
  - `selectors` / `selectorAmmo` / `selectorTiers`: parallel lists, selector part -> ammo item
    it feeds -> tier (0 Common, 1 Uncommon).
  - `family` (`Power`, `Tech`, `Smart`), `vanillaAmmo` (the vanilla item its loot and vendor
    stock are taken from) and `lootWeight` (its share of that item), for distribution.
- `AmmoOverhaul.shares.<family>`: each tier's share of a family's ammo.
- `AmmoOverhaul.loot.ownedBias`: chance converted loot goes to a caliber of a gun the player
  carries.
- `AmmoOverhaul.npcUncommonFactor.<rarity>`: how much likelier than the Uncommon share an NPC
  of that rarity is to carry the Uncommon round.
- `AmmoOverhaul.ammoEffects`: names of on-hit entries; each has `.ammo`, `.effect` (a status
  effect) and `.chance`.
- `AmmoOverhaul.npcMagazines.<rarity>`: magazines an NPC carries per gun, by `gamedataNPCRarity`.

Records: one feed slot per family + caliber (selectors' `placementSlots` name it, so the slot
itself enforces "same family and caliber"); selectors are parts (`Items.Part` base,
`ItemType.Prt_Magazine`) with the same name and description as their round; ammo variants are
normal ammo items based on `Ammo.HandgunAmmo`, with their own quality and Weight stat. Vanilla
handgun ammo is the 9mm Common round (renamed 9mm Ball); the 5mm and 10mm rounds are new items, so
an Omaha or Yukimura in an old save starts empty.

## Player: per-gun ammo

The engine copies a gun's ammo type from its record into the spawned weapon object
(`gameweaponObject`), twice: the ammo it's **loaded** with (+0x2e4 on 2.50: name hash, then length
byte; the magazine count and capacity follow at +0x2f4/+0x2f8) and the ammo it **wants**
(+0x4a8). The loaded ammo drives the HUD total, per-shot consumption and native reload. When the
two differ the engine has an ammo change pending (`HasAmmoChangeRequest`) and carries it out by
reloading into the wanted ammo, about every 1.5 s while the gun is empty. Writing only the loaded
field caused exactly that: the gun kept reverting to its record's ammo with a full magazine, and
fighting it gave endless reloads. So both are written, and the records stay unchanged.

- **The plugin finds the fields at runtime** instead of hard-coding offsets (`NativeAmmo`). Of
  the offsets holding the old ammo ID (`AO_FindAmmoFields`), the loaded field is the one where
  writing makes `GetTotalAmmoCount()` the new ammo's inventory count; the wanted field is the one
  where writing clears the pending change. Failed writes are undone. Every write checks the field
  still holds the expected ID, and memory is checked with `VirtualQuery`, so after a game patch
  the mod fails safe instead of corrupting memory. When a check can't tell candidates apart
  (equal counts, no pending change) the write is kept and the field located again next time.
- **When it's written:** at `WeaponObject.OnGameAttached` (spawn, including the respawn of a drawn
  gun after a part change) and at `EquipCycleEvents` / `EquippedEvents.OnEnter` (draws).
- **Switching types unloads the gun:** the engine takes ammo out of the inventory per shot and
  the inventory count includes the loaded rounds (measured on a vanilla Liberty: mag 12, inventory
  486; 3 shots: mag 9, inventory 483; reload: mag 12, inventory 483). So emptying the magazine
  loses nothing. A selector change marks the gun (saved with the game); when it next spawns (a
  part change respawns a drawn gun at once) the plugin writes its magazine count to 0, only if
  the field next to the loaded ammo holds the count and capacity the engine reports, and the
  blackboard is updated. If that can't be done within 3 s, the gun in hand falls back to
  `ForceResetAmmoEvent` plus a holster and redraw.
- **Safety net:** the gun in hand's shared blackboard `Weapon.MagazineAmmoCount` is watched; if
  the loaded field ever holds other ammo than the selection, the selection is applied again and
  the gun unloaded.
- **Menus and HUD count the record's ammo** (`RPGManager.GetAmmoCountValue` for the HUD reserve
  and iron sights, `UIInventoryItem.GetAmmo` / `InventoryItemData.SetAmmo` for weapon cards and
  tooltips, `InventoryDataManagerV2.GetAmmoForWeaponType` for the D-pad wheel); they're wrapped to
  count the gun's selected ammo.
- **Magazine events (measured, 2.50):**
  - `SetAmmoCountEvent` (on the weapon) can raise the magazine but never lowers it.
  - `WeaponConsumeMagazineAmmoEvent` (on the weapon) lowers it *and* takes the rounds out of the
    inventory, like a shot. Handy for scripted tests.
  - `ForceResetAmmoEvent` (on the player, `SetIsLeftHandWeapon(false)`) sets the magazine without
    touching the inventory. It lands on the weapon's next state change (holster, draw), not in
    Safe state and not from a scripted consume or an interrupted reload, and in play it didn't
    land before a real shot either. The last one queued wins; one queued with no gun in hand is
    dropped.
  - A draw queued in the same frame as a holster cancels the holster.
- **Weapons are patched in script, not YAML:** TweakDB stores each record's values directly, so
  `Base_Lexington` changes don't reach its presets. The tweak finds weapons by tag and clones each
  one's *own* blueprint, so the NoMuzzle, NoScope and Collectible variants keep their layout.
- **Selectors are `Prt_Magazine`, not a weapon-mod type:** vanilla weapon-mod types can't be
  removed, can't be swapped on non-iconic guns, and are destroyed when replaced
  (`RPGManager.CanPartBeUnequipped`, `ItemModificationSystem.InstallItemPart`).
- **Any round fits any gun of its caliber:** vanilla marks parts of a higher quality than the gun
  as not installable (`InventoryDataManagerV2.GetPlayerInventoryPartsForItemRef`); the mark is
  taken off selectors. The install request itself has no quality check.
- **The slot element has no quality prereq, and the slot is `unlockedBy: Common`:** otherwise the
  slot is hidden on low-quality guns.
- **Mod screen wraps:** the mod screens intersect each item's real slots with hardcoded lists
  (`InventoryDataManagerV2.GetAttachmentSlotsForInventory`,
  `UIInventoryItemModsStaticData.GetAttachmentSlots`), so feed slots are appended there.
- **On-hit hook is `DamageSystem.ProcessStatusEffects`:** the effect is added to the attack data
  before vanilla applies the attack's status effects, so vanilla's blocked, friendly and immunity
  checks still apply to it. NPC shots get their gun's effect too (the selection is read from the
  shooter's inventory).

## NPC ammo

Vanilla NPCs never use inventory ammo: shots go through script `AIWeapon.Fire` (from
`AISubActionShootWithWeapon`) and the engine takes nothing from the NPC's inventory; reloads are
`AISubActionReloadWeapon_Record_Implementation` (`StartReload`/`StopReload`).

- **Stock:** the first time a hostile NPC draws a gun, every gun it carries gets
  `npcMagazines.<rarity>` × magazine capacity of its ammo. A gun of a managed caliber uses the
  ammo its feed slot selects, as for the player (a preset can fit a selector through
  `slotPartListPreset`); other guns use their record's. Like the player's, the stack includes the
  loaded rounds. NPCs friendly to the player and companions aren't counted.
- **Uncommon rounds:** before stocking a managed gun with an empty feed slot, the NPC rolls once
  for the caliber's Uncommon round: chance = the family's Uncommon share ×
  `npcUncommonFactor.<rarity>`, capped at 1. On a hit the gun is stocked with the Uncommon round
  and the selector's stat modifiers are added straight to the gun's stats. No part is fitted:
  `TransactionSystem.AddPart` on an NPC's drawn gun hangs the game, and an
  `ItemModificationSystem` install request does nothing for NPCs. The roll is kept per gun for the
  session only.
- **Use:** each `AIWeapon.Fire` takes the shot's rounds (`NumShotsToFire`) from the stack; with
  none left the shot and the reload are skipped.
- **Running dry:** switch to another gun with ammo (`AISwitchToSecondary/PrimaryWeaponCommand`);
  with none, the guns are taken out of the NPC's inventory and the AI falls back to melee or
  vanilla no-weapon combat (`NoWeaponCombatConditions`). The AI gives back missing record
  equipment (`AISubActionEquipOnBody`), so stashed guns are filtered out of
  `AIActionTransactionSystem.CalculateEquipmentItems`. `AIUnequipCommand` alone doesn't stick.
- **Loot:** death and incapacitation loot is native (`gamePuppet.ProcessLoot`) and wipes the NPC's
  ammo stacks, so they're noted at `OnDeath` / `OnIncapacitated` and given back in
  `ScriptedPuppet.EvaluateLootQuality`, which runs once loot is in. Stashed guns come back the same
  way (as fresh items of the same record). The engine's random ammo drop is turned off for every
  character (`dropsAmmoOnDeathChance` = 0).
- **Not counted:** guns whose record ammo is `Ammo.Standard` (melee weapons, cyberware, heavy
  machine guns and a few others) stay unlimited until they get a real ammo type.

## Weight and inventory

- Ammo items have a Weight stat (about one carry point per typical magazine). Stack items update
  carried weight by the quantity difference (`PlayerPuppet` `OnItemQuantityChanged`), so every
  shot and pickup moves it. Existing stacks in a save pick it up on load.
- The backpack lists ammo: `UIInventoryItemsManager.GetBlacklistedTags` no longer includes `Ammo`.

## Known gaps

- Dual wield: only the right-hand gun is watched by the safety net.
- Ammo of the same type shares one NPC stack; a gun first given to an NPC after its first draw
  adds no stock if the NPC already carries that ammo.
- NPC guns have `DamagePerHit` 0 (their damage comes from elsewhere), so damage multipliers on a
  round (Mushrooms, Dumbfires) do nothing on NPC shots. Pen, hit probability and other stats do
  apply. NPC Omahas have `ChargeTime` 0, so Sleevers changes nothing for them.
- The Uncommon roll isn't saved. After loading a save, an NPC stocked with an Uncommon round reads
  its gun's ammo as the Common round again, and its stock holds the Uncommon one, so it can run
  dry early. Untested.
- Boss fights: a boss that runs dry loses its guns. 12 magazines makes it unlikely; untested.
- The selector icon is the generic mod icon. No crafting or loot yet; test items come from CET.

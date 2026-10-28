# Ammo Overhaul: design notes

Target: Cyberpunk 2077 2.50 (exe 3.0.88.46235). Goal: ammo locked by family (Power/Tech/Smart)
and caliber, special ammo chosen per gun with a feed part, ammo as real carried weight, and NPCs
that carry and use up real ammo. This file records how the proof of concept works and why.

## Layout

- `src/tweaks/AmmoOverhaul/*.yaml`: all data (TweakXL): settings, feed slots, ammo variants,
  selectors, ammo weight.
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
standalone `AmmoOverhaul.*` flats keyed by short names (`poc_9mm.yaml`, read by `AOData.reds`):

- `AmmoOverhaul.calibers`: caliber names, e.g. `Power_9mm` (family + caliber).
- Per caliber, `AmmoOverhaul.<caliber>.*`:
  - `weaponTags`: weapons carrying any of these tags belong to the caliber.
  - `feedSlot` / `feedElement`: the slot that selects the ammo, and its blueprint element.
  - `defaultAmmo`: the ammo an empty slot takes (the caliber's cheap standard round). The
    caliber's weapon records are set to it.
  - `selectors` / `selectorAmmo`: parallel lists, selector part -> ammo item it feeds.
- `AmmoOverhaul.ammoEffects`: names of on-hit entries; each has `.ammo`, `.effect` (a status
  effect) and `.chance`.
- `AmmoOverhaul.npcMagazines.<rarity>`: magazines an NPC carries per gun, by `gamedataNPCRarity`.

Records: one feed slot per family + caliber (selectors' `placementSlots` name it, so the slot
itself enforces "same family and caliber"); selectors are parts (`Items.Part` base,
`ItemType.Prt_Magazine`); ammo variants are normal ammo items. Each ammo item has a Weight stat.

## Player: per-gun ammo

The engine copies a gun's ammo type from its record into the spawned weapon object
(`gameweaponObject`) and from then on reloads from, consumes and reports that ammo. It's a
TweakDBID inside the object, not in the RTTI (+0x2e4 on 2.50: name hash, then length byte; the
magazine count and capacity follow at +0x2f4/+0x2f8). Writing another ammo ID there switches that
one gun's HUD total, per-shot consumption and native reload at once, with the record unchanged.

- **The plugin finds the field at runtime** instead of hard-coding the offset. `NativeAmmo.Apply`
  takes the offsets in the object holding the record's ammo ID (`AO_FindAmmoFields`), writes the
  wanted ammo into each in turn and keeps the one where `GetTotalAmmoCount()` becomes the wanted
  ammo's inventory count; failed writes are undone. Every write checks the field still holds the
  expected ID, and memory is checked with `VirtualQuery`, so after a game patch the mod fails safe
  instead of corrupting memory. Equal counts can't tell candidates apart; then the write is kept
  and the field is located again next time.
- **When it's written:** at `WeaponObject.OnGameAttached` (spawn, including the respawn of a drawn
  gun after a part change) and at `EquipCycleEvents` / `EquippedEvents.OnEnter` (draws; a plain
  holster and draw keeps the field, but this covers the engine re-copying it). Records stay at the
  caliber default.
- **Engine restore quirk:** on the first selector change of a session, ~1.5 s after the redraw,
  the engine natively puts back the gun's earlier ammo state (type and magazine count). Nothing
  in script triggers it. The gun's shared blackboard `Weapon.MagazineAmmoCount` changes when it
  happens, so the gun in hand is watched there: if its field no longer holds the selection, the
  selection is applied again and the gun is unloaded.
- **Switching types unloads the gun:** the engine takes ammo out of the inventory per shot and
  the inventory count includes the loaded rounds (measured on a vanilla Liberty: mag 12, inventory
  486; 3 shots: mag 9, inventory 483; reload: mag 12, inventory 483). So emptying the magazine
  loses nothing. The gun in hand is unloaded (`ForceResetAmmoEvent`), holstered and redrawn,
  0.5 s then 0.3 s apart; any other gun is marked (saved) and unloaded the next time it spawns.
- **Magazine events (measured, 2.50):**
  - `SetAmmoCountEvent` (on the weapon) can raise the magazine but never lowers it.
  - `WeaponConsumeMagazineAmmoEvent` (on the weapon) lowers it *and* takes the rounds out of the
    inventory, like a shot. Handy for scripted tests.
  - `ForceResetAmmoEvent` (on the player, `SetIsLeftHandWeapon(false)`) sets the magazine without
    touching the inventory. It lands on the weapon's next state change (holster, draw, a real
    shot, which applies it before firing), not in Safe state, not from scripted consume or an
    interrupted `StartReload`/`StopReload`. The last one queued wins; one queued with no gun in
    hand is dropped. It doesn't change the ammo type.
  - A draw queued in the same frame as a holster cancels the holster.
- **Weapons are patched in script, not YAML:** TweakDB stores each record's values directly, so
  `Base_Lexington` changes don't reach its presets. The tweak finds weapons by tag and clones each
  one's *own* blueprint, so the NoMuzzle, NoScope and Collectible variants keep their layout.
- **Selectors are `Prt_Magazine`, not a weapon-mod type:** vanilla weapon-mod types can't be
  removed, can't be swapped on non-iconic guns, and are destroyed when replaced
  (`RPGManager.CanPartBeUnequipped`, `ItemModificationSystem.InstallItemPart`).
- **The slot element has no quality prereq, and the slot is `unlockedBy: Common`:** otherwise the
  slot is hidden on low-quality guns.
- **Mod screen wraps:** the mod screens intersect each item's real slots with hardcoded lists
  (`InventoryDataManagerV2.GetAttachmentSlotsForInventory`,
  `UIInventoryItemModsStaticData.GetAttachmentSlots`), so feed slots are appended there.
- **On-hit hook is `DamageSystem.ProcessStatusEffects`:** the effect is added to the attack data
  before vanilla applies the attack's status effects, so vanilla's blocked, friendly and immunity
  checks still apply to it.

## NPC ammo

Vanilla NPCs never use inventory ammo: shots go through script `AIWeapon.Fire` (from
`AISubActionShootWithWeapon`) and the engine takes nothing from the NPC's inventory; reloads are
`AISubActionReloadWeapon_Record_Implementation` (`StartReload`/`StopReload`).

- **Stock:** the first time a hostile NPC draws a gun, every gun it carries gets
  `npcMagazines.<rarity>` × magazine capacity of its ammo. Like the player's, the stack includes the
  loaded rounds. NPCs friendly to the player and companions aren't counted.
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

- Dual wield: only the right-hand gun is watched for the engine restore.
- After the first swap of a session the HUD can show the restored magazine count until the
  queued unload lands (first shot, reload or holster); no round is fired from it.
- NPC guns use their record's ammo, not per-gun selections.
- Ammo of the same type shares one NPC stack; a gun first given to an NPC after its first draw
  adds no stock if the NPC already carries that ammo.
- Boss fights: a boss that runs dry loses its guns. 12 magazines makes it unlikely; untested.
- The selector icon is the generic mod icon. No crafting or loot yet; test items come from CET.
- Weapon cards show the record's ammo count, not the gun's selection.

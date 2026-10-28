# Spike: load held ammo without per-type feed parts

Question: can the player pick any ammo type they hold on the gun's mod screen, with no feed part
to buy or find, nothing used up by fitting it, and options that come and go with what's held?

Answer: yes, with real selector items that the mod keeps in sync and hides from the backpack.
Found by reading the 2.50 scripts; nothing was run in game.

## What the scripts show

- The mod screen gets its parts from `InventoryDataManagerV2.GetPlayerPartsInventoryData`. That
  reads `TransactionSystem.GetItemList` and drops only items `IsItemBlacklisted` rejects:
  `HideInUI`, `TppHead`, `Currency`, `base_fists`. `HideInBackpackUI` is not in that list.
- The backpack drops `HideInBackpackUI` (`backpack_main.script:463`), and so does the stash
  (`UIInventoryItemsManager.GetStashBlacklistedTags`).
- So a selector tagged `HideInBackpackUI` still shows on the mod screen but not in the backpack
  or stash. Do not use `HideInUI`: that would hide it from the mod screen too.
- The player gets `ItemAddedEvent` (`OnItemAddedToInventory`) and `ItemChangedEvent`
  (`OnItemChangedEvent`, which has a `difference` field) when items arrive or quantities change,
  including when ammo hits 0.

## Recommendation

Sync rule: for each ammo type with count > 0, the player holds exactly 1 loose selector for it.
For each type at 0, they hold none. Selectors fitted on guns are left alone.

- Run the sync on `ItemAddedEvent` and `ItemChangedEvent` for `AO_Ammo` items, on load, and when
  the mod screen opens. Run it next frame, because items added this frame aren't in
  `GetItemList` yet.
- A swap returns the old selector to the inventory; the sync then trims the extra one.
- Two guns of one caliber both work: fitting the loose selector on the first gun leaves 0 loose,
  the sync adds another, and the second gun can take that one.
- Selectors: `HideInBackpackUI`, price 0, removed from loot, vendor and crafting lists. The
  per-type feed parts in loot and shops go away.
- The virtual-list version (fake entries in `GetPlayerInventoryPartsForItemRef` plus a selector
  made at install time) also works, but it means faking `InventoryItemData` and changing the
  install path. Only try it if the synced items cause trouble.

## Still to check in game, in the UX spec

- The mod screen refreshes its list when the sync adds or removes a selector while it's open.
- The vendor sell list hides the selectors (it isn't covered above).
- What a fitted selector does once its ammo runs out (today's fallback behaviour).

# Free ammo loading and NPC damage parity: design

Date: 2026-10-28. Status: approved in conversation (parts 1-3), spec written for the record.

Two independent parts from play-testing v1 + the second Uncommons:

1. **Free loading.** Selectors are the only way to pick a gun's round, but nothing hands them out,
   and a fitted selector is gone from the inventory, so a round fitted on one gun can't go on a
   second one. The player should pick any round they hold on the gun's mod screen, for any number
   of guns, with no selector ever visible anywhere else.
2. **NPC damage parity.** A round's damage multiplier (`DamagePerHit` Multiplier on its selector)
   does nothing on NPC shots, because NPC guns have `DamagePerHit` 0. V and NPCs must follow the
   same damage rules.

Background: `docs/spikes/2026-10-28-ammo-loading.md` (why hidden synced selectors),
`docs/DESIGN.md` ("Player: per-gun ammo", "NPCs", "Known gaps").

## Part 1: free loading with hidden, synced selectors

### What the player sees

- The feed slot on the mod screen lists one entry per round of that caliber the player holds at
  least 1 of, Common included. The same round can be fitted on any number of guns.
- Removing the round from a gun leaves the slot empty, which loads the caliber's Common round
  (today's `AOData.SelectedAmmo` fallback).
- A type held at 0 isn't listed.
- **Running out:** a gun keeps its fitted round, goes to 0, and doesn't reload until the player
  picks another round on the mod screen. No automatic switch, ever (user ruling: switching ammo
  by hand is the intended micromanagement).
- Selectors never show in the backpack, the stash, a vendor's sell list or crafting/dismantling.
  They weigh 0 and are worth 0. They exist only as choices on the gun's mod screen.
- Selectors are never in loot, vendor stock or crafting (already true; keep it true).

### Sync rule

For each selector of every caliber (`AmmoOverhaul.<cal>.selectors` / `selectorAmmo`): if the
player holds ≥ 1 of its ammo, the player holds exactly 1 **loose** selector of it; if 0, none.
Selectors fitted on guns are never touched. The ammo count is the inventory quantity (it includes
rounds in magazines, so "0" means truly gone).

- **When:** on `ItemAddedEvent` / `ItemChangedEvent` for an `AO_Ammo` item (including a drop to
  0) and for an `AO_AmmoSelector` item (a fit takes the loose one, a removal returns one), on
  player attach (save load), and when the mod screen opens. The sync runs on the next frame (items
  added this frame aren't in `GetItemList` yet) and is coalesced: many events in one frame make
  one sync.
- Must not recurse: the sync's own add/remove events don't trigger an endless loop (a pending
  flag; a sync that changes nothing schedules nothing).
- Old saves: loose duplicates and loose selectors for ammo held at 0 are removed by the first sync.

### Hiding

- Selectors get the tag `HideInBackpackUI` (backpack and stash filter it; the mod screen's
  `IsItemBlacklisted` doesn't). Not `HideInUI`: that hides them from the mod screen too.
- Weight 0 (check what `Items.Part` gives and override to 0 if needed). Prices stay empty.
- Vendor sell list and crafting/dismantle screens: verify in game; where a selector shows, filter
  `AO_AmmoSelector` in that screen's item list with a wrap.
- An open mod screen must show a selector the sync adds and drop one it removes (verify; if it
  doesn't refresh, trigger the screen's own refresh after a sync).

## Part 2: NPC damage parity

- A round's **damage factor** is the product of the `DamagePerHit` Multiplier modifiers on its
  selector record (1.0 if none, or no selector). Computed once per ammo and cached on
  `AmmoFeedSystem`.
- In `AmmoFeedSystem.RollGunHit` (the `CalculateDamageVariants` hook), when the instigator is not
  the player, the hit's roll factor is multiplied by the damage factor of the ammo the NPC fires
  (`AOData.LoadedAmmo`: rolled Uncommon or preset-fitted selector). Player hits are unchanged (the
  multiplier is already in V's gun stats; applying it again would double it).
- Rounds added later get parity automatically: the factor comes from the same record the player's
  gun uses.
- **Audit:** every stat type any selector modifies is listed in `docs/DESIGN.md` with how it
  reaches NPCs: measured working on an NPC gun, fixed in the hook like damage, or irrelevant with a
  reason (e.g. `ChargeTime`: NPC rail guns have 0). Any stat found broken the same way as damage
  gets the same in-hook treatment.

## Testing (in game, CET harness, `tools/snippets`)

Part 1:
- Getting ammo of a new type adds 1 loose selector; dropping it to 0 removes it.
- The same round fitted on two guns of one caliber, one after the other.
- Backpack data (`HideInBackpackUI` filter) and the vendor sell list show no selector.
- A gun whose fitted round hits 0 keeps the round, reads 0 rounds, and doesn't switch.
- Removing the round loads the Common round.
- Loose duplicates / zero-ammo selectors (old-save state) are cleaned to one per held type.
- No sync loop: selector add/remove events settle (count of syncs bounded).

Part 2:
- `AmmoDamageFactor`: Dumbfires 1.8, Mushrooms 1.2, a Common round 1.0, 4ga Slugs 1.3 (all
  from records).
- An NPC firing Mushrooms (or Dumbfires) at V lands hits about ×factor those of the same NPC on
  the Common round, measured inside the damage roll's range with the rig's NPC-shoots-V phase.
- V's Uncommon hits are not multiplied twice.

## Out of scope

How rounds load into the gun (built), NPC ammo rolls/stock/loot, a hotkey or quick-switch,
the Rare/Epic tiers.

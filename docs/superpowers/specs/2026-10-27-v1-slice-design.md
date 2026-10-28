# v1 slice: Common and Uncommon ammo for three calibers

A test package that proves the whole ammo path end to end, for one caliber of each family, before
the full v1 lineup (13 calibers, Common to Epic) is built. Everything the full v1 needs should be
exercised here once: new caliber items, ammo types that change the gun, NPCs carrying and dropping
them, vendors selling them and world loot turning into them.

## What the user asked for

- v1 ammo is a Common standard round plus one Uncommon, one Rare and one Epic per caliber. No
  faction or legendary rounds, no explosive rounds, no crafting yet.
- This slice: only Common and Uncommon, one caliber per family, one gun per caliber, packaged so
  it can be tested in game.
- Higher tiers are meant to be rare and expensive; how often a tier turns up also depends on its
  family (Tech common, Smart rare). The slice only has to show the mechanism for that, not the
  final numbers.

Settled at review: the three guns are the Lexington, Omaha and Yukimura; the test rounds
(incendiary, explosive, dragon) and their selectors are dropped. Selectors use their round's
icon, so a fitted selector looks like ammo loaded into the gun (custom icons later keep that
look), and the weapon screen gets an Ammo section of its own.

## Scope

| Family | Caliber key | Gun in this slice | Common | Uncommon |
|---|---|---|---|---|
| Power | `Power_9mm` (P-9) | Lexington | 9mm Ball (FMJ, vanilla `Ammo.HandgunAmmo`) | 9mm Mushrooms (hollow point) |
| Tech | `Tech_Light` (T-LIGHT, 5mm) | Omaha | 5mm Rail Slugs (new item) | 5mm Sleevers (sabot) |
| Smart | `Smart_10` (S-10, 10mm micro-rocket) | Yukimura | 10mm Seekers (new item) | 10mm Dumbfires |

All three guns use `Ammo.HandgunAmmo` in vanilla. So the slice also covers the split this mod
makes everywhere: one vanilla ammo item becomes several calibers, and only one of them keeps the
vanilla item.

Out of scope: Rare and Epic rounds, the other 10 calibers and the other guns of these three,
crafting, faction lines, final balance numbers, icons beyond a reused vanilla one.

## The ammo types

Each type is an ammo item (the stack in the inventory) plus a selector part (fitted in the gun's
feed slot, it picks which stack the gun uses and changes the gun). Numbers are starting points
to tune in game.

### 9mm Hollow Point (Power, Uncommon)

Expands on impact: hits harder against flesh, worse against armor.

- Selector: `DamagePerHit` ×1.2; `CanWeaponIgnoreArmor` −0.5 (the target's armor counts 1.5×).
- Effect: about +20% against unarmored targets, break-even at about 67 armor, worse above (an NPC
  with 100 armor: 1/(1+1.5) ×1.2 = 0.48 of the hit, against 0.5 for FMJ).
- Read from `DamageSystem.ProcessArmor`: armor is multiplied by `1 − pen` with no lower limit, so
  negative pen raises armor. Untested in game. Side effect to check: a pen of 0 or below lets a
  hit show as a Glance against any armor, as FMJ already does.

### 5mm Sabot (Tech, Uncommon)

A lighter slug in a sleeve: the rails get it up to speed sooner.

- Selector: `ChargeTime` ×0.7 (Omaha 1.5 s → about 1.05 s); `DamagePerHit` ×0.95.
- Untested: whether `ChargeTime` set through a part changes the charge, and whether the charge HUD
  follows.

### 10mm Dumbfire (Smart, Uncommon)

Smart rocket with the guidance taken out and the space filled with propellant: flies straight,
hits harder.

- Selector: `DamagePerHit` ×1.25 and no homing.
- Two ways to turn homing off, to try in this order:
  1. `SmartGunHitProbability` ×0 (the stat a smart bullet reads to decide whether it homes, seen
     in `samples/sampleSmartBullet.script`). The lock-on still shows.
  2. `SmartGunTargetAcquisitionRange` ×0, so nothing gets locked at all.
  If neither works, the fallback is a package override to a non-guided projectile attack
  (`OverrideRangedAttackPackageEffector`, proven on our selectors).

### Common rounds

- 9mm Ball is vanilla handgun ammo, renamed, with no other changes.
- 5mm Rail Slugs and 10mm Seekers are new ammo items that change nothing on the gun. Their
  selectors exist so the player can switch back from the Uncommon round.

## Data

Records stay in TweakXL YAML. The slice is small enough to write by hand; when the full v1 is
built, this layout is what a generator script would produce from a caliber-by-type table, so
nothing here changes then.

Split `poc_9mm.yaml` into:

- `core.yaml`: mod settings (`AmmoOverhaul.calibers`, NPC magazines, distribution shares),
  vanilla ammo weights.
- `power_9mm.yaml`, `tech_light.yaml`, `smart_10.yaml`: one file per caliber, each with its feed
  slot and element, ammo items, selectors and the caliber's `AmmoOverhaul.<caliber>.*` flats.
- `test.yaml`: test enemies only (a ganger per gun with the Uncommon selector fitted).

Per caliber, as today: `weaponTags` (`Lexington`, `Omaha`, `Yukimura`), `feedSlot`,
`feedElement`, `defaultAmmo`, `selectors`, `selectorAmmo`. New per-caliber fields:

- `family` (`Power`, `Tech` or `Smart`) and `selectorTiers` (0 Common, 1 Uncommon, parallel to
  `selectors`), for distribution.
- `vanillaAmmo`: the vanilla item the caliber's loot is taken from (`Ammo.HandgunAmmo` for all
  three here).

Ammo item names and weights:

| Item | Weight | Base |
|---|---|---|
| `Ammo.HandgunAmmo` (FMJ) | 0.06 (existing) | vanilla |
| `Ammo.AO_9mm_HollowPoint` | 0.06 | `Ammo.HandgunAmmo` |
| `Ammo.AO_TLight_Slug`, `Ammo.AO_TLight_Sabot` | 0.04 | `Ammo.HandgunAmmo` |
| `Ammo.AO_S10_Standard`, `Ammo.AO_S10_Dumbfire` | 0.08 | `Ammo.HandgunAmmo` |

New items set `quality` (Common or Uncommon) so the inventory shows the tier colour, and carry
`AO_Ammo` plus `AO_Tier_<n>` and `AO_Family_<name>` tags.

## Names and descriptions

Each round has a slang or technical name and a short description in the voice of someone at a
gun counter, ending with a plain effect line (ammo items show no stats). The selector uses the
same name and description, so the weapon screen reads as loading that round. No made-up lore
details; check whose point of view each line takes.

| Item | Name | Description |
|---|---|---|
| `Ammo.HandgunAmmo` | 9mm Ball | Plain FMJ. Cheapest 9 in town, and every gun shop's got a crate of it. *Standard 9mm. No special effects.* |
| `Ammo.AO_9mm_HollowPoint` | 9mm Mushrooms | Hollow points. They open up on impact and tear through anyone not wearing armor. Hit plating and they just flatten out. *+20% damage. Armor is 50% more effective against it.* |
| `Ammo.AO_TLight_Slug` | 5mm Rail Slugs | Steel slugs for light railguns. Nothing to them, the rails do all the work. *Standard light rail ammo. No special effects.* |
| `Ammo.AO_TLight_Sabot` | 5mm Sleevers | Skinny slug in a plastic sleeve. The rails grab it quicker, so you charge faster, but it hits a bit softer. *Charges 30% faster. −5% damage.* |
| `Ammo.AO_S10_Standard` | 10mm Seekers | Standard smart rockets. Get a lock and they chase the target for you. *Standard smart ammo. Tracks locked targets.* |
| `Ammo.AO_S10_Dumbfire` | 10mm Dumbfires | Smart rockets with the chip pulled and extra propellant packed in. Hits harder, but it only goes where you point it. *+25% damage. Doesn't track targets.* |

- Keys: `AO-Ammo-<id>` and `AO-Ammo-<id>-Desc` (ids `9mm-Ball`, `9mm-Mushrooms`,
  `5mm-RailSlugs`, `5mm-Sleevers`, `10mm-Seekers`, `10mm-Dumbfires`), in `Localization.reds`.
  Selectors point at the same keys. The section label is `AO-Section-Ammo` ("Ammo"); the slot
  keeps `AO-Slot-AmmoFeed`.
- Renaming 9mm Ball means setting `displayName` and `localizedDescription` on the vanilla
  `Ammo.HandgunAmmo`, so ammo already in saves shows the new name too.
- The effect numbers in the text must match the selector stats; when stats are tuned, the text
  is updated with them.
- The old test keys (incendiary, explosive, dragon) are removed.

## Code changes

### Load time (`AmmoFeedTweak.reds`)

No change in logic: each caliber's guns get its default ammo and feed slot. The Omaha's and
Yukimura's records are set to the new Common item.

### UI

**Selector icons.** Each selector's `iconPath` is its ammo item's (the UI draws
`"UIIcon." + iconPath`), in place of the generic mod icon. The empty feed slot shows an ammo
icon too, dimmed like other empty slots.

**An Ammo section on the weapon screen.** `InventoryWeaponItemChooser` builds two sections:
Attachments (the scope, magazine and silencer part types, `RebuildParts`) and Mods (every other
slot, from `GetSlots`). The feed slot is a slot without one of those part types, so it lands
under Mods. The change:

- Wrap `GetSlots` to leave the feed slot out, so Mods shows only real mods (and its label hides
  when the gun has none, through the existing `UpdateModsLabel` count, which needs the same
  filter).
- After `RebuildSlots`, add an "Ammo" label and slot container next to the Mods ones, built by
  copying their widgets (same style), and spawn the feed slot's display there with
  `ItemDisplayUtils.SpawnCommonSlotController`, as the chooser does for its own slots.
- Order: Attachments, Ammo, Mods. Untested: copying the widgets keeps layout and focus
  navigation working (controller and mouse); fallback is to leave the slot in Mods with its label
  renamed when it's the only one. Other screens that list a weapon's slots (tooltips, the crafting
  upgrade screen) keep showing it as a mod in the slice.

**Ammo icons.**

- Vanilla picks ammo icons and HUD labels by record ID for the four vanilla items
  (`UIItemsHelper` around line 670). New items fall back to a missing icon. Wrap the lookup to
  return the icon of the item's `$base` vanilla ammo for `AO_Ammo` items. The real icons come
  later.
- Check that the HUD, weapon cards and D-pad wheel show the new items' counts (the existing menu
  wraps already count the selected ammo).

### NPCs (`NpcAmmo.reds`)

- Guns of the new calibers already get stock from the selection or default ammo; this only needs
  testing.
- **Uncommon on NPCs:** when an NPC's stock is first created, roll for each managed gun whether it
  carries the Uncommon round instead: by NPC rarity times the family's Uncommon share (below). On
  a hit, fit the Uncommon selector into the gun's feed slot through the transaction system, so its
  stats, the on-hit effects and the loot all follow the existing paths. Untested: fitting a part
  to an NPC's gun at runtime. Fallback: weapon presets with the selector fitted, picked from the
  character's equipment (as `test.yaml` does).

### Vendors (new, `Vendors.reds`)

- Wrap `Vendor.InitializeStock` and `Vendor.RegenerateStock` (`marketSystem/vendor.script`); after
  vanilla builds `m_stock`, replace each stack of a vanilla ammo item that one of our calibers
  takes from: split its quantity across those calibers' ammo items by the shares below.
- Ammo is always in stock (`Vendor.AlwaysInStock`), so the rewritten stacks restock like vanilla
  ammo.
- Uncommon only at weapon vendors (`gamedataVendorType.WeaponVendor`); vending machines and other
  vendors get Common only.

### World loot (new, `LootConvert.reds`)

Containers and loose ammo come from native loot tables that only know the four vanilla items.
They're converted the first time they're opened or picked up:

- Find the earliest script point where a container's contents are known and the player hasn't
  seen them yet (candidates: the loot container's interaction or the looting UI opening; to be
  found during planning). Converting there means the loot window already shows the real ammo.
- Fallback if no such point exists: convert on arrival in the player's inventory (the loot window
  shows vanilla names, the inventory the real ones).
- Each converted stack is split by the same shares as vendors, with a bias toward calibers of guns
  the player carries (the stack goes to a carried gun's caliber with `AmmoOverhaul.loot.ownedBias`,
  0.6 to start). Otherwise a Lexington player keeps picking up rockets.
- Converted containers are marked so they aren't converted twice; the mark is saved.

### Shares

One small table in `core.yaml`, read by vendors, world loot and NPCs:

| Family | Common | Uncommon |
|---|---|---|
| Power | 0.85 | 0.15 |
| Tech | 0.75 | 0.25 |
| Smart | 0.90 | 0.10 |

Calibers that take loot from the same vanilla item split it by `AmmoOverhaul.<caliber>.lootWeight`
(9mm 0.6, Tech_Light 0.25, Smart_10 0.15 to start).

## Saves

- Existing saves: the player's handgun ammo becomes 9mm Ball. An Omaha or Yukimura they own now takes
  the new Common round and starts empty until they find or buy some. Acceptable for a test build;
  the test kit gives the rounds.
- Removing the mod: items of new records disappear from saves, as with any TweakXL item mod.

## Testing (in game, CET harness)

The test kit gives the three guns, all six selectors and a stack of each round. Checks:

1. The weapon screen shows Attachments, Ammo and Mods; the feed slot is only under Ammo, shows
   the fitted round's icon (or the empty ammo icon), and works with mouse and controller.
2. Each gun loads, fires and counts its default round; fitting each selector switches the stack,
   unloads the gun and changes the HUD count and icon.
3. Hollow point: damage against a spawned unarmored and an armored enemy compared with FMJ (the
   harness reads health before and after a set number of hits).
4. Sabot: Omaha `ChargeTime` and time to full charge read before and after fitting.
5. Dumbfire: shots don't home (fire at a moving enemy off-axis), damage up 25%.
6. NPCs: a test ganger per gun with the Uncommon fitted uses and drops that round; random gangers
   carrying an Omaha or Yukimura drop the new Common round, some the Uncommon.
7. Vendors: a gun shop's stock shows 9mm, 5mm and 10mm stacks in roughly the set shares, and
   Uncommon only at gun shops; restock after the restock time keeps the split.
8. Loot: a container with vanilla handgun ammo shows (or gives) the new items; reopening it
   doesn't convert again; with only a Lexington carried, most converted ammo is 9mm.
9. Saves: save and reload keeps the fitted selectors, the stacks and the converted-container marks.

## Settled at review

- The owned-gun bias for loot starts at 0.6 (tunable).
- Uncommon is sold at gun shops only.

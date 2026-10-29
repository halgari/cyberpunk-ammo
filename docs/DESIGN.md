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
  - `AmmoSection.reds`: the Ammo section on the weapon screen.
  - `AmmoDistribution.reds`: how vanilla ammo is shared out among calibers and tiers.
  - `Vendors.reds`: vendor ammo stock.
  - `LootConvert.reds`: ammo in loot containers.
  - `Hooks.reds`: wraps of vanilla functions for the player side and the UI.
  - `Localization.reds`: text, served through Codeware.
- `art/icons/`: source art for item icons. `tools/icons/build.sh` packs it into
  `src/archive/AmmoOverhaul.archive` (an .inkatlas and its texture, via WolvenKit on Proton:
  `tools/linux/wolvenkit.sh`); each icon is a `UIIcon.AO_*` record that items name in `iconPath`.
- `native/AmmoOverhaul/`: the RED4ext plugin (C++). `native/AOProbe/` is a research probe, not
  part of the mod.
- `tools/linux/`: build, compile check, deploy and the in-game harness (see `docs/TESTING.md`).
- `reference/` (gitignored): decompiled 2.50 scripts (`reference/scripts`, the one to search) and
  the vanilla script bundle the compile check uses.

## Data model

TweakXL rejects unknown properties on existing record types, so the mod's settings live in
standalone `AmmoOverhaul.*` flats keyed by short names (read by `AOData.reds`):

- `AmmoOverhaul.calibers`: caliber names (`Power_9mm`, `Power_45`, … `Tech_Light`, `Smart_25`:
  the 13 in `docs/CATALOG.md`).
- Per caliber, `AmmoOverhaul.<caliber>.*`:
  - `weaponTags`: weapons carrying any of these tags belong to the caliber.
  - `weaponRecords`: weapon records that belong to it although they carry none of its tags
    (Kolac, Osprey, the Mk.31 HMG, the Malorian 3516, Hercules 3AX, Rasetsu and others).
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
normal ammo items based on `Ammo.HandgunAmmo`, with their own quality, Weight stat and price. The
four vanilla ammo items are Common rounds, renamed: handgun ammo is 9mm Ball, rifle ammo 5.56
Ball, sniper ammo 12.7 Ball, shotgun ammo 12ga Buckshot. Every other round is a new item.

Guns aren't modified beyond which stack they load from, so a Common round fires exactly like the
gun's vanilla ammo. Only a selector for an Uncommon round changes stats (its `statModifiers`
apply to the gun while it's fitted). Calibers differ in ammo weight, price and availability.

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

## Selectors: free loading

Selectors are the only way to pick a gun's round, and a fitted one leaves the inventory, so the
player is kept holding exactly one **loose** selector per round they have at least 1 of (Common
included), and none for a round at 0. Any number of guns can then take the same round: fitting
takes the loose one, the sync hands out the next.

- **The sync** (`SelectorSync.reds`, state on `SelectorSyncSystem`: redscript rejects `@addField`
  on the mod's own `AmmoFeedSystem`): for each selector of every caliber, gives or removes loose
  copies until there is 1 if `GetItemQuantity` of its ammo is > 0 (that count includes loaded
  rounds), else 0. Fitted selectors are inner items of the gun, never in the loose list, so they're
  never touched: a gun whose round runs out keeps it fitted at 0 and doesn't reload until the
  player picks another round (no automatic switch). Removing the round loads Common.
- **Triggers:** item added, changed and removed on V for ammo (tag `Ammo` or `Con_Ammo`: vanilla
  `HandgunAmmo` drives the 9mm Ball selector) and for selectors; part install and remove; player
  attach (so a save's leftover duplicates and zero-ammo selectors go on load); the mod screen
  opening. One pending flag and `DelayCallbackNextFrame`: many events in a frame make one sync, the
  next frame (items added this frame aren't in the item list yet). The sync's own adds and removes
  queue one follow-up that changes nothing and schedules nothing. Its items skip the activity log.
- **Open mod screen:** refreshed after any sync that changed something (vanilla has no handler for
  an added part).
- **Hidden everywhere else:** selectors are tagged `HideInBackpackUI` (backpack and stash drop it;
  the mod screen's `IsItemBlacklisted` doesn't, unlike `HideInUI`), weigh 0 and have no price. The
  vendor sell list (`VendorDataManager.GetItemsPlayerCanSellFast`) is wrapped to drop
  `AO_AmmoSelector` items. Crafting and dismantling list only craftable/disassemblable items, which
  selectors aren't (from the scripts; not tested live).

Checked by `calibers/sync.sh` (new round adds a selector, 0 removes it, vanilla 9mm, the same
round on two guns, fitted not counted, run-out stays fitted, removal loads Common, duplicate
cleanup, bounded syncs, open mod screen) and `calibers/hidden.lua` (tags, weight, backpack item
map, stash blacklist, mod screen lists it, vendor sell list with a bypassed control).

## NPC ammo

Vanilla NPCs never use inventory ammo: shots go through script `AIWeapon.Fire` (from
`AISubActionShootWithWeapon`) and the engine takes nothing from the NPC's inventory; reloads are
`AISubActionReloadWeapon_Record_Implementation` (`StartReload`/`StopReload`).

- **Stock:** the first time a hostile NPC draws a gun, every gun it carries gets
  `npcMagazines.<rarity>` × magazine capacity of its ammo. A gun of a managed caliber uses the
  ammo its feed slot selects, as for the player (a preset can fit a selector through
  `slotPartListPreset`); other guns use their record's. Like the player's, the stack includes the
  loaded rounds. NPCs friendly to the player and companions aren't counted.
- **Better rounds:** before stocking a managed gun with an empty feed slot, the NPC rolls once
  per tier, Epic first, then Rare, then Uncommon (`NpcAmmo.RollTier`): chance = the family's share
  of the tier × `npc<Uncommon|Rare|Epic>Factor.<rarity>`, capped at 1; the first hit wins. Only
  Rare and higher ranks roll Rare rounds, only Elite and Boss roll Epics (Boss twice as often).
  On a hit the gun is stocked with one of that tier's rounds at random (`NpcAmmo.PickTier`) and
  the selector's stat modifiers are added straight to the gun's stats. No part is fitted:
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
  character (`dropsAmmoOnDeathChance` = 0). A body leaves at most `npcLootWeight` (6) carry
  points of each round, by the round's Weight stat. NPCs still carry and fire their whole stock;
  the cap is only on the loot.
- **Heavy machine guns:** the NPC presets (`Preset_HMG_*`) are on 12.7, so a heavy is stocked
  with its 200-round belt × magazines (1200 rounds for an Elite) and runs dry like anyone else.
  The loot cap leaves 40 rounds of 12.7 on the body.
- **Not counted:** guns whose record ammo is `Ammo.Standard` (melee weapons, cyberware and a few
  others) stay unlimited until they get a real ammo type.

## Distribution

Our rounds replace a share of a vanilla ammo item (`vanillaAmmo`). A caliber's share is its
`lootWeight`; within a caliber each tier gets its family's share (`AmmoOverhaul.shares.<family>`),
counting only the tiers allowed (`AmmoDistribution.reds`).

| Vanilla ammo | Is | Also split into (share) |
|---|---|---|
| Handgun ammo | 9mm Ball (0.40) | .45 (0.20), 12mm (0.10), 5mm rail (0.15), 10mm smart (0.15) |
| Rifle ammo | 5.56 Ball (0.65) | 7.62 (0.35) |
| Sniper ammo | 12.7 Ball (0.60) | heavy rail (0.30), 25mm dart (0.10) |
| Shotgun ammo | 12ga Buckshot (0.70) | 4-gauge (0.10), 20mm cluster (0.20) |

Heavy rail comes from sniper ammo although its guns used all four vanilla items.

- **Spread** splits a quantity in those proportions (vendors). 1000 handgun rounds at a gun shop
  become about 340 9mm Ball and 60 Mushrooms, 170 .45 Ball and 30 Mushrooms, 85 12mm Ball and 15
  Mushrooms, 112 Rail Slugs and 38 Sleevers, 135 Seekers and 15 Dumbfires.
- **Pick** chooses one round for a whole stack (loot): with chance `loot.ownedBias` a caliber of a
  gun the player carries, else one by `lootWeight`; then a tier by share, then one of the tier's
  rounds at random. Loot picks up to Epic.
- **Several rounds per tier:** a tier's share is split evenly among its rounds (Spread rounds by
  largest remainder), so a caliber's two Uncommons each get half its Uncommon share. NPCs that
  roll a tier pick one of its rounds at random (`NpcAmmo.PickTier`).
- **Vendors:** each stack of a replaced vanilla ammo is split whenever the vendor builds its stock
  (`Vendor.InitializeStock`, `RegenerateStock`). Gun shops (`Gunsmith`) sell up to Rare, other
  vendors Common only. Epics come only from loot and NPCs. A restock rebuilds the stock from the vendor's pool and drops our split
  stacks first (they're regenerating items), so nothing is split twice. Vendors whose stock has
  been split are kept on `AmmoFeedSystem` (saved); stock saved before the mod was installed is
  split the first time the vendor fills its inventory (`FillVendorInventory`). Contents can't
  tell: 9mm Ball is vanilla handgun ammo, and a stock bought down to Ball would otherwise be split
  again on every load.
- **Loot containers:** a container fills with loot the first time the player looks at it
  (`gameLootContainerBase.OnInventoryFilledEvent`). Then each stack of replaced vanilla ammo
  becomes one Pick (up to Epic), same quantity. Converted containers are kept by entity ID on
  `AmmoFeedSystem` (saved), so a container converts once.
- **NPC bodies** drop the round their gun used (see NPC ammo).

## Damage roll

Every ranged gun hit, by V or an NPC, is multiplied by a roll (`DamageRoll.reds`, applied in a
wrap of `DamageSystem.CalculateDamageVariants`). Vanilla rolls 0.90..1.10 on V's hits only; the
mod's default is 0.90..1.01 on everyone's, so guns are a little weaker on average. Melee,
explosions and damage over time keep vanilla's roll.

A roll is a dud (`dudChance`, damage times `dudMult`), else a hot round (`hotChance`, times
`hotMult`), else uniform in `min`..`max`. Values come from four layers, the first one set wins:

1. the round: `<ammo>.rollMin`, `.rollMax`, `.rollDudChance`, `.rollDudMult`, `.rollHotChance`,
   `.rollHotMult` (standalone flats, as TweakXL won't add properties to an item record);
2. its faction: `AmmoOverhaul.roll.<faction>.min` ..., where `<ammo>.aoFaction` names the faction;
3. its family: `AmmoOverhaul.roll.<Power|Tech|Smart>.min` ... (declared at −1, unset);
4. global: `AmmoOverhaul.roll.min` ... in `core.yaml`, always set.

A value below 0 is unset. Appending a damage type (`Physical`, `Thermal`, `Electric`, `Chemical`)
gives a per-type value (`<ammo>.rollMinThermal`, `AmmoOverhaul.roll.Power.minThermal`); a type no
layer sets uses the whole-hit roll. Each type with its own values rolls on its own; the rest share
one draw. The round a shot is loaded with is `AOData.LoadedAmmo` (the NPC's rolled or selected
round, V's selection, or the gun record's ammo for unmanaged guns). Resolved rolls and each weapon
record's caliber are cached on `AmmoFeedSystem`.

The tooltip's damage range comes from the base weapon's min/max factors
(`Items.Base_Weapon_inline106/107` and `Items.Base_Weapon_Damage_Type_Min_Max_*`); the max ones are
set to 1.01 to match. Melee weapons use their own records and keep 0.9..1.1. A round with its own
range doesn't change the tooltip yet (none ships with one).

## Hit data

What a round does on a hit besides damage, kept as flats on its ammo record (`AOData`), and
applied in the damage pipeline to V's shots and NPCs' alike:

- `<ammo>.aoEffects` / `aoEffectChances`: status effects and the chance of each per shot
  (`AmmoFeedSystem.ApplyAmmoOnHit`, before vanilla applies the attack's effects, so its blocked,
  friendly and immunity checks still apply). Each of a shot's n pellets rolls
  1 - (1 - chance)^(1/n) (`AOData.PelletChance`), so a Dragon's Breath shot burns 60% of the time,
  not on nearly every shot. On V, burning, poison, bleeding and EMP become vanilla's Player versions
  (`AOData.PlayerEffect`: `PlayerBurning`, `PlayerPoisoned`, `PlayerBleeding`, `PlayerElectrocuted`),
  as vanilla does for its own weapons. The 4ga Slug's knockdown is one of these.
- `aoShareType` / `aoShare`: that share of the hit's Physical damage moves to Thermal, Electric
  or Chemical (`AmmoFeedSystem.ApplyHitDamage`, after the roll).
- `aoMachineBonus`: every damage type times this against a machine (`AOData.IsMachine`: a
  vehicle, drone, turret or mechanical puppet). Measured: x1.8..1.96 on a security android's
  hits (`calibers/hitdata.sh`).
- `aoNonlethal`: the hit carries the game's non-lethal flag, so a killing shot knocks out (the
  target is Unconscious; a Ball kill on the same ganger is not, `calibers/hitdata.sh`).

The round is the one the gun is loaded with (`AOData.LoadedAmmo`). The Rare and Epic rounds are
generated with their hit data (`tools/rounds/rounds.py`).

## NPC damage parity

NPC guns have `DamagePerHit` 0 (their damage comes from elsewhere), so the `DamagePerHit`
Multiplier on a round's selector part (Mushrooms 1.2, +P 1.1, Dumbfires 1.8, 4ga Slugs 1.3, ...)
does nothing when added to an NPC gun's stats. `AmmoFeedSystem.RollGunHit` applies it instead:
for a hit whose instigator is not the player, every damage-type multiplier is also multiplied by
`AmmoFeedSystem.DamageFactor(ammo)`, the product of the `DamagePerHit` Multiplier modifiers on the
selector that feeds the round (`AOData.SelectorForAmmo`, `AOData.AmmoDamageFactor`; cached like
the calibers), and by the gun's pellet ratio (see the audit). Unmanaged ammo and Common rounds are 1.0. V's own hits are not multiplied here:
V's gun's `DamagePerHit` carries the modifier already. The `DamagePerHit` modifier still lands
on the NPC gun's stats, but is multiplied against 0, so it never doubles.

Checked by `calibers/parity.lua` (factors per round, generic over every tier-1 round) and
`calibers/parity.sh` (the Mushrooms ganger, the stat audit below, and live hits: a Mushrooms
Lexington on V is 1.2 x the roll, a Common one the plain roll, and V's own Mushrooms hits are
rolled once).

### Stat audit

Every stat type a selector modifies (read from `src/tweaks/AmmoOverhaul/*.yaml`), and how it
reaches NPC shots. The modifiers are added to the NPC gun's stats object (`NpcAmmo.RollUncommon`).
`calibers/parity.sh` reads the gun's stats while it is in an NPC's hand (a `Plain_*` NPC with the
roll forced on, against the same gun with the roll off) and compares them with what the selector
says. Rare and Epic rounds are read the same way with the roll forced to their tier.

| Stat | On NPC shots |
| --- | --- |
| `DamagePerHit` | Broken (NPC gun value 0): fixed in the roll hook, checked by `parity.lua`/`parity.sh`. |
| `CanWeaponIgnoreArmor` | Works. Measured on a Mushrooms NPC gun in hand (`slice/npcdrop.sh`: -0.5). |
| `SmartGunHitProbability` | Works. Measured: Yukimura with Dumbfires 1 -> 0. |
| `ProjectilesPerShot` | Count: was broken for combined modifiers (see below), fixed in `NpcAmmo.ToModifier`. Damage: the engine splits an NPC shot's damage by the pellet count twice (per-pellet damage about 1 / pellets squared; V's shot total stays the same), so Birdshot did ~0.44 of Common per shot and Slugs ~3.7; fixed in the roll hook (`AmmoFeedSystem.PelletRatio`: NPC hits times the gun's `ProjectilesPerShot` over that count without the round's own change, so a gun whose vanilla count differs from its base keeps vanilla damage on the Common round). Measured at 3 m (`calibers/parity.sh`, `pellets.sh`): 12ga Slugs 3 -> 1, Birdshot 3 -> 6, 4ga Birdshot 7 -> 17.5; Birdshot lands up to 6 pellets; per-shot damage of Birdshot and Slugs within 0.6..1.5 of Common. |
| `HitReactionFactor` | Works. Measured: 12ga and 4ga Birdshot 2 -> 2.5. |
| `EffectiveRange`, `MaximumRange`, `SpreadDefault*`, `SpreadMax*`, `SpreadAds*` | No effect: NPC guns have 0 for them, with or without the round, so a multiplier changes nothing. Known gap. |
| `RecoilKickMin/Max`, `WeaponEvolutionToStaminaCost` | Irrelevant: NPCs have no camera recoil and no stamina. |
| `ChargeTime` | Known gap: NPC rail guns have `ChargeTime` 0. |
| `Weight`, `Price` | Irrelevant: inventory and vendor stats of the ammo item. |
| `CanSilentKill` | Works. Measured: 9mm Subsonic 0 -> 1. |
| `RicochetChance`, `RicochetCount` | Work. Measured: 9mm Bouncers 0 -> 0.3 and 0 -> 1. |
| `HitDismembermentFactor` | Works. Measured: 9mm Shredders 0.5 -> 1. |
| `BulletMagnetismDefaultAngle` | Works. Measured: 5mm Feedback 0 -> 2. |
| `TechPierceChargeLevel`, `TechPierceDamageFactor` | Work. Measured: 5mm DU Pen 0.9 -> 0.45 and -0.44 -> -0.22. Damage through cover is times (1 + factor) (`DamageSystem`), so DU Pen keeps 78% instead of 56%. The charge level caps at 1, so it can't stop a full charge from piercing. |
| `TechPierceEnabled` | Irrelevant: NPC rail guns have 0. On V's Omaha Split Slugs take it 1 -> 0 (measured). |
| `FullAutoOnFullCharge` | Works. Measured: 5mm Superconductor 0 -> 1. |
| `SmartGunHipMaxLockedTargets`, `SmartGunAdsMaxLockedTargets` | Work. Measured: 10mm Hunter 0 -> 2. |
| `SmartGunHipTimeToLock`, `SmartGunAdsTimeToLock` | Irrelevant: 0 on NPC smart guns (the AI aims). |
| `SmartGunHitProbability` (Hunter's +0.2) | Irrelevant: an NPC smart gun is already at the cap, 1. |
| `SmartGunPlayerProjectileVelocity` | Irrelevant: V's rounds only. |
| `WeaponNoise`, `SwayTraversalTime`, `SwaySideMaximumAngleDistance` | Irrelevant: 0 on NPC guns. |
| `ProjectilesPerShot` (exactly n: Split Slugs 3, Toxic Scatter 5) | The gun's `ProjectilesPerShotBase` is taken away and n added. V's Omaha (3, base 3) gets 3 and 5 (measured). An NPC Omaha fires 1 but has base 3, so it gets 1 and 3 (measured; Known gaps). Damage per shot stays right through the pellet ratio. |

Combined modifiers ("add value times a stat of the gun", used for pellet counts):
`RPGManager.StatRecordToModifier` reads their value from a null record, and on an NPC's gun the game
ignored it (measured: a Slug's -1 added the gun's pellets, a 4ga Birdshot's 1.5 added them once). For
these `NpcAmmo.ToModifier` works the amount out (value times the gun's reference stat) and adds a
constant.

## Crafting

Records come from `tools/crafting/crafting.py` (run after `tools/rounds/rounds.py`); hooks are in
`Crafting.reds`. Spec: `docs/superpowers/specs/2026-10-29-ammo-crafting-design.md`.

- **Cost per batch:** the family sets the count (Tech 1, Power 2, Smart 4), the tier the grade
  of component. `Crafting.AO_Cost_<family>_<tier>` packages, set as each round's `CraftingData`
  in `zz_crafting_costs.yaml` (record updates: TweakXL can't type a one-line foreign-key flat,
  and the file loads after the caliber files). The 4 vanilla ammo items keep vanilla's cost.
- **Batch:** `AmmoOverhaul.<caliber>.craftBatch` for Common; Uncommon 1/2, Rare 1/3, Epic 1/4,
  rounded half up. Each round's `aoRecipe` names an `ItemRecipe` making that batch; the wrapped
  `GetAmmoBulletAmount` reads it (vanilla's switch only knows its 4 items).
- **Recipes:** every caliber's Common round is added on player attach (vanilla adds its own once
  per save, behind facts). Uncommon and up are `Items.AO_Recipe_<round>` items: picking one up
  teaches it (vanilla's `CraftingSystemInventoryCallback`, tag `Recipe`); they never show in the
  backpack. Loot and NPC bodies with an Uncommon+ round carry its recipe at `recipeDropFactor`;
  gun shops list each Uncommon and Rare recipe at `recipeVendorChance` per restock. A recipe item
  costs `recipePriceBatches` batches of its round.
- **Disassembly:** vanilla gives 1 Common component per round of any ammo. Rounds now break down
  per full batch (`aoScrapRounds`: the Common batch, twice that for Tech) into `aoScrapGive`
  components (1, Smart 2) of the round's quality; leftover rounds give nothing. Feed selectors
  can't be broken down.

## Weight and inventory

- Ammo items have a Weight stat (about one carry point per typical magazine). Stack items update
  carried weight by the quantity difference (`PlayerPuppet` `OnItemQuantityChanged`), so every
  shot and pickup moves it. Existing stacks in a save pick it up on load.
- The backpack lists ammo: `UIInventoryItemsManager.GetBlacklistedTags` no longer includes `Ammo`.

## Known gaps

- Dual wield: only the right-hand gun is watched by the safety net.
- Ammo of the same type shares one NPC stack; a gun first given to an NPC after its first draw
  adds no stock if the NPC already carries that ammo.
- NPC rail guns have `ChargeTime` 0, so Sleevers change nothing for them.
- NPC guns have no value (0) for `EffectiveRange`, `MaximumRange` and the spread stats, so a round's
  multipliers on them (+P range, Short Fuse range, Slug and Birdshot spread) do nothing for NPCs.
  `calibers/parity.sh` reads the stats and fails if one of them stops being 0.
- NPC Tech guns whose shot count differs from `ProjectilesPerShotBase` (the Omaha: 1 against 3)
  get two fewer projectiles than V from Split Slugs and Toxic Scatter (1 and 3, not 3 and 5).
  Damage per shot is unchanged.
- Old saves: vanilla ammo already held becomes the four Common rounds. A gun moved to a new
  caliber (a Unity to .45, a Satara to heavy rail, a Kolac to 12.7, an Omaha to 5mm rail) starts
  empty until its rounds are bought or looted.
- Vendors already split in a save from the slice (which split only handgun ammo) are marked done,
  so their rifle, sniper and shotgun ammo splits across the new calibers only at their next
  restock.
- The NPC round roll isn't saved. After loading a save, an NPC stocked with a better round reads
  its gun's ammo as the Common round again, and its stock holds the better one, so it can run
  dry early. Untested.
- Loose ammo lying in the world (`gameItemDropObject`) and loot bags aren't converted: they stay
  vanilla ammo, which is the Common round of 9mm, 5.56, 12.7 or 12-gauge.
- **Crash:** an NPC killed with a selector fitted in its drawn gun can crash the game (the
  watchdog ends it; about one kill in four with the test gangers of `test.yaml`, whose presets fit
  one). Real NPCs never have one fitted: Uncommon NPCs get the selector's stats, not the part, and
  fitting a part on an NPC's drawn gun hangs the game. A player dropping a fitted gun is fine. Only
  a preset from another mod that fits a selector would hit this.
- Boss fights: a boss that runs dry loses its guns. 12 magazines makes it unlikely; untested.
- The four vanilla ammo items are Common rounds, so a vanilla stack shown anywhere (a quest reward,
  another mod's vendor) shows that round's name and icon.

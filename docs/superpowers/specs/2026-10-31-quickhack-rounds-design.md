# Quickhack rounds: design

Date: 2026-10-31. Status: draft for review. Branch `quickhack-rounds`, on top of `faction-rounds-3`.

Smart rounds that carry a quickhack. The hack's rarity sets the round's rarity, and crafting a box takes
one copy of that quickhack. Shops sell them and NPCs carry and drop them. On V, an NPC's hack round is
a plain smart round.

That's 39 kinds across 10mm, 20mm and 25mm: 117 rounds, taking the mod from 237 to 354.

## The hacks

The game's own rarities, minus Common (Common rounds stay vanilla) and the 4++ versions. The record is
the quickhack crafting takes.

- **Reboot Optics:** Uncommon `BlindLvl1Program`, then `BlindLvl2Program`, `Lvl3`, `Lvl4`.
- **Sonic Shock:** Uncommon `CommsNoiseProgram`, then `CommsNoiseLvl2Program`, `Lvl3`, `Lvl4`.
- **Contagion:** Uncommon `ContagionProgram`, then `ContagionLvl2Program`, `Lvl3`, `Lvl4`.
- **Cyberware Malfunction:** Uncommon `DisableCyberwareProgram`, then `DisableCyberwareLvl2Program`, `Lvl3`, `Lvl4`.
- **Short Circuit:** Uncommon `EMPOverloadLvl1Program`, then `EMPOverloadLvl2Program`, `Lvl3`, `Lvl4`.
- **Cripple Movement:** Uncommon `LocomotionMalfunctionProgram`, then `LocomotionMalfunctionLvl2Program`, `Lvl3`, `Lvl4`.
- **Overheat:** Uncommon `OverheatLvl1Program`, then `OverheatLvl2Program`, `Lvl3`, `Lvl4`.
- **Weapon Glitch:** Uncommon `WeaponMalfunctionProgram`, then `WeaponMalfunctionLvl2Program`, `Lvl3`, `Lvl4`.
- **Synapse Burnout:** Rare `BrainMeltLvl2Program`, then `Lvl3`, `Lvl4`.
- **Cyberpsychosis:** Epic `MadnessLvl3Program`, then `Lvl4`.
- **Detonate Grenade:** Epic `GrenadeExplodeLvl3Program`, then `Lvl4`.

## On hit

- Each shot rolls: Uncommon 10%, Rare 15%, Epic 20%, Legendary 25%. Starting points for the feel test.
- A hit applies the status effect that tier of the hack applies, so tiers differ as they do in vanilla.
  No upload bar and no RAM cost. It goes through the mod's existing per-shot effect path, so one roll
  per shot on a burst.
- **Probe first:** read each program's action for its effect records. A hack whose effect doesn't work
  applied directly gets a stated substitute, and the user hears about it before the plan. Detonate
  Grenade is the likely one: vanilla's works through the grenade the target holds.
- Contagion spreads as The Clap does, through a blast (`AmmoOverhaul.ClapCloud`), since the effect
  doesn't spread by itself. The radius grows with rarity.
- **Who's immune:** quest protected NPCs and machines get nothing that would knock out or kill them, as
  with the faction rounds. Boss and MaxTac get nothing from Cyberpsychosis. Drones get nothing.
- **On V:** an NPC firing one does its normal damage and nothing more. This is the user's ruling, and
  the one stated exception to NPCs and V following the same rules.

## Tiers

Own tier codes, `HACK_UNCOMMON` to `HACK_LEGENDARY` (10 to 13), for the same reason faction rounds have
theirs: the general lists match tiers exactly, so 11 hacks don't swamp each smart caliber's rolls.
Quality comes from the code as usual.

## Getting them

- **Shops:** gun shops stock Uncommon and Rare hack rounds, in the Rare cap's existing rule. Vendors who
  sell quickhacks stock Uncommon to Epic. Legendary is never sold.
- **NPCs with smart guns:** roll a hack round before the general roll, by rank: Normal 3%, Officer 5%,
  Elite 8%, Boss 12%. Legendary is 1 in 10 of those on Elite and Boss, never lower. They fire them and
  drop what's left.
- **Netrunners:** whatever gun they hold, they drop a small stack of a smart caliber's hack round, by
  the same rank table. **Probe first:** a stat or tag that marks a netrunner, as the record name isn't
  safe. If none exists, this part drops out and the user hears about it.
- **Containers:** none, as faction rounds.

## Crafting

- One box takes one copy of the matching quickhack, plus the usual components by family (Smart).
- Hack rounds' recipes are known from the start, as Common rounds' are, because the quickhack is what
  limits them. This replaces a load sheet per round: 117 more sheets would crowd the loot pool.
- Legendary hack rounds can be crafted, unlike other Legendaries. A Legendary quickhack is the price.
- Breaking a box down returns components only, never the quickhack.
- **Double removal:** `CraftingSystem.CraftItem` removes a program ingredient twice when V holds more
  than one (5 held, 1 craft, 3 left). A wrap on `CraftItem` counts the quickhack before and after, and
  gives back whatever went beyond the recipe's cost. Vanilla recipes don't take programs, so nothing
  else changes.
- Installed hacks are parts of the deck and count 0 as inventory, so crafting can't take them. V needs
  a spare copy, and the recipe screen shows it as missing otherwise.

## Text

- Name: the caliber, the vanilla hack name and the tag `[Hack]`, such as `10mm Reboot Optics [Hack]`, so
  the name says which quickhack to bring. Rarity shows in the colour, as quickhacks' does.
- Description: one plain line and the numbers, such as "Carries a Reboot Optics payload.\n\n10% chance
  per shot to blind the target."
- Public text describes the family and names no Legendary.

## Art

- One icon per hack and rarity, shared by the three calibers: 39 cells, 276 of the atlas's 300 used.
- A data cartridge marked with the hack's own icon from the game, its colour by rarity.
- Legendaries get their own object, approved as a form first, shared by the 11 hacks with the hack's mark.

## Testing

New mechanisms only, in `tools/snippets/calibers/quickhack.sh`:

- Each hack on a live hit, one tier each, plus Normal, Boss and Immortal targets where the rules differ.
- An NPC's hack round on V adds no status.
- NPC rolls by rank, and the general smart lists stay clear of them.
- Netrunner drop, and shop stock by vendor type.
- Crafting: 1 held costs 1, 5 held costs 1, a batch costs its amount, an installed hack isn't taken.
- `records.lua`, `icons.lua`, `distribution.lua` and `tiers.lua` at 354 rounds. Full suite before release.

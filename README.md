# Brass Market

Brass Market (internally AmmoOverhaul) is a Cyberpunk 2077 (2.50) mod that replaces the game's four ammo types with 13 calibers and about
149 rounds, from plain ball to Legendary, for V and NPCs alike.

## What it does

- **Calibers.** Each gun takes the caliber that fits it: 9mm, .45, 12mm magnum, 5.56, 7.62,
  12.7, 12-gauge, 4-gauge, light and heavy rail slugs, and 10mm, 20mm and 25mm smart rounds
  (`docs/CATALOG.md` lists every gun).
- **Rounds.** Every caliber has Common, Uncommon, Rare and Epic rounds: hollow points, steel
  core, incendiary, subsonic, flechettes, dumbfire smart rounds and more. Most calibers also
  have a Legendary round that does something no other round does. Common rounds behave
  like the game's ammo; better rounds change damage, armor, range, effects on hit.
- **Choosing a round.** A gun's mod screen gets an Ammo section: pick any round you carry for
  that caliber. The gun loads it from then on, until you pick another.
- **NPCs.** NPCs carry real rounds, better ones the tougher they are, fire them under the same
  damage rules as V, and drop what they carry.
- **Getting rounds.** Vendors and loot hand out every caliber and tier; gun shops sell up to
  Rare. Every caliber's Common round can be crafted; better rounds need a recipe ("load sheet")
  from loot or a gun shop. Rounds break down by the box into components of their own grade.

## Requirements

Cyberpunk 2077 2.50, with RED4ext 1.31, TweakXL 1.12, ArchiveXL 1.28, Codeware 1.21 and
redscript 0.5.32 or newer. Cyber Engine Tweaks is only needed for the test tools.

## Install and uninstall

Install with a mod manager, or extract the zip into the game folder (the one holding `bin` and
`r6`). It adds `r6/scripts/AmmoOverhaul`, `r6/tweaks/AmmoOverhaul`,
`archive/pc/mod/AmmoOverhaul.archive` and `red4ext/plugins/AmmoOverhaul`.

Existing saves work: ammo you hold becomes the Common rounds of 9mm, 5.56, 12-gauge and 12.7.
A gun that moved to a new caliber (a Unity to .45, a Satara to heavy rail, a Kolac to 12.7, an
Omaha to light rail) starts empty until you buy or find its rounds.

Don't remove the mod from a playthrough you'll keep: rounds, recipes and fitted ammo choices
belong to the mod and are lost or broken without it. Keep a save from before installing.

## Known gaps

- Loose ammo lying in the world stays the game's own ammo, which is the Common round of 9mm,
  5.56, 12.7 or 12-gauge.
- Some rounds' range and spread changes do nothing for NPCs (the game gives NPC guns no range or
  spread values).
- More in `docs/DESIGN.md`, "Known gaps".

## For developers

- `docs/DESIGN.md`: how the mod works. `docs/CATALOG.md`: guns, calibers and rounds.
- `docs/TESTING.md`: the dev loop (Linux, Lutris/GE-Proton) and the in-game checks.
- `docs/RELEASING.md`: building the zip and releasing to GitHub and Nexus Mods.

## License

GPL-3.0. See `LICENSE`.

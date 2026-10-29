# Nexus Mods page

The mod page text, in Nexus's BBCode, ready to paste into the description field. Keep it in step
with README.md. The upload settings for the first file are at the end.

```
[size=5][b]Ammo Overhaul[/b][/size]

The game's four ammo types become 13 calibers and about 130 rounds, from plain ball to Epic match grade. V and NPCs play by the same rules.

[size=4][b]Calibers[/b][/size]
Every gun takes the caliber that fits it:
[list]
[*][b]Power:[/b] 9mm, .45, 12mm magnum, 5.56, 7.62, 12.7, 12-gauge and 4-gauge.
[*][b]Tech:[/b] light and heavy rail slugs.
[*][b]Smart:[/b] 10mm, 20mm and 25mm guided rounds.
[/list]

[size=4][b]Rounds[/b][/size]
Each caliber has Common, Uncommon, Rare and Epic rounds: hollow points, steel core, incendiary, subsonic, flechettes, dumbfire smart rounds and more. Common rounds work like the game's ammo. Better rounds change damage, armor, range or what a hit does.

Pick a gun's round in the new [b]Ammo[/b] section of its mod screen. The gun loads that round until you pick another.

[size=4][b]NPCs[/b][/size]
NPCs carry real rounds, better ones the tougher they are. They fire them under the same damage rules as you, and you can loot what they carry.

[size=4][b]Getting rounds[/b][/size]
[list]
[*]Vendors and loot hand out every caliber and tier. Gun shops sell up to Rare; Epic rounds only turn up as loot.
[*]Every caliber's Common round can be crafted from the start. Better rounds need a recipe ("load sheet") from loot or a gun shop.
[*]Tech rounds are the cheapest to craft and Smart rounds the most expensive.
[*]Rounds break down by the box into components of their own grade.
[/list]

[size=4][b]Requirements[/b][/size]
Cyberpunk 2077 2.50, with RED4ext, TweakXL, ArchiveXL, Codeware and redscript.

[size=4][b]Install[/b][/size]
Use a mod manager, or extract the zip into the game folder (the one holding [i]bin[/i] and [i]r6[/i]).

Existing saves work. Ammo you hold becomes the Common rounds of 9mm, 5.56, 12-gauge and 12.7. A gun that moved to a new caliber (a Unity to .45, a Satara to heavy rail, a Kolac to 12.7, an Omaha to light rail) starts empty until you buy or find its rounds.

[b]Don't remove the mod from a playthrough you'll keep.[/b] Its rounds, recipes and ammo choices are lost or broken without it, so keep a save from before you install it.

[size=4][b]Known issues[/b][/size]
[list]
[*]Loose ammo lying in the world stays the game's own ammo, which counts as the Common round of 9mm, 5.56, 12.7 or 12-gauge.
[*]Some rounds' range and spread changes do nothing for NPCs, because the game gives NPC guns no range or spread values.
[/list]

Source: https://github.com/halgari/cyberpunk-ammo
```

## First upload (by hand)

The Nexus upload action only adds versions to a file that already exists, so the first file goes
up through the site:

- **Game:** Cyberpunk 2077. **Category:** Gameplay (or Weapons).
- **Requirements** (Requirements tab): RED4ext, TweakXL, ArchiveXL, Codeware, redscript.
- **File:** `dist/AmmoOverhaul-<version>.zip` from `tools/linux/release.sh <version>`.
  Category Main, version as in `VERSION`, name "Ammo Overhaul".
- Then note the **mod ID** (in the page URL) and the **file ID** (Files tab, "Advanced"), and
  finish the setup in `docs/RELEASING.md`.

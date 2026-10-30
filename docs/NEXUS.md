# Nexus Mods page

The mod page text, in Nexus's BBCode, ready to paste into the description field. Keep it in step
with README.md and docs/CATALOG.md. The main image is `art/banner/main-4k.png` (made by
`tools/render/banner.py`). The upload settings for the first file are at the end.

Nexus BBCode notes: `[spoiler]`, `[line]`, `[center]`, `[color=#hex]` and `[size=1-6]` all work;
tables don't render reliably, so everything is lists. The tier colors are the game's own rarity
colors (Common grey, Uncommon green, Rare blue, Epic purple, Legendary orange).

```
[center][size=6][b][color=#d4a04c]BRA€$[/color][color=#9aa3ad]MARKET[/color][/b][/size]
[size=4]An ammo overhaul: 13 calibers, 149 rounds, and the shops, loot and crafting that go with them[/size][/center]

[line]

The base game has four kinds of ammo. [b]Brass Market[/b] has 13 calibers and 149 different rounds, from plain ball up to Legendary. Gun shops stock the rounds, NPCs carry and fire them, you can craft them from recipes, and you can break boxes down for components.

Each gun is assigned the caliber that fits it. Each caliber has Common, Uncommon, Rare and Epic rounds. You pick which round the gun loads from its mod screen.

[size=5][b][color=#2ad4ff]What the mod adds[/color][/b][/size]
[list]
[*]13 calibers: 9mm, .45, 12mm magnum, 5.56, 7.62, 12.7, 12-gauge, 4-gauge, light and heavy rail slugs, and 10mm, 20mm and 25mm smart rounds.
[*]149 rounds: hollow points, steel core, incendiary, subsonic, rubber, flechettes, dragon's breath, thermite slugs, depleted uranium, EMP payloads and more.
[*]An [b]Ammo[/b] slot on every gun's mod screen. Fit any round you carry for that caliber and the gun loads it until you change it.
[*]NPCs carry rounds from the mod, and tougher NPCs carry better ones. Their rounds work on you the same way yours work on them, so a gang boss loaded with steel core gets the same armor pen against you that you'd get against him. NPCs can run out of ammo. When they do, they switch to another gun or fight with their fists. Whatever they still have is what you loot.
[*]Gun shops stock every caliber up to Rare. Recipes drop from loot and are also sold in gun shops. You craft rounds by the box and break boxes down for components.
[*]Each round has its own box icon with the name printed on it, so Mushrooms and Penetrators look different in your backpack.
[/list]

[size=5][b][color=#2ad4ff]How it works: ammo is a gun mod[/color][/b][/size]
A round is implemented as a weapon mod with charges. Every gun gets an [b]Ammo[/b] slot on its mod screen, next to the scope and muzzle slots. Fit a round there and the gun carries that round's stats for as long as it stays fitted. The rounds in your backpack are the charges, and each shot uses one.
[list]
[*]Because it's a mod on the gun, a round can change anything a gun mod can: damage, armor pen, damage type, spread, range, charge time, how many projectiles come out, what happens on a hit.
[*]One stack feeds every gun of its caliber. Fit Steel-Core on your Lexington and your Saratoga and both draw from the same box.
[*]The gun doesn't switch rounds on its own. When a round runs out the gun stays empty until you fit another, so it won't start spending your Epic rounds without you choosing to.
[*]Take the round out and the gun goes back to Common.
[/list]
The rest of the mod covers where rounds come from: shops, loot and crafting.

[size=5][b][color=#2ad4ff]Progression[/color][/b][/size]
Brass Market is horizontal progression. Better ammo isn't tied to your level. You get it from loot, shops or crafting, and once you have it you decide when to use it.

Higher tier rounds run out. An SMG loaded with Epic Penetrators will go through a box in one fight, and each new box costs Epic components to craft.

Which round you fit depends on the job. Rubber is for a job where nobody can die, Subsonic for going in quietly, EMP or Shaped Charge for a floor full of drones, and Ball for gangers who don't need anything better.

NPCs carry the same rounds you do and fire them during the fight. Whatever an NPC shoots at you comes out of the stack you'd loot, so a merc firing Toxin Core has fewer rounds left by the time you reach the body.

The three families cost different amounts to craft. Tech slugs are the cheapest, which suits guns that spray. Smart rounds have the most payload types (EMP, fire, chem, flash, hacks) and cost the most. Power is in the middle and has the most calibers and loads.

Which gun is worth using depends partly on what ammo you have for it. A 9mm you'd otherwise sell is worth keeping if you're holding 400 rounds of Incendiary for it. Carrying guns in two or three calibers lets you shoot whatever ammo you've picked up instead of sticking to one gun type all game.

[size=5][b][color=#2ad4ff]Tiers[/color][/b][/size]
[list]
[*][color=#b0b0b0][b]Common[/b][/color]: the caliber's plain round. Works like the game's ammo did, with no bonuses.
[*][color=#3fbf5f][b]Uncommon[/b][/color]: two per caliber. Small trades: more damage for less armor pen, faster charge for less punch.
[*][color=#3fa0ff][b]Rare[/b][/color]: specialist loads. Fire, ricochets, non-lethal, quiet, armor piercing.
[*][color=#b04fff][b]Epic[/b][/color]: Penetrators, toxin cores, thermite, EMP, match grade. Loot only; no shop sells it.
[*][color=#e8a33c][b]Legendary[/b][/color]: one per caliber, each doing something no other round does. Carried by elite enemies, bosses and MaxTac, and now and then found in a stash that already holds Epic rounds. Not sold and not craftable; they come in small stacks.
[/list]

[size=5][b][color=#2ad4ff]Legendary rounds[/color][/b][/size]
[list]
[*][color=#e8a33c][b]Gatecrasher[/b][/color] (7.62, 12.7): ignores all armor, no damage falloff, goes through cover at full damage.
[*][color=#e8a33c][b]Cook-off[/b][/color] (9mm, .45, 12mm, 5.56, 7.62): a kill sets off a blast at the body that hurts everyone close by, you included. An enemy's Cook-off hit on you sets off your own grenade if it's charged.
[*][color=#e8a33c][b]Kebab[/b][/color] (light and heavy rail): a charged shot goes through every body and wall in its line with no damage lost.
[*][color=#e8a33c][b]Lockout[/b][/color] (10mm, 20mm, 25mm): every hit jams the target's weapon for 4 seconds.
[*][color=#e8a33c][b]Mule Kick[/b][/color] (4-gauge): every hit knocks the target down, tough ones stagger. Each shot shoves you hard away from your aim, so a shot at the floor sends you up.
[*][color=#e8a33c][b]Heartseeker[/b][/color] (12-gauge): one guided slug that locks onto heads, no Smart Link needed. Ignores all armor, +100% headshot damage, +50% crit chance.
[/list]

[line]

[size=5][b][color=#2ad4ff]Calibers[/color][/b][/size]
Each gun is assigned one of the calibers below and loads only rounds of that caliber.

[size=4][b][color=#d4a04c]Power[/color][/b][/size] (gunpowder cartridges)
[list]
[*][b]9mm[/b]: Lexington, Slaught-O-Matic, Guillotine, Pulsar, Saratoga, Erebus, Cook-off
[*][b].45[/b]: Unity, Liberty, Nue, Cook-off
[*][b]12mm magnum[/b]: Nova, Overture, Metel, Malorian Arms 3516
[*][b]5.56[/b]: Umbra, Masamune, Copperhead, Defender, Cook-off
[*][b]7.62[/b]: Ajax, Kyubi, MA70 HB, Gatecrasher, Cook-off
[*][b]12.7[/b]: Kolac, SOR-22, Grad, Osprey, Mk.31 HMG, Gatecrasher
[*][b]12-gauge[/b]: Crusher, Pozhar, Tactician, Igla, Testera, Heartseeker
[*][b]4-gauge[/b]: Carnage
[/list]

[size=4][b][color=#2ad4ff]Tech[/color][/b][/size] (rail-fired slugs)
[list]
[*][b]Light rail (5mm)[/b]: Kenshin, Ticon, Omaha, Grit, Senkoh LX, Quasar
[*][b]Heavy rail[/b]: Burya, Achilles, Nekomata, Rasetsu, Satara, Kebab
[/list]

[size=4][b][color=#ff5a5a]Smart[/color][/b][/size] (guided micro-rockets)
[list]
[*][b]10mm[/b]: Chao, Kappa, Yukimura, Dian, Shingen, Warden, Hercules 3AX, Sidewinder, Lockout
[*][b]20mm cluster[/b]: Zhuo, Palica
[*][b]25mm dart[/b]: Ashura
[/list]

Guns keep their vanilla fire rate, pellet count and handling. The caliber decides which box a gun draws from, and the round decides what the shot does when it hits. Heavier calibers weigh more and cost more.

[line]

[size=5][b][color=#2ad4ff]The rounds[/color][/b][/size]
What each load does. Percentages are changes from the plain round.

[size=4][b][color=#d4a04c]Pistol and rifle rounds[/color][/b][/size]
[list]
[*][color=#b0b0b0][b]Ball[/b][/color] (Common): the plain round.
[*][color=#3fbf5f][b]Mushrooms[/b][/color] (Uncommon): hollow points. +20% damage, armor matters more.
[*][color=#3fbf5f][b]+P[/b][/color] (Uncommon): hot loads. +10% damage, +15% range, more recoil.
[*][color=#3fa0ff][b]Steel-Core[/b][/color] (Rare): ignores 25% of armor. -10% damage.
[*][color=#3fa0ff][b]Incendiary[/b][/color] (Rare): a chance to set the target on fire, a quarter of the damage is fire.
[*][color=#3fa0ff][b]Subsonic[/b][/color] (Rare): much quieter, kills stay silent. A little less damage and range.
[*][color=#3fa0ff][b]Bouncers[/b][/color] (Rare): 30% chance to ricochet once.
[*][color=#3fa0ff][b]Rubber[/b][/color] (Rare): non-lethal, targets go down unconscious. Big flinch.
[*][color=#3fa0ff][b]Hardcast[/b][/color] (Rare, 12mm): 25% chance to stagger, a little armor pen, more kick.
[*][color=#3fa0ff][b]Ballistic Tip[/b][/color] (Rare, 7.62 and 12.7): +40% range, +5% damage.
[*][color=#3fa0ff][b]Ping[/b][/color] (Rare, 7.62 and 12.7): targets hit show through walls for 5 seconds. -10% damage.
[*][color=#b04fff][b]Penetrator[/b][/color] (Epic): ignores 60% of armor. In 12mm, 7.62 and 12.7 it also goes through thin cover at half damage.
[*][color=#b04fff][b]Match[/b][/color] (Epic): tight damage roll that sits high, 30% less spread and sway.
[*][color=#b04fff][b]Toxin Core[/b][/color] (Epic): 25% chance to poison, 30% of the damage is chemical.
[*][color=#b04fff][b]Shredders[/b][/color] (Epic): 30% chance to cause bleeding, twice the dismemberment.
[*][color=#b04fff][b]HEI[/b][/color] (Epic, 12.7): +50% damage against drones, mechs and vehicles, and a chance to set targets on fire.
[/list]

[size=4][b][color=#d4a04c]Shotgun shells[/color][/b][/size]
[list]
[*][color=#b0b0b0][b]Buckshot[/b][/color] (Common): the plain shell.
[*][color=#3fbf5f][b]Slugs[/b][/color] (Uncommon): one projectile carrying the whole shot, tight spread and long range. 4-gauge slugs hit harder and knock targets down.
[*][color=#3fbf5f][b]Birdshot[/b][/color] (Uncommon): twice the pellets, wide spread, big flinch.
[*][color=#3fa0ff][b]Flechettes[/b][/color] (Rare): tighter spread, double range.
[*][color=#3fa0ff][b]Beanbags[/b][/color] (Rare, 12ga): non-lethal knockdown.
[*][color=#3fa0ff][b]Riot[/b][/color] (Rare, 4ga): non-lethal knockdown.
[*][color=#3fa0ff][b]Dragon's Breath Lite[/b][/color] (Rare, 12ga): half fire damage, 30% chance to ignite.
[*][color=#3fa0ff][b]Flares[/b][/color] (Rare, 4ga): blinds the target, may set it on fire.
[*][color=#b04fff][b]Dragon's Breath[/b][/color] (Epic): all fire damage, sets targets badly on fire.
[*][color=#b04fff][b]Frag-12[/b][/color] (Epic, 12ga): explosive slug. Ignores 50% of armor, +50% against drones, mechs and vehicles.
[*][color=#b04fff][b]Long Flechettes[/b][/color] (Epic, 12ga): tight spread, 3.5x range.
[*][color=#b04fff][b]Thermite Slugs[/b][/color] (Epic, 4ga): sets targets badly on fire, double damage against drones, mechs and vehicles.
[/list]

[size=4][b][color=#2ad4ff]Rail slugs[/color][/b][/size] (light and heavy rail)
[list]
[*][color=#b0b0b0][b]Rail Slugs[/b][/color] (Common): the plain slug.
[*][color=#3fbf5f][b]Sleevers[/b][/color] (Uncommon): 30% faster charge, slightly less damage.
[*][color=#3fbf5f][b]Bricks[/b][/color] (Uncommon): +15% damage, slower charge.
[*][color=#3fa0ff][b]Ferro[/b][/color] (Rare): 40% chance to ricochet, up to twice.
[*][color=#3fa0ff][b]Split Slugs[/b][/color] (Rare): three projectiles per shot, wider spread.
[*][color=#3fa0ff][b]Feedback[/b][/color] (Rare): shots bend toward targets near the crosshair.
[*][color=#b04fff][b]DU Penetrator[/b][/color] (Epic): pierces cover at a lower charge, loses half as much through it, ignores 50% of armor.
[*][color=#b04fff][b]Toxic Scatter[/b][/color] (Epic): five projectiles per shot, 25% chance to poison.
[*][color=#b04fff][b]Superconductor[/b][/color] (Epic): full auto at full charge.
[*][color=#b04fff][b]EMP Capacitor[/b][/color] (Epic): 30% chance of an EMP, 30% of the damage is electrical.
[/list]

[size=4][b][color=#ff5a5a]Smart rounds[/color][/b][/size] (10mm, 20mm, 25mm)
[list]
[*][color=#b0b0b0][b]Seekers[/b][/color] (Common): the plain guided round.
[*][color=#3fbf5f][b]Dumbfires[/b][/color] (Uncommon): no guidance, +80% damage.
[*][color=#3fbf5f][b]Short-Fuse[/b][/color] (Uncommon): +20% damage, much shorter reach.
[*][color=#3fa0ff][b]EMP Payload[/b][/color] (Rare): 25% chance of an EMP, part electrical damage.
[*][color=#3fa0ff][b]Incendiary Payload[/b][/color] (Rare): 25% chance to set targets on fire, part fire damage.
[*][color=#3fa0ff][b]Chem Payload[/b][/color] (Rare): 25% chance to poison, part chemical damage.
[*][color=#3fa0ff][b]Flash Payload[/b][/color] (Rare): 30% chance to blind the target.
[*][color=#b04fff][b]Hunter[/b][/color] (Epic): locks two more targets, locks on twice as fast, flies 30% faster.
[*][color=#b04fff][b]Hack Carrier[/b][/color] (Epic): chance of a cyberware malfunction or a jammed weapon.
[*][color=#b04fff][b]Shaped Charge[/b][/color] (Epic): ignores 50% of armor, +50% against drones, mechs and vehicles.
[/list]

[spoiler]
[b]Every round, by caliber[/b]
[list]
[*][b]9mm[/b]: Ball, Mushrooms, +P, Steel-Core, Incendiary, Subsonic, Bouncers, Rubber, Penetrator, Match, Toxin Core, Shredders
[*][b].45[/b]: Ball, Mushrooms, +P, Steel-Core, Incendiary, Subsonic, Bouncers, Rubber, Penetrator, Match, Toxin Core, Shredders
[*][b]12mm[/b]: Ball, Mushrooms, +P, Steel-Core, Incendiary, Rubber, Hardcast, Penetrator, Match, Toxin Core, Shredders, Cook-off
[*][b]5.56[/b]: Ball, Mushrooms, +P, Steel-Core, Incendiary, Subsonic, Bouncers, Penetrator, Match, Toxin Core, Shredders
[*][b]7.62[/b]: Ball, Mushrooms, +P, Steel-Core, Incendiary, Ballistic Tip, Ping, Penetrator, Match, Toxin Core, Shredders
[*][b]12.7[/b]: Ball, Mushrooms, +P, Steel-Core, Incendiary, Ballistic Tip, Ping, Penetrator, Match, Toxin Core, HEI
[*][b]12-gauge[/b]: Buckshot, Slugs, Birdshot, Flechettes, Beanbags, Dragon's Breath Lite, Dragon's Breath, Frag-12, Long Flechettes
[*][b]4-gauge[/b]: Buckshot, Slugs, Birdshot, Flechettes, Riot, Flares, Dragon's Breath, Thermite Slugs
[*][b]Light rail[/b]: Rail Slugs, Sleevers, Bricks, Ferro, Split Slugs, Feedback, DU Penetrator, Toxic Scatter, Superconductor, EMP Capacitor, Kebab
[*][b]Heavy rail[/b]: Rail Slugs, Sleevers, Bricks, Ferro, Split Slugs, Feedback, DU Penetrator, Toxic Scatter, Superconductor, EMP Capacitor
[*][b]10mm[/b]: Seekers, Dumbfires, Short-Fuse, EMP Payload, Incendiary Payload, Chem Payload, Flash Payload, Hunter, Hack Carrier, Shaped Charge
[*][b]20mm[/b]: Seekers, Dumbfires, Short-Fuse, EMP Payload, Incendiary Payload, Chem Payload, Flash Payload, Hunter, Hack Carrier, Shaped Charge, Lockout
[*][b]25mm[/b]: Seekers, Dumbfires, Short-Fuse, EMP Payload, Incendiary Payload, Chem Payload, Flash Payload, Hunter, Hack Carrier, Shaped Charge, Lockout
[/list]
[/spoiler]

[line]

[size=5][b][color=#2ad4ff]The market[/color][/b][/size]
[size=4][b]Buying[/b][/size]
[list]
[*]Gun shops stock every caliber, Common to Rare. Other vendors that sold ammo sell Common rounds.
[*]Epic rounds aren't sold anywhere. They only come from loot.
[/list]

[size=4][b]Looting[/b][/size]
[list]
[*]NPCs carry ammo for the gun they're holding, and tougher NPCs carry better rounds. You loot whatever they have left after the fight.
[*]Ammo in containers becomes any caliber and tier, leaning toward the guns you carry.
[/list]

[size=4][b]Crafting[/b][/size]
[list]
[*]Every caliber's Common round is craftable from the start.
[*]Better rounds need a [b]load sheet[/b]: a recipe that drops from loot or turns up in gun shops. Picking it up teaches you the recipe.
[*]Rounds craft by the box, from components of the round's own grade: Common components for Common rounds, up to Epic components for Epic rounds. Higher tiers make smaller boxes.
[*]What a box costs depends on the family. [b]Tech[/b] slugs are the cheapest (1 component a box), [b]Power[/b] cartridges cost twice that (2), and [b]Smart[/b] rounds are the most expensive (4).
[/list]

[size=4][b]Breaking down[/b][/size]
[list]
[*]Disassemble rounds by the full box for components of their own grade. Odd rounds stay in the stack.
[/list]

[line]

[size=5][b][color=#2ad4ff]Requirements[/color][/b][/size]
Cyberpunk 2077 [b]2.50[/b], with:
[list]
[*]RED4ext
[*]TweakXL
[*]ArchiveXL
[*]Codeware
[*]redscript
[/list]

[size=5][b][color=#2ad4ff]Install[/color][/b][/size]
Use a mod manager, or extract the zip into the game folder (the one holding [i]bin[/i] and [i]r6[/i]).

[b]Existing saves work.[/b] Ammo you already hold becomes the Common rounds of 9mm, 5.56, 12-gauge and 12.7. A gun that moved to a new caliber (a Unity to .45, a Satara to heavy rail, a Kolac to 12.7, an Omaha to light rail) starts empty until you buy or find its rounds.

[color=#ff5a5a][b]Don't remove the mod from a playthrough you'll keep.[/b][/color] Its rounds, recipes and ammo choices are lost or broken without it. Keep a save from before you install it.

[size=5][b][color=#2ad4ff]Compatibility and how it's built[/color][/b][/size]
[list]
[*][b]Hooked functions.[/b] Brass Market wraps a lot of game functions. A wrap chains with other mods' wraps, but a mod that replaces or hooks the same functions may break this one or be broken by it. The ones most likely to clash:
[list]
[*]damage calculation: [i]DamageSystem.CalculateDamageVariants[/i] and [i]ProcessStatusEffects[/i]
[*]NPC weapons: [i]AIWeapon.Fire[/i], NPC reload, NPC equipment and loot ([i]ScriptedPuppet.EvaluateLootQuality[/i], death and knockout)
[*]the weapon mod screen and part install and removal ([i]ItemModificationSystem[/i], [i]RPGManager.CanPartBeUnequipped[/i], the mod screen's slot lists)
[*]vendor stock ([i]Vendor.InitializeStock[/i], [i]RegenerateStock[/i], [i]FillVendorInventory[/i]) and loot containers
[*]ammo crafting and disassembly ([i]CraftingSystem[/i], [i]GetAmmoBulletAmount[/i])
[*]ammo counts on the HUD, weapon cards and the weapon wheel ([i]RPGManager.GetAmmoCountValue[/i] and friends)
[/list]
Other ammo, damage, vendor and loot overhauls are the likely conflicts.
[*][b]Damage variance.[/b] The game rolls your gun damage between 90% and 110% of the listed number and doesn't roll NPC damage at all. Brass Market replaces that roll ([i]CalculateDamageVariants[/i]) for every ranged gun hit, yours and NPCs': 90% to 101% by default, so guns are a little weaker on average and both sides roll the same way. Match rounds roll in a narrower, higher band. Melee, explosions and damage over time keep the game's roll. A mod that changes damage variance will conflict with this.
[*][b]Same damage for NPCs.[/b] NPC guns have no damage stat for a round to modify, so their rounds' multipliers are applied in the damage pipeline instead. A Mushrooms round hits as hard from their gun as from yours.
[*][b]Native plugin.[/b] A small RED4ext plugin writes each gun's loaded ammo into the weapon itself. That's how one gun can load a different round than the game's data says. It finds what it needs at runtime and checks before every write, so after a game patch it stops working instead of corrupting anything.
[*][b]Guns from other mods[/b] get a caliber if they carry a vanilla gun's family tag (most guns built on a vanilla gun do). Others keep using the game's ammo.
[/list]

[size=5][b][color=#2ad4ff]Known issues[/color][/b][/size]
[list]
[*][b]Two reloads after changing rounds is expected.[/b] Fitting a new round empties the gun (the rounds go back in your pack, nothing is lost). Back in the game, V looks the gun over, then draws it and reloads it with the new round. It looks like two reloads in a row, but it's an inspect, then a draw and one reload.
[*]Loose ammo lying around the world is still the game's own ammo, which counts as the Common round of 9mm, 5.56, 12.7 or 12-gauge.
[*]Some rounds' range and spread changes do nothing for NPCs, because the game gives NPC guns no range or spread values.
[/list]

[line]

[size=5][b][color=#2ad4ff]Coming next[/color][/b][/size]
The next version adds:
[list]
[*][b]Legendary rounds.[/b] Extremely rare and hard to find.
[*][b]Faction ammo.[/b] Rounds made by Night City's gangs and corps, each matching its faction's quirks. Most of it probably won't be craftable; you'd get it from the people who use it.
[/list]

[line]

[center]Source and bug reports: [url=https://github.com/halgari/cyberpunk-ammo]github.com/halgari/cyberpunk-ammo[/url][/center]
```

## First upload (by hand)

The Nexus upload action only adds versions to a file that already exists, so the first file goes
up through the site:

- **Game:** Cyberpunk 2077. **Category:** Gameplay (or Weapons).
- **Name:** Brass Market. **Main image:** `art/banner/main-4k.png`.
- **Requirements** (Requirements tab): RED4ext, TweakXL, ArchiveXL, Codeware, redscript.
- **File:** `dist/AmmoOverhaul-<version>.zip` from `tools/linux/release.sh <version>`.
  Category Main, version as in `VERSION`, name "Brass Market".
- Then note the **mod ID** (in the page URL) and the **file ID** (Files tab, "Advanced"), and
  finish the setup in `docs/RELEASING.md`.

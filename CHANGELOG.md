# Changelog

Each release's section is its GitHub release notes and its Nexus Mods changelog
(`tools/linux/release.sh` reads the section under the version's heading).

## Unreleased

- Quickhack rounds: 117 new rounds, 354 in all. Smart rounds in 10mm, 20mm and 25mm that carry a
  quickhack, with a chance per shot to land it with no upload and no RAM: Reboot Optics, Sonic Shock,
  Contagion, Cyberware Malfunction, Short Circuit, Cripple Movement, Overheat, Weapon Glitch, Synapse
  Burnout, Cyberpsychosis and Detonate Grenade. The hack's rarity is the round's, marked [Hack] in the
  name, and the chance goes up with it: 10%, 15%, 20% and 25%, or 4%, 6%, 8% and 10% for Contagion,
  Short Circuit and Synapse Burnout. Gun shops stock them up to Rare and netrunner vendors up to Epic.
  NPCs with smart guns carry them, and netrunners drop them. The recipes are known from the start: a
  box takes one spare copy of the quickhack plus Smart components. Breaking a box down gives
  components only. An NPC's hack round is a plain smart round when it hits you.
- Faction rounds: 88 new rounds. Maelstrom, Scavengers, Arasaka, Tyger Claws, Valentinos,
  6th Street, Militech, the Animals, Barghest, Voodoo Boys, Wraiths, Aldecaldos, the Mox, NCPD, Kang
  Tao and NUSA each have their own, in their own packaging, marked in the name: [Mael], [Scav], [Ara],
  [Tyger], [Val], [6th], [Mil], [Animal], [Barghest], [VDB], [Wraith], [Nomad], [Mox], [NCPD], [Kang]
  or [NUSA]. They come from that faction's NPCs, who carry and fire them and drop what's left on them.
  A few gun shops on Maelstrom, Scav, Arasaka, Mox and Aldecaldo turf stock some too; on an existing
  save, a shop adds them the next time it restocks. They can't be crafted.
  - Redliners (.45, 5.56, 7.62): +25% fire rate, +40% recoil and spread, and a 2% chance per shot
    to jam your weapons for 3 seconds.
  - Chrome-cookers (light and heavy rail): 15% chance of a cyberware malfunction. -10% damage.
  - Meat-grinders (.45, 12mm, 12-gauge, 4-gauge): 30% chance to cause bleeding, three times the
    dismemberment chance.
  - Reloads (9mm, .45, 12mm): half the price of a Common round. Damage varies -30% to +15%, with
    duds and hot rounds.
  - Gutter Lead (9mm, .45, 12mm): 25% chance to cause bleeding, 25% chance to poison. -50% damage.
  - Parts-pullers (.45, 12mm): a kill leaves 2 Rare crafting components on the body.
  - Kata (.45, 5.56, 7.62, light rail): damage varies only 1% either way. 30% less recoil, 30%
    faster aim.
  - Kansatsu (10mm, 20mm, 25mm): targets hit show through walls for 5 seconds. Locks on twice as
    fast.
  - Shinobi (9mm, .45): silent kills, +50% headshot damage. -10% range.
  - Shinobi Seconds (9mm, .45): silent kills. -15% damage, and 5% are duds that hit for a quarter.
  - Tanto (9mm, .45, 12mm): 25% chance to cause bleeding, +10% crit chance.
  - Gold Tips (.45, 12mm): +15% crit chance, +30% crit damage, +20% recoil.
  - Santa Muerte (.45, 12mm): +50% headshot damage, and headshots set the target on fire.
  - Surplus (9mm, .45, 12mm): damage varies only 5% either way. -10% recoil.
  - Fourth of July (9mm, 12mm, 10mm): hits tag targets through walls for 5 seconds, with a 10% chance
    to set them on fire.
  - Mil-Spec (9mm, 7.62, light rail): damage varies only 5% either way. 25% armor penetration, -15%
    recoil.
  - Cease and Desist (7.62, 12-gauge): 30% chance per shot to stagger the target. 50% armor
    penetration, -10% damage.
  - Protein Loads (12mm, light and heavy rail): kills give +6% move speed and 10% faster reloads for
    10 seconds, stacking 3 times.
  - Leg Day (12mm, heavy rail): 20% chance per shot to cripple the target's legs, so it stops where
    it stands. Tougher targets stagger, and V gets knocked down. +80% recoil.
  - Dogtown Tax (9mm, 5.56): kills leave eddies on the body.
  - Chimera Scrap (7.62, light rail): bullets explode on impact.
  - Bad Juju (.45, light rail, 10mm): 15% chance per shot to turn the target on its friends for 20
    seconds. Bosses and MaxTac shrug it off, and it blinds V instead.
  - Pocket Sand (.45, 12-gauge): 20% chance per shot to blind the target for 2 seconds.
  - The Clap (light and heavy rail): 20% chance per shot to poison the target, and it spreads to
    whoever's close.
  - Waste Not (9mm, .45, 12mm): 15% of shots don't use a round.
  - Speedloaders (.45, 12mm): draw the gun and the magazine's full, however you left it.
  - Cut Off (9mm, .45, 12-gauge): non-lethal, with a 15% chance per shot to knock the target out.
    Tougher targets stagger, and V gets knocked down.
  - Last Call (9mm, 12mm): 15% chance per shot to drop the target unconscious 4 seconds later.
    Tougher targets stagger, and V gets knocked down.
  - Standard Issue (9mm, .45): hold the trigger and shots stay tight instead of spreading.
  - Resisting Arrest (9mm, 12-gauge): 20% chance per shot to shock the target.
  - Wide Angle (10mm, 20mm): locks on to targets much further from the crosshair.
  - Second Opinion (10mm, 20mm, 25mm): locks on to 2 more targets at once.
  - Deniable (.45, light rail, 10mm): silent kills, and double damage on targets who haven't seen
    you.
  - Black Budget (12.7, heavy rail): 30% chance per shot to badly poison the target.
- Gun shops in Northside, Kabuki and the Arroyo sometimes carry a stack or two of their turf's
  faction rounds, and the two Scav shops always have Reloads. One gun shop Downtown sometimes has a
  small stack of Shinobi. The Mox's gun shop in Kabuki sometimes has Cut Off and Last Call, and one
  in the Badlands has Waste Not. Containers don't hold faction rounds.

## 0.5.0

- A Legendary tier: 14 new rounds to find, 149 in all. Elite enemies, bosses and MaxTac sometimes
  carry them, and a stash holding Epic rounds now and then has a small stack. No shop sells them
  and they can't be crafted. Two of them:
  - Kebab (light and heavy rail): a charged shot goes through every body and wall in its line
    with no damage lost.
  - Pump N Dump (12-gauge): one slug per shot, greased so the gun cycles at 2.5 times the speed.
    Burns through ammo fast.
  - The rest are for you to find.
- Five new rounds:
  - Ping (Rare; 7.62, 12.7): targets hit show through walls for 5 seconds. -10% damage.
  - Penetrator (Epic) in 12mm, 7.62 and 12.7: ignores 60% of armor and goes through thin cover
    at half damage. NPCs firing it get the same.
- Spread changes now cover the Tactician's minimum spread, which they used to miss. Slugs are x0.2
  spread on every shotgun.

## 0.1.0

First release.

- 13 calibers in place of the game's 4 ammo types: 9mm, .45, 12mm magnum, 5.56, 7.62, 12.7,
  12-gauge, 4-gauge, light and heavy rail slugs, and 10mm, 20mm and 25mm smart rounds.
- About 130 rounds across Common, Uncommon, Rare and Epic. Pick a gun's round in the new Ammo
  section of its mod screen; Common rounds work like the game's ammo.
- NPCs carry and fire real rounds, better ones the tougher they are, and leave what they carry
  as loot. Their rounds follow the same damage rules as yours.
- Vendors and loot hand out every caliber and tier; gun shops sell up to Rare.
- Crafting: every caliber's Common round can be crafted from the start; better rounds need a
  recipe ("load sheet") from loot or a gun shop. Tech rounds are the cheapest to make, Smart
  rounds the dearest. Rounds break down by the box into components of their own grade.

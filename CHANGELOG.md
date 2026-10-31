# Changelog

Each release's section is its GitHub release notes and its Nexus Mods changelog
(`tools/linux/release.sh` reads the section under the version's heading).

## Unreleased

- Faction rounds: 51 new rounds, 200 in all. Maelstrom, Scavengers, Arasaka, Tyger Claws, Valentinos,
  6th Street, Militech and the Animals each have their own, in their own packaging, marked in the
  name: [Mael], [Scav], [Ara], [Tyger], [Val], [6th], [Mil] or [Animal]. They come from that faction's
  NPCs, who carry and fire them and drop what's left on them. A few gun shops on Maelstrom, Scav and
  Arasaka turf stock some too; on an existing save, a shop adds them the next time it restocks. They
  can't be crafted.
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
- Gun shops in Northside, Kabuki and the Arroyo sometimes carry a stack or two of their turf's
  faction rounds, and the two Scav shops always have Reloads. One gun shop Downtown sometimes has a
  small stack of Shinobi, the only Epic round any shop sells. Containers don't hold faction rounds.

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

# Changelog

Each release's section is its GitHub release notes and its Nexus Mods changelog
(`tools/linux/release.sh` reads the section under the version's heading).

## Unreleased

- A Legendary tier: 14 new rounds, 149 in all. Elite enemies, bosses and MaxTac sometimes carry
  them, and a stash holding Epic rounds now and then has a small stack. No shop sells them and
  they can't be crafted.
  - Gatecrasher (7.62, 12.7): ignores all armor, no damage falloff, through cover at full damage.
  - Cook-off (9mm, .45, 12mm, 5.56, 7.62): a kill sets off a blast at the body that hurts everyone
    close by. An enemy's Cook-off hit on you sets off your grenade if it's charged.
  - Kebab (light and heavy rail): a charged shot goes through every body and wall in its line
    with no damage lost.
  - Lockout (10mm, 20mm, 25mm): every hit jams the target's weapon for 4 seconds.
  - Mule Kick (4-gauge): every hit knocks the target down and tough ones stagger; each shot shoves
    V hard away from the aim, so a shot at the floor sends V up.
  - Heartseeker (12-gauge): one guided slug that locks onto heads, no Smart Link needed.
  - 4-gauge's Legendary round is still to come.
- Five new rounds, 135 in all:
  - Ping (Rare; 7.62, 12.7): targets hit show through walls for 5 seconds. -10% damage.
  - Penetrator (Epic) in 12mm, 7.62 and 12.7: ignores 60% of armor and goes through thin cover
    at half damage. NPCs firing it get the same.

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

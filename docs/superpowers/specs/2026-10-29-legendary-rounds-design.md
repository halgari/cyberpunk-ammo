# Legendary rounds, first set: design

Date: 2026-10-29. Status: designed in conversation with the user; the probes below run before
the plan is written.

A fifth tier above Epic. Each Legendary round does one thing no lower tier does. This first set
has six kinds across 14 rounds, which takes the mod from 135 rounds (after Ping and the new
Penetrators) to 149.

## Binding rules

- NPCs and V follow the same rules. Where a Legendary effect can't mean the same thing on V, the
  NPC version below says what it does instead.
- Common rounds stay vanilla. No automatic ammo switching.
- Item text: slang names, plain gun-counter descriptions, no invented lore; the effect lines
  after a blank line. Names chosen with the user: Heartseeker, Kebab, Lockout, Cook-off; the
  Total Penetrator and 4-gauge names are still open (working: Balls Deep, Bouncing Betty).
- **No crafting** (user ruling): no recipes, and no Legendary rounds at the crafting screen.
  Breaking rounds down works as for the other tiers. A Legendary stack breaks down into Legendary
  components by the existing disassembly rule.

## The tier

- Quality: Legendary.
- Price: x16 of the caliber's Common round (Epic is x8).
- Never sold. No vendor, gun shop included, ever stocks a Legendary round.
- **NPCs:** only NPCs of rank Elite, Boss or MaxTac roll for a Legendary round. They fire it,
  and it drops as loot.
  - The chance per gun is 3% for Elite and 10% for Boss and MaxTac.
  - A failed roll falls through to the existing Epic, Rare and Uncommon rolls.
  - The other ranks never roll for Legendary.
- **Containers:** loot containers that already hold Epic rounds have a 0.2% chance per ammo
  stack of holding the caliber's Legendary round instead.
- A Legendary stack is small: a quarter of an Epic stack, rounded up.
- The tier shares (`AmmoOverhaul.shares`) gain a fifth entry, so the existing four stay as they
  are and still sum to 1 without it. The plan decides whether the entry is 0 with the NPC and
  container rolls above, or a share.

## The rounds

**Total Penetrator** (12.7, 7.62)
- Ignores all armor (`CanWeaponIgnoreArmor` full).
- No damage falloff (`DamageFalloffDisabled`).
- Goes through cover at full damage: `TechPierceEnabled` +1, `TechPierceChargeLevel` x0, and
  `TechPierceDamageFactor` set so no damage is lost through cover.
- All stats, which NPC guns get through `NpcAmmo` as every round's stats. No probe needed.

**Cook-off** (9mm, .45, 12mm, 5.56, 7.62)
- When a Cook-off round kills an NPC, a small blast goes off at the body. It's the NPC's gear
  cooking off, and it damages everyone near it, V included.
- **Hit on V:** every hit sets off the grenade in V's grenade slot, on V, if that grenade has a
  charge. The charge is used up and starts recharging, so the next hits do nothing until it's
  back. With an empty slot, or no charge, nothing happens. The grenade's own effect applies: a
  Frag blasts, an EMP hits V's cyberware, and so on.

**Kebab** (5mm rail, heavy rail; designed as Skewer)
- A charged shot goes through every body and wall in its line with no damage loss.

**Lockout** (10mm, 20mm, 25mm smart)
- Every hit jams the target's gun for a few seconds. A hit on V jams V's gun.

**Heartseeker** (12ga; designed as the smart slug)
- One heavy slug that steers itself onto the target nearest the crosshair.
- The guidance is in the shell: V needs no Smart Link. An NPC's Heartseeker steers toward V.

**Launcher round** (4ga; working name Bouncing Betty)
- The shot throws a real grenade out of the muzzle: it flies on an arc, bounces and rolls, and
  goes off on a short fuse, like a thrown frag. The user's preferred version.
- Fallbacks, in order, if the probe can't throw a grenade from the gun: an explosive projectile
  that bursts where it hits (a body, a wall or the floor); a blast at the point of impact.
- It can hurt V at close range (default; the user can turn this off).
- An NPC's round does the same to V.

## Probes (in the game, before the plan)

1. **Can a Power gun fire a projectile instead of an instant-hit shot?** A smart projectile for
   Heartseeker. For the Launcher round, first: can the mod spawn a real grenade (the frag's
   projectile) at the muzzle and throw it forward with the gun's aim, so it arcs, bounces and
   goes off on its fuse? Then a grenade-like projectile. The candidates are the
   weapon's projectile and smart stats, as the smart guns and the grenade launchers use them.
   - Fallback for Heartseeker: a single slug with strong bullet magnetism, much stronger than
     Feedback's +2 degrees.
   - Fallback for the Launcher round: probe 2's blast, set off at the point of impact.
2. **Can the mod set off a grenade-style blast at a point from script?** Cook-off's blast at a
   body and V's grenade cooking off on V depend on it. So does the Launcher round's fallback.
   For V's grenade, the probe also has to find the grenade in V's grenade slot, its charge, and
   how to use one up.
3. **Does Tech pierce go through bodies as well as walls,** with `TechPierceDamageFactor` at no
   loss? Fallback for Kebab: the hit code carries the shot on to the next target in line.
4. **Does the weapon jam effect work on V's gun?** That's `BaseStatusEffect.WeaponMalfunction`
   (Hack Carrier uses it on NPCs), or a player version of it.

A probe that fails moves its round to its fallback, and the user hears about it before that
round is built.

## Everything else follows the existing pattern

- The round generator (`tools/rounds/rounds.py`) gains the Legendary tier.
- Selectors, prices, icons and item text are generated as for the other tiers.
- NPC rank rolls and container rolls extend the existing tier code.
- Docs, the banner and the Nexus page update, and Legendary rounds move out of "Coming next".

## Testing

- **Records:** 14 Legendary rounds, Legendary quality, x16 price, no recipe, never in vendor
  stock.
- **NPC rolls:** only Elite, Boss and MaxTac roll for Legendary, at 3% and 10%.
- **Live, one check per mechanism:**
  - the Cook-off blast at a killed NPC, and V's grenade cooking off and recharging;
  - Kebab through two NPCs in a line;
  - Lockout jams an NPC's gun, and V's;
  - Heartseeker homes;
  - the Launcher round arcs, bounces and goes off;
  - Total Penetrator through cover at full damage.
- **The user's playtest of all six.**

## Out of scope

Faction rounds. Legendary rounds for the other mechanics. Crafting of Legendary rounds.

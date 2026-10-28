# Damage roll for every shooter, and the second Uncommon rounds

First of three specs for the next lineup (`docs/CATALOG.md`, "Next lineup"): this one, then Rare
rounds, then Epic rounds. Each has its own plan.

## Goal

1. Every ranged gun hit rolls its damage by one rule, whoever fires it, with the roll set by the
   round the gun is loaded with. Later rounds (Match grade, faction loads) only set values.
2. Every caliber gets a second Uncommon round, with names, item text and icons.

## Decisions (agreed 2026-10-28)

- Vanilla rolls only V's hits on NPCs (`DamageSystem.CalculateDamageVariants`,
  `RandRangeF(0.90, 1.10)`; probed: 30 hits, 0.908 to 1.101). NPC hits on V and on other NPCs
  don't roll. Now every ranged gun hit rolls.
- The default roll is a downside: 0.90 to 1.01. Average damage drops to about x0.955 for everyone,
  Common rounds and NPCs included. Accepted by the user; difficulty covers it.
- Values are layered, each overriding the last: global default, family, faction, round. Most
  rounds set nothing. Each layer can set a range per damage type.
- Uncommon rounds trade one perk for one quirk, with no armor penetration bonus (armor pen starts
  at Rare).
- 4-gauge's wide load is Birdshot, as on 12-gauge (one load, one name), pushed further.

## Damage roll

**Where:** a `@wrapMethod` on `DamageSystem.CalculateDamageVariants`. It replaces vanilla's roll
(the wrapped method isn't called) for hits whose attack has a ranged weapon
(`attackData.GetWeapon()` is ranged and the attack isn't melee). Other hits call the wrapped
method, so melee keeps vanilla's player-only roll and grenades and other explosions stay unrolled.
Projection hits (`projectionPipeline`) stay skipped.

**Which round:** for V, the round the gun's feed selector loads. For an NPC, the round its gun
was stocked with (`NpcAmmo`, including a rolled Uncommon). Guns the mod doesn't manage (record ammo
`Ammo.Standard`: turrets, drones, mounted guns) use the global default.

**Values,** all optional floats:

| Value | Meaning | Global default |
|---|---|---|
| `rollMin`, `rollMax` | uniform range for the hit | 0.90, 1.01 |
| `rollDudChance`, `rollDudMult` | chance of a much weaker hit, and its multiplier | 0, 1 |
| `rollHotChance`, `rollHotMult` | chance of a much stronger hit, and its multiplier | 0, 1 |

One draw per hit: first a dud (chance) then a hot hit (chance); otherwise the uniform range. A
per-type value (`rollMin.Thermal` and so on, for Physical, Thermal, Electric, Chemical) rolls that
damage type on its own with `MultAttackValue(value, damageType)`; types without one roll together.

**Layers,** first found wins:

1. The round: flats on its ammo record (`Ammo.AO_X.rollMin`).
2. Its faction: `AmmoOverhaul.roll.<faction>.<value>`, the faction read from the round's
   `aoFaction` flat. No round has one yet; the layer is built and tested with a test round.
3. Its family: `AmmoOverhaul.roll.<Power|Tech|Smart>.<value>`. All three start unset, so they
   take the global default.
4. Global: `AmmoOverhaul.roll.<value>`, in `core.yaml`.

The resolved values are cached per ammo record. `CaliberForWeapon` is cached per weapon record in
the same change (deferred minor from the v1 review), since the hook runs on every hit.

**Tooltip:** the item screen's damage range (`EffectiveDamagePerHitMin/Max`) shows the loaded
round's range: global 0.90 to 1.01 of `EffectiveDamagePerHit` on every gun, and rounds that set
their own range adjust it through their selector's stat modifiers. Probe first: how vanilla
derives the 0.9 and 1.1.

## Second Uncommon rounds

| Family | Calibers | Round | Effect |
|---|---|---|---|
| Power | 9mm, .45, 12mm, 5.56, 7.62, 12.7 | +P | damage x1.1, effective range x1.15, recoil x1.25, more stamina per shot |
| 12-gauge | 12ga | Birdshot | pellets x2 (the shot's damage is split across them), spread x1.6, armor x1.5 as effective, flinch up |
| 4-gauge | 4ga | 4ga Birdshot | pellets x2.5, spread x2, armor x1.5 as effective, flinch up |
| Tech | 5mm rail, heavy rail | Bricks | damage x1.15, charge time x1.3 |
| Smart | 10mm, 20mm, 25mm | Short-Fuse | damage x1.2, shorter reach |

- Pellet counts use the Slugs method (a `CombinedStatModifier` on `ProjectilesPerShot` against
  `ProjectilesPerShotBase`), so they scale with each gun's own count.
- "Armor x1.5 as effective" is the Mushrooms method (armor penetration -0.5).
- Flinch is `HitReactionFactor`; the value is set in the plan from vanilla's range.
- **+P stamina:** only if a stat for stamina per shot exists on 2.50 (probe). Without one, +P is
  damage and range for recoil.
- **Short-Fuse reach:** probe how a smart projectile's reach is limited (lifetime, speed, or a
  range stat). If none can be shortened, the quirk is a shorter lock range instead.

**Availability:** the family's Uncommon share (`AmmoOverhaul.shares.<family>`) is split evenly
between its two Uncommon rounds, for vendors, loot and the NPC Uncommon roll.

## Item text

Names (caliber prefix, as with Mushrooms): `9mm +P`, `.45 +P`, `12mm +P`, `5.56 +P`, `7.62 +P`,
`12.7 +P`; `Birdshot`, `4ga Birdshot`; `5mm Bricks`, `Heavy Bricks`; `10mm Short-Fuse`,
`20mm Short-Fuse`, `25mm Short-Fuse`. One description key per load, shared across calibers
(4ga Birdshot has its own, since its numbers differ).

Drafts, for the user's sign-off before they ship:

- **+P:** Loaded hot, over standard pressure. More punch and more reach, but it kicks harder and
  wears you out faster.

  +10% damage. +15% range. +25% recoil. Costs more stamina per shot.
- **Birdshot:** A shell full of small shot. It spreads wide and makes people flinch, but armor
  shrugs most of it off.

  Twice the pellets, each one weaker. Wider spread. Armor is 50% more effective against it.
  Targets flinch more.
- **4ga Birdshot:** Birdshot in a 4-gauge shell. More pellets and a wider spread than anything a
  12-gauge throws.

  2.5x the pellets, each one weaker. Much wider spread. Armor is 50% more effective against it.
  Targets flinch more.
- **Bricks:** Dense slugs, heavier than standard. They hit harder, but the rails take longer to
  get them moving.

  +15% damage. Charges 30% slower.
- **Short-Fuse:** Seekers with a bigger warhead and less fuel. They hit harder but burn out sooner,
  so keep your targets close.

  +20% damage. Shorter range.

Effect lines are fixed by the plan's final numbers and the probes (stamina, reach).

## Icons

13 new rounds, rendered with the Blender pipeline (`tools/render`), in the same look as v1. The
atlas grows to fit 39 cells at 160 px (the plan picks the layout).

## Old saves

Nothing to convert: the new rounds only appear in vendors and loot. The roll change applies at
once to every save.

## Checks before building (probes)

1. How vanilla derives `EffectiveDamagePerHitMin/Max` (the tooltip range).
2. A stamina-per-shot stat on 2.50.
3. How a smart projectile's reach can be shortened.
4. That `CalculateDamageVariants` sees NPC hits on V and on NPCs (the CET hook already logged NPC
   hits on V: `N>P`).

## Testing

In game, with the CET harness:

- Roll: the probe rig (frozen invulnerable test NPC, V moved 5 m in front, `AIWeapon.Fire`), 30+
  hits per case: V with a Common round lands in 0.90 to 1.01; an NPC hitting V also rolls; a test
  round with its own range, dud and hot values, and a per-type range, gets them; faction and family
  layers override the global one; melee and grenades are unchanged.
- Uncommons: records, names and text for all 13; stat ratios against the Common round on one gun
  per family (as `uncommon.lua` and `slugs.lua` do); pellet counts on every shotgun; shares in
  vendors, loot and the NPC roll.
- Icons: every new round and selector has its own atlas part.
- The v1 suite stays green.

Hands-on for the user: Birdshot and 4ga Birdshot against a group, Short-Fuse at range, a fight on
Very Hard with the new roll.

## Order of work

1. Probes.
2. Damage roll hook, layers, cache and tooltip.
3. Second Uncommon rounds: records, effects, shares.
4. Item text, for sign-off.
5. Icons.

# Rare and Epic rounds, slice 1: design

Date: 2026-10-29. Status: designed in conversation; written for the user's review.

The agreed lineup (`docs/CATALOG.md`, "Next lineup" and "Grid") adds 4 Rare and 4 Epic rounds
per caliber. It is split by mechanic. **Slice 1** (this spec): the tier groundwork plus every
round built from stat changes and on-hit effects, about 85 rounds. **Slice 2** (later, its own
spec): rounds that need new mechanics, each behind a probe.

## Binding rules

- **NPCs and V follow the same rules.** A round does the same thing whoever fires it. Effects
  run in the mod's own hit code for both. A round that changes handling stats has those stats
  measured on an NPC gun. If a stat does nothing on NPC guns and the hit code can't make up for
  it, the round moves to slice 2 instead of shipping V-only. Exception: range and spread are
  already a known gap on NPC guns (0 there), so Flechette, Ballistic tip and Match's range and
  spread parts are V-only, as with the Uncommons.
- Common rounds stay vanilla. No automatic ammo switching. Rounds are picked on the gun's mod
  screen (hidden synced selectors, already built).
- Rare carries one small drawback. Epic is a straight upgrade in its dimension; price and
  scarcity are its cost.
- Armor pen: Rare about 20-30% of armor ignored, Epic about 50-70%. Full armor ignore and no
  falloff stay for Legendary or faction rounds. No cover piercing in slice 1.
- No area damage in slice 1. No shock or EMP on Power rounds.
- **Flechettes ignore no armor** (user ruling: unrealistic). Their perk is range and grouping.
- Item text: slang names, plain gun-counter descriptions, no invented lore; the effect lines
  after a blank line, as the existing rounds do.

## Roster

Working names from the grid; final names follow the item-text voice. Held back for slice 2
in brackets.

- **9mm, .45:** Rare Steel-core AP, Incendiary (9mm: weaker burn), Subsonic, Bouncers, Rubber.
  Epic Penetrator (armor only), Match, Toxin core, Shredders.
- **12mm:** Rare Steel-core AP, Incendiary, Rubber, Hardcast. Epic Match, Toxin core, Shredders.
  (Penetrator.)
- **5.56:** Rare Steel-core AP, Incendiary, Subsonic, Bouncers. Epic Penetrator (armor only),
  Match, Toxin core, Shredders.
- **7.62:** Rare Steel-core AP, Incendiary, Ballistic tip. Epic Match, Toxin core, Shredders.
  (Tracer, Penetrator.)
- **12.7:** Rare Steel-core AP, Incendiary, Ballistic tip. Epic HEI (no area), Match, Toxin
  core. (Tracer, Penetrator.)
- **12ga:** Rare Flechette, Beanbag, Dragon's breath (light). Epic Dragon's breath, Frag-12 (no
  area), Flechette (long). (Gas, Tungsten slug.)
- **4ga:** Rare Flare, Riot, Flechette. Epic Dragon's breath, Thermite slug. (Gas canister,
  Kinetic penetrator, Micro-grenade.)
- **5mm rail, heavy rail:** Rare Ferro, Split slug, Feedback. Epic DU penetrator, Toxic
  scatter, Superconductor, EMP capacitor. (Capacitor.)
- **10mm smart:** Rare EMP, Incendiary, Chem, Flash payloads. Epic Hunter, Hack carrier,
  Shaped charge. (Splitter.)
- **20mm, 25mm smart:** Rare EMP, Incendiary, Chem, Flash payloads. Epic Hunter, Hack carrier,
  Shaped charge. (HE.)

## Starting values

Per round kind; every caliber's round of that kind uses these unless a caliber note says
otherwise. Playtesting tunes them. "Damage" is the round's damage factor (applied to NPC hits by
the parity hook, as for the Uncommons).

**Power, Rare**
- Steel-core AP: ignores 25% of armor; damage x0.90.
- Incendiary: 15% burn chance (9mm 8%); 25% of damage as Thermal; damage x0.95.
- Subsonic: weapon noise much lower and silent kills, as a suppressor gives; damage x0.90,
  range x0.90.
- Bouncers: 30% ricochet chance, 1 bounce; damage x0.85.
- Rubber: non-lethal (targets go unconscious instead of dying); strong flinch; damage x0.60.
- Hardcast (12mm): 25% stagger chance; ignores 10% of armor; recoil x1.20.
- Ballistic tip (7.62, 12.7): effective range x1.40; damage x1.05; armor ignored 10 points
  less than the caliber's Common round.

**Power, Epic**
- Penetrator (9mm, .45, 5.56): ignores 60% of armor.
- Match: damage roll 0.98-1.06, no dud or hot; spread and sway x0.70.
- Toxin core: 25% poison chance; 30% of damage as Chemical.
- Shredders: 30% bleed chance; dismemberment x2.
- HEI (12.7): damage x1.5 against drones, mechs and vehicles; 20% burn chance; no area.

**Shotguns**
- Flechette (Rare, 12ga and 4ga): tighter spread; effective range x2; damage x0.85; no armor
  pen.
- Flechette, long (12ga Epic): tighter spread; effective range x3.5; no armor pen.
- Beanbag (12ga Rare), Riot (4ga Rare): one projectile with the shot's damage; non-lethal;
  knockdown; damage x0.50.
- Dragon's breath, light (12ga Rare): 30% burn chance; 50% of damage as Thermal; range x0.80.
- Dragon's breath (12ga and 4ga Epic): 60% chance of the stronger burn (MediumBurning); all
  damage as Thermal.
- Frag-12 (12ga Epic): one projectile; ignores 50% of armor; damage x1.5 against machines.
- Flare (4ga Rare): one projectile; short blind; 30% chance of a light burn.
- Thermite slug (4ga Epic): one projectile; heavy burn every hit; damage x2 against machines.

**Tech**
- Ferro (Rare): 40% ricochet chance, up to 2 bounces; damage x0.90.
- Split slug (Rare): 3 projectiles sharing the shot's damage; wider spread; no pierce.
- Feedback (Rare): bullet magnetism +2 degrees; damage x0.90.
- DU penetrator (Epic): pierces at a lower charge; pierce damage x1.5; ignores 50% of armor.
- Toxic scatter (Epic): 5 projectiles; 25% poison chance per hit.
- Superconductor (Epic): full auto at full charge.
- EMP capacitor (Epic): 30% EMP chance; 30% of damage as Electric.

**Smart**
- EMP, Incendiary, Chem payloads (Rare): 25% chance of EMP, burn or poison; 30% of damage as
  Electric, Thermal or Chemical; damage x0.90.
- Flash payload (Rare): 30% blind chance; damage x0.80.
- Hunter (Epic): 2 more locked targets; lock time x0.5; hit chance +20%; rocket speed x1.3.
- Hack carrier (Epic): 15% Cyberware Malfunction chance and 15% weapon jam chance.
- Shaped charge (Epic): ignores 50% of armor; damage x1.5 against machines.

## Tiers: price, frequency, sources

- **Price**, as the base game prices weapons by quality (measured: each quality step about
  doubles a Lexington's buy price): Uncommon x2, Rare x4, Epic x8 of the caliber's Common round.
  9mm: 2, 4, 8, 16 per round. This changes the built Uncommons too (today x1).
- **Weight:** the Common round's.
- **Tier shares** (of a family's ammo, `AmmoOverhaul.shares.<family>`, Common to Epic):
  Power 0.80 / 0.14 / 0.05 / 0.01; Tech 0.70 / 0.22 / 0.07 / 0.01; Smart 0.86 / 0.10 / 0.035 /
  0.005. Within a tier, a caliber's rounds split the share evenly (as now).
- **Gun shops** sell up to Rare. Other vendors Common only. No vendor sells Epic.
- **Loot containers** roll any tier by share (an Epic about once per 100 converted stacks); the
  owned-caliber bias stays.
- **NPCs**, per rank: a cap and a factor on each tier's share. Trash, Weak: Uncommon x0.5, no
  Rare or Epic. Normal: Uncommon x1. Rare, Officer: Uncommon x1.5, Rare x1.5. Elite: x2 each,
  Epic allowed. Boss: Uncommon x2, Rare x3, Epic x4. A higher tier rolls first; a miss falls to
  the next lower tier. Bodies drop the round they fired (as now).

## How rounds work

- **Stat changes** on the selector part, as the Uncommons: armor pen (`CanWeaponIgnoreArmor`,
  measured working on NPC guns), range, spread, sway, recoil, ricochet, bullet magnetism,
  projectiles per shot, Tech charge and pierce, smart lock and speed, weapon noise and silent
  kill, dismemberment, hit reaction. NPCs get them through `NpcAmmo.RollUncommon`'s copy (which
  becomes the roll for every tier). Each stat type new to this slice is measured on an NPC gun
  in hand (the parity audit's method) and added to the audit in `docs/DESIGN.md`.
- **Damage factor** (`DamagePerHit` Multiplier on the selector): applied to NPC hits by the
  parity hook, as now.
- **Per-round hit data**, read by the mod's hit hooks for every ranged gun hit, V or NPC (the
  round is `AOData.LoadedAmmo`):
  - on-hit effects: a list of status effects, each with a chance (generalizes today's single
    `AmmoOverhaul.<name>.effect`, used by the 4ga Slug's knockdown);
  - damage-type share: a fraction of the hit's Physical damage moved to Thermal, Chemical or
    Electric;
  - machine bonus: a damage factor when the target is a drone, mech or vehicle;
  - hit flags: `Nonlethal` (Rubber, Beanbag, Riot);
  - damage roll range (Match): the existing per-round roll flats.
  Effects go through `ProcessStatusEffects` (vanilla's immunity, block and friendly checks
  still apply); share, machine bonus and roll go through `CalculateDamageVariants`.
- **Records:** one ammo item and one selector per round, in the caliber's YAML file, following
  the Uncommon pattern (selector lists, tiers, icons, text). Each new round gets its own icon
  from the existing icon pipeline.

## Testing (in game, CET harness)

- Records, generic over every Rare and Epic: ammo and selector exist, tier lists line up,
  quality, price x4 / x8 (Uncommon x2), weight, text keys, icon cells, selector hidden.
- Distribution: shares sum to 1 per family; vendor caps (gun shop up to Rare, no Epic); loot
  can produce each tier; NPC rank caps and factors (forced rolls per rank).
- Effects, live on the hit rig both ways (V on the NPC, the NPC on V), one round per effect
  kind: a status effect lands at a forced chance of 1; the damage-type share shows in the hit's
  per-type values; the machine bonus on a drone versus a human; non-lethal leaves the target
  unconscious, not dead; Match hits stay in 0.98-1.06.
- Handling stats: each new stat type read off an NPC gun in hand against its selector's value
  (generalized `parity-stats.lua`); a stat that fails moves its round to slice 2.
- The existing suite stays green; Common rounds unchanged (`vanilla.lua`).

## Out of scope (slice 2)

Tracer, cover-piercing Penetrators (12mm, 7.62, 12.7), Tungsten slug, Kinetic penetrator, Gas
and Gas canister, Micro-grenade, smart HE, Splitter, Capacitor (charge-dependent shock).
Crafting recipes for any tier.

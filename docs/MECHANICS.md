# Ammo mechanics: what an ammo type can do, and how

How the 2.50 engine handles the things an ammo type would change, read from the game scripts in
`reference/scripts` and checked in game where noted. The list of every modifiable stat is in
`docs/CATALOG.md` ("What an ammo type can change").

## Two ways an ammo type changes a gun

Each ammo type has a selector part, and a part changes the gun the way vanilla mods do:

1. **Stat modifiers** on the part (`statModifiers`): fire rate, recoil, spread, damage, armor
   penetration, ricochet, charge, smart guidance, status chances. **Checked in game** on our
   selector (pellets and spread, see "More projectiles" below).
2. **Gameplay packages** (`OnAttach`) whose effectors act on the gun. The important one is
   `OverrideRangedAttackPackageEffector`, which replaces the gun's **attack package**: the record
   that says what a shot is. **Checked in game:** a test selector carrying the Chimera power mod's
   effector (`Items.AO_Feed_9mm_TestExplosive`) switches the Lexington to
   `Attacks.ChimeraPowerModExplosiveBulletPackage` when fitted, back when removed, and keeps it
   through a holster and redraw. The effector only acts on a gun that has its
   `weaponAttachmentSource` part fitted, so each selector names itself there.

An attack package holds a `defaultFire` and a `chargeFire` attack (each with a player and an NPC
version). The attack is a hitscan ray (Power and Tech guns) or a projectile (Smart guns), and it can
carry its own status effects, hit flags, stamina cost and an `explosionAttack`. So the package
override is the general hook for "what this ammo does on hit", with no script.

Untested: NPC shots with an overridden package (the NPC attack is separate, and the Metel's NPC
attack has no explosion); a second override on the same gun (iconics with their own package,
the Chimera mod); whether the engine re-applies the override after loading a save.

## Damage on hit

Order in `DamageSystem` (source modifiers, then target modifiers): charge, pierce, ricochet, crit,
multipliers, cyberware, stealth; then the target's resistances and armor.

### Armor

- Damage × `1 / (1 + armor × effectiveness)`. Effectiveness is 0.01 per point on NPCs (100 armor
  halves damage) and 0.003 on the player (34 armor is about −9%), times the player's
  armor-effectiveness multiplier.
- It reduces every damage type alike, so switching a bullet to Thermal or Electric doesn't get
  past armor. A hit never does less than 1.
- **Penetration** scales armor by `(1 − pen)`: the weapon's `CanWeaponIgnoreArmor` (a fraction;
  1.0 ignores armor), +0.25 for the Breach hit flag, +0.25 for a Tech shot charged past its pierce
  level. Negative pen isn't blocked by the formula (a hollow-point quirk; untested).
- **Skips armor:** damage over time (burn, bleed, poison, shock ticks) and attacks with no weapon
  (grenades). Whether a bullet's explosion counts as having a weapon is untested.
- **Armored plates:** on the player's shots, a hit on an armored hit shape uses the target's
  `HitShapeArmor` if higher.
- **Armor melt:** an effect tagged `OverheatArmorMelt` (the Overheat quickhack) lowers armor by up
  to a set percent while it runs.
- A hit reduced by armor with no pen and no crit shows as a Glance.
- **Negative pen on a part:** a selector with `CanWeaponIgnoreArmor` −0.5 (9mm Mushrooms) brings
  the Lexington's stat to −0.5, checked in game. `ProcessArmor` multiplies armor by `1 − pen`
  with no lower limit, so the target's armor should count 1.5×; the damage itself is not yet
  measured. Tech guns start with pen of their own (Omaha 0.5).

### Resistances

Separate from armor. Elemental resistances (thermal, electric, chemical) apply to melee,
explosions, quickhacks and damage over time, **not to direct gun hits**. Also by attack type:
explosion, melee, quickhack, DoT, boss and mech resistance. So a bullet's elemental share is
never resisted (only armored), while its burn or poison ticks skip armor but meet resistance.

### Explosive rounds

A bullet attack with an `explosionAttack`: at impact the engine sets off a second, sphere attack
that hits everything in range, on top of the full direct hit.

- The Metel's own package (`Attacks.PhysicalExplosiveBulletPackage`) explodes in a 2 m radius; the
  Chimera mod's in 3.2 m for 25% of the gun's damage per hit.
- The blast's attack type decides its resistance: `Ranged` (Chimera, Metel) skips explosion
  resistance, `Explosion` (`Attacks.BulletLightExplosion`) meets it.
- The blast can carry status effects and hit flags (incendiary, EMP, chemical, non-lethal
  blasts).
- Smart projectiles carry them too: Ba Xing Chong's `Attacks.ZhuoBulletHighExplosive`.
- It hits everything in range, including the shooter (Ba Xing Chong's description warns of it).

Other ways vanilla adds blasts: `TriggerAttackEffector` sets off a separate attack on an event
(Testera "Nicolas", Sidewinder "Divided" chemical blast, Satara "Brick" EMP).

### Status effects and hit flags

- Native chance stats, applied by the engine: `BurningApplicationRate`,
  `BleedingApplicationRate`, `PoisonedApplicationRate`, `ElectrocutedApplicationRate`,
  `StunApplicationRate`. These could replace the scripted on-hit hook the PoC uses for incendiary.
- `AddStatusEffectToAttack` effectors or the attack's own `statusEffects` add any effect (blind,
  EMP, cripple, knockdown, cyberware malfunction, …).
- **Burn strength is set on the effect, not the hit.** Vanilla Burning ticks every 0.5 s for 8 s,
  each tick 4% of a curve on the target's level (`Attacks.ThermalDamageOverTime`), one stack. A
  custom effect can set a flat tick and its own duration: `BaseStatusEffect.AO_TestLightBurn`
  ticks 1 Thermal per 0.5 s for 2 s (measured on an enemy: about 2 health per second while
  burning). Extra stacks don't add damage: with 8 allowed, they ran one after another (16 s of the
  same burn), because `removeAllStacksWhenDurationEnds` is false. So per-pellet burns don't add up;
  pellets just keep one burn going.
- Hit flags: `Nonlethal` (target goes Unconscious instead of dying), `ForceKnockdown`,
  `ForceDismember`, `CriticalHit`, `BreachHit` (+0.25 pen).

## Shooting

- **Fire rate:** `CycleTime` is the time between shots (lower is faster), scaled by
  `CycleTimeBonus`. Burst guns: `CycleTime_Burst`, `NumShotsInBurst`. Tech guns also wait on
  `ChargeTime` for charged shots.
- **Recoil:** the view kicking up each shot. `RecoilKickMin` / `Max` (`MaxADS` while aiming),
  direction `RecoilAngle` / `RecoilDir`, wander `RecoilDrift*`.
- **Recovery:** `RecoilRecoveryTime`, how fast the view settles after the kick. Fast recovery lets
  a fast gun stay on target; slow recovery stacks kicks.
- **Spread:** where bullets go within the crosshair (hip and ADS, base, max, growth per shot,
  movement penalty, shotgun pellet spread). Recoil moves the crosshair; spread scatters around it.
- **Sway:** the aim wobbling while aiming, before firing.
- **Bullet magnetism:** when a target is within a small angle of the crosshair at the shot, the
  bullet is bent onto it. `BulletMagnetismDefaultAngle` (0.3° on the Lexington) and
  `BulletMagnetismHighVelocityAngle` for fast-moving targets (1°). A few iconics use 1.5° to 2°.
  1° is about 35 cm at 20 m. Not the controller aim-assist setting. Fits match-grade Power rounds
  and a Tech "rail feedback" slug that corrects itself against the rails.
- **More projectiles:** `ProjectilesPerShotBonus` adds pellets to any gun (Doom Doom gives the
  single-shot Nova +2, Suzie +1; the Headsman goes the other way, one slug instead of pellets).
  **Checked in game** on a selector (`Items.AO_Feed_9mm_TestDragon`): +7 gave the Lexington 8
  pellets, and the engine split the shot's damage across them by itself (10.9 became 1.37 per
  pellet), so the total per shot stays the same unless the ammo changes damage too. Extra
  `Spread*` on the same part widened the cone (0.8 to 2.3 hip, 0.33 to 1.83 aiming). Untested
  with Tech charge.
- **Selector stats reach the gun:** the same test shows a selector part's `statModifiers` apply to
  the weapon like any vanilla part's.
- **Stamina:** every shot costs stamina, set on the **attack record** (so an ammo type's package
  can set its own). Full auto gets dearer through the magazine (`FullAutoStaminaCostPenalty`) and a
  fully charged Tech shot costs 1.5×. At zero stamina the player is Exhausted: aiming in takes 20%
  longer, reloads take the `ReloadTimeExhaustionPenalty`, plus one effect not yet read.

## Smart guidance

- A smart bullet homes only if the gun's `SmartGunHitProbability` says so
  (`samples/sampleSmartBullet.script` reads it, clamped 0 to 1). The Yukimura has 0.7; a
  selector with ×0 (10mm Dumbfires) brings it to 0, checked in game (the stat; whether the
  rounds then fly straight not yet checked).

## Tech charge

- Tech guns have a Charge trigger mode: hold to charge, release to fire. Kenshin, Omaha, Burya,
  Senkoh, Achilles and Grit charge while aiming (hip fire is normal); Nekomata and Satara charge
  either way. Power and Smart guns don't charge, and NPC shots get no charge bonus.
- Charge time 1 s (Kenshin), 1.5 s (Omaha, Senkoh, Grit), 2.5 s (Nekomata).
- The cap is 50% (`BaseMaxChargeThreshold`) until Tech perks allow full charge (75%) and then
  overcharge (100%); the higher caps scale the bonus by 1.33 and 1.66.
- **Damage:** × `1 + ChargeMultiplier × charge × cap bonus` (`ChargeFullMultiplier` at full). The
  Kenshin's 0.5 gives 1.5× at base, about 1.8× with overcharge.
- **Pierce:** from `TechPierceChargeLevel` (90% on most, 20% on the Grit) the shot goes through
  cover keeping `1 + TechPierceDamageFactor` of its damage (80% Kenshin, 50% Nekomata) and gets
  +0.25 armor pen.
- At full charge the gun fires the package's `chargeFire` attack, so an ammo type can give charged
  shots their own effect (a capacitor slug that discharges only on a charged shot).
- `FullAutoOnFullCharge` (Senkoh, Grit) turns a full charge into full auto.
- **Charge time on a part:** `ChargeTime` ×0.7 on a selector (5mm Sleevers) takes the Omaha from
  1.5 s to 1.05 s, checked in game (the stat; how the charge feels not yet checked).
- Not yet read: `ChargeDischargeTime`, `ChargeMaxTimeInChargedState`.

## Jams and malfunctions

No vanilla gun jams on its own; Rostović's "frequently jams" is lore only. What exists:

- **Jam status effects** (type `Jam`: `WeaponMalfunction`, `WeaponMalfunctionRepeat`,
  `BossWeaponMalfunction`, from the Weapon Glitch quickhack). On the player any effect of type Jam
  blocks shooting while it lasts (`weaponTransitions` checks it); on NPCs it's the quickhack.
- **The weapon blowing up in hand:** Weapon Glitch at its top level triggers
  `Attacks.WeaponMalfunctionBlowWeaponHackAttackManMassive` on the wielder.
- **Random behaviour:** Royce's ability re-rolls crit chance, damage type and status effects after
  every reload.

For malfunctioning ammo, the choices are: a jam (a Jam-type effect on the shooter for a moment), a
dud (a shot that does little or nothing), an overpressure burst (damage to the shooter) and
per-reload re-rolls. Ammo is a stack item, so every round in a stack is identical; randomness has
to come per shot or per reload, from script. Per shot needs a hook on the player's shots (NPC shots
already go through our `AIWeapon.Fire` wrap). Untested.

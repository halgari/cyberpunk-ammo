# Ammo catalog: weapons, calibers, what ammo can change

Working document for categorizing the ammo. Everything here was read from the running game (2.50
with Phantom Liberty) unless marked otherwise. The dump scripts are in `tools/catalog/` (run with
`tools/linux/cet.sh -f`); their output (TSV) is in `reference/catalog/` (gitignored, regenerate).

Stats below are each family's `_Default` preset as the player would get it at the current level,
so damage compares within the table, not with other saves.

## Weapons

Every ranged family with its default preset's stats. Hit = damage per projectile × projectiles per shot. Rate = attacks per second. Range = effective range (m). Caliber codes are explained in the next section.

| Family | Type | Mag | Hit | Rate | Range | Lore ammo | Caliber |
|---|---|---|---|---|---|---|---|
| **Power** | | | | | | |  |
| M-10AF Lexington (Militech) | Handgun | 20 | 11 | 5.1 | 25 | 9mm, canon (artbook) | P-9 |
| Slaught-O-Matic (Budget Arms) | Handgun | - | - | - | - | small pistol round, inferred | P-9 |
| Guillotine (Budget Arms) | SMG | 45 | 9 | 7.8 | 22 | 9mm, inferred | P-9 |
| DS1 Pulsar (Darra) | SMG | 40 | 9 | 7.5 | 18 | 9mm, inferred | P-9 |
| M221 Saratoga (Militech) | SMG | 40 | 8 | 8.0 | 20 | pistol caliber, inferred | P-9 |
| Erebus (iconic; 6 pellets) | SMG | 50 | 3×6 | 26.8 | 15 | pistol caliber, inferred | P-9 |
| Unity (Constitutional Arms) | Handgun | 12 | 22 | 2.5 | 30 | .45, wiki (unsourced) | P-45 |
| Liberty (Constitutional Arms) | Handgun | 14 | 19 | 2.7 | 30 | .45, inferred | P-45 |
| Nue (Tsunami) | Handgun | 10 | 28 | 2.0 | 35 | .45, canon (artbook) | P-45 |
| DR5 Nova (Darra) | Revolver | 6 | 25 | 1.8 | 35 | .357/.38 class, inferred | P-MAG |
| Overture (Malorian) | Revolver | 6 | 30 | 1.3 | 35 | .42, canon (DB) | P-MAG |
| Metel (Techtronika) | Revolver | 8 | 39 | 1.1 | 25 | .44 class, explosive rounds, inferred | P-MAG |
| Malorian Arms 3516 (iconic) | Handgun | 10 | 32 | 2.2 | 30 | 14mm (2020) / .577 (Pondsmith), canon | P-MAG |
| DA8 Umbra (Darra) | Rifle | 40 | 8 | 7.3 | 25 | 5.56, inferred | P-556 |
| HJSH-18 Masamune (Arasaka) | Rifle | 24 | 11 | 3.5 | 44 | 5.56 class, inferred | P-556 |
| D5 Copperhead (Nokota) | Rifle | 30 | 9 | 6.0 | 35 | 7.62x39 (AK niche), inferred | P-556 |
| M2067 Defender (Constitutional Arms) | LMG | 80 | 8 | 8.1 | 25 | 5.56/7.62, inferred | P-556 |
| M251s Ajax (Militech) | Rifle | 30 | 12 | 4.9 | 35 | 7.62x51 class, inferred | P-762 |
| Kyubi (Tsunami) | Rifle | 20 | 17 | 3.2 | 44 | 7.62x51 / 6.5mm, inferred | P-762 |
| MA70 HB (Midnight Arms) | LMG | 60 | 12 | 5.1 | 25 | 7.62x51 class, explosive, inferred | P-762 |
| Kolac (Rostovic) | Precision | 6 | 58 | 0.7 | 50 | "large caliber" canon; .338 inferred | P-127 |
| SOR-22 (Midnight Arms) | Precision | 10 | 35 | 1.3 | 52 | "high caliber" canon; .338 inferred | P-127 |
| SPT32 Grad (Techtronika) | Sniper | 4 | 72 | 0.3 | 75 | 12.7x108, inferred | P-127 |
| NDI Osprey (Nokota) | Sniper | 12 | 32 | 1.4 | 50 | "large caliber, tons of gunpowder" canon; .50 inferred | P-127 |
| Mk.31 HMG (Militech) | HMG | 200 | 22 | 6.0 | 50 | .50 BMG class, explosive, inferred | P-127 |
| Crusher (Militech) | Shotgun | 12 | 11×5 | 8.8 | 10 | 12ga, canon (2077) | P-12G |
| VST-37 Pozhar (Techtronika) | Shotgun | 12 | 8×5 | 11.2 | 10 | "high caliber" canon; 12ga inferred | P-12G |
| M2038 Tactician (Constitutional Arms) | Shotgun | 8 | 13×6 | 6.0 | 10 | 12ga, inferred | P-12G |
| DB-4 Igla (Rostovic) | Double barrel | 2 | 17×6 | 5.0 | 15 | 8ga, wiki (unsourced) | P-12G |
| DB-2 Testera (Rostovic) | Double barrel | 2 | 12×12 (both barrels) | 8.9 | 15 | 8ga, inferred (sawed-off Igla) | P-12G |
| Carnage (Budget Arms) | Shotgun | 4 | 12×10 | 6.2 | 7 | 4ga, canon (CDPR video); Judy's text says 12ga | P-4G |
| **Tech** | | | | | | |  |
| JKE-X2 Kenshin (Arasaka) | Handgun | 20 | 11 | 3.9 | 30 | tungsten-tipped round, canon | T-LIGHT |
| Militech Ticon | Handgun | 21 | 10 | 2.6 | 33 | solid-metal slug, inferred from Omaha | T-LIGHT |
| M-76e Omaha (Militech; 3 slugs) | Handgun | 9 | 6×3 | 9.0 | 25 | solid-metal slugs, canon | T-LIGHT |
| HA-4 Grit (Hansen) | Handgun | 30 | 13 | 3.6 | 25 | pistol slug, inferred | T-LIGHT |
| Senkoh LX (Arasaka) | SMG | 30 | 9 | 4.8 | 22 | pistol slug, inferred | T-LIGHT |
| RT-46 Burya (Techtronika) | Revolver | 4 | 44 | 0.8 | 37 | very dense slug, canon | T-HEAVY |
| DR-12 Quasar (Darra) | Revolver | 16 | 14 | 3.2 | 30 | birdshot from rails, canon | T-LIGHT |
| M-179e Achilles (Militech; 5 slugs) | Precision | 9 | 5×5 | 8.2 | 52 | vehicle-piercing slug, canon | T-HEAVY |
| Nekomata (Tsunami) | Sniper | 4 | 44 | 0.9 | 75 | tungsten spike, canon | T-HEAVY |
| Rasetsu (Tsunami) | Sniper | 3 | 74 | 0.3 | 79 | slug, inferred | T-HEAVY |
| DB-2 Satara (Rostovic) | Double barrel | 2 | 8×14 | 10.8 | 15 | steel spikes, canon | T-HEAVY |
| **Smart** | | | | | | |  |
| A-22B Chao (Kang Tao) | Handgun | 21 | 10 | 2.0 | 30 | caseless guided gyrojet, canon (type) | S-10 |
| Kappa (Tsunami) | Handgun | 30 | 8 | 5.5 | 20 | guided, canon (type) | S-10 |
| HJKE-11 Yukimura (Arasaka) | Handgun | 30 | 9 | 4.5 | 25 | guided, canon (type) | S-10 |
| G-58 Dian (Kang Tao) | SMG | 45 | 6 | 8.0 | 25 | caseless guided, canon (type) | S-10 |
| TKI-20 Shingen (Arasaka) | SMG | 30 | 8 | 4.5 | 20 | caseless self-guiding, canon (artbook) | S-10 |
| Warden (Hansen; 4 per shot) | SMG | 40 | 4×4 | 14.7 | 20 | guided, canon (type) | S-10 |
| Hercules 3AX (Militech) | Rifle | 90 | 8 | 6.3 | 35 | rifle smart round, inferred | S-10 |
| D5 Sidewinder (Nokota) | Rifle | 30 | 9 | 6.0 | 30 | Copperhead-size smart round, inferred | S-10 |
| Ashura (Tsunami) | Sniper | 1 | 109 | 0.3 | 50 | one large smart dart, canon | S-DART |
| L-69 Zhuo (Kang Tao; 8 barrels) | Shotgun | 4 | 8×8 | 7.0 | 20 | 8 smart projectiles, canon | S-CLUSTER |
| DB-4 Palica (Rostovic) | Double barrel | 2 | 9×16 | 13.3 | 10 | smart mini-rockets, canon | S-CLUSTER |

The Slaught-O-Matic (disposable, non-reloadable) has no `_Default` preset, so no stats were read. Grenade launchers are obsolete records; the Projectile Launch System cyberware fires its own projectile (`Ammo.Standard`) and isn't in this table.

Sources for "Lore ammo": "canon" means stated in the game's database entries, the 2077 artbook, a
CDPR video or the tabletop books; "inferred" means matched to the gun's design or a real-world
analog. The Carnage is the one conflict: CDPR's *Tools of Destruction* video calls it a 4-gauge,
but Judy's message about Mox (the iconic Carnage) says 12-gauge.

## Calibers (locked)

13 calibers: 8 Power, 2 Tech, 3 Smart. Each is one `AmmoOverhaul.calibers` entry; its guns are
picked by their family tag (`Lexington`, `Nue`, …).

**A caliber is size only. What the projectile is made of or does (FMJ, hollow point, tungsten,
flechette, explosive, …) is the ammo type, chosen within the caliber.** Power keeps the most
calibers because bore and case size is what sets conventional guns apart; Tech and Smart differ
mostly by what they fire, which is the ammo type's job.

| Code | Caliber | Guns |
|---|---|---|
| **Power** | gunpowder cartridges | |
| P-9 | 9mm | Lexington, Slaught-O-Matic, Guillotine, Pulsar, Saratoga, Erebus |
| P-45 | .45 | Unity, Liberty, Nue |
| P-MAG | 12mm magnum revolver | Nova, Overture, Metel, Malorian 3516 |
| P-556 | 5.56mm | Umbra, Masamune, Copperhead, Defender |
| P-762 | 7.62mm | Ajax, Kyubi, MA70 HB |
| P-127 | 12.7mm | Kolac, SOR-22, Grad, Osprey, Mk.31 HMG |
| P-12G | 12-gauge | Crusher, Pozhar, Tactician, Igla, Testera |
| P-4G | 4-gauge | Carnage |
| **Tech** | rail-fired projectiles | |
| T-LIGHT | light rail (5mm) | Kenshin, Ticon, Omaha, Grit, Senkoh LX, Quasar |
| T-HEAVY | heavy rail (9mm) | Burya, Achilles, Nekomata, Rasetsu, Satara |
| **Smart** | guided micro-rockets | |
| S-10 | 10mm micro-rocket | Chao, Kappa, Yukimura, Dian, Shingen, Warden, Hercules 3AX, Sidewinder |
| S-CLUSTER | 20mm cluster shell | Zhuo, Palica |
| S-DART | 25mm guided dart | Ashura |

Why these merges (closest by the game's damage per projectile, and by bore):

- The 3516 (32 per hit) sits inside the magnum revolvers' range (25 to 39), so it's a magnum.
- The precision rifles (Kolac 58, SOR-22 35) overlap the snipers (Grad 72, Osprey 32), so .338
  became 12.7mm.
- 8-gauge (21mm bore) is far nearer 12-gauge (18.5mm) than 4-gauge (26.7mm); the Igla's 8-gauge
  is an unsourced wiki claim. The Carnage stays the only 4-gauge, for loads 12-gauge can't carry.
- Kept apart on purpose: 9mm / .45 / magnum and 5.56 / 7.62. They are close in damage, but bore
  and spread between them are part of what makes Power varied.
- Tech by size: the Quasar hits like the Tech pistols (14.5), the Burya like the Tech rifles (44).
  The Satara is heavy by damage per shot (14 spikes, about 106); that it fires many small
  projectiles comes from the gun's stats, not its caliber.
- Smart: the smart rifles hit like the smart pistols (8 to 10 per hit). The smart shotguns fire 8
  to 16 rockets per trigger pull, and ammo is used per pull, so they get their own shell. The mm
  sizes for Tech and Smart are invented; the lore gives none.

**Guns keep their vanilla behavior.** A caliber only decides which inventory stack a gun loads
from. Pellet count, fire rate and so on stay the gun's own, so the Satara still fires 14 spikes
from the heavy rail stack and the Grad still fires one round. Only an ammo type (through its
selector part) changes how a gun shoots. The flip side: a gun moved to another caliber no longer
takes its old vanilla stack (the Satara no longer loads shotgun shells, the Kolac no longer loads
rifle ammo).

### Vanilla ammo items

The four vanilla ammo items become the standard round of their nearest caliber, so stacks in
existing saves keep a meaning and vanilla loot, vendors and crafting keep supplying them:

| Vanilla item | Becomes |
|---|---|
| `Ammo.HandgunAmmo` | 9mm (P-9) |
| `Ammo.RifleAmmo` | 5.56mm (P-556) |
| `Ammo.ShotgunAmmo` | 12-gauge (P-12G) |
| `Ammo.SniperRifleAmmo` | 12.7mm (P-127) |

The other nine calibers (.45, magnum, 7.62mm, 4-gauge, both Tech, all three Smart) are new items
that need adding to loot, vendor stock and crafting. In an old save, guns moved to one of them start
with no ammo; a new game is recommended but not required. NPC guns get the same caliber patch as
the player's, so NPCs carry and drop the right ammo without extra work.

## What an ammo type can change

An ammo type comes with its selector part, and parts change the gun the same way vanilla mods,
magazines and receivers do: **stat modifiers** on the part (`statModifiers`), and **gameplay
packages** (`OnAttach`) whose effectors do things on hit, on kill, while aiming, and so on. Every
stat below is one some vanilla part already modifies, so the engine reads it from the weapon. Not yet
checked on our selector part: that its stat modifiers reach the weapon (expected, since vanilla
`Prt_Magazine` parts work this way).

### Stats (grouped)

- **Damage:** `DamagePerHit`, `BonusDamagePerHit`, `PhysicalDamage` / `ThermalDamage` /
  `ElectricDamage` / `ChemicalDamage` (damage type split), `PowerMod1_DamageConvert` (convert a
  share to Thermal), `HeadshotDamageMultiplier`, `CritChance`, `CritDamage`, `HeadshotCritChance`,
  `BonusDamageAgainstElites` / `Bosses` / `Mechanicals`, `WeaponVehicleDamagePercentBonus`,
  `StealthHitDamageMultiplier`, `AdditionalStealthDamage`, `DamageFalloffDisabled`.
- **Armor and cover:** `ArmorPenetrationBonus`, `CanWeaponIgnoreArmor`, `HackingPenetration`;
  Tech: `TechPierceEnabled`, `TechPierceChargeLevel`, `TechPierceDamageFactor`.
- **Range and ballistics:** `EffectiveRange`, `EffectiveRangeBonus`, `MaximumRange`, `Range`,
  `BulletMagnetismDefaultAngle` / `HighVelocityAngle` (aim assist).
- **Accuracy:** `Spread*` (hip and ADS, X and Y, default and max), `SpreadPenalty`,
  `ARSMGLMGMod3_SpreadPerShot`, `ShotgunMod3_Spread` (pellet grouping), `Sway*`.
- **Recoil:** `RecoilKickMin` / `Max` / `MaxADS`, `RecoilAngle`, `RecoilKickReduction`,
  `RecoilRecoveryTime`, `RecoilDir*`, `RecoilDrift*`, `HasMuzzleBrake`.
- **Fire rate and shots:** `CycleTimeBonus`, `CycleTime_Burst*`, `NumShotsInBurst*`,
  `ProjectilesPerShotBonus` (pellets per shot: Doom Doom gives the single-shot Nova +2, Suzie +1;
  the Headsman turns pellets into one slug). A scatter load for a single-shot gun pairs it with
  wider `Spread*` and lower `DamagePerHit` (untested with Tech charge). Also
  `FullAutoOnFullCharge`.
- **Magazine and reload:** `MagazineCapacityBonus`, `ReloadTimeBonus`, `MagazineAutoRefill`.
- **Ricochet:** `RicochetChance`, `RicochetCount`, `RicochetMinAngle` / `MaxAngle`,
  `RicochetTargetSearchAngle`, `BonusRicochetDamage`, `BonusRicochetCritChance`,
  `BonusRicochetAngle`.
- **Charge (Tech):** `ChargeTime`, `BaseChargeTime`, `ChargeMultiplier`, `FullyChargedThreshold`,
  `OverchargeThreshold`, `CanOverchargeWeapon`, `CanFullyChargeWeapon`, `ChargeDischargeTime`,
  `ChargeMaxTimeInChargedState`.
- **Smart:** `SmartGunHitProbability`, `SmartGunPlayerProjectileVelocity`, `SmartMod2_Velocity`,
  `SmartGunSpiralRadius`, `SmartGunAdsMaxLockedTargets`, `SmartGunTrackMultipleEntitiesInADS`,
  `BonusSmartGunTimeToLock`, lock angles (`SmartGun*LockingAngle*`, `*TargetableAngle*`),
  `SmartGun*TimeToUnlock`.
- **Status chances (native, no script needed):** `BurningApplicationRate`,
  `BleedingApplicationRate`, `PoisonedApplicationRate`, `ElectrocutedApplicationRate`,
  `StunApplicationRate`, `DurationBonusBleeding`, `TechMod1_EMPChance`.
- **Body hits:** `HitDismembermentFactor`, `HitWoundsFactor`, `HitReactionFactor` (flinch),
  `KnockdownImpulse`, `PhysicalImpulse`.
- **Handling and noise:** `AimInTime` / `AimOutTime`, `EquipDuration`, `WeaponNoise`,
  `CanSilentKill`, `Weight` (of the gun, not the ammo).
- **Stamina:** a stamina cost per shot is changed by vanilla mods (PowerMod2's "+stamina cost per
  bullet"); a natural quirk for overpressure rounds.

### Effects on hit (effectors in vanilla)

Effector types vanilla parts and iconic weapons use, so they work on a weapon part:

| Effector | What it does | Vanilla examples |
|---|---|---|
| `AddStatusEffectToAttack` | adds a status effect to the hit (vanilla still checks immunity) | Knockdown, Stun, Poison, Burn, Bleed, EMP, MinorBlind, crippled limbs |
| `ApplyStatusEffect` / `...ByChance` | applies a status effect when a condition fires | most iconic abilities |
| `TriggerAttack` | sets off a separate attack (an explosion) at the target | Testera "Nicolas" explosion, Sidewinder "Divided" chemical blast, Satara "Brick" EMP, Microgenerator |
| `OverrideRangedAttackPackage` | replaces the gun's bullet attack: **explosive rounds** | Chimera power mod (`Attacks.ChimeraPowerModExplosiveBulletPackage`) |
| `AddHitFlagToAttack` | flags the hit: `Nonlethal`, `ForceKnockdown`, `ForceDismember`, `CriticalHit`, `StealthHit` | Kiroshi fragment (non-lethal), perks |
| `ModifyAttackCritChance` | crit chance on that hit | perks, iconics |
| `ApplyStatGroup` | temporary stat buff (fire rate after a headshot, etc.) | many iconics |
| `ModifyStatPoolValue` | changes health, ammo, stamina | iconics that refund ammo |

Explosion attacks already in the game include `Attacks.BulletLightExplosion`,
`Attacks.BaseBulletExplosion`, `Attacks.ExplosiveBulletEffect`, `Attacks.ExplosionSmall_Thermal`,
`Attacks.HerculesHipBulletExplosion`, `Attacks.RocketExplosion`, `Attacks.EmpBlastStrongArms`,
`Attacks.BiotechGrenadeV2` (chemical), `Attacks.ElectricAbility`, the Microgenerator and EMP
grenade blasts.

### Status effects available (by type)

- **Burning:** Burning, MediumBurning, Overheat, burn-grenade tiers.
- **Shock:** Electrocuted, ElectrocutedNoDamage.
- **Poison:** LightPoision, Poisoned, HeavyPoision, bio-grenade tiers, ContagionPoison.
- **Bleeding:** MinorBleeding, Bleeding, BleedingInfinite.
- **EMP:** EmpVeryLowDamage to EmpVeryHighDamage, EmpJamWeaponAccuracyDebuff, EmpJamWeaponChance.
- **Blind:** MinorBlind, ShortBlind, ModerateBlind, MajorBlind, flash-grenade tiers, SmokeScreen.
- **Stun and knockdown:** Stun, HeavyStun, WeakExplosionStun, Knockdown, HitReactionStagger.
- **Wounds:** CrippledArm / Leg / Hand (left and right), DismemberedArm / Leg.
- **Non-lethal:** Unconscious, TranquilizerUnconscious (and the `Nonlethal` hit flag).
- **Hacks (Smart):** CyberwareMalfunction, CyberwareShutdown, LocomotionMalfunction (Kappa
  "George"), WeaponMalfunction (jam), SystemCollapse, Overload, Madness, CommsNoise,
  JamCommuniations, MemoryWipe, Deaf / HearingImpaired.
- **Debuffs:** Vulnerable, MajorVulnerable, Weak, LowAccuracy, Exhausted, Pain.

### What iconic weapons already do (proof each is possible)

- **Explosive rounds:** Chimera mod, Doom Doom (3 per shot), Chao "Ogou" (2-round burst),
  Osprey prototype, Shingen Mark V, the `TinyMike` ability, Zhuo "Ba Xing Chong" (rocket shotgun with smart
  targeting and blast radius).
- **Element:** Yinglong (Electric + EMP), Saratoga "Problem Solver" (Electric, disables cyberware),
  the `Nash` ability (Chemical, poison), the `Buck` ability (incendiary "explosive-packed bullets"), Copperhead "Psalm 11:6"
  (fire).
- **Hacks on hit:** Quasar "Gris-Gris" (uploads a random quickhack), Chimera smart mod (quickhack by
  body part), Kappa "Crimestopper" (disables cyber-limbs, freezes the target).
- **Blind:** Kenshin "Apparition".
- **Penetration:** Buzzsaw (high-penetration SMG rounds), Nekomata "Breakthrough" (through walls,
  then ricochets), Senkoh prototype (penetrates without charging), Rasetsu (bends to hit several).
- **Shot shape:** Tactician "Headsman" (single slug instead of pellets, very accurate),
  the `Suzie` ability (extra round per shot), Carnage "Edgerunners" (faster, less accurate).
- **Ricochet without cyberware:** Liberty "Kongou".
- **Non-lethal:** blunt weapons and the Kiroshi fragment set the `Nonlethal` flag; targets go
  Unconscious instead of dying.

## What fits each family (design notes)

Axes, as discussed: **caliber** (above), **ammo type** (what it does to the gun and on hit) and
**rarity** (the budget). Faction ammo is its own line on top: well-funded groups carry strong
loads whose blueprints may not exist anywhere in the game.

- **Rarity budget:** Common and Uncommon have a small budget, so a perk (benefit) has to be paid
  for with a quirk (drawback). Higher rarities can have perks without quirks. Legendary can add a
  special effect.
- **Power (gunpowder):** flies straight; changes come from the bullet and the powder. Fits:
  FMJ, hollow point (more damage, less armor penetration), armor-piercing, +P overpressure (damage
  and range for recoil and stamina), subsonic (quiet, `CanSilentKill`, less range), incendiary,
  explosive tip, ricochet-friendly rounds, rubber or beanbag (`Nonlethal`, knockdown, fewer
  ricochets). Shotguns: buckshot, birdshot, slug (one projectile, accurate, long range), flechette
  (buckshot with tighter grouping and more range), dragon's breath (fire). 4-gauge only: micro
  grenades (explosion on hit), EMP, gas, flare (blind).
- **Tech (rails):** the projectile is a dumb slug, so no complex electronics. Fits: denser or
  harder slugs (penetration, armor), lighter slugs (faster charge, less damage), split or
  flechette slugs, ferromagnetic slugs that ricochet, capacitor slugs that store charge and
  release it on impact (Electric damage, Shock, small EMP).
- **Smart (guided rockets):** little kinetic damage, but impact effects are their strength. Fits:
  payloads (EMP, chemical, incendiary, flash), hack carriers (cyberware malfunction, quickhack
  upload, weapon jam at legendary), better guidance (hit probability, velocity, more targets,
  faster lock), longer flight. Smart sniper darts should almost always hit and cost a lot.

### Built (v1)

Every caliber has a Common and an Uncommon round. The Common round is the gun's vanilla ammo in
all but name, weight and price: guns aren't modified. Only the Uncommon loads change stats.

| Caliber | Common | Uncommon | Uncommon effect |
|---|---|---|---|
| P-9 | 9mm Ball (vanilla handgun ammo) | 9mm Mushrooms | damage ×1.2, armor pen −0.5 |
| P-45 | .45 Ball | .45 Mushrooms | as 9mm Mushrooms |
| P-MAG | 12mm Ball | 12mm Mushrooms | as 9mm Mushrooms |
| P-556 | 5.56 Ball (vanilla rifle ammo) | 5.56 Mushrooms | as 9mm Mushrooms |
| P-762 | 7.62 Ball | 7.62 Mushrooms | as 9mm Mushrooms |
| P-127 | 12.7 Ball (vanilla sniper ammo) | 12.7 Mushrooms | as 9mm Mushrooms |
| P-12G | Buckshot (vanilla shotgun ammo) | Slugs | one projectile with the whole shot, spread ×0.2, range ×2 |
| P-4G | 4ga Buckshot | 4ga Slugs | as Slugs, plus damage ×1.3, armor pen +0.5, knockdown, recoil ×1.6 |
| T-LIGHT | 5mm Rail Slugs | 5mm Sleevers | charge time ×0.7, damage ×0.95 |
| T-HEAVY | Heavy Rail Slugs | Heavy Sleevers | as 5mm Sleevers |
| S-10 | 10mm Seekers | 10mm Dumbfires | damage ×1.8, no guidance |
| S-CLUSTER | 20mm Seekers | 20mm Dumbfires | as 10mm Dumbfires |
| S-DART | 25mm Seekers | 25mm Dumbfires | as 10mm Dumbfires |

Each caliber also has a second Uncommon round (2026-10-28):

| Load | Calibers | Effect |
|---|---|---|
| +P | 9mm, .45, 12mm, 5.56, 7.62, 12.7 | damage ×1.1, effective range ×1.15, recoil ×1.25, stamina per shot ×1.3 |
| Birdshot | 12-gauge | pellets ×2 (same total damage), spread ×1.6, armor pen −0.5, flinch +0.5 |
| 4ga Birdshot | 4-gauge | pellets ×2.5 (same total damage), spread ×2, armor pen −0.5, flinch +0.5 |
| Bricks | 5mm rail, heavy rail | damage ×1.15, charge time ×1.3 |
| Short-Fuse | 10mm, 20mm, 25mm smart | damage ×1.2, reach ×0.4 |

4-gauge has no Common slug: Buckshot is its Common round and the Slug is Uncommon only. 4ga Slugs
don't pierce cover; piercing is kept for the higher-tier penetrators.

Calibers differ in ammo weight, price and how often they turn up, not in how the gun shoots:

| Caliber | Ammo weight (× the 9mm round) | Price (× the game ammo it comes from) |
|---|---|---|
| 9mm, 5.56, 12-gauge | 1× | 1× |
| .45, 7.62 | 1.5× | 1.2× (.45), 1.3× (7.62) |
| 12mm | 2× | 1.6× |
| 12.7, 4-gauge | 2.5× | 2× |
| Heavy rail | 2× the 5mm round | 1.5× |
| 20mm cluster | 1.5× the 10mm round | 1.3× |
| 25mm dart | 3× the 10mm round | 2.5× |

### Built (Rare and Epic, 2026-10-29)

96 Rare and Epic rounds, all made by `tools/rounds/rounds.py` (records, list entries, text, icon
data; edit there and rerun it). Each is its caliber's plain Uncommon with the changes below, at
x4 (Rare) or x8 (Epic) the Common price. The effect line is the one the item shows. Chances are per
shot (each pellet of a shotgun rolls its share).

- **Steel-Core** (Rare; 9mm, .45, 12mm, 5.56, 7.62, 12.7): Ignores 25% of armor. -10% damage.
- **Incendiary** (Rare; 9mm, .45, 12mm, 5.56, 7.62, 12.7): 15% chance (9mm: 8%) to set the target on fire. A quarter of the damage is fire damage. -5% damage.
- **Subsonic** (Rare; 9mm, .45, 5.56): Much quieter shots. Silent kills. -10% damage. -10% range.
- **Bouncers** (Rare; 9mm, .45, 5.56): 30% chance to ricochet once. -15% damage.
- **Rubber** (Rare; 9mm, .45, 12mm): Non-lethal: targets go down unconscious instead of dying. Much stronger flinch. -40% damage.
- **Penetrator** (Epic; 9mm, .45, 5.56): Ignores 60% of armor.
- **Penetrator** (Epic; 12mm, 7.62, 12.7): Ignores 60% of armor. Goes through thin cover at half damage. (`TechPierceEnabled` +1, `TechPierceChargeLevel` x0, `TechPierceDamageFactor` -0.5: every shot pierces as a charged Tech shot, and damage through cover is times 1 + factor, so half.)
- **Match** (Epic; 9mm, .45, 12mm, 5.56, 7.62, 12.7): Damage varies -2% to +6% instead of -10% to +1%. 30% less spread and sway.
- **Toxin Core** (Epic; 9mm, .45, 12mm, 5.56, 7.62, 12.7): 25% chance to poison. 30% of the damage is chemical damage.
- **Shredders** (Epic; 9mm, .45, 12mm, 5.56, 7.62): 30% chance to cause bleeding. Twice the dismemberment chance.
- **Hardcast** (Rare; 12mm): 25% chance to stagger. Ignores 10% of armor. +20% recoil.
- **Ballistic Tip** (Rare; 7.62, 12.7): +40% range. +5% damage. Armor is 10% more effective against it.
- **Ping** (Rare; 7.62, 12.7): Targets hit show through walls for 5 seconds. -10% damage. (Every hit applies `AmmoOverhaul.PingTag`: Hawk's tag, `BaseStatusEffect.KyubiMyersTag`, for 5 s instead of 15.)
- **HEI** (Epic; 12.7): +50% damage against drones, mechs and vehicles. 20% chance to set the target on fire.
- **Flechettes** (Rare; 12ga, 4ga): Tighter spread. Double range. -15% damage.
- **Beanbags** (Rare; 12ga): Fires one projectile with the whole shot's damage. Knocks targets down. Non-lethal: targets go down unconscious instead of dying. -50% damage.
- **Dragon's Breath Lite** (Rare; 12ga): 30% chance to set the target on fire. Half the damage is fire damage. -20% range.
- **Dragon's Breath** (Epic; 12ga, 4ga): All damage is fire damage. 60% chance to set the target badly on fire.
- **Frag-12** (Epic; 12ga): Fires one projectile with the whole shot's damage. Ignores 50% of armor. +50% damage against drones, mechs and vehicles.
- **Long Flechettes** (Epic; 12ga): Tighter spread. 3.5x range.
- **Riot** (Rare; 4ga): Fires one projectile with the whole shot's damage. Knocks targets down. Non-lethal: targets go down unconscious instead of dying. -50% damage.
- **Flares** (Rare; 4ga): Fires one projectile with the whole shot's damage. Blinds the target for a moment. 30% chance to set the target on fire.
- **Thermite Slugs** (Epic; 4ga): Fires one projectile with the whole shot's damage. Sets the target badly on fire. Double damage against drones, mechs and vehicles.
- **Ferro** (Rare; 5mm, Heavy): 40% chance to ricochet, up to twice. -10% damage.
- **Split Slugs** (Rare; 5mm, Heavy): Fires three projectiles that share the shot's damage. Wider spread. Doesn't pierce cover.
- **Feedback** (Rare; 5mm, Heavy): Shots bend toward targets near the crosshair. -10% damage.
- **DU Penetrator** (Epic; 5mm, Heavy): Pierces cover at a lower charge. Loses half as much damage through cover. Ignores 50% of armor.
- **Toxic Scatter** (Epic; 5mm, Heavy): Fires five projectiles that share the shot's damage. Wider spread. 25% chance to poison.
- **Superconductor** (Epic; 5mm, Heavy): Full auto at full charge.
- **EMP Capacitor** (Epic; 5mm, Heavy): 30% chance of an EMP. 30% of the damage is electrical damage.
- **EMP Payload** (Rare; 10mm, 20mm, 25mm): 25% chance of an EMP. 30% of the damage is electrical damage. -10% damage.
- **Incendiary Payload** (Rare; 10mm, 20mm, 25mm): 25% chance to set the target on fire. 30% of the damage is fire damage. -10% damage.
- **Chem Payload** (Rare; 10mm, 20mm, 25mm): 25% chance to poison. 30% of the damage is chemical damage. -10% damage.
- **Flash Payload** (Rare; 10mm, 20mm, 25mm): 30% chance to blind the target. -20% damage.
- **Hunter** (Epic; 10mm, 20mm, 25mm): Locks two more targets. Locks on twice as fast. +20% hit chance. Rounds fly 30% faster.
- **Hack Carrier** (Epic; 10mm, 20mm, 25mm): 15% chance of a cyberware malfunction. 15% chance to jam the target's weapon.
- **Shaped Charge** (Epic; 10mm, 20mm, 25mm): Ignores 50% of armor. +50% damage against drones, mechs and vehicles.

### Built (Legendary, 2026-10-30)

14 Legendary rounds (tier 4), from `tools/rounds/rounds.py`, spec
`docs/superpowers/specs/2026-10-29-legendary-rounds-design.md`. x16 the Common price, never sold, no
recipe; NPC roll Elite 3%, Boss and MaxTac 10%; 0.2% per ammo stack in a container holding Epic
rounds; a Legendary stack is a quarter of the Epic one it replaces.

- **Gatecrasher** (Legendary; 7.62, 12.7): Ignores all armor. No damage falloff. Goes through cover at full damage.
- **Cook-off** (Legendary; 9mm, .45, 12mm, 5.56, 7.62): A kill sets off a blast at the body (`AmmoOverhaul.CookOffBlast`: 35% of each target's max health, 6 m). A hit on V sets off V's selected grenade if it has a charge, and takes the charge (`CookOff.reds`).
- **Kebab** (Legendary; 5mm, Heavy): A charged shot goes through every body and wall in its line with no damage lost (`TechPierceDamageFactor` x0; measured: no loss on the second body).
- **Lockout** (Legendary; 10mm, 20mm, 25mm): Every hit jams the target's weapon for 4 seconds (`AmmoOverhaul.LockoutJam`).
- **Mule Kick** (Legendary; 4ga): Buckshot with knockback at the game's cap. `aoMuleKick` (MuleKick.reds): each of V's shots shoves V 14 m/s away from the aim (PSMImpulse, the jump pads' push); a hit knocks the target down once per shot, Elite, Boss and MaxTac stagger (ForceStagger), a hit on V knocks V down.
- **Heartseeker** (Legendary; 12ga): One guided slug (the smart package, `aoRangedAttack`); while it's fitted in V's drawn gun the gun record's evolution is Smart, which turns the lock on (`Heartseeker.reds`). Locks heads. Ignores all armor. +100% headshot damage. +50% crit chance.

### Ammo ideas so far

- **Dumbfire (Smart):** much more damage, guidance removed entirely, so the smart gun becomes a
  small grenade launcher. Also the Scavengers' broken-guidance junk rounds.
- **Toxic rounds, several ways:**
  - Power: poison-coated or toxin-cored bullets (`PoisonedApplicationRate`, Chemical share).
  - Tech: a payload load that gives up the rail's penetration for a scatter of poison pellets
    (more projectiles, poison on hit, no pierce).
  - A gas round that bursts into a cloud: a blast (`explosionAttack`) carrying Poisoned, or a
    triggered bio-grenade attack (`Attacks.BiotechGrenadeV2`, as on the Sidewinder "Divided").
    Natural for 4-gauge, Smart payloads and the cluster shell.
- **Dragon's breath:** the closest to a fire burst from the muzzle is many low-damage pellets
  that each set a weak, short burn, in a wide spread. Being tested on a 9mm round (8 pellets, a
  light burn). A true cone of fire from the muzzle would need its own area attack at the gun
  (not looked into yet).
- **Overpressure:** a Power load that punches through cover like a charged Tech shot. Built as
  the 12mm, 7.62 and 12.7 Penetrator (`TechPierceEnabled` works on a Power gun: probed on an Ajax).
- **Capacitor slug (Tech):** stores rail energy and discharges on impact, only on charged shots
  (through the package's `chargeFire`).
- **Rail feedback slug (Tech):** corrects itself slightly against the rails (bullet magnetism).

## Next lineup (brainstorm, 2026-10-28)

Per caliber: 1 Common, 2 Uncommon, 4 Rare, 4 Epic. Not every caliber gets every round; a family
has a pool and each caliber takes what fits it.

**Tier rules**

- Uncommon: sidegrades, one perk paid for with one quirk.
- Rare: specialists that add a mechanic (element, status, ricochet, control, pellet pattern).
- Epic: the far end of a dimension; expensive and scarce.
- Armor pen: none at Common/Uncommon, some at Rare (about 20-30% of armor ignored), high at Epic
  (about 50-70%). Full armor ignore (`CanWeaponIgnoreArmor`) and no damage falloff
  (`DamageFalloffDisabled`) are kept for Legendary or faction rounds.
- Cover piercing: Epic penetrators only.
- Explosives: only where there's room for a charge that matters. Below about 20mm a round carries
  a few grams at most (a hand grenade has about 180 g), so it bursts on or in the target. Such
  rounds are HEI: bonus against drones, mechs and vehicles, no area damage. Real area damage only
  from about 20mm up (4ga, 20mm and 25mm Smart), with a small radius.
- Power guns have no power source: no shock or EMP on Power rounds.

**Power (9mm, .45, 12mm, 5.56, 7.62, 12.7)**

| Tier | Round | Effect | Calibers |
|---|---|---|---|
| Uncommon | Mushrooms (built) | more damage, less armor pen | all |
| Uncommon | Hot loads (+P) | more damage and range; more recoil, stamina cost per shot | all |
| Rare | Steel-core AP | some armor pen, a little less damage | all |
| Rare | Incendiary | Burning chance | all (9mm weak) |
| Rare | Subsonic | quiet, silent kills, less range | 9mm, .45, 5.56 |
| Rare | Bouncers | ricochet chance and count, less damage | 9mm, .45, 5.56 |
| Rare | Rubber | non-lethal, flinch | handguns (fills 12mm's gap) |
| Epic | Penetrator (tungsten/DU) | high armor pen, pierces cover | 12mm, 7.62, 12.7 |
| Epic | HEI | bonus against drones, mechs, vehicles; Burning chance; no area | 12.7 |
| Epic | Match grade | steady damage (see below), tighter spread, less sway | all |
| Epic | Toxin core | Poisoned, Chemical share | all |
| Epic | Shredders | heavy Bleeding, dismemberment | handguns, 5.56 |

9mm and .45 keep all five Rares (Rubber is a niche extra).

**Grid (agreed 2026-10-28).**

| Caliber | Uncommon | Rare | Epic |
|---|---|---|---|
| 9mm | Mushrooms, Hot loads | Steel-core AP, Incendiary (weak), Subsonic, Bouncers, Rubber | Penetrator (no cover pierce), Match, Toxin core, Shredders |
| .45 | Mushrooms, Hot loads | Steel-core AP, Incendiary, Subsonic, Bouncers, Rubber | Penetrator (no cover pierce), Match, Toxin core, Shredders |
| 12mm | Mushrooms, Hot loads | Steel-core AP, Incendiary, Rubber, Hardcast | Penetrator, Match, Toxin core, Shredders |
| 5.56 | Mushrooms, Hot loads | Steel-core AP, Incendiary, Subsonic, Bouncers | Penetrator (no cover pierce), Match, Toxin core, Shredders |
| 7.62 | Mushrooms, Hot loads | Steel-core AP, Incendiary, Ping, Ballistic tip | Penetrator, Match, Toxin core, Shredders |
| 12.7 | Mushrooms, Hot loads | Steel-core AP, Incendiary, Ping, Ballistic tip | Penetrator, HEI, Match, Toxin core |
| 12ga | Slugs, Birdshot | Flechette, Beanbag, Dragon's breath (light), Gas | Dragon's breath, Frag-12, Tungsten slug, Flechette (long) |
| 4ga | Slugs, Barn Door | Flare, Riot, Gas canister, Flechette | Kinetic penetrator, Micro-grenade, Dragon's breath, Thermite slug |
| 5mm rail | Sleevers, Dense slugs | Capacitor, Ferro, Split slug, Feedback | DU penetrator, Toxic scatter, Superconductor, EMP capacitor |
| Heavy rail | Sleevers, Dense slugs | Capacitor, Ferro, Split slug, Feedback | DU penetrator, Toxic scatter, Superconductor, EMP capacitor |
| 10mm smart | Dumbfires, Short-fuse | EMP, Incendiary, Chem, Flash payloads | Hunter, Hack carrier, Shaped charge, Splitter |
| 20mm cluster | Dumbfires, Short-fuse | EMP, Incendiary, Chem, Flash payloads | HE, Hunter, Hack carrier, Shaped charge |
| 25mm dart | Dumbfires, Short-fuse | EMP, Incendiary, Chem, Flash payloads | HE, Hunter, Hack carrier, Shaped charge |

The 4ga EMP shell is dropped (Power guns have no power source). New rounds in the grid:

- Ping (7.62, 12.7 Rare; first called Tracer): the target hit is marked and shows through walls for a few seconds.
- Ballistic tip (7.62, 12.7 Rare): more effective range and more damage at distance, a little
  less armor pen.
- Hardcast (12mm Rare): heavier hit (stagger, knockdown impulse), a little armor pen.
- Thermite slug (4ga Epic): long heavy burn, big damage to mechs and drones.
- Splitter (10mm smart Epic): two or three smaller rockets per shot, less damage each. Untested:
  likely several projectiles at the muzzle (`ProjectilesPerShot` on a smart gun), not a split in
  flight; needs a probe.
- Penetrator on 9mm, .45 and 5.56: high armor pen, no cover piercing.

**12-gauge:** Uncommon Slugs (built) and Birdshot (more pellets, wide, low damage, strong flinch).
Rare Flechette (tighter, about 2x effective range, some armor pen), Beanbag (non-lethal
knockdown), light Dragon's breath, Gas. Epic Dragon's breath (full), Frag-12 (HEI slug), Tungsten
slug (high pen, pierces cover), long-range Flechette (about 3-4x effective range, high armor pen).

**4-gauge:** Uncommon Slugs (built) and Barn Door (about twice the pellets, very wide, much less
per pellet). Rare Flare (Blind plus light burn), Riot (non-lethal knockdown), Gas canister,
Flechette. Epic Kinetic penetrator (pierces cover and armor, huge knockback and recoil),
Micro-grenade (radius about 1.5-2 m), EMP shell, 4ga Dragon's breath.

**Tech (5mm, heavy rail):** Uncommon Sleevers (built) and Dense slugs (more damage and some pen,
slower charge). Rare Capacitor (Shock on charged shot), Ferro (ricochet), Split slug (several
projectiles, no pierce), Feedback (about 2 degrees bullet magnetism). Epic DU penetrator (pierces at
lower charge, more pierce damage), Toxic scatter, Superconductor (overcharge or full auto on full
charge), EMP capacitor.

**Smart (10mm, 20mm, 25mm):** Uncommon Dumbfires (built) and Short-fuse (more damage, shorter
reach; untested whether smart projectiles have falloff or only a flight time). Rare EMP,
Incendiary, Chem and Flash payloads. Epic HE (20mm and 25mm only, small radius), Hunter (more
targets, faster lock, higher hit chance, faster flight), Hack carrier (Cyberware Malfunction or
weapon jam), Shaped charge (armor pen, against drones and mechs).

**Mechanics checked for this lineup**

- Pellet patterns: pellets follow the gun's `Spread*` stats, laid out by
  `SpreadUseEvenDistribution`, `SpreadEvenDistributionRowCount`, `SpreadEvenDistributionJitterSize`
  and `SpreadUseCircularSpread`; `ProjectilesPerShot` sets the count. Dragon's breath and Barn Door
  are stat changes. A muzzle cone of fire is not pursued.
- Damage roll: every player hit on an NPC is multiplied by `RandRangeF(0.90, 1.10)` in
  `DamageSystem.CalculateDamageVariants` (script). Probed on 2.50: 30 Lexington hits, ratios
  0.908 to 1.101, mean 0.999. The `EffectiveDamagePerHitMin/Max` stats (0.9x and 1.1x) are for the
  tooltip only and don't drive the roll. So Match grade needs a `@wrapMethod` on
  `CalculateDamageVariants` that narrows the roll for its guns (for example 1.00 to 1.10), plus
  the tooltip's min stat raised to match.
- Falloff: `EffectiveRange` (where damage starts dropping) and `DamageFalloffDisabled`.
- Tooltip damage range: `EffectiveDamagePerHitMin/Max` add up `BaseDamageMin/Max` and the
  per-type `PhysicalDamageMin/Max` (Thermal, Chemical, Electric likewise), each a
  `CombinedStatModifier` of its damage stat x0.9 / x1.1 on `Items.Base_Weapon` (`_inline106/107`)
  and `Items.Base_Weapon_Damage_Type_Min_Max`; melee has its own records.
- Stamina per shot: the bullet attack's `StaminaCost` modifiers multiply weapon stats, among them
  `WeaponEvolutionToStaminaCost` (1.0 on a Lexington), so a round raises the cost with a
  multiplier on it. `PowerMod2_StaminaCost` exists but nothing in 2.50 sets it.
- Smart reach: `MaximumRange` (100 on a Yukimura) is how far a smart rocket flies; at 0.3x a
  rocket stops reaching a target at 40 m but still hits at 20 m. Damage has no falloff out to
  40 m (same pre-roll damage at 5, 20 and 40 m). Lock range is `SmartGunTargetAcquisitionRange`
  (25).

**Damage roll for everyone (agreed direction)**

Vanilla rolls only V's hits on NPCs. The plan: wrap `CalculateDamageVariants` so every ranged gun
hit rolls by the same rule, whoever fires it, with the roll set by the loaded round (V: the feed
selector; NPC: the round it was stocked with). Melee keeps vanilla's player-only roll; grenades and
other explosions stay unrolled; projection hits stay skipped.

Per round, all optional, on the ammo record (the stat list is a fixed enum, so these are record
values and perks can't change them):

- `aoRollMin`, `aoRollMax`: uniform range. Default 0.90 and 1.01: mostly a downside, not
  vanilla's 0.90-1.10. Average damage drops to about x0.955 for everyone (V's Common rounds
  included, and NPCs, which never rolled before); agreed, difficulty covers it.
- `aoRollDudChance`, `aoRollDudMult`: a chance of a much weaker hit (bad primer, short charge).
- `aoRollHotChance`, `aoRollHotMult`: a chance of a much stronger hit (overcharged case).

Values are layered, each overriding the last: global default, family (Power, Tech, Smart), faction
(e.g. Maelstrom about -20% with duds), then the round itself. They are flats in `core.yaml`
(`AmmoOverhaul.roll.<family|faction>.<value>`); a round inherits through its tags, so most rounds
name none. Each layer can also set a range per damage type (`MultAttackValue(value, damageType)`
takes a type), e.g. a wild Thermal part on a steady Physical one.

Examples: Match grade 0.98-1.06, no dud or hot. A Maelstrom homemade load 0.85-1.15, 12% dud
x0.4, 8% hot x1.6. The tooltip's `EffectiveDamagePerHitMin/Max` follow through selector stat
modifiers. The hook looks up the loaded round per hit, so `CaliberForWeapon` gets cached with it.

## Open questions

1. Rarity budget units: how many perk points per tier, and how quirks offset them.
2. Crafting: answered 2026-10-29 (`docs/DESIGN.md`, Crafting). Every caliber's Common round is
   known; Uncommon and up are recipe items from loot and gun shops. Cost to make goes Tech < Power
   < Smart.

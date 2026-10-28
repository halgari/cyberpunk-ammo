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
| P-MAG | magnum revolver | Nova, Overture, Metel, Malorian 3516 |
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

### Built (v1 slice)

| Caliber | Common | Uncommon | Uncommon effect |
|---|---|---|---|
| P-9 | 9mm Ball (vanilla handgun ammo) | 9mm Mushrooms (hollow point) | damage ×1.2, armor pen −0.5 |
| T-LIGHT | 5mm Rail Slugs | 5mm Sleevers (sabot) | charge time ×0.7, damage ×0.95 |
| S-10 | 10mm Seekers | 10mm Dumbfires | damage ×1.25, no guidance |

All guns of these calibers that use handgun ammo have the feed slot; Hercules 3AX and Sidewinder
(rifle ammo) wait for the rifle calibers.

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
- **Overpressure:** a Power load that punches through cover like a charged Tech shot (whether
  `TechPierceEnabled` works on a Power gun is untested).
- **Capacitor slug (Tech):** stores rail energy and discharges on impact, only on charged shots
  (through the package's `chargeFire`).
- **Rail feedback slug (Tech):** corrects itself slightly against the rails (bullet magnetism).

## Open questions

1. Rarity budget units: how many perk points per tier, and how quirks offset them.
2. Where the nine new calibers come from: which vendors, loot tables and crafting recipes.

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
  after a blank line. Names chosen with the user: Gatecrasher, Cook-off, Kebab, Lockout,
  Heartseeker, Mule Kick.
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

**Gatecrasher** (12.7, 7.62; designed as Total Penetrator)
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

**Mule Kick** (4ga; replaces Bouncing Betty, see the probe results)
- An overloaded shell that throws both ends of the gun.
- Every hit knocks the target down (`BaseStatusEffect.Knockdown`) and the gun's knockback stats go
  to their cap of 100, so a kill throws the body. Elite, Boss and MaxTac NPCs stagger instead of
  falling (user ruling).
- V is shoved hard away from the shot, using the game's own push (`PSMImpulse`, as jump pads do):
  fired forward, V is thrown back; fired at the floor, V goes up; fired in the air, V gets a
  second jump or a dodge. Strength 14, played and approved by the user: push = -14 x the camera's
  forward. Only a real shot kicks, not a trigger pull on an empty gun.
- An NPC's hit on V knocks V down hard. An NPC firing it doesn't move.

## Probes (in the game, before the plan)

1. **Can a Power gun fire a projectile instead of an instant-hit shot?** A smart projectile for
   Heartseeker. For Bouncing Betty, first: can the mod spawn a real grenade (the frag's
   projectile) at the muzzle and throw it forward with the gun's aim, so it arcs, bounces and
   goes off on its fuse? Then a grenade-like projectile. The candidates are the
   weapon's projectile and smart stats, as the smart guns and the grenade launchers use them.
   - Fallback for Heartseeker: a single slug with strong bullet magnetism, much stronger than
     Feedback's +2 degrees.
   - Fallback for Bouncing Betty: probe 2's blast, set off at the point of impact.
2. **Can the mod set off a grenade-style blast at a point from script?** Cook-off's blast at a
   body and V's grenade cooking off on V depend on it. So does Bouncing Betty's fallback.
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
  - Mule Kick throws the target and V, and a floor shot lifts V;
  - Gatecrasher through cover at full damage.
- **The user's playtest of all six.**

## Out of scope

Faction rounds. Legendary rounds for the other mechanics. Crafting of Legendary rounds.

## Probe results (2026-10-30, played by the user)

**Probe 4, the jam on V: passes.** `StatusEffectHelper.ApplyStatusEffect(player,
"BaseStatusEffect.WeaponMalfunction")` jams V's drawn gun for its 14 s, then it clears. Lockout
applies it again on every hit.

**Probe 2, a blast from script: passes.**
- `RPGManager.PrepareGameEffectAttack(instigator, source, attackID, position)` then
  `:StartAttack()` sets off a blast at a point. From CET the call takes the instigator first (no
  game instance).
- `Attacks.Explosion` (the device and barrel blast) has `OverridePlayerDamageWithFixedPercentage`
  and `OverrideNPCDamageBasedOnTiers`: a fixed share of V's health, NPC damage by tier. It killed a
  test NPC from full and took a large chunk off V. Cook-off's damage uses it.
- A grenade's own attack (`Attacks.CommonFragGrenade`, from the grenade record's `attack` flat)
  set off from script does almost no damage: its damage comes from the thrown grenade item, and
  there is none. It still shows the grenade's blast and carries its effects (EMP and so on), so
  Cook-off on V sets off both: the grenade's attack for its look and effects, the device blast
  for the damage.
- **V's grenade:** the selected grenade is `EquipmentSystem.GetData(player):GetActiveGadget()`
  (the equip slots read empty). Charges are the `GrenadesCharges` stat pool: max = stat
  `GrenadesCharges` (70), charges = stat `GrenadesMaxCharges` (2), so one charge = max / charges
  (35). A thrown grenade takes one charge off. Cook-off checks pool >= one charge and takes it
  off with `RequestChangingStatPoolValue`; the pool recharges as normal.
- In play: Copperhead kills set off a blast at the body (Cook-off on NPCs); an NPC hit on V with a
  charge ready cooked off V's frag, hits with no charge did nothing until it refilled.
- Hooks used: CET `Observe("NPCPuppet", "OnHit"/"OnDeath")` and `Observe("PlayerPuppet",
  "OnHit")`, filtered to ranged attacks so blasts don't set off more blasts. The real build puts
  this in the mod's hit code.

**Probe 3, Tech pierce through bodies: passes.** A Nekomata (pierce on at 0.9 charge,
`TechPierceDamageFactor` raised from -0.5 to 0 with an additive modifier) fired one charged shot
through a Tyger Claw into a second one behind it: the near one went 100 -> 50.3%, the far one
100 -> 69.0%. Open: the far target took about 60% of the near one's damage, from hit location or a
body loss of its own. Kebab's live check measures it with matched hits; if the loss is real, the
hit code tops up the damage on the second and later targets.

**Probe 1, Heartseeker part: passes.** A Carnage clone (`TweakDB:CloneRecord` of
`Items.Preset_Carnage_Default`) fires a homing smart slug with no Smart Link cyberware:
- Record: `rangedAttacks` = `Attacks.SmartBulletHighPackage`, `evolution` Smart, tags `Smart` and
  `SmartWeapon` added, `crosshair` = `Crosshairs.SmartGun`. With the tags and the smart crosshair
  the gun locks and shows the lock markers; the shotgun reticle stays as well, which the user
  likes. Without the tags it fired straight (dumb-fire).
- Stats (copied from the Yukimura, then changed): all the `SmartGun*` lock stats, including the
  lock angles (9 degrees), which a copy without the tags read as 0; `SmartGunHitProbability` 1;
  `ProjectilesPerShot` 1 (the game moves the pellets' damage into the one slug: 10 x 11.9 became
  118.6); `SmartGunHip/AdsTimeToLock` 0.3; `SmartGunHipMaxLockedTargets` 1;
  `SmartGunPlayerProjectileVelocity` 35 (the clone had 0, which fired slow shells);
  `SmartGunAddSpiralTrajectory` 0; `SmartGunTrackHeadComponents` 3 with chest and legs 0, so it
  locks onto heads.
- V was also given `HasSmartLink` 1 by a stat modifier during the test. It's not yet known
  whether the lock needs it once the tags and lock angles are there; the build checks.
- Damage, open: the user saw about 40 per slug against Scav snipers from 118.6 on the gun.
  Suspects: armor, the Carnage's `HeadshotDamageMultiplier` 0.85, a smart-projectile damage
  change. Heartseeker gets full armor ignore (Legendary) and a raised headshot multiplier; the
  live check measures the damage on an unarmored test NPC.
- A script hook on `BaseProjectile` launch never fires for smart bullets (they are native), and
  `ProjectileLaunchHelper.SpawnProjectileFromScreenCenter` from a Carnage spawned nothing, so the
  homing has to come from the smart weapon setup above.

**Probe 1, Bouncing Betty part: works, and rejected by the user.** A real frag can be launched
from script (give the item, `AddItemToSlot` on `WeaponLeft`, wait for it to spawn, then
`gameprojectileSetUpAndLaunchEvent` with a parabolic trajectory; one ItemID can't be reused while
its grenade is in flight, so it needs a pool of records). The user: it reads as a thrown grenade,
not a shot. Tried next and also rejected: `Attacks.ChimeraPowerModExplosiveBulletPackage` on a
Carnage (nothing visible), and a raycast with a scripted blast at the crosshair ("contrived",
"chintzy"). The 4ga Legendary is now Mule Kick. Rule from this: Legendary effects use what the
engine does natively, not scripts faking a weapon.
- Found on the way: `WeaponObject.OverrideRangedAttackPackage` swaps the attack package on one
  gun. It may replace Heartseeker's shared-record switch; not tested.

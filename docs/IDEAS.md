# Ammo ideas (brainstorm)

Not a plan or a spec. Ideas for more rounds, generated on 2026-10-29 by four brainstorming
agents (one per family group). Each was asked for 5 more rounds per caliber (1 Uncommon, 2 Rare,
2 Epic) on top of the existing lineup, plus wildcards. They worked from the house rules in
`docs/CATALOG.md`, the weapon stats the game has, and the mod's on-hit effects.

Each round has a slang name, what it does, the levers it would use, and a feasibility tag:
- `stats`: stat changes only;
- `hit-code`: uses the mod's on-hit effects;
- `probe`: needs an in-game experiment first.

The numbers are rough, and the ideas haven't been checked against each other or against the
game. Some overlap with grid entries that aren't built yet. Pick, merge and rename freely.

The agents' favorites:
- **Power guns:** Twofers (9mm), Pinners (5.56), Moonclips (12mm), Gunsmashers (.45), Trophy
  Hunters (12.7).
- **Shotguns:** Wall-hangers (12ga), Landslide (4ga), Cluster-12 (12ga), Wallbanger (4ga),
  Door-knockers (12ga).
- **Tech:** Overvolts (5mm), Hair-trigger (5mm), Railbreaker (heavy), Thunderclap (heavy),
  Cold-iron (heavy).
- **Smart:** Tagalongs (10mm), Roof-knockers (20mm), Swarm (10mm), Spotters (25mm),
  Corner-turners (10mm).

# Power: handgun and rifle calibers


Format per round: Name. Concept. What it does. Levers. Feasibility. NPC side (only if not obvious).
No explosives, no shock or EMP. Armor pen only at Rare (small) and Epic (large), and none here beyond what the grid already has.

## 9mm (pistols and SMGs: Lexington, Unity...)

Already there: Mushrooms, Hot loads, Steel-core AP, Incendiary (weak), Subsonic, Bouncers, Rubber, Penetrator, Match, Toxin core, Shredders.

Uncommon
- **Wadcutters.** Flat-nosed target loads that punch a clean round hole.
  Better headshot damage and crit damage; shorter effective range and a little less body damage.
  Levers: HeadshotDamageMultiplier, CritDamage up; EffectiveRange, DamagePerHit down. Tag: `stats`.

Rare
- **Stoppers.** Heavy-for-caliber flat loads meant to make a guy stop what he's doing.
  Good chance to stagger on hit; less damage per hit. Control mechanic for pistol-and-SMG crowds.
  Levers: HitReactionStagger chance, DamagePerHit down. Tag: `hit-code`.
  NPC side: a hit on V can flinch her aim, so Stopper SMG gangs are about suppression, not damage.
- **Hosers.** Light loads for people who like full auto.
  Faster cycle time and less recoil per shot; lower damage and wider spread at range.
  Levers: CycleTime down, RecoilKickMin/Max down, DamagePerHit down, SpreadDefault up. Tag: `stats`.

Epic
- **Twofers.** Two bullets stacked in one case, one trigger pull.
  Two projectiles per shot at a bit over half damage each, so a clean hit does more than one round; spread is a bit wider. Straight upgrade; cost is price and recoil.
  Levers: ProjectilesPerShot to 2, DamagePerHit down, small spread penalty. Tag: `stats` (the ammo count is one per shot, so check how the mag counts it).
- **Church Mice.** Quiet in the extreme. The far end of the stealth dimension: subsonic's silent kills with no range loss and no damage loss.
  Levers: CanSilentKill, WeaponNoise to minimum, EffectiveRange kept. Tag: `stats`.
  NPC side: guards firing these don't call out the gunfire; V gets no sound cue on who shot.

Wildcards
- **Pepper-pops.** Capsule rounds that leave a burning-eyes cloud on hit.
  Blind chance and a flinch, low damage. Tag: `hit-code`. Fits a pistol you carry for crowd control without killing.
- **Doorknockers.** Dense rounds with a lot of push for a 9mm.
  Higher knockdown impulse on hit; much lower damage. Tag: `stats`. Overlaps a bit with Stoppers, so use only one.
- **Cheapies.** Bulk steel-case ammo, lower reload time and magazine feel, more malfunctions.
  Small WeaponMalfunction chance on the shooter. Tag: `hit-code`. Funny, probably a vendor-only cheap Uncommon.

## .45 (heavy pistols and SMGs)

Already there: Mushrooms, Hot loads, Steel-core AP, Incendiary, Subsonic, Bouncers, Rubber, Penetrator, Match, Toxin core, Shredders.

Uncommon
- **Heavies.** 230 grain bullets, slow and fat.
  More damage and knockdown impulse; slower cycle time and a lower effective range.
  Levers: DamagePerHit up, BaseKnockdownImpulse up, CycleTime up, EffectiveRange down. Tag: `stats`.

Rare
- **Gunsmashers.** Hard-nosed flat loads aimed at the gun hand.
  Chance to jam the target's weapon on hit (WeaponMalfunction). Less damage on every hit.
  Levers: WeaponMalfunction chance, DamagePerHit down. Tag: `hit-code`.
  NPC side: fired at V, can jam her gun. The cost of getting hit by a gang with these is real, so keep the chance low.
- **Pancakes.** Wide, soft slugs that spread flat against whatever they hit.
  Light Bleeding chance and more damage against unarmored targets; they lose a little range. Not a Shredder: the wound is big but not deep.
  Levers: BleedingApplicationRate, DurationBonusBleeding, EffectiveRange down. Tag: `hit-code`.

Epic
- **Wall-bangers.** Big loads that knock people over.
  Far end of the knockdown dimension: knockdown on most hits, a lower dismemberment threshold. Price and recoil are the cost.
  Levers: KnockdownImpulse up, KnockdownDamageThreshold down, dismemberment threshold down. Tag: `stats`.
- **Brawlers.** Built for hip fire and rooms.
  Hip spread almost nothing, strong aim assist, quick handling, ADS unchanged. The straight upgrade for a gunfighter who never aims.
  Levers: SpreadDefault hip down, BulletMagnetismDefaultAngle up, Handling and AimInTime better. Tag: `stats`.

Wildcards
- **Slow Walkers.** Heavy subsonic .45: quiet, silent kills, no range penalty but a big bullet drop. A cousin to Church Mice for those who want weight over speed. Tag: `stats`.
- **Sidewalk Specials.** Cheap city loads with a high crit chance and a high dud chance. Uses the damage-roll band. Tag: `hit-code`.
- **Stunners.** Blunt loads, Stun chance on a headshot only. Tag: `hit-code`.

## 12mm (revolvers and heavy pistols: Nova, Overture, Metel)

Already there: Mushrooms, Hot loads, Steel-core AP, Incendiary, Rubber, Hardcast, Penetrator, Match, Toxin core, Shredders.

Uncommon
- **Cowboy loads.** Light, mild-recoil loads from the old west.
  Lower recoil, faster follow-up, better handling; less damage and range.
  Levers: RecoilKick down, CycleTime down, DamagePerHit down, EffectiveRange down. Tag: `stats`.

Rare
- **Snakeshot.** Little pellets in a revolver cartridge, the thing you load for snakes and rats.
  Several tiny pellets per shot, very short range. Pistol-sized shotgun for rooms. Weak against armor.
  Levers: ProjectilesPerShot up, DamagePerHit down, SpreadDefault up, EffectiveRange down. Tag: `stats`.
- **Bear loads.** Long hard bullets for big game.
  Bonus damage against Elites, Rares and Bosses; a bit less against ordinary grunts.
  Levers: BonusDamageAgainstElites/Rares/Bosses up, DamagePerHit down. Tag: `stats`.
  NPC side: boss-tier NPCs carrying them are more of a threat to V, but V is not an Elite so the bonus does not fire; mention in description that it's for V's targets.

Epic
- **Hand Cannons.** The big one. Biggest damage per hit of any handgun round, good crit damage.
  The cost is price and heavy recoil. Straight upgrade on Hot loads.
  Levers: DamagePerHit up, CritDamage up, RecoilKick up modestly. Tag: `stats`.
- **Moonclips.** Fast-reload loading.
  Reload and empty reload time cut hard, which suits a six-shooter that has a long reload. The far end of the reload dimension.
  Levers: ReloadTime down, EmptyReloadTime down. Tag: `stats`.

Wildcards
- **Last Call.** The last round in the cylinder hits hard: triple damage. Hit code needs the ammo count; may need a probe. Tag: `probe`.
- **Black Powder.** Old smoky loads. Big muzzle flash and smoke; lower velocity. Small Burning chance, short range, big knock. Tag: `hit-code`.
- **Dead Man's Hand.** Crit chance high, damage roll band wide (many duds and many hots). Gambler round. Tag: `hit-code`.

## 5.56 (assault rifles and SMGs)

Already there: Mushrooms, Hot loads, Steel-core AP, Incendiary, Subsonic, Bouncers, Penetrator (no cover pierce), Match, Toxin core, Shredders.

Uncommon
- **Lighties.** Light varmint-weight loads.
  Less recoil and tighter spread; less damage. A comfort sidegrade for hip-fire rifles.
  Levers: RecoilKick down, SpreadDefault down, DamagePerHit down. Tag: `stats`.

Rare
- **Tumblers.** Pointed bullets that yaw in tissue.
  Bleeding chance on hit. Less armor effect: no pen change, but bleed does not apply to armored bodies (keeps it a soft-target round). Lighter than Shredders.
  Levers: BleedingApplicationRate, DurationBonusBleeding, DamagePerHit slightly down. Tag: `hit-code`.
- **Zippers.** Very fast, very light bullets.
  Flatter flight (high velocity bullet magnetism, long range), much less damage; works for fast long suppressive fire.
  Levers: BulletMagnetismHighVelocityAngle up, EffectiveRange up, DamagePerHit down. Tag: `stats`.

Epic
- **Pinners.** Cracking supersonic rounds that make a body duck.
  A high Stagger chance on hit, higher than Stoppers, plus a little more damage. The far end of control: a squad under this fire can barely return fire.
  Levers: HitReactionStagger chance up, HitTimerAfterStagger up, DamagePerHit up slightly. Tag: `hit-code`.
  NPC side: V gets staggered a lot. Keep the stagger timer short or this is miserable.
- **Pillows.** Near-zero recoil loads (soft, light powder charge with a long-burn flake).
  Recoil almost gone, cycle time a bit faster, spread tight in a burst; damage unchanged. Price is the cost.
  Levers: RecoilKickMin/Max very low, RecoilAngle small, CycleTime down. Tag: `stats`.

Wildcards
- **Frangibles.** Powder-metal bullets that shatter on contact with anything. No ricochet, no cover contact; bonus damage to unarmored targets and drones, none against armor. Tag: `stats`.
- **Paintballs.** Dye loads: mark the target (Ping-lite for 2 seconds, no wall view). Tag: `hit-code`.
- **Greenhorns.** Training loads: tiny damage, huge stamina savings, bad range. Fun for a build that fires a lot. Tag: `stats`.

## 7.62 (Ajax, Kyubi, MA70 HB)

Already there: Mushrooms, Hot loads, Steel-core AP, Incendiary, Tracer, Ballistic tip, Ping, Penetrator, Match, Toxin core, Shredders, Gatecrasher, Cook-off.

Uncommon
- **Snap loads.** Light, quick-handling loads.
  Quicker aim-in and better handling; less damage.
  Levers: AimInTime down, Handling up, DamagePerHit down. Tag: `stats`.

Rare
- **Drone-poppers.** Hardened steel plug in a soft jacket, good against metal skin.
  Bonus damage against drones, mechs and vehicles; less against flesh.
  Levers: BonusDamageAgainstMechanicals up, DamagePerHit down. Tag: `hit-code` (or `stats` if the stat does the job).
  NPC side: an NPC rifle with these chews through V's allied drones and any vehicle V is hiding behind.
- **Skull-poppers.** Match-weight loads for people who aim high.
  Headshot damage and crit chance go up, body damage goes down. A DMR habit.
  Levers: HeadshotDamageMultiplier up, HeadshotCritChance up, DamagePerHit down. Tag: `stats`.

Epic
- **Rug-pullers.** Heavy 7.62 with a nasty shove.
  Knockdown on most hits, more stagger, longer stun time on the ground. The far end of control for a rifle.
  Levers: KnockdownImpulse up, KnockdownDamageThreshold down, HitTimerAfterKnockdown up. Tag: `stats`.
- **Lawnmowers.** Belt-friendly loads for the Ajax and its relatives.
  Cycle time fast, recoil tamed by a lighter bolt push, long bursts stay on target. A straight rate-of-fire upgrade.
  Levers: CycleTime down, RecoilKick down, spread bloom per shot down. Tag: `stats`.

Wildcards
- **Boat-tails.** Pointed, tapered rifle bullets. Range up, falloff gentler than Ballistic tip but with no pen change. Overlaps a bit. Tag: `stats`.
- **Rattlers.** Loud, bright loads: hit makes target flinch and lights them for a second. Low damage. Tag: `hit-code`.
- **Hangmen.** Crit chance high on a staggered target (staggered target takes extra crit). Needs a stagger source on the same gun, so maybe a pair with Pinners. Tag: `hit-code`.

## 12.7 (precision and sniper rifles: Grad, SOR-22)

Already there: Mushrooms, Hot loads, Steel-core AP, Incendiary, Tracer, Ballistic tip, Ping, Penetrator, HEI, Match, Toxin core, Gatecrasher, Cook-off.

Uncommon
- **Sandbags.** Steady, heavy loads for a prone-minded shooter.
  Sway and recoil down; slower aim-in and handling.
  Levers: Sway down, RecoilKick down, AimInTime up, Handling down. Tag: `stats`.

Rare
- **Door-openers.** Big shoves.
  A decent chance to knock the target down on hit; heavy recoil.
  Levers: KnockdownImpulse up, BaseKnockdownImpulse up, RecoilKick up. Tag: `stats`.
  NPC side: a sniper using these can pin V out of her scope.
- **Whisperers.** Subsonic 12.7: quiet, silent kills, less range, a bit less damage.
  Levers: CanSilentKill, WeaponNoise down, EffectiveRange down, DamagePerHit down. Tag: `stats`.

Epic
- **Trophy Hunters.** Premium hunting loads for taking down the top of the food chain.
  Large bonus damage against Elites, Rares and Bosses plus extra crit damage. Straight upgrade for V's boss fights.
  Levers: BonusDamageAgainstElites/Rares/Bosses up, CritDamage up. Tag: `stats`.
- **Long Walkers.** The far end of reach.
  Effective range very long, strong bullet magnetism at high velocity, near-flat flight. No no-falloff (that's Legendary); it just takes much longer to fall off.
  Levers: EffectiveRange up, BulletMagnetismHighVelocityAngle up. Tag: `stats`.

Wildcards
- **Skippers.** Heavy bullets that skip off the ground and ricochet at a shallow angle, so you can hit behind low cover. Tag: `stats` (Ricochet levers).
- **Spotters.** Tracer plus a damage-taken mark: marked target takes extra damage from the next hit for a few seconds. Tag: `probe` (needs a debuff).
- **Sleepers.** Non-lethal heavy rounds: kill becomes knockout, long-range dart. A sniper's mercy shot. Tag: `hit-code`.

## Family themes (Power)

Directions the current lineup doesn't use yet:
- **Fire rate and handling as a perk:** Hosers, Lawnmowers, Pillows, Brawlers, Moonclips. Rounds that change how the gun feels, not just damage.
- **Control through stagger and knockdown:** Stoppers, Pinners, Rug-pullers, Wall-bangers, Door-openers. Stagger is a good mid-tier mechanic since it works on both sides.
- **Crit and headshot dimension:** Wadcutters, Skull-poppers, Dead Man's Hand. Gives the stat-heavy builds something.
- **Boss and big-target hunting:** Bear loads, Trophy Hunters. Fits revolvers and anti-materiel rifles.
- **Gun-disabling and utility:** Gunsmashers (weapon malfunction), Pepper-pops (blind), Paintballs (marks).
- **Stealth extremes:** Church Mice and Whisperers keep stealth builds from being stuck with Subsonic only.
- **Shaped pellets in a handgun:** Snakeshot (pellet pattern in a pistol) and Twofers (two projectiles per shot).
- **Spanning calibers:** Stoppers/Pinners (stagger), Whisperers/Church Mice (silence), Hosers/Lawnmowers (rate), Trophy Hunters/Bear loads (big game).

## Best 5 overall

1. **Twofers (9mm).** Instantly readable, uses the pellets lever in a way no one expects from a pistol, and feels like a "gun-guy" joke.
2. **Pinners (5.56).** Mid-fight control on both sides makes AR duels about positioning, not just damage. Watch the stagger timer on the V side.
3. **Moonclips (12mm).** Fixes the revolver's biggest pain with a pure stat change; trivially safe to build.
4. **Gunsmashers (.45).** Weapon-malfunction on hit is a rare mechanic that makes a gunfight feel different and the name does the work.
5. **Trophy Hunters (12.7).** Gives snipers a boss-fight round without touching armor pen; pure stats.

# Power: shotguns


Existing: 12ga has Slugs, Birdshot (Unc), Flechette, Beanbag, Dragon's breath (light), Gas (Rare), Dragon's breath, Frag-12, Tungsten slug, long Flechette (Epic), Pump N Dump (Leg). 4ga has Slugs, Barn Door (Unc), Flare, Riot, Gas canister, Flechette (Rare), Kinetic penetrator, Micro-grenade, Dragon's breath, Thermite slug (Epic), Bouncing Betty (Leg).

The grid already fills most slots, so below I propose NEW rounds that sit beside it. Where one is meant to replace a grid entry, I say so.

Split between the two guns: the 12ga is the fast, handy, tactical shotgun, so its rounds are about the pellet pattern, control and tricks. The 4ga is the siege gun: huge, slow, loud, and its shells are big enough to carry real payloads, so its rounds are about area, structure and brute force.

## 12-gauge

### Uncommon
- **Name: Reds** (cheap field loads)
  - Concept: bargain buckshot with a loose crimp, the shell everybody has in a drawer.
  - What it does: faster cycle and quicker reload. Drawback: a wider, uneven spread and a bit less damage per pellet.
  - Levers: CycleTime, ReloadTime, SpreadDefault up, DamagePerHit down.
  - Tag: `stats`
  - NPC side: gangers pump out shots faster but scatter more, so they miss at range.

### Rare
- **Name: Stingers** (rubber-ball buckshot, hard version)
  - Concept: hard rubber pellets that bounce off walls and floors.
  - What it does: ricochet chance and count on every pellet, so corners and floors work. Drawback: lower damage, no armor pen, shorter range.
  - Levers: RicochetChance, RicochetCount, BonusRicochetDamage, DamagePerHit down, EffectiveRange down.
  - Tag: `stats`
  - NPC side: hiding behind a thin corner is less safe than usual.
- **Name: Door-knockers** (breaching round)
  - Concept: a frangible powdered-metal slug that turns to dust on impact.
  - What it does: huge stagger and knockdown impulse at close range, extra damage against mechanicals and drones (they are built from thin plates), no overpenetration. Drawback: falls off hard past a few meters.
  - Levers: KnockdownImpulse, BaseKnockdownImpulse, BonusDamageAgainstMechanicals, EffectiveRange down, ProjectilesPerShot to 1.
  - Tag: `stats`
  - NPC side: gets V staggered off their aim at close range.
- **Name: Hornets** (stinging shot)
  - Concept: tiny barbed pellets that leave wounds that keep bleeding.
  - What it does: Bleeding chance on each pellet, longer bleed. Drawback: less damage up front and almost no armor pen, so it is poor against heavies.
  - Levers: BleedingApplicationRate, DurationBonusBleeding, DamagePerHit down.
  - Tag: `stats` (or `hit-code` if the rate stat does not apply per pellet)
  - NPC side: V picks up bleeds from enemy pellets; a medkit habit matters.
- **Name: Smokers** (pyro marker shot)
  - Concept: a slow-burning flare wad in the shell that lights the target's outline.
  - What it does: tags the target through walls for a few seconds (Ping style) and gives a small Burning chance. Drawback: loud, and pellets are fewer.
  - Levers: KyubiMyersTag, BurningApplicationRate, WeaponNoise up, ProjectilesPerShot down.
  - Tag: `hit-code`
  - NPC side: V gets tagged for squad focus fire; use cover fast.

### Epic
- **Name: Choke-bore Match** ("Trap loads")
  - Concept: hand-built target loads, perfectly round shot in a buffered wad.
  - What it does: a very tight, even pattern with a narrow damage roll, long effective range, steady headshot damage. Straight upgrade for precision work. Price is the cost.
  - Levers: SpreadDefault/Max down, EffectiveRange up, damage-roll band narrow and high, HeadshotDamageMultiplier up.
  - Tag: `hit-code` (the band) plus `stats`
  - NPC side: elites shred from further out than V expects.
- **Name: Wall-hangers** (double-ought brutality)
  - Concept: oversize 000 buck with a heavy powder charge.
  - What it does: far fewer but much heavier pellets, big knockdown, and a dismemberment threshold drop so limbs come off. Armor pen about 50%.
  - Levers: ProjectilesPerShot down, DamagePerHit up, KnockdownImpulse up, dismemberment thresholds, ArmorPenetrationBonus.
  - Tag: `stats`
  - NPC side: terrifying for V at close range; a pure damage threat.
- **Name: Sandblasters** (jacketed pellets that fragment)
  - Concept: pellets that break apart in flesh, a cloud of small fragments.
  - What it does: strong bleeding plus a high damage multiplier against unarmoured targets only. Armor pen none; deliberately the soft-target extreme.
  - Levers: BleedingApplicationRate, DamagePerHit up, ArmorPenetrationBonus negative.
  - Tag: `stats`
  - NPC side: devastating on V in light clothing; armored V is rewarded.

### Wildcards (4)
- **Name: Whisper-12** (subsonic buck)
  - Concept: low-pressure loads with a heavy wad, near silent for a shotgun.
  - What it does: quiet, silent kills allowed, much less range and fewer pellets.
  - Levers: WeaponNoise down, CanSilentKill, EffectiveRange down. Tag: `stats`. NPC side: V never hears the shot.
- **Name: Bangers** (flash-bang wad)
  - Concept: a noisy, bright charge loaded over a light shot.
  - What it does: Stagger and a Blind chance in a cone at close range; low damage. Note: no EMP or shock, just light and noise.
  - Levers: HitReactionStagger, Blind chance, DamagePerHit down. Tag: `hit-code`. NPC side: V gets blinded at point blank; keeps distance relevant.
- **Name: Tow-hooks** (grapple slug)
  - Concept: a slug with a barbed head tied to a short line.
  - What it does: yanks a target a short way toward V on hit. Fun with melee builds.
  - Levers: pinning/ragdoll impulse toward shooter. Tag: `probe`. NPC side: pulls V into the enemy's melee range.
- **Name: Cluster-12** (airburst slug)
  - Concept: a timed slug that breaks into pellets at distance.
  - What it does: a single accurate projectile that bursts into a pattern in the target's area at long range, so it is a "reverse" shotgun (tight near, wide far).
  - Levers: change what the gun fires or spawn pellets at hit point. Tag: `probe`. NPC side: long range lanes get dangerous.

## 4-gauge

Distinct role: area, structure damage and big payloads. A 26mm shell has room, so these may use radius, lingering effects and cover destruction.

### Uncommon
- **Name: Cannon wads** (heavy wad slug)
  - Concept: a plastic-sabot slug with a big wad.
  - What it does: more knockback and a larger damage per hit, but a very slow reload.
  - Levers: BaseKnockdownImpulse up, ReloadTime up, EmptyReloadTime up. Tag: `stats`. NPC side: slow reloads give V a window.

### Rare
- **Name: Chalk** (marker/dust shell)
  - Concept: a burst of fine coloured powder that clings to anything it hits.
  - What it does: tags and highlights targets in a cone for several seconds, lowering their dodge and stealth; low damage. Drawback: no armor pen, small damage.
  - Levers: KyubiMyersTag multi-target in cone, DamagePerHit down. Tag: `hit-code`. NPC side: V is tagged in a cone for the squad.
- **Name: Sawdust** (rock-salt flesh shell)
  - Concept: coarse rock salt, a nasty, painful, mostly non-lethal load.
  - What it does: non-lethal, strong flinch/stagger, and a small chance to knock down; stops enemies without killing. Drawback: no cover or armor effect.
  - Levers: Nonlethal, HitReactionStagger, Knockdown. Tag: `hit-code`. NPC side: cops use it; V gets pushed, not killed.
- **Name: Cutters** (chain/bar shot)
  - Concept: two lumps joined by a short chain that spin through the air.
  - What it does: huge dismemberment chance at short range and heavy bleeding; wildly inaccurate. Drawback: huge spread, short range.
  - Levers: dismemberment thresholds, BleedingApplicationRate, SpreadDefault up, EffectiveRange down. Tag: `stats`. NPC side: shorten the fight distance and V dies.
- **Name: Sticky foam** (breach foam shell)
  - Concept: expanding gel that glues feet to the ground.
  - What it does: slows and briefly pins enemies in a small area; low damage. Drawback: needs a hit on the ground or a target.
  - Levers: spawn a lingering slow/pin patch. Tag: `probe`. NPC side: V is slowed in a small patch.

### Epic
- **Name: Wrecking balls** (armor-shredder lump)
  - Concept: a solid cast lump slug, a straight brick of metal.
  - What it does: far end of damage per hit at close to mid range, armor pen about 60%, huge impact on shields and mechs. Straight upgrade over Slugs. Deliberate overlap with Kinetic penetrator is avoided since this has no cover pierce.
  - Levers: DamagePerHit up, ArmorPenetrationBonus, BonusDamageAgainstMechanicals. Tag: `stats`. NPC side: unavoidable in a ranged duel.
- **Name: Landslide** (shockwave shell)
  - Concept: a heavy powder charge with a concussion wad, no shrapnel.
  - What it does: a short cone/area impulse that knocks over everything near the impact; lightweight damage but huge control. Straight upgrade for crowd control.
  - Levers: spawn a blast with knockdown impulse and no damage. Tag: `probe`. NPC side: sweeps V off their feet.
- **Name: Napalm bomb** (liquid-fire pot)
  - Concept: a jar of gelled fuel in a frangible shell. Overlaps Thermite slug and Dragon's breath; use only if one of those is cut.
  - What it does: lingering fire patch on the ground that burns anyone crossing it.
  - Levers: spawn burning area. Tag: `probe`.

### Wildcards (4)
- **Name: Wallbanger** (cover-breaker)
  - Concept: a shell with a hardened nose that blasts hunks out of cover.
  - What it does: damages and destroys destructible cover, plus a blast of splinters behind it. Also a hit-the-wall version of a grenade.
  - Levers: spawn small blast at impact, cover damage. Tag: `probe`. NPC side: cover stops being safe against heavy enemies.
- **Name: Flare-up** (illumination shell)
  - Concept: a magnesium parachute flare lighting the area.
  - What it does: lights the area and leaves a drifting light that outlines all enemies nearby in the dark for 10 s; no damage. Tactical support.
  - Levers: spawn light source, KyubiMyersTag area. Tag: `probe`.
- **Name: Pepper pot** (CS cloud shell)
  - Concept: a canister that rolls out an irritant cloud.
  - What it does: Blind and cough-stagger in a lingering cloud, non-lethal. Overlaps Gas canister; swap in if gas becomes a poison cloud instead.
  - Levers: spawn gas cloud, Blind/Stagger. Tag: `probe`.
- **Name: Stakes** (spike slug)
  - Concept: a long steel spike with fins.
  - What it does: pins an enemy to a wall or the ground, holding them in place for a few seconds and bleeding.
  - Levers: pinning/ragdoll trick, Bleeding. Tag: `probe`. NPC side: pins V briefly; scary but easy to read.

## Family themes (Power shotguns)

Directions the current lineup does not use:
- Pattern manipulation: choke, tight-then-wide, airburst, one-slug-or-many.
- Crowd control: stagger, flash, foam, shockwave, tow.
- Marking and light: chalk, flare-up, smokers, for team and stealth play.
- Cover destruction and breaching on 4ga: it is the only Power caliber with room for it.
- Handling tradeoffs: faster pump or slower reload instead of just damage.

## Best 5 overall
1. **Wall-hangers** (12ga Epic): the simple, loud fantasy of heavy buckshot and dismemberment.
2. **Landslide** (4ga Epic): pure crowd control, nothing else in the mod does it.
3. **Cluster-12** (12ga wildcard): flips the shotgun's range curve; distinctive and memorable.
4. **Wallbanger** (4ga wildcard): gives the 4ga a unique job (breaking cover).
5. **Door-knockers** (12ga Rare): a crisp, easy-to-implement close-range knockdown specialist that also hits machines.

# Tech: rail

## 5mm rail (Omaha, Kenshin, Ticon, Grit, Senkoh LX, Quasar)

Already there: Sleevers, Dense slugs, Capacitor, Ferro, Split slug, Feedback, DU penetrator, Toxic scatter, Superconductor, EMP capacitor.

### Uncommon
- **Quickdraw** (light, hollow-core slugs for rail pistols)
  - Concept: a hollowed slug that weighs next to nothing, so the coil spins it up fast.
  - Does: much shorter charge time. Perk is speed, quirk is less damage per shot and a shorter effective range.
  - Levers: ChargeTime / BaseChargeTime down, DamagePerHit down, EffectiveRange down.
  - Feasibility: `stats`.
  - NPC side: the gunner's telegraph (the charge whine) is shorter, so you get less warning.

### Rare
- **Hair-trigger** (pre-magnetized slug that holds a partial charge)
  - Concept: slugs with a residual field so the coil already has a head start.
  - Does: partial charge is enough to count as a charged shot, so the cover pierce triggers earlier. Drawback: lower pierce damage and a little more spread.
  - Levers: TechPierceChargeLevel down, TechPierceDamageFactor down, small Spread up.
  - Feasibility: `stats`.
  - NPC side: NPCs punch through cover with barely a wind-up. Dangerous in firefights behind low walls.
- **Arc rounds** (slug plated with a conductive jacket)
  - Concept: the slug dumps the coil's leftover current into the target as an arc.
  - Does: a share of damage becomes Electrical and a chance of Electrocuted. Differs from Capacitor by landing on every shot, charged or not, at a lower strength. Drawback: slightly longer charge.
  - Levers: damage-type share to Electrical, ElectrocutedApplicationRate, ChargeTime up.
  - Feasibility: `hit-code`.
  - NPC side: V gets electrocuted, which interacts with cyberware-based loadouts.

### Epic
- **Overvolts** (slugs tolerant of an overdriven coil)
  - Concept: a tough slug that survives being fired with the capacitor bank pushed past its rating.
  - Does: a longer hold at full charge (ChargeMaxTimeInChargedState up), plus a big bonus damage on a fully charged shot with no penalty for waiting. Price and scarcity are the cost.
  - Levers: ChargeFullMultiplier up, BonusChargeDamage up, ChargeMaxTimeInChargedState up.
  - Feasibility: `stats`.
  - NPC side: an NPC that holds a full charge keeps it for longer, a sniper-lite threat from pistols.
- **Blackout** (slug with a burst-fuse bead in the nose)
  - Concept: the nose bead flashes a short pulse on contact, enough to knock a man's implants offline for a second.
  - Does: chance of CyberwareMalfunction and Stun on a charged shot. Small EMP-flavored effect without the full EMP capacitor's machine focus. Targets humans with cyberware, so it complements EMP capacitor.
  - Levers: CyberwareMalfunction chance (charged only), Stun chance, a small Electrical share.
  - Feasibility: `hit-code`.
  - NPC side: V's cyberware flickers; quickhacks and sandevistan interrupted.

### Wildcards
- **Pinwheel** (Rare): two tiny slugs in one sabot, fired at slightly different angles. Does: `ProjectilesPerShot` 2 with a tight spread, so a forgiving shot at mid range; drawback is less damage each. `stats`.
- **Tungsten flea** (Epic): the lightest, hardest slug possible, with a very fast, nearly instant charge. A pistol that fires like a semi-auto. Does: very short ChargeTime, some armor pen, low damage. `stats`.
- **Static** (Uncommon): rough-cast slugs that foul the coil. Does: bigger Stagger on hit, but a small chance of WeaponMalfunction on the shooter. `hit-code`.

## Heavy rail (Burya, Achilles, Nekomata, Rasetsu, Satara)

Already there: Sleevers, Dense slugs, Capacitor, Ferro, Split slug, Feedback, DU penetrator, Toxic scatter, Superconductor, EMP capacitor.

### Uncommon
- **Long darts** (needle-shaped sleeve slug)
  - Concept: a long, thin slug with a fin tail, like a sabot dart.
  - Does: longer effective range and a tighter spread. Quirk is a slower charge and a little less damage up close.
  - Levers: EffectiveRange up, Spread down, ChargeTime up, DamagePerHit slightly down.
  - Feasibility: `stats`.
  - NPC side: rail snipers reach out further but telegraph longer.

### Rare
- **Cold-iron** (slugs of dead-soft iron that magnetize on the way out)
  - Concept: the slug is magnetized by the coil and tends to pull toward metal.
  - Does: a bonus against Mechanicals (drones, mechs, turrets) and a higher bullet magnetism angle. Drawback: reduced damage against organics.
  - Levers: BonusDamageAgainstMechanicals, BulletMagnetismDefaultAngle up, DamagePerHit down.
  - Feasibility: `stats`.
  - NPC side: NPC rail snipers aim better at V's vehicle and mechs; lighter on organics.
- **Hotshot** (a fast, thin-jacketed slug that glows on exit)
  - Concept: a slug driven fast enough that air friction cooks it, so it sets things on fire.
  - Does: Burning chance and a Thermal share on charged shots; drawback: no cover pierce bonus at the usual charge level (TechPierceChargeLevel up).
  - Levers: Burning chance, Thermal share, TechPierceChargeLevel up.
  - Feasibility: `hit-code`.
  - NPC side: V catches fire from rail snipers, which makes it a counter-snipe nuisance.

### Epic
- **Railbreaker** (heavy penetrator slug with an extra-long pierce)
  - Concept: a dense long-rod penetrator that keeps going through anything.
  - Does: armor pen about 50-70% plus cover pierce, and the pierce damage factor is high so the slug does almost full damage on the far side. Differs from DU penetrator by its extra pierce depth rather than a lower threshold.
  - Levers: ArmorPenetrationBonus, TechPierceDamageFactor up, TechPierceEnabled.
  - Feasibility: `stats`.
  - NPC side: cover stops protecting V; NPCs with heavy rails become genuine threats behind walls.
- **Thunderclap** (a slug with a stored charge that dumps on impact)
  - Concept: a big capacitor slug that discharges as a burst, with a shock that jolts and knocks the target around.
  - Does: charged shot has a high chance of Knockdown and Stagger, plus Electrocuted. A crowd-control epic for snipers.
  - Levers: Knockdown / Stagger chance, BaseKnockdownImpulse up, ElectrocutedApplicationRate.
  - Feasibility: `hit-code`.
  - NPC side: V is thrown to the ground; very lethal in an ambush.

### Wildcards
- **Coilbusters** (Epic): the slug dumps energy into a machine's power cell. Does: huge damage against drones, mechs and turrets, with a chance of EMP on them, but nothing against humans. `hit-code`.
- **Slow burn** (Rare): a very slow, very strong charge. Does: a long charge time with a big full-charge damage multiplier, no cover pierce change. A one-shot hunter's slug. `stats`.
- **Harmonic** (Rare): a slug tuned to the coil's frequency so it recharges the weapon. Does: faster charge from the second shot on and lower recoil; drawback is lower damage. `stats`.

## Family themes (Tech)

The current lineup covers density, pierce, shock, ricochet and magnet. These are untried:
- The charge itself as a resource: shorter charge, a held charge, and what an overcharged shot does (ChargeMaxTimeInChargedState, ChargeFullMultiplier, BonusChargeDamage).
- A partial charge that counts: lowering TechPierceChargeLevel for early pierce, with a damage trade.
- Machine-focused rounds: magnet-pull toward metal, bonuses against power cells.
- Cyberware disruption on humans (CyberwareMalfunction) distinct from the EMP capacitor's machine focus.
- Knockdown and crowd control through electric discharge.
- Tech NPCs telegraph by their charge whine, so a faster or slower charge changes how readable they are for V; a good lever to balance both sides.

## Best 5 overall

1. **Overvolts** (5mm Epic): rewards holding a charge, the cleanest expression of the charge mechanic.
2. **Hair-trigger** (5mm Rare): a clear change to how cover pierce feels, using only stats.
3. **Railbreaker** (heavy Epic): the clear sniper's penetrator, with a distinct identity from DU penetrator.
4. **Thunderclap** (heavy Epic): gives snipers a control mechanic instead of just damage.
5. **Cold-iron** (heavy Rare): magnetics as a perk, and gives machine-hunters a specialist round.

# Smart


Already in the grid (not repeated below): Dumbfires, Short-fuse (Uncommon); EMP, Incendiary, Chem, Flash payloads (Rare); Hunter, Hack carrier, Shaped charge, Splitter (10mm Epic); HE (20mm, 25mm Epic); Lockout and Gatecrasher-class Legendaries. Everything here is new on top of that.

Useful smart levers: SmartGunAds/HipMaxLockedTargets, TimeToLock, HitProbability, MissDelay, MissRadius, SmartGunAddSpiralTrajectory, SpiralRadius, SmartGunTargetAcquisitionRange, lock angles (Targetable/Locking/TagLock), SmartGunKeepTargetsOnAimStateChange, SmartGunContinousLockEnabled, SmartGunDisableOnReload, SmartGunMaxLockedPointsPerTarget (which body point it homes on), SmartGunPlayerProjectileVelocity, SmartGunNPCTrajectoryCurvatureMultiplier, SmartGunNPCShootProjectilesOnlyStraight.

---

## 10mm smart (Yukimura, Chao, Kappa, Dian, Shingen, Warden, Sidewinder)

### Uncommon
- **Name: Pathfinders**
  - Concept: rockets with a better seeker head but a weaker motor and warhead.
  - What it does: much faster lock and wider lock cone. Drawback: lower damage and slower flight, so fast movers can slip it.
  - Levers: SmartGunAds/HipTimeToLock down, lock angles up, DamagePerHit down, SmartGunPlayerProjectileVelocity down.
  - Feasibility: `stats`
  - NPC side: NPCs lock V faster (SmartGunNPCLockOnTime shorter), but the slow flight gives V time to dodge.

### Rare
- **Name: Scorpions**
  - Concept: rockets that hunt for the weak spot, not the centre of mass.
  - What it does: homes on the head or a cyberware point (MaxLockedPointsPerTarget), bonus headshot damage. Drawback: lower body damage, longer lock time.
  - Levers: SmartGunMaxLockedPointsPerTarget, HeadshotDamageMultiplier, TimeToLock up, DamagePerHit down.
  - Feasibility: `stats` (the point selection may need a probe to confirm it is configurable per mod)
  - NPC side: NPC rockets go for V's head; V's helmet or headgear matters.
- **Name: Corner-turners**
  - Concept: high-agility rockets with a big curved flight path.
  - What it does: lock-on works on targets not in line of sight (just out of cover, around a corner) and the rocket curves in; more spiral trajectory. Drawback: damage loss, shorter range, rockets can bump walls.
  - Levers: SmartGunAdsTargetableAngle up, SmartGunAddSpiralTrajectory, NPC trajectory curvature multiplier, EffectiveRange down.
  - Feasibility: `stats`
  - NPC side: NPCs flank-fire at V behind low cover; a real threat to hiding spots.

### Epic
- **Name: Swarm**
  - Concept: cheap mini-rockets in a hail that saturate a crowd.
  - What it does: lock many more targets at once (MaxLockedTargets very high), each locked target gets rockets split evenly across them. No drawback besides cost and low damage per rocket.
  - Levers: SmartGunAds/HipMaxLockedTargets, SmartGunEvenDistributionPeriod, DamagePerHit lower.
  - Feasibility: `stats`
  - NPC side: an NPC with Swarm locks V and any allies V has; mostly just more rockets on V.
- **Name: Tagalongs**
  - Concept: a rocket that leaves a bug on the target and then fires again from the gun at it.
  - What it does: first hit tags the target for 10 s. Rockets fired at a tagged target have much higher hit probability, a free lock, and ignore the lock cone, so you can shoot at it from behind cover. Tag shows through walls.
  - Levers: KyubiMyersTag-style tag, SmartGunHitProbability up on tagged targets, SmartGunKeepTargetsOnAimStateChange, SmartGunContinousLockEnabled.
  - Feasibility: `hit-code` (the "free lock" part is a `probe`)
  - NPC side: once V is tagged, NPCs fire from cover and the rockets find V.

### Wildcards
- **Name: Ghost heads**
  - Concept: a seeker with a stealth mode that does not ping the target's "locked on" warning.
  - What it does: silent lock (no lock-on alert to the target), less noise; low damage. Fits a stealth build.
  - Levers: WeaponNoise down, SmartGunStartingAccuracy; the missing lock warning needs a probe.
  - Feasibility: `stats` / `probe`
  - NPC side: V gets no lock warning from NPC fire. Mean, so maybe restrict it to V only.
- **Name: Stickers**
  - Concept: adhesive-nosed rockets that cling then detonate a beat later.
  - What it does: delayed damage (applied after 1-2 s) and a stagger on stick; the target can shake off with a dodge.
  - Levers: ForceStagger, delayed damage over time (Bleeding or Burning as a stand-in).
  - Feasibility: `hit-code` / `probe` for a true delay
  - NPC side: a short warning icon on V; V can roll to dodge.
- **Name: Whistlers**
  - Concept: rockets with a screamer in the nose.
  - What it does: loud and intimidating; makes nearby enemies break cover and stagger (low-level panic). Drawback: no stealth.
  - Levers: WeaponNoise up, Stagger on nearby NPCs, ForceStagger small chance.
  - Feasibility: `hit-code` / `probe`
  - NPC side: V gets staggered by incoming rockets more often.

---

## 20mm cluster (Zhuo, Palica)

### Uncommon
- **Name: Pumpkins**
  - Concept: bigger blast radius from a bulged warhead, smaller muzzle velocity.
  - What it does: slightly wider blast radius (where the gun has one). Drawback: slower flight and lower lock accuracy.
  - Levers: blast radius if configurable, SmartGunPlayerProjectileVelocity down, SmartGunHitProbability down.
  - Feasibility: `probe` for radius; otherwise `stats` as a slower, heavier hit.
  - NPC side: telegraphed, slow rockets V can sidestep.

### Rare
- **Name: Flechette pods**
  - Concept: the cluster bursts into a cone of darts just before the target.
  - What it does: converts the blast to a pellet burst: many small hits, good against unarmored crowds; little armor pen. Drawback: low single-target damage, short range.
  - Levers: ProjectilesPerShot up, SpreadDefault wide, EffectiveRange down.
  - Feasibility: `stats`
  - NPC side: V gets a shotgun-like burst from a smart gun; armor stops most of it.
- **Name: Sticky bombs**
  - Concept: tacky warheads that stick to the target and blow after a delay.
  - What it does: stick, then go off 1.5 s later with small-radius area damage. A running enemy carries the blast into its friends. Drawback: slow, no damage on initial impact.
  - Levers: delayed explosion, small radius.
  - Feasibility: `probe`
  - NPC side: V gets a visible countdown marker, and can dodge, or kill the carrier.

### Epic
- **Name: Carpet**
  - Concept: a rocket that releases bomblets along its flight path.
  - What it does: the rocket drops smaller blasts along its line, so a target in a corridor is hit by several. Straight upgrade in area coverage; cost is rarity.
  - Levers: ProjectilesPerShot up, spiral trajectory, small-radius blasts.
  - Feasibility: `probe`
  - NPC side: V is caught in corridors; V can get out of the line.
- **Name: Roof-knockers**
  - Concept: top-attack warheads that dive onto the target from above.
  - What it does: flight path arcs high and drops down, so cover from the front does not stop it; hits behind low walls. Cover piercing is not granted (it goes over, not through).
  - Levers: SmartGunNPCTrajectoryCurvatureMultiplier, SmartGunAddSpiralTrajectory, SmartGunMissDelay, hit probability up.
  - Feasibility: `stats` / `probe` for the arc
  - NPC side: V behind a chest-high wall is no longer safe.

### Wildcards
- **Name: Mule kicks**
  - Concept: a blunt, heavy 20mm slug with a gas-piston kick.
  - What it does: huge knockdown impulse, no blast. Pairs with mechs.
  - Levers: BaseKnockdownImpulse, KnockdownImpulse, ForceStagger.
  - Feasibility: `stats`
  - NPC side: knocks V on their back; hard to chain.
- **Name: Smoke pots**
  - Concept: cluster of smoke canisters.
  - What it does: leaves a smoke cloud at the impact point, blocks sight. Drawback: no damage.
  - Levers: spawned world effect.
  - Feasibility: `probe`
  - NPC side: smoke cover for NPC pushes.
- **Name: Beehives**
  - Concept: cluster that releases tiny seeker bomblets, each homes on a nearby body.
  - What it does: bomblets chain to nearby targets. Chain hit.
  - Levers: chained second-target effect.
  - Feasibility: `probe`
  - NPC side: V in a squad gets bomblets on any teammate nearby.

---

## 25mm dart (Ashura)

### Uncommon
- **Name: Needle points**
  - Concept: a narrower, long dart with a smaller head.
  - What it does: longer lock range (SmartGunTargetAcquisitionRange) and faster flight. Drawback: lower damage.
  - Levers: TargetAcquisitionRange up, SmartGunPlayerProjectileVelocity up, DamagePerHit down.
  - Feasibility: `stats`
  - NPC side: NPCs lock V from further; Ashura is rare among NPCs.

### Rare
- **Name: Anchors**
  - Concept: barbed darts that hold the target in place.
  - What it does: stagger and a short slow (pins feeling), plus a chance of Knockdown. Drawback: lower damage.
  - Levers: Knockdown, Stagger, ForceStagger; pin via ragdoll is `probe`.
  - Feasibility: `hit-code` / `probe`
  - NPC side: V gets a root or heavy stagger, then follow-up fire.
- **Name: Peekers**
  - Concept: darts with a camera in the tail, sending a feed.
  - What it does: the hit target and nearby enemies are scanned for a few seconds (tag/outline plus weak points), plus bonus damage to scanned targets from other Smart rounds. Drawback: low damage.
  - Levers: tag effect, BonusDamageAgainst..., longer tag duration.
  - Feasibility: `hit-code`
  - NPC side: V is outlined to the whole squad.

### Epic
- **Name: Bunker-busters**
  - Concept: tandem-charge darts that punch a hole in a wall and then go off.
  - What it does: dart penetrates cover and detonates behind it with a small blast. Epic cover pierce, armor pen high. Cost: price and scarcity.
  - Levers: pierce cover, ArmorPenetrationBonus, small blast.
  - Feasibility: `probe`
  - NPC side: V cannot hide behind thin cover from an NPC with Bunker-busters.
- **Name: Sniper's mercy**
  - Concept: a dart with a perfect seeker; never misses.
  - What it does: near 100% hit probability on locked targets even behind moving cover or at range, big crit damage on the head. Straight upgrade in accuracy.
  - Levers: SmartGunHitProbability max, CritDamage up, HeadshotDamageMultiplier.
  - Feasibility: `stats`
  - NPC side: do not put on NPCs, or use only on elite snipers; otherwise V cannot dodge it.

### Wildcards
- **Name: Tranq darts**
  - Concept: sedative darts.
  - What it does: Nonlethal, with a delayed collapse. Kill becomes a knockout.
  - Levers: Nonlethal, Stun/Knockdown after delay.
  - Feasibility: `hit-code`
  - NPC side: V gets drowsy: blur and slowed aim, not a loss.
- **Name: Cutters**
  - Concept: darts that cut cyberware.
  - What it does: Cyberware Malfunction chance and weapon malfunction on mechs.
  - Levers: CyberwareMalfunction, WeaponMalfunction, BonusDamageAgainstMechanicals.
  - Feasibility: `hit-code`
  - NPC side: V's cyberware flickers off for a few seconds.
- **Name: Spotters**
  - Concept: darts that paint the target for the rest of the group.
  - What it does: for a few seconds, all other weapons in the group hit the target harder (bonus damage taken). Co-op-flavored, great with squads.
  - Levers: damage-taken debuff on target.
  - Feasibility: `probe`
  - NPC side: V is painted and everyone hits harder.

---

## Family themes

- Lock behavior: lock speed, number of targets, lock cones, locking around corners, silent lock, which body point is targeted.
- Flight path: top-attack, corner-turning, spiral, slow-and-heavy, fast-and-light.
- Target data: tag and scan, painting a target, a camera feed, "bonus damage taken" debuffs.
- Payloads we have not used: sticky or delayed charges, smoke, tranq, flechette pods, bomblets and chains.
- Control, not just damage: anchors, knockdown, mule kicks, whistlers.
- Smart rounds have the least kinetic damage and the most room for odd effects, so many ideas here lean on `probe`. The `stats` ones are safe fallbacks.
- Beware the NPC side: perfect-accuracy and silent-lock rounds should be V-only or elite-only.

## Best 5 overall

1. **Tagalongs** (10mm): the tag makes every following rocket find its mark; fits the smart gun fantasy.
2. **Roof-knockers** (20mm): top-attack answers cover, which Smart has no answer to otherwise, without being a cover pierce.
3. **Swarm** (10mm): mass lock is a different playstyle, and it is stats only.
4. **Spotters** (25mm): the sniper dart as the squad's force multiplier; unusual and memorable.
5. **Corner-turners** (10mm): lock around corners; cheap to do, clearly different, and a real threat from NPCs too.

# Faction rounds

Added 2026-10-30. The odder ideas above work better as faction ammo than as general stock: a
round tied to one faction can be stranger and more one-sided than something every gun shop
sells. The faction's NPCs carry and fire it, so V meets it in their fights before getting any.
Same rules for NPCs and V, as always.

## Open questions

- **Tier.** Faction rounds could be their own label at Rare and Epic quality, or sit inside the
  normal tiers with a faction tag. Suggest Rare and Epic only, so the effects have room.
- **Where they come from.** Suggest: dropped by that faction's NPCs, and sometimes stocked by
  gun shops on their turf. Not crafted at first.
- **Calibers.** Each faction gets the calibers its NPCs actually carry. That needs a pass over
  the NPC loadouts in TweakDB before the rounds are pinned down.

## Themes, all factions

Gangs:
- **Maelstrom:** overclocked and unstable. Rounds that push the gun past spec: faster cycle
  time, harder recoil, heat. Chrome disruption on the Tech side. Drawbacks that bite the
  shooter. Brutal kills.
- **Scavengers:** junk and harvest. Recycled, hand-loaded, cheap and unreliable rounds. Dirty
  wounds. A kill that leaves more to strip off the body.
- **Tyger Claws:** speed and style. Handling, quick aim-in and fast draws, for bikes and close
  fights. Bleeding, from the blade culture.
- **Valentinos:** luck and showing off. Crits, headshots and one big shot, mostly on pistols and
  revolvers. Rounds that reward the risky play.
- **6th Street:** military surplus. Old stock that works: cheap steel-core, tracer belts,
  steady handling. Holding a street with suppressing fire.
- **Animals:** brute force. Heavy rounds with big knockback, stagger and knockdown, and the kick
  to match. Only works if you're strong enough to hold the gun.
- **Voodoo Boys:** netrunner ammo. Hits that set up quickhacks: tag the target, open it up, or
  pass a hack along to whoever's nearby. Tech and Smart guns.
- **Moxes:** self-defense. Pepper, flash and knockout rounds that stop someone without a body.
  They rarely fight V, so these would mostly come from vendors.
- **Wraiths:** Badlands raiders. Anti-vehicle and ambush rounds: hit the car and the driver.
  Fire.
- **Barghest:** Dogtown militia with stolen Militech gear. War-zone overkill: dismemberment,
  explosive heads on the big calibers, fear.

Corps:
- **Arasaka:** precision and control. Every round the same, low recoil, quiet kills, and
  surveillance: a hit marks the target for the whole team. Best on Smart and Tech, which they
  make.
- **Militech:** battlefield munitions. Belted mixes (every Nth round is tracer or AP), suppression,
  HE on the big guns, anti-armor.
- **Kang Tao:** smart guidance, cheap and mass-produced. More locks and more rockets, each one
  weaker.
- **Biotechnica:** chemicals. Poison and chem damage, stronger than the general Chem payloads.
- **Petrochem:** fuel. Incendiary and lingering fire.

Law and others:
- **NCPD:** duty loads. Stop the threat: stagger and less-lethal, plus tagging suspects. The
  mod already has Rubber and Beanbags, so this is the thinnest theme.
- **MaxTac:** borg killers. Rounds for putting down someone full of chrome: shut down
  cyberware, a bonus against heavy armor and bosses.
- **Aldecaldos:** nomad hunters. Hand-loaded long-range rounds, reliable, good against vehicles
  and big game. Friendly to V, so vendor-only.
- **FIA (Dogtown):** spy craft. Suppressed, quiet and precise.
- **Trauma Team, NetWatch:** skip; they barely fight V.

## First three: candidates

For the next release. Two or three ideas each; pick one or two per faction.

**Maelstrom**
- **Redliners** (Power rifles and SMGs). Overpressure loads that make the gun cycle faster. The
  cost is a lot more recoil and spread, and a small chance each shot that the gun jams.
  Levers: CycleTime, recoil, spread; WeaponMalfunction on the shooter. `stats` plus `probe`
  (jamming the shooter's own gun; Lockout's probe 4 covers half of it).
- **Chrome-cookers** (Tech). Each hit has a chance to make the target's cyberware malfunction.
  On V, V's cyberware glitches. Tech only, since Power rounds don't carry a charge. Levers:
  CyberwareMalfunction in the hit code. `hit-code`.
- **Meat-grinders** (Power). Kills tear bodies apart and hits cause bleeding. Levers:
  dismemberment thresholds, Bleeding chance. `stats` plus `hit-code`.

**Scavengers**
- **Reloads** (Power, many calibers). Recycled brass from mixed lots. Cheap, about half the price
  of the caliber's Common round, with a wide damage roll: some duds, some hot. Levers: the
  damage-roll band with dud and hot chances. `hit-code`.
- **Parts-pullers** (Power). A kill with this round leaves extra crafting components on the
  body. Levers: on kill, add components to the body's loot. `probe` (loot on kill).
- **Dirties** (Power). Rough, hand-cast bullets that leave a dirty wound: bleeding plus poison,
  a little less damage up front. Levers: Bleeding and Poisoned chances, damage down. `hit-code`.

**Arasaka**
- **House loads** (Power and Tech). Arasaka's own spec: a very narrow damage roll, less recoil
  and faster aim-in. A straight upgrade at Epic. Levers: damage-roll band, recoil, AimInTime.
  `stats` plus `hit-code`.
- **Watchlist** (Smart). A hit tags the target for everyone on the shooter's side, and smart
  rounds lock onto a tagged target right away. On V: V is tagged and the whole enemy squad knows
  where V is. Levers: Ping's tag, lock time. `hit-code` plus `probe` (instant lock on a tagged
  target, and the tag telling NPCs where V is).
- **Quiet professionals** (Power pistols and SMGs). Quiet rounds with silent kills and a headshot
  bonus. Levers: WeaponNoise, CanSilentKill, HeadshotDamageMultiplier. `stats`.

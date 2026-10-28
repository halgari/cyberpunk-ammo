# v1 calibers: all 13 calibers at Common and Uncommon

Extends the v1 slice (`2026-10-27-v1-slice-design.md`: 9mm, 5mm light rail and 10mm smart at
Common and Uncommon) to every caliber in `docs/CATALOG.md`, and gives calibers trade-offs of their
own. Rare and Epic for all 13 calibers are a later spec.

## Goal

Every ranged gun in the game loads its caliber's ammo, and each caliber has two rounds (4-gauge:
see below) that the player can swap through the Ammo slot, buy, loot and take from NPCs, exactly
as the slice's three calibers work now. Picking a caliber is a trade-off, not a ladder: a bigger
round gives up something (armor performance, recoil, weight, price or how often it turns up) for
its punch.

## Decisions (agreed in brainstorming, 2026-10-28)

- **Order:** Common and Uncommon for the 10 new calibers first, on the slice's machinery. Rare and
  Epic for all 13 come after, in their own spec.
- **Names:** one load keeps one slang name across calibers, with the caliber as prefix
  (`.45 Mushrooms`, `Heavy Sleevers`, `20mm Dumbfires`). Shotgun loads have their own names.
- **The magnum group is `12mm`** (Cyberpunk's metric naming for very heavy pistol rounds); `.45`
  stays `.45`.
- **4-gauge:** Buckshot is Common; the Slug is Uncommon only (there is no Common slug).
- **Calibers differ in stats, ammo weight, price and availability.** Enemy loadouts are not
  changed: NPCs keep the guns their records give them, and get only the ammo for those guns.
- **Not linear:** going up in caliber does not simply scale damage. Each caliber's profile trades
  one thing for another; the numbers below are starting points to tune in game.
- Individual guns (pump vs semi-auto, iconics) are a later pass.

## Lineup

| Caliber | Code | Guns | Common | Uncommon |
|---|---|---|---|---|
| 9mm | P-9 | *(slice)* | 9mm Ball | 9mm Mushrooms |
| .45 | P-45 | Unity, Liberty, Nue | .45 Ball | .45 Mushrooms |
| 12mm | P-MAG | Nova, Overture, Metel, Malorian 3516 | 12mm Ball | 12mm Mushrooms |
| 5.56 | P-556 | Umbra, Masamune, Copperhead, Defender | 5.56 Ball | 5.56 Mushrooms |
| 7.62 | P-762 | Ajax, Kyubi, MA70 HB | 7.62 Ball | 7.62 Mushrooms |
| 12.7 | P-127 | Kolac, SOR-22, Grad, Osprey, Mk.31 HMG | 12.7 Ball | 12.7 Mushrooms |
| 12-gauge | P-12G | Crusher, Pozhar, Tactician, Igla, Testera | Buckshot | Slugs |
| 4-gauge | P-4G | Carnage | 4ga Buckshot | 4ga Slugs |
| 5mm light rail | T-LIGHT | *(slice)* | 5mm Rail Slugs | 5mm Sleevers |
| Heavy rail | T-HEAVY | Burya, Achilles, Nekomata, Rasetsu, Satara | Heavy Rail Slugs | Heavy Sleevers |
| 10mm smart | S-10 | *(slice)* + Hercules 3AX, Sidewinder | 10mm Seekers | 10mm Dumbfires |
| 20mm cluster | S-CLUSTER | Zhuo, Palica | 20mm Seekers | 20mm Dumbfires |
| 25mm dart | S-DART | Ashura | 25mm Seekers | 25mm Dumbfires |

Iconic variants of these families come along through their family tags, as in the slice.

## Uncommon effects

Same load, same effect in every caliber, with the slice's numbers:

- **Mushrooms (Power):** damage ×1.2, armor penetration −0.5.
- **Sleevers (Tech):** charge time ×0.7, damage ×0.95.
- **Dumbfires (Smart):** damage ×1.25, smart hit probability ×0 (no guidance).
- **Slugs (12-gauge):** the shot leaves as one projectile carrying the whole shot's damage
  (the engine splits a shot's damage across its projectiles, so fewer projectiles carry more
  each); tight spread; effective range ×2.
- **4ga Slugs:** a hand cannon. One projectile carrying the whole shot's damage plus ×1.3; armor
  penetration +0.5; knocks the target down (`ForceKnockdown`); effective range ×2; recoil ×1.6.
  It does not pierce cover: piercing is kept for higher-tier rounds (kinetic penetrators,
  tungsten slugs, depleted-uranium rods) in the Rare/Epic spec.

## Caliber profiles

Every round of a caliber, Common included, carries the caliber's profile. An empty feed slot means
the Common round with no selector fitted, so the profile can't live on the selector: the startup
tweak that already gives each caliber's guns its feed slot and default ammo also adds the profile
to those guns' stats. Uncommon effects stack on top.

Profile values are relative to the gun's own stats (1.00 / 0 = unchanged):

| Caliber | Damage | Armor pen | Recoil | Range | Ammo weight | Price | Character |
|---|---|---|---|---|---|---|---|
| 9mm | 1.00 | 0 | 1.00 | 1.00 | 1× | 1× | baseline: light, cheap, everywhere |
| .45 | 1.10 | −0.15 | 1.10 | 1.00 | 1.5× | 1.2× | hits harder, worse into armor |
| 12mm | 1.15 | +0.10 | 1.35 | 1.00 | 2× | 1.6× | hand cannon: kick, weight, cost |
| 5.56 | 1.00 | +0.15 | 1.00 | 1.00 | 1× | 1× | rifle baseline, decent into armor |
| 7.62 | 1.05 | +0.25 | 1.20 | 1.10 | 1.5× | 1.3× | harder and better into armor, kicks |
| 12.7 | 1.00 | +0.40 | 1.25 | 1.00 | 2.5× | 2× | best into armor; heavy and dear |
| 12-gauge | 1.00 | −0.25 | 1.00 | 0.75 | 1× | 1× | brutal close, poor into armor, falls off |
| 4-gauge | 1.00 | −0.25 | 1.30 | 1.00 | 2.5× | 2× | the Carnage's big shells |
| 5mm light rail | 1.00 | 0 | 1.00 | 1.00 | 1× | 1× | baseline (Tech guns already pierce) |
| Heavy rail | 1.00 | +0.20 | 1.20 | 1.00 | 2× | 1.5× | dense slugs: armor, weight |
| 10mm smart | 1.00 | −0.10 | 1.00 | 1.00 | 1× | 1× | forgiving, light |
| 20mm cluster | 1.00 | −0.20 | 1.00 | 1.00 | 1.5× | 1.3× | swarms, poor into armor |
| 25mm dart | 1.00 | +0.10 | 1.00 | 1.00 | 3× | 2.5× | one big dart, rare |

- **Damage** is `DamagePerHit` ×. **Armor pen** is added to `CanWeaponIgnoreArmor`, which scales
  the target's armor by `(1 − pen)` (negative counts armor for more). **Recoil** multiplies the
  recoil kick stats. **Range** multiplies `EffectiveRange` (player shots only).
- **Ammo weight** is per round, relative to the 9mm round's carry weight; **price** is relative to
  the game ammo the caliber comes from (below).
- Damage multipliers do nothing on NPC shots (a known gap from the slice); armor pen and recoil on
  NPC guns are whatever the engine does with them.
- Stamina per shot is set on attack records, not by a stat, so it isn't part of a profile in v1.
- Uncommon effects stack on the profile: 12ga Slugs end at range 0.75 × 2 = 1.5× the gun's, 4ga
  Slugs at armor pen −0.25 + 0.5 = +0.25, `.45 Mushrooms` at damage 1.10 × 1.2 and pen −0.65.

## Where each caliber's ammo comes from

The four game ammo items stay the Common round of their caliber, so stacks in existing saves keep
their meaning. Vendors split each stack of game ammo, and loot conversion replaces it, across the
calibers that come from it (as the slice does for handgun ammo):

| Game ammo | Is | Also split into (share of the stack) |
|---|---|---|
| Handgun ammo | 9mm Ball (0.40) | .45 (0.20), 12mm (0.10), 5mm rail (0.15), 10mm smart (0.15) |
| Rifle ammo | 5.56 Ball (0.65) | 7.62 (0.35) |
| Sniper ammo | 12.7 Ball (0.60) | heavy rail (0.30), 25mm dart (0.10) |
| Shotgun ammo | 12ga Buckshot (0.70) | 4-gauge (0.10), 20mm cluster (0.20) |

Shares are each caliber's `lootWeight`; within a caliber the family's tier shares and the
owned-gun bias apply unchanged. Heavy rail comes from sniper ammo even though its guns used all
four (Burya handgun, Achilles rifle, Nekomata sniper, Satara shotgun). Kolac and SOR-22 (rifle
ammo) and Hercules and Sidewinder (rifle ammo) take their new caliber's ammo; the Mk.31 HMG
(`Ammo.Standard` today) joins 12.7.

Vendors, loot conversion and NPC ammo use the slice's code unchanged: gun shops sell up to
Uncommon, other vendors Common only; containers convert once; NPCs carry and drop their gun's
caliber and may roll Uncommon.

## Old saves

Game ammo already held becomes 9mm Ball, 5.56 Ball, 12.7 Ball and 12ga Buckshot. A gun moved to a
new caliber (a Unity to .45, a Satara to heavy rail, a Kolac to 12.7) starts empty until its
rounds are bought or looted. Same rule as the slice; documented, not fixed.

## Item text

Names as in the lineup. Descriptions in the item-text voice (slang or technical names, short
plain gun-counter text, no invented lore, checked with anti-ai-writing), drafted per load and
signed off by the user before they ship.

## Icons

One icon per round (about 20), made with the recipe in `docs/TESTING.md`: a square single-round
reference the user approves, then a square box shot from it. About 23 cents per round. Contact
sheets in batches.

## Checks before building

- Rasetsu and Erebus have no `_Default` preset: their gun lists come from the presets that exist.
  Erebus's ammo is read before it's left in 9mm.
- Hercules 3AX has no family weapon tag: it is matched by record.
- Mk.31 HMG's record is checked before it joins 12.7.
- Whether a negative `ProjectilesPerShotBonus` brings every shotgun (including the double
  barrels) to exactly one projectile.

## Testing

The slice's in-game harness, extended to all 13 calibers: every gun family has its feed slot;
rounds swap and unload; Uncommon stats apply; each caliber's profile reaches its guns; vendor and
loot splits match the shares above; NPCs of each caliber carry the right ammo. Then a hands-on
checklist for the user: profile feel per caliber, 12ga Buckshot against Slugs, the 4ga Slug.

## Order of work

1. Caliber profiles on the slice's three calibers (framework, tested on guns that already work).
2. The ten new calibers at Common and Uncommon: records, feed slots, gun lists, ammo split.
3. 12ga Slugs and 4ga Slugs (the projectile-count check first).
4. Item text, for the user's sign-off.
5. Icons.

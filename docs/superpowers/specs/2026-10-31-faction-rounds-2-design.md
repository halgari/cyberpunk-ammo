# Faction rounds, second five: design

Date: 2026-10-31. Status: draft for review. Follows `2026-10-30-faction-rounds-design.md`, whose
binding rules, tier codes, pricing and NPC rolls all carry over.

Tyger Claws, Valentinos, 6th Street, Militech and the Animals each get two kinds of round. That's
25 rounds across 10 kinds, taking the mod from 175 rounds to 200. They ship in the same release as
the first three factions. Voodoo Boys wait for a later release; Zombie Powder and Backdoor stay in
`docs/IDEAS.md` with their probe results.

## What's new against the first batch

- **Five faction keys:** `TygerClaws`, `Valentinos`, `SixthStreet`, `Militech`, `Animals`, set in
  `AmmoOverhaul.factionOf.*` from the game's `Factions.*` names, which are the same words.
- **Name tags:** `[Tyger]`, `[Val]`, `[6th]`, `[Mil]`, `[Animal]`.
- **New hit behaviour:** an effect that fires only on a headshot (Santa Muerte), and rank-aware
  stagger and knockdown chances (Hard Stop, Leg Day). Everything else uses levers the mod already
  has.
- **No new turf shops.** These rounds reach V from NPCs of the faction only. Turf stock can be added
  later with one flat per shop.

## The rounds

Numbers are starting points for the feel test. Calibers come from what each faction carries
(`docs/FACTIONS.md`).

**Tyger Claws: knock-off Arasaka, blade culture**

- **Shinobi Seconds** (Uncommon; 9mm, .45)
  - Counterfeit Shinobi: silent kills (`CanSilentKill`), -15% damage, and duds through the round's
    damage roll (5% hit for a quarter).
  - Text: "Shinobi copies off a Kabuki bench. Quiet like the real thing, most of the time.\n\nKills
    don't alert anyone nearby. -15% damage. 5% are duds that hit for a quarter."
- **Tanto** (Rare; 9mm, .45, 12mm)
  - 25% chance to cause bleeding, +10% crit chance.
  - Text: "Serrated jackets, cut by hand.\n\n25% chance to cause bleeding. +10% crit chance."

**Valentinos: flash and honor**

- **Gold Tips** (Rare; .45, 12mm)
  - +15% crit chance, +30% crit damage, +20% recoil. Sells for half again the Rare price.
  - Text: "Real gold on the nose, because anything less is an insult.\n\n+15% crit chance. +30% crit
    damage. +20% recoil."
- **Santa Muerte** (Epic; .45, 12mm)
  - +50% headshot damage, and a headshot sets the target on fire.
  - On V: an NPC's shot sets V on fire on a headshot if the game flags those on V. If it doesn't, each
    hit on V has a 10% chance instead, so the round still does the same thing to V.
  - Text: "Blessed before they're loaded. La Santisima takes who she takes.\n\n+50% headshot damage.
    Headshots set the target on fire."

**6th Street: surplus that works**

- **Surplus** (Uncommon; 9mm, .45, 12mm)
  - Narrow damage roll (-5% to +5%), -10% recoil.
  - Text: "Old military lots, kept dry and turned regularly. Nothing fancy, nothing surprising.\n\n
    Damage varies only 5% either way. -10% recoil."
- **Fourth of July** (Rare; 9mm, 12mm, 10mm)
  - Each hit tags the target through walls for 5 seconds (`AmmoOverhaul.PingTag`), with a 10% chance
    to set it on fire. The probe found no way to change tracer visuals and noise is a dead stat, so
    it has neither.
  - On V: the tag does nothing strange, as Ping; the burn is V's own burn.
  - Text: "Spotting rounds for squad fire. Your friends see what you hit.\n\nHits tag targets through
    walls for 5 seconds. 10% chance to set the target on fire."

**Militech: mil-spec consistency**

- **Mil-Spec** (Rare; 9mm, 7.62, light rail)
  - Narrow damage roll (-5% to +5%), 25% armor pen, -15% recoil.
  - Text: "Lot-tested, sealed, signed for. Every round does what the last one did.\n\nDamage varies
    only 5% either way. 25% armor penetration. -15% recoil."
- **Hard Stop** (Epic; 7.62, 12ga)
  - 30% chance per shot to stagger the target (`BaseStatusEffect.ForceStagger`), 50% armor pen,
    -10% damage. Boss and MaxTac NPCs don't stagger. Whether it really stops return fire is checked
    in the feel test.
  - On V: a stagger.
  - Text: "Rated to end the argument. Whoever takes one loses their footing.\n\n30% chance per shot to
    stagger the target. 50% armor penetration. -10% damage."

**Animals: stopping power**

- **Protein Loads** (Rare; 12mm, light rail, heavy rail)
  - +30% damage, +60% recoil, -30% effective range.
  - Text: "Big, hot loads straight from the Animals' gym. Whoever takes one feels it for days.\n\n
    +30% damage. +60% recoil. -30% range."
- **Leg Day** (Epic; 12mm, heavy rail)
  - 20% chance per shot to knock the target down, with `MuleKick.NpcEffect`'s rule: Elite, Boss and
    MaxTac NPCs stagger instead. +80% recoil.
  - On V: a knockdown, as Mule Kick. Mule Kick stays the Legendary version: every hit lands, and
    only it shoves the shooter.
  - Text: "Nobody walks right after leg day. They sit down and think about what they've done.\n\n
    20% chance per shot to knock the target down. +80% recoil."

## Headshot effects

A round's `<ammo>.aoHeadEffect` names a status effect. `AmmoFeedSystem.ApplyAmmoOnHit` adds it when
`attackData.HasFlag(hitFlag.Headshot)`, behind the same `gated` check as Cook-off. Probe result: the
flag is set before that hook runs and helmet hits have already lost it (0/12 on the chest, 11/15 on
the head, a burn on exactly those 11). Per-pellet chance doesn't apply, as these calibers fire one
projectile. The headshot damage comes from the part's stat, as a native bonus.

## Art

Approved for the first three, awaiting approval for the last two. Each form is its own object in
`tools/render/scene.py`, printed with the game's decals (`tools/render/faction_textures.sh`).

- **Tyger Claws:** vermilion lacquer box with a gold band and dark red silk, the red tiger crest on
  a black lid. Nickel cases, red tips.
- **Valentinos:** dark wood cigar box with gilt corners and red velvet, gold V and script name on a
  burgundy lid. Santa Muerte's lid is black with the game's Santisima Muerte stencil. Gold cases.
- **6th Street:** olive crate worn to the wood, rope handles, skull badge and name stencilled on the
  front, a hand-painted flag in the lid. Tarnished cases, green tips.
- **Militech:** gunmetal transit case with yellow latches, hazard stripes and the wordmark, rounds standing in foam with their tips
  under the rim so the lid would close, the Militech mark on the lid. Steel cases, yellow tips and coils.
- **Animals:** black gym supplement tub with a yellow wrapped label: the flexing jaguar, the red
  gang name and PAIN PAIN PAIN GAIN. Cap off beside it, two rounds spilled. Red tips and coils.

## Testing

New mechanisms only, in `tools/snippets/calibers/faction.sh`:

- Faction spelling: a spawned NPC of each new faction rolls as its key.
- Santa Muerte: a head shot burns, a chest shot doesn't; an NPC's Santa Muerte on V gives the burn
  by the rule above.
- Fourth of July and Hard Stop on live hits; Boss and MaxTac don't stagger from Hard Stop.
- Leg Day: Normal NPCs go down, Elites stagger.
- `records.lua`, `icons.lua`, `distribution.lua` and `tiers.lua` at 200 rounds. The atlas holds 300
  cells, so it keeps its size.

Field test by the user, with the kit's "Give field kit" button, as before. Full suite before release.

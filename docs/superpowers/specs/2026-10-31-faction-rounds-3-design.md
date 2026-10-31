# Faction rounds, last eight: design

Date: 2026-10-31. Status: built on branch `faction-rounds-3`, awaiting the user's feel test and art approval. Follows `2026-10-31-faction-rounds-2-design.md`; binding
rules, tier codes, pricing and NPC rolls all carry over.

All the gangs get rounds: Barghest, Voodoo Boys, Wraiths, Aldecaldos and the Mox. So do NCPD, Kang Tao
and NUSA, the factions V really meets. NUSA is the rare one. NetWatch, Afterlife mercs, Biotechnica,
Zetatech and Trauma Team get none. They ship in the same release as the first two batches.

That's 16 kinds and 37 rounds, taking the mod from 200 to 237. The atlas holds 300.

## Design rule

Every round does something a stat line can't. No round's main trade is damage against recoil. Effects
come from vanilla mods, attachments and named guns (`reference/catalog/effectors.tsv`, `parts.tsv`).

## What's new against the second batch

- **Eight faction keys:** `Barghest`, `VoodooBoys`, `Wraiths` (and `WraithsAndroid`), `Aldecaldos`,
  `TheMox`, `NCPD`, `KangTao`, `NUSA` (and `NUSA_Myers`).
- **Name tags:** `[Barghest]`, `[VDB]`, `[Wraith]`, `[Nomad]`, `[Mox]`, `[NCPD]`, `[Kang]`, `[NUSA]`.
- **A faction Legendary:** tier code 9, rolled first for the faction. Collect Call is the only one.
- **Turf shops for allies:** V rarely fights the Mox or Aldecaldos, so `Vendors.wat_kab_gunsmith_01`
  stocks the Mox and `Vendors.bls_ina_se5_gunsmith_01` the Aldecaldos, by the first batch's rule.
- **NUSA is rare:** Epic rounds only, at half the Epic chance of other factions. NPC rolls only: the
  only mark on an airdrop found was an `Airdropped` stat on its reward items, so containers stay out.

## The rounds

Numbers are starting points for the feel test.

**Barghest: Hansen's army and its market**

- **Dogtown Tax** (Rare; 9mm, 5.56)
  - V's kills leave eddies on the body, by the Parts-pullers rule. An NPC firing one gets nothing.
  - Text: "Hansen takes his cut of everything. Now you do too.\n\nKills leave eddies on the body."
- **Chimera Scrap** (Epic; 7.62, light rail)
  - Explosive bullets from the Firecracker mod's attack package, set by the selector's `OnAttach`
    (`docs/MECHANICS.md`). An NPC's attack can't carry it, so its hits make `AmmoOverhaul.ScrapBlast`
    instead, 1% of the target's health.
  - Text: "Cut from what's left of the mech. Still angry about it.\n\nBullets explode on impact."

**Voodoo Boys: the Net comes to you**

- **Bad Juju** (Epic; .45, light rail, 10mm)
  - 15% chance per shot of Cyberpsychosis for 20 seconds: `AmmoOverhaul.JujuMadness`, a copy of
    `MandessLevel4PlusPlus`, whose 60 seconds is too long. Boss and MaxTac immune. On V:
    `AIQuickHackStatusEffect.HackBlind`.
  - Text: "Something rides in on the round and it isn't friendly.\n\n15% chance per shot to turn the
    target on its friends for 20 seconds."
- **Collect Call** (Legendary; light rail, 10mm)
  - 10% chance per shot of the Haunted Gun's Blackwall upload, which kills outright. On Boss and
    MaxTac, and on V: `CyberwareMalfunction` instead, never a kill.
  - Text: "It's for you. It's from the other side of the Blackwall.\n\n10% chance per shot to kill the
    target outright. Please hold."

**Wraiths: dirty, and proud of it**

- **Pocket Sand** (Rare; .45, 12ga)
  - 20% chance per shot of `ShortBlind`, 2 seconds. Boss and MaxTac immune. On V:
    `AIQuickHackStatusEffect.HackBlind`.
  - Text: "Badlands grit packed behind the slug. Rude, and it works.\n\n20% chance per shot to blind
    the target for 2 seconds."
- **The Clap** (Epic; light rail, heavy rail)
  - 20% chance per shot of `BaseContagionPoison`. The effect doesn't spread by itself, so a hit that
    poisons also makes `AmmoOverhaul.ClapCloud`, a 4 m blast, and the hit hook adds the poison to whoever
    it reaches. That includes V, if V is close.
  - Text: "Picked up in the desert and passed around freely. You'll want to get that looked at.\n\n20%
    chance per shot to poison the target. It spreads to whoever's close."

**Aldecaldos: nothing wasted**

- **Waste Not** (Rare; 9mm, .45, 12mm)
  - 15% of shots don't use a round. An NPC's magazine runs the same way.
  - Text: "Handloaded at the back of a truck, and nobody spills a grain.\n\n15% of shots don't use a
    round."
- **Speedloaders** (Epic; .45, 12mm)
  - Drawing the gun refills its magazine from what V carries (Shuffler's `MagazineAutoRefill`, which
    acts on draw, not on holster), clamped to the pocket. NPCs don't swap mid-fight, so it does nothing
    for them.
  - Text: "Clan trick for when the raiders come twice.\n\nDraw the gun and the magazine's full,
    however you left it."

**The Mox: Lizzie's house rules**

- **Cut Off** (Epic; 9mm, .45, 12ga)
  - Non-lethal, and 15% chance per shot to knock the target out (`Unconscious`). Elite, Boss and
    MaxTac stagger instead. On V: a knockdown.
  - Text: "Bar rules. You've had enough.\n\nNon-lethal. 15% chance per shot to knock the target out."
- **Last Call** (Epic; 9mm, 12mm)
  - 15% chance per shot to start a 4 second script delay, then `Unconscious`. Vanilla's Neurotoxin stun
    lasts only a second. Elite, Boss and MaxTac stagger when it ends. On V: a knockdown when it ends.
  - Text: "Something in the drink. They've got about four seconds left.\n\n15% chance per shot to
    drop the target unconscious 4 seconds later."

**NCPD: to serve, and so on**

- **Standard Issue** (Uncommon; 9mm, .45)
  - `SpreadMax*` and `SpreadAdsMax*` x0.3, so a burst stops growing early. The Focus Fire mod is only a
    flat hip spread cut, so it wasn't used. The same on NPCs.
  - Text: "Lowest bidder, but they did get the barrels right.\n\nHold the trigger and shots stay tight
    instead of spreading."
- **Resisting Arrest** (Rare; 9mm, 12ga)
  - 20% chance per shot of `Electrocuted`. On V: `PlayerElectrocuted`.
  - Text: "Taser payload in a duty round. Stop moving.\n\n20% chance per shot to shock the target."

**Kang Tao: guidance packages**

- **Wide Angle** (Rare; 10mm, 20mm)
  - Much wider lock cone: +25 on the eight smart angle stats. They read 0 on every gun, the engine's
    own 8 to 12 degrees, so a multiplier does nothing and a value counts in degrees.
  - Text: "Seeker with a wider eye.\n\nLocks on to targets much further from the crosshair."
- **Second Opinion** (Epic; 10mm, 20mm, 25mm)
  - Locks two more targets at once: +2 on `SmartGunHipMaxLockedTargets` and
    `SmartGunAdsMaxLockedTargets`, hip 3 to 5 and ADS 1 to 3.
  - Text: "The round checks with its neighbours before it commits.\n\nLocks on to 2 more targets at
    once."

**NUSA: paperwork says this never happened**

- **Deniable** (Epic; .45, light rail, 10mm)
  - Double damage on NPCs not in combat, by script (`aoUnawareBonus`). Silent kills.
  - Text: "Lot numbers filed off at the factory.\n\nSilent kills. Double damage on targets who haven't
    seen you."
- **Black Budget** (Epic; 12.7, heavy rail)
  - 30% chance per shot of `HeavyPoision`, Maiko's Nue effect. On V: `PlayerPoisoned`.
  - Text: "Doesn't appear on any invoice.\n\n30% chance per shot to badly poison the target."

## Probes before the plan

Done on 2026-10-31, on a Normal NPC:

- `HauntedGunBlackwallUpload`: dead within a second, from full health.
- `MandessLevel4PlusPlus`: 60 seconds, NPC alive and unhurt on its own.
- `BaseContagionPoison`: 3 seconds, 38 health. Spreading not seen, with no second NPC.
- `NeurotoxinDelayedStun`: 1 second, then `Stun` for 1 second.
- `Unconscious`: instant and permanent. `Electrocuted`: 3 seconds, 40 health.

Later probes moved the rounds above where they failed. The live tests in `faction.sh` cover the rest.

## Rulings

- **Tiers:** the user asked for the strong ones to rate higher. Pocket Sand is Rare, The Clap,
  Speedloaders and Cut Off are Epic.
- **Cut Off** replaces Safe Word, which the user called weird.
- **Who counts as tough:** quest protected NPCs (Immortal, Invulnerable) and machines count as tough,
  so they're never knocked out or killed. With no tough record (Pocket Sand, Bad Juju) nothing happens
  to them. Drones get nothing.
- **Turf shops:** both Mox rounds are Epic, so that shop lists them by `aoTurfAmmo` (9mm, .45, 12mm,
  stack 10). The Aldecaldos shop sells Waste Not only.

## Art

Each faction needs its own new object, approved as forms first as before. First ideas:

- **Barghest:** dented ammo can with Hansen's stencil, rounds on a scrap-metal tray.
- **Voodoo Boys:** a wooden shrine tray of black wax, rounds stood in it like candles among real ones,
  the gang's mark chalked on the board behind. **Collect Call:** a netrunner's black cyberdeck, rounds
  in its memory bay, the screen on a Blackwall breach warning. The user turned down a pouch and a rotary phone.
- **Wraiths:** a jerrycan cut open and packed with sand.
- **Aldecaldos:** a tobacco tin, hand-labelled.
- **The Mox:** a pink sequinned clutch.
- **NCPD:** a plastic evidence bag with a chain-of-custody label.
- **Kang Tao:** a slim graphite device case. White was too white.
- **NUSA:** a blank grey document box stamped CLASSIFIED.

Built as `bar_can`, `vdb_shrine`, `vdb_deck`, `wraith_can`, `nomad_tin`, `mox_clutch`, `ncpd_bag`,
`kang_case` and `nusa_box` in `tools/render/scene.py`, awaiting approval.

## Testing

New mechanisms only, in `tools/snippets/calibers/faction.sh`: faction spelling, each on-hit effect by
rank and on V, Waste Not and Speedloaders on a live gun, the Legendary roll, and the two new turf
shops. `records.lua`, `icons.lua`, `distribution.lua` and `tiers.lua` at the new count. Full suite
before release.

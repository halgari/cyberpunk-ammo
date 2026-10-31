# Faction rounds, last eight: design

Date: 2026-10-31. Status: draft for review. Follows `2026-10-31-faction-rounds-2-design.md`; binding
rules, tier codes, pricing and NPC rolls all carry over.

All the gangs get rounds: Barghest, Voodoo Boys, Wraiths, Aldecaldos and the Mox. So do NCPD, Kang Tao
and NUSA, the factions V really meets. NUSA is the rare one. NetWatch, Afterlife mercs, Biotechnica,
Zetatech and Trauma Team get none. They ship in the same release as the first two batches.

That's 16 kinds and about 40 rounds, taking the mod from 200 to about 240. The atlas holds 300.

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
- **NUSA is rare:** Epic rounds only, at half the Epic chance of other factions. NPC rolls only,
  unless the probe below finds a way to reach Dogtown airdrops alone.

## The rounds

Numbers are starting points for the feel test.

**Barghest: Hansen's army and its market**

- **Dogtown Tax** (Rare; 9mm, 5.56)
  - V's kills leave eddies on the body, by the Parts-pullers rule. An NPC firing one gets nothing.
  - Text: "Hansen takes his cut of everything. Now you do too.\n\nKills leave eddies on the body."
- **Chimera Scrap** (Epic; 7.62, light rail)
  - Explosive bullets from the Firecracker mod's attack package, through the mod's existing
    explosive path (`docs/MECHANICS.md`).
  - Text: "Cut from what's left of the mech. Still angry about it.\n\nBullets explode on impact."

**Voodoo Boys: the Net comes to you**

- **Bad Juju** (Epic; .45, light rail, 10mm)
  - 15% chance per shot of Cyberpsychosis for 20 seconds: a copy of `MandessLevel4PlusPlus`, whose
    60 seconds is too long. Boss and MaxTac immune. On V: `AIQuickHackStatusEffect.HackBlind`.
  - Text: "Something rides in on the round and it isn't friendly.\n\n15% chance per shot to turn the
    target on its friends for 20 seconds."
- **Collect Call** (Legendary; light rail, 10mm)
  - 10% chance per shot of the Haunted Gun's Blackwall upload, which kills outright. On Boss and
    MaxTac, and on V: `CyberwareMalfunction` and a heavy hit instead, never a kill.
  - Text: "It's for you. It's from the other side of the Blackwall.\n\n10% chance per shot to kill the
    target outright. Please hold."

**Wraiths: dirty, and proud of it**

- **Pocket Sand** (Uncommon; .45, 12ga)
  - 20% chance per shot of `ShortBlind`, 2 seconds. Boss and MaxTac immune. On V:
    `AIQuickHackStatusEffect.HackBlind`.
  - Text: "Badlands grit packed behind the slug. Rude, and it works.\n\n20% chance per shot to blind
    the target for 2 seconds."
- **The Clap** (Rare; light rail, heavy rail)
  - 20% chance per shot of `BaseContagionPoison`, which spreads between NPCs standing close (to
    confirm). On V: `PlayerPoisoned`.
  - Text: "Picked up in the desert and passed around freely. You'll want to get that looked at.\n\n20%
    chance per shot to poison the target. It spreads to whoever's close."

**Aldecaldos: nothing wasted**

- **Waste Not** (Rare; 9mm, .45, 12mm)
  - 15% of shots don't use a round. An NPC's magazine runs the same way.
  - Text: "Handloaded at the back of a truck, and nobody spills a grain.\n\n15% of shots don't use a
    round."
- **Speedloaders** (Rare; .45, 12mm)
  - Holstering the gun refills its magazine from what V carries (Shuffler's `MagazineAutoRefill`).
    NPCs don't holster mid-fight, so it does nothing for them.
  - Text: "Clan trick for when the raiders come twice.\n\nHolster the gun and the magazine refills
    itself."

**The Mox: nobody touches the girls**

- **Safe Word** (Rare; 9mm, .45, 12ga)
  - Non-lethal, and 15% chance per shot to knock the target out (`Unconscious`). Elite, Boss and
    MaxTac stagger instead. On V: a knockdown.
  - Text: "You had your chance to use it.\n\nNon-lethal. 15% chance per shot to knock the target out."
- **Last Call** (Epic; 9mm, 12mm)
  - 15% chance per shot to start a 4 second timer, then `Unconscious`. Vanilla's Neurotoxin stun lasts
    only a second, so this is a new record of the same shape. Elite, Boss and MaxTac stagger when it
    ends. On V: a knockdown when it ends.
  - Text: "Something in the drink. They've got about four seconds left.\n\n15% chance per shot to
    drop the target unconscious 4 seconds later."

**NCPD: to serve, and so on**

- **Standard Issue** (Uncommon; 9mm, .45)
  - Spread tightens during sustained fire, the Focus Fire mod's stat group. The same on NPCs.
  - Text: "Lowest bidder, but they did get the barrels right.\n\nHold the trigger and shots tighten
    up instead of spreading."
- **Resisting Arrest** (Rare; 9mm, 12ga)
  - 20% chance per shot of `Electrocuted`. On V: `PlayerElectrocuted`.
  - Text: "Taser payload in a duty round. Stop moving.\n\n20% chance per shot to shock the target."

**Kang Tao: guidance packages**

- **Wide Angle** (Rare; 10mm, 20mm)
  - Much wider lock cone, the Panorama mod's stats.
  - Text: "Seeker with a wider eye.\n\nLocks on to targets much further from the crosshair."
- **Second Opinion** (Epic; 10mm, 20mm, 25mm)
  - Locks two more targets at once, the Headhopper mod's `SmartGunAdsMaxLockedTargets`.
  - Text: "The round checks with its neighbours before it commits.\n\nLocks on to 2 more targets at
    once."

**NUSA: paperwork says this never happened**

- **Deniable** (Epic; .45, light rail, 10mm)
  - Hits on an unaware target count as stealth hits with a large bonus, the Warden and Ticon
    `AddHitFlagToAttackEffector`. Silent kills.
  - Text: "Lot numbers filed off at the factory.\n\nSilent kills. Big bonus damage on targets who
    haven't seen you."
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

Still to probe:

- The Clap: spreading with two NPCs close together.
- Waste Not: `Pride_Free_Ammo_Buff` against the mod's own feed. If it can't work, a scripted refund of
  the round in the feed.
- Speedloaders: `MagazineAutoRefill` with per-gun ammo.
- Standard Issue, Wide Angle and Second Opinion: mod stats on a selector part.
- Chimera Scrap: the attack package on a selector, and an iconic with its own package.
- Deniable: the stealth hit flag and the damage it gives.
- Bad Juju: Cyberpsychosis on a shorter copy, with other NPCs near.
- Airdrops: whether a Dogtown airdrop container can be told from any other.

If a round fails its probe it changes before the plan, and the user hears about it.

## Art

Each faction needs its own new object, approved as forms first as before. First ideas:

- **Barghest:** dented ammo can with Hansen's stencil, rounds on a scrap-metal tray.
- **Voodoo Boys:** a woven pouch with charms. **Collect Call:** an old rotary phone with rounds in its
  dial, a new object as Legendaries need.
- **Wraiths:** a jerrycan cut open and packed with sand.
- **Aldecaldos:** a tobacco tin, hand-labelled.
- **The Mox:** a pink sequinned clutch.
- **NCPD:** a plastic evidence bag with a chain-of-custody label.
- **Kang Tao:** a slim white device case.
- **NUSA:** a blank grey document box stamped CLASSIFIED.

## Testing

New mechanisms only, in `tools/snippets/calibers/faction.sh`: faction spelling, each on-hit effect by
rank and on V, Waste Not and Speedloaders on a live gun, the Legendary roll, and the two new turf
shops. `records.lua`, `icons.lua`, `distribution.lua` and `tiers.lua` at the new count. Full suite
before release.

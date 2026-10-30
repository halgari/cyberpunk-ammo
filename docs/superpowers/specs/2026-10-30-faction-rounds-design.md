# Faction rounds, first three: design

Date: 2026-10-30. Status: draft for the user's review; no code yet. Decisions the user has not
made yet are marked **Open** and collected at the end. Round ideas come from `docs/IDEAS.md`
("Faction rounds").

Maelstrom, Scavengers and Arasaka each get rounds nobody else sells. A faction's NPCs carry and
fire them, so V meets a round in that faction's fights before getting any. This draft has 26 rounds
across 9 kinds, which takes the mod from 149 rounds to 175.

## Binding rules

- NPCs and V follow the same rules. Where an effect can't mean the same on V, the round says what
  it does instead.
- Common rounds stay vanilla. No automatic ammo switching.
- Effects use what the engine does natively: stats, status effects, the mod's hit code, the game's
  own systems. No scripts faking a weapon with timed blasts or launched items (user ruling, from
  Bouncing Betty). Each effect gets tried for feel before its kind is built out.
- Armor pen: 20-30% at Rare, 50-70% at Epic. No full armor ignore (Legendary only).
- Cover piercing only at Epic and up. No shock or EMP on Power rounds.
- Item text: slang names, plain gun-counter descriptions, no invented lore, effect lines after a
  blank line.

## How they differ from the general rounds

- **A faction tag.** Each faction round's ammo carries `aoFaction` ("Maelstrom", "Scavengers",
  "Arasaka"). The flat already exists: `DamageRoll.Keys` reads `AmmoOverhaul.roll.<aoFaction>.*`
  as a layer between the round and its family, but no shipped round sets it yet (only
  `Ammo.AO_Test_RollFaction`). `tools/rounds/rounds.py` needs a `faction=` field on a kind to write
  it.
- **Their own tier codes.** `selectorTiers` gets two new values: 5 (faction, Rare quality) and 6
  (faction, Epic quality). Every general list looks rounds up by exact tier
  (`SelectorsForTier(caliber, 2 or 3)`, `AmmosForTier`, `TierWeights`), so tiers 5 and 6 stay out
  of the general NPC rolls, `AmmoDistribution.Spread`, `Pick` and vendors without special cases.
  That's the same way tier 4 keeps Legendary rounds out. The generator maps 5 and 6 to Rare and
  Epic for quality, price and disassembly.
- **No crafting** (Open, recommended): no recipe and no load sheet. `tools/crafting/crafting.py`
  already skips tier 4 for recipes and keeps its disassembly flats; 5 and 6 join that rule. A stack
  breaks down into Rare or Epic components by the existing rule.
- **Price:** Rare x4 and Epic x8 of the caliber's Common round, as for the general tiers. Reloads
  are the exception below.

## The rounds

Calibers come from the loadout tally at the end of this spec. Numbers are starting points for the
feel test.

**Maelstrom: overclocked and unstable**

- **Redliners** (Rare; 5.56, 7.62, .45)
  - Overpressure loads: the gun cycles about 25% faster, with about 40% more recoil and spread.
  - Each shot has a 2% chance to jam the shooter's own gun for 3 seconds. Same on NPCs and V.
  - Levers: CycleTime, recoil, spread (stats). The jam is `WeaponMalfunction`, which Lockout
    already uses on V and NPCs. It needs a per-shot hook on both sides: `ShootEvents.OnEnter` (V,
    as Mule Kick) and `NpcAmmo.TakeShot` (NPCs). Feasibility: stats plus existing hooks.
  - Item text: "Overpressure loads. They run the gun past what it was built for, and sometimes the
    gun quits.\n\n+25% fire rate. +40% recoil and spread. 2% chance per shot to jam your gun."
- **Chrome-cookers** (Rare; light and heavy rail)
  - A hit has a 15% chance of a cyberware malfunction, and 10% less damage.
  - On V: V's cyberware glitches, through the mod's existing player effect mapping
    (`AOData.PlayerEffect`). Check the mapping covers it.
  - Levers: `BaseStatusEffect.CyberwareMalfunction` in `aoEffects`, as Hack Carrier does.
    Feasibility: hit code, proven. Overlap: Hack Carrier does this on Smart at Epic with a jam too.
- **Meat-grinders** (Epic; .45, 12mm, 12ga, 4ga)
  - Kills tear bodies apart, and hits have a 30% chance to bleed.
  - Levers: `HitDismembermentFactor` raised (stats), `Bleeding` in `aoEffects`. Feasibility: hit
    code proven; the dismemberment stat isn't tested on a gun, so it needs a feel test. On V: bleed
    only. 4ga is here because the Carnage is the Maelstrom's own gun.

**Scavengers: junk and harvest**

- **Reloads** (quality Open, see below; 12mm, .45, 9mm)
  - Recycled brass from mixed lots. A wide damage roll with real duds and hot rounds. Half the
    price of the caliber's Common round.
  - Levers: `rollMin`, `rollMax`, `rollDudChance`, `rollHotChance`, set once for all Scav rounds
    in `AmmoOverhaul.roll.Scavengers.*`, the faction layer that already exists. Feasibility: hit
    code, proven by Match.
  - These are worse than Common, so a Rare badge would read wrong. **Open:** recommended Uncommon
    quality, an exception to the Rare and Epic rule.
- **Dirties** (Rare; 12mm, .45, 9mm)
  - Rough hand-cast bullets: 10% less damage, 25% chance to bleed, 25% chance to poison.
  - Levers: `aoEffects` with both effects. Feasibility: hit code, proven. On V: `PlayerPoisoned`
    through the existing mapping.
- **Parts-pullers** (Rare; 12mm, .45)
  - A kill with this round leaves extra crafting components on the body.
  - The mod already adds to a body's loot at `EvaluateLootQuality` (`NpcAmmo`), so this adds a
    small stack of components of the round's grade to what's given back. Feasibility: existing
    hook, new code; needs a test that the killing round is known at loot time (Cook-off marks its
    kills the same way).
  - NPC side: no effect. V's body isn't looted. That's the one round with no NPC version; flagged
    because of the same-rules rule. **Open.**

**Arasaka: precision and control**

- **Kata** (Epic; .45, 5.56, 7.62, light rail)
  - House spec: every round the same. Very narrow damage roll, about 30% less recoil, about 30%
    faster aim-in.
  - Levers: roll band as Match, recoil, AimInTime (stats). Feasibility: stats and hit code, proven.
    It is close to Match, with handling instead of Match's price; check they read as different.
- **Kansatsu** (Epic; 10mm, 20mm, 25mm smart)
  - A hit tags the target. The shooter's team sees it, and smart rounds lock onto a tagged target
    at once.
  - Levers: the tag is Ping's (`AmmoOverhaul.PingTag`, proven). Instant lock is not proven. The
    lock time stats are per gun (`SmartGunHip/AdsTimeToLock`, `SmartGunTimeToLock*Multiplier`), so
    the engine has no per-target lock time that scripts can see. **Needs a probe.**
  - Native fallback: the round halves lock time at all times (a stat) and the tag still shows the
    target through walls. It loses the link between the tag and the lock.
  - On V: V is tagged. Whether NPCs act on it is a second probe; the vanilla route to try is the
    squad's shared threat data. Fallback: the tag on V does nothing for NPCs, so the NPC version
    is the short lock only.
- **Shinobi** (Rare; 9mm, .45)
  - Silent kills and +50% headshot damage, with 10% less range.
  - Levers: `CanSilentKill`, `WeaponNoise`, `HeadshotDamageMultiplier` (stats). Feasibility: stats,
    proven by Subsonic and Heartseeker.

## Distribution

**Finding an NPC's faction.** `NPCPuppet.GetAffiliation()` returns the character record's
affiliation name (`TweakDBInterface.GetCharacterRecord(id).Affiliation().EnumName()`). It is on
every NPC and costs one lookup at stock time.
- Flats map an affiliation to a faction key, so adding a faction later is data:
  - `AmmoOverhaul.factionOf.Maelstrom` and `.MaelstromAndroid`: "Maelstrom"
  - `AmmoOverhaul.factionOf.Scavengers` and `.ScavengersAndroid`: "Scavengers"
  - `AmmoOverhaul.factionOf.Arasaka`: "Arasaka"
- The affiliation records come from `reference/catalog/factions.tsv`. There is no Arasaka android
  affiliation in it. `UnaffiliatedCorpo`, `KangTao` and others are not Arasaka and get nothing.
- The enum name's exact spelling at runtime needs one check in the game.

**NPC roll.** `NpcAmmo.RollRound` is the one place every NPC gun gets a round. The order for a gun
becomes:
1. A gun whose feed slot is already filled keeps its round, as now.
2. Legendary, with its rank chance, as now.
3. **New:** if the NPC's faction has rounds for this gun's caliber, roll that faction's chance for
   the NPC's rank. A hit picks one of the faction's rounds for the caliber: Epic first with its own
   chance, then Rare. It goes through the same path as any rolled round (`aoUncommonGuns`, selector
   stat modifiers on the gun), so the stats and hit code work with no new NPC code.
4. A miss falls through to the existing Epic, Rare and Uncommon rolls.

**Chance per gun, by rank** (`AmmoOverhaul.npcFactionChance.<rank>` for Rare,
`AmmoOverhaul.npcFactionEpicChance.<rank>` for Epic; every rank listed, zeros included, so tests
can set them):
- Trash: Rare 0%, Epic 0%
- Weak: Rare 5%, Epic 0%
- Normal: Rare 10%, Epic 0%
- Rare: Rare 15%, Epic 3%
- Officer: Rare 20%, Epic 5%
- Elite: Rare 25%, Epic 10%
- Boss: Rare 30%, Epic 15%
- MaxTac: 0% (no faction)

For scale: today Trash, Weak and Normal NPCs never roll a general Rare or Epic, and only Elite and
Boss roll a general Epic. These chances make faction rounds the most common thing above Uncommon in
that faction's fights. That is the point, and it also raises difficulty in those fights. **Open:**
the numbers.

**Loot.** Nothing new. What's left of an NPC's stack is noted at death and given back as loot
(`NpcAmmo`, `EvaluateLootQuality`), so a faction round drops as a normal stack: a gun's magazines
by rank, less what was fired. This is V's main source.

**Containers.** None at first: a container has no known faction. `LootConvert` keeps rolling up to
Epic from general rounds, which excludes tiers 5 and 6.

**Turf gun shops** (Open, recommended: build second, after the NPC side plays well)
- The hook exists: `Vendor.AOSplitAmmo` runs on every stock build and already knows
  `GetVendorType()` is Gunsmith.
- **What the code can't tell yet:** which faction a shop belongs to. The repo has no list of vendor
  IDs. `Vendor_Record` has a `Faction()` field, but I can't see whether gun shops fill it in without
  the game. The vendor's ID string (`GetVendorTweakID()`) is available, and it's the likely way
  to hand-map shops.
- Step one is a read-only dump in the game: every Gunsmith's ID and `Faction()`, through the
  existing `AODebugVendors`.
- If `Faction()` is empty, the fallback is a hand-written `AmmoOverhaul.vendorFaction.<vendor id>`
  list, one entry per shop. Using V's district at stock time was also considered. It's worse: a
  stock can be built when V is elsewhere, and the prevention system's current district is about
  V, not the shop.
- Which shop counts as whose turf is a judgement call; the first list is a proposal for the user.
- Rule: a turf shop has a 25% chance per stock build of one or two extra stacks of that faction's
  Rare rounds. Never Epic: nobody sells Epic. Reloads count as stock at any Scav turf shop.

**Same rules check.** All of the above only changes which round an NPC holds. Stats, jams, bleeds
and tags then work through the code every round uses. Parts-pullers is the one exception, noted
above.

## Art

- Each faction gets its own box family, so a round reads as that faction's at a glance. The box form
  is decided per faction, the same as Legendary's case.
- **Arasaka:** the black hard case with a red seam, red latches and the lid label is approved. Black
  cases with the red emblem printed on the rounds.
- **Maelstrom:** black worn steel can, red wordmark spray, white skull stencil, black rounds with
  red tips. The last fix (decals sized to the wall) was never shown to the user.
- **Scavengers:** loose rounds in a tray or a pile on cardboard. Not picked, and the sim never
  settled.
- The prototype scene files are gone from the scratchpad, so all three are rebuilt in `tools/render`
  from the descriptions above and the case form already there. Game textures (gang logo atlas,
  Arasaka label sheet, Maelstrom masks) have to be extracted again with `tools/linux/wolvenkit.sh`.
  Blender and PIL only.
- A task of its own: render, show the user, then generate all 26 icons.

## Everything else follows the existing pattern

- `tools/rounds/rounds.py` gains `faction=` and tiers 5 and 6; selectors, prices, icons and item
  text are generated as for other rounds. `rounds_tiers.json` gains the tiers for the renderer.
- `AOData` gains `FactionOf(npc)`, `FactionChance(rank, tier)` and `SelectorsForFaction(caliber,
  faction)`.
- Checks that count tiers (`tiers`, `records`, `distribution`, `crafting`, `icons`) gain the new
  tiers. Docs, the catalog, the banner grid (17 x 9 holds 153, so 175 needs a new grid) and the Nexus
  page update.

## Testing

- **Records:** 26 rounds, right quality and price, no recipe, in no general list, never in a
  non-turf vendor's stock, never rolled by another faction.
- **NPC rolls:** a Maelstrom, a Scav and an Arasaka NPC each roll only their own rounds; an
  unaffiliated NPC never does; the chances by rank; a miss falls through.
- **Live, one check per mechanism:**
  - Redliners jam the shooter on both sides;
  - Chrome-cookers on V;
  - Meat-grinders dismember;
  - the Reloads roll layer;
  - Parts-pullers add components;
  - Kansatsu tag and lock;
  - Shinobi silent kill;
  - a faction round drops as loot.
- **The user's feel test** before each kind is built out, then a playtest of all nine kinds.

## Out of scope

Other factions. Legendary faction rounds. Crafting of faction rounds. Faction-marked containers.

## Data: which guns each faction carries

From `reference/catalog/factions.tsv`, mapped to the mod's calibers by each caliber's `weaponTags`.
The number is how many distinct character records carry that caliber. It's a count of records, not
of spawns: it shows what a faction is built around, not how often V meets it. Melee and vehicle or
mech guns are left out.

- **Maelstrom** (including androids):
  - light rail 259 (Omaha, Quasar, Kenshin)
  - .45 256 (Unity, Nue)
  - heavy rail 251 (Burya, Satara, Nekomata)
  - 5.56 93 (Umbra, Defender)
  - 10mm smart 83 (Sidewinder)
  - 7.62 83 (Ajax)
  - 12mm 54 (Nova, Overture)
  - 4ga 26 (Carnage)
  - 12ga 25 (Igla, Pozhar, Testera)
  - 9mm 19
- **Scavengers** (including androids):
  - 12mm 586 (Nova, Overture, Metel)
  - light rail 337 (Grit, Quasar, Ticon)
  - .45 322 (Unity)
  - heavy rail 193 (Burya, Satara, Nekomata)
  - 9mm 106 (Pulsar, Guillotine, Saratoga)
  - 10mm smart 97 (Dian, Warden)
  - 5.56 88 (Copperhead, Defender)
  - 12ga 52, 20mm smart 51, 12.7 21, 7.62 1
- **Arasaka:**
  - .45 342 (Nue, Unity, Liberty)
  - 10mm smart 296 (Yukimura, Kappa, Shingen, Chao)
  - light rail 290 (Kenshin, Omaha, Quasar)
  - 5.56 88 (Masamune, Defender)
  - 9mm 67 (Saratoga, Lexington)
  - heavy rail 66 (Satara, Nekomata)
  - 7.62 60 (Kyubi)
  - 12ga 55 (Tactician, Testera)
  - 20mm smart 44 (Zhuo)
  - 25mm smart 15 (Ashura)
  - 12mm 12

What this changed from `docs/IDEAS.md`: Maelstrom barely carry SMGs (Redliners swap SMGs for .45,
their main Power gun), and light rail, not rifles, is what they carry most, which suits
Chrome-cookers. Scav guns are mostly 12mm Novas, so 12mm leads their list.

## Open questions, recommendation first

1. **Tiers.** Rare and Epic only, as IDEAS suggests, with one exception: Reloads at Uncommon
   quality, since they're worse than Common.
2. **Sources.** NPC drops first, turf gun shops second, no crafting and no containers.
3. **Drop rates.** The chance list above, which makes faction rounds common in that faction's
   fights, even from Weak and Normal NPCs.
4. **Parts-pullers.** Keep them as the one round with no effect when an NPC fires it, or drop them
   and give Scavs only Reloads and Dirties. Recommended: keep.
5. **Kansatsu.** Run the instant-lock probe first; if the engine can't do it, take the fallback
   (faster lock at all times, plus the tag) rather than faking it from a script.
6. **Faction marking on the item.** Rely on the name and the box, with no "Arasaka" line in the
   text. Recommended, since it stays out of lore.
7. **Turf map.** After the vendor dump, the user approves which gun shops count as whose turf.
8. **Round count.** 26 rounds in the first set, or fewer calibers per kind to ship sooner.

# Faction rounds, first three: design

Date: 2026-10-30. Status: built. Round ideas come from `docs/IDEAS.md`
("Faction rounds").

Maelstrom, Scavengers and Arasaka each get rounds nobody else sells. A faction's NPCs carry and
fire them, so V meets a round in that faction's fights before getting any. There are 26 rounds
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
- **Their own tier codes.** `selectorTiers` gets 5 (faction, Rare quality), 6 (Epic), 7 (Common, for
  Reloads) and 8 (Uncommon, for Gutter Lead). Every general list looks rounds up by exact tier
  (`SelectorsForTier(caliber, 2 or 3)`, `AmmosForTier`, `TierWeights`), so tiers 5 to 8 stay out
  of the general NPC rolls, `AmmoDistribution.Spread`, `Pick` and vendors without special cases.
  That's the same way tier 4 keeps Legendary rounds out. The generator maps them to their quality for
  quality, price and disassembly, and a round's tier is its `tier=` in `tools/rounds/rounds.py`.
- **No crafting:** no recipe and no load sheet. `tools/crafting/crafting.py`
  already skips tier 4 for recipes and keeps its disassembly flats; 5 to 8 join that rule. A stack
  breaks down into components of its quality by the existing rule.
- **Price:** Uncommon x2, Rare x4 and Epic x8 of the caliber's Common round, as for the general
  tiers. Reloads are the exception below.

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
    gun quits.\n\n+25% fire rate. +40% recoil and spread. 2% chance per shot to jam your weapons
    for 3 seconds." "Weapons", not "gun": the jam stays on V across a swap (see the probe results).
- **Chrome-cookers** (Epic; light and heavy rail)
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

- **Reloads** (Common quality; 12mm, .45, 9mm)
  - Recycled brass from mixed lots. A wide damage roll with real duds and hot rounds. Half the
    price of the caliber's Common round.
  - Levers: `rollMin`, `rollMax`, `rollDudChance`, `rollHotChance`, set once for all Scav rounds
    in `AmmoOverhaul.roll.Scavengers.*`, the faction layer that already exists. Feasibility: hit
    code, proven by Match.
  - Worse than a Common round, so Common quality (see Decisions).
- **Gutter Lead** (Uncommon; 12mm, .45, 9mm)
  - Rough hand-cast bullets: half damage, 25% chance to bleed, 25% chance to poison. Called
    Dirties until 2026-10-30.
  - Levers: `aoEffects` with both effects. Feasibility: hit code, proven. On V: `PlayerPoisoned`
    through the existing mapping.
- **Parts-pullers** (Rare; 12mm, .45)
  - A kill with this round leaves extra crafting components on the body.
  - The mod already adds to a body's loot at `EvaluateLootQuality` (`NpcAmmo`), so this adds a
    small stack of components of the round's grade to what's given back. Feasibility: existing
    hook, new code; needs a test that the killing round is known at loot time (Cook-off marks its
    kills the same way).
  - NPC side: no effect. V's body isn't looted. The one round with no NPC version (see Decisions).

**Arasaka: precision and control**

- **Kata** (Epic; .45, 5.56, 7.62, light rail)
  - House spec: every round the same. Very narrow damage roll, about 30% less recoil, about 30%
    faster aim-in.
  - Levers: roll band as Match, recoil, AimInTime (stats). Feasibility: stats and hit code, proven.
    It is close to Match, with handling instead of Match's price; check they read as different.
- **Kansatsu** (Epic; 10mm, 20mm, 25mm smart)
  - A hit tags the target. The shooter's team sees it, and smart rounds lock onto a tagged target
    at once.
  - Built as the fallback: the round halves lock time at all times (`SmartGunAdsTimeToLock`,
    `SmartGunHipTimeToLock`) and the tag (`AmmoOverhaul.PingTag`, Ping's) shows the target through
    walls. The tag and the lock aren't linked: the lock time stats are per gun, and the engine has
    no per-target lock time (see the probe results).
  - On V: V is tagged. NPCs don't act on it, so the NPC version is the short lock only.
- **Shinobi** (Epic; 9mm, .45)
  - Silent kills and +50% headshot damage, with 10% less range.
  - Levers: `CanSilentKill`, `HeadshotDamageMultiplier` (stats). Feasibility: stats,
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
   chance, then the rest below Epic in one roll, whatever their quality, so Scav rounds come up
   alike.
   It goes through the same path as any rolled round (`aoUncommonGuns`, selector
   stat modifiers on the gun), so the stats and hit code work with no new NPC code.
4. A miss falls through to the existing Epic, Rare and Uncommon rolls.

**Chance per gun, by rank** (`AmmoOverhaul.npcFactionChance.<rank>` for "Rare", meaning all below Epic,
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

Arasaka's rounds are all Epic, so it has its own Epic table in place of that column
(`npcFactionEpicChance.Arasaka.<rank>`): Weak 0, Normal 5%, Rare 10%, Officer 15%, Elite 20%, Boss
25%, MaxTac 0.

For scale: today Trash, Weak and Normal NPCs never roll a general Rare or Epic, and only Elite and
Boss roll a general Epic. These chances make faction rounds the most common thing above Uncommon in
that faction's fights. That is the point, and it also raises difficulty in those fights.

**Loot.** Nothing new. What's left of an NPC's stack is noted at death and given back as loot
(`NpcAmmo`, `EvaluateLootQuality`), so a faction round drops as a normal stack: a gun's magazines
by rank, less what was fired. This is V's main source.

**Containers.** None at first: a container has no known faction. `LootConvert` keeps rolling up to
Epic from general rounds, which excludes tiers 5 to 8.

**Turf gun shops**
- `Vendor.AOSplitAmmo` runs on every stock build and already knows `GetVendorType()` is Gunsmith.
- **Shops have no faction.** Dumped in the game 2026-10-30: all 266 vendors have
  `Faction()` = `Factions.Unaffiliated`, so it's no use. The mapping is by hand: a
  `Vendors.<shop>.aoFaction` flat in `core.yaml`, read with `GetVendorTweakID()`. Using V's district
  at stock time is worse: a stock can be built when V is elsewhere.
- Shop IDs carry their district. Approved by the user:
  - Maelstrom: `wat_nid_gunsmith_01` (Northside).
  - Arasaka: `cct_dtn_guns_01` (City Center, Downtown). Shinobi only, see the exception below.
  - Scavengers: `wat_kab_gunsmith_02` (Kabuki), `std_arr_gunsmith_01` (Arroyo).
- Rule: a turf shop has a 25% chance per stock build (`turfChance`) of one or two extra stacks
  (`turfStack`, 30 rounds) of that faction's rounds below Epic, not counting Common. Nobody sells
  Epic, with one exception: Arasaka's rounds are all Epic, so `cct_dtn_guns_01` sells Shinobi at the
  same chance in stacks of 10 (`aoTurfAmmo`, `aoTurfStack`), at its normal Epic price. That shop
  and that round only (the user's call). Reloads count as stock at any Scav turf shop, every caliber, every build.

**Same rules check.** All of the above only changes which round an NPC holds. Stats, jams, bleeds
and tags then work through the code every round uses. Parts-pullers is the one exception, noted
above.

## Art

Approved by the user and built in `tools/render` (`faction_art.py`, the faction forms in
`scene.py`), Blender and PIL only. Each is a new object, not a recolour. The decals are the game's
own, extracted by `tools/render/faction_textures.sh` and kept out of the repo.

- **Arasaka:** a black hard case, lid well open, with a red seam, red latches and a black lid label
  with the red crest and white wordmark. Black cases with the crest printed on the rounds, on the
  cassette's lid and the Ashura's nose where a wrap wouldn't read.
- **Maelstrom:** a black worn steel can, with a white skull stencil and the wordmark sprayed red,
  sized to the front wall. Black rounds with red bullets; Chrome-cookers' coils are red.
- **Scavengers:** a cut-down cardboard flat of mixed brass, steel and nickel, leaning loose. The
  caliber is scrawled on the front in a dying marker (drawn stroke by stroke, no font) over a dried
  bloody handprint and spatter.

## Everything else follows the existing pattern

- `tools/rounds/rounds.py` gains `faction=` and tiers 5 to 8; selectors, prices, icons and item
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
  - Kansatsu's short lock, and the tag not changing it;
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

## Decisions (the user, 2026-10-30)

1. **Tiers.** Reloads are Common quality because they're trash: an exception to "Common rounds are
   vanilla", for this one kind. Gutter Lead moved to Uncommon, and Shinobi and Chrome-cookers to
   Epic, after the field test.
2. **Sources.** NPC drops first, turf gun shops second. No crafting, no containers.
3. **Drop rates.** The chance list above.
4. **Parts-pullers.** Kept, with no effect when an NPC fires them.
5. **Kansatsu.** Probed; the engine can't do it, so the fallback stands. No faking from a script.
6. **Faction marking.** A short tag in brackets in the item name: [Mael], [Scav], [Ara]. The item
   text may mention the faction offhand but doesn't have to.
7. **Turf map.** The shop list above, approved.
8. **Round count.** 26.
9. **Release.** Faction rounds come in the version after 0.5.0.

## Probe results (2026-10-30, on the 0.5.0 base)

- **Kansatsu instant lock: fails, so the fallback stands.** Same gun, same target, 3.6 s lock time:
  4.54 s and 4.53 s to a full lock with no tag, 4.53 s and 4.54 s with the tag on. Lock time is a
  gun stat and the engine has no per-target lock stat, so a tag can't shorten it short of a script
  changing the gun, which the rules rule out. The round is lock time x0.5 at all times plus the tag.
- **Redliners jam on a swap: the jam stays on V.** Jammed on a Unity, V drew a Lexington on another
  round and was still jammed. The game's shooting gate reads Jam effects on V, not on the gun
  (`weaponTransitions`), so the second gun can't fire until the jam ends. Kept, and the text says
  "jam your weapons".
- **`WeaponNoise` is 0 on V's Unity as well as on NPC guns,** so x0.3 changes nothing. Shinobi and
  Subsonic drop the stat. Subsonic's quiet comes from its silenced shot and silent kills.

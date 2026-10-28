# Manufacturers and factions

Working notes for manufacturer and faction ammo. Two different things:

- **Manufacturer lines:** a brand's take on the standard ammo types (Militech AP, Budget Arms cheap
  FMJ). Sold and crafted like normal ammo.
- **Faction ammo:** what a group makes or is supplied with for itself. Stronger, with a clear
  personality, often with no blueprint anywhere in the game; mostly from that faction's bodies and
  stashes.

## What each faction carries in vanilla

From `tools/catalog/dump-factions.lua` (every character record's primary and secondary equipment,
pools followed; data in `reference/catalog/factions.tsv`). Counts weigh every pool entry, so
handguns (secondary pools) are over-represented; read the shares as a tendency.

| Faction | Power | Tech | Smart | Most carried |
|---|---|---|---|---|
| Scavengers | 60% | 28% | 10% | Nova, Unity, Burya, Grit, Guillotine, Pulsar, Quasar |
| Tyger Claws | 74% | 9% | 15% | Nova, Nue, Liberty, Saratoga, Masamune, Kenshin, Chao |
| 6th Street | 56% | 10% | 33% | Nova, Overture, Lexington, Liberty, Kappa, Chao, Yukimura |
| Maelstrom | 39% | 53% | 6% | Omaha, Unity, Quasar, Kenshin, Burya, Umbra, Sidewinder |
| Barghest | 56% | 38% | 5% | Lexington, Omaha, Grit, Copperhead, Kyubi, HMG |
| Arasaka | 44% | 19% | 36% | Nue, Yukimura, Kenshin, Kappa, Masamune, Satara |
| Voodoo Boys | 35% | 30% | 34% | Omaha, Unity, Quasar, Yukimura, Chao, Palica |
| Valentinos | 79% | 15% | 4% | Overture, Nue, Nova, Quasar, Liberty |
| Wraiths | 41% | 48% | 10% | Omaha, Unity, Quasar, Burya, Kenshin, Sidewinder |
| Animals | 45% | 43% | 11% | Nova, Quasar, Burya, Kappa |
| Militech | 66% | 25% | 8% | Omaha, Lexington, Umbra, Ajax, Kyubi, Crusher, HMG |
| NCPD | 75% | 10% | 14% | Lexington, Unity, Omaha, Ajax, Zhuo, Defender |
| Afterlife mercs | 56% | 17% | 26% | Nue, Kenshin, Kappa, Yukimura |
| Aldecaldos | 90% | 9% | 0% | Nova, Unity, Lexington, Quasar, Overture |
| The Mox | 87% | 12% | 0% | Lexington, Nova, Unity, Overture |
| Kang Tao | 19% | 1% | 79% | Chao, Dian, Zhuo, drones |
| Trauma Team | 24% | 0% | 75% | Yukimura, Dian, Masamune, Zhuo |
| Zetatech | 59% | 9% | 30% | Kappa, Chao, Yukimura, Omaha |
| Biotechnica | 76% | 19% | 4% | Nue, Ajax, Quasar |
| NetWatch | 52% | 20% | 28% | Nue, Lexington, Omaha, Yukimura |
| NUSA / FIA | 61% | 16% | 22% | Nue, Yukimura, Kenshin, Kappa, SOR-22, Achilles |
| Civilians | 97% | 2% | 0% | Unity, Nova |

Surprises against the lore: Scavengers carry a lot of Tech (Burya, Grit, Quasar) and some Smart
(Dian); Animals are nearly half Tech. Their faction ammo can still be crude: a Scav railgun fed
scrap slugs fits.

## Manufacturers

| Maker | Origin and vibe | Guns | Ammo line identity |
|---|---|---|---|
| Militech | US military giant; mil-spec, reliable, overkill | Lexington, Saratoga, Omaha, Ticon, Ajax, Achilles, Hercules, Crusher, Mk.31 HMG | armor-piercing, HE, tracer; consistent, no quirks below Rare; expensive |
| Arasaka | Japanese megacorp; precise, quiet, elite | Kenshin, Yukimura, Shingen, Masamune, Senkoh (with Jinguji) | match grade, subsonic, smart and rail precision; very expensive |
| Kang Tao | Chinese; smart guns only | Chao, Dian, Zhuo | smart payloads and guidance packages |
| Tsunami | Japanese; began with air guns; rail and competition guns | Nue, Kappa, Kyubi, Nekomata, Rasetsu, Ashura | dense and sabot rail slugs, smart darts |
| Techtronika | Russian; brute force, simple, reliable | Burya, Metel, Pozhar, Grad | hot powder: damage and recoil up, stamina cost; big, crude rail slugs |
| Rostović | Serbian budget; "frequently jams" | Kolac, Igla, Testera, Palica, Satara | cheap, strong for the price, jam chance as the standard quirk |
| Budget Arms | plastic, disposable, "discard after use" | Slaught-O-Matic, Guillotine, Carnage | cheapest; low damage or erratic spread; occasional duds |
| Constitutional Arms | American civilian and police guns | Unity, Liberty, Defender, Tactician | self-defense: hollow point, +P, beanbag |
| Darra Polytechnic | Indian; cheap and stylish | Nova, Quasar, Pulsar, Umbra | value loads, flashy tracers, birdshot rail loads (Quasar) |
| Midnight Arms | "strong and heavy" | SOR-22, MA70 HB, Erebus | heavy loads, magnum rifle, explosive LMG rounds |
| Nokota | Western mass-market | Copperhead, Sidewinder, Osprey | everyday rifle ball, big-bore sniper |
| Malorian Arms | boutique; Johnny's 3516, Overture | 3516, Overture | rare magnum craft loads; legendary only |
| Hansen Armory | Dogtown's own (Kurt Hansen) | Grit, Warden | Barghest surplus; rebuilt rail slugs |

## Factions

Each: tech level (what families it makes ammo for), what it values (perks it pays for) and accepts
(quirks), signature effects, reliability, and where its ammo comes from.

### Gangs

- **Maelstrom.** Chrome-obsessed. Tech-heavy (53% in vanilla), little Smart. *Values:* raw power,
  electric damage, EMP and cyberware disruption (frying chrome is their thing). *Accepts:* heat and
  instability: high variance, jam chance, overpressure damage to the shooter. Their ammo has the
  biggest bonuses in its tier and the widest swings (per-shot or per-reload re-rolls). Overcharge
  capacitor slugs. No blueprints.
- **Tyger Claws.** Japanese-styled, funded by Arasaka. *Values:* precision, crits, bleed (blade
  culture), quiet loads. Ammo mirrors Arasaka's lines as cheaper knock-offs: same effects, a step
  weaker, sometimes inconsistent (the off-brand Arasaka). Some genuine Arasaka stock leaks through
  as rare loot. Power plus some Smart and Tech (Kenshin, Chao).
- **Valentinos.** Flash and honor. Revolver culture (magnum). *Values:* headshots, crits,
  first-shot bonuses, showy incendiary. *Accepts:* recoil and noise. Engraved or gold-tipped
  rounds: crit-heavy, loud.
- **6th Street.** Veterans and militia, patriotic. Mil-surplus Militech gear, and a surprising
  share of Smart guns. *Values:* reliability, armor piercing, tracer for squad fire. *Accepts:*
  weight, cost. Steady, no randomness: surplus mil-spec at a discount.
- **Animals.** Strength culture. *Values:* stopping power, knockdown, stagger, big bores.
  *Accepts:* recoil, stamina cost, short range. Overpressure "bruiser" loads; slugs and beanbags
  that floor people.
- **Voodoo Boys.** Netrunners. Balanced across all three families. *Values:* hacks on hit (upload a
  quickhack, cyberware malfunction, comms jam), Smart hack-carriers. *Accepts:* low kinetic damage.
  Their ammo matters more for the effect than the hit.
- **Wraiths.** Desert raiders, scavenged military, Tech-heavy. *Values:* cheap damage, bleed and
  poison. *Accepts:* unreliability. Dirty, reloaded rounds: strong but erratic, jam chance.
- **Scavengers.** Kidnappers and organ harvesters. Junk ammo: reloaded brass and scrap slugs.
  *Values:* taking people alive and organs intact (tranquilizer and non-lethal rounds, headshot
  focus, low dismemberment), cheapness. *Accepts:* duds, jams, low damage. Little real Smart
  ammo; their Smart guns could carry crude "dumbfired" smart rounds (guidance broken).
- **The Mox.** Protectors of sex workers. Self-defense: non-lethal, stopping power, cheap pistols.
- **Aldecaldos.** Nomads. Handloaded, hunting and long-range rounds; reliable and frugal.
  *Values:* range, accuracy, reliability. *Accepts:* fewer exotic effects.
- **Barghest.** Kurt Hansen's Dogtown army, ex-military, Hansen Armory. *Values:* armor piercing,
  rebuilt rail slugs. *Accepts:* weight. Military, hard-hitting.

### Corporations and agencies

- **Arasaka.** Elite. Smart and rail precision, subsonic, match grade; top tiers with no blueprint.
  *Values:* precision, quiet, armor piercing. *Accepts:* cost only.
- **Militech.** Mil-spec. AP, HE, explosive 12.7mm, reliable. *Values:* armor piercing, explosives,
  consistency. *Accepts:* weight, noise.
- **Kang Tao.** Smart only (79%). Payloads and guidance packages: the best smart ammo.
- **Zetatech.** Electronics and optics. Tracking and tagging rounds, smart guidance firmware.
- **Biotechnica.** Bio and chemical: toxins, poison payloads, pathogen rounds.
- **NetWatch.** Anti-netrunner: rounds that disrupt cyberdecks and quickhack uploads, short-circuit
  netrunner cyberware.
- **Trauma Team.** Smart-heavy (75%). Fast suppression and protection: high hit probability,
  stun, non-lethal crowd control; reliable.
- **NCPD.** Heavy-hitting non-lethal: beanbag and rubber, taser shells, tracer. Standard issue is
  plain and reliable.
- **MaxTac** (NCPD's cyberpsycho unit). Anti-cyberpsycho: EMP, cyberware shutdown, armor piercing,
  overkill. Top tier, no blueprint.
- **NUSA / FIA** (Phantom Liberty). Spy and special-forces gear: subsonic, poison, tracking.
- **Afterlife mercs.** Professionals; custom handloads from many makers.

## Ideas this raises

- **Reliability as a stat of its own:** jam, dud and overpressure chances. Cheap makers and dirty
  factions pay with it; mil-spec never does. See "Jams and malfunctions" in `docs/MECHANICS.md`.
- **Variance as a trade:** Maelstrom-style re-rolls give a high top end in exchange for
  inconsistency. A wide damage range, or one weighted to an end: a shot does medium damage, a lot,
  or (a misfire) nothing at all. Other Maelstrom quirks: some shots cost extra stamina, or burn the
  wielder a little.
- **Knock-offs:** a faction line that mirrors a manufacturer's at a lower tier (Tyger Claws and
  Arasaka). It also gives cheap faction ammo for a reason.
- **Loot identity:** NPCs carry their faction's ammo, so a fight's loot says who you fought.

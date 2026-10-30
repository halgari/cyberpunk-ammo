# Ping rounds and cover-piercing Penetrators: design

Date: 2026-10-29. Status: designed in conversation and probed in the game; written for the
user's review.

The first part of slice 2 (`2026-10-29-rare-epic-slice1-design.md`, "Out of scope"). Five
rounds, each filling an empty slot in the 4 Rare / 4 Epic grid, so the mod goes from 130 rounds
to 135:

- **Ping**, Rare: 7.62 and 12.7. It tags the target it hits.
- **Penetrator**, Epic: 12mm, 7.62 and 12.7. Unlike the 9mm, .45 and 5.56 Penetrator, it goes
  through cover.

## Binding rules (unchanged)

- NPCs and V follow the same rules. A round does the same thing whoever fires it.
- Common rounds stay vanilla. No automatic ammo switching.
- Rare carries one small drawback. Epic is a straight upgrade; price and scarcity are its cost.
- Item text: slang names, plain gun-counter descriptions, no invented lore; the effect lines
  after a blank line.

## Probe results (2026-10-29, played by the user)

1. **A Power gun pierces cover with the Tech pierce stats.** On an Ajax:
   `TechPierceEnabled` +1, `TechPierceChargeLevel` x0, `TechPierceDamageFactor` +0.5. Shots went
   through a car and hit the enemy behind it. The bullets look like normal bullets, not a Tech
   shot. With the stats removed, the car stopped every shot.
2. **Hawk's tag outlines a target through walls.** `BaseStatusEffect.KyubiMyersTag` (tags
   `Debuff`, `AutoTag`; 15 s) applied to a hostile NPC showed it glowing through cover.
3. **The pierce stats take on an NPC's gun** (a Tyger Claw's Liberty). NPCs only fire at what they
   can see, so they don't aim through cover on purpose. Shots that were already on their way
   seemed to get through. The automated check below confirms it.

## The rounds

**Penetrator** (Epic; 12mm, 7.62, 12.7)
- Stats on the selector part: ignores 60% of armor (`armor(0.60)`, as the other Penetrator);
  `TechPierceEnabled` +1; `TechPierceChargeLevel` x0; `TechPierceDamageFactor` -0.5.
  (Corrected from +0.5, the probe's value, 2026-10-29: damage through cover is times
  1 + `TechPierceDamageFactor` (`DamageSystem.ProcessPierceAttack`), and a Power gun has 0, so
  +0.5 gave 1.5x, not half. The probe never measured damage; half is the intended design.)
- Every shot goes through the cover a charged Tech shot goes through, at half damage on the far
  side.
- Text: "Tungsten-core rounds. They punch through armor and thin cover.\n\nIgnores 60% of
  armor. Goes through thin cover at half damage."
- Art: as the other Penetrator (black tip, spitzer nose).

**Ping** (Rare; 7.62, 12.7). Planned as "Tracer"; renamed by the user, since it tags targets
rather than drawing a visible trace.
- On hit, applies `AmmoOverhaul.PingTag` at chance 1 through the existing on-hit effects
  (`aoEffects`, `aoEffectChances`).
- `AmmoOverhaul.PingTag` is a new status effect record based on
  `BaseStatusEffect.KyubiMyersTag`, with a 5 s duration.
- Drawback: -10% damage (`damage(0.90)`); the tag takes up room in the bullet.
- Text: "Rounds with a tag chip in the nose. Whatever they hit shows up on your optics for a
  few seconds, through walls.\n\nTargets hit show through walls for 5 seconds. -10% damage."
- Art: a teal tip.

**NPCs**
- NPC guns already get a round's selector stats at runtime (`NpcAmmo`, `AddModifier` with the
  selector's modifiers), so the pierce stats reach NPC guns without new code.
- An NPC's Ping hit applies the tag to V through the same hit code. V already knows the NPC
  is there, so V sees nothing new. If the tag misbehaves on the player (a visual glitch or an
  error), the hit code skips it for the player, and the item text stays the same.

## Everything else follows the existing pattern

- The rounds are added in `tools/rounds/rounds.py`, which generates the records, selectors,
  text, art list and refs. The cover-piercing Penetrator is its own entry (the same `load` name,
  different stats and text) for 12mm, 7.62 and 12.7.
- Selectors, shop and loot shares (each tier's share is split among its rounds), NPC tiers,
  prices and a crafting recipe for each round come from the existing generators
  (`tools/crafting/crafting.py`).
- Icons are rendered in Blender, like the rest (`tools/render`).
- The banner goes from 13 x 10 to 15 x 9 boxes (`tools/render/banner.py`). The title render is
  reused.
- Docs: `docs/CATALOG.md`, `docs/DESIGN.md`, `README.md` and `docs/NEXUS.md` (counts and the
  round list), plus `CHANGELOG.md`.

## Testing

- **Offline:** the generators' own tests and the compile check (`check.sh`).
- **Records** (`calibers/records.lua` and the parity checks): the five rounds exist with the
  stats above, the counts are 135, and each has a recipe and an icon.
- **Live, on the hit rig, one check per mechanism:**
  - a Ping hit puts `AmmoOverhaul.PingTag` on the target, and it's gone after about 5 s;
  - an NPC gun given the cover-piercing Penetrator has `TechPierceEnabled` 1;
  - an NPC firing it through the rig's cover hits the target behind it.
- **The user's playtest:**
  - a Penetrator goes through a car with an Ajax and a Grad;
  - a Ping hit outlines the target through walls, for about 5 s;
  - an NPC Ping hit on V does nothing strange.

## Out of scope

The rest of slice 2: Tungsten slug, Kinetic penetrator, Gas and Gas canister, Micro-grenade,
smart HE, Splitter, Capacitor.

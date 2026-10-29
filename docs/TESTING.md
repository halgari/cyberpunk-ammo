# Ammo Overhaul PoC: test guide

## Install

Needs Cyberpunk 2077 2.50 (exe 3.0.88.46235) with RED4ext 1.31, TweakXL 1.12, ArchiveXL 1.28,
Codeware 1.21, CET 1.38 and redscript 0.5.32 or newer of each.

Extract `AmmoOverhaul.zip` into the game folder (the one containing `bin` and `r6`). It adds
`r6\scripts\AmmoOverhaul`, `r6\tweaks\AmmoOverhaul` and `red4ext\plugins\AmmoOverhaul`. Delete
those three folders to uninstall.

## Get the test items (CET console)

Load a save with a free inventory slot, open the CET overlay, then in the Console tab:

```lua
for _, id in ipairs({ "Items.Preset_Lexington_Default", "Items.Preset_Omaha_Default", "Items.Preset_Yukimura_Default",
    "Items.AO_Feed_9mm_Ball", "Items.AO_Feed_9mm_Mushrooms", "Items.AO_Feed_5mm_RailSlugs",
    "Items.AO_Feed_5mm_Sleevers", "Items.AO_Feed_10mm_Seekers", "Items.AO_Feed_10mm_Dumbfires" }) do
  Game.AddToInventory(id, 1)
end
for _, id in ipairs({ "Ammo.HandgunAmmo", "Ammo.AO_9mm_HollowPoint", "Ammo.AO_TLight_Slug",
    "Ammo.AO_TLight_Sabot", "Ammo.AO_S10_Standard", "Ammo.AO_S10_Dumbfire" }) do
  Game.AddToInventory(id, 60)
end
```

Any other caliber works the same way: its gun preset (`Items.Preset_Unity_Default`, …), its two
selectors (`Items.AO_Feed_45_Ball`, `Items.AO_Feed_45_Mushrooms`, named as in `docs/CATALOG.md`,
Built) and its rounds (the `selectorAmmo` list in its `src/tweaks/AmmoOverhaul/*.yaml`).

Use newly spawned guns: one already in an old save may keep its old slot layout.

## Test kit (CET window)

With the dev helpers installed (`tools/linux/dev-install.sh`), opening the CET overlay also opens
an "Ammo Overhaul test kit" window:

- Buttons spawn hostile enemies in front of you by gun type (handgun, SMG, rifle, shotgun,
  sniper, dual wield, HMG), plus a Mushrooms Lexington, a Sleevers Omaha and a Dumbfires
  Yukimura ganger, each carrying only that gun with its Uncommon selector fitted. "How many" and "Distance" set the group. They turn hostile wherever
  you are.
- "Invulnerable" (on by default) keeps you alive for long running-dry tests; untick it for a
  real fight.
- "Kill test enemies" kills them for loot checks; "Remove test enemies" deletes them.
- "Give slice kit" gives the Lexington, Omaha and Yukimura, all six selectors and 60 of each
  round.
- Below that: your ammo, each test enemy's status, distance, gun, magazine and ammo carried
  (updated twice a second), and the mod's latest log lines.
- Hotkeys you can bind in the overlay's Hotkeys tab: spawn handgun / rifle / shotgun enemy,
  kill, remove.

## Icons

`tools/icons/build.sh` rebuilds `src/archive/AmmoOverhaul.archive` from `art/icons` (needs
`tools/wolvenkit` (WolvenKit.ConsoleLinux) and `tools/wolvenkit-win` (WolvenKit.Console, run on
Proton with the .NET 10 runtime in the tools prefix)). `icons.lua` checks the records and that the
game finds the atlas.

The art is rendered in Blender 5.2 (Cycles, on the GPU), one box shot per round:

```sh
tools/render/assets.sh                         # once: CC0 scans (ambientCG) and a studio HDRI (Poly Haven)
python3 tools/render/render.py                 # all 26 rounds to art/icons/<round>.png
python3 tools/render/render.py --rounds --only 9mm-ball,20mm-seekers --out /tmp/x   # with close-ups
tools/icons/build.sh                           # atlas and archive
```

Blender comes from `$BLENDER` or `~/.cache/ammo-overhaul/blender/blender-*/blender`. `render.py`
holds the round table (name, shape, box colour and stripe, the label) and draws the box print;
`scene.py` models the round, the open box and the lighting. Smart rounds follow the game's own
models: 10mm after the Kang Tao Dian projectile, 20mm as a Palica-style eight-cell cassette, 25mm
after the Ashura round. All 26 render in about two minutes.

Square, not landscape: the backpack tile shows only the centred square of an icon's cell, so
`make_icons.py` fits the art edge to edge into a square cell, as the game's own icons are (mostly
160×160 parts cropped tight to the art). The game draws a part at its pixel size in the atlas's 4K
texture rather than scaling it to the slot, so cells are vanilla's 160×160: the atlas is 1024×1024,
6 × 5 cells; a round's
part is `ao_` + its art name (`9mm-ball` → `ao_9mm_ball`). The atlas build also lifts the midtones
(`LIFT`) so the renders match the game's icon brightness.

## What to check

The slice checklist. The automated part is the snippets in `tools/snippets/slice/` (listed under
each step); the rest needs a person at the game. Give yourself the kit first (test kit window →
"Give slice kit").

1. **Weapon screen.** Inventory → a Lexington, Omaha or Yukimura: the sections read Attachments,
   Ammo, Mods. The feed slot is only under Ammo and shows the fitted round's icon (an ammo icon
   when empty). It works with mouse and controller. Then run `section.lua`. Any 9mm, 5mm or 10mm
   handgun or SMG (Kenshin, Grit, Pulsar, Chao...) has the slot, and an Uncommon round fits a
   Common gun (`rarity.lua`, `rarity2.lua`).
2. **Switching rounds.** Each gun loads, fires and counts its default round. Fitting a selector
   switches the stack, unloads the gun and changes the HUD count and icon. (`records.lua` checks
   the records; the HUD is by eye.)
3. **9mm Mushrooms.** Shoot an unarmored and an armored enemy with Ball, then Mushrooms: Mushrooms
   should hit harder on the unarmored one and worse on the armored one. (`uncommon.sh` checks the
   stats.)
4. **5mm Sleevers.** The Omaha charges in about 1.05 s instead of 1.5 s (`uncommon.sh` checks the
   stat).
5. **10mm Dumbfires.** Shots fly straight at a moving enemy off to the side; Seekers curve.
   (`uncommon.sh` checks hit probability 0 and damage ×1.8.)
6. **NPCs.** `npc.sh`: each test ganger carries and drops only its gun's round; with the roll
   forced on, plain gangers carry the Uncommon. In a normal fight, gangers with an Omaha or
   Yukimura drop 5mm or 10mm rounds.
7. **Vendors.** A gun shop lists all six rounds, about half of the handgun ammo as 9mm Ball. Other
   vendors sell no Uncommon. (`vendors.lua` with `VENDOR=1`.)
8. **Loot.** Open a few unlooted containers: handgun ammo in them shows the new names. With only a
   Lexington carried, most of it is 9mm. (`loot.lua`, `lootfill.lua` then `lootfill2.lua`.)
9. **Saves.** Save and reload: fitted selectors, stacks and opened containers stay as they were.

### v1 calibers

The automated checks are in `tools/snippets/calibers/` (`check.sh <file>` runs a `.lua` one):

- `records.lua`: every caliber's rounds and selectors (names, weights, prices), its guns load its
  Common round and carry its feed slot. Rare and Epic rounds too: quality, x4 / x8 price, weight, text, icon,
  selector tags, no damage-type or machine stats on a selector, valid hit data, all 91 listed.
  Run it with the generator's stat list in front:
  `PRE="AO_REFS={$(sed 's/.*/"&",/' tools/rounds/refs.txt | tr -d '\n')};" check.sh calibers/records.lua`.
- `tiers.lua`: tier shares, prices, vendor and loot caps (gun shops up to Rare, loot up to Epic),
  and the NPC tier roll by rank. It blocks the game for about a minute:
  `CET_T=240 FROZEN_AFTER=240 check.sh calibers/tiers.lua`.
- `hitdata.lua`: every round's hit data (effects and chances, damage share, machine bonus,
  non-lethal) reads as its YAML says; the old `ammoEffects` list is gone. `hitdata.sh`: the same
  on live hits with a test round (burns, half Thermal, x2 on machines, non-lethal): V on a ganger,
  a ganger on V (V gets PlayerBurning), V's killing shot knocks out (Unconscious) where Ball's
  doesn't, V on an android (draws guns: not while you play). Also each player effect swap and the
  per-pellet chance.
- `vanilla.lua`: no gun carries a stat change; Common rounds fire like vanilla ammo.
- `distribution.lua`: each vanilla ammo item splits in the shares of `docs/DESIGN.md`; with
  `PRE="VENDOR=true;"` gun shops split their rifle, sniper and shotgun ammo too.
- `npc.sh`: one test NPC per new caliber carries and drops its gun's round, and the Uncommon one
  when the roll is forced on.
- `slugs.sh`: every shotgun fires one projectile with Slugs, with tighter spread and twice the
  range (draws weapons: not while you play).
- `icons.lua`: every round and selector has its own icon in the atlas.
- `lootdupe.lua`: a body knocked out, looted and then killed gives its ammo back once, not
  twice. `lootcap.lua`: a body leaves at most `npcLootWeight` carry points of a round (1200
  rounds of 12.7 leave 40). Both spawn a test NPC on the first run; run them again once it loads.

- `uncommon2.sh`: each second Uncommon (+P, Birdshot, 4ga Birdshot, Bricks, Short-Fuse) changes
  its gun's stats as `docs/CATALOG.md` says (draws weapons: not while you play).
- `roll.lua`: the damage roll's layers (round, faction, family, global, per damage type), its
  draws (5000 each), the cached caliber of every weapon record, and the tooltip range of a drawn
  Unity (draw it first).
- `rig.lua` / `rig.sh`: the hit rig, a frozen invulnerable test NPC in front of V on the open road
  by the test save's load point, logging every hit's damage before and after the roll. Police
  are locked off while it runs; it reloads, respawns a stray NPC and checks line of sight. Before
  each shot it turns V to face the NPC and pitches the camera at its chest, and fires only when
  the game's look-at target is the NPC (what turns the crosshair red); only hits on that NPC count.
- `roll.sh`: the roll on real hits: V's .45 Ball, the test round's duds and hot rounds, Crusher
  pellets, and the NPC's hits on V. V's shots follow V's camera, so the rig pitches it at the
  NPC's Chest slot before each shot (a level camera fires over a crouching NPC). If it fails, read
  the FAIL lines: a short hit count is the rig, a ratio out of range is the roll.
- `parity.lua`: each round's NPC damage factor from its selector record (Mushrooms 1.2, Dumbfires
  1.8, 4ga Slugs 1.3, Common 1.0). `parity.sh`: the same on live hits with the rig: a Mushrooms
  ganger hits V for 1.2x the roll, a Common one the plain roll, V's own Mushrooms hits roll once;
  every other stat a round changes, read off an NPC's gun in hand (Uncommon, and one Rare or Epic
  round per new stat, with the roll forced to that tier); NPC Birdshot and Slug shots
  land about as hard per shot as Common. Takes about 7 min. The suite runs it last without gating:
  a Crusher phase can lose its NPC when the rig respawns its own on lost line of sight ("no
  Crusher with ProjectilesPerShot ..."), which is the rig, not the parity.
- `sync.sh`: the hidden selectors follow the ammo held: one loose selector per round with at least
  1 round, none at 0, the same round on two guns, a run-out round stays fitted, an open mod screen
  updates (fits guns and opens menus: not while you play).
- `hidden.lua`: selectors are tagged `HideInBackpackUI`, weigh 0, are left out of the backpack's
  item map and a vendor's sell list, and still listed on a gun's mod screen. Hold a selector
  before running it (the suite gives Mushrooms rounds first).
- `tools/linux/game-shot.sh out.png`: a screenshot of the game from a headless Hyprland output,
  without touching the screen you're using (`--remove` puts the game back on a real monitor).
- `tools/icons/check_parts.py`: every `UIIcon` part in the YAML has a cell in the built atlas.

By hand:

10. **Buckshot against Slugs.** With a Crusher or Tactician, fire both at an enemy at 5 m and at
    25 m. Buckshot spreads and falls off; Slugs put one hole where you aim and still hit hard at
    25 m.
11. **4ga Slugs.** A Carnage with 4ga Slugs knocks a ganger down on a hit, kicks clearly harder
    than 4ga Buckshot and does better against an armored enemy. It does not shoot through cover.
12. **Icons.** The backpack, the weapon screen's Ammo section and the HUD show each round's own box
    art, and the four vanilla stacks show 9mm Ball, 5.56 Ball, 12.7 Ball and Buckshot.

13. **Birdshot against a group.** Birdshot and 4ga Birdshot spread wide, make several gangers
    flinch at once and do little to an armored one.
14. **Short-Fuse at range.** A Short-Fuse rocket hits harder than a Seeker up close and doesn't
    reach a target 50 m away (its reach is 40 m).
15. **A Very Hard fight.** Damage rolls feel steady, a little weaker than vanilla, from you and
    from enemies alike.
16. **Selectors stay hidden.** Pick up a new round: the backpack, the stash, a vendor's sell tab
    and the crafting and dismantle screens show no selector, but the gun's Ammo slot lists the
    round. Fit it on two guns of that caliber. Shoot one dry: it stays on that round at 0 until you
    pick another.
17. **Old save.** Load a save from before this change that holds selectors: after loading, the
    backpack shows none, and each gun's Ammo slot lists one entry per round you hold.

Rare and Epic rounds (spawn them with `Game.AddToInventory('Ammo.AO_<caliber>_<Load>', 60)`; the
names are in `docs/CATALOG.md`):

18. **Icons.** Hold a Rare and an Epic 9mm round (Steel-Core, Match). A Lexington's Ammo slot
    lists both with their own box art, and the backpack shows it too.
19. **Machine bonus.** Shoot a drone or a mech with 12.7 HEI, then with 12.7 Ball. HEI hits clearly
    harder (x1.5). (`hitdata.sh` measures it on a security android; check the record it spawns
    really looks like one.)
20. **Burning from an NPC.** Spawn `Character.AO_Test_Ganger_9mm_HitData` with the test kit and let
    it shoot you: you catch fire, and part of each hit is fire damage.
21. **Non-lethal.** Finish a ganger with 9mm Rubber or 12ga Beanbags: it goes down unconscious, not
    dead.
22. **Superconductor.** A Tech rifle or the Omaha with Superconductor fires full auto once fully
    charged.
23. **Hunter.** A Yukimura or another smart gun with Hunter locks two more targets, and faster.
24. **Through cover.** With an Omaha, DU Penetrator goes through cover at about half charge and
    hits harder through it than Rail Slugs; Split Slugs never go through.
25. **Gun shop.** A gunsmith's stock has some Rare rounds and no Epic ones. Rare stacks are small
    (a few rounds of each), so a shop can show none of some Rares.

For each step, note pass or fail and what you saw.

## Logs

Afterwards, run `collect-logs.ps1 -GameDir "<your game folder>"` (keep `zip.ps1` next to it; it
writes `AmmoOverhaul-logs.zip` to the desktop) and send the zip. Lines from this mod are tagged
`AmmoOverhaul`: weapons patched and character drops turned off at startup, then `takes …`,
`ammo field located at …`, `engine restored …`, `redraw: …`, and for NPCs `stocked …`,
`out of …`, `leaves …`. In game, the last lines can also be read from CET:
`print(Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem"):Trail())`.

## Linux dev loop (Lutris / GE-Proton)

`tools/linux/` drives a GOG install under Lutris. Windows tools run on GE-Proton, never system
wine, and never in the game's prefix (`common.sh` has the paths).

- `check.sh`: offline compile against `reference/final.redscripts.vanilla`; exits 1 on failure.
- `deploy.sh [--no-check]`: runs `check.sh` first (a failed in-game compile disables every
  script mod), then copies the scripts and tweaks into the game.
- `build-native.sh <Name> [--deploy]`: cross-builds `native/<Name>` into
  `build/native/<Name>.dll` with clang-cl, lld-link, xwin and the RED4ext SDK (setup in the
  script's header); `--deploy` copies it to `red4ext/plugins/<Name>/`.
- `dev-install.sh [--remove]`: autoload of `ManualSave-900`, intro skip, the CET harness.
- `restart-game.sh`: kill, relaunch, wait until a save is loaded. The game lands unfocused on
  workspace 10 (Hyprland rule in `~/.config/hypr/cyberpunk.lua`). Script and plugin changes need
  a restart.
- `cet.sh 'lua' | -f file.lua [-t secs]`: run Lua in the game. Snippets in `tools/snippets/`:
  - `feed-kit.lua`: the slice kit, then `GUN=` (default the Lexington preset) equipped and
    drawn; run twice.
  - `set-feed.lua`: `FEED='Items.AO_Feed_9mm_Mushrooms'` installs, `FEED=nil` removes the one in
    `SLOT=` (`cet.sh "FEED='…'; $(cat tools/snippets/set-feed.lua)"`).
  - `ammo-state.lua`: inventory counts and the drawn gun's magazine and total (the total is the
    loaded ammo's count; `recordAmmo` is only the record's).
  - `slice/*.lua`: the slice checks, each printing PASS/FAIL lines; run with `common.lua` in
    front: `cet.sh "$(cat tools/snippets/slice/common.lua tools/snippets/slice/<check>.lua)"`.
    `rarity.lua` then `rarity2.lua` fit an Uncommon selector into a Common Kenshin.
    `vendors.lua` checks the distribution maths; with `VENDOR=1` set in front it also restocks
    every vendor the save knows of (twice) and checks their ammo. `loot.lua` converts ammo given
    to the nearest container; `lootfill.lua` then `lootfill2.lua` (a few seconds apart) teleport
    to an unfilled container, look at it so it fills, check the fill event marked it, and
    teleport back.
  - `npc-spawn.lua`: spawns a tagged NPC (`REC=` picks the record) 8 m ahead and makes the player
    invulnerable. `npc-state.lua`: each test NPC's gun, magazine and ammo; `FIGHT=true` makes
    them hostile.
  - `mod-check.lua`, `vanilla-gun-kit.lua`.
- Scripted shots: queue `WeaponConsumeMagazineAmmoEvent` on the weapon (takes inventory like a
  shot). Native reload: `weapon:StartReload(0.5)`, then `StopReload(gameweaponReloadStatus.Standard)`.
- `ModLog` lines land in CET's `bin/x64/plugins/cyber_engine_tweaks/gamelog.log`, flushed late
  (often at exit); use the trail above instead.
- Synthetic input doesn't reach the game: Hyprland's `send_key_state` to the game window did
  nothing. Anything that needs real firing, aiming or menus is a manual step.

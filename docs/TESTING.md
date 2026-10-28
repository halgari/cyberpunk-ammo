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

## What to check

Equip the new Lexington and draw it.

1. **Default ammo.** With the feed slot empty, the HUD reserve shows your handgun ammo, and
   firing uses up `Ammo.HandgunAmmo`.
2. **Slot shows.** In Inventory → the Lexington → mods, there's an "Ammo Feed" slot, empty at
   first and labelled "Ammo Feed: standard rounds". Clicking it lists only the two "Ammo Feed:
   9mm …" items; vanilla mod slots don't list the selectors.
3. **Swap and remove.** Install FMJ, swap it for Incendiary, then remove it. Each change should
   work, and a replaced selector should go back to the inventory.
4. **Switching types unloads.** Fire a few FMJ rounds, then install Incendiary. After closing the
   menu the gun is holstered and redrawn with an empty magazine and reloads from the 30
   incendiary rounds. The unfired FMJ rounds should still be in the FMJ count. On the first swap
   after loading a save the HUD may show a full magazine for a moment: fire once, and the gun
   should click empty and reload instead of firing.
5. **Consumes the selected type.** Fire incendiary rounds: `Ammo.AO_9mm_Incendiary` goes down by
   the same amount and FMJ doesn't change. With all 30 used, the gun doesn't reload from FMJ.
6. **On-hit effect.** Shoot an enemy with incendiary rounds: they catch fire on every hit
   (chance 1.0 for this test). FMJ rounds don't.
7. **Save and load.** Save with Incendiary installed and a part-used magazine, reload: the
   counts are unchanged and the gun still fires incendiary rounds.
8. **Ammo in the backpack.** Inventory → backpack lists your ammo stacks.
9. **Ammo weight.** Your carried weight includes ammo (handgun 0.06, rifle 0.04, shotgun 0.12,
   sniper 0.2 per round) and changes as you fire and pick up rounds.
10. **NPCs use real ammo.** In a normal gang fight, enemies eventually run dry if you stay in
    cover: they switch guns, then fight without guns (melee, or back off). Note anything odd,
    such as an enemy standing still aiming, a quest fight that stalls, or allies running dry.
11. **NPC loot.** Loot a body: the ammo it had left is in its loot (no extra random ammo), and its
    gun drops as usual.
12. **NPC special ammo.** Spawn the "Incendiary Lexington ganger" with Invulnerable off: its hits
    set you on fire, and its body drops only incendiary rounds (no standard handgun ammo).

For each check, note pass or fail and what you saw, especially the counts.

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
    every vendor the save knows of (twice) and checks their ammo.
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

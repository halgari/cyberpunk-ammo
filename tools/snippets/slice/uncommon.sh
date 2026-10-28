#!/usr/bin/env bash
# Task 2 driver: for each slice gun, draw it, fit the Common selector, store its stats, fit the
# Uncommon selector and compare (uncommon.lua). Draws weapons: only when the user isn't playing.
set -euo pipefail
cd "$(dirname "$0")/../../.."
C=tools/linux/cet.sh; S=tools/snippets
run() { $C -t 30 "MODE='$1'; $(cat $S/slice/common.lua $S/slice/uncommon.lua)"; }
for g in "Lexington 9mm_Ball 9mm_Mushrooms" "Omaha 5mm_RailSlugs 5mm_Sleevers" "Yukimura 10mm_Seekers 10mm_Dumbfires"; do
  set -- $g
  # The first run after a load only hands out the kit; the second equips and draws.
  $C "GUN='Items.Preset_$1_Default'; $(cat $S/feed-kit.lua)" | grep -q "gave the slice kit" && sleep 1 &&
    $C "GUN='Items.Preset_$1_Default'; $(cat $S/feed-kit.lua)" >/dev/null
  # Wait for the draw (the first one after a load can take several seconds).
  for _ in $(seq 1 20); do
    $C -t 5 "local w = Game.GetPlayer():GetActiveWeapon(); return w and TDBID.ToStringDEBUG(w:GetItemID().id) or 'none'" 2>/dev/null | grep -q "$1" && break
    sleep 1
  done
  sleep 2
  $C "FEED='Items.AO_Feed_$2'; $(cat $S/set-feed.lua)" >/dev/null; sleep 6
  run base
  $C "FEED='Items.AO_Feed_$3'; $(cat $S/set-feed.lua)" >/dev/null; sleep 6
  run check
done

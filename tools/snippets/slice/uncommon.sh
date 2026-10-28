#!/usr/bin/env bash
# Task 2 driver: for each slice gun, draw it, fit the Common selector, store its stats, fit the
# Uncommon selector and compare (uncommon.lua). Draws weapons: only when the user isn't playing.
set -euo pipefail
cd "$(dirname "$0")/../../.."
C=tools/linux/cet.sh; S=tools/snippets
run() { $C -t 30 "MODE='$1'; $(cat $S/slice/common.lua $S/slice/uncommon.lua)"; }
for g in "Lexington 9mm_Ball 9mm_Mushrooms" "Omaha 5mm_RailSlugs 5mm_Sleevers" "Yukimura 10mm_Seekers 10mm_Dumbfires"; do
  set -- $g
  $C "GUN='Items.Preset_$1_Default'; $(cat $S/feed-kit.lua)" >/dev/null; sleep 4
  $C "FEED='Items.AO_Feed_$2'; $(cat $S/set-feed.lua)" >/dev/null; sleep 6
  run base
  $C "FEED='Items.AO_Feed_$3'; $(cat $S/set-feed.lua)" >/dev/null; sleep 6
  run check
done

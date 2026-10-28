#!/usr/bin/env bash
# For each shotgun: draw it, fit Buckshot, store its stats, fit Slugs and compare (slugs.lua).
# Draws weapons: only when the user isn't playing. Exits 1 on any FAIL.
set -uo pipefail
cd "$(dirname "$0")/../../.."
C=tools/linux/cet.sh; S=tools/snippets; out=""
run() { $C -t 30 "MODE='$1'; $(cat $S/slice/common.lua $S/calibers/slugs.lua)"; }
out+="$(run static)"$'\n'
for g in "Crusher 12ga" "Pozhar 12ga" "Tactician 12ga" "Igla 12ga" "Testera 12ga" "Carnage 4ga"; do
  set -- $g
  $C "Game.AddToInventory('Items.Preset_$1_Default', 1); Game.AddToInventory('Items.AO_Feed_$2_Buckshot', 1); Game.AddToInventory('Items.AO_Feed_$2_Slugs', 1)" >/dev/null
  sleep 1
  $C "GUN='Items.Preset_$1_Default'; $(cat $S/feed-kit.lua)" >/dev/null
  for _ in $(seq 1 20); do
    $C -t 5 "local w = Game.GetPlayer():GetActiveWeapon(); return w and TDBID.ToStringDEBUG(w:GetItemID().id) or 'none'" 2>/dev/null | grep -q "$1" && break
    sleep 1
  done
  sleep 2
  $C "FEED='Items.AO_Feed_$2_Buckshot'; $(cat $S/set-feed.lua)" >/dev/null; sleep 6
  run base >/dev/null
  $C "FEED='Items.AO_Feed_$2_Slugs'; $(cat $S/set-feed.lua)" >/dev/null; sleep 6
  out+="$(run check)"$'\n'
done
echo "$out"
p=$(grep -c '^PASS' <<<"$out"); n=$(grep -c '^FAIL' <<<"$out")
echo "== slugs: $p pass, $n fail"
(( n == 0 && p > 0 ))

#!/usr/bin/env bash
# For one gun per second Uncommon: draw it, fit the Common selector, store its stats, fit the
# second Uncommon and compare (uncommon2.lua). Draws weapons: not while the user plays.
# Exits 1 on any FAIL.
set -uo pipefail
cd "$(dirname "$0")/../../.."
C=tools/linux/cet.sh; S=tools/snippets; out=""
run() { $C -t 30 "MODE='$1'; LOAD='$2'; $(cat $S/slice/common.lua $S/calibers/uncommon2.lua)"; }
#   gun preset, Common selector, second Uncommon selector, load
for g in "Lexington 9mm_Ball 9mm_PlusP PlusP" "Crusher 12ga_Buckshot 12ga_Birdshot Birdshot" \
         "Carnage 4ga_Buckshot 4ga_Birdshot Birdshot4" "Omaha 5mm_RailSlugs 5mm_Bricks Bricks" \
         "Yukimura 10mm_Seekers 10mm_ShortFuse ShortFuse"; do
  set -- $g
  # The selector sync keeps a selector only while its ammo is held: give 60 of each round too.
  $C "Game.AddToInventory('Items.Preset_$1_Default', 1)
for _, sel in ipairs({'Items.AO_Feed_$2', 'Items.AO_Feed_$3'}) do
  Game.AddToInventory(sel, 1)
  for _, cal in ipairs(TweakDB:GetFlat('AmmoOverhaul.calibers')) do
    local ammo = TweakDB:GetFlat('AmmoOverhaul.'..cal..'.selectorAmmo')
    for i, s in ipairs(TweakDB:GetFlat('AmmoOverhaul.'..cal..'.selectors')) do
      if TDBID.ToStringDEBUG(s) == sel then Game.AddToInventory(TDBID.ToStringDEBUG(ammo[i]), 60) end
    end
  end
end" >/dev/null
  sleep 1
  for _ in $(seq 20); do
    $C "GUN='Items.Preset_$1_Default'; $(cat $S/feed-kit.lua)" >/dev/null
    sleep 2
    $C -t 5 "local w = Game.GetPlayer():GetActiveWeapon(); return w and TDBID.ToStringDEBUG(w:GetItemID().id) or 'none'" 2>/dev/null | grep -q "$1" && break
  done
  sleep 2
  $C "FEED='Items.AO_Feed_$2'; $(cat $S/set-feed.lua)" >/dev/null; sleep 6
  run base "$4" >/dev/null
  $C "FEED='Items.AO_Feed_$3'; $(cat $S/set-feed.lua)" >/dev/null; sleep 6
  out+="$(run check "$4")"$'\n'
done
echo "$out"
p=$(grep -c '^PASS' <<<"$out"); n=$(grep -c '^FAIL' <<<"$out")
echo "== uncommon2: $p pass, $n fail"
(( n == 0 && p > 0 ))

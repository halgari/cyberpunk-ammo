#!/usr/bin/env bash
# Does a single-projectile round tighten the whole shot? On a Crusher and a Tactician: every spread
# stat with Buckshot against Slugs and Pump N Dump (spread.lua). Stats only: the rig's shots (AIWeapon.Fire)
# ignore spread, so a hit group proves nothing there (x25 spread landed the same 25 of 25 at 30 m).
#   tools/linux/game-lock.sh tools/snippets/calibers/spread.sh
# Draws guns: not while the user plays. Exits 1 on any FAIL.
set -uo pipefail
cd "$(dirname "$0")/../../.."
C=tools/linux/cet.sh; S=tools/snippets; out=""
sp() { $C -t 30 "$(cat $S/slice/common.lua $S/calibers/spread.lua); $1" 2>&1 | sed -n 's/^=> //p' | tail -1; }
fit() { $C "FEED='Items.AO_Feed_12ga_$1'; $(cat $S/set-feed.lua)" >/dev/null; sleep 6; }
draw() {
  $C "GUN='$1'; $(cat $S/feed-kit.lua)" >/dev/null
  for _ in $(seq 1 20); do
    $C -t 5 "local w = Game.GetPlayer():GetActiveWeapon(); return w and TDBID.ToStringDEBUG(w:GetItemID().id)" | grep -q "$1" && break
    sleep 1
  done
  sleep 2
}
for g in Crusher Tactician; do
  GUN=Items.Preset_${g}_Default
  $C "Game.AddToInventory('$GUN', 1); SELS = {'Items.AO_Feed_12ga_Buckshot', 'Items.AO_Feed_12ga_Slugs', 'Items.AO_Feed_12ga_PumpNDump'}
for _, i in ipairs(SELS) do Game.AddToInventory(i, 1) end
Game.AddToInventory('Ammo.ShotgunAmmo', 200); Game.AddToInventory('Ammo.AO_12ga_Slug', 400); Game.AddToInventory('Ammo.AO_12ga_PumpNDump', 50)" >/dev/null
  sleep 1; draw $GUN
  fit Buckshot; sp "AO_SPREAD_BASE = SP.read(); return 'ok'" >/dev/null
  fit Slugs; r=$(sp "return SP.compare('$g Slugs', 0.2)"); echo "$r" | tr '|' '\n'; out+="$r|"
  fit PumpNDump; r=$(sp "return SP.compare('$g Pump N Dump', 0.2, 0.4)"); echo "$r" | tr '|' '\n'; out+="$r|"
done
tr '|' '\n' <<<"$out" | grep -E '^(PASS|FAIL)'
p=$(tr '|' '\n' <<<"$out" | grep -c '^PASS'); n=$(tr '|' '\n' <<<"$out" | grep -c '^FAIL')
echo "== spread: $p pass, $n fail"
(( n == 0 && p > 0 ))

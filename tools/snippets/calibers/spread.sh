#!/usr/bin/env bash
# Does a single-projectile round really tighten the shot? On a Crusher and a Tactician: every spread
# stat with Buckshot and with Slugs, Pump N Dump's stats, then a grouping check on the hit rig: V's
# Slugs at a far target, as issued and with the gun's spread put back to x1 (spread.lua).
#   tools/linux/game-lock.sh tools/snippets/calibers/spread.sh
# Draws guns and spawns an NPC: not while the user plays. Exits 1 on any FAIL.
source "$(dirname "$0")/npc-lib.sh"
sp() { lua "$(cat $S/slice/common.lua $S/calibers/spread.lua); $1"; }
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
# Grouping, on the last gun: 25 shots at 30 m as issued, 25 with the x0.2 undone.
fit Slugs
group() { # label: fires until 25 shots are off, prints hits and scatter
  lua "RIG.clear(); SHOTS = 0; return 1" >/dev/null
  sp "SP.hook(); SP.points = {}; return 1" >/dev/null
  for _ in $(seq 150); do
    [[ $(lua "return SHOTS") -ge 25 ]] && break
    f=$(lua "return RIG.fireV()")
    [[ $f == fired ]] && lua "SHOTS = SHOTS + 1; return 1" >/dev/null
    [[ $f == holstered ]] && { draw $GUN; }
    sleep 0.9
  done
  sleep 1
  sp "return SP.scatter('$1')"
}
for _ in $(seq 30); do
  r=$(lua "return RIG.setup('$GUN', ${DIST:-30})"); [[ $r == ready ]] && break
  [[ $r == draw* ]] && draw $GUN
  sleep 3
done
echo "setup: $r"
tight=$(group "x0.2 as issued"); echo "$tight"
sp "return SP.undo()" >/dev/null
wide=$(group "x1 (round's x0.2 undone)"); echo "$wide"
sp "return SP.redo()" >/dev/null
lua "RIG.teardown(); return 1" >/dev/null
hits() { sed -n 's/.*: \([0-9]*\) hits.*/\1/p' <<<"$1"; }
h=$(hits "$tight"); w=$(hits "$wide")
if (( ${h:-0} > 0 && ${h:-0} >= ${w:-0} )); then out+="PASS grouping: $h hits of 25 at x0.2, ${w:-0} at x1|"
else out+="FAIL grouping: ${h:-0} hits of 25 at x0.2, ${w:-0} at x1|"; fi
tr '|' '\n' <<<"$out" | grep -E '^(PASS|FAIL)'
p=$(tr '|' '\n' <<<"$out" | grep -c '^PASS'); n=$(tr '|' '\n' <<<"$out" | grep -c '^FAIL')
echo "== spread: $p pass, $n fail"
(( n == 0 && p > 0 ))

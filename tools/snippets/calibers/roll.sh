#!/usr/bin/env bash
# The damage roll hook on real hits, with the hit rig (rig.lua): V's .45 Ball shots on a Unity NPC
# and the NPC's shots on V roll in 0.90..1.01; Ammo.AO_Test_Roll (fed by the test selector, added
# to the .45 lists for the run) gives duds, its own range and hot rounds; each Crusher pellet rolls
# in range. Draws guns and spawns an NPC: not while the user plays. Exits 1 on any FAIL.
set -uo pipefail
cd "$(dirname "$0")/../../.."
C=tools/linux/cet.sh; S=tools/snippets; out=""
lua() { $C -t 30 "$(cat $S/calibers/rig.lua); $1" 2>&1 | sed -n 's/^=> //p' | tail -1; }
draw() { $C "GUN='$1'; $(cat $S/feed-kit.lua)" >/dev/null; sleep 3; }
feed() { $C "FEED='$1'; $(cat $S/set-feed.lua)" >/dev/null; sleep 6; }
setup() {
  for _ in $(seq 20); do
    r=$(lua "return RIG.setup('$1')"); [[ $r == ready ]] && break
    echo "  $r" >&2
    # SHOTS=<dir>: a screenshot of every stalled setup (tools/linux/game-shot.sh).
    [[ -n "${SHOTS:-}" ]] && tools/linux/game-shot.sh "$SHOTS/setup-$(date +%s).png"
    [[ $r == draw* ]] && draw "$1"
    sleep 3
  done
  echo "setup $1: $r" >&2
}
# Fires until the rig holds $2 V hits (or 120 tries; set up again after 10 tries with no new hit), redrawing $1 when V holsters.
shoot() {
  lua "RIG.clear(); return 1" >/dev/null
  local have=0 last=0 idle=0
  for _ in $(seq 120); do
    have=$(lua "return #RIG.ratios('V')"); [[ $have -ge $2 ]] && break
    # No new hit for 10 tries: the NPC got loose or out of sight; set the rig up again.
    if (( have > last )); then last=$have; idle=0; else idle=$((idle + 1)); fi
    (( idle >= 10 )) && { setup "$1"; idle=0; }
    [[ $(lua "return RIG.fireV()") == holstered ]] && draw "$1"
    sleep 0.4
  done
  local got; got=$(lua "return #RIG.ratios('V')")
  if [[ $got -lt $2 ]]; then
    echo "  shoot $1: $got of $2 hits ($(lua "return RIG.fireV()"))" >&2
    [[ -n "${SHOTS:-}" ]] && tools/linux/game-shot.sh "$SHOTS/shoot-$(date +%s).png"
  fi
}
UNITY=Items.Preset_Unity_Default; CRUSHER=Items.Preset_Crusher_Default
$C "for _, i in ipairs({'$UNITY', '$CRUSHER', 'Items.AO_Feed_45_Ball', 'Items.AO_Feed_Test_Roll'}) do Game.AddToInventory(i, 1) end
Game.AddToInventory('Ammo.AO_45_Ball', 300); Game.AddToInventory('Ammo.AO_Test_Roll', 300); Game.AddToInventory('Ammo.ShotgunAmmo', 100)" >/dev/null
sleep 1; draw $UNITY; draw $UNITY; feed Items.AO_Feed_45_Ball
setup $UNITY
shoot $UNITY 30
out+="$(lua "local v = RIG.ratios('V')
local ok = #v >= 25 and v[1] >= 0.898 and v[#v] <= 1.012
return string.format('%s %d .45 Ball hits by V roll in 0.90..1.01 (%.3f..%.3f)|%s some roll below 0.95',
  ok and 'PASS' or 'FAIL', #v, v[1] or 0, v[#v] or 0, (v[1] or 1) < 0.95 and 'PASS' or 'FAIL')")|"
# The test round, fed through the .45 lists for this run.
L='local K = "AmmoOverhaul.Power_45."
local function add(f, v) local a = TweakDB:GetFlat(K .. f); table.insert(a, v); TweakDB:SetFlat(K .. f, a) end'
$C "$L"'
AO_ROLL_SAVED = AO_ROLL_SAVED or { s = TweakDB:GetFlat(K .. "selectors"), a = TweakDB:GetFlat(K .. "selectorAmmo"), t = TweakDB:GetFlat(K .. "selectorTiers") }
add("selectors", "Items.AO_Feed_Test_Roll"); add("selectorAmmo", "Ammo.AO_Test_Roll"); add("selectorTiers", 9)' >/dev/null
draw $UNITY; feed Items.AO_Feed_Test_Roll; setup $UNITY
shoot $UNITY 30
out+="$(lua "local v, d, m, h, other = RIG.ratios('V'), 0, 0, 0, 0
for _, r in ipairs(v) do
  if math.abs(r - 0.1) < 0.005 then d = d + 1 elseif r >= 0.498 and r <= 0.602 then m = m + 1
  elseif math.abs(r - 3.0) < 0.01 then h = h + 1 else other = other + 1 end
end
return string.format('%s %d Test_Roll hits: %d duds, %d in 0.5..0.6, %d hot, %d other', (#v >= 25 and other == 0 and m > 0 and d + h > 0) and 'PASS' or 'FAIL', #v, d, m, h, other)")|"
$C 'local K = "AmmoOverhaul.Power_45."
if AO_ROLL_SAVED then TweakDB:SetFlat(K .. "selectors", AO_ROLL_SAVED.s); TweakDB:SetFlat(K .. "selectorAmmo", AO_ROLL_SAVED.a); TweakDB:SetFlat(K .. "selectorTiers", AO_ROLL_SAVED.t); AO_ROLL_SAVED = nil end' >/dev/null
feed Items.AO_Feed_45_Ball
# Shotgun pellets: every pellet is its own hit and rolls on its own.
draw $CRUSHER; draw $CRUSHER; setup $CRUSHER
shoot $CRUSHER 12
out+="$(lua "local v = RIG.ratios('V')
local ok = #v >= 12 and v[1] >= 0.898 and v[#v] <= 1.012 and math.abs(v[#v] - v[1]) > 0.001
return string.format('%s %d Crusher pellet hits roll in 0.90..1.01 (%.3f..%.3f)', ok and 'PASS' or 'FAIL', #v, v[1] or 0, v[#v] or 0)")|"
# Last, as letting the NPC loose unsettles it: its own AI shoots V until 20 hits land.
draw $UNITY; setup $UNITY
lua "RIG.clear(); return 1" >/dev/null
for _ in $(seq 6); do
  lua "RIG.letNpcShoot(); return 1" >/dev/null; sleep 8; lua "RIG.freeze(); return 1" >/dev/null
  [[ $(lua "return #RIG.ratios('NPC')") -ge 20 ]] && break
done
out+="$(lua "local n = RIG.ratios('NPC')
local differ = false
for _, r in ipairs(n) do if math.abs(r - 1) > 0.001 then differ = true end end
local ok = #n >= 10 and n[1] >= 0.898 and n[#n] <= 1.012
return string.format('%s %d NPC hits on V roll in 0.90..1.01 (%.3f..%.3f)|%s NPC hits are rolled',
  ok and 'PASS' or 'FAIL', #n, n[1] or 0, n[#n] or 0, differ and 'PASS' or 'FAIL')")|"
lua "RIG.teardown(); return 1" >/dev/null
res=$(tr '|' '\n' <<<"$out" | sed '/^$/d'); echo "$res"
p=$(grep -c '^PASS' <<<"$res"); n=$(grep -c '^FAIL' <<<"$res")
echo "== roll: $p pass, $n fail"
(( n == 0 && p > 0 ))

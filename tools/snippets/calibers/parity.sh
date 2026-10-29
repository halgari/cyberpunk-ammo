#!/usr/bin/env bash
# NPC damage parity on live hits (hit rig, rig.lua): a 9mm Lexington ganger forced to Mushrooms
# (npcUncommonFactor flats 10, respawned until it carries Ammo.AO_9mm_HollowPoint, as slice/npcdrop.sh)
# hits V for 1.2x the roll; with the factor 0 it carries 9mm Ball and hits for the plain roll; and V's
# own Mushrooms hits on the NPC are not multiplied again. Also runs parity-ganger.lua with the ganger out, and measures the other stats
# the Uncommon selectors modify on NPC guns (parity-stats.lua; shotgun pellets via the rig's volleys).
# Draws guns and spawns an NPC: not while the user plays. Exits 1 on any FAIL.
set -uo pipefail
cd "$(dirname "$0")/../../.."
C=tools/linux/cet.sh; S=tools/snippets; out=""
lua() { $C -t 30 "$(cat $S/calibers/rig.lua); $1" 2>&1 | sed -n 's/^=> //p' | tail -1; }
R='AO_R = {Trash=0.5,Weak=0.5,Normal=1.0,Rare=1.5,Officer=1.5,Elite=2.0,Boss=2.0}'
flats() { $C "$R"' for r in pairs(AO_R) do TweakDB:SetFlat("AmmoOverhaul.npcUncommonFactor."..r, '"$1"') end return "set"' >/dev/null; }
restore() { $C "$R"' for r, v in pairs(AO_R) do TweakDB:SetFlat("AmmoOverhaul.npcUncommonFactor."..r, v) end; GetMod("AOTestKit").despawnAll(); return "x"' >/dev/null; }
trap restore EXIT
# Spawns $3 with the roll at factor $1 until it holds $2 (any, if empty); returns when its gun is out.
spawn() {
  for _ in $(seq 1 10); do
    $C "$R"'
    local k = GetMod("AOTestKit"); k.despawnAll(); k.state.distance = 12
    for r in pairs(AO_R) do TweakDB:SetFlat("AmmoOverhaul.npcUncommonFactor."..r, '"$1"') end
    k.spawn("'"$3"'", 1); return "spawned"' >/dev/null
    for _ in $(seq 1 20); do
      [[ "$($C -t 10 'local n=0 for _,npc in ipairs(Game.GetDynamicEntitySystem():GetTagged("AO_Test")) do if ScriptedPuppet.GetActiveWeapon(npc) then n=n+1 end end return n' 2>/dev/null)" == "=> 1" ]] && break
    done
    [[ -z "$2" ]] && return 0
    [[ "$($C -t 10 'local npc = Game.GetDynamicEntitySystem():GetTagged("AO_Test")[1]
    return Game.GetTransactionSystem():GetItemQuantity(npc, ItemID.CreateQuery(TweakDBID.new("'"$2"'"))) > 0' 2>/dev/null)" == "=> true" ]] && return 0
  done
  echo "  could not get $3 carrying $2" >&2
  out+="FAIL could not spawn $3 with ${2:-a gun}|"
}
# The rig's setup (spawns Unity if none) against the already spawned ganger: waits for ready.
setup() {
  for _ in $(seq 30); do
    r=$(lua "return RIG.setup(${1:+'$1'})"); [[ $r == ready ]] && break
    echo "  $r" >&2
    [[ $r == draw* ]] && draw "$1"
    sleep 3
  done
  [[ $r == ready ]]
}
# Lets the NPC shoot V until $1 hits land (6 rounds of 8 s), then freezes it.
npcshoot() {
  lua "RIG.clear(); return 1" >/dev/null
  for _ in $(seq 6); do
    lua "RIG.letNpcShoot(); return 1" >/dev/null; sleep 8; lua "RIG.freeze(); return 1" >/dev/null
    [[ $(lua "return #RIG.ratios('NPC')") -ge $1 ]] && break
  done
}
verdict() { # name lo hi
  lua "local n = RIG.ratios('NPC')
local ok = #n >= 10 and n[1] >= $2 and n[#n] <= $3
return string.format('%s %d $1 NPC hits on V in $2..$3 (%.3f..%.3f)', ok and 'PASS' or 'FAIL', #n, n[1] or 0, n[#n] or 0)"
}

draw() { $C "GUN='$1'; $(cat $S/feed-kit.lua)" >/dev/null; sleep 3; }
feed() { $C "FEED='$1'; $(cat $S/set-feed.lua)" >/dev/null; sleep 6; }
# Fires until the rig holds $2 V hits (or 120 tries; set up again after 10 idle tries), redrawing $1 when V holsters.
shoot() {
  lua "RIG.clear(); return 1" >/dev/null
  local have=0 last=0 idle=0
  for _ in $(seq 120); do
    have=$(lua "return #RIG.ratios('V')"); [[ $have -ge $2 ]] && break
    if (( have > last )); then last=$have; idle=0; else idle=$((idle + 1)); fi
    (( idle >= 10 )) && { setup "$1"; idle=0; }
    [[ $(lua "return RIG.fireV()") == holstered ]] && draw "$1"
    sleep 0.4
  done
}

# The Mushrooms ganger: its round's factor and its gun's DamagePerHit.
spawn 10.0 Ammo.AO_9mm_HollowPoint Character.AO_Test_Ganger_9mm_Mushrooms
ganger="$(tools/snippets/calibers/check.sh calibers/parity-ganger.lua 2>&1)"
out+="$(grep -E '^(PASS|FAIL)' <<<"$ganger" | tr '\n' '|')"

# Stats of an Uncommon's selector on an NPC gun (parity-stats.lua): name, character, round, selector, stats that change, stats the NPC gun has no value for.
statcase() {
  local pre="PS_NAME='$1'; PS_SEL='$4'; PS_STATS='$5'; PS_ZERO='${6:-}';"
  spawn 0.0 "" "$2"
  $C "$pre PS_MODE='base'; $(cat $S/slice/common.lua $S/calibers/parity-stats.lua)" >/dev/null
  spawn 10.0 "$3" "$2"
  res=$(PRE="$pre PS_MODE='held';" tools/snippets/calibers/check.sh calibers/parity-stats.lua 2>&1)
  out+="$(grep -E '^(PASS|FAIL)' <<<"$res" | tr '\n' '|')"
}
statcase "Dumbfires" Character.AO_Test_Plain_Yukimura Ammo.AO_S10_Dumbfire Items.AO_Feed_10mm_Dumbfires SmartGunHitProbability
statcase "Short Fuse" Character.AO_Test_Plain_Yukimura Ammo.AO_S10_ShortFuse Items.AO_Feed_10mm_ShortFuse "" MaximumRange
statcase "+P" Character.AO_Test_Plain_Lexington Ammo.AO_9mm_PlusP Items.AO_Feed_9mm_PlusP "" EffectiveRange
statcase "12ga Slugs" Character.AO_Test_Plain_Crusher Ammo.AO_12ga_Slug Items.AO_Feed_12ga_Slugs ProjectilesPerShot SpreadDefaultX,SpreadDefaultY,SpreadMaxX,SpreadMaxY,SpreadAdsDefaultX,SpreadAdsDefaultY,SpreadAdsMaxX,SpreadAdsMaxY,EffectiveRange
statcase "12ga Birdshot" Character.AO_Test_Plain_Crusher Ammo.AO_12ga_Birdshot Items.AO_Feed_12ga_Birdshot ProjectilesPerShot,HitReactionFactor SpreadDefaultX,SpreadMaxX
statcase "4ga Birdshot" Character.AO_Test_Plain_Carnage Ammo.AO_4ga_Birdshot Items.AO_Feed_4ga_Birdshot ProjectilesPerShot,HitReactionFactor

# Phase 1: the Mushrooms Lexington shoots V.
spawn 10.0 Ammo.AO_9mm_HollowPoint Character.AO_Test_Plain_Lexington
setup && npcshoot 20
out+="$(verdict 'Mushrooms' 1.0776 1.2144)|"
# Phase 2: roll factor 0, a 9mm Ball Lexington.
spawn 0.0 Ammo.HandgunAmmo Character.AO_Test_Plain_Lexington
setup && npcshoot 20
out+="$(verdict 'Ball (roll factor off)' 0.898 1.012)|"

# Pellets: a 12ga Crusher with Birdshot lands more hits per shot on V than with Common (shots are
# the rig's hits within 0.1 s).
volley() { # round
  lua "local v = RIG.volleys('NPC'); table.sort(v, function(a, b) return a.n < b.n end)
local t = 0 for _, s in ipairs(v) do t = t + s.total end
AO_VOL = { shots = #v, median = v[math.ceil(#v / 2)] and v[math.ceil(#v / 2)].n or 0, total = #v > 0 and t / #v or 0 }
return string.format('%d shots, median %d hits, %.1f damage per shot', AO_VOL.shots, AO_VOL.median, AO_VOL.total)"
}
spawn 0.0 "" Character.AO_Test_Plain_Crusher
setup && npcshoot 24
common="$(volley)"; echo "  Common: $common" >&2
lua "AO_COMMON = AO_VOL; return 1" >/dev/null
spawn 10.0 Ammo.AO_12ga_Birdshot Character.AO_Test_Plain_Crusher
setup && npcshoot 24
bird="$(volley)"; echo "  Birdshot: $bird" >&2
out+="$(lua "local c, b = AO_COMMON, AO_VOL
local ok = c and b and c.shots >= 3 and b.shots >= 3 and b.median >= 1.5 * c.median
return string.format('%s Birdshot NPC shots land more hits (median %d) than Common (median %d)', ok and 'PASS' or 'FAIL', b and b.median or 0, c and c.median or 0)")|"
out+="$(lua "local c, b = AO_COMMON, AO_VOL
local ok = c and b and c.total > 0 and b.total / c.total < 1.5
return string.format('%s Birdshot damage per NPC shot %.1f is not double Common %.1f (a shot's damage is split across its pellets; wider spread lands fewer)', ok and 'PASS' or 'FAIL', b and b.total or 0, c and c.total or 0)")|"

# Phase 3: V's own Mushrooms hits on a Unity target are rolled once, not multiplied by 1.2 again.
LEX=Items.Preset_Lexington_Default
$C "Game.AddToInventory('$LEX', 1); Game.AddToInventory('Items.AO_Feed_9mm_Mushrooms', 1); Game.AddToInventory('Ammo.AO_9mm_HollowPoint', 300)" >/dev/null
sleep 1; draw $LEX; draw $LEX; feed Items.AO_Feed_9mm_Mushrooms
flats 0.0
$C 'GetMod("AOTestKit").despawnAll(); return 1' >/dev/null; sleep 2
setup $LEX
shoot $LEX 25
out+="$(lua "local v = RIG.ratios('V')
local ok = #v >= 10 and v[1] >= 0.898 and v[#v] <= 1.012
return string.format('%s %d V Mushrooms hits on the NPC in 0.898..1.012, not x1.2 again (%.3f..%.3f)', ok and 'PASS' or 'FAIL', #v, v[1] or 0, v[#v] or 0)")|"
$C "FEED='Items.AO_Feed_9mm_Ball'; $(cat $S/set-feed.lua)" >/dev/null
lua "RIG.teardown(); return 1" >/dev/null
res=$(tr '|' '\n' <<<"$out" | sed '/^$/d'); echo "$res"
p=$(grep -c '^PASS' <<<"$res"); n=$(grep -c '^FAIL' <<<"$res")
echo "== parity: $p pass, $n fail"
(( n == 0 && p > 0 ))

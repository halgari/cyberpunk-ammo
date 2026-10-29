#!/usr/bin/env bash
# Helpers for the live NPC checks (parity.sh, pellets.sh): the hit rig, forcing an NPC to an Uncommon
# round (npcUncommonFactor flats, as slice/npcdrop.sh), and shooting. Source it from the repo root script.
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
    local gun=0
    for _ in $(seq 1 20); do
      [[ "$($C -t 10 'local n=0 for _,npc in ipairs(Game.GetDynamicEntitySystem():GetTagged("AO_Test")) do if ScriptedPuppet.GetActiveWeapon(npc) then n=n+1 end end return n' 2>/dev/null)" == "=> 1" ]] && { gun=1; break; }
    done
    (( gun )) || continue
    [[ -z "$2" ]] && return 0
    [[ "$($C -t 10 'local npc = Game.GetDynamicEntitySystem():GetTagged("AO_Test")[1]
    return Game.GetTransactionSystem():GetItemQuantity(npc, ItemID.CreateQuery(TweakDBID.new("'"$2"'"))) > 0' 2>/dev/null)" == "=> true" ]] && return 0
  done
  echo "  could not get $3 carrying ${2:-a gun}" >&2
  out+="FAIL could not spawn $3 with ${2:-a gun}|"
  return 1
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
# Lets the NPC shoot V until $1 hits land (${2:-6} rounds of 8 s), then freezes it.
npcshoot() {
  lua "RIG.clear(); return 1" >/dev/null
  for _ in $(seq ${2:-6}); do
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
# Fires until the rig holds $2 V hits (keeping the hits already there if $3 is keep) (or 120 tries; set up again after 10 idle tries), redrawing $1 when V holsters.
shoot() {
  [[ "${3:-}" == keep ]] || lua "RIG.clear(); return 1" >/dev/null
  local have=0 last=0 idle=0
  for _ in $(seq 120); do
    have=$(lua "return #RIG.ratios('V')"); [[ $have -ge $2 ]] && break
    if (( have > last )); then last=$have; idle=0; else idle=$((idle + 1)); fi
    (( idle >= 10 )) && { setup "$1"; idle=0; }
    [[ $(lua "return RIG.fireV()") == holstered ]] && draw "$1"
    sleep 0.4
  done
}


# Whether the rig's NPC still holds a Crusher whose ProjectilesPerShot is $1 (the rig respawns a
# Unity when its NPC sinks or loses sight, and a Unity's hits would pass for the Crusher's).
holds_crusher() {
  [[ "$(lua "local n = RIG.npc(); local w = n and ScriptedPuppet.GetActiveWeapon(n)
if not w or TDBID.ToStringDEBUG(w:GetItemID().id) ~= 'Items.Preset_Crusher_Default' then return 'no' end
return Game.GetStatsSystem():GetStatValue(w:GetItemData():GetStatsObjectID(), gamedataStatType.ProjectilesPerShot) == $1 and 'yes' or 'no'")" == yes ]]
}
# Spawns a Plain_Crusher (roll factor $1, carrying $2 if given, ProjectilesPerShot $3), sets the rig
# up at 3 m and lets it shoot V until 24 hits; tries again when the rig swapped the NPC. 0 if the
# hits in the rig are the Crusher's.
crusher_run() {
  for _ in 1 2 3 4 5 6; do
    spawn $1 "$2" Character.AO_Test_Plain_Crusher || return 1
    for _ in 1 2 3 4 5 6 7 8; do [[ $(lua "return RIG.setup(nil, 3)") == ready ]] && break; sleep 3; done
    holds_crusher $3 || continue
    npcshoot 24
    holds_crusher $3 && return 0
  done
  out+="FAIL no Crusher with ProjectilesPerShot $3 shot V|"
  return 1
}

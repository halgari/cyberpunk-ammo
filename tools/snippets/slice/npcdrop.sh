#!/usr/bin/env bash
# The Uncommon stats an NPC's gun gets (NpcAmmo.RollUncommon) don't follow the gun when it drops
# at death: a Lexington ganger with the roll forced on has pen -0.5 in hand; the dropped gun has
# vanilla pen (0), while its magazine size (a control that should survive) is read the same.
set -uo pipefail
cd "$(dirname "$0")/../../.."
C=tools/linux/cet.sh; S=tools/snippets/slice
R='AO_R = {Trash=0.5,Weak=0.5,Normal=1.0,Rare=1.5,Officer=1.5,Elite=2.0,Boss=2.0}'
$C "$R"'
local k = GetMod("AOTestKit"); k.despawnAll(); k.state.distance = 6
for r in pairs(AO_R) do TweakDB:SetFlat("AmmoOverhaul.npcUncommonFactor."..r, 10.0) end
k.spawn("Character.AO_Test_Plain_Lexington", 1); return "spawned"' >/dev/null
for _ in $(seq 1 20); do
  [[ "$($C -t 10 'local n=0 for _,npc in ipairs(Game.GetDynamicEntitySystem():GetTagged("AO_Test")) do if ScriptedPuppet.GetActiveWeapon(npc) then n=n+1 end end return n' 2>/dev/null)" == "=> 1" ]] && break
done
$C -t 15 '
local npc = Game.GetDynamicEntitySystem():GetTagged("AO_Test")[1]
local w = ScriptedPuppet.GetActiveWeapon(npc)
local ss = Game.GetStatsSystem()
AO_NPCGUN = w:GetItemID()
AO_HELD = { pen = ss:GetStatValue(w:GetItemData():GetStatsObjectID(), gamedataStatType.CanWeaponIgnoreArmor),
            mag = ss:GetStatValue(w:GetItemData():GetStatsObjectID(), gamedataStatType.MagazineCapacity) }
npc:Kill(nil, false, false); return "killed"' >/dev/null
sleep 5
$C -t 15 "$(cat $S/common.lua)"'
local ts = Game.GetTransactionSystem(); local ss = Game.GetStatsSystem(); local p = Game.GetPlayer()
check("held gun has the Uncommon pen", AO_HELD and AO_HELD.pen == -0.5, tostring(AO_HELD and AO_HELD.pen))
local q = TSQ_ALL(); q.maxDistance = 25; q.testedSet = TargetingSet.Complete; q.searchFilter = TSF_All(TSFMV.Obj_Other)
local _, parts = Game.GetTargetingSystem():GetTargetParts(p, q)
local d
for _, part in ipairs(parts or {}) do
  local o = part:GetComponent():GetEntity()
  if o and o:IsA("gameItemDropObject") then d = d or ts:GetItemData(o, AO_NPCGUN) end
end
check("the gun dropped", d ~= nil, "no drop object holds it")
if d then
  local id = d:GetStatsObjectID()
  check("dropped gun reads its magazine size (control)", ss:GetStatValue(id, gamedataStatType.MagazineCapacity) == AO_HELD.mag, tostring(ss:GetStatValue(id, gamedataStatType.MagazineCapacity)))
  check("dropped gun has vanilla pen", ss:GetStatValue(id, gamedataStatType.CanWeaponIgnoreArmor) == 0, tostring(ss:GetStatValue(id, gamedataStatType.CanWeaponIgnoreArmor)))
end
report()'
$C "$R"' for r, v in pairs(AO_R) do TweakDB:SetFlat("AmmoOverhaul.npcUncommonFactor."..r, v) end; GetMod("AOTestKit").despawnAll(); return "x"' >/dev/null

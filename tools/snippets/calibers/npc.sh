#!/usr/bin/env bash
# v1 calibers NPC run: one plain test NPC per new caliber (test.yaml: a gang record with only the
# family's gun). Uncommon roll forced off: checks their ammo (npc.lua), kills them, checks their
# loot (slice/npcloot.lua) and picks up the dropped Unity (keeps .45 and vanilla stats: Review
# Focus 5). Then forced on: checks they carry the Uncommon round and removes them unkilled (an
# NPC dying with a selector fitted can crash the game, DESIGN.md Known gaps). Police, MaxTac and
# story NPCs leave no loot at all, so they aren't used. Exits 1 on FAIL.
set -uo pipefail
cd "$(dirname "$0")/../../.."
C=tools/linux/cet.sh; S=tools/snippets
NPCS='{"Unity","Nova","Copperhead","Ajax","Grad","Crusher","Carnage","Achilles","Zhuo","Ashura"}'
WANT='WANT = {"Power_45","Power_12mm","Power_556","Power_762","Power_127","Power_12ga","Power_4ga","Tech_Heavy","Smart_20","Smart_25"};'
N=10
out=""
F='AO_RARITIES = {"Trash","Weak","Normal","Rare","Officer","Elite","Boss"}
if not AO_FACTORS then AO_FACTORS = {} for _,r in ipairs(AO_RARITIES) do AO_FACTORS[r] = TweakDB:GetFlat("AmmoOverhaul.npcUncommonFactor."..r) end end
local function factor(v) for _,r in ipairs(AO_RARITIES) do TweakDB:SetFlat("AmmoOverhaul.npcUncommonFactor."..r, v or AO_FACTORS[r]) end end
local k = GetMod("AOTestKit")'
spawn() { $C "$F"'
k.despawnAll(); k.state.distance = 12; factor('"$1"')
Game.GetGodModeSystem():AddGodMode(Game.GetPlayer():GetEntityID(), gameGodModeType.Invulnerable, CName.new("AO_Test"))
for _, g in ipairs('"$NPCS"') do k.spawn("Character.AO_Test_Plain_"..g, 1) end; return "spawned"' >/dev/null; }
DRAWN='local n=0 for _,npc in ipairs(Game.GetDynamicEntitySystem():GetTagged("AO_Test")) do if ScriptedPuppet.GetActiveWeapon(npc) then n=n+1 end end return n'
wait_drawn() { for _ in $(seq 1 30); do [[ "$($C -t 10 "$DRAWN" 2>/dev/null)" == "=> $N" ]] && break; sleep 1; done; echo "drawn: $($C -t 10 "$DRAWN")"; }
spawn 0.0; wait_drawn
out+="$($C -t 30 "UNCOMMON=false; $WANT $(cat $S/slice/common.lua $S/calibers/npc.lua)")"$'\n'
$C 'GetMod("AOTestKit").killAll(); return "killed"' >/dev/null
for _ in $(seq 1 8); do $C -t 10 'return "tick"' >/dev/null 2>&1 || true; sleep 1; done
out+="$($C -t 30 "$(cat $S/slice/common.lua $S/slice/npcloot.lua)")"$'\n'
# Review Focus 5: the Unity a police officer dropped, picked up, keeps .45 and the .45 profile.
out+="$($C -t 30 "$(cat $S/slice/common.lua)"'
local ts = Game.GetTransactionSystem(); local p = Game.GetPlayer()
local q = TSQ_ALL(); q.maxDistance = 40; q.testedSet = TargetingSet.Complete; q.searchFilter = TSF_All(TSFMV.Obj_Other)
local _, parts = Game.GetTargetingSystem():GetTargetParts(p, q)
local got
for _, part in ipairs(parts or {}) do
  local o = part:GetComponent():GetEntity()
  if not got and o and o:IsA("gameItemDropObject") then
    local _, items = ts:GetItemList(o)
    for _, it in ipairs(items or {}) do
      if str(it:GetID().id):find("Preset_Unity_") then got = it:GetID(); ts:TransferItem(o, p, got, 1) break end
    end
  end
end
check("found the dropped Unity", got ~= nil, "no drop holds one")
if got then
  local d = ts:GetItemData(p, got)
  check("picked-up Unity is in the inventory", d ~= nil)
  if d then
    local pen = Game.GetStatsSystem():GetStatValue(d:GetStatsObjectID(), gamedataStatType.CanWeaponIgnoreArmor)
    check("picked-up Unity has vanilla pen (0)", pen == 0, tostring(pen))
    check("picked-up Unity loads .45 Ball", str(flat(got.id, "ammo")) == "Ammo.AO_45_Ball", str(flat(got.id, "ammo")))
  end
end
report()')"$'\n'
spawn 10.0; wait_drawn
out+="$($C -t 30 "UNCOMMON=true; $WANT $(cat $S/slice/common.lua $S/calibers/npc.lua)")"$'\n'
$C "$F"'
factor(nil); k.despawnAll(); Game.GetGodModeSystem():RemoveGodMode(Game.GetPlayer():GetEntityID(), gameGodModeType.Invulnerable, CName.new("AO_Test")); return "removed"' >/dev/null
echo "$out"
p=$(grep -c '^PASS' <<<"$out"); n=$(grep -c '^FAIL' <<<"$out")
echo "== npc: $p pass, $n fail"
(( n == 0 && p > 0 ))

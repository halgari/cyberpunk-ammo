#!/usr/bin/env bash
# Task 5 driver: spawns one plain ganger per slice gun with the Uncommon roll off (Common round),
# one per gun with it forced on (Uncommon), and the three fitted test gangers; waits for all of them
# to draw, runs npc.lua, kills them and checks their loot (npcloot.lua), then removes them and
# restores the roll factors.
set -euo pipefail
cd "$(dirname "$0")/../../.."
C=tools/linux/cet.sh; S=tools/snippets/slice
F='AO_RARITIES = {"Trash","Weak","Normal","Rare","Officer","Elite","Boss"}
if not AO_FACTORS then AO_FACTORS = {} for _,r in ipairs(AO_RARITIES) do AO_FACTORS[r] = TweakDB:GetFlat("AmmoOverhaul.npcUncommonFactor."..r) end end
local function factor(v) for _,r in ipairs(AO_RARITIES) do TweakDB:SetFlat("AmmoOverhaul.npcUncommonFactor."..r, v or AO_FACTORS[r]) end end
local k = GetMod("AOTestKit")'
DRAWN='local n=0 for _,npc in ipairs(Game.GetDynamicEntitySystem():GetTagged("AO_Test")) do if ScriptedPuppet.GetActiveWeapon(npc) then n=n+1 end end return n'
wait_drawn() { for _ in $(seq 1 20); do [[ "$($C -t 10 "$DRAWN" 2>/dev/null)" == "=> $1" ]] && return 0; done; echo "only some drew" >&2; }
$C "$F"'
k.despawnAll(); k.state.distance = 10; factor(0.0)
for _,g in ipairs({"Lexington","Omaha","Yukimura"}) do k.spawn("Character.AO_Test_Plain_"..g, 1) end
return "spawned Common"'
wait_drawn 3
$C "$F"'
factor(10.0)
for _,g in ipairs({"Lexington","Omaha","Yukimura"}) do k.spawn("Character.AO_Test_Plain_"..g, 1) end
for _,r in ipairs({"9mm_Mushrooms","5mm_Sleevers","10mm_Dumbfires"}) do k.spawn("Character.AO_Test_Ganger_"..r, 1) end
return "spawned Uncommon and fitted"'
wait_drawn 9
$C -t 30 "$(cat $S/common.lua $S/npc.lua)"
$C 'GetMod("AOTestKit").killAll(); return "killed"'
for _ in $(seq 1 8); do $C -t 10 'return "tick"' >/dev/null 2>&1 || true; done
$C -t 30 "$(cat $S/common.lua $S/npcloot.lua)"
$C "$F"'
factor(nil); k.despawnAll(); return "removed, factors restored"'

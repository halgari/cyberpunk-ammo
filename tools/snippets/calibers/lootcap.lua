-- Final review, Important 2: a body leaves at most AmmoOverhaul.npcLootWeight carry points of
-- each round (6: an Elite's six magazines), so an HMG heavy stocked with 1200 rounds of 12.7 Ball
-- (0.15 each) leaves 40, while a normal stock (60 .45 Ball, 5.4 points) is left whole.
-- Spawns one test NPC; needs AOTestKit.
--   tools/snippets/calibers/check.sh calibers/lootcap.lua
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
local k = GetMod("AOTestKit")
local npc = Game.GetDynamicEntitySystem():GetTagged("AO_Test")[1]
if not npc then
  k.spawn("Character.AO_Test_Plain_Unity", 1)
  print("spawned a test NPC: run again once it has loaded")
  return
end
check("npcLootWeight is 6", TweakDB:GetFlat("AmmoOverhaul.npcLootWeight") == 6, tostring(TweakDB:GetFlat("AmmoOverhaul.npcLootWeight")))
local hmg = sys:DebugLootCycle(npc, "Ammo.SniperRifleAmmo", 1200, 0)
print("12.7, 1200 stocked: " .. hmg)
check("1200 rounds of 12.7 leave 40", hmg:match("^(%d+)") == "40", hmg)
local unity = sys:DebugLootCycle(npc, "Ammo.AO_45_Ball", 60, 0)
print(".45, 60 stocked: " .. unity)
check("60 rounds of .45 are left whole", unity:match("^(%d+)") == "60", unity)
k.despawnAll()
report()

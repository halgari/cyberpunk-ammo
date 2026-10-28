-- Final review, Important 1: a body's ammo is given back once per wipe, never twice. A test NPC
-- with 60 rounds is knocked out (60 come back), the player takes 25, it dies (35 come back, not
-- 60), then the game's loot event (still 35). Spawns one test NPC; needs AOTestKit.
--   tools/snippets/calibers/check.sh calibers/lootdupe.lua
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
local k = GetMod("AOTestKit")
local npc = Game.GetDynamicEntitySystem():GetTagged("AO_Test")[1]
if not npc then
  k.spawn("Character.AO_Test_Plain_Unity", 1)
  print("spawned a test NPC: run again once it has loaded")
  return
end
local res = sys:DebugLootCycle(npc, "Ammo.AO_45_Ball", 60, 25)
print("loot cycle: " .. res)
local a, b, c, d = res:match("^(%-?%d+) (%-?%d+) (%-?%d+) (%-?%d+)$")
check("knockout gives the 60 back", a == "60", res)
check("player took 25", b == "35", res)
check("death gives back what was left (35), not the first note (60)", c == "35", res)
check("loot event adds nothing more", d == "35", res)
k.despawnAll()
report()

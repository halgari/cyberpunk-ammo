-- Task 7, fill event, step 1: teleports the player next to the nearest unfilled loot container,
-- looking at it (loot fills when the player looks at a container). Run lootfill2.lua a few
-- seconds later. Moves the player: only when the user isn't playing.
local p = Game.GetPlayer()
local q = TSQ_ALL(); q.maxDistance = 150; q.testedSet = TargetingSet.Complete; q.searchFilter = TSF_All(TSFMV.Obj_Other)
local _, parts = Game.GetTargetingSystem():GetTargetParts(p, q)
local box, best
for _, part in ipairs(parts or {}) do
  local o = part:GetComponent():GetEntity()
  if o and o:IsA("gameLootContainerBase") and not o.wasLootInitalized and o:GetClassName().value == "LootContainerObjectAnimatedByTransform" then
    local d = Vector4.Distance(o:GetWorldPosition(), p:GetWorldPosition())
    if not best or d < best then box, best = o, d end
  end
end
if not box then return "no unfilled loot container within 150 m" end
AO_HOME = AO_HOME or p:GetWorldPosition()
AO_BOX = box
local pos = box:GetWorldPosition()
-- Yaw 90 faces -X; stand 1.2 m along +X, looking down at it.
Game.GetTeleportationFacility():Teleport(p, Vector4.new(pos.x + 1.2, pos.y, pos.z + 0.2, 1), EulerAngles.new(0, -35, 90))
return string.format("next to a container %.0f m away", best)

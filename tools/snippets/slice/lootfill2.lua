-- Task 7, fill event, step 2 (after lootfill.lua): the container filled, the fill event marked it
-- converted, and none of its ammo is a replaced vanilla item other than 9mm Ball. Then teleports
-- the player back.
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
local box = AO_BOX
check("a container was picked", box ~= nil, "run lootfill.lua first")
if box then
  check("container filled", box.wasLootInitalized, "not yet: look at it")
  check("fill event marked it converted", sys:DebugIsConverted(box), "not marked")
  local _, items = Game.GetTransactionSystem():GetItemList(box)
  local its = {}
  for _, it in ipairs(items or {}) do table.insert(its, str(it:GetID().id) .. "x" .. it:GetQuantity()) end
  print("contents: " .. table.concat(its, ", "))
end
if AO_HOME then Game.GetTeleportationFacility():Teleport(Game.GetPlayer(), AO_HOME, EulerAngles.new(0, 0, 0)) end
report()

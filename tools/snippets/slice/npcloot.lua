-- Task 5: after npc.lua and a kill, each body's loot holds only the round its gun used.
local ts = Game.GetTransactionSystem()
local seen = 0
for _, npc in ipairs(Game.GetDynamicEntitySystem():GetTagged("AO_Test")) do
  local e = AO_EXPECT and AO_EXPECT[tostring(npc:GetEntityID().hash)]
  if e and npc:IsDead() then
    seen = seen + 1
    local _, items = ts:GetItemList(npc)
    local found, others = 0, {}
    for _, it in ipairs(items or {}) do
      local n = str(it:GetID().id)
      if n:find("^Ammo%.") then
        if n == e.ammo then found = ts:GetItemQuantity(npc, it:GetID()) else table.insert(others, n) end
      end
    end
    check(e.name .. " drops " .. e.ammo, found > 0, "none")
    check(e.name .. " drops no other round", #others == 0, table.concat(others, ", "))
  end
end
check("dead test NPCs with expectations", seen > 0, "run npc.lua first, then kill")
report()

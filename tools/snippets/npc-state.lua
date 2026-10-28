-- Prints each AO_Test NPC's weapon, magazine and ammo stacks. FIGHT=true also makes it hostile.
local p = Game.GetPlayer()
local ts = Game.GetTransactionSystem()
for _, npc in ipairs(Game.GetDynamicEntitySystem():GetTagged("AO_Test")) do
  if FIGHT then
    npc:GetAttitudeAgent():SetAttitudeTowards(p:GetAttitudeAgent(), EAIAttitude.AIA_Hostile)
    npc:GetTargetTrackerComponent():AddThreat(p, true, p:GetWorldPosition(), 1.0, -1.0, false)
  end
  local w = ScriptedPuppet.GetActiveWeapon(npc) or ScriptedPuppet.GetWeaponRight(npc)
  local line = { NPC = tostring(npc:GetEntityID().hash), dead = tostring(npc:IsDead()) }
  if w then
    line.weapon = TDBID.ToStringDEBUG(w:GetItemID().id)
    line.mag = tostring(WeaponObject.GetMagazineAmmoCount(w)) .. "/" .. tostring(WeaponObject.GetMagazineCapacity(w))
  end
  local ok, items = ts:GetItemList(npc)
  local ammo = {}
  for _, it in ipairs(items or {}) do
    local id = it:GetID()
    local s = TDBID.ToStringDEBUG(id.id)
    if s:find("^Ammo%.") then table.insert(ammo, s .. "=" .. ts:GetItemQuantity(npc, id)) end
  end
  line.ammo = table.concat(ammo, ",")
  print(line.NPC, line.dead, line.weapon, line.mag, line.ammo)
end

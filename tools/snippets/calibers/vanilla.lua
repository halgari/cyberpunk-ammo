-- Common rounds act like the gun's vanilla ammo: the mod adds no stat group to any gun, and with
-- LIVE=true the drawn gun's armor pen is its vanilla value (a Unity's and a Yukimura's is 0).
--   tools/snippets/calibers/check.sh calibers/vanilla.lua
local n, bad = 0, {}
for _, r in ipairs(TweakDB:GetRecords("gamedataWeaponItem_Record")) do
  for _, g in ipairs(flat(r:GetID(), "statModifierGroups") or {}) do
    if str(g):find("^AOProfile%.") then n = n + 1; if #bad < 5 then table.insert(bad, str(r:GetID())) end end
  end
end
check("no gun carries a caliber stat group", n == 0, n .. " e.g. " .. table.concat(bad, " "))
for _, c in ipairs(flat("AmmoOverhaul", "calibers") or {}) do
  check("AOProfile." .. c .. " gone", rec("AOProfile." .. c) == nil)
end
if LIVE then
  local w = Game.GetPlayer():GetActiveWeapon()
  local v = Game.GetStatsSystem():GetStatValue(w:GetEntityID(), gamedataStatType.CanWeaponIgnoreArmor)
  check("live " .. str(w:GetItemID().id) .. " pen 0 (vanilla)", v == 0, tostring(v))
end
report()

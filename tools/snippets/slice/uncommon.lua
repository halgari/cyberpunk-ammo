-- Task 2: the Uncommon selectors change the drawn gun's stats. Run twice per gun, through
-- tools/snippets/slice/uncommon.sh: MODE='base' with the Common selector fitted stores the stats,
-- MODE='check' with the Uncommon fitted compares (stored in the global AO_SLICE between runs).
local w = Game.GetPlayer():GetActiveWeapon()
local function stat(name) return Game.GetStatsSystem():GetStatValue(w:GetEntityID(), gamedataStatType[name]) end
local names = { "DamagePerHit", "CanWeaponIgnoreArmor", "ChargeTime", "SmartGunHitProbability" }
local gun = str(w:GetItemID().id)
AO_SLICE = AO_SLICE or {}
if MODE == "base" then
  local s = {}
  for _, n in ipairs(names) do s[n] = stat(n) end
  AO_SLICE[gun] = s
  for _, n in ipairs(names) do print("base " .. gun .. " " .. n .. " " .. s[n]) end
  return
end
local base = AO_SLICE[gun]
if not base then check(gun .. " base stored", false, "run MODE='base' first"); report(); return end
local function ratio(n) return base[n] ~= 0 and stat(n) / base[n] or 0 end
local function near(a, b) return math.abs(a - b) < 0.01 end
for _, n in ipairs(names) do print("now  " .. gun .. " " .. n .. " " .. stat(n)) end
if gun:find("Lexington") then
  check("Mushrooms damage x1.2", near(ratio("DamagePerHit"), 1.2), tostring(ratio("DamagePerHit")))
  check("Mushrooms pen -0.5", near(stat("CanWeaponIgnoreArmor") - base.CanWeaponIgnoreArmor, -0.5), tostring(stat("CanWeaponIgnoreArmor")))
elseif gun:find("Omaha") then
  check("Sleevers charge x0.7", near(ratio("ChargeTime"), 0.7), tostring(ratio("ChargeTime")))
  check("Sleevers damage x0.95", near(ratio("DamagePerHit"), 0.95), tostring(ratio("DamagePerHit")))
elseif gun:find("Yukimura") then
  check("Dumbfires damage x1.25", near(ratio("DamagePerHit"), 1.25), tostring(ratio("DamagePerHit")))
  check("Dumbfires hit probability 0", stat("SmartGunHitProbability") == 0, tostring(stat("SmartGunHitProbability")))
end
report()

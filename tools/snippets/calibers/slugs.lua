-- 12ga and 4ga Slugs on the drawn shotgun. Run through slugs.sh: MODE='base' with Buckshot fitted
-- stores the stats, MODE='check' with Slugs fitted compares (stored in AO_SLUGS between runs).
-- MODE='static' checks the 4ga Slug's knockdown entry.
if MODE == "static" then
  local d = tostring(Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem"):DebugHitData("Ammo.AO_4ga_Slug"))
  check("4ga Slugs knock the target down (aoEffects)", d:find("effects=BaseStatusEffect.Knockdown:1;", 1, true) ~= nil, d)
  report()
  return
end
local w = Game.GetPlayer():GetActiveWeapon()
local function stat(name) return Game.GetStatsSystem():GetStatValue(w:GetEntityID(), gamedataStatType[name]) end
local names = { "ProjectilesPerShot", "DamagePerHit", "SpreadDefaultX", "SpreadAdsDefaultX", "EffectiveRange",
  "CanWeaponIgnoreArmor", "RecoilKickMax" }
local gun = str(w:GetItemID().id)
AO_SLUGS = AO_SLUGS or {}
if MODE == "base" then
  local s = {}
  for _, n in ipairs(names) do s[n] = stat(n); print("base " .. gun .. " " .. n .. " " .. s[n]) end
  AO_SLUGS[gun] = s
  return
end
local base = AO_SLUGS[gun]
if not base then check(gun .. " base stored", false, "run MODE='base' first"); report(); return end
local function ratio(n) return base[n] ~= 0 and stat(n) / base[n] or 0 end
local function near(a, b) return math.abs(a - b) < 0.01 end
for _, n in ipairs(names) do print("now  " .. gun .. " " .. n .. " " .. stat(n)) end
local big = gun:find("Carnage") ~= nil
local dmg = base.ProjectilesPerShot * (big and 1.3 or 1)
check(gun .. " one projectile", stat("ProjectilesPerShot") == 1, tostring(stat("ProjectilesPerShot")))
check(gun .. " damage x" .. dmg .. " (the whole shot in one slug)", near(ratio("DamagePerHit"), dmg), tostring(ratio("DamagePerHit")))
check(gun .. " tighter spread", ratio("SpreadDefaultX") < 0.5 and ratio("SpreadAdsDefaultX") < 0.5,
  ratio("SpreadDefaultX") .. " " .. ratio("SpreadAdsDefaultX"))
check(gun .. " range x2", near(ratio("EffectiveRange"), 2), tostring(ratio("EffectiveRange")))
if big then
  check(gun .. " pen +0.5", near(stat("CanWeaponIgnoreArmor") - base.CanWeaponIgnoreArmor, 0.5), tostring(stat("CanWeaponIgnoreArmor")))
  check(gun .. " recoil x1.6", near(ratio("RecoilKickMax"), 1.6), tostring(ratio("RecoilKickMax")))
end
report()

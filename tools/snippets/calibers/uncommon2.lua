-- Second Uncommon rounds on the drawn gun. Run through uncommon2.sh: MODE='base' with the Common
-- selector fitted stores the stats, MODE='check' with LOAD's selector fitted compares (stored in
-- AO_UNC2 between runs). LOAD is PlusP, Birdshot, Birdshot4, Bricks or ShortFuse.
local w = Game.GetPlayer():GetActiveWeapon()
local function stat(name) return Game.GetStatsSystem():GetStatValue(w:GetEntityID(), gamedataStatType[name]) end
local names = { "DamagePerHit", "EffectiveRange", "RecoilKickMin", "RecoilKickMax", "WeaponEvolutionToStaminaCost",
  "ProjectilesPerShot", "SpreadDefaultX", "SpreadAdsDefaultX", "SpreadMaxY", "CanWeaponIgnoreArmor",
  "HitReactionFactor", "ChargeTime", "MaximumRange" }
local gun = str(w:GetItemID().id)
AO_UNC2 = AO_UNC2 or {}
if MODE == "base" then
  local s = {}
  for _, n in ipairs(names) do s[n] = stat(n) end
  AO_UNC2[gun] = s
  return "stored " .. gun
end
local base = AO_UNC2[gun]
if not base then check(gun .. " base stored", false, "run MODE='base' first"); report(); return end
local function ratio(n) return base[n] ~= 0 and stat(n) / base[n] or 0 end
local function near(a, b) return math.abs(a - b) < 0.01 end
local function is(n, want) check(gun .. " " .. LOAD .. " " .. n .. " x" .. want, near(ratio(n), want), tostring(ratio(n))) end
if LOAD == "PlusP" then
  is("DamagePerHit", 1.1); is("EffectiveRange", 1.15); is("RecoilKickMin", 1.25); is("RecoilKickMax", 1.25)
  is("WeaponEvolutionToStaminaCost", 1.3)
elseif LOAD == "Birdshot" or LOAD == "Birdshot4" then
  local pellets, spread = LOAD == "Birdshot" and 2 or 2.5, LOAD == "Birdshot" and 1.6 or 2
  check(gun .. " pellets x" .. pellets, near(ratio("ProjectilesPerShot"), pellets),
    base.ProjectilesPerShot .. " -> " .. stat("ProjectilesPerShot"))
  check(gun .. " the shot's total damage is unchanged", near(ratio("DamagePerHit") * ratio("ProjectilesPerShot"), 1),
    tostring(ratio("DamagePerHit") * ratio("ProjectilesPerShot")))
  is("SpreadDefaultX", spread); is("SpreadAdsDefaultX", spread)
  check(gun .. " armor pen -0.5", near(stat("CanWeaponIgnoreArmor") - base.CanWeaponIgnoreArmor, -0.5), tostring(stat("CanWeaponIgnoreArmor")))
  check(gun .. " flinch +0.5", near(stat("HitReactionFactor") - base.HitReactionFactor, 0.5), tostring(stat("HitReactionFactor")))
elseif LOAD == "Bricks" then
  is("DamagePerHit", 1.15); is("ChargeTime", 1.3)
elseif LOAD == "ShortFuse" then
  is("DamagePerHit", 1.2); is("MaximumRange", 0.4)
end
report()

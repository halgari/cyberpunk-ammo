-- Caliber profiles (spec "Caliber profiles"): each caliber's AOProfile.<Caliber> group holds its
-- damage / pen / recoil / range modifiers, and the startup tweak adds it to the caliber's guns.
--   tools/linux/cet.sh "$(cat tools/snippets/slice/common.lua tools/snippets/calibers/profiles.lua)"
-- With LIVE=true, also checks the drawn gun's stats against LIVE_EXPECT (values without the
-- profile measured on the build before profiles, see the comments).
local PROFILES = {
  -- caliber = { damage x, pen +, recoil x, range x }
  Power_9mm = { 1.00, 0, 1.00, 1.00 },
  Tech_Light = { 1.00, 0, 1.00, 1.00 },
  Smart_10 = { 1.00, -0.10, 1.00, 1.00 },
  Power_45 = { 1.10, -0.15, 1.10, 1.00 },
  Power_12mm = { 1.15, 0.10, 1.35, 1.00 },
  Power_556 = { 1.00, 0.15, 1.00, 1.00 },
  Power_762 = { 1.05, 0.25, 1.20, 1.10 },
  Power_127 = { 1.00, 0.40, 1.25, 1.00 },
  Tech_Heavy = { 1.00, 0.20, 1.20, 1.00 },
  Smart_20 = { 1.00, -0.20, 1.00, 1.00 },
  Smart_25 = { 1.00, 0.10, 1.00, 1.00 },
  Power_12ga = { 1.00, -0.25, 1.00, 0.75 },
  Power_4ga = { 1.00, -0.25, 1.30, 1.00 },
}
local GUNS = {
  { "Power_9mm", "Items.Preset_Lexington_Default" },
  { "Tech_Light", "Items.Preset_Omaha_Default" },
  { "Smart_10", "Items.Preset_Yukimura_Default" },
  { "Power_45", "Items.Preset_Unity_Default" },
  { "Power_45", "Items.Preset_Nue_Jackie" },
  { "Power_12mm", "Items.Preset_Overture_Default" },
  { "Power_12mm", "Items.Preset_Silverhand_3516" },
  { "Power_556", "Items.Preset_Umbra_Default" },
  { "Power_762", "Items.Preset_Ajax_Default" },
  { "Power_127", "Items.Preset_Grad_Default" },
  { "Power_127", "Items.Preset_Kolac_Default" },
  { "Tech_Heavy", "Items.Preset_Burya_Default" },
  { "Tech_Heavy", "Items.Preset_Tech_Sniper_Rifle_Default" },
  { "Smart_20", "Items.Preset_Palica_Default" },
  { "Smart_25", "Items.Preset_Ashura_Default" },
  { "Smart_10", "Items.Preset_Hercules_Default" },
  { "Power_12ga", "Items.Preset_Tactician_Default" },
  { "Power_12ga", "Items.Preset_Igla_Sovereign" },
  { "Power_4ga", "Items.Preset_Carnage_Default" },
}
-- gun = { stat, expected value with the Common round fitted }
local LIVE_EXPECT = {
  -- Yukimura CanWeaponIgnoreArmor was 0 before profiles (measured 2026-10-28).
  ["Items.Preset_Yukimura_Default"] = { "CanWeaponIgnoreArmor", -0.10 },
  -- Power guns have no pen of their own: Unity's is the profile's.
  ["Items.Preset_Unity_Default"] = { "CanWeaponIgnoreArmor", -0.15 },
}

local function near(a, b) return math.abs((a or 0) - b) < 0.001 end
-- stat -> { modifierType = value } of a record's ConstantStatModifiers
local function mods(id)
  local m = {}
  for _, x in ipairs(flat(id, "statModifiers") or {}) do
    local s = str(flat(x, "statType")):gsub("^BaseStats%.", "")
    local t = flat(x, "modifierType")
    m[s] = m[s] or {}
    m[s][t and t.value or "?"] = flat(x, "value")
  end
  return m
end
local function expectMod(name, m, stat, mtype, want, neutral)
  local got = m[stat] and m[stat][mtype]
  if want == neutral then
    check(name .. " no " .. stat .. " modifier (neutral)", got == nil, tostring(got))
  else
    check(name .. " " .. stat .. " " .. mtype .. " " .. want, near(got, want), tostring(got))
  end
end

for cal, p in pairs(PROFILES) do
  local id = "AOProfile." .. cal
  local r = rec(id)
  check(id .. " exists", r ~= nil, "no record")
  check("AmmoOverhaul." .. cal .. ".profile flat", str(flat("AmmoOverhaul." .. cal, "profile") or TweakDBID.new("")) == id,
    tostring(flat("AmmoOverhaul." .. cal, "profile")))
  if r then
    local m = mods(id)
    expectMod(id, m, "DamagePerHit", "Multiplier", p[1], 1)
    expectMod(id, m, "CanWeaponIgnoreArmor", "Additive", p[2], 0)
    expectMod(id, m, "RecoilKickMin", "Multiplier", p[3], 1)
    expectMod(id, m, "RecoilKickMax", "Multiplier", p[3], 1)
    expectMod(id, m, "EffectiveRange", "Multiplier", p[4], 1)
  end
end

for _, row in ipairs(GUNS) do
  local cal, gun = row[1], row[2]
  local n = 0
  for _, g in ipairs(flat(gun, "statModifierGroups") or {}) do
    if str(g) == "AOProfile." .. cal then n = n + 1 end
  end
  check(gun .. " has AOProfile." .. cal .. " once", n == 1, tostring(n))
end

if LIVE then
  local w = Game.GetPlayer():GetActiveWeapon()
  local gun = w and str(w:GetItemID().id) or "none"
  local e = LIVE_EXPECT[gun]
  check("live gun has an expectation", e ~= nil, gun)
  if e then
    local v = Game.GetStatsSystem():GetStatValue(w:GetEntityID(), gamedataStatType[e[1]])
    check("live " .. gun .. " " .. e[1] .. " = " .. e[2], near(v, e[2]), tostring(v))
  end
end
report()

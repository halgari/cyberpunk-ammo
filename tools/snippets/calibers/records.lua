-- v1 calibers: each caliber's rounds and selectors exist with their names, weights and prices,
-- and its guns (iconics included) load its Common round and carry its feed slot.
--   tools/snippets/calibers/check.sh calibers/records.lua
local ROUNDS = {
  -- round, name, weight, selector, price multiplier on the source ammo's price
  { "Ammo.AO_45_Ball", ".45 Ball", 0.09, "Items.AO_Feed_45_Ball", 1.2 },
  { "Ammo.AO_45_HollowPoint", ".45 Mushrooms", 0.09, "Items.AO_Feed_45_Mushrooms", 1.2 },
  { "Ammo.AO_12mm_Ball", "12mm Ball", 0.12, "Items.AO_Feed_12mm_Ball", 1.6 },
  { "Ammo.AO_12mm_HollowPoint", "12mm Mushrooms", 0.12, "Items.AO_Feed_12mm_Mushrooms", 1.6 },
  { "Ammo.RifleAmmo", "5.56 Ball", 0.06, "Items.AO_Feed_556_Ball", 1 },
  { "Ammo.AO_556_HollowPoint", "5.56 Mushrooms", 0.06, "Items.AO_Feed_556_Mushrooms", 1 },
  { "Ammo.AO_762_Ball", "7.62 Ball", 0.09, "Items.AO_Feed_762_Ball", 1.3 },
  { "Ammo.AO_762_HollowPoint", "7.62 Mushrooms", 0.09, "Items.AO_Feed_762_Mushrooms", 1.3 },
  { "Ammo.SniperRifleAmmo", "12.7 Ball", 0.15, "Items.AO_Feed_127_Ball", 2 },
  { "Ammo.AO_127_HollowPoint", "12.7 Mushrooms", 0.15, "Items.AO_Feed_127_Mushrooms", 2 },
  { "Ammo.AO_THeavy_Slug", "Heavy Rail Slugs", 0.08, "Items.AO_Feed_Heavy_RailSlugs", 1.5 },
  { "Ammo.AO_THeavy_Sabot", "Heavy Sleevers", 0.08, "Items.AO_Feed_Heavy_Sleevers", 1.5 },
  { "Ammo.AO_S20_Standard", "20mm Seekers", 0.12, "Items.AO_Feed_20mm_Seekers", 1.3 },
  { "Ammo.AO_S20_Dumbfire", "20mm Dumbfires", 0.12, "Items.AO_Feed_20mm_Dumbfires", 1.3 },
  { "Ammo.AO_S25_Standard", "25mm Seekers", 0.24, "Items.AO_Feed_25mm_Seekers", 2.5 },
  { "Ammo.AO_S25_Dumbfire", "25mm Dumbfires", 0.24, "Items.AO_Feed_25mm_Dumbfires", 2.5 },
  { "Ammo.ShotgunAmmo", "Buckshot", 0.06, "Items.AO_Feed_12ga_Buckshot", 1 },
  { "Ammo.AO_12ga_Slug", "Slugs", 0.06, "Items.AO_Feed_12ga_Slugs", 1 },
  { "Ammo.AO_4ga_Buckshot", "4ga Buckshot", 0.15, "Items.AO_Feed_4ga_Buckshot", 2 },
  { "Ammo.AO_4ga_Slug", "4ga Slugs", 0.15, "Items.AO_Feed_4ga_Slugs", 2 },
}
local GUNS = {
  -- weapon record, Common round, feed element
  { "Items.Preset_Unity_Default", "Ammo.AO_45_Ball", "Items.AO_AmmoFeed_Power_45_Element" },
  { "Items.Preset_Unity_Agent", "Ammo.AO_45_Ball", "Items.AO_AmmoFeed_Power_45_Element" },
  { "Items.Preset_Liberty_Default", "Ammo.AO_45_Ball", "Items.AO_AmmoFeed_Power_45_Element" },
  { "Items.Preset_Liberty_Padre", "Ammo.AO_45_Ball", "Items.AO_AmmoFeed_Power_45_Element" },
  { "Items.Preset_Nue_Default", "Ammo.AO_45_Ball", "Items.AO_AmmoFeed_Power_45_Element" },
  { "Items.Preset_Nue_Jackie", "Ammo.AO_45_Ball", "Items.AO_AmmoFeed_Power_45_Element" },
  { "Items.Preset_Nue_Arasaka_2077", "Ammo.AO_45_Ball", "Items.AO_AmmoFeed_Power_45_Element" },
  { "Items.Preset_Nova_Default", "Ammo.AO_12mm_Ball", "Items.AO_AmmoFeed_Power_12mm_Element" },
  { "Items.Preset_Nova_Doom_Doom", "Ammo.AO_12mm_Ball", "Items.AO_AmmoFeed_Power_12mm_Element" },
  { "Items.Preset_Overture_Default", "Ammo.AO_12mm_Ball", "Items.AO_AmmoFeed_Power_12mm_Element" },
  { "Items.Preset_Overture_River", "Ammo.AO_12mm_Ball", "Items.AO_AmmoFeed_Power_12mm_Element" },
  { "Items.Preset_Metel_Default", "Ammo.AO_12mm_Ball", "Items.AO_AmmoFeed_Power_12mm_Element" },
  { "Items.Preset_Metel_Kurt", "Ammo.AO_12mm_Ball", "Items.AO_AmmoFeed_Power_12mm_Element" },
  { "Items.Preset_Silverhand_3516", "Ammo.AO_12mm_Ball", "Items.AO_AmmoFeed_Power_12mm_Element" },
  { "Items.Preset_Umbra_Default", "Ammo.RifleAmmo", "Items.AO_AmmoFeed_Power_556_Element" },
  { "Items.Preset_Umbra_Bebe", "Ammo.RifleAmmo", "Items.AO_AmmoFeed_Power_556_Element" },
  { "Items.Preset_Masamune_Default", "Ammo.RifleAmmo", "Items.AO_AmmoFeed_Power_556_Element" },
  { "Items.Preset_Masamune_Arasaka_2077", "Ammo.RifleAmmo", "Items.AO_AmmoFeed_Power_556_Element" },
  { "Items.Preset_Copperhead_Default", "Ammo.RifleAmmo", "Items.AO_AmmoFeed_Power_556_Element" },
  { "Items.Preset_Copperhead_Genesis", "Ammo.RifleAmmo", "Items.AO_AmmoFeed_Power_556_Element" },
  { "Items.Preset_Defender_Default", "Ammo.RifleAmmo", "Items.AO_AmmoFeed_Power_556_Element" },
  { "Items.Preset_Defender_Kurt", "Ammo.RifleAmmo", "Items.AO_AmmoFeed_Power_556_Element" },
  { "Items.Preset_Ajax_Default", "Ammo.AO_762_Ball", "Items.AO_AmmoFeed_Power_762_Element" },
  { "Items.Preset_Ajax_Moron", "Ammo.AO_762_Ball", "Items.AO_AmmoFeed_Power_762_Element" },
  { "Items.Preset_Kyubi_Default", "Ammo.AO_762_Ball", "Items.AO_AmmoFeed_Power_762_Element" },
  { "Items.Preset_Kyubi_Myers", "Ammo.AO_762_Ball", "Items.AO_AmmoFeed_Power_762_Element" },
  { "Items.Preset_MA70_Default", "Ammo.AO_762_Ball", "Items.AO_AmmoFeed_Power_762_Element" },
  { "Items.Preset_Kolac_Default", "Ammo.SniperRifleAmmo", "Items.AO_AmmoFeed_Power_127_Element" },
  { "Items.Preset_Kolac_Tiny_Mike", "Ammo.SniperRifleAmmo", "Items.AO_AmmoFeed_Power_127_Element" },
  { "Items.Preset_Sor22_Default", "Ammo.SniperRifleAmmo", "Items.AO_AmmoFeed_Power_127_Element" },
  { "Items.Preset_Grad_Default", "Ammo.SniperRifleAmmo", "Items.AO_AmmoFeed_Power_127_Element" },
  { "Items.Preset_Grad_Panam", "Ammo.SniperRifleAmmo", "Items.AO_AmmoFeed_Power_127_Element" },
  { "Items.Preset_Osprey_Default", "Ammo.SniperRifleAmmo", "Items.AO_AmmoFeed_Power_127_Element" },
  { "Items.Preset_Osprey_Prototype", "Ammo.SniperRifleAmmo", "Items.AO_AmmoFeed_Power_127_Element" },
  { "Items.Preset_HMG_Default", "Ammo.SniperRifleAmmo", "Items.AO_AmmoFeed_Power_127_Element" },
  { "Items.Preset_Burya_Default", "Ammo.AO_THeavy_Slug", "Items.AO_AmmoFeed_Tech_Heavy_Element" },
  { "Items.Preset_Burya_Comrade", "Ammo.AO_THeavy_Slug", "Items.AO_AmmoFeed_Tech_Heavy_Element" },
  { "Items.Preset_Achilles_Default", "Ammo.AO_THeavy_Slug", "Items.AO_AmmoFeed_Tech_Heavy_Element" },
  { "Items.Preset_Achilles_Nash", "Ammo.AO_THeavy_Slug", "Items.AO_AmmoFeed_Tech_Heavy_Element" },
  { "Items.Preset_Nekomata_Default", "Ammo.AO_THeavy_Slug", "Items.AO_AmmoFeed_Tech_Heavy_Element" },
  { "Items.Preset_Nekomata_Breakthrough", "Ammo.AO_THeavy_Slug", "Items.AO_AmmoFeed_Tech_Heavy_Element" },
  { "Items.Preset_Rasetsu_Prototype", "Ammo.AO_THeavy_Slug", "Items.AO_AmmoFeed_Tech_Heavy_Element" },
  { "Items.Preset_Tech_Sniper_Rifle_Default", "Ammo.AO_THeavy_Slug", "Items.AO_AmmoFeed_Tech_Heavy_Element" },
  { "Items.Preset_Satara_Default", "Ammo.AO_THeavy_Slug", "Items.AO_AmmoFeed_Tech_Heavy_Element" },
  { "Items.Preset_Satara_Brick", "Ammo.AO_THeavy_Slug", "Items.AO_AmmoFeed_Tech_Heavy_Element" },
  { "Items.Preset_Zhuo_Default", "Ammo.AO_S20_Standard", "Items.AO_AmmoFeed_Smart_20_Element" },
  { "Items.Preset_Zhuo_Eight_Star", "Ammo.AO_S20_Standard", "Items.AO_AmmoFeed_Smart_20_Element" },
  { "Items.Preset_Palica_Default", "Ammo.AO_S20_Standard", "Items.AO_AmmoFeed_Smart_20_Element" },
  { "Items.Preset_Ashura_Default", "Ammo.AO_S25_Standard", "Items.AO_AmmoFeed_Smart_25_Element" },
  { "Items.Preset_Ashura_Twitch", "Ammo.AO_S25_Standard", "Items.AO_AmmoFeed_Smart_25_Element" },
  { "Items.Preset_Hercules_Default", "Ammo.AO_S10_Standard", "Items.AO_AmmoFeed_Smart_10_Element" },
  { "Items.Preset_Sidewinder_Default", "Ammo.AO_S10_Standard", "Items.AO_AmmoFeed_Smart_10_Element" },
  { "Items.Preset_Sidewinder_Divided", "Ammo.AO_S10_Standard", "Items.AO_AmmoFeed_Smart_10_Element" },
  { "Items.Preset_Crusher_Default", "Ammo.ShotgunAmmo", "Items.AO_AmmoFeed_Power_12ga_Element" },
  { "Items.Preset_Crusher_Amazon", "Ammo.ShotgunAmmo", "Items.AO_AmmoFeed_Power_12ga_Element" },
  { "Items.Preset_Pozhar_Default", "Ammo.ShotgunAmmo", "Items.AO_AmmoFeed_Power_12ga_Element" },
  { "Items.Preset_Tactician_Default", "Ammo.ShotgunAmmo", "Items.AO_AmmoFeed_Power_12ga_Element" },
  { "Items.Preset_Tactician_Headsman", "Ammo.ShotgunAmmo", "Items.AO_AmmoFeed_Power_12ga_Element" },
  { "Items.Preset_Igla_Default", "Ammo.ShotgunAmmo", "Items.AO_AmmoFeed_Power_12ga_Element" },
  { "Items.Preset_Igla_Sovereign", "Ammo.ShotgunAmmo", "Items.AO_AmmoFeed_Power_12ga_Element" },
  { "Items.Preset_Testera_Default", "Ammo.ShotgunAmmo", "Items.AO_AmmoFeed_Power_12ga_Element" },
  { "Items.Preset_Testera_Nicolas", "Ammo.ShotgunAmmo", "Items.AO_AmmoFeed_Power_12ga_Element" },
  { "Items.Preset_Carnage_Default", "Ammo.AO_4ga_Buckshot", "Items.AO_AmmoFeed_Power_4ga_Element" },
  { "Items.Preset_Carnage_Mox", "Ammo.AO_4ga_Buckshot", "Items.AO_AmmoFeed_Power_4ga_Element" },
  -- Erebus stays 9mm.
  { "Items.Preset_Borg4a_HauntedGun", "Ammo.HandgunAmmo", "Items.AO_AmmoFeed_Power_9mm_Element" },
}
-- Guns left alone: their ammo isn't ammo (Plan B fires eddies).
-- Boss and mounted HMGs keep theirs (enemy loadouts aren't changed).
local UNTOUCHED = { { "Items.Preset_Liberty_Dex", "Items.money" }, { "Items.Smasher_HMG", "Ammo.Standard" },
  { "Items.Preset_HMG_turret_car_attach", "Ammo.Standard" } }

local function near(a, b) return math.abs(a - b) < 0.001 end
-- Product of the Multiplier modifiers on a price list, leaving out the game's Price.* records.
local function priceMult(id, field)
  local m = 1
  for _, x in ipairs(flat(id, field) or {}) do
    local t = flat(x, "modifierType")
    if not str(x):find("^Price%.") and t and t.value == "Multiplier" and str(flat(x, "statType")) == "BaseStats.Price" then
      m = m * flat(x, "value")
    end
  end
  return m
end

for _, r in ipairs(ROUNDS) do
  local ammo, name, weight, sel, price = r[1], r[2], r[3], r[4], r[5]
  check(ammo .. " exists", rec(ammo) ~= nil)
  check(ammo .. " name " .. name, locName(ammo) == name, tostring(locName(ammo)))
  local w = statSum(ammo, "Weight")
  check(ammo .. " weight " .. weight, near(w, weight), tostring(w))
  for _, f in ipairs({ "buyPrice", "sellPrice" }) do
    local p = priceMult(ammo, f)
    check(ammo .. " " .. f .. " x" .. price, near(p, price), tostring(p))
  end
  check(sel .. " exists", rec(sel) ~= nil)
  check(sel .. " name " .. name, locName(sel) == name, tostring(locName(sel)))
end

for _, g in ipairs(GUNS) do
  check(g[1] .. " ammo " .. g[2], str(flat(g[1], "ammo")) == g[2], str(flat(g[1], "ammo")))
  local root = flat(flat(g[1], "blueprint"), "rootElement")
  local found = false
  for _, c in ipairs(flat(root, "childElements") or {}) do if str(c) == g[3] then found = true end end
  check(g[1] .. " feed element", found, str(root))
end
for _, g in ipairs(UNTOUCHED) do
  check(g[1] .. " keeps ammo " .. g[2], str(flat(g[1], "ammo")) == g[2], str(flat(g[1], "ammo")))
end

-- No weapon record is claimed by two calibers (it would get two feed slots and two profiles).
local cals = {}
for _, c in ipairs(flat("AmmoOverhaul", "calibers") or {}) do
  local tags, recs = {}, {}
  for _, t in ipairs(flat("AmmoOverhaul." .. c, "weaponTags") or {}) do tags[type(t) == "string" and t or t.value] = true end
  for _, r in ipairs(flat("AmmoOverhaul." .. c, "weaponRecords") or {}) do recs[type(r) == "string" and r or str(r)] = true end
  table.insert(cals, { c, tags, recs })
end
local doubles = {}
for _, r in ipairs(TweakDB:GetRecords("gamedataWeaponItem_Record")) do
  local id = str(r:GetID())
  local claimed = {}
  for _, c in ipairs(cals) do
    local hit = c[3][id] or false
    for _, t in ipairs(r:Tags()) do if c[2][t.value] then hit = true end end
    if hit then table.insert(claimed, c[1]) end
  end
  if #claimed > 1 then table.insert(doubles, id .. "=" .. table.concat(claimed, "+")) end
end
check(#cals .. " calibers read for the double-claim scan", #cals >= 8, tostring(#cals))
check("no weapon record claimed by two calibers", #doubles == 0, table.concat(doubles, " "))
report()

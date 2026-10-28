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
report()

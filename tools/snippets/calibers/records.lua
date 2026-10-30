-- v1 calibers: each caliber's rounds and selectors exist with their names, weights and prices,
-- and its guns (iconics included) load its Common round and carry its feed slot.
--   tools/snippets/calibers/check.sh calibers/records.lua
local ROUNDS = {
  -- round, name, weight, selector, price multiplier on the source ammo's price (Uncommon x2 on top)
  { "Ammo.AO_45_Ball", ".45 Ball", 0.09, "Items.AO_Feed_45_Ball", 1.2 },
  { "Ammo.AO_45_HollowPoint", ".45 Mushrooms", 0.09, "Items.AO_Feed_45_Mushrooms", 2.4 },
  { "Ammo.AO_12mm_Ball", "12mm Ball", 0.12, "Items.AO_Feed_12mm_Ball", 1.6 },
  { "Ammo.AO_12mm_HollowPoint", "12mm Mushrooms", 0.12, "Items.AO_Feed_12mm_Mushrooms", 3.2 },
  { "Ammo.RifleAmmo", "5.56 Ball", 0.06, "Items.AO_Feed_556_Ball", 1 },
  { "Ammo.AO_556_HollowPoint", "5.56 Mushrooms", 0.06, "Items.AO_Feed_556_Mushrooms", 2 },
  { "Ammo.AO_762_Ball", "7.62 Ball", 0.09, "Items.AO_Feed_762_Ball", 1.3 },
  { "Ammo.AO_762_HollowPoint", "7.62 Mushrooms", 0.09, "Items.AO_Feed_762_Mushrooms", 2.6 },
  { "Ammo.SniperRifleAmmo", "12.7 Ball", 0.15, "Items.AO_Feed_127_Ball", 2 },
  { "Ammo.AO_127_HollowPoint", "12.7 Mushrooms", 0.15, "Items.AO_Feed_127_Mushrooms", 4 },
  { "Ammo.AO_THeavy_Slug", "Heavy Rail Slugs", 0.08, "Items.AO_Feed_Heavy_RailSlugs", 1.5 },
  { "Ammo.AO_THeavy_Sabot", "Heavy Sleevers", 0.08, "Items.AO_Feed_Heavy_Sleevers", 3 },
  { "Ammo.AO_S20_Standard", "20mm Seekers", 0.12, "Items.AO_Feed_20mm_Seekers", 1.3 },
  { "Ammo.AO_S20_Dumbfire", "20mm Dumbfires", 0.12, "Items.AO_Feed_20mm_Dumbfires", 2.6 },
  { "Ammo.AO_S25_Standard", "25mm Seekers", 0.24, "Items.AO_Feed_25mm_Seekers", 2.5 },
  { "Ammo.AO_S25_Dumbfire", "25mm Dumbfires", 0.24, "Items.AO_Feed_25mm_Dumbfires", 5 },
  { "Ammo.ShotgunAmmo", "Buckshot", 0.06, "Items.AO_Feed_12ga_Buckshot", 1 },
  { "Ammo.AO_12ga_Slug", "Slugs", 0.06, "Items.AO_Feed_12ga_Slugs", 2 },
  { "Ammo.AO_4ga_Buckshot", "4ga Buckshot", 0.15, "Items.AO_Feed_4ga_Buckshot", 2 },
  { "Ammo.AO_4ga_Slug", "4ga Slugs", 0.15, "Items.AO_Feed_4ga_Slugs", 4 },
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

-- Second Uncommon rounds: name, weight, price and quality as their caliber's first Uncommon,
-- listed at tier 1 in the caliber's selectors.
local SECOND = {
  -- caliber, round, name, selector, the caliber's first Uncommon round
  { "Power_9mm", "Ammo.AO_9mm_PlusP", "9mm +P", "Items.AO_Feed_9mm_PlusP", "Ammo.AO_9mm_HollowPoint" },
  { "Power_45", "Ammo.AO_45_PlusP", ".45 +P", "Items.AO_Feed_45_PlusP", "Ammo.AO_45_HollowPoint" },
  { "Power_12mm", "Ammo.AO_12mm_PlusP", "12mm +P", "Items.AO_Feed_12mm_PlusP", "Ammo.AO_12mm_HollowPoint" },
  { "Power_556", "Ammo.AO_556_PlusP", "5.56 +P", "Items.AO_Feed_556_PlusP", "Ammo.AO_556_HollowPoint" },
  { "Power_762", "Ammo.AO_762_PlusP", "7.62 +P", "Items.AO_Feed_762_PlusP", "Ammo.AO_762_HollowPoint" },
  { "Power_127", "Ammo.AO_127_PlusP", "12.7 +P", "Items.AO_Feed_127_PlusP", "Ammo.AO_127_HollowPoint" },
  { "Power_12ga", "Ammo.AO_12ga_Birdshot", "Birdshot", "Items.AO_Feed_12ga_Birdshot", "Ammo.AO_12ga_Slug" },
  { "Power_4ga", "Ammo.AO_4ga_Birdshot", "4ga Birdshot", "Items.AO_Feed_4ga_Birdshot", "Ammo.AO_4ga_Slug" },
  { "Tech_Light", "Ammo.AO_TLight_Bricks", "5mm Bricks", "Items.AO_Feed_5mm_Bricks", "Ammo.AO_TLight_Sabot" },
  { "Tech_Heavy", "Ammo.AO_THeavy_Bricks", "Heavy Bricks", "Items.AO_Feed_Heavy_Bricks", "Ammo.AO_THeavy_Sabot" },
  { "Smart_10", "Ammo.AO_S10_ShortFuse", "10mm Short-Fuse", "Items.AO_Feed_10mm_ShortFuse", "Ammo.AO_S10_Dumbfire" },
  { "Smart_20", "Ammo.AO_S20_ShortFuse", "20mm Short-Fuse", "Items.AO_Feed_20mm_ShortFuse", "Ammo.AO_S20_Dumbfire" },
  { "Smart_25", "Ammo.AO_S25_ShortFuse", "25mm Short-Fuse", "Items.AO_Feed_25mm_ShortFuse", "Ammo.AO_S25_Dumbfire" },
}
for _, r in ipairs(SECOND) do
  local cal, ammo, name, sel, first = r[1], r[2], r[3], r[4], r[5]
  check(ammo .. " exists", rec(ammo) ~= nil)
  check(ammo .. " name " .. name, locName(ammo) == name, tostring(locName(ammo)))
  local desc = rec(ammo) and Game.GetLocalizedTextByKey(rec(ammo):LocalizedDescription()) or ""
  check(ammo .. " has a description", desc ~= "" and not desc:find("^AO%-"), desc)
  check(ammo .. " weight as " .. first, near(statSum(ammo, "Weight"), statSum(first, "Weight")), tostring(statSum(ammo, "Weight")))
  check(ammo .. " price as " .. first, near(priceMult(ammo, "buyPrice"), priceMult(first, "buyPrice")), tostring(priceMult(ammo, "buyPrice")))
  check(ammo .. " Uncommon", str(flat(ammo, "quality")) == "Quality.Uncommon", str(flat(ammo, "quality")))
  check(sel .. " name " .. name, rec(sel) ~= nil and locName(sel) == name, tostring(rec(sel) and locName(sel)))
  check(sel .. " Uncommon", str(flat(sel, "quality")) == "Quality.Uncommon", str(flat(sel, "quality")))
  local sels, ammos, tiers = flat("AmmoOverhaul." .. cal, "selectors") or {}, flat("AmmoOverhaul." .. cal, "selectorAmmo") or {}, flat("AmmoOverhaul." .. cal, "selectorTiers") or {}
  local at = nil
  for i, x in ipairs(sels) do if str(x) == sel then at = i end end
  check(cal .. " lists " .. sel .. " at tier 1 for " .. ammo, at ~= nil and tiers[at] == 1 and str(ammos[at]) == ammo,
    at and (tostring(tiers[at]) .. " " .. str(ammos[at])) or "not listed")
end

-- Rare and Epic rounds (tools/rounds/rounds.py), every caliber: quality, price x4 / x8 of the
-- Common round (on the price lists), the Common round's weight, text, icon, a hidden selector of the
-- tier's quality, no damage-type or machine stats on the selector (those are hit data, applied to
-- V and NPCs alike), valid hit data.
local QUAL, PRICE = { [2] = "Quality.Rare", [3] = "Quality.Epic", [4] = "Quality.Legendary" }, { [2] = 4, [3] = 8, [4] = 16 }
local SHARE_TYPES = { Thermal = true, Chemical = true, Electric = true }
local BANNED = { ["BaseStats.ThermalDamage"] = true, ["BaseStats.ChemicalDamage"] = true, ["BaseStats.ElectricDamage"] = true,
  ["BaseStats.BonusDamageAgainstMechanicals"] = true }
local counted = { [2] = 0, [3] = 0, [4] = 0 }
for _, cal in ipairs(flat("AmmoOverhaul", "calibers") or {}) do
  local K = "AmmoOverhaul." .. cal
  local sels, ammos, tiers = flat(K, "selectors") or {}, flat(K, "selectorAmmo") or {}, flat(K, "selectorTiers") or {}
  local common = str(ammos[1])
  for i, t in ipairs(tiers) do
    if t >= 2 then
      local ammo, sel = str(ammos[i]), str(sels[i])
      counted[t] = counted[t] + 1
      local bad = {}
      local function need(ok, what) if not ok then table.insert(bad, what) end end
      need(rec(ammo) ~= nil and rec(sel) ~= nil, "records exist")
      if rec(ammo) and rec(sel) then
        need(str(flat(ammo, "quality")) == QUAL[t] and str(flat(sel, "quality")) == QUAL[t], "quality " .. str(flat(ammo, "quality")))
        local p, pc = priceMult(ammo, "buyPrice"), priceMult(common, "buyPrice")
        need(near(p, pc * PRICE[t]) and near(priceMult(ammo, "sellPrice"), p), string.format("price x%.2f of Common's x%.2f", p, pc))
        need(near(statSum(ammo, "Weight"), statSum(common, "Weight")), "weight " .. statSum(ammo, "Weight"))
        local name, desc = locName(ammo) or "", Game.GetLocalizedTextByKey(rec(ammo):LocalizedDescription())
        need(name ~= "" and not name:find("^AO%-") and locName(sel) == name, "name " .. name)
        need(desc ~= "" and not desc:find("^AO%-") and desc:find("\n\n", 1, true) ~= nil, "description")
        need(rec("UIIcon." .. tostring(flat(ammo, "iconPath"))) ~= nil, "icon record")
        local tags = {}
        for _, x in ipairs(flat(sel, "tags") or {}) do tags[type(x) == "string" and x or x.value] = true end
        need(tags.HideInBackpackUI and tags.AO_AmmoSelector, "selector tags")
        for _, m in ipairs(flat(sel, "statModifiers") or {}) do
          need(not BANNED[str(flat(m, "statType"))], "selector carries " .. str(flat(m, "statType")))
        end
        local fx, ch = flat(ammo, "aoEffects") or {}, flat(ammo, "aoEffectChances") or {}
        need(#ch == 0 or #ch == #fx, "effect chances")
        for _, e in ipairs(fx) do
          need(TweakDB:GetRecord(type(e) == "string" and e or str(e)) ~= nil, "effect " .. tostring(e))
        end
        local st = flat(ammo, "aoShareType")
        need(st == nil or SHARE_TYPES[st], "share type " .. tostring(st))
      end
      check(cal .. " " .. ammo .. " (tier " .. t .. ")", #bad == 0, table.concat(bad, "; "))
    end
  end
end
check("96 Rare and Epic rounds listed", counted[2] + counted[3] == 96, counted[2] .. " Rare, " .. counted[3] .. " Epic")
check("Rare count", counted[2] == 50, tostring(counted[2]))
check("Epic count", counted[3] == 46, tostring(counted[3]))
check("14 Legendary rounds listed", counted[4] == 14, tostring(counted[4]))


-- The 12mm, 7.62 and 12.7 Penetrator go through thin cover (the Tech pierce stats, probed on an
-- Ajax) and have their own text; the 9mm, .45 and 5.56 Penetrator stay armor-only.
local function modSum(id, stat, mtype)
  local sum, any = (mtype == "Multiplier") and 1 or 0, false
  for _, m in ipairs(flat(id, "statModifiers") or {}) do
    local mt = flat(m, "modifierType")
    if str(flat(m, "statType")) == "BaseStats." .. stat and mt and mt.value == mtype then
      any = true
      if mtype == "Multiplier" then sum = sum * (flat(m, "value") or 1) else sum = sum + (flat(m, "value") or 0) end
    end
  end
  return sum, any
end
-- The description's LocKey is stored hashed: compare it with the hash of the expected key.
local function hasDescKey(id, key)
  local r = rec(id)
  return r ~= nil and r:LocalizedDescription() == CName.new(key)
end
local pen9 = statSum("Items.AO_Feed_9mm_Penetrator", "CanWeaponIgnoreArmor")
for _, loc in ipairs({ "12mm", "762", "127" }) do
  local sel = "Items.AO_Feed_" .. loc .. "_Penetrator"
  check(sel .. " exists", rec(sel) ~= nil, "no record")
  check(sel .. " TechPierceEnabled 1", near(statSum(sel, "TechPierceEnabled"), 1), tostring(statSum(sel, "TechPierceEnabled")))
  local ch, chAny = modSum(sel, "TechPierceChargeLevel", "Multiplier")
  check(sel .. " TechPierceChargeLevel x0", chAny and near(ch, 0), tostring(ch))
  check(sel .. " TechPierceDamageFactor -0.5 (half damage through cover)", near(statSum(sel, "TechPierceDamageFactor"), -0.5), tostring(statSum(sel, "TechPierceDamageFactor")))
  check(sel .. " armor pen as the 9mm Penetrator", near(statSum(sel, "CanWeaponIgnoreArmor"), pen9) and pen9 > 0, tostring(statSum(sel, "CanWeaponIgnoreArmor")))
  check(sel .. " own text key", hasDescKey(sel, "AO-Ammo-" .. loc .. "-Penetrator-Desc"), "other key")
end
local _, pierce9 = modSum("Items.AO_Feed_9mm_Penetrator", "TechPierceEnabled", "Additive")
check("9mm Penetrator has no TechPierceEnabled", not pierce9, "has it")
check("9mm Penetrator keeps the shared text", hasDescKey("Items.AO_Feed_9mm_Penetrator", "AO-Ammo-Penetrator-Desc"), "other key")

-- Legendary rounds (docs/superpowers/specs/2026-10-29-legendary-rounds-design.md).
local function lsel(loc, load) return "Items.AO_Feed_" .. loc .. "_" .. load end
for _, loc in ipairs({ "762", "127" }) do
  local s = lsel(loc, "Gatecrasher")
  check(s .. " ignores all armor", near(statSum(s, "CanWeaponIgnoreArmor"), 1), tostring(statSum(s, "CanWeaponIgnoreArmor")))
  check(s .. " no falloff", near(statSum(s, "DamageFalloffDisabled"), 1), tostring(statSum(s, "DamageFalloffDisabled")))
  check(s .. " pierces cover", near(statSum(s, "TechPierceEnabled"), 1), tostring(statSum(s, "TechPierceEnabled")))
  local f, any = modSum(s, "TechPierceDamageFactor", "Multiplier")
  check(s .. " full damage through cover (factor x0)", any and near(f, 0), tostring(f))
end
for _, a in ipairs({ "Ammo.AO_9mm_CookOff", "Ammo.AO_45_CookOff", "Ammo.AO_12mm_CookOff", "Ammo.AO_556_CookOff", "Ammo.AO_762_CookOff" }) do
  check(a .. " cooks off", flat(a, "aoCookOff") == true, tostring(flat(a, "aoCookOff")))
end
for _, loc in ipairs({ "5mm", "Heavy" }) do
  local f, any = modSum(lsel(loc, "Kebab"), "TechPierceDamageFactor", "Multiplier")
  check(loc .. " Kebab loses no damage through targets (factor x0)", any and near(f, 0), tostring(f))
end
local jam = rec("AmmoOverhaul.LockoutJam")
check("AmmoOverhaul.LockoutJam exists", jam ~= nil)
local jamMods = jam and jam:Duration() and jam:Duration():StatModifiers() or {}
check("LockoutJam lasts 4 s", #jamMods == 1 and near(jamMods[1]:Value(), 4), tostring(#jamMods))
for _, a in ipairs({ "Ammo.AO_S10_Lockout", "Ammo.AO_S20_Lockout", "Ammo.AO_S25_Lockout" }) do
  local fx, ch = flat(a, "aoEffects") or {}, flat(a, "aoEffectChances") or {}
  check(a .. " jams on every hit", #fx == 1 and str(fx[1]) == "AmmoOverhaul.LockoutJam" and near(ch[1] or 0, 1), tostring(fx[1]))
end
local pd = "Items.AO_Feed_12ga_PumpNDump"
check("Pump N Dump spread x0.2, as Slugs", near(statSum(pd, "SpreadDefaultX"), 0.2), tostring(statSum(pd, "SpreadDefaultX")))
check("Pump N Dump cycles at x0.4", near(statSum(pd, "CycleTime"), 0.4), tostring(statSum(pd, "CycleTime")))
check("Pump N Dump ignores no armor", near(statSum(pd, "CanWeaponIgnoreArmor"), 0), tostring(statSum(pd, "CanWeaponIgnoreArmor")))
local mk = "Items.AO_Feed_4ga_MuleKick"
check("Mule Kick flagged", flat("Ammo.AO_4ga_MuleKick", "aoMuleKick") == true, tostring(flat("Ammo.AO_4ga_MuleKick", "aoMuleKick")))
check("Mule Kick knockback", near(statSum(mk, "KnockdownImpulse"), 100) and near(statSum(mk, "BaseKnockdownImpulse"), 100), tostring(statSum(mk, "KnockdownImpulse")))

-- Every record the generator names exists (stat types, status effects, bases): tools/rounds/refs.txt.
if AO_REFS then
  local missing = {}
  for _, r in ipairs(AO_REFS) do if not TweakDB:GetRecord(r) then table.insert(missing, r) end end
  check(#AO_REFS .. " generator references exist", #missing == 0, table.concat(missing, " "))
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
-- Dumbfires trade all guidance for damage x1.8 (play-test: x1.25 lost to Short-Fuse's x1.2 with guidance).
for _, cal in ipairs({ "10mm", "20mm", "25mm" }) do
  local feed = TweakDB:GetRecord("Items.AO_Feed_" .. cal .. "_Dumbfires")
  local dmg
  for _, m in ipairs(feed and feed:StatModifiers() or {}) do
    if m:IsA("gamedataConstantStatModifier_Record") and m:StatType():StatType() == gamedataStatType.DamagePerHit then dmg = m:Value() end
  end
  check(cal .. " Dumbfires damage x1.8", dmg and math.abs(dmg - 1.8) < 0.001, tostring(dmg))
  local d = feed and Game.GetLocalizedTextByKey(feed:LocalizedDescription()) or ""
  check(cal .. " Dumbfires text says +80% damage", d:find("+80% damage", 1, true) ~= nil, d)
end
report()

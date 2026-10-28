-- Task 3 + icon art: every slice round and its selector use their UIIcon.AO_* record (art/icons, packed by
-- tools/icons/build.sh) from the mod's atlas; vanilla handgun ammo shows the 9mm Ball art.
-- The empty feed slot and the loot-window placeholder of our rounds use the
-- ammo shadow icon.
local AMMO_ICON = "undefined_ammo_box_handgun_None_"
local ATLAS = "ammooverhaul\\icons\\ao_ammo_icons.inkatlas"
local OWN = {
  ["Ammo.HandgunAmmo"] = "AO_9mm_Ball", ["Items.AO_Feed_9mm_Ball"] = "AO_9mm_Ball",
  ["Ammo.AO_TLight_Sabot"] = "AO_5mm_Sleevers", ["Items.AO_Feed_5mm_Sleevers"] = "AO_5mm_Sleevers",
  ["Ammo.AO_S10_Dumbfire"] = "AO_10mm_Dumbfires", ["Items.AO_Feed_10mm_Dumbfires"] = "AO_10mm_Dumbfires",
  ["Ammo.AO_9mm_HollowPoint"] = "AO_9mm_Mushrooms", ["Items.AO_Feed_9mm_Mushrooms"] = "AO_9mm_Mushrooms",
  ["Ammo.AO_TLight_Slug"] = "AO_5mm_RailSlugs", ["Items.AO_Feed_5mm_RailSlugs"] = "AO_5mm_RailSlugs",
  ["Ammo.AO_S10_Standard"] = "AO_10mm_Seekers", ["Items.AO_Feed_10mm_Seekers"] = "AO_10mm_Seekers",
}
local resolver = IconsNameResolver.GetIconsNameResolver()
for _, id in ipairs({ "Ammo.HandgunAmmo", "Ammo.AO_9mm_HollowPoint", "Ammo.AO_TLight_Slug", "Ammo.AO_TLight_Sabot",
    "Ammo.AO_S10_Standard", "Ammo.AO_S10_Dumbfire" }) do
  if OWN[id] then
    check(id .. " iconPath", flat(id, "iconPath") == OWN[id], tostring(flat(id, "iconPath")))
  else
    local n = resolver:TranslateItemToIconName(TweakDBID.new(id), false).value
    check(id .. " icon", (flat(id, "iconPath") or "") == "" and n == AMMO_ICON, n)
  end
end
for _, id in ipairs({ "Items.AO_Feed_9mm_Ball", "Items.AO_Feed_9mm_Mushrooms", "Items.AO_Feed_5mm_RailSlugs",
    "Items.AO_Feed_5mm_Sleevers", "Items.AO_Feed_10mm_Seekers", "Items.AO_Feed_10mm_Dumbfires" }) do
  local want = OWN[id] or AMMO_ICON
  check(id .. " iconPath", flat(id, "iconPath") == want, tostring(flat(id, "iconPath")))
end
for _, icon in ipairs({ "AO_9mm_Ball", "AO_9mm_Mushrooms", "AO_5mm_RailSlugs", "AO_5mm_Sleevers",
    "AO_10mm_Seekers", "AO_10mm_Dumbfires" }) do
  local r = rec("UIIcon." .. icon)
  check("UIIcon." .. icon .. " exists", r ~= nil, "no record")
  if r then
    check("UIIcon." .. icon .. " part", r:AtlasPartName().value == icon:lower(), r:AtlasPartName().value)
  end
end
local depot = Game.GetResourceDepot and Game.GetResourceDepot()
if depot then
  check("icon atlas is in the game's resources", depot:ResourceExists(ATLAS), ATLAS)
end
local sys = Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem")
local ok, res = pcall(function() return sys:DebugIcons("Ammo.AO_TLight_Slug", "AttachmentSlots.AO_AmmoFeed_Tech_Light") end)
check("DebugIcons exists", ok, tostring(res))
if ok then
  local loot, slot = res:match("^(%S+) (%S+)$")
  check("loot shadow of a new round", loot == "UIIcon.LootingShadow_HandgunAmmo", tostring(loot))
  check("empty feed slot shadow", slot == "UIIcon.LootingShadow_HandgunAmmo", tostring(slot))
end
report()

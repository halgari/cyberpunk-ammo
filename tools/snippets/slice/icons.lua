-- Task 3: rounds and selectors use the handgun ammo icon; the empty feed slot and the loot-window
-- placeholder of our rounds use the ammo shadow icon.
local AMMO_ICON = "undefined_ammo_box_handgun_None_"
local resolver = IconsNameResolver.GetIconsNameResolver()
local rounds = { "Ammo.AO_9mm_HollowPoint", "Ammo.AO_TLight_Slug", "Ammo.AO_TLight_Sabot", "Ammo.AO_S10_Standard", "Ammo.AO_S10_Dumbfire" }
for _, id in ipairs(rounds) do
  local n = resolver:TranslateItemToIconName(TweakDBID.new(id), false).value
  check(id .. " icon", n == AMMO_ICON, n)
end
for _, id in ipairs({ "Items.AO_Feed_9mm_Ball", "Items.AO_Feed_9mm_Mushrooms", "Items.AO_Feed_5mm_RailSlugs",
    "Items.AO_Feed_5mm_Sleevers", "Items.AO_Feed_10mm_Seekers", "Items.AO_Feed_10mm_Dumbfires" }) do
  local p = flat(id, "iconPath")
  check(id .. " iconPath", p == AMMO_ICON, tostring(p))
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

-- Task 9: every round of all 13 calibers and its feed selector use the round's own UIIcon.AO_* box
-- art (art/icons, packed by tools/icons/build.sh) from the mod's atlas, named after the selector
-- (Items.AO_Feed_45_Ball -> AO_45_Ball). The game's four ammo items show their Common round's art.
local ATLAS = "ammooverhaul\\icons\\ao_ammo_icons.inkatlas"
local ROUNDS = {
  { "Ammo.HandgunAmmo", "9mm_Ball" }, { "Ammo.AO_9mm_HollowPoint", "9mm_Mushrooms" },
  { "Ammo.AO_45_Ball", "45_Ball" }, { "Ammo.AO_45_HollowPoint", "45_Mushrooms" },
  { "Ammo.AO_12mm_Ball", "12mm_Ball" }, { "Ammo.AO_12mm_HollowPoint", "12mm_Mushrooms" },
  { "Ammo.RifleAmmo", "556_Ball" }, { "Ammo.AO_556_HollowPoint", "556_Mushrooms" },
  { "Ammo.AO_762_Ball", "762_Ball" }, { "Ammo.AO_762_HollowPoint", "762_Mushrooms" },
  { "Ammo.SniperRifleAmmo", "127_Ball" }, { "Ammo.AO_127_HollowPoint", "127_Mushrooms" },
  { "Ammo.ShotgunAmmo", "12ga_Buckshot" }, { "Ammo.AO_12ga_Slug", "12ga_Slugs" },
  { "Ammo.AO_4ga_Buckshot", "4ga_Buckshot" }, { "Ammo.AO_4ga_Slug", "4ga_Slugs" },
  { "Ammo.AO_TLight_Slug", "5mm_RailSlugs" }, { "Ammo.AO_TLight_Sabot", "5mm_Sleevers" },
  { "Ammo.AO_THeavy_Slug", "Heavy_RailSlugs" }, { "Ammo.AO_THeavy_Sabot", "Heavy_Sleevers" },
  { "Ammo.AO_S10_Standard", "10mm_Seekers" }, { "Ammo.AO_S10_Dumbfire", "10mm_Dumbfires" },
  { "Ammo.AO_S20_Standard", "20mm_Seekers" }, { "Ammo.AO_S20_Dumbfire", "20mm_Dumbfires" },
  { "Ammo.AO_S25_Standard", "25mm_Seekers" }, { "Ammo.AO_S25_Dumbfire", "25mm_Dumbfires" },
  { "Ammo.AO_9mm_PlusP", "9mm_PlusP" }, { "Ammo.AO_45_PlusP", "45_PlusP" }, { "Ammo.AO_12mm_PlusP", "12mm_PlusP" },
  { "Ammo.AO_556_PlusP", "556_PlusP" }, { "Ammo.AO_762_PlusP", "762_PlusP" }, { "Ammo.AO_127_PlusP", "127_PlusP" },
  { "Ammo.AO_12ga_Birdshot", "12ga_Birdshot" }, { "Ammo.AO_4ga_Birdshot", "4ga_Birdshot" },
  { "Ammo.AO_TLight_Bricks", "5mm_Bricks" }, { "Ammo.AO_THeavy_Bricks", "Heavy_Bricks" },
  { "Ammo.AO_S10_ShortFuse", "10mm_ShortFuse" }, { "Ammo.AO_S20_ShortFuse", "20mm_ShortFuse" },
  { "Ammo.AO_S25_ShortFuse", "25mm_ShortFuse" },
}
local seen = {}
for _, r in ipairs(ROUNDS) do
  local ammo, feed, icon = r[1], "Items.AO_Feed_" .. r[2], "AO_" .. r[2]
  check(ammo .. " iconPath", flat(ammo, "iconPath") == icon, tostring(flat(ammo, "iconPath")))
  check(feed .. " iconPath", flat(feed, "iconPath") == icon, tostring(flat(feed, "iconPath")))
  local u = rec("UIIcon." .. icon)
  check("UIIcon." .. icon .. " exists", u ~= nil, "no record")
  if u then
    local part = u:AtlasPartName().value
    check("UIIcon." .. icon .. " part", part == icon:lower(), part)
    check("UIIcon." .. icon .. " part used once", not seen[part], tostring(seen[part]))
    seen[part] = icon
  end
end
local depot = Game.GetResourceDepot and Game.GetResourceDepot()
if depot then
  check("icon atlas is in the game's resources", depot:ResourceExists(ATLAS), ATLAS)
end
report()

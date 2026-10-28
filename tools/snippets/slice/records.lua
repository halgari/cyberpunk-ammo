-- Task 1: the slice's records exist, have the right names, and the guns use the new ammo.
local rounds = {
  { "Ammo.HandgunAmmo", "9mm Ball", 0.06, "Items.AO_Feed_9mm_Ball" },
  { "Ammo.AO_9mm_HollowPoint", "9mm Mushrooms", 0.06, "Items.AO_Feed_9mm_Mushrooms" },
  { "Ammo.AO_TLight_Slug", "5mm Rail Slugs", 0.04, "Items.AO_Feed_5mm_RailSlugs" },
  { "Ammo.AO_TLight_Sabot", "5mm Sleevers", 0.04, "Items.AO_Feed_5mm_Sleevers" },
  { "Ammo.AO_S10_Standard", "10mm Seekers", 0.08, "Items.AO_Feed_10mm_Seekers" },
  { "Ammo.AO_S10_Dumbfire", "10mm Dumbfires", 0.08, "Items.AO_Feed_10mm_Dumbfires" },
}
for _, r in ipairs(rounds) do
  local ammo, name, weight, sel = r[1], r[2], r[3], r[4]
  check(ammo .. " exists", rec(ammo) ~= nil)
  check(ammo .. " name", locName(ammo) == name, tostring(locName(ammo)))
  local w = statSum(ammo, "Weight")
  check(ammo .. " weight", math.abs(w - weight) < 0.001, tostring(w))
  check(sel .. " exists", rec(sel) ~= nil)
  check(sel .. " name", locName(sel) == name, tostring(locName(sel)))
end
for _, id in ipairs({ "AttachmentSlots.AO_AmmoFeed_Tech_Light", "AttachmentSlots.AO_AmmoFeed_Smart_10",
    "Character.AO_Test_Ganger_9mm_Mushrooms", "Character.AO_Test_Ganger_5mm_Sleevers", "Character.AO_Test_Ganger_10mm_Dumbfires" }) do
  check(id .. " exists", rec(id) ~= nil)
end
local guns = {
  { "Items.Base_Lexington", "Ammo.HandgunAmmo", "Items.AO_AmmoFeed_Power_9mm_Element" },
  { "Items.Base_Omaha", "Ammo.AO_TLight_Slug", "Items.AO_AmmoFeed_Tech_Light_Element" },
  { "Items.Base_Yukimura", "Ammo.AO_S10_Standard", "Items.AO_AmmoFeed_Smart_10_Element" },
}
for _, g in ipairs(guns) do
  check(g[1] .. " ammo", str(flat(g[1], "ammo")) == g[2], str(flat(g[1], "ammo")))
  local root = flat(flat(g[1], "blueprint"), "rootElement")
  local found = false
  for _, c in ipairs(flat(root, "childElements") or {}) do if str(c) == g[3] then found = true end end
  check(g[1] .. " feed element", found, str(root))
end
for _, id in ipairs({ "Items.AO_Feed_9mm_Incendiary", "Ammo.AO_9mm_TestDragon", "Items.AO_Feed_9mm_FMJ" }) do
  check(id .. " removed", rec(id) == nil)
end
report()

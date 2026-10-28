-- A gun the mod doesn't manage (Unity: Power handgun on vanilla Ammo.HandgunAmmo) plus ammo,
-- for measuring vanilla ammo behaviour without the feed system in the way.
Game.AddToInventory("Items.Preset_Unity_Default", 1)
Game.AddToInventory("Ammo.HandgunAmmo", 100)
print("gave Unity + 100 handgun ammo")

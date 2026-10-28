-- The PoC test kit: a fresh Lexington, both feed selectors and some of each ammo type.
Game.AddToInventory("Items.Preset_Lexington_Default", 1)
Game.AddToInventory("Items.AO_Feed_9mm_FMJ", 1)
Game.AddToInventory("Items.AO_Feed_9mm_Incendiary", 1)
Game.AddToInventory("Ammo.HandgunAmmo", 50)
Game.AddToInventory("Ammo.AO_9mm_Incendiary", 30)
print("gave Lexington, both feeds, 50 handgun, 30 incendiary")

-- Prints the ammo counts next to the drawn weapon's ammo type and magazine.
--   tools/linux/cet.sh -f tools/snippets/ammo-state.lua
local ts = Game.GetTransactionSystem()
local p = Game.GetPlayer()
local function count(id) return ts:GetItemQuantity(p, ItemID.CreateQuery(TweakDBID.new(id))) end
print("inventory handgun", count("Ammo.HandgunAmmo"), "incendiary", count("Ammo.AO_9mm_Incendiary"), "rifle", count("Ammo.RifleAmmo"))
local w = p:GetActiveWeapon()
if w then
  print("weapon", TDBID.ToStringDEBUG(w:GetItemID().id),
        "ammoType", TDBID.ToStringDEBUG(WeaponObject.GetAmmoType(w).id),
        "mag", WeaponObject.GetMagazineAmmoCount(w), "/", WeaponObject.GetMagazineCapacity(w),
        "total", w:GetTotalAmmoCount())
else
  print("no active weapon")
end

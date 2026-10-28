-- Prints the ammo counts next to the drawn weapon's record ammo and magazine. recordAmmo is what
-- the gun's record says (WeaponObject.GetAmmoType), not what it's loaded with: `total` is the
-- inventory count of the loaded ammo, so compare it with the counts above.
--   tools/linux/cet.sh -f tools/snippets/ammo-state.lua
local ts = Game.GetTransactionSystem()
local p = Game.GetPlayer()
local function count(id) return ts:GetItemQuantity(p, ItemID.CreateQuery(TweakDBID.new(id))) end
for _, id in ipairs({ "Ammo.HandgunAmmo", "Ammo.AO_9mm_HollowPoint", "Ammo.AO_TLight_Slug", "Ammo.AO_TLight_Sabot",
    "Ammo.AO_S10_Standard", "Ammo.AO_S10_Dumbfire", "Ammo.RifleAmmo" }) do
  print("inventory", id, count(id))
end
local w = p:GetActiveWeapon()
if w then
  print("weapon", TDBID.ToStringDEBUG(w:GetItemID().id),
        "recordAmmo", TDBID.ToStringDEBUG(WeaponObject.GetAmmoType(w).id),
        "mag", WeaponObject.GetMagazineAmmoCount(w), "/", WeaponObject.GetMagazineCapacity(w),
        "total", w:GetTotalAmmoCount())
else
  print("no active weapon")
end

// Natives from the AmmoOverhaul RED4ext plugin (native/AmmoOverhaul). Global, so no module.
// See NativeAmmo in AmmoOverhaul/NativeAmmo.reds for how they're used.

public static native func AO_FindAmmoFields(weapon: ref<WeaponObject>, ammo: TweakDBID) -> array<Int32>
public static native func AO_ReadAmmoField(weapon: ref<WeaponObject>, offset: Int32) -> TweakDBID
public static native func AO_WriteAmmoField(weapon: ref<WeaponObject>, offset: Int32, expected: TweakDBID, ammo: TweakDBID) -> Bool
public static native func AO_ReadInt32(weapon: ref<WeaponObject>, offset: Int32) -> Int32
public static native func AO_WriteInt32(weapon: ref<WeaponObject>, offset: Int32, expected: Int32, value: Int32) -> Bool

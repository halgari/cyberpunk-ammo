module AmmoOverhaul

// Rounds that change what the gun fires (<ammo>.aoRangedAttack; Heartseeker, Legendary 12ga):
// the shot takes that RangedAttackPackage instead of the gun's, for V (the shooting state's attack
// pick) and NPCs (AIWeapon's). Probe 1 (2026-10-30) made a Carnage fire homing smart slugs with
// the smart package, the smart weapon tags and a smart pistol's lock stats; here the lock stats
// come from the round's selector and the tags are put on the gun as dynamic tags while the round
// is loaded (AmmoOverhaul marks the ones it added, so a swap back takes only those off).

public abstract class RangedAttackSwap {

  public static func Package(owner: ref<GameObject>, weapon: ref<WeaponObject>) -> ref<RangedAttackPackage_Record> {
    if !IsDefined(owner) || !IsDefined(weapon) {
      return null;
    }
    let id: TweakDBID = AOData.RangedAttack(AOData.LoadedAmmo(owner, weapon));
    return TDBID.IsValid(id) ? TweakDBInterface.GetRangedAttackPackageRecord(id) : null;
  }

  // Puts the smart weapon tags on `gun` while its round fires a smart package, and takes the ones
  // added here off when it doesn't.
  public static func SyncTags(owner: ref<GameObject>, gun: ItemID) -> Void {
    let data: wref<gameItemData> = GameInstance.GetTransactionSystem(owner.GetGame()).GetItemData(owner, gun);
    if !IsDefined(data) {
      return;
    }
    let caliber: String = AOData.CaliberForWeapon(ItemID.GetTDBID(gun));
    if StrLen(caliber) == 0 {
      return;
    }
    let ammo: TweakDBID = owner.IsPlayer() ? AOData.SelectedAmmo(owner, gun, caliber) : NpcAmmo.GunAmmo(owner as NPCPuppet, gun);
    let smart: Bool = TDBID.IsValid(AOData.RangedAttack(ammo));
    let dynamic: array<CName> = data.GetDynamicTags();
    let added: Bool = ArrayContains(dynamic, n"AO_SmartTags");
    if smart && !added {
      if !data.HasTag(n"Smart") {
        data.SetDynamicTag(n"Smart");
      }
      if !data.HasTag(n"SmartWeapon") {
        data.SetDynamicTag(n"SmartWeapon");
      }
      data.SetDynamicTag(n"AO_SmartTags");
    } else {
      if !smart && added {
        data.RemoveDynamicTag(n"Smart");
        data.RemoveDynamicTag(n"SmartWeapon");
        data.RemoveDynamicTag(n"AO_SmartTags");
      }
    }
  }
}

@wrapMethod(WeaponTransition)
protected final func GetDesiredAttackRecord(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> ref<Attack_Record> {
  let attack: ref<Attack_Record> = wrappedMethod(stateContext, scriptInterface);
  let weapon: ref<WeaponObject> = this.GetWeaponObject(scriptInterface);
  let package: ref<RangedAttackPackage_Record> = RangedAttackSwap.Package(scriptInterface.executionOwner, weapon);
  if !IsDefined(package) {
    return attack;
  }
  let ranged: ref<RangedAttack_Record> = package.DefaultFire();
  let swapped: ref<Attack_Record>;
  if scriptInterface.GetTimeSystem().IsTimeDilationActive() {
    swapped = ranged.PlayerTimeDilated();
  }
  if !IsDefined(swapped) && scriptInterface.localBlackboard.GetInt(GetAllBlackboardDefs().PlayerStateMachine.UpperBody) == 6 {
    swapped = ranged.SecondaryPlayerAttack();
  }
  if !IsDefined(swapped) {
    swapped = ranged.PlayerAttack();
  }
  return IsDefined(swapped) ? swapped : attack;
}

@wrapMethod(AIWeapon)
public final static func SetAttackBasedOnTimeDilation(owner: wref<GameObject>, weapon: wref<WeaponObject>, opt overrideRangedAttack: TweakDBID) -> Void {
  if !TDBID.IsValid(overrideRangedAttack) && IsDefined(owner) && owner.IsNPC() {
    let package: ref<RangedAttackPackage_Record> = RangedAttackSwap.Package(owner, weapon);
    if IsDefined(package) && IsDefined(package.DefaultFire()) {
      overrideRangedAttack = package.DefaultFire().GetID();
    }
  }
  wrappedMethod(owner, weapon, overrideRangedAttack);
}

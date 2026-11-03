module AmmoOverhaul

// Two guns in hand on the same round draw from one stack, and the engine doesn't count the other
// gun: a reload fills the magazine from the whole stack, rounds only leave it when fired, and a
// loaded gun still fires with the stack at 0. So 10 rounds would load both guns with 10 and fire
// 20. Guns also come out of the inventory fully loaded, whatever the stack. Here the two magazines
// together never hold more than the stack: a gun can't start a reload that has nothing left for
// it, and whichever magazine goes over gives the extra rounds back.

// Watches one gun's magazine count, on the gun's own blackboard.
public class AODualMagazineWatch extends IScriptable {
  public let weapon: wref<WeaponObject>;
  // The listener lasts as long as its handle.
  public let handle: ref<CallbackHandle>;

  protected cb func OnMagazine(value: Uint32) -> Bool {
    let system: ref<AmmoFeedSystem> = AmmoFeedSystem.Get(GetGameInstance());
    if IsDefined(system) && IsDefined(this.weapon) {
      system.BalanceDualWield(this.weapon);
    }
    return false;
  }
}

public class AODualBalanceCallback extends DelayCallback {
  public func Call() -> Void {
    let system: ref<AmmoFeedSystem> = AmmoFeedSystem.Get(GetGameInstance());
    if IsDefined(system) {
      system.BalanceHands();
    }
  }
}

public abstract class DualWield {

  // The gun in the player's other hand if it's on the same round as `weapon`, otherwise null.
  public static func Partner(weapon: ref<WeaponObject>) -> ref<WeaponObject> {
    let owner: ref<PlayerPuppet> = weapon.GetOwner() as PlayerPuppet;
    if !IsDefined(owner) {
      return null;
    }
    let right: ref<WeaponObject> = ScriptedPuppet.GetWeaponRight(owner);
    let left: ref<WeaponObject> = ScriptedPuppet.GetWeaponLeft(owner);
    if !IsDefined(right) || !IsDefined(left) || (weapon != right && weapon != left) {
      return null;
    }
    let other: ref<WeaponObject> = weapon == right ? left : right;
    let ammo: TweakDBID = DualWield.Selected(owner, weapon);
    return TDBID.IsValid(ammo) && ammo == DualWield.Selected(owner, other) ? other : null;
  }

  private static func Selected(owner: ref<PlayerPuppet>, weapon: ref<WeaponObject>) -> TweakDBID {
    let id: ItemID = weapon.GetItemID();
    return AOData.SelectedAmmo(owner, id, AOData.CaliberForWeapon(ItemID.GetTDBID(id)));
  }
}

// What CanReload asks: rounds in the stack that aren't in this gun's magazine. They mustn't be in
// the other gun's either.
@wrapMethod(WeaponObject)
public final static func HasAvailableAmmoInInventory(self: ref<WeaponObject>) -> Bool {
  if !wrappedMethod(self) {
    return false;
  }
  let partner: ref<WeaponObject> = DualWield.Partner(self);
  if !IsDefined(partner) {
    return true;
  }
  let loaded: Uint32 = WeaponObject.GetMagazineAmmoCount(self) + WeaponObject.GetMagazineAmmoCount(partner);
  return self.GetTotalAmmoCount() - Cast<Int32>(loaded) > 0;
}

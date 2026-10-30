module AmmoOverhaul

// Rounds that change what the gun fires (<ammo>.aoRangedAttack; Heartseeker, Legendary 12ga).
//   - The shot takes that RangedAttackPackage instead of the gun's: V's through the shooting
//     state's attack pick, NPCs' (and V's shots fired through AIWeapon) through AIWeapon's.
//   - The smart lock: the game only runs a gun's smart targeting when its weapon record's
//     evolution is Smart (measured 2026-10-30: the Smart and SmartWeapon tags and V's HasSmartLink
//     stat made no difference). Records are shared, so while V's drawn gun has such a round its
//     record's evolution is set to Smart, and put back as soon as V draws anything else. The
//     change only applies to a gun drawn after it, so the gun is redrawn once. The lock stats come
//     from the round's selector. The crosshair stays the gun's own: a redraw with the smart
//     crosshair (Crosshairs.SmartGun) on the Tactician crashed the game (measured 2026-10-30).
// NPCs' guns aren't changed: their shots are the package's NPC smart attack.

public abstract class RangedAttackSwap {

  public static func Package(owner: ref<GameObject>, weapon: ref<WeaponObject>) -> ref<RangedAttackPackage_Record> {
    if !IsDefined(owner) || !IsDefined(weapon) {
      return null;
    }
    let id: TweakDBID = AOData.RangedAttack(AOData.LoadedAmmo(owner, weapon));
    return TDBID.IsValid(id) ? TweakDBInterface.GetRangedAttackPackageRecord(id) : null;
  }

  private static func SetRecord(record: TweakDBID, evolution: TweakDBID) -> Void {
    TweakDBManager.SetFlat(AOData.Flat(record, "evolution"), ToVariant(evolution));
    TweakDBManager.UpdateRecord(record);
  }

  // Puts back every weapon record made Smart here, except `keep`.
  public static func Restore(system: ref<AmmoFeedSystem>, keep: TweakDBID) -> Void {
    let i: Int32 = ArraySize(system.m_smartRecords) - 1;
    while i >= 0 {
      if system.m_smartRecords[i] != keep {
        RangedAttackSwap.SetRecord(system.m_smartRecords[i], system.m_smartEvolution[i]);
        AmmoFeedSystem.Log("smart round: " + TDBID.ToStringDEBUG(system.m_smartRecords[i]) + " back to its own evolution");
        ArrayErase(system.m_smartRecords, i);
        ArrayErase(system.m_smartEvolution, i);
      }
      i -= 1;
    }
  }

  // V drew `weapon`: makes its record Smart if its round fires a smart package (and redraws it so
  // the change takes), and puts any other record back.
  public static func Sync(system: ref<AmmoFeedSystem>, player: ref<PlayerPuppet>, weapon: ref<WeaponObject>) -> Void {
    let record: TweakDBID = ItemID.GetTDBID(weapon.GetItemID());
    let smart: Bool = IsDefined(RangedAttackSwap.Package(player, weapon));
    RangedAttackSwap.Restore(system, smart ? record : TDBID.None());
    if !smart || ArrayContains(system.m_smartRecords, record) || !IsDefined(TweakDBInterface.GetWeaponItemRecord(record)) {
      return;
    }
    ArrayPush(system.m_smartRecords, record);
    ArrayPush(system.m_smartEvolution, TweakDBInterface.GetForeignKey(AOData.Flat(record, "evolution"), TDBID.None()));
    RangedAttackSwap.SetRecord(record, t"WeaponEvolution.Smart");
    AmmoFeedSystem.Log("smart round: " + TDBID.ToStringDEBUG(record) + " made Smart, redrawing");
    AmmoFeedRedrawCallback.Schedule(player, weapon.GetItemID(), 1, 0.3);
  }
}

// Sync after a feed change, outside the item part transaction.
public class RangedAttackSyncCallback extends DelayCallback {
  public let player: wref<PlayerPuppet>;
  public let weaponID: ItemID;

  public static func Schedule(player: ref<PlayerPuppet>, weaponID: ItemID) -> Void {
    let callback: ref<RangedAttackSyncCallback> = new RangedAttackSyncCallback();
    callback.player = player;
    callback.weaponID = weaponID;
    GameInstance.GetDelaySystem(player.GetGame()).DelayCallback(callback, 0.5, false);
  }

  public func Call() -> Void {
    let player: ref<PlayerPuppet> = this.player;
    let weapon: ref<WeaponObject> = IsDefined(player) ? GameObject.GetActiveWeapon(player) : null;
    if IsDefined(weapon) && weapon.GetItemID() == this.weaponID {
      RangedAttackSwap.Sync(AmmoFeedSystem.Get(player.GetGame()), player, weapon);
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
  // NPCs' shots, and any shot of V's fired through AIWeapon (the live checks' rig).
  if !TDBID.IsValid(overrideRangedAttack) && IsDefined(owner) {
    let package: ref<RangedAttackPackage_Record> = RangedAttackSwap.Package(owner, weapon);
    if IsDefined(package) && IsDefined(package.DefaultFire()) {
      overrideRangedAttack = package.DefaultFire().GetID();
    }
  }
  wrappedMethod(owner, weapon, overrideRangedAttack);
}

module AmmoOverhaul

// Rounds that change what the gun fires (<ammo>.aoRangedAttack; Heartseeker, Legendary 12ga).
//   - The shot takes that RangedAttackPackage instead of the gun's: V's through the shooting
//     state's attack pick, NPCs' (and V's shots fired through AIWeapon) through AIWeapon's.
//   - The smart lock: the game only runs a gun's smart targeting when its weapon record's
//     evolution is Smart (measured 2026-10-30: the Smart and SmartWeapon tags and V's HasSmartLink
//     stat made no difference). Records are shared, so while V's drawn gun has such a round its
//     record's evolution is set to Smart, and put back (to its caliber's family) as soon as V
//     draws anything else. The change only applies to a gun drawn after it, so the gun is redrawn
//     once. The lock stats come from the round's selector. While it lasts, other guns of that
//     record (NPCs' too) also read as Smart to anything that checks the record's evolution. The crosshair stays the gun's own: a redraw with the smart
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

  // A gun this can change: one of the mod's Power or Tech guns (no 12ga gun is Smart in the game).
  // What it goes back to is its caliber's family, so nothing has to be remembered across loads.
  public static func OwnEvolution(record: TweakDBID) -> TweakDBID {
    let caliber: String = AOData.CaliberForWeapon(record);
    let family: String = StrLen(caliber) > 0 ? AOData.Family(caliber) : "";
    if Equals(family, "Power") {
      return t"WeaponEvolution.Power";
    }
    return Equals(family, "Tech") ? t"WeaponEvolution.Tech" : TDBID.None();
  }

  public static func IsSmart(record: TweakDBID) -> Bool {
    return TweakDBInterface.GetForeignKey(AOData.Flat(record, "evolution"), TDBID.None()) == t"WeaponEvolution.Smart";
  }

  // Puts back every weapon record made Smart here, except `keep`.
  public static func Restore(system: ref<AmmoFeedSystem>, keep: TweakDBID) -> Void {
    let i: Int32 = ArraySize(system.m_smartRecords) - 1;
    while i >= 0 {
      let record: TweakDBID = system.m_smartRecords[i];
      if record != keep {
        let own: TweakDBID = RangedAttackSwap.OwnEvolution(record);
        if TDBID.IsValid(own) {
          RangedAttackSwap.SetRecord(record, own);
          AmmoFeedSystem.Log("smart round: " + TDBID.ToStringDEBUG(record) + " back to its own evolution");
        }
        ArrayErase(system.m_smartRecords, i);
      }
      i -= 1;
    }
  }

  // V drew `weapon`: makes its record Smart if its round fires a smart package (and redraws it so
  // the change takes), and puts any other record back. A gun in hand whose record was put back (a
  // second copy of the same gun, a swapped round, or one left Smart by an earlier load in this
  // session) is redrawn too.
  public static func Sync(system: ref<AmmoFeedSystem>, player: ref<PlayerPuppet>, weapon: ref<WeaponObject>) -> Void {
    let record: TweakDBID = ItemID.GetTDBID(weapon.GetItemID());
    let own: TweakDBID = RangedAttackSwap.OwnEvolution(record);
    let smart: Bool = TDBID.IsValid(own) && IsDefined(RangedAttackSwap.Package(player, weapon));
    let wasSmart: Bool = TDBID.IsValid(own) && RangedAttackSwap.IsSmart(record);
    RangedAttackSwap.Restore(system, smart ? record : TDBID.None());
    if !smart {
      if wasSmart {
        if RangedAttackSwap.IsSmart(record) {
          RangedAttackSwap.SetRecord(record, own);
        }
        AmmoFeedSystem.Log("smart round: " + TDBID.ToStringDEBUG(record) + " in hand put back, redrawing");
        AmmoFeedRedrawCallback.Schedule(player, weapon.GetItemID(), 1, 0.3);
      }
      return;
    }
    if !ArrayContains(system.m_smartRecords, record) {
      ArrayPush(system.m_smartRecords, record);
    }
    if wasSmart {
      return;
    }
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

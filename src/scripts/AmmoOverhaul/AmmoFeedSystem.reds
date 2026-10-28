module AmmoOverhaul

// Makes each managed gun use the ammo its feed selector picks.
//
// A gun's ammo type comes from its TweakDB record: the engine copies it into the weapon object
// when the gun spawns and again on every draw, and reloads from and consumes that ammo. Records
// stay at the caliber's default; whenever a managed gun spawns or is drawn, its own copy is set to
// the gun's selection through the native plugin (NativeAmmo). Part changes respawn a drawn gun.
//
// Changing a gun's selector unloads it: the engine takes ammo out of the inventory per shot, so
// unfired rounds in the magazine were never removed from their stack and nothing is lost. The gun
// in hand is unloaded (ForceResetAmmoEvent, which doesn't touch the inventory), holstered and
// redrawn; any other gun is marked and unloaded the next time it spawns.
public class AmmoFeedSystem extends ScriptableSystem {

  private let m_player: wref<PlayerPuppet>;

  // Guns whose magazine still holds rounds of a previous selection. Saved with the game.
  private persistent let m_unload: array<ItemID>;

  // Offset of the ammo field in weapon objects, once located this session (see NativeAmmo).
  private let m_ammoOffset: Int32;

  private let m_magListener: ref<CallbackHandle>;
  private let m_magWeapon: wref<WeaponObject>;

  // The last log lines, for reading live from CET (ModLog output only reaches the file late):
  //   Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem"):Trail()
  private let m_trail: array<String>;

  public static func Get(game: GameInstance) -> ref<AmmoFeedSystem> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"AmmoOverhaul.AmmoFeedSystem") as AmmoFeedSystem;
  }

  private final func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
    // The request's owner is the player; the player system may not report it yet at this point.
    let player: ref<PlayerPuppet> = request.owner as PlayerPuppet;
    if !IsDefined(player) || player == this.m_player {
      return;
    }
    this.m_player = player;
    AmmoFeedSystem.Log("attached, " + IntToString(ArraySize(this.m_unload)) + " gun(s) waiting to unload");
  }

  private final func OnPlayerDetach(request: ref<PlayerDetachRequest>) -> Void {
    let player: ref<GameObject> = request.owner;
    // Loading a save (e.g. after dying) attaches the new player before the old one detaches;
    // only tear down for the player being tracked.
    if IsDefined(this.m_player) && player != this.m_player {
      return;
    }
    this.m_player = null;
  }

  // A selector is about to be installed in or removed from `weaponID`.
  public final func BeforeFeedChange(owner: ref<GameObject>, weaponID: ItemID) -> Void {
    let player: ref<PlayerPuppet> = this.m_player;
    if !IsDefined(player) || owner != player {
      return;
    }
    let inHand: wref<WeaponObject> = ScriptedPuppet.GetWeaponRight(player);
    if IsDefined(inHand) && inHand.GetItemID() == weaponID {
      AmmoFeedSystem.Redraw(player, weaponID);
    } else {
      if !ArrayContains(this.m_unload, weaponID) {
        ArrayPush(this.m_unload, weaponID);
      }
    }
  }

  // Empties the magazine of the gun in hand without touching the inventory. The reset lands on
  // the gun's next state change (holster, draw, shot); one queued with no gun in hand is dropped.
  public static func QueueUnload(player: ref<PlayerPuppet>, leftHand: Bool) -> Void {
    let evt: ref<ForceResetAmmoEvent> = new ForceResetAmmoEvent();
    evt.SetTargetValue(0);
    evt.SetIsLeftHandWeapon(leftHand);
    player.QueueEvent(evt);
  }

  // Unload, holster, draw, a moment apart: the part change respawns the gun over the next frames
  // (a reset queued before it's back in hand is dropped), the reset has to be in before the
  // holster starts, and a draw queued in the same frame as the holster cancels it. The delays run
  // on game time, so from the mod screen it all happens once the menu closes.
  private static func Redraw(player: ref<PlayerPuppet>, weaponID: ItemID) -> Void {
    AmmoFeedRedrawCallback.Schedule(player, weaponID, 0, 0.5);
  }

  // A weapon spawned: give a managed player gun its selected ammo, and unload it if it was
  // waiting to. The ammo field may only be filled in a little after the object attaches, so a
  // failed attempt is retried a few times.
  public final func OnWeaponSpawned(weapon: ref<WeaponObject>) -> Void {
    let player: ref<PlayerPuppet> = this.m_player;
    if !IsDefined(player) || weapon.GetOwner() != player {
      return;
    }
    let id: ItemID = weapon.GetItemID();
    if StrLen(AOData.CaliberForWeapon(ItemID.GetTDBID(id))) > 0 {
      this.GiveSelectedAmmo(weapon, 0);
      this.WatchMagazine(weapon);
    }
    if !ArrayContains(this.m_unload, id) {
      return;
    }
    ArrayRemove(this.m_unload, id);
    let unload: ref<AmmoFeedUnloadCallback> = new AmmoFeedUnloadCallback();
    unload.player = player;
    unload.weapon = weapon;
    GameInstance.GetDelaySystem(player.GetGame()).DelayCallback(unload, 0.5, false);
    AmmoFeedSystem.Log("unloading " + TDBID.ToStringDEBUG(ItemID.GetTDBID(id)) + " once in hand");
  }

  // Some time after a selector change (seen on the first one of a session), the engine restores
  // the gun's earlier ammo state, type and magazine count both. The magazine count's blackboard
  // entry changes when that happens, so a managed gun in hand is watched there: if its ammo field
  // no longer holds the selection, it gets the selection again and is unloaded, since the
  // magazine count belongs to the other ammo.
  private final func WatchMagazine(weapon: ref<WeaponObject>) -> Void {
    if IsDefined(this.m_magWeapon) && IsDefined(this.m_magListener) {
      this.m_magWeapon.GetSharedData().UnregisterListenerUint(GetAllBlackboardDefs().Weapon.MagazineAmmoCount, this.m_magListener);
    }
    this.m_magWeapon = weapon;
    this.m_magListener = weapon.GetSharedData().RegisterListenerUint(GetAllBlackboardDefs().Weapon.MagazineAmmoCount, this, n"OnMagazineChanged");
  }

  protected cb func OnMagazineChanged(value: Uint32) -> Bool {
    let weapon: ref<WeaponObject> = this.m_magWeapon;
    let player: ref<PlayerPuppet> = this.m_player;
    if !IsDefined(weapon) || !IsDefined(player) || this.m_ammoOffset <= 0 {
      return false;
    }
    let id: ItemID = weapon.GetItemID();
    let ammo: TweakDBID = AOData.SelectedAmmo(player, id, AOData.CaliberForWeapon(ItemID.GetTDBID(id)));
    let current: TweakDBID = NativeAmmo.Current(weapon, this.m_ammoOffset);
    if current == ammo || !TDBID.IsValid(current) {
      return false;
    }
    AmmoFeedSystem.Log("engine restored " + TDBID.ToStringDEBUG(current) + " in " + TDBID.ToStringDEBUG(ItemID.GetTDBID(id)) + ", unloading");
    if NativeAmmo.Apply(player, weapon, ammo, this.m_ammoOffset) {
      AmmoFeedSystem.QueueUnload(player, false);
    }
    return false;
  }

  // The player's gun in hand finished a step of drawing.
  public final func OnWeaponDrawn(weapon: ref<WeaponObject>) -> Void {
    if IsDefined(weapon) && weapon.GetOwner() == this.m_player && StrLen(AOData.CaliberForWeapon(ItemID.GetTDBID(weapon.GetItemID()))) > 0 {
      this.GiveSelectedAmmo(weapon, 0);
    }
  }

  public final func GiveSelectedAmmo(weapon: ref<WeaponObject>, attempt: Int32) -> Void {
    let player: ref<PlayerPuppet> = this.m_player;
    if !IsDefined(player) || !IsDefined(weapon) {
      return;
    }
    let id: ItemID = weapon.GetItemID();
    let ammo: TweakDBID = AOData.SelectedAmmo(player, id, AOData.CaliberForWeapon(ItemID.GetTDBID(id)));
    if NativeAmmo.Apply(player, weapon, ammo, this.m_ammoOffset) {
      if attempt > 0 || ammo != AOData.DefaultAmmo(AOData.CaliberForWeapon(ItemID.GetTDBID(id))) {
        AmmoFeedSystem.Log(TDBID.ToStringDEBUG(ItemID.GetTDBID(id)) + " takes " + TDBID.ToStringDEBUG(ammo));
      }
      return;
    }
    if attempt >= 5 {
      AmmoFeedSystem.Log("couldn't give " + TDBID.ToStringDEBUG(ItemID.GetTDBID(id)) + " " + TDBID.ToStringDEBUG(ammo) + " (ammo field not found)");
      return;
    }
    let retry: ref<AmmoFeedApplyCallback> = new AmmoFeedApplyCallback();
    retry.system = this;
    retry.weapon = weapon;
    retry.attempt = attempt + 1;
    GameInstance.GetDelaySystem(player.GetGame()).DelayCallback(retry, 0.1, false);
  }

  public static func Log(message: String) -> Void {
    ModLog(n"AmmoOverhaul", message);
    let system: ref<AmmoFeedSystem> = AmmoFeedSystem.Get(GetGameInstance());
    if IsDefined(system) {
      ArrayPush(system.m_trail, message);
      if ArraySize(system.m_trail) > 40 {
        ArrayErase(system.m_trail, 0);
      }
    }
  }

  public final func Trail() -> String {
    let text: String = "";
    for line in this.m_trail {
      text += line + "\n";
    }
    return text;
  }

  // Applies the on-hit effect of the ammo the firing weapon uses. Called from the damage pipeline
  // before vanilla applies the attack's status effects, so vanilla's blocked/friendly/immunity
  // checks still apply to ours.
  public static func ApplyAmmoOnHit(hitEvent: ref<gameHitEvent>) -> Void {
    let attackData: ref<AttackData> = hitEvent.attackData;
    if !IsDefined(attackData) {
      return;
    }
    let instigator: ref<GameObject> = attackData.GetInstigator();
    if !IsDefined(instigator) || !instigator.IsPlayer() {
      return;
    }
    if !AttackData.IsRangedOrDirect(attackData.GetAttackType()) || AttackData.IsDoT(attackData) {
      return;
    }
    let weapon: ref<WeaponObject> = attackData.GetWeapon();
    if !IsDefined(weapon) {
      return;
    }
    let weaponID: ItemID = weapon.GetItemID();
    let caliber: String = AOData.CaliberForWeapon(ItemID.GetTDBID(weaponID));
    if StrLen(caliber) == 0 {
      return;
    }
    let chance: Float;
    let effect: TweakDBID = AOData.OnHitEffect(AOData.SelectedAmmo(instigator, weaponID, caliber), chance);
    if TDBID.IsValid(effect) && RandF() < chance {
      attackData.AddStatusEffect(effect, 1.0);
    }
  }
}

public class AmmoFeedApplyCallback extends DelayCallback {
  public let system: wref<AmmoFeedSystem>;
  public let weapon: wref<WeaponObject>;
  public let attempt: Int32;

  public func Call() -> Void {
    if IsDefined(this.system) && IsDefined(this.weapon) {
      this.system.GiveSelectedAmmo(this.weapon, this.attempt);
    }
  }
}

public class AmmoFeedUnloadCallback extends DelayCallback {
  public let player: wref<PlayerPuppet>;
  public let weapon: wref<WeaponObject>;

  public func Call() -> Void {
    if IsDefined(this.player) && IsDefined(this.weapon) {
      AmmoFeedSystem.QueueUnload(this.player, this.weapon == ScriptedPuppet.GetWeaponLeft(this.player));
    }
  }
}

public class AmmoFeedRedrawCallback extends DelayCallback {
  public let player: wref<PlayerPuppet>;
  public let weaponID: ItemID;
  // 0: unload, 1: holster, 2: draw.
  public let step: Int32;

  public static func Schedule(player: ref<PlayerPuppet>, weaponID: ItemID, step: Int32, delay: Float) -> Void {
    let callback: ref<AmmoFeedRedrawCallback> = new AmmoFeedRedrawCallback();
    callback.player = player;
    callback.weaponID = weaponID;
    callback.step = step;
    GameInstance.GetDelaySystem(player.GetGame()).DelayCallback(callback, delay, false);
  }

  public func Call() -> Void {
    if !IsDefined(this.player) {
      return;
    }
    let equipment: ref<EquipmentSystem> = GameInstance.GetScriptableSystemsContainer(this.player.GetGame()).Get(n"EquipmentSystem") as EquipmentSystem;
    switch this.step {
      case 0:
        AmmoFeedSystem.Log("redraw: unloading");
        AmmoFeedSystem.QueueUnload(this.player, false);
        break;
      case 1:
        AmmoFeedSystem.Log("redraw: holstering");
        equipment.GetPlayerData(this.player).SendPSMWeaponManipulationRequest(EquipmentManipulationRequestType.Unequip, EquipmentManipulationRequestSlot.Right, gameEquipAnimationType.Instant);
        break;
      default:
        AmmoFeedSystem.Log("redraw: drawing");
        let draw: ref<DrawItemRequest> = new DrawItemRequest();
        draw.owner = this.player;
        draw.itemID = this.weaponID;
        draw.equipAnimationType = gameEquipAnimationType.Instant;
        equipment.QueueRequest(draw);
        return;
    }
    AmmoFeedRedrawCallback.Schedule(this.player, this.weaponID, this.step + 1, 0.3);
  }
}

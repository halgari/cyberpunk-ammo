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
// is marked and unloaded when it next spawns (a part change respawns a drawn gun straight away),
// by writing its magazine count through the plugin (NativeAmmo.Unload). If that can't be done,
// the gun in hand falls back to ForceResetAmmoEvent plus a holster and redraw.
public class AmmoFeedSystem extends ScriptableSystem {

  private let m_player: wref<PlayerPuppet>;

  // Guns whose magazine still holds rounds of a previous selection. Saved with the game.
  private persistent let m_unload: array<ItemID>;

  // Offset of the ammo field in weapon objects, once located this session (see NativeAmmo).
  private let m_ammoOffset: Int32;
  private let m_wantedAmmoOffset: Int32;

  private let m_magListener: ref<CallbackHandle>;
  private let m_magWeapon: wref<WeaponObject>;
  private let m_lastRestoreRedraw: Float;

  // The last log lines, for reading live from CET (ModLog output only reaches the file late):
  //   Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem"):Trail()
  private let m_trail: array<String>;

  private let m_ammoSection: String;

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
    if !ArrayContains(this.m_unload, weaponID) {
      ArrayPush(this.m_unload, weaponID);
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
  // waiting to. The ammo field and magazine count may only be filled in a little after the object
  // attaches, so a failed attempt is retried a few times.
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
  }

  // Safety net: if the engine ever loads the gun in hand with other ammo than its selection (it
  // did while only the loaded-ammo field was written: the wanted-ammo field still held the old
  // type, so the engine kept "changing ammo" back with a reload), the selection is applied again
  // and the gun unloaded, since its magazine count belongs to the other ammo. The magazine
  // count's blackboard entry changes whenever that happens, so the gun is watched there.
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
    if NativeAmmo.Apply(player, weapon, ammo, this.m_ammoOffset, this.m_wantedAmmoOffset) && !NativeAmmo.Unload(player, weapon, this.m_ammoOffset) {
      this.FallbackUnload(weapon);
    }
    return false;
  }

  // Unloads `weapon` if it's waiting to; false if that has to be tried again later.
  private final func UnloadIfMarked(weapon: ref<WeaponObject>) -> Bool {
    let id: ItemID = weapon.GetItemID();
    if !ArrayContains(this.m_unload, id) {
      return true;
    }
    if !NativeAmmo.Unload(this.m_player, weapon, this.m_ammoOffset) {
      return false;
    }
    ArrayRemove(this.m_unload, id);
    AmmoFeedSystem.Log("unloaded " + TDBID.ToStringDEBUG(ItemID.GetTDBID(id)));
    return true;
  }

  // The magazine count couldn't be written: unload the gun in hand the old way.
  private final func FallbackUnload(weapon: ref<WeaponObject>) -> Void {
    let player: ref<PlayerPuppet> = this.m_player;
    let id: ItemID = weapon.GetItemID();
    ArrayRemove(this.m_unload, id);
    // Don't loop if the engine restores again straight after a redraw.
    let now: Float = EngineTime.ToFloat(GameInstance.GetSimTime(player.GetGame()));
    AmmoFeedSystem.Log("couldn't write the magazine of " + TDBID.ToStringDEBUG(ItemID.GetTDBID(id)) + ", unloading by redraw");
    if now - this.m_lastRestoreRedraw > 10.0 {
      this.m_lastRestoreRedraw = now;
      AmmoFeedSystem.Redraw(player, id);
    } else {
      AmmoFeedSystem.QueueUnload(player, false);
    }
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
    let applied: Bool = NativeAmmo.Apply(player, weapon, ammo, this.m_ammoOffset, this.m_wantedAmmoOffset);
    if applied && this.UnloadIfMarked(weapon) {
      if attempt > 0 || ammo != AOData.DefaultAmmo(AOData.CaliberForWeapon(ItemID.GetTDBID(id))) {
        AmmoFeedSystem.Log(TDBID.ToStringDEBUG(ItemID.GetTDBID(id)) + " takes " + TDBID.ToStringDEBUG(ammo));
      }
      return;
    }
    // The magazine count of a respawned gun can take over a second to come through.
    if attempt >= 30 {
      if !applied {
        AmmoFeedSystem.Log("couldn't give " + TDBID.ToStringDEBUG(ItemID.GetTDBID(id)) + " " + TDBID.ToStringDEBUG(ammo) + " (ammo field not found)");
      } else {
        if weapon == ScriptedPuppet.GetWeaponRight(player) {
          this.FallbackUnload(weapon);
        }
      }
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

  // --- Debug entry points for the CET checks (tools/snippets/slice) --------------------------

  // The last Ammo section the weapon screen built (AmmoSection.reds), for DebugAmmoSection.
  public final func NoteAmmoSection(description: String) -> Void {
    this.m_ammoSection = description;
  }

  // "attachments <i> ammo <i> mods <i> | slots <feed slot IDs> | label <text>", or "" if the
  // weapon screen hasn't been opened since the game started.
  public final func DebugAmmoSection() -> String {
    return this.m_ammoSection;
  }

  // "<loot-window placeholder of item> <empty-slot placeholder of slot>".
  public final func DebugIcons(item: String, slot: String) -> String {
    let none: gamedataItemType;
    let area: gamedataEquipmentArea;
    return NameToString(UIItemsHelper.GetLootingShadowIcon(TDBID.Create(item), TDBID.None(), none, area)) + " "
      + NameToString(UIItemsHelper.GetSlotShadowIcon(TDBID.Create(slot), none, area));
  }

  // "item=quantity;..." of AmmoDistribution.Spread.
  public final func DebugSpread(vanilla: String, quantity: Int32, maxTier: Int32) -> String {
    let text: String = "";
    for stack in AmmoDistribution.Spread(TDBID.Create(vanilla), quantity, maxTier) {
      text += TDBID.ToStringDEBUG(stack.ammo) + "=" + IntToString(stack.quantity) + ";";
    }
    return text;
  }

  // "item=count;..." over `n` AmmoDistribution.Pick calls. `owned` is a comma-separated caliber
  // list standing in for the player's guns; "" uses the guns the player really carries.
  public final func DebugPick(vanilla: String, maxTier: Int32, n: Int32, owned: String) -> String {
    let calibers: array<String> = Equals(owned, "")
      ? AmmoDistribution.OwnedCalibers(GetPlayer(this.GetGameInstance()))
      : StrSplit(owned, ",");
    let items: array<TweakDBID>;
    let counts: array<Int32>;
    let i: Int32 = 0;
    while i < n {
      let item: TweakDBID = AmmoDistribution.Pick(TDBID.Create(vanilla), maxTier, calibers);
      let at: Int32 = ArrayFindFirst(items, item);
      if at < 0 {
        ArrayPush(items, item);
        ArrayPush(counts, 1);
      } else {
        counts[at] += 1;
      }
      i += 1;
    }
    let text: String = "";
    i = 0;
    while i < ArraySize(items) {
      text += TDBID.ToStringDEBUG(items[i]) + "=" + IntToString(counts[i]) + ";";
      i += 1;
    }
    return text;
  }

  // One line per known vendor with ammo: "<vendor> <type> | item=quantity;...".
  public final func DebugVendors() -> String {
    let text: String = "";
    for vendor in MarketSystem.GetInstance(this.GetGameInstance()).AODebugVendors() {
      let ammo: String = vendor.AODebugAmmo();
      if NotEquals(ammo, "") {
        text += TDBID.ToStringDEBUG(vendor.GetVendorTweakID()) + " " + EnumValueToString("gamedataVendorType", Cast<Int64>(EnumInt(vendor.GetVendorType()))) + " | " + ammo + "\n";
      }
    }
    return text;
  }

  // Restocks a known vendor now; "<ammo before> -> <ammo after>".
  public final func DebugRestock(vendorID: String) -> String {
    for vendor in MarketSystem.GetInstance(this.GetGameInstance()).AODebugVendors() {
      if vendor.GetVendorTweakID() == TDBID.Create(vendorID) {
        let before: String = vendor.AODebugAmmo();
        vendor.AODebugRestock();
        return before + " -> " + vendor.AODebugAmmo();
      }
    }
    return "no vendor " + vendorID;
  }

  public final func Trail() -> String {
    let text: String = "";
    for line in this.m_trail {
      text += line + "\n";
    }
    return text;
  }

  // Applies the on-hit effect of the ammo the firing weapon uses, for the player's shots and NPCs'
  // alike (the gun's selection is read from its owner's inventory). Called from the damage pipeline
  // before vanilla applies the attack's status effects, so vanilla's blocked/friendly/immunity
  // checks still apply to ours.
  public static func ApplyAmmoOnHit(hitEvent: ref<gameHitEvent>) -> Void {
    let attackData: ref<AttackData> = hitEvent.attackData;
    if !IsDefined(attackData) {
      return;
    }
    let instigator: ref<GameObject> = attackData.GetInstigator();
    if !IsDefined(instigator) {
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
    let npc: ref<NPCPuppet> = instigator as NPCPuppet;
    let ammo: TweakDBID = IsDefined(npc) ? NpcAmmo.GunAmmo(npc, weaponID) : AOData.SelectedAmmo(instigator, weaponID, caliber);
    let effect: TweakDBID = AOData.OnHitEffect(ammo, chance);
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

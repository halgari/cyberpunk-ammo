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

  // Loot containers whose vanilla ammo has been converted (LootConvert). Saved with the game.
  private persistent let m_convertedContainers: array<EntityID>;

  // Vendors whose ammo stock has been split (Vendors.reds). Saved with the game.
  private persistent let m_splitVendors: array<TweakDBID>;

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

  // Resolved damage rolls, one map per (family, damage type): families "" (unmanaged), Power, Tech,
  // Smart; types "" first, then DamageTypes(). Keyed by the ammo's TDBID number. And each weapon
  // record's caliber ("" boxed too), keyed the same way.
  private let m_rolls: array<ref<inkHashMap>>;
  private let m_calibers: ref<inkHashMap>;
  private let m_factors: ref<inkHashMap>;

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

  public final func MarkVendorSplit(vendor: TweakDBID) -> Void {
    if !ArrayContains(this.m_splitVendors, vendor) {
      ArrayPush(this.m_splitVendors, vendor);
    }
  }

  public final func IsVendorSplit(vendor: TweakDBID) -> Bool {
    return ArrayContains(this.m_splitVendors, vendor);
  }

  // Notes a container as converted; false if it already was.
  public final func MarkConverted(container: EntityID) -> Bool {
    if ArrayContains(this.m_convertedContainers, container) {
      return false;
    }
    ArrayPush(this.m_convertedContainers, container);
    return true;
  }

  public static func DamageTypes() -> array<String> {
    return ["", "Physical", "Thermal", "Electric", "Chemical"];
  }

  // The damage roll of `ammo` for one damage type ("" for the whole hit). The family is the
  // ammo's own AO_Family tag, else `family`: the vanilla Common rounds carry no tag, and are fired
  // by managed guns (their family's layer) and unmanaged ones ("", the global roll) alike.
  public final func Roll(ammo: TweakDBID, family: String, damageType: String) -> AORoll {
    let types: array<String> = AmmoFeedSystem.DamageTypes();
    let index: Int32 = ArrayFindFirst(types, damageType);
    if index < 0 {
      index = 0;
      damageType = "";
    }
    let tagged: String = DamageRoll.AmmoFamily(ammo);
    if StrLen(tagged) > 0 {
      family = tagged;
    }
    let families: array<String> = ["", "Power", "Tech", "Smart"];
    let fam: Int32 = Max(ArrayFindFirst(families, family), 0);
    if fam == 0 {
      family = "";
    }
    index = fam * ArraySize(types) + index;
    while ArraySize(this.m_rolls) <= index {
      ArrayPush(this.m_rolls, new inkHashMap());
    }
    let key: Uint64 = TDBID.ToNumber(ammo);
    let box: ref<AORollBox> = this.m_rolls[index].Get(key) as AORollBox;
    if !IsDefined(box) {
      box = new AORollBox();
      box.roll = DamageRoll.Values(ammo, family, damageType);
      this.m_rolls[index].Insert(key, box);
    }
    return box.roll;
  }

  public final func CachedCaliber(weapon: TweakDBID) -> String {
    if !IsDefined(this.m_calibers) {
      this.m_calibers = new inkHashMap();
    }
    let key: Uint64 = TDBID.ToNumber(weapon);
    let box: ref<AOCaliberBox> = this.m_calibers.Get(key) as AOCaliberBox;
    if !IsDefined(box) {
      box = new AOCaliberBox();
      box.caliber = AOData.FindCaliber(weapon);
      this.m_calibers.Insert(key, box);
    }
    return box.caliber;
  }

  // AOData.AmmoDamageFactor of `ammo`, cached (keyed like the calibers).
  public final func DamageFactor(ammo: TweakDBID) -> Float {
    if !IsDefined(this.m_factors) {
      this.m_factors = new inkHashMap();
    }
    let key: Uint64 = TDBID.ToNumber(ammo);
    let box: ref<AOFactorBox> = this.m_factors.Get(key) as AOFactorBox;
    if !IsDefined(box) {
      box = new AOFactorBox();
      box.factor = AOData.AmmoDamageFactor(ammo);
      this.m_factors.Insert(key, box);
    }
    return box.factor;
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

  // The ammo IDs of a caliber's tier, space-separated.
  public final func DebugTierAmmo(caliber: String, tier: Int32) -> String {
    let text: String = "";
    for ammo in AOData.AmmosForTier(caliber, tier) {
      text += TDBID.ToStringDEBUG(ammo) + " ";
    }
    return text;
  }

  // "ammo=count;..." over `n` NpcAmmo.PickUncommon calls, as the selector's ammo.
  public final func DebugUncommonPick(caliber: String, n: Int32) -> String {
    let items: array<TweakDBID>;
    let counts: array<Int32>;
    let i: Int32 = 0;
    while i < n {
      let ammo: TweakDBID = AOData.SelectorAmmo(caliber, NpcAmmo.PickUncommon(caliber));
      let at: Int32 = ArrayFindFirst(items, ammo);
      if at < 0 {
        ArrayPush(items, ammo);
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

  // "min max dudChance dudMult hotChance hotMult" of an ammo's roll; `fresh` drops the cache first.
  public final func DebugRollFor(ammo: String, damageType: String, fresh: Bool) -> String {
    if fresh {
      ArrayClear(this.m_rolls);
    }
    let r: AORoll = this.Roll(TDBID.Create(ammo), "", damageType);
    return FloatToString(r.min) + " " + FloatToString(r.max) + " " + FloatToString(r.dudChance) + " "
      + FloatToString(r.dudMult) + " " + FloatToString(r.hotChance) + " " + FloatToString(r.hotMult);
  }

  // As DebugRollFor, through the cache, with the caller's family ("" for an unmanaged gun).
  public final func DebugRollWith(ammo: String, family: String, damageType: String) -> String {
    let r: AORoll = this.Roll(TDBID.Create(ammo), family, damageType);
    return FloatToString(r.min) + " " + FloatToString(r.max);
  }

  public final func DebugDamageFactor(ammo: String) -> String {
    return FloatToString(this.DamageFactor(TDBID.Create(ammo)));
  }

  // The ammo AOData.LoadedAmmo reads for `target`'s active weapon ("" if it holds none).
  public final func DebugLoadedAmmo(target: ref<GameObject>) -> String {
    let weapon: ref<WeaponObject> = GameObject.GetActiveWeapon(target);
    return IsDefined(weapon) ? TDBID.ToStringDEBUG(AOData.LoadedAmmo(target, weapon)) : "";
  }

  // "min max mean duds hots" over `n` draws of an ammo's roll (duds and hots counted by value).
  public final func DebugRollDraws(ammo: String, damageType: String, n: Int32) -> String {
    let r: AORoll = this.Roll(TDBID.Create(ammo), "", damageType);
    let lo: Float = 1000000.0;
    let hi: Float = -1000000.0;
    let sum: Float = 0.0;
    let duds: Int32 = 0;
    let hots: Int32 = 0;
    let i: Int32 = 0;
    while i < n {
      let v: Float = DamageRoll.Draw(r);
      lo = MinF(lo, v);
      hi = MaxF(hi, v);
      sum += v;
      if r.dudChance > 0.0 && v == r.dudMult {
        duds += 1;
      } else {
        if r.hotChance > 0.0 && v == r.hotMult {
          hots += 1;
        }
      }
      i += 1;
    }
    return FloatToString(lo) + " " + FloatToString(hi) + " " + FloatToString(sum / Cast<Float>(n)) + " "
      + IntToString(duds) + " " + IntToString(hots);
  }

  // A weapon record's caliber, through the cache or (`fresh`) looked up again.
  public final func DebugCaliber(weapon: String, fresh: Bool) -> String {
    return fresh ? AOData.FindCaliber(TDBID.Create(weapon)) : this.CachedCaliber(TDBID.Create(weapon));
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

  // What a known vendor's ammo is once its screen opens (an unsplit stock gets split then).
  public final func DebugOpenVendor(vendorID: String) -> String {
    for vendor in MarketSystem.GetInstance(this.GetGameInstance()).AODebugVendors() {
      if vendor.GetVendorTweakID() == TDBID.Create(vendorID) {
        vendor.AOBeforeFill();
        return vendor.AODebugAmmo();
      }
    }
    return "no vendor " + vendorID;
  }

  // Buys out a known vendor's rounds (9mm Ball stays), then goes through a save load and the
  // vendor screen opening: "<ammo after>".
  public final func DebugReloadVendor(vendorID: String) -> String {
    for vendor in MarketSystem.GetInstance(this.GetGameInstance()).AODebugVendors() {
      if vendor.GetVendorTweakID() == TDBID.Create(vendorID) {
        vendor.AODebugBuyOutRounds();
        vendor.OnRestored(this.GetGameInstance(), false);
        vendor.AOBeforeFill();
        return vendor.AODebugAmmo();
      }
    }
    return "no vendor " + vendorID;
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

  // Runs LootConvert on any object: once=false converts regardless, once=true goes through the
  // converted-containers list like the fill event. "<stacks converted>".
  public final func DebugConvert(target: ref<GameObject>, once: Bool) -> String {
    return IntToString(once ? LootConvert.ConvertOnce(target) : LootConvert.Convert(target));
  }

  // The body's loot through a knockout, the player taking `take` rounds, death, and the game's
  // loot event, with each wipe of the inventory simulated (the engine wipes it at death and at
  // incapacitation). Runs the real NoteLoot, NpcLootCallback.Call and RestoreLoot on `target` given
  // `rounds` of `ammo`. "<after knockout> <after taking> <after death> <after loot event>".
  public final func DebugLootCycle(target: ref<GameObject>, ammo: String, rounds: Int32, take: Int32) -> String {
    let npc: ref<NPCPuppet> = target as NPCPuppet;
    if !IsDefined(npc) {
      return "not an NPC";
    }
    let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(npc.GetGame());
    let id: TweakDBID = TDBID.Create(ammo);
    ArrayClear(npc.aoLootAmmo);
    ArrayClear(npc.aoLootQuantity);
    npc.aoLootGiven = false;
    ArrayClear(npc.aoStocked);
    ArrayPush(npc.aoStocked, id);
    ts.RemoveItemByTDBID(npc, id, NpcAmmo.Rounds(npc, id));
    ts.GiveItem(npc, ItemID.CreateQuery(id), rounds);
    let callback: ref<NpcLootCallback> = new NpcLootCallback();
    callback.npc = npc;
    NpcAmmo.NoteLoot(npc);
    ts.RemoveItemByTDBID(npc, id, NpcAmmo.Rounds(npc, id));
    callback.Call();
    let out: String = IntToString(NpcAmmo.Rounds(npc, id));
    ts.RemoveItemByTDBID(npc, id, take);
    out += " " + IntToString(NpcAmmo.Rounds(npc, id));
    NpcAmmo.NoteLoot(npc);
    ts.RemoveItemByTDBID(npc, id, NpcAmmo.Rounds(npc, id));
    callback.Call();
    out += " " + IntToString(NpcAmmo.Rounds(npc, id));
    NpcAmmo.RestoreLoot(npc);
    return out + " " + IntToString(NpcAmmo.Rounds(npc, id));
  }

  // Whether the fill event (or DebugConvert with once) has converted this container.
  public final func DebugIsConverted(target: ref<GameObject>) -> Bool {
    return ArrayContains(this.m_convertedContainers, target.GetEntityID());
  }

  public final func Trail() -> String {
    let text: String = "";
    for line in this.m_trail {
      text += line + "\n";
    }
    return text;
  }

  // The weapon's ProjectilesPerShot over its unmodified count (ProjectilesPerShotBase); 1.0 when
  // either is missing or 0.
  public static func PelletRatio(weapon: ref<WeaponObject>) -> Float {
    let stats: ref<StatsSystem> = GameInstance.GetStatsSystem(weapon.GetGame());
    let id: StatsObjectID = weapon.GetItemData().GetStatsObjectID();
    let base: Float = stats.GetStatValue(id, gamedataStatType.ProjectilesPerShotBase);
    let count: Float = stats.GetStatValue(id, gamedataStatType.ProjectilesPerShot);
    return base > 0.0 && count > 0.0 ? count / base : 1.0;
  }

  // Rolls a ranged gun hit's damage with its loaded round's roll; false (nothing done) for any
  // other hit. Each damage type with its own values rolls on its own, the rest share one roll.
  public static func RollGunHit(hitEvent: ref<gameHitEvent>) -> Bool {
    let attackData: ref<AttackData> = hitEvent.attackData;
    if !IsDefined(attackData) || !AttackData.IsRangedOrDirect(attackData.GetAttackType()) || AttackData.IsDoT(attackData) {
      return false;
    }
    let weapon: ref<WeaponObject> = attackData.GetWeapon();
    let instigator: ref<GameObject> = attackData.GetInstigator();
    let system: ref<AmmoFeedSystem> = AmmoFeedSystem.Get(GetGameInstance());
    if !IsDefined(weapon) || !IsDefined(instigator) || !IsDefined(system) || !WeaponObject.IsRanged(weapon.GetItemID()) {
      return false;
    }
    let ammo: TweakDBID = AOData.LoadedAmmo(instigator, weapon);
    let family: String = AOData.Family(AOData.CaliberForWeapon(ItemID.GetTDBID(weapon.GetItemID())));
    let whole: AORoll = system.Roll(ammo, family, "");
    let factor: Float = DamageRoll.Draw(whole);
    // NPC guns have no DamagePerHit to carry the round's multiplier: apply it to the hit here.
    // The engine also splits an NPC shot's damage by the pellet count twice, so a round that changes
    // the count (Birdshot, Slugs) changes the shot's total: multiply back by the count's change.
    let npcFactor: Float = 1.0;
    if !instigator.IsPlayer() {
      npcFactor = system.DamageFactor(ammo) * AmmoFeedSystem.PelletRatio(weapon);
    }
    let types: array<String> = AmmoFeedSystem.DamageTypes();
    let i: Int32 = 1;
    while i < ArraySize(types) {
      let own: AORoll = system.Roll(ammo, family, types[i]);
      let damageType: gamedataDamageType = IntEnum<gamedataDamageType>(Cast<Int32>(EnumValueFromString("gamedataDamageType", types[i])));
      hitEvent.attackComputed.MultAttackValue((DamageRoll.Same(own, whole) ? factor : DamageRoll.Draw(own)) * npcFactor, damageType);
      i += 1;
    }
    return true;
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
    let ammo: TweakDBID = AOData.LoadedAmmo(instigator, weapon);
    let effect: TweakDBID = AOData.OnHitEffect(ammo, chance);
    if TDBID.IsValid(effect) && RandF() < chance {
      attackData.AddStatusEffect(effect, 1.0);
    }
  }
}

public class AOFactorBox extends IScriptable {
  let factor: Float;
}

public class AOCaliberBox extends IScriptable {
  let caliber: String;
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

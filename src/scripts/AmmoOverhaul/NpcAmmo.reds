module AmmoOverhaul

// NPCs carry real ammo and use it up.
//
// When a hostile NPC first draws a gun it is given ammo for it: a number of that gun's magazines
// set by the NPC's rarity (AmmoOverhaul.npcMagazines.*). Like the player's, the stack includes the rounds in the
// gun: every shot (AIWeapon.Fire) takes rounds from it, and with none left the gun neither fires
// nor reloads. The NPC then switches to another gun that still has ammo; with none left, its
// guns are taken out of its inventory (they come back as loot), which leaves it to the AI's
// melee or no-weapon combat.
//
// What's left is the body's loot. Death and incapacitation wipe an NPC's inventory before loot is
// generated, so the stacks are noted then and given back once the loot is in
// (EvaluateLootQuality). The engine's own random ammo drop is turned off (AmmoFeedTweak).
//
// NPCs friendly to the player (companions, allies in a quest fight) aren't counted; they're
// stocked if they turn hostile.

// Ammo types it was given, and the guns it was given them for.
@addField(NPCPuppet)
public let aoStocked: array<TweakDBID>;

@addField(NPCPuppet)
public let aoStockedGuns: array<ItemID>;

@addField(NPCPuppet)
public let aoSwitchCommands: Int32;

@addField(NPCPuppet)
public let aoStashedGuns: array<TweakDBID>;

@addField(NPCPuppet)
public let aoLastDryCommand: Float;

@addField(NPCPuppet)
public let aoLootAmmo: array<TweakDBID>;

@addField(NPCPuppet)
public let aoLootQuantity: array<Int32>;

public abstract class NpcAmmo {

  // Hostile NPCs in the world; not the inventory screen's preview puppet, which is an NPCPuppet.
  public static func IsCounted(npc: ref<NPCPuppet>) -> Bool {
    return IsDefined(npc) && !npc.IsCrowd() && !npc.IsPlayerCompanion() && !GameObject.IsFriendlyTowardsPlayer(npc)
      && !StrBeginsWith(TDBID.ToStringDEBUG(npc.GetRecordID()), "Character.Player_Puppet");
  }

  public static func AmmoFor(npc: ref<NPCPuppet>, weapon: ref<WeaponObject>) -> TweakDBID {
    if !IsDefined(weapon) || weapon.IsMelee() {
      return TDBID.None();
    }
    return NpcAmmo.GunAmmo(npc, weapon.GetItemID());
  }

  // The ammo a gun in `npc`'s inventory uses: for the mod's guns the one its feed slot selects,
  // like the player's, otherwise its record's.
  public static func GunAmmo(npc: ref<NPCPuppet>, gun: ItemID) -> TweakDBID {
    let ammo: TweakDBID = NpcAmmo.RecordAmmo(ItemID.GetTDBID(gun));
    let caliber: String = AOData.CaliberForWeapon(ItemID.GetTDBID(gun));
    if TDBID.IsValid(ammo) && StrLen(caliber) > 0 {
      let selected: TweakDBID = AOData.SelectedAmmo(npc, gun, caliber);
      if TDBID.IsValid(selected) {
        return selected;
      }
    }
    return ammo;
  }

  // The ammo item a gun record uses, or an invalid ID if it doesn't use a real one: melee weapons,
  // cyberware and heavy machine guns carry the placeholder Ammo.Standard and stay unlimited.
  public static func RecordAmmo(weapon: TweakDBID) -> TweakDBID {
    let record: ref<WeaponItem_Record> = TweakDBInterface.GetWeaponItemRecord(weapon);
    if !IsDefined(record) || !IsDefined(record.Ammo()) {
      return TDBID.None();
    }
    let ammo: ref<Item_Record> = record.Ammo();
    if ammo.GetID() == t"Ammo.Standard" || !IsDefined(ammo.ItemType()) || NotEquals(ammo.ItemType().Type(), gamedataItemType.Con_Ammo) {
      return TDBID.None();
    }
    return ammo.GetID();
  }

  public static func Magazines(npc: ref<NPCPuppet>) -> Int32 {
    let rarity: String = EnumValueToString("gamedataNPCRarity", Cast<Int64>(EnumInt(npc.GetNPCRarity())));
    return TweakDBInterface.GetInt(TDBID.Create("AmmoOverhaul.npcMagazines." + rarity), 3);
  }

  // The first time `npc` needs ammo, gives it ammo for every gun it carries.
  public static func Stock(npc: ref<NPCPuppet>, weapon: ref<WeaponObject>) -> Void {
    if ArrayContains(npc.aoStockedGuns, weapon.GetItemID()) {
      return;
    }
    let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(npc.GetGame());
    let restored: Bool = ArraySize(npc.aoStockedGuns) == 0;
    let items: array<wref<gameItemData>>;
    ts.GetItemList(npc, items);
    for item in items {
      let id: ItemID = item.GetID();
      let ammo: TweakDBID = NpcAmmo.GunAmmo(npc, id);
      if TDBID.IsValid(ammo) && !ArrayContains(npc.aoStockedGuns, id) {
        ArrayPush(npc.aoStockedGuns, id);
        if !ArrayContains(npc.aoStocked, ammo) {
          ArrayPush(npc.aoStocked, ammo);
        }
        // Carrying ammo before anything was stocked: restored with a save, so that's its stock.
        if !restored || ts.GetItemQuantity(npc, ItemID.CreateQuery(ammo)) == 0 {
          let capacity: Int32 = Max(1, Cast<Int32>(item.GetStatValueByType(gamedataStatType.MagazineCapacity)));
          let rounds: Int32 = capacity * NpcAmmo.Magazines(npc);
          ts.GiveItem(npc, ItemID.CreateQuery(ammo), rounds);
          AmmoFeedSystem.Log(NpcAmmo.Name(npc) + " stocked " + IntToString(rounds) + " " + TDBID.ToStringDEBUG(ammo) + " for " + TDBID.ToStringDEBUG(ItemID.GetTDBID(id)));
        }
      }
    }
  }

  public static func Rounds(npc: ref<NPCPuppet>, ammo: TweakDBID) -> Int32 {
    return GameInstance.GetTransactionSystem(npc.GetGame()).GetItemQuantity(npc, ItemID.CreateQuery(ammo));
  }

  // A shot is about to be fired: takes its rounds, or false if there are none.
  public static func TakeShot(npc: ref<NPCPuppet>, weapon: ref<WeaponObject>) -> Bool {
    let ammo: TweakDBID = NpcAmmo.AmmoFor(npc, weapon);
    if !TDBID.IsValid(ammo) || !NpcAmmo.IsCounted(npc) {
      return true;
    }
    NpcAmmo.Stock(npc, weapon);
    let have: Int32 = NpcAmmo.Rounds(npc, ammo);
    if have <= 0 {
      NpcAmmo.OnDry(npc, weapon);
      return false;
    }
    let cost: Int32 = Cast<Int32>(GameInstance.GetStatsSystem(npc.GetGame()).GetStatValue(Cast<StatsObjectID>(weapon.GetEntityID()), gamedataStatType.NumShotsToFire));
    GameInstance.GetTransactionSystem(npc.GetGame()).RemoveItem(npc, ItemID.CreateQuery(ammo), Min(Max(cost, 1), have));
    return true;
  }

  // False if `npc` is out of ammo for `weapon`, so it shouldn't reload.
  public static func CanReload(npc: ref<NPCPuppet>, weapon: ref<WeaponObject>) -> Bool {
    let ammo: TweakDBID = NpcAmmo.AmmoFor(npc, weapon);
    if !TDBID.IsValid(ammo) || !NpcAmmo.IsCounted(npc) || !ArrayContains(npc.aoStocked, ammo) {
      return true;
    }
    if NpcAmmo.Rounds(npc, ammo) > 0 {
      return true;
    }
    NpcAmmo.OnDry(npc, weapon);
    return false;
  }

  // Out of ammo for the gun in hand.
  private static func OnDry(npc: ref<NPCPuppet>, weapon: ref<WeaponObject>) -> Void {
    let now: Float = EngineTime.ToFloat(GameInstance.GetSimTime(npc.GetGame()));
    if now - npc.aoLastDryCommand < 1.5 {
      return;
    }
    npc.aoLastDryCommand = now;
    let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(npc.GetGame());
    let items: array<wref<gameItemData>>;
    let guns: array<ItemID>;
    let loaded: Bool = false;
    ts.GetItemList(npc, items);
    for item in items {
      let ammo: TweakDBID = NpcAmmo.GunAmmo(npc, item.GetID());
      if TDBID.IsValid(ammo) {
        ArrayPush(guns, item.GetID());
        if NpcAmmo.Rounds(npc, ammo) > 0 {
          loaded = true;
        }
      }
    }
    // Another gun still has ammo: the AI only knows primary and secondary, so alternate.
    if loaded && npc.aoSwitchCommands < 4 {
      let command: ref<AICommand> = npc.aoSwitchCommands % 2 == 0 ? new AISwitchToSecondaryWeaponCommand() : new AISwitchToPrimaryWeaponCommand();
      npc.aoSwitchCommands += 1;
      npc.GetAIControllerComponent().SendCommand(command);
      AmmoFeedSystem.Log(NpcAmmo.Name(npc) + " out of " + TDBID.ToStringDEBUG(NpcAmmo.AmmoFor(npc, weapon)) + ", switching weapon");
      return;
    }
    for gun in guns {
      if !ArrayContains(npc.aoStashedGuns, ItemID.GetTDBID(gun)) {
        ArrayPush(npc.aoStashedGuns, ItemID.GetTDBID(gun));
      }
      ts.RemoveItem(npc, gun, 1);
    }
    AmmoFeedSystem.Log(NpcAmmo.Name(npc) + " out of ammo for all " + IntToString(ArraySize(guns)) + " gun(s)");
  }

  // Notes the ammo `npc` carries before death or incapacitation wipes it.
  public static func NoteLoot(npc: ref<NPCPuppet>) -> Void {
    if (ArraySize(npc.aoStocked) == 0 && ArraySize(npc.aoStashedGuns) == 0) || ArraySize(npc.aoLootAmmo) > 0 {
      return;
    }
    for ammo in npc.aoStocked {
      let rounds: Int32 = NpcAmmo.Rounds(npc, ammo);
      if rounds > 0 {
        ArrayPush(npc.aoLootAmmo, ammo);
        ArrayPush(npc.aoLootQuantity, rounds);
      }
    }
  }

  // Loot has been generated: put the noted ammo back for the player to take.
  public static func RestoreLoot(npc: ref<NPCPuppet>) -> Void {
    let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(npc.GetGame());
    let i: Int32 = 0;
    while i < ArraySize(npc.aoLootAmmo) {
      let missing: Int32 = npc.aoLootQuantity[i] - NpcAmmo.Rounds(npc, npc.aoLootAmmo[i]);
      if missing > 0 {
        ts.GiveItem(npc, ItemID.CreateQuery(npc.aoLootAmmo[i]), missing);
      }
      AmmoFeedSystem.Log(NpcAmmo.Name(npc) + " leaves " + IntToString(npc.aoLootQuantity[i]) + " " + TDBID.ToStringDEBUG(npc.aoLootAmmo[i]));
      i += 1;
    }
    for gun in npc.aoStashedGuns {
      ts.GiveItem(npc, ItemID.FromTDBID(gun), 1);
    }
    ArrayClear(npc.aoStashedGuns);
    ArrayClear(npc.aoLootAmmo);
    ArrayClear(npc.aoLootQuantity);
    ArrayClear(npc.aoStocked);
    ArrayClear(npc.aoStockedGuns);
  }

  private static func Name(npc: ref<NPCPuppet>) -> String {
    return TDBID.ToStringDEBUG(npc.GetRecordID());
  }
}

// --- Hooks -----------------------------------------------------------------------------------

@wrapMethod(NPCPuppet)
protected cb func OnItemAddedToSlot(evt: ref<ItemAddedToSlot>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  let slot: TweakDBID = evt.GetSlotID();
  if (slot == t"AttachmentSlots.WeaponRight" || slot == t"AttachmentSlots.WeaponLeft") && NpcAmmo.IsCounted(this) {
    let weapon: ref<WeaponObject> = GameInstance.GetTransactionSystem(this.GetGame()).GetItemInSlot(this, slot) as WeaponObject;
    if IsDefined(weapon) {
      NpcAmmo.Stock(this, weapon);
    }
  }
  return result;
}

@wrapMethod(AIWeapon)
public final static func Fire(weaponOwner: wref<GameObject>, weapon: wref<WeaponObject>, const timeStamp: Float, tbhCoefficient: Float, requestedTriggerMode: gamedataTriggerMode, opt targetPosition: Vector4, opt target: ref<GameObject>, opt rangedAttack: TweakDBID, opt maxSpreadOverride: Float, opt aimingDelay: Float, opt offset: Vector4, opt shouldTrackTarget: Bool, opt predictionTime: Float, opt posProviderOverride: ref<IPositionProvider>, opt muzzleOffset: Vector4, opt weaponCustomEvent: CName) -> Void {
  let npc: ref<NPCPuppet> = weaponOwner as NPCPuppet;
  if IsDefined(npc) && IsDefined(weapon) && !NpcAmmo.TakeShot(npc, weapon) {
    return;
  }
  wrappedMethod(weaponOwner, weapon, timeStamp, tbhCoefficient, requestedTriggerMode, targetPosition, target, rangedAttack, maxSpreadOverride, aimingDelay, offset, shouldTrackTarget, predictionTime, posProviderOverride, muzzleOffset, weaponCustomEvent);
}

@wrapMethod(AISubActionReloadWeapon_Record_Implementation)
public final static func Activate(context: ScriptExecutionContext, record: wref<AISubActionReloadWeapon_Record>) -> Void {
  let weapon: wref<WeaponObject>;
  let npc: ref<NPCPuppet> = ScriptExecutionContext.GetOwner(context) as NPCPuppet;
  if IsDefined(npc) && AISubActionReloadWeapon_Record_Implementation.GetWeapon(context, record, weapon) && !NpcAmmo.CanReload(npc, weapon) {
    return;
  }
  wrappedMethod(context, record);
}

@wrapMethod(AISubActionReloadWeapon_Record_Implementation)
public final static func Update(context: ScriptExecutionContext, record: wref<AISubActionReloadWeapon_Record>, const duration: Float) -> AIbehaviorUpdateOutcome {
  let weapon: wref<WeaponObject>;
  let npc: ref<NPCPuppet> = ScriptExecutionContext.GetOwner(context) as NPCPuppet;
  if IsDefined(npc) && AISubActionReloadWeapon_Record_Implementation.GetWeapon(context, record, weapon) && !NpcAmmo.CanReload(npc, weapon) {
    return AIbehaviorUpdateOutcome.SUCCESS;
  }
  return wrappedMethod(context, record, duration);
}

@wrapMethod(NPCPuppet)
protected cb func OnDeath(evt: ref<gameDeathEvent>) -> Bool {
  NpcAmmo.NoteLoot(this);
  return wrappedMethod(evt);
}

@wrapMethod(NPCPuppet)
protected func OnIncapacitated() -> Void {
  NpcAmmo.NoteLoot(this);
  wrappedMethod();
}

@wrapMethod(ScriptedPuppet)
private final func EvaluateLootQuality() -> Bool {
  let npc: ref<NPCPuppet> = this as NPCPuppet;
  if IsDefined(npc) && (ArraySize(npc.aoLootAmmo) > 0 || ArraySize(npc.aoStashedGuns) > 0) {
    NpcAmmo.RestoreLoot(npc);
  }
  return wrappedMethod();
}

// The AI gives NPCs back any record equipment missing from their inventory; leave out the guns
// taken away for lack of ammo.
@wrapMethod(AIActionTransactionSystem)
public final static func CalculateEquipmentItems(const puppet: wref<ScriptedPuppet>, equipmentGroupRecord: wref<NPCEquipmentGroup_Record>, out items: array<wref<NPCEquipmentItem_Record>>, powerLevel: Int32) -> Void {
  wrappedMethod(puppet, equipmentGroupRecord, items, powerLevel);
  let npc: ref<NPCPuppet> = puppet as NPCPuppet;
  if !IsDefined(npc) || ArraySize(npc.aoStashedGuns) == 0 {
    return;
  }
  let i: Int32 = ArraySize(items) - 1;
  while i >= 0 {
    if IsDefined(items[i].Item()) && ArrayContains(npc.aoStashedGuns, items[i].Item().GetID()) {
      ArrayErase(items, i);
    }
    i -= 1;
  }
}

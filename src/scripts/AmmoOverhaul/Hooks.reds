module AmmoOverhaul

// --- Per-gun ammo ---------------------------------------------------------------------------

// Every spawn of a weapon, including the respawn after a part change.
@wrapMethod(WeaponObject)
protected cb func OnGameAttached() -> Bool {
  let result: Bool = wrappedMethod();
  let system: ref<AmmoFeedSystem> = AmmoFeedSystem.Get(this.GetGame());
  if IsDefined(system) {
    system.OnWeaponSpawned(this);
  }
  return result;
}

// A draw doesn't respawn the gun but copies the record's ammo into it again, somewhere between
// the item reaching the hand slot and the equip finishing. Applying at both points covers it
// before the gun can fire.
@wrapMethod(EquipCycleEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  if this.IsRightHandLogic(this.stateMachineInstanceData) {
    AmmoFeedSystem.Get(scriptInterface.executionOwner.GetGame()).OnWeaponDrawn(GameObject.GetActiveWeapon(scriptInterface.executionOwner));
  }
}

@wrapMethod(EquippedEvents)
protected func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  if this.IsRightHandLogic(this.stateMachineInstanceData) {
    AmmoFeedSystem.Get(scriptInterface.executionOwner.GetGame()).OnWeaponDrawn(GameObject.GetActiveWeapon(scriptInterface.executionOwner));
  }
}

// Every selector install, swap and removal (mod screen or script) goes through these two.
@wrapMethod(ItemModificationSystem)
private final func InstallItemPart(obj: ref<GameObject>, itemID: ItemID, partItemID: ItemID, opt slotID: TweakDBID) -> Bool {
  let caliber: String = AOData.CaliberForWeapon(ItemID.GetTDBID(itemID));
  if StrLen(caliber) > 0 && TDBID.IsValid(AOData.SelectorAmmo(caliber, ItemID.GetTDBID(partItemID))) {
    AmmoFeedSystem.Get(obj.GetGame()).BeforeFeedChange(obj, itemID);
  }
  return wrappedMethod(obj, itemID, partItemID, slotID);
}

@wrapMethod(ItemModificationSystem)
private final const func RemoveItemPart(obj: ref<GameObject>, itemID: ItemID, slotID: TweakDBID, shouldUpdateEntity: Bool) -> ItemID {
  let caliber: String = AOData.CaliberForWeapon(ItemID.GetTDBID(itemID));
  if StrLen(caliber) > 0 && slotID == AOData.FeedSlot(caliber) {
    AmmoFeedSystem.Get(obj.GetGame()).BeforeFeedChange(obj, itemID);
  }
  return wrappedMethod(obj, itemID, slotID, shouldUpdateEntity);
}

// --- On-hit ammo effects ---------------------------------------------------------------------

@wrapMethod(DamageSystem)
private final func ProcessStatusEffects(hitEvent: ref<gameHitEvent>) -> Void {
  AmmoFeedSystem.ApplyAmmoOnHit(hitEvent);
  wrappedMethod(hitEvent);
}

// --- Weapon mod screen -----------------------------------------------------------------------
// The mod screens intersect the slots an item really has with these hardcoded lists, so the
// feed slots must be on them to show up at all.

@wrapMethod(InventoryDataManagerV2)
public final static func GetAttachmentSlotsForInventory() -> array<TweakDBID> {
  let slots: array<TweakDBID> = wrappedMethod();
  AOData.AppendFeedSlots(slots);
  return slots;
}

@wrapMethod(UIInventoryItemModsStaticData)
public final static func GetAttachmentSlots(itemType: gamedataItemType) -> array<TweakDBID> {
  let slots: array<TweakDBID> = wrappedMethod(itemType);
  AOData.AppendFeedSlots(slots);
  return slots;
}

// Selectors are swapped freely; vanilla only lets scopes, muzzles and iconic mods come off.
@wrapMethod(RPGManager)
public final static func CanPartBeUnequipped(data: InventoryItemData, slotId: TweakDBID) -> Bool {
  if AOData.IsFeedSlot(slotId) {
    return true;
  }
  return wrappedMethod(data, slotId);
}

// Slot labels come from the slot record's localizedName (a LocKey# string the UI can resolve);
// unknown slots would otherwise fall back to the generic "Mod" label of their item type.
@wrapMethod(UIItemsHelper)
public final static func GetEmptySlotName(slotId: TweakDBID) -> String {
  if AOData.IsFeedSlot(slotId) {
    return TweakDBInterface.GetAttachmentSlotRecord(slotId).LocalizedName();
  }
  return wrappedMethod(slotId);
}

@wrapMethod(UIItemsHelper)
public final static func GetSlotName(slotID: TweakDBID, itemType: gamedataItemType, equipmentArea: gamedataEquipmentArea) -> String {
  if AOData.IsFeedSlot(slotID) {
    return TweakDBInterface.GetAttachmentSlotRecord(slotID).LocalizedName();
  }
  return wrappedMethod(slotID, itemType, equipmentArea);
}

// Vanilla picks these placeholders by record ID for the four vanilla ammo items and the vanilla
// slots, so our rounds and the feed slot would get none.
@wrapMethod(UIItemsHelper)
public final static func GetLootingShadowIcon(itemTDBID: TweakDBID, slotID: TweakDBID, itemType: gamedataItemType, equipmentArea: gamedataEquipmentArea) -> CName {
  let record: ref<Item_Record> = TweakDBInterface.GetItemRecord(itemTDBID);
  if IsDefined(record) && record.TagsContains(n"AO_Ammo") {
    return AOData.FeedShadowIcon();
  }
  return wrappedMethod(itemTDBID, slotID, itemType, equipmentArea);
}

@wrapMethod(UIItemsHelper)
public final static func GetSlotShadowIcon(slotID: TweakDBID, itemType: gamedataItemType, equipmentArea: gamedataEquipmentArea) -> CName {
  if AOData.IsFeedSlot(slotID) {
    return AOData.FeedShadowIcon();
  }
  return wrappedMethod(slotID, itemType, equipmentArea);
}

// --- Ammo in the backpack --------------------------------------------------------------------

// Ammo is carried weight, so it's listed like other items (the backpack hides anything tagged Ammo).
@wrapMethod(UIInventoryItemsManager)
public final static func GetBlacklistedTags() -> array<CName> {
  let tags: array<CName> = wrappedMethod();
  ArrayRemove(tags, n"Ammo");
  return tags;
}

// --- Weapon ammo counts in menus -------------------------------------------------------------

// Weapon cards, tooltips and the D-pad wheel count the ammo of the weapon's record; a managed gun
// takes the ammo its selector picks, so count that instead.
@wrapMethod(UIInventoryItem)
public final func GetAmmo(opt update: Bool) -> Int32 {
  let ammo: Int32 = wrappedMethod(update);
  let selected: Int32 = AOData.SelectedAmmoCount(this.ID);
  if ammo >= 0 && selected >= 0 {
    this.m_weaponData.Ammo = selected;
    return selected;
  }
  return ammo;
}

@wrapMethod(InventoryItemData)
public final static func SetAmmo(self: script_ref<InventoryItemData>, ammo: Int32) -> Void {
  let selected: Int32 = AOData.SelectedAmmoCount(InventoryItemData.GetID(self));
  wrappedMethod(self, selected >= 0 ? selected : ammo);
}

@wrapMethod(InventoryDataManagerV2)
public final func GetAmmoForWeaponType(const itemData: script_ref<InventoryItemData>) -> Int32 {
  let selected: Int32 = AOData.SelectedAmmoCount(InventoryItemData.GetID(itemData));
  return selected >= 0 ? selected : wrappedMethod(itemData);
}

// The HUD's reserve count (and the iron sight counter) is this minus the magazine; count the
// managed gun's selected ammo instead of its record's.
@wrapMethod(RPGManager)
public final static func GetAmmoCountValue(owner: ref<GameObject>, itemID: ItemID) -> Int32 {
  let caliber: String = AOData.CaliberForWeapon(ItemID.GetTDBID(itemID));
  if IsDefined(owner) && StrLen(caliber) > 0 {
    let ammo: TweakDBID = AOData.SelectedAmmo(owner, itemID, caliber);
    if TDBID.IsValid(ammo) {
      return GameInstance.GetTransactionSystem(owner.GetGame()).GetItemQuantity(owner, ItemID.CreateQuery(ammo));
    }
  }
  return wrappedMethod(owner, itemID);
}

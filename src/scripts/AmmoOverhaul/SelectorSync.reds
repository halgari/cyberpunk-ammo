module AmmoOverhaul

// Keeps V's loose selectors in step with the ammo V holds, so the feed slot on the mod screen
// lists every round V can load and nothing else.
//
// Rule, for every selector of every caliber: if V holds at least 1 of its ammo (inventory
// quantity, magazines included), V holds exactly 1 loose copy of it; at 0, none. Selectors fitted
// on guns are not in V's item list and are never touched, so a gun whose round runs out keeps it
// fitted and reads 0 rounds; nothing ever switches ammo by itself.
//
// Triggers: V's item events for ammo and selectors, a selector install or removal, player attach
// (save load) and the mod screen opening. A sync runs on the next frame (items added this frame
// aren't in the item list yet) and is coalesced: one pending at a time, however many events. Its
// own adds and removals raise events too, which request one more sync; that one finds nothing to
// change and schedules nothing.
public class SelectorSync {

  // Schedules a sync for the next frame; does nothing if one is already pending. Item events go
  // through OnItemEvent; every other trigger calls this directly, which also lifts a pause.
  public static func Request(player: ref<PlayerPuppet>) -> Void {
    if !IsDefined(player) {
      return;
    }
    let system: ref<SelectorSyncSystem> = SelectorSyncSystem.Get(player.GetGame());
    if !IsDefined(system) {
      return;
    }
    system.paused = false;
    if system.pending {
      return;
    }
    system.pending = true;
    let callback: ref<SelectorSyncCallback> = new SelectorSyncCallback();
    callback.player = player;
    GameInstance.GetDelaySystem(player.GetGame()).DelayCallbackNextFrame(callback);
  }

  // Player attach: a fresh count, a clear pending flag (a callback queued before a load never
  // runs) and a sync, which also cleans up an old save's loose duplicates.
  public static func Attach(player: ref<PlayerPuppet>) -> Void {
    let system: ref<SelectorSyncSystem> = SelectorSyncSystem.Get(player.GetGame());
    if !IsDefined(system) {
      return;
    }
    system.count = 0;
    system.pending = false;
    system.streak = 0;
    SelectorSync.Request(player);
  }

  // Applies the rule now. Returns the number of selectors added plus removed.
  public static func Run(player: ref<PlayerPuppet>) -> Int32 {
    if !IsDefined(player) {
      return 0;
    }
    let game: GameInstance = player.GetGame();
    let system: ref<SelectorSyncSystem> = SelectorSyncSystem.Get(game);
    let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(game);
    let loose: array<wref<gameItemData>>;
    ts.GetItemListByTag(player, n"AO_AmmoSelector", loose);
    // Selectors given by the sync don't show in the activity log, coming or going.
    let quiet: array<CName>;
    ArrayPush(quiet, n"SkipActivityLog");
    ArrayPush(quiet, n"SkipActivityLogOnRemove");
    let changes: Int32 = 0;
    for caliber in AOData.Calibers() {
      for selector in AOData.Selectors(caliber) {
        let ammo: TweakDBID = AOData.SelectorAmmo(caliber, selector);
        let want: Int32 = 0;
        if TDBID.IsValid(ammo) && ts.GetItemQuantity(player, ItemID.CreateQuery(ammo)) > 0 {
          want = 1;
        }
        let kept: Int32 = 0;
        for item in loose {
          if IsDefined(item) && ItemID.GetTDBID(item.GetID()) == selector {
            let quantity: Int32 = item.GetQuantity();
            let allowed: Int32 = Max(want - kept, 0);
            if quantity > allowed {
              ts.RemoveItem(player, item.GetID(), quantity - allowed);
              changes += quantity - allowed;
            }
            kept += Min(quantity, allowed);
          }
        }
        if kept < want {
          ts.GiveItem(player, ItemID.FromTDBID(selector), want - kept, quiet);
          changes += want - kept;
        }
      }
    }
    if IsDefined(system) {
      system.count += 1;
      if changes > 0 {
        AmmoFeedSystem.Log("selector sync: " + IntToString(changes) + " change(s)");
        SelectorSync.RefreshModScreen(system);
      }
    }
    return changes;
  }

  // Called by the next-frame callback. A run of changing syncs that never settles (selectors that
  // keep failing to appear) stops after a few and ignores item events until another trigger
  // (a fit, the mod screen, a load) requests a sync.
  public static func RunPending(player: ref<PlayerPuppet>) -> Void {
    let system: ref<SelectorSyncSystem> = SelectorSyncSystem.Get(player.GetGame());
    if !IsDefined(system) {
      return;
    }
    system.pending = false;
    if system.streak >= 5 {
      AmmoFeedSystem.Log("selector sync: not settling, paused");
      system.streak = 0;
      system.paused = true;
      return;
    }
    if SelectorSync.Run(player) > 0 {
      system.streak += 1;
    } else {
      system.streak = 0;
    }
  }

  // An item event on V: syncs when an ammo stack (vanilla or the mod's) goes from 0 or to 0, and
  // for any selector. `before` and `after` are the stack's quantities around the event.
  public static func OnItemEvent(player: ref<PlayerPuppet>, itemID: ItemID, before: Int32, after: Int32) -> Void {
    let record: ref<Item_Record> = TweakDBInterface.GetItemRecord(ItemID.GetTDBID(itemID));
    if !IsDefined(record) {
      return;
    }
    let selector: Bool = record.TagsContains(n"AO_AmmoSelector");
    let ammo: Bool = record.TagsContains(n"Ammo") || Equals(record.ItemType().Type(), gamedataItemType.Con_Ammo);
    if !selector && !(ammo && (before <= 0 || after <= 0)) {
      return;
    }
    let system: ref<SelectorSyncSystem> = SelectorSyncSystem.Get(player.GetGame());
    if IsDefined(system) && system.paused {
      return;
    }
    SelectorSync.Request(player);
  }

  // An open mod screen shows the selectors it read when it was built; rebuild its lists.
  private static func RefreshModScreen(system: ref<SelectorSyncSystem>) -> Void {
    let screen: ref<InventoryItemModeLogicController> = system.modScreen;
    if IsDefined(screen) {
      screen.AORefreshAfterSync();
    }
  }
}

public class SelectorSyncCallback extends DelayCallback {
  public let player: wref<PlayerPuppet>;

  public func Call() -> Void {
    if IsDefined(this.player) {
      SelectorSync.RunPending(this.player);
    }
  }
}

// The sync's state; not saved (a load re-syncs on attach).
public class SelectorSyncSystem extends ScriptableSystem {
  public let pending: Bool;
  // Syncs run since the player attached (DebugSyncCount).
  public let count: Int32;
  // Consecutive syncs that changed something.
  public let streak: Int32;
  public let paused: Bool;
  // The inventory's item mode (the mod screen), while the inventory menu exists.
  public let modScreen: wref<InventoryItemModeLogicController>;

  public static func Get(game: GameInstance) -> ref<SelectorSyncSystem> {
    return GameInstance.GetScriptableSystemsContainer(game).Get(n"AmmoOverhaul.SelectorSyncSystem") as SelectorSyncSystem;
  }

  // --- Debug entry points (calibers/sync.lua) ------------------------------------------------

  // The open mod screen's selector choices (AODebugChoices), or "" if no mod screen is up.
  public final func DebugModScreen() -> String {
    let screen: ref<InventoryItemModeLogicController> = this.modScreen;
    return IsDefined(screen) ? screen.AODebugChoices() : "";
  }

  // Opens the inventory straight into the mod screen of the gun in weapon slot `slotIndex` (as
  // the ripperdoc's "mods" button does; CET can't fill the display data struct itself).
  public final func DebugOpenModScreen(gun: ItemID, slotIndex: Int32) -> Void {
    let data: InventoryItemDisplayData;
    data.m_itemID = gun;
    data.m_equipmentArea = gamedataEquipmentArea.Weapon;
    data.m_slotIndex = slotIndex;
    let wrapper: ref<CyberwareDisplayWrapper> = new CyberwareDisplayWrapper();
    wrapper.displayData = data;
    let evt: ref<StartHubMenuEvent> = new StartHubMenuEvent();
    evt.SetStartMenu(n"inventory_screen", n"", wrapper);
    GameInstance.GetUISystem(GetGameInstance()).QueueEvent(evt);
  }

  // "<selected ammo> <rounds held> <fitted feed part or none>" for one of V's guns.
  public final func DebugGunAmmo(gun: ItemID) -> String {
    let player: ref<GameObject> = GetPlayer(GetGameInstance());
    let caliber: String = AOData.CaliberForWeapon(ItemID.GetTDBID(gun));
    let ammo: TweakDBID = AOData.SelectedAmmo(player, gun, caliber);
    let part: String = "none";
    let itemData: wref<gameItemData> = GameInstance.GetTransactionSystem(player.GetGame()).GetItemData(player, gun);
    let slot: TweakDBID = AOData.FeedSlot(caliber);
    if IsDefined(itemData) && itemData.HasPartInSlot(slot) {
      let inner: InnerItemData;
      itemData.GetItemPart(inner, slot);
      part = TDBID.ToStringDEBUG(ItemID.GetTDBID(InnerItemData.GetItemID(inner)));
    }
    return TDBID.ToStringDEBUG(ammo) + " " + IntToString(AOData.SelectedAmmoCount(gun)) + " " + part;
  }
}

// --- Triggers --------------------------------------------------------------------------------

@wrapMethod(PlayerPuppet)
protected cb func OnItemAddedToInventory(evt: ref<ItemAddedEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  SelectorSync.OnItemEvent(this, evt.itemID, 0, evt.currentQuantity);
  return result;
}

@wrapMethod(PlayerPuppet)
protected cb func OnItemChangedEvent(evt: ref<ItemChangedEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  SelectorSync.OnItemEvent(this, evt.itemID, evt.currentQuantity - evt.difference, evt.currentQuantity);
  return result;
}

@wrapMethod(PlayerPuppet)
protected cb func OnItemBeingRemovedFromInventory(evt: ref<ItemBeingRemovedEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  SelectorSync.OnItemEvent(this, evt.itemID, 0, 0);
  return result;
}

// A fit takes the loose selector, a removal or swap returns one.
@wrapMethod(ItemModificationSystem)
private final func InstallItemPart(obj: ref<GameObject>, itemID: ItemID, partItemID: ItemID, opt slotID: TweakDBID) -> Bool {
  let result: Bool = wrappedMethod(obj, itemID, partItemID, slotID);
  let player: ref<PlayerPuppet> = obj as PlayerPuppet;
  if IsDefined(player) && TweakDBInterface.GetItemRecord(ItemID.GetTDBID(partItemID)).TagsContains(n"AO_AmmoSelector") {
    SelectorSync.Request(player);
  }
  return result;
}

@wrapMethod(ItemModificationSystem)
private final const func RemoveItemPart(obj: ref<GameObject>, itemID: ItemID, slotID: TweakDBID, shouldUpdateEntity: Bool) -> ItemID {
  let result: ItemID = wrappedMethod(obj, itemID, slotID, shouldUpdateEntity);
  let player: ref<PlayerPuppet> = obj as PlayerPuppet;
  if IsDefined(player) && AOData.IsFeedSlot(slotID) {
    SelectorSync.Request(player);
  }
  return result;
}

// The inventory menu hands its item mode its data once per opening; the mod screen for one item
// is set up on every open.
@wrapMethod(InventoryItemModeLogicController)
public final func SetupData(buttonHints: wref<ButtonHints>, tooltipsManager: wref<gameuiTooltipsManager>, inventoryManager: ref<InventoryDataManagerV2>, player: wref<PlayerPuppet>) -> Void {
  wrappedMethod(buttonHints, tooltipsManager, inventoryManager, player);
  if !IsDefined(player) {
    return;
  }
  let system: ref<SelectorSyncSystem> = SelectorSyncSystem.Get(player.GetGame());
  if IsDefined(system) {
    system.modScreen = this;
  }
}

@wrapMethod(InventoryItemModeLogicController)
public final func SetupMode(displayData: InventoryItemDisplayData, leftDisplayData: InventoryItemDisplayData, dataSource: ref<InventoryDataManagerV2>, opt inventoryController: wref<gameuiInventoryGameController>, opt selectLeftItemChooser: Bool) -> Void {
  wrappedMethod(displayData, leftDisplayData, dataSource, inventoryController, selectLeftItemChooser);
  if !IsDefined(this.m_player) {
    return;
  }
  let system: ref<SelectorSyncSystem> = SelectorSyncSystem.Get(this.m_player.GetGame());
  if IsDefined(system) {
    system.modScreen = this;
  }
  SelectorSync.Request(this.m_player);
}

// Vanilla refreshes the part list when a part is removed or its quantity changes, but not when a
// new one arrives; rebuild the cached lists and the grid as vanilla's own refresh does.
@addMethod(InventoryItemModeLogicController)
public func AORefreshAfterSync() -> Void {
  if !IsDefined(this.m_InventoryManager) || !IsDefined(this.m_selectedItemChooser) {
    return;
  }
  this.m_InventoryManager.MarkToRebuild();
  this.RefreshAvailableItems(true);
}

// "item <gun> | grid <selectors in the item grid> | parts <feed slot choices>" for the open mod
// screen, "" if none.
@addMethod(InventoryItemModeLogicController)
public func AODebugChoices() -> String {
  if !IsDefined(this.m_selectedItemChooser) || !IsDefined(this.m_InventoryManager) {
    return "";
  }
  let gun: ItemID = this.m_selectedItemChooser.GetModifiedItemID();
  let text: String = "item " + TDBID.ToStringDEBUG(ItemID.GetTDBID(gun)) + " | grid";
  for wrapped in this.m_currentItems {
    if IsDefined(wrapped) {
      let id: TweakDBID = ItemID.GetTDBID(InventoryItemData.GetID(wrapped.ItemData));
      if TweakDBInterface.GetItemRecord(id).TagsContains(n"AO_AmmoSelector") {
        text += " " + TDBID.ToStringDEBUG(id);
      }
    }
  }
  text += " | parts";
  let caliber: String = AOData.CaliberForWeapon(ItemID.GetTDBID(gun));
  if StrLen(caliber) > 0 {
    let slots: array<TweakDBID>;
    ArrayPush(slots, AOData.FeedSlot(caliber));
    let parts: array<InventoryItemData>;
    this.m_InventoryManager.GetPlayerInventoryPartsForItemRef(gun, slots, this.m_itemDropQueue, parts);
    for part in parts {
      text += " " + TDBID.ToStringDEBUG(ItemID.GetTDBID(InventoryItemData.GetID(part)));
    }
  }
  return text;
}

module AmmoOverhaul

// World loot: when a loot container fills, each stack of vanilla ammo that calibers replace
// becomes one round picked for it (AmmoDistribution.Pick, up to Uncommon), same quantity. Each
// container converts once: 9mm Ball is vanilla handgun ammo, so converted containers are kept on
// AmmoFeedSystem (saved) rather than told apart by their contents.

public abstract class LootConvert {

  // Converts every replaced vanilla ammo stack in `container`; returns the stacks converted.
  public static func Convert(container: ref<GameObject>) -> Int32 {
    if !IsDefined(container) {
      return 0;
    }
    let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(container.GetGame());
    let items: array<wref<gameItemData>>;
    ts.GetItemList(container, items);
    let owned: array<String> = AmmoDistribution.OwnedCalibers(GetPlayer(container.GetGame()));
    let ids: array<ItemID>;
    let quantities: array<Int32>;
    for item in items {
      let calibers: array<String> = AmmoDistribution.Calibers(ItemID.GetTDBID(item.GetID()));
      if ArraySize(calibers) > 0 && item.GetQuantity() > 0 {
        ArrayPush(ids, item.GetID());
        ArrayPush(quantities, item.GetQuantity());
      }
    }
    let i: Int32 = 0;
    while i < ArraySize(ids) {
      let vanilla: TweakDBID = ItemID.GetTDBID(ids[i]);
      let target: TweakDBID = AmmoDistribution.Pick(vanilla, 1, owned);
      if target != vanilla {
        ts.RemoveItem(container, ids[i], quantities[i]);
        ts.GiveItem(container, ItemID.FromTDBID(target), quantities[i]);
      }
      i += 1;
    }
    return ArraySize(ids);
  }

  // Convert, unless this container was converted before; marks it.
  public static func ConvertOnce(container: ref<GameObject>) -> Int32 {
    let system: ref<AmmoFeedSystem> = AmmoFeedSystem.Get(container.GetGame());
    if !IsDefined(system) || !system.MarkConverted(container.GetEntityID()) {
      return 0;
    }
    let stacks: Int32 = LootConvert.Convert(container);
    if stacks > 0 {
      AmmoFeedSystem.Log("loot: converted " + IntToString(stacks) + " ammo stacks in " + EntityID.ToDebugString(container.GetEntityID()));
    }
    return stacks;
  }
}

@wrapMethod(gameLootContainerBase)
protected cb func OnInventoryFilledEvent(evt: ref<ContainerFilledEvent>) -> Bool {
  let result: Bool = wrappedMethod(evt);
  LootConvert.ConvertOnce(this);
  return result;
}

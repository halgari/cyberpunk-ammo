module AmmoOverhaul

// Vendor ammo: each stack of vanilla ammo a caliber replaces is split into that ammo's calibers
// and tiers (AmmoDistribution.Spread) whenever the vendor builds its stock. Gun shops sell up to
// Uncommon, everyone else Common only. A restock rebuilds the stock from the vendor's pool (our
// rounds are regenerating items, so the old split stacks are dropped first), so each stack is
// split once.

@wrapMethod(Vendor)
private final func InitializeStock() -> Void {
  wrappedMethod();
  this.AOSplitAmmo();
}

@wrapMethod(Vendor)
private final func RegenerateStock() -> Void {
  wrappedMethod();
  this.AOSplitAmmo();
}

// Stock saved before the mod was installed is split on load. 9mm Ball is vanilla handgun ammo,
// so a stock already split is told apart by holding any of our rounds.
@wrapMethod(Vendor)
public final func OnRestored(gameInstance: GameInstance, forceReinit: Bool) -> Void {
  wrappedMethod(gameInstance, forceReinit);
  for stack in this.m_stock {
    if TweakDBInterface.GetItemRecord(ItemID.GetTDBID(stack.itemID)).TagsContains(n"AO_Ammo") {
      return;
    }
  }
  this.AOSplitAmmo();
}

@addMethod(Vendor)
private final func AOSplitAmmo() -> Void {
  let maxTier: Int32 = Equals(this.GetVendorType(), gamedataVendorType.Gunsmith) ? 1 : 0;
  let stock: array<SItemStack>;
  let split: Int32 = 0;
  for stack in this.m_stock {
    let vanilla: TweakDBID = ItemID.GetTDBID(stack.itemID);
    let calibers: array<String> = AmmoDistribution.Calibers(vanilla);
    if ArraySize(calibers) == 0 {
      ArrayPush(stock, stack);
    } else {
      for part in AmmoDistribution.Spread(vanilla, stack.quantity, maxTier) {
        let copy: SItemStack = stack;
        copy.itemID = ItemID.FromTDBID(part.ammo);
        copy.quantity = part.quantity;
        ArrayPush(stock, copy);
      }
      split += 1;
    }
  }
  if split > 0 {
    this.m_stock = stock;
    AmmoFeedSystem.Log("vendor " + TDBID.ToStringDEBUG(this.GetVendorTweakID()) + ": split " + IntToString(split) + " ammo stacks (max tier " + IntToString(maxTier) + ")");
  }
}

// --- Debug (AmmoFeedSystem.DebugVendors / DebugRestock) ---------------------------------------

// "item=quantity;..." of the ammo in the vendor's stock.
@addMethod(Vendor)
public final func AODebugAmmo() -> String {
  let text: String = "";
  for stack in this.GetStock() {
    if TweakDBInterface.GetItemRecord(ItemID.GetTDBID(stack.itemID)).TagsContains(n"Ammo") {
      text += TDBID.ToStringDEBUG(ItemID.GetTDBID(stack.itemID)) + "=" + IntToString(stack.quantity) + ";";
    }
  }
  return text;
}

@addMethod(Vendor)
public final func AODebugRestock() -> Void {
  this.RegenerateStock();
}

// Vendors the market knows of in this save (visited or attached nearby).
@addMethod(MarketSystem)
public final func AODebugVendors() -> array<ref<Vendor>> {
  return this.m_vendors;
}

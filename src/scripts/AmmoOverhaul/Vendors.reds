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

// Stock built before the mod was installed is split the first time the vendor fills its
// inventory (opening its screen). Vendors whose stock has been split are kept on AmmoFeedSystem
// (saved): 9mm Ball is vanilla handgun ammo, so a stock bought down to Ball can't be told apart
// from an unsplit one by its contents.
@wrapMethod(Vendor)
private final func FillVendorInventory(allowRegeneration: Bool) -> Void {
  this.AOBeforeFill();
  wrappedMethod(allowRegeneration);
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
  AmmoFeedSystem.Get(this.m_gameInstance).MarkVendorSplit(this.GetVendorTweakID());
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

// Takes our rounds out of the stock, as if the player had bought them all (9mm Ball stays).
@addMethod(Vendor)
public final func AODebugBuyOutRounds() -> Void {
  let stock: array<SItemStack>;
  for stack in this.m_stock {
    if !TweakDBInterface.GetItemRecord(ItemID.GetTDBID(stack.itemID)).TagsContains(n"AO_Ammo") {
      ArrayPush(stock, stack);
    }
  }
  this.m_stock = stock;
}

// Splits a stock that was never split (built before the mod was installed). One that already
// holds our rounds (saved before vendors were tracked) is only marked.
@addMethod(Vendor)
public final func AOBeforeFill() -> Void {
  let system: ref<AmmoFeedSystem> = AmmoFeedSystem.Get(this.m_gameInstance);
  if ArraySize(this.m_stock) == 0 || system.IsVendorSplit(this.GetVendorTweakID()) {
    return;
  }
  for stack in this.m_stock {
    if TweakDBInterface.GetItemRecord(ItemID.GetTDBID(stack.itemID)).TagsContains(n"AO_Ammo") {
      system.MarkVendorSplit(this.GetVendorTweakID());
      return;
    }
  }
  this.AOSplitAmmo();
}

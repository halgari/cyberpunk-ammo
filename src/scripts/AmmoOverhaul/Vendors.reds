module AmmoOverhaul

// Vendor ammo: the vanilla ammo stacks a caliber replaces are swapped, whenever the vendor builds
// its stock, for shipments (AmmoDistribution.Shipments): every covered caliber's Common round in a
// big stack, and at gun shops a few Uncommon and Rare rounds in smaller ones. Other vendors sell
// Common only. Shops on a faction's turf add that faction's rounds (FactionRounds.TurfStock). A
// restock rebuilds the stock from the vendor's pool (our rounds are regenerating items, so the old
// shipments are dropped first), so each pool is swapped once.

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
  // Gun shops sell up to Rare; other vendors Common only. The one Epic on sale is a turf exception.
  let maxTier: Int32 = Equals(this.GetVendorType(), gamedataVendorType.Gunsmith) ? 2 : 0;
  let stock: array<SItemStack>;
  let calibers: array<String>;
  let split: Int32 = 0;
  let template: SItemStack;
  for stack in this.m_stock {
    let found: array<String> = AmmoDistribution.Calibers(ItemID.GetTDBID(stack.itemID));
    if ArraySize(found) == 0 {
      ArrayPush(stock, stack);
    } else {
      template = stack;
      for caliber in found {
        if !ArrayContains(calibers, caliber) {
          ArrayPush(calibers, caliber);
        }
      }
      split += 1;
    }
  }
  for part in AmmoDistribution.Shipments(calibers, maxTier) {
    let copy: SItemStack = template;
    copy.itemID = ItemID.FromTDBID(part.ammo);
    copy.quantity = part.quantity;
    ArrayPush(stock, copy);
  }
  // A netrunner vendor may hold no ammo to split, so these count as a change of their own.
  let hacks: array<AOStack> = HackRounds.ShopStock(this.GetVendorTweakID(), maxTier > 0);
  for part in hacks {
    let copy: SItemStack = template;
    copy.itemID = ItemID.FromTDBID(part.ammo);
    copy.quantity = part.quantity;
    ArrayPush(stock, copy);
  }
  AmmoFeedSystem.Get(this.m_gameInstance).MarkVendorSplit(this.GetVendorTweakID());
  // Gun shops also list some Uncommon and Rare recipes, as stacks like the ammo they sell.
  if split > 0 && maxTier > 0 {
    for recipe in AmmoDistribution.VendorRecipes(maxTier) {
      let copy: SItemStack = template;
      copy.itemID = ItemID.FromTDBID(recipe);
      copy.quantity = 1;
      ArrayPush(stock, copy);
    }
    let faction: String = TweakDBInterface.GetString(AOData.Flat(this.GetVendorTweakID(), "aoFaction"), "");
    if StrLen(faction) > 0 {
      for part in FactionRounds.TurfStock(this.GetVendorTweakID(), faction) {
        let copy: SItemStack = template;
        copy.itemID = ItemID.FromTDBID(part.ammo);
        copy.quantity = part.quantity;
        ArrayPush(stock, copy);
      }
    }
  }
  if split > 0 || ArraySize(hacks) > 0 {
    this.m_stock = stock;
    AmmoFeedSystem.Log("vendor " + TDBID.ToStringDEBUG(this.GetVendorTweakID()) + ": split " + IntToString(split) + " ammo stacks (max tier " + IntToString(maxTier) + ")");
  }
}

// --- Debug (AmmoFeedSystem.DebugVendors / DebugRestock) ---------------------------------------

// The faction rounds in the stock, "item=quantity;...".
@addMethod(Vendor)
public final func AODebugFactionAmmo() -> String {
  let text: String = "";
  for stack in this.GetStock() {
    let id: TweakDBID = ItemID.GetTDBID(stack.itemID);
    if StrLen(TweakDBInterface.GetString(AOData.Flat(id, "aoFaction"), "")) > 0 {
      text += TDBID.ToStringDEBUG(id) + "=" + IntToString(stack.quantity) + ";";
    }
  }
  return text;
}

// The hack rounds in the stock, "item=quantity;...", with a "!" on any the buy screen would skip.
@addMethod(Vendor)
public final func AODebugHackAmmo() -> String {
  let text: String = "";
  for stack in this.GetStock() {
    let id: TweakDBID = ItemID.GetTDBID(stack.itemID);
    if StrLen(TweakDBInterface.GetString(AOData.Flat(id, "aoHackProgram"), "")) > 0 {
      text += TDBID.ToStringDEBUG(id) + "=" + IntToString(stack.quantity) + (stack.isAvailable ? ";" : "!;");
    }
  }
  return text;
}

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

// --- Debug: the vendor sell list ---------------------------------------------------------------

// A data manager for a vendor record, without a vendor object (the sell list needs only the record).
@addMethod(VendorDataManager)
public final func AODebugForVendor(vendorID: String) -> Void {
  this.m_VendorID = TDBID.Create(vendorID);
}

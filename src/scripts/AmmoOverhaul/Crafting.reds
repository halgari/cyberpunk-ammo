module AmmoOverhaul

// Crafting and disassembly of rounds (records from tools/crafting/crafting.py). Vanilla only knows
// its 4 ammo items: their batch size (GetAmmoBulletAmount), their recipes (AddAmmoRecipes), and
// every ammo item breaks down into 1 Common component per round. Here:
//   - each round's batch is its recipe record's (<ammo>.aoRecipe);
//   - every caliber's Common round is known from the start; Uncommon and up are learned by picking
//     up their recipe item (vanilla's CraftingSystemInventoryCallback);
//   - rounds break down per full batch (<ammo>.aoScrapRounds) into aoScrapGive components of the
//     round's own quality; leftover rounds give nothing;
//   - feed selectors can't be broken down (that would drop a gun's ammo choice).

@wrapMethod(CraftingSystem)
public final static func GetAmmoBulletAmount(ammoId: TweakDBID) -> Int32 {
  let recipe: TweakDBID = AOData.Recipe(ammoId);
  if TDBID.IsValid(recipe) && !AOData.IsVanillaAmmo(ammoId) {
    let record: ref<ItemRecipe_Record> = TweakDBInterface.GetItemRecipeRecord(recipe);
    if IsDefined(record) && IsDefined(record.CraftingResult()) {
      return record.CraftingResult().Amount();
    }
  }
  return wrappedMethod(ammoId);
}

@wrapMethod(CraftingSystem)
private final func AddAmmoRecipes() -> Void {
  wrappedMethod();
  for caliber in AOData.Calibers() {
    for ammo in AOData.AmmosForTier(caliber, 0) {
      if !AOData.IsVanillaAmmo(ammo) && !this.m_playerCraftBook.KnowsRecipe(ammo) {
        this.m_playerCraftBook.AddRecipe(ammo, [], CraftingSystem.GetAmmoBulletAmount(ammo));
      }
    }
  }
}

@wrapMethod(CraftingSystem)
public final const func GetDisassemblyResultItems(target: wref<GameObject>, itemID: ItemID, amount: Int32, restoredAttachments: script_ref<[ItemAttachments]>, opt calledFromUI: Bool) -> [IngredientData] {
  let ammo: TweakDBID = ItemID.GetTDBID(itemID);
  let rounds: Int32 = AOData.ScrapRounds(ammo);
  if rounds <= 0 {
    return wrappedMethod(target, itemID, amount, restoredAttachments, calledFromUI);
  }
  let result: array<IngredientData>;
  let give: Int32 = (amount / rounds) * AOData.ScrapGive(ammo);
  if give > 0 {
    let quality: gamedataQuality = TweakDBInterface.GetItemRecord(ammo).Quality().Type();
    ArrayPush(result, this.CreateIngredientData(RPGManager.GetCraftingMaterialRecord(quality), give));
  }
  return result;
}

@wrapMethod(CraftingSystem)
public final const func CanItemBeDisassembled(itemData: wref<gameItemData>) -> Bool {
  if IsDefined(itemData) && itemData.HasTag(n"AO_AmmoSelector") {
    return false;
  }
  return wrappedMethod(itemData);
}

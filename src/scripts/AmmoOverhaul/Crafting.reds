module AmmoOverhaul

// Crafting and disassembly of rounds (records from tools/crafting/crafting.py). Vanilla only knows
// its 4 ammo items: their batch size (GetAmmoBulletAmount), their recipes (AddAmmoRecipes), and
// every ammo item breaks down into 1 Common component per round. Here:
//   - each round's batch is its recipe record's (<ammo>.aoRecipe);
//   - every caliber's Common round and every quickhack round is known from the start (added on
//     player attach); Uncommon and up are learned by picking up their recipe item (vanilla's
//     CraftingSystemInventoryCallback);
//   - a quickhack round costs one program a batch, which vanilla's crafting needs help with;
//   - rounds break down per full batch (<ammo>.aoScrapRounds) into aoScrapGive components of the
//     round's own quality; leftover rounds stay in the stack;
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

// Vanilla adds its ammo recipes once per save (behind facts), so ours are added whenever the
// player attaches: new games, and saves from before the mod or a new caliber.
@wrapMethod(CraftingSystem)
private final func OnPlayerAttach(request: ref<PlayerAttachRequest>) -> Void {
  wrappedMethod(request);
  this.AOAddCommonRecipes();
}

@addMethod(CraftingSystem)
private final func AOAddCommonRecipes() -> Void {
  if !IsDefined(this.m_playerCraftBook) {
    return;
  }
  for caliber in AOData.Calibers() {
    for tier in [0, 10, 11, 12, 13] {
      for ammo in AOData.AmmosForTier(caliber, tier) {
        if !AOData.IsVanillaAmmo(ammo) && !this.m_playerCraftBook.KnowsRecipe(ammo) {
          this.m_playerCraftBook.AddRecipe(ammo, [], CraftingSystem.GetAmmoBulletAmount(ammo));
        }
      }
    }
  }
}

// Vanilla takes a program twice, once as an ingredient and again as a program, up to what V holds.
// A round costs one a batch, so the rest goes back. Installed hacks are deck parts and aren't touched.
@wrapMethod(CraftingSystem)
private final func CraftItem(target: wref<GameObject>, itemRecord: ref<Item_Record>, amount: Int32, opt ammoBulletAmount: Int32) -> wref<gameItemData> {
  let program: String = TweakDBInterface.GetString(AOData.Flat(itemRecord.GetID(), "aoHackProgram"), "");
  if StrLen(program) == 0 {
    return wrappedMethod(target, itemRecord, amount, ammoBulletAmount);
  }
  let transactions: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.GetGameInstance());
  let query: ItemID = ItemID.CreateQuery(TDBID.Create(program));
  let before: Int32 = transactions.GetItemQuantityWithDuplicates(target, query);
  let crafted: wref<gameItemData> = wrappedMethod(target, itemRecord, amount, ammoBulletAmount);
  let extra: Int32 = before - transactions.GetItemQuantityWithDuplicates(target, query) - amount;
  // One at a time: given 2 at once, only 1 arrived.
  while extra > 0 {
    transactions.GiveItem(target, ItemID.FromTDBID(TDBID.Create(program)), 1);
    extra -= 1;
  }
  return crafted;
}

// Vanilla's maximum is 0 when V holds exactly one batch's cost, and at 0 the screen refuses to craft
// ammo. For these rounds that's the usual case: one hack held.
@wrapMethod(CraftingSystem)
public final const func GetMaxCraftingAmount(itemData: wref<gameItemData>) -> Int32 {
  let result: Int32 = wrappedMethod(itemData);
  let ammo: TweakDBID = ItemID.GetTDBID(itemData.GetID());
  if result > 0 || StrLen(TweakDBInterface.GetString(AOData.Flat(ammo, "aoHackProgram"), "")) == 0 {
    return result;
  }
  let owner: wref<GameObject> = this.m_playerCraftBook.GetOwner();
  let transactions: ref<TransactionSystem> = GameInstance.GetTransactionSystem(this.GetGameInstance());
  let held: Int32 = transactions.GetItemQuantity(owner, itemData.GetID());
  let room: Int32 = (Cast<Int32>(itemData.GetStatValueByType(gamedataStatType.Quantity)) - held) / CraftingSystem.GetAmmoBulletAmount(ammo);
  for ingredient in this.GetItemCraftingCost(itemData) {
    let query: ItemID = ItemID.CreateQuery(ingredient.id.GetID());
    room = Min(room, transactions.GetItemQuantityWithDuplicates(owner, query) / ingredient.quantity);
  }
  return Max(room, 0);
}

@wrapMethod(CraftingSystem)
public final const func GetDisassemblyResultItems(target: wref<GameObject>, itemID: ItemID, amount: Int32, restoredAttachments: script_ref<[ItemAttachments]>, opt calledFromUI: Bool) -> [IngredientData] {
  let ammo: TweakDBID = ItemID.GetTDBID(itemID);
  let rounds: Int32 = AOData.ScrapRounds(ammo);
  if rounds <= 0 {
    return wrappedMethod(target, itemID, amount, restoredAttachments, calledFromUI);
  }
  let result: array<IngredientData>;
  // The backpack's hover preview asks for one item: show what one batch gives.
  let batches: Int32 = calledFromUI && amount == 1 ? 1 : amount / rounds;
  let give: Int32 = batches * AOData.ScrapGive(ammo);
  if give > 0 {
    let quality: gamedataQuality = TweakDBInterface.GetItemRecord(ammo).Quality().Type();
    ArrayPush(result, this.CreateIngredientData(RPGManager.GetCraftingMaterialRecord(quality), give));
  }
  return result;
}

// Only full batches are broken down: the rounds left over stay in the stack (the quantity picker
// lets the player pick any count).
@wrapMethod(CraftingSystem)
private final const func DisassembleItem(target: wref<GameObject>, itemID: ItemID, amount: Int32) -> Void {
  let rounds: Int32 = AOData.ScrapRounds(ItemID.GetTDBID(itemID));
  if rounds <= 0 {
    wrappedMethod(target, itemID, amount);
    return;
  }
  let whole: Int32 = (amount / rounds) * rounds;
  if whole > 0 {
    wrappedMethod(target, itemID, whole);
  }
}

@wrapMethod(CraftingSystem)
public final const func CanItemBeDisassembled(itemData: wref<gameItemData>) -> Bool {
  if IsDefined(itemData) && itemData.HasTag(n"AO_AmmoSelector") {
    return false;
  }
  return wrappedMethod(itemData);
}

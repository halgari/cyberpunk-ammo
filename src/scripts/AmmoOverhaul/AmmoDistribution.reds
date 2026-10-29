module AmmoOverhaul

// How vanilla ammo is shared out among the calibers and tiers that replace it, for vendor stock
// (Vendors.reds) and world loot (LootConvert.reds). A caliber's share of its vanilla ammo is its
// lootWeight; within a caliber each tier gets its family's share (AmmoOverhaul.shares.*), counting
// only the tiers allowed (up to maxTier).

public struct AOStack {
  let ammo: TweakDBID;
  let quantity: Int32;
}

public abstract class AmmoDistribution {

  // Calibers whose vanillaAmmo is `vanilla`.
  public static func Calibers(vanilla: TweakDBID) -> array<String> {
    let found: array<String>;
    for caliber in AOData.Calibers() {
      if AOData.VanillaAmmo(caliber) == vanilla {
        ArrayPush(found, caliber);
      }
    }
    return found;
  }

  // Calibers of every weapon the player carries.
  public static func OwnedCalibers(player: ref<PlayerPuppet>) -> array<String> {
    let owned: array<String>;
    let items: array<wref<gameItemData>>;
    if !IsDefined(player) {
      return owned;
    }
    GameInstance.GetTransactionSystem(player.GetGame()).GetItemListByTag(player, n"Weapon", items);
    for item in items {
      let caliber: String = AOData.CaliberForWeapon(ItemID.GetTDBID(item.GetID()));
      if NotEquals(caliber, "") && !ArrayContains(owned, caliber) {
        ArrayPush(owned, caliber);
      }
    }
    return owned;
  }

  // One ammo item to give in place of `vanilla`: with chance OwnedBias a caliber the player owns
  // (if any of `vanilla`'s), else one picked by lootWeight; then a tier by its share.
  public static func Pick(vanilla: TweakDBID, maxTier: Int32, owned: array<String>) -> TweakDBID {
    let calibers: array<String> = AmmoDistribution.Calibers(vanilla);
    if ArraySize(calibers) == 0 {
      return vanilla;
    }
    let mine: array<String>;
    for caliber in calibers {
      if ArrayContains(owned, caliber) {
        ArrayPush(mine, caliber);
      }
    }
    let caliber: String;
    if ArraySize(mine) > 0 && RandF() < AOData.OwnedBias() {
      caliber = mine[RandRange(0, ArraySize(mine))];
    } else {
      let weights: array<Float>;
      for c in calibers {
        ArrayPush(weights, AOData.LootWeight(c));
      }
      caliber = calibers[AmmoDistribution.Weighted(weights)];
    }
    let tiers: array<Float> = AmmoDistribution.TierWeights(caliber, maxTier);
    // A tier's rounds share its weight evenly.
    let tierAmmo: array<TweakDBID> = AOData.AmmosForTier(caliber, AmmoDistribution.Weighted(tiers));
    return ArraySize(tierAmmo) > 0 ? tierAmmo[RandRange(0, ArraySize(tierAmmo))] : vanilla;
  }

  // `quantity` of `vanilla` split by lootWeight × tier share: rounded down, the remainder to the
  // largest share, empty stacks left out. Ammo no caliber replaces comes back as one stack.
  public static func Spread(vanilla: TweakDBID, quantity: Int32, maxTier: Int32) -> array<AOStack> {
    let items: array<TweakDBID>;
    let weights: array<Float>;
    let total: Float = 0.0;
    for caliber in AmmoDistribution.Calibers(vanilla) {
      let tiers: array<Float> = AmmoDistribution.TierWeights(caliber, maxTier);
      let t: Int32 = 0;
      while t < ArraySize(tiers) {
        let tierAmmo: array<TweakDBID> = AOData.AmmosForTier(caliber, t);
        let weight: Float = AOData.LootWeight(caliber) * tiers[t];
        if ArraySize(tierAmmo) > 0 && weight > 0.0 {
          // A tier's rounds share its weight evenly.
          for ammo in tierAmmo {
            ArrayPush(items, ammo);
            ArrayPush(weights, weight / Cast<Float>(ArraySize(tierAmmo)));
          }
          total += weight;
        }
        t += 1;
      }
    }
    let stacks: array<AOStack>;
    if total <= 0.0 || quantity <= 0 {
      if quantity > 0 {
        ArrayPush(stacks, AOStack(vanilla, quantity));
      }
      return stacks;
    }
    // Largest remainder: each stack gets its share rounded down, then the rounds left over go one
    // each to the stacks that lost the most to rounding.
    let counts: array<Int32>;
    let rest: array<Float>;
    let given: Int32 = 0;
    let i: Int32 = 0;
    while i < ArraySize(items) {
      let exact: Float = Cast<Float>(quantity) * weights[i] / total;
      let count: Int32 = FloorF(exact);
      ArrayPush(counts, count);
      ArrayPush(rest, exact - Cast<Float>(count));
      given += count;
      i += 1;
    }
    while given < quantity {
      let best: Int32 = 0;
      i = 1;
      while i < ArraySize(rest) {
        if rest[i] > rest[best] {
          best = i;
        }
        i += 1;
      }
      counts[best] += 1;
      rest[best] = -1.0;
      given += 1;
    }
    i = 0;
    while i < ArraySize(items) {
      if counts[i] > 0 {
        ArrayPush(stacks, AOStack(items[i], counts[i]));
      }
      i += 1;
    }
    return stacks;
  }

  // The recipe item to hand out with a dropped `ammo`: with chance recipeDropFactor for an Uncommon+
  // round, else an invalid ID.
  public static func RecipeRoll(ammo: TweakDBID) -> TweakDBID {
    let recipe: TweakDBID = AOData.RecipeItem(ammo);
    if TDBID.IsValid(recipe) && RandF() < AOData.RecipeDropFactor() {
      return recipe;
    }
    return TDBID.None();
  }

  // Recipe items a vendor selling up to `maxTier` lists this restock: each Uncommon..maxTier round's
  // recipe with chance recipeVendorChance.
  public static func VendorRecipes(maxTier: Int32) -> array<TweakDBID> {
    let recipes: array<TweakDBID>;
    for caliber in AOData.Calibers() {
      let t: Int32 = 1;
      while t <= maxTier {
        for ammo in AOData.AmmosForTier(caliber, t) {
          let recipe: TweakDBID = AOData.RecipeItem(ammo);
          if TDBID.IsValid(recipe) && RandF() < AOData.RecipeVendorChance() {
            ArrayPush(recipes, recipe);
          }
        }
        t += 1;
      }
    }
    return recipes;
  }

  // The caliber's tier shares for tiers 0..maxTier that have an ammo item, scaled to sum to 1.
  private static func TierWeights(caliber: String, maxTier: Int32) -> array<Float> {
    let family: String = AOData.Family(caliber);
    let weights: array<Float>;
    let sum: Float = 0.0;
    let t: Int32 = 0;
    while t <= maxTier {
      let tierAmmo: array<TweakDBID> = AOData.AmmosForTier(caliber, t);
      let share: Float = ArraySize(tierAmmo) > 0 ? AOData.TierShare(family, t) : 0.0;
      ArrayPush(weights, share);
      sum += share;
      t += 1;
    }
    if sum <= 0.0 {
      ArrayClear(weights);
      ArrayPush(weights, 1.0);
      return weights;
    }
    let i: Int32 = 0;
    while i < ArraySize(weights) {
      weights[i] = weights[i] / sum;
      i += 1;
    }
    return weights;
  }

  // An index drawn with probability proportional to its weight (0 if all are 0).
  private static func Weighted(weights: array<Float>) -> Int32 {
    let total: Float = 0.0;
    for w in weights {
      total += w;
    }
    if total <= 0.0 {
      return 0;
    }
    let roll: Float = RandF() * total;
    let i: Int32 = 0;
    while i < ArraySize(weights) {
      roll -= weights[i];
      if roll < 0.0 {
        return i;
      }
      i += 1;
    }
    return ArraySize(weights) - 1;
  }
}

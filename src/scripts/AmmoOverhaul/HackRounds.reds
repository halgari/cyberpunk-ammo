module AmmoOverhaul

// Quickhack rounds (docs/superpowers/specs/2026-10-31-quickhack-rounds-design.md): who carries them.
// Their tier codes keep them off the general lists; what they do on a hit is the rank path in
// FactionRounds, and crafting them is tools/crafting/crafting.py.
public abstract class HackRounds {
  private static func Chance(rarity: String) -> Float {
    return TweakDBInterface.GetFloat(TDBID.Create("AmmoOverhaul.npcHackChance." + rarity), 0.0);
  }

  private static func SeniorRank(rarity: String) -> Bool {
    return Equals(rarity, "Elite") || Equals(rarity, "Boss") || Equals(rarity, "MaxTac");
  }

  // A hack round for a smart gun of `caliber`, invalid if the roll misses. Chance first: most rolls
  // miss. Legendary only on senior ranks, Epic from Officer up.
  public static func Roll(caliber: String, rarity: String) -> TweakDBID {
    if !Equals(AOData.Family(caliber), "Smart") || RandF() >= HackRounds.Chance(rarity) {
      return TDBID.None();
    }
    let selectors: array<TweakDBID>;
    if HackRounds.SeniorRank(rarity) && RandF() < TweakDBInterface.GetFloat(t"AmmoOverhaul.hackLegendaryShare", 0.1) {
      selectors = AOData.SelectorsForTier(caliber, 13);
    } else {
      let tiers: array<Int32> = [10, 11];
      if Equals(rarity, "Officer") || HackRounds.SeniorRank(rarity) {
        ArrayPush(tiers, 12);
      }
      for tier in tiers {
        for selector in AOData.SelectorsForTier(caliber, tier) {
          ArrayPush(selectors, selector);
        }
      }
    }
    return ArraySize(selectors) > 0 ? selectors[RandRange(0, ArraySize(selectors))] : TDBID.None();
  }

  // A gun shop's or netrunner vendor's stacks this stock build: gun shops to Rare, netrunner vendors
  // to Epic, past hackShopChance.
  // Sets off a Detonate Grenade round's blast at `target`. An NPC's hack round does nothing extra to
  // V, so its blast doesn't go off with V inside it (a metre over the range, for V's own width).
  public static func Blast(instigator: ref<GameObject>, target: ref<GameObject>, blast: TweakDBID) -> Void {
    let player: ref<GameObject> = GetPlayer(target.GetGame());
    if !instigator.IsPlayer() && IsDefined(player) {
      let range: Float = TweakDBInterface.GetFloat(AOData.Flat(blast, "range"), 5.0);
      if Vector4.Distance(player.GetWorldPosition(), target.GetWorldPosition()) <= range + 1.0 {
        return;
      }
    }
    AmmoFeedSystem.Log("hack blast " + TDBID.ToStringDEBUG(blast));
    FactionRounds.Blast(instigator, target, blast);
  }

  public static func ShopStock(vendor: TweakDBID, gunshop: Bool) -> array<AOStack> {
    let stacks: array<AOStack>;
    let netrunner: Bool = TweakDBInterface.GetBool(AOData.Flat(vendor, "aoHackShop"), false);
    if !gunshop && !netrunner || RandF() >= TweakDBInterface.GetFloat(t"AmmoOverhaul.hackShopChance", 0.5) {
      return stacks;
    }
    let tiers: array<Int32> = [10, 11];
    if netrunner {
      ArrayPush(tiers, 12);
    }
    let rounds: array<TweakDBID>;
    for caliber in AOData.Calibers() {
      for tier in tiers {
        for ammo in AOData.AmmosForTier(caliber, tier) {
          ArrayPush(rounds, ammo);
        }
      }
    }
    let size: Int32 = TweakDBInterface.GetInt(t"AmmoOverhaul.hackShopStack", 15);
    let count: Int32 = RandRange(1, 3);
    while count > 0 && ArraySize(rounds) > 0 {
      let pick: Int32 = RandRange(0, ArraySize(rounds));
      ArrayPush(stacks, AOStack(rounds[pick], size));
      ArrayErase(rounds, pick);
      count -= 1;
    }
    return stacks;
  }

  public static func IsNetrunner(npc: ref<NPCPuppet>) -> Bool {
    let archetype: wref<ArchetypeData_Record> = TweakDBInterface.GetCharacterRecord(npc.GetRecordID()).ArchetypeData();
    if !IsDefined(archetype) {
      return false;
    }
    let kind: gamedataArchetypeType = archetype.Type().Type();
    return Equals(kind, gamedataArchetypeType.NetrunnerT1) || Equals(kind, gamedataArchetypeType.NetrunnerT2)
      || Equals(kind, gamedataArchetypeType.NetrunnerT3);
  }

  // A netrunner's body holds a small stack of a smart caliber's hack round, whatever gun it held.
  // A netrunner's roll for its body, whatever gun it held, or none. Stocked like its own rounds, so
  // the loot note carries them past the game's wipe of the body. Called as the note is taken, which a
  // knockout and a death both do, so it rolls once.
  public static func Drop(npc: ref<NPCPuppet>) -> Void {
    if npc.aoHackDropped || !HackRounds.IsNetrunner(npc) {
      return;
    }
    npc.aoHackDropped = true;
    let calibers: array<String>;
    for caliber in AOData.Calibers() {
      if Equals(AOData.Family(caliber), "Smart") {
        ArrayPush(calibers, caliber);
      }
    }
    let caliber: String = calibers[RandRange(0, ArraySize(calibers))];
    let selector: TweakDBID = HackRounds.Roll(caliber, MuleKick.Rarity(npc));
    if TDBID.IsValid(selector) {
      let ammo: TweakDBID = AOData.SelectorAmmo(caliber, selector);
      GameInstance.GetTransactionSystem(npc.GetGame()).GiveItem(npc, ItemID.CreateQuery(ammo),
        TweakDBInterface.GetInt(t"AmmoOverhaul.hackDropStack", 10));
      if !ArrayContains(npc.aoStocked, ammo) {
        ArrayPush(npc.aoStocked, ammo);
      }
    }
  }
}

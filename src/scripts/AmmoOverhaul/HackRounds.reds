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
  public static func Drop(npc: ref<NPCPuppet>) -> Void {
    if !HackRounds.IsNetrunner(npc) {
      return;
    }
    let calibers: array<String>;
    for caliber in AOData.Calibers() {
      if Equals(AOData.Family(caliber), "Smart") {
        ArrayPush(calibers, caliber);
      }
    }
    let caliber: String = calibers[RandRange(0, ArraySize(calibers))];
    let selector: TweakDBID = HackRounds.Roll(caliber, MuleKick.Rarity(npc));
    if TDBID.IsValid(selector) {
      GameInstance.GetTransactionSystem(npc.GetGame()).GiveItem(npc, ItemID.CreateQuery(AOData.SelectorAmmo(caliber, selector)),
        TweakDBInterface.GetInt(t"AmmoOverhaul.hackDropStack", 10));
    }
  }
}

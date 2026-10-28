module AmmoOverhaul

// One hit's damage multiplier range: a dud (dudChance, times dudMult), else a hot round
// (hotChance, times hotMult), else a uniform roll in min..max.
public struct AORoll {
  let min: Float;
  let max: Float;
  let dudChance: Float;
  let dudMult: Float;
  let hotChance: Float;
  let hotMult: Float;
}

// Holds a resolved AORoll in AmmoFeedSystem's caches (hash maps take objects).
public class AORollBox extends IScriptable {
  let roll: AORoll;
}

// Resolves an ammo type's damage roll from four layers, first set wins: the round's own flats
// (<ammo>.rollMin ...), its faction's (AmmoOverhaul.roll.<aoFaction>.min ...), its family's
// (AmmoOverhaul.roll.<Power|Tech|Smart>.min ...) and the global ones (AmmoOverhaul.roll.min ...,
// always set). A damage type (Physical, Thermal, Electric, Chemical) is appended to each name,
// e.g. <ammo>.rollMinThermal; when no layer sets the typed value, the whole-hit value is used.
// A value below 0 counts as unset, so layers can be declared at -1.
public abstract class DamageRoll {

  // The layers' flat names for one value, in order: round, faction, family, global.
  private static func Keys(ammo: TweakDBID, family: String, name: String, damageType: String) -> array<TweakDBID> {
    let lower: String = StrLower(StrLeft(name, 1)) + StrRight(name, StrLen(name) - 1) + damageType;
    let keys: array<TweakDBID>;
    ArrayPush(keys, AOData.Flat(ammo, "roll" + name + damageType));
    let faction: String = TweakDBInterface.GetString(AOData.Flat(ammo, "aoFaction"), "");
    if StrLen(faction) > 0 {
      ArrayPush(keys, TDBID.Create("AmmoOverhaul.roll." + faction + "." + lower));
    }
    if StrLen(family) > 0 {
      ArrayPush(keys, TDBID.Create("AmmoOverhaul.roll." + family + "." + lower));
    }
    ArrayPush(keys, TDBID.Create("AmmoOverhaul.roll." + lower));
    return keys;
  }

  private static func First(keys: array<TweakDBID>, out value: Float) -> Bool {
    for key in keys {
      let v: Float = TweakDBInterface.GetFloat(key, -1.0);
      if v >= 0.0 {
        value = v;
        return true;
      }
    }
    return false;
  }

  private static func Value(ammo: TweakDBID, family: String, name: String, damageType: String) -> Float {
    let value: Float = 1.0;
    if StrLen(damageType) > 0 && DamageRoll.First(DamageRoll.Keys(ammo, family, name, damageType), value) {
      return value;
    }
    DamageRoll.First(DamageRoll.Keys(ammo, family, name, ""), value);
    return value;
  }

  // `damageType` is "" for the whole hit.
  public static func Values(ammo: TweakDBID, family: String, damageType: String) -> AORoll {
    let r: AORoll;
    r.min = DamageRoll.Value(ammo, family, "Min", damageType);
    r.max = DamageRoll.Value(ammo, family, "Max", damageType);
    r.dudChance = DamageRoll.Value(ammo, family, "DudChance", damageType);
    r.dudMult = DamageRoll.Value(ammo, family, "DudMult", damageType);
    r.hotChance = DamageRoll.Value(ammo, family, "HotChance", damageType);
    r.hotMult = DamageRoll.Value(ammo, family, "HotMult", damageType);
    return r;
  }

  public static func Draw(r: AORoll) -> Float {
    if RandF() < r.dudChance {
      return r.dudMult;
    }
    if RandF() < r.hotChance {
      return r.hotMult;
    }
    return RandRangeF(r.min, r.max);
  }

  public static func Same(a: AORoll, b: AORoll) -> Bool {
    return a.min == b.min && a.max == b.max && a.dudChance == b.dudChance && a.dudMult == b.dudMult
      && a.hotChance == b.hotChance && a.hotMult == b.hotMult;
  }

  // The family an ammo item is tagged with (AO_Family_<x>), or "" for vanilla and unmanaged ammo.
  public static func AmmoFamily(ammo: TweakDBID) -> String {
    let record: ref<Item_Record> = TweakDBInterface.GetItemRecord(ammo);
    if IsDefined(record) {
      for family in ["Power", "Tech", "Smart"] {
        if record.TagsContains(StringToName("AO_Family_" + family)) {
          return family;
        }
      }
    }
    return "";
  }
}

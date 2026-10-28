module AmmoOverhaul

// Reads the mod's settings from TweakDB. Everything about calibers, slots and ammo types lives in
// the AmmoOverhaul.* flats in r6/tweaks/AmmoOverhaul; nothing here is specific to a gun or ammo
// type. Settings are keyed by short names (AmmoOverhaul.<caliber>.<field>) because TweakXL
// doesn't allow extra properties on existing record types.
public abstract class AOData {

  private static func Key(name: String, field: String) -> TweakDBID {
    return TDBID.Create("AmmoOverhaul." + name + "." + field);
  }

  // Record references are written as quoted strings, but accept foreign keys too in case
  // TweakXL types them that way.
  private static func GetID(path: TweakDBID) -> TweakDBID {
    let value: String = TweakDBInterface.GetString(path, "");
    if StrLen(value) > 0 {
      return TDBID.Create(value);
    }
    return TweakDBInterface.GetForeignKey(path, TDBID.None());
  }

  private static func GetIDs(path: TweakDBID) -> array<TweakDBID> {
    let ids: array<TweakDBID>;
    for value in TweakDBInterface.GetStringArray(path) {
      ArrayPush(ids, TDBID.Create(value));
    }
    if ArraySize(ids) == 0 {
      ids = TweakDBInterface.GetForeignKeyArray(path);
    }
    return ids;
  }

  private static func GetNames(path: TweakDBID) -> array<CName> {
    let names: array<CName>;
    for value in TweakDBInterface.GetStringArray(path) {
      ArrayPush(names, StringToName(value));
    }
    if ArraySize(names) == 0 {
      names = TweakDBInterface.GetCNameArray(path);
    }
    return names;
  }

  private static func GetStrings(path: TweakDBID) -> array<String> {
    let values: array<String> = TweakDBInterface.GetStringArray(path);
    if ArraySize(values) == 0 {
      for name in TweakDBInterface.GetCNameArray(path) {
        ArrayPush(values, NameToString(name));
      }
    }
    return values;
  }

  // Appends ".<field>" to a record ID, for reading a record's own flats.
  public static func Flat(record: TweakDBID, field: String) -> TweakDBID {
    let path: TweakDBID = record;
    TDBID.Append(path, TDBID.Create("." + field));
    return path;
  }

  // --- Calibers ------------------------------------------------------------------------------

  public static func Calibers() -> array<String> {
    return AOData.GetStrings(t"AmmoOverhaul.calibers");
  }

  public static func WeaponTags(caliber: String) -> array<CName> {
    return AOData.GetNames(AOData.Key(caliber, "weaponTags"));
  }

  public static func FeedElement(caliber: String) -> TweakDBID {
    return AOData.GetID(AOData.Key(caliber, "feedElement"));
  }

  public static func FeedSlot(caliber: String) -> TweakDBID {
    return AOData.GetID(AOData.Key(caliber, "feedSlot"));
  }

  // What the caliber's guns take with an empty feed slot; their records' base ammo.
  public static func DefaultAmmo(caliber: String) -> TweakDBID {
    return AOData.GetID(AOData.Key(caliber, "defaultAmmo"));
  }

  // The ammo stack a selector part feeds, or an invalid ID if it isn't one of this caliber's.
  public static func SelectorAmmo(caliber: String, selector: TweakDBID) -> TweakDBID {
    let selectors: array<TweakDBID> = AOData.GetIDs(AOData.Key(caliber, "selectors"));
    let ammo: array<TweakDBID> = AOData.GetIDs(AOData.Key(caliber, "selectorAmmo"));
    let i: Int32 = 0;
    while i < ArraySize(selectors) && i < ArraySize(ammo) {
      if selectors[i] == selector {
        return ammo[i];
      }
      i += 1;
    }
    return TDBID.None();
  }

  // The caliber of a weapon record (by its tags), or "" if the mod doesn't manage it.
  public static func CaliberForWeapon(weapon: TweakDBID) -> String {
    let record: ref<WeaponItem_Record> = TweakDBInterface.GetWeaponItemRecord(weapon);
    if IsDefined(record) {
      for caliber in AOData.Calibers() {
        for tag in AOData.WeaponTags(caliber) {
          if record.TagsContains(tag) {
            return caliber;
          }
        }
      }
    }
    return "";
  }

  public static func FeedSlots() -> array<TweakDBID> {
    let slots: array<TweakDBID>;
    for caliber in AOData.Calibers() {
      ArrayPush(slots, AOData.FeedSlot(caliber));
    }
    return slots;
  }

  public static func IsFeedSlot(slot: TweakDBID) -> Bool {
    let slots: array<TweakDBID> = AOData.FeedSlots();
    return TDBID.IsValid(slot) && ArrayContains(slots, slot);
  }

  public static func AppendFeedSlots(out slots: array<TweakDBID>) -> Void {
    for slot in AOData.FeedSlots() {
      if !ArrayContains(slots, slot) {
        ArrayPush(slots, slot);
      }
    }
  }

  // The ammo stack selected by the part in the weapon's feed slot; the caliber's default ammo
  // when the slot is empty. Invalid when nothing is selected and there is no default.
  public static func SelectedAmmo(owner: ref<GameObject>, weaponID: ItemID, caliber: String) -> TweakDBID {
    if StrLen(caliber) == 0 {
      return TDBID.None();
    }
    let itemData: wref<gameItemData> = GameInstance.GetTransactionSystem(owner.GetGame()).GetItemData(owner, weaponID);
    let slot: TweakDBID = AOData.FeedSlot(caliber);
    let part: InnerItemData;
    let ammo: TweakDBID;
    if IsDefined(itemData) && itemData.HasPartInSlot(slot) {
      itemData.GetItemPart(part, slot);
      ammo = AOData.SelectorAmmo(caliber, ItemID.GetTDBID(InnerItemData.GetItemID(part)));
      if TDBID.IsValid(ammo) {
        return ammo;
      }
    }
    return AOData.DefaultAmmo(caliber);
  }

  // --- Ammo effects --------------------------------------------------------------------------

  // The on-hit status effect of an ammo type and its chance, or an invalid ID if it has none.
  public static func OnHitEffect(ammo: TweakDBID, out chance: Float) -> TweakDBID {
    for name in AOData.GetStrings(t"AmmoOverhaul.ammoEffects") {
      if AOData.GetID(AOData.Key(name, "ammo")) == ammo {
        chance = TweakDBInterface.GetFloat(AOData.Key(name, "chance"), 1.0);
        return AOData.GetID(AOData.Key(name, "effect"));
      }
    }
    return TDBID.None();
  }
}

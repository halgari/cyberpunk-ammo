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

  // The first selector, across all calibers, that feeds `ammo`; invalid if none does.
  public static func SelectorForAmmo(ammo: TweakDBID) -> TweakDBID {
    for caliber in AOData.Calibers() {
      let selectors: array<TweakDBID> = AOData.Selectors(caliber);
      let stacks: array<TweakDBID> = AOData.GetIDs(AOData.Key(caliber, "selectorAmmo"));
      let i: Int32 = 0;
      while i < ArraySize(selectors) && i < ArraySize(stacks) {
        if stacks[i] == ammo {
          return selectors[i];
        }
        i += 1;
      }
    }
    return TDBID.None();
  }

  // What a round multiplies damage by: the product of the DamagePerHit Multiplier modifiers on its
  // selector part, 1.0 if it has none (or isn't one of the mod's rounds). NPC guns have no
  // DamagePerHit to carry the modifier, so the damage roll applies it (RollGunHit).
  public static func AmmoDamageFactor(ammo: TweakDBID) -> Float {
    let factor: Float = 1.0;
    let selector: TweakDBID = AOData.SelectorForAmmo(ammo);
    if !TDBID.IsValid(selector) {
      return factor;
    }
    let modifiers: array<wref<StatModifier_Record>>;
    TweakDBInterface.GetItemRecord(selector).StatModifiers(modifiers);
    for modifier in modifiers {
      let constant: wref<ConstantStatModifier_Record> = modifier as ConstantStatModifier_Record;
      if IsDefined(constant) && Equals(constant.StatType().StatType(), gamedataStatType.DamagePerHit) && Equals(constant.ModifierType(), n"Multiplier") {
        factor *= constant.Value();
      }
    }
    return factor;
  }

  // --- Tiers and distribution ----------------------------------------------------------------

  // "Power", "Tech" or "Smart".
  public static func Family(caliber: String) -> String {
    return TweakDBInterface.GetString(AOData.Key(caliber, "family"), "");
  }

  public static func Selectors(caliber: String) -> array<TweakDBID> {
    return AOData.GetIDs(AOData.Key(caliber, "selectors"));
  }

  // A selector's tier (0 Common, 1 Uncommon, ...), or -1 if it isn't one of this caliber's.
  public static func SelectorTier(caliber: String, selector: TweakDBID) -> Int32 {
    let selectors: array<TweakDBID> = AOData.Selectors(caliber);
    let tiers: array<Int32> = TweakDBInterface.GetIntArray(AOData.Key(caliber, "selectorTiers"));
    let i: Int32 = 0;
    while i < ArraySize(selectors) && i < ArraySize(tiers) {
      if selectors[i] == selector {
        return tiers[i];
      }
      i += 1;
    }
    return -1;
  }

  // The selectors of a tier, in the order the caliber lists them (empty if it has none).
  public static func SelectorsForTier(caliber: String, tier: Int32) -> array<TweakDBID> {
    let out: array<TweakDBID>;
    for selector in AOData.Selectors(caliber) {
      if AOData.SelectorTier(caliber, selector) == tier {
        ArrayPush(out, selector);
      }
    }
    return out;
  }

  // The ammo items of a tier, one per selector.
  public static func AmmosForTier(caliber: String, tier: Int32) -> array<TweakDBID> {
    let out: array<TweakDBID>;
    for selector in AOData.SelectorsForTier(caliber, tier) {
      let ammo: TweakDBID = AOData.SelectorAmmo(caliber, selector);
      if TDBID.IsValid(ammo) {
        ArrayPush(out, ammo);
      }
    }
    return out;
  }

  // The vanilla ammo item this caliber's share of world loot and vendor stock is taken from.
  public static func VanillaAmmo(caliber: String) -> TweakDBID {
    return AOData.GetID(AOData.Key(caliber, "vanillaAmmo"));
  }

  public static func LootWeight(caliber: String) -> Float {
    return TweakDBInterface.GetFloat(AOData.Key(caliber, "lootWeight"), 0.0);
  }

  // A tier's share of a family's ammo, or 0 if not set.
  public static func TierShare(family: String, tier: Int32) -> Float {
    let shares: array<Float> = TweakDBInterface.GetFloatArray(TDBID.Create("AmmoOverhaul.shares." + family));
    return tier >= 0 && tier < ArraySize(shares) ? shares[tier] : 0.0;
  }

  public static func OwnedBias() -> Float {
    return TweakDBInterface.GetFloat(t"AmmoOverhaul.loot.ownedBias", 0.0);
  }

  // By gamedataNPCRarity name, e.g. "Elite".
  public static func NpcUncommonFactor(rarity: String) -> Float {
    return TweakDBInterface.GetFloat(TDBID.Create("AmmoOverhaul.npcUncommonFactor." + rarity), 1.0);
  }

  // Weapon records the caliber takes besides those with its tags (guns with no family tag).
  public static func WeaponRecords(caliber: String) -> array<TweakDBID> {
    return AOData.GetIDs(AOData.Key(caliber, "weaponRecords"));
  }

  // Whether the caliber manages this weapon: it carries one of the caliber's weaponTags or is one
  // of its weaponRecords, and fires real ammo (Plan B fires eddies and is left alone).
  public static func Matches(weapon: ref<WeaponItem_Record>, caliber: String) -> Bool {
    let ammo: ref<Item_Record> = weapon.Ammo();
    if !IsDefined(ammo) || !ammo.TagsContains(n"Ammo") {
      return false;
    }
    for tag in AOData.WeaponTags(caliber) {
      if weapon.TagsContains(tag) {
        return true;
      }
    }
    let records: array<TweakDBID> = AOData.WeaponRecords(caliber);
    return ArrayContains(records, weapon.GetID());
  }

  // The caliber of a weapon record, or "" if the mod doesn't manage it. Cached per record by
  // AmmoFeedSystem once the game runs (every hit asks).
  public static func CaliberForWeapon(weapon: TweakDBID) -> String {
    let system: ref<AmmoFeedSystem> = AmmoFeedSystem.Get(GetGameInstance());
    return IsDefined(system) ? system.CachedCaliber(weapon) : AOData.FindCaliber(weapon);
  }

  public static func FindCaliber(weapon: TweakDBID) -> String {
    let record: ref<WeaponItem_Record> = TweakDBInterface.GetWeaponItemRecord(weapon);
    if IsDefined(record) {
      for caliber in AOData.Calibers() {
        if AOData.Matches(record, caliber) {
          return caliber;
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

  // Placeholder icon of an empty feed slot and of our rounds in loot windows.
  public static func FeedShadowIcon() -> CName {
    return n"UIIcon.LootingShadow_HandgunAmmo";
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

  // The ammo a shot from `weapon` is loaded with: the NPC's rolled or selected round, the
  // player's selection, or the weapon record's own ammo for guns the mod doesn't manage.
  public static func LoadedAmmo(instigator: ref<GameObject>, weapon: ref<WeaponObject>) -> TweakDBID {
    let weaponID: ItemID = weapon.GetItemID();
    let npc: ref<NPCPuppet> = instigator as NPCPuppet;
    if IsDefined(npc) {
      return NpcAmmo.GunAmmo(npc, weaponID);
    }
    let caliber: String = AOData.CaliberForWeapon(ItemID.GetTDBID(weaponID));
    if StrLen(caliber) > 0 {
      return AOData.SelectedAmmo(instigator, weaponID, caliber);
    }
    let record: ref<WeaponItem_Record> = TweakDBInterface.GetWeaponItemRecord(ItemID.GetTDBID(weaponID));
    return IsDefined(record) && IsDefined(record.Ammo()) ? record.Ammo().GetID() : TDBID.None();
  }

  // How many rounds of its selected ammo the player has for `weaponID`, or -1 if the weapon
  // isn't one of the mod's (then the record's ammo is right).
  public static func SelectedAmmoCount(weaponID: ItemID) -> Int32 {
    let caliber: String = AOData.CaliberForWeapon(ItemID.GetTDBID(weaponID));
    let player: ref<GameObject> = GetPlayer(GetGameInstance());
    if StrLen(caliber) == 0 || !IsDefined(player) {
      return -1;
    }
    let ammo: TweakDBID = AOData.SelectedAmmo(player, weaponID, caliber);
    return TDBID.IsValid(ammo) ? GameInstance.GetTransactionSystem(player.GetGame()).GetItemQuantity(player, ItemID.CreateQuery(ammo)) : 0;
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

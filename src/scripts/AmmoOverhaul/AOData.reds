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

  // True for any ammo selector part (tag AO_AmmoSelector); screens other than a gun's mod screen
  // filter these out.
  public static func IsSelector(item: ItemID) -> Bool {
    return TweakDBInterface.GetItemRecord(ItemID.GetTDBID(item)).TagsContains(n"AO_AmmoSelector");
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

  // --- Crafting (Crafting.reds; records from tools/crafting/crafting.py) ----------------------

  // The ItemRecipe record that makes `ammo` (vanilla's for the 4 vanilla ammo items); invalid if none.
  public static func Recipe(ammo: TweakDBID) -> TweakDBID {
    return AOData.GetID(AOData.Flat(ammo, "aoRecipe"));
  }

  // Rounds per full batch when breaking `ammo` down (0: not a round, vanilla result).
  public static func ScrapRounds(ammo: TweakDBID) -> Int32 {
    return TweakDBInterface.GetInt(AOData.Flat(ammo, "aoScrapRounds"), 0);
  }

  // Components each full batch of `ammo` breaks down into.
  public static func ScrapGive(ammo: TweakDBID) -> Int32 {
    return TweakDBInterface.GetInt(AOData.Flat(ammo, "aoScrapGive"), 0);
  }

  public static func IsVanillaAmmo(ammo: TweakDBID) -> Bool {
    return ammo == t"Ammo.HandgunAmmo" || ammo == t"Ammo.RifleAmmo" || ammo == t"Ammo.ShotgunAmmo" || ammo == t"Ammo.SniperRifleAmmo";
  }

  // The recipe item for `ammo` that loot and gun shops hand out: Uncommon and up only.
  public static func RecipeItem(ammo: TweakDBID) -> TweakDBID {
    let item: ref<Item_Record> = TweakDBInterface.GetItemRecord(ammo);
    if !IsDefined(item) || Equals(item.Quality().Type(), gamedataQuality.Common) || AOData.IsVanillaAmmo(ammo) {
      return TDBID.None();
    }
    return AOData.Recipe(ammo);
  }

  public static func RecipeDropFactor() -> Float {
    return TweakDBInterface.GetFloat(t"AmmoOverhaul.recipeDropFactor", 0.0);
  }

  public static func RecipeVendorChance() -> Float {
    return TweakDBInterface.GetFloat(t"AmmoOverhaul.recipeVendorChance", 0.0);
  }

  // By gamedataNPCRarity name, e.g. "Elite".
  public static func NpcUncommonFactor(rarity: String) -> Float {
    return TweakDBInterface.GetFloat(TDBID.Create("AmmoOverhaul.npcUncommonFactor." + rarity), 1.0);
  }

  // How much likelier than its family's share of `tier` an NPC of `rarity` is to carry a round of
  // that tier: 1 Uncommon, 2 Rare, 3 Epic. Unset Rare and Epic factors are 0 (never).
  public static func NpcTierFactor(rarity: String, tier: Int32) -> Float {
    switch tier {
      case 1:
        return AOData.NpcUncommonFactor(rarity);
      case 2:
        return TweakDBInterface.GetFloat(TDBID.Create("AmmoOverhaul.npcRareFactor." + rarity), 0.0);
      case 3:
        return TweakDBInterface.GetFloat(TDBID.Create("AmmoOverhaul.npcEpicFactor." + rarity), 0.0);
      default:
        return 0.0;
    }
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

  // --- Hit data ------------------------------------------------------------------------------
  // What a round does on a hit besides its gun's stats, read from the ammo record's own flats and
  // applied by the hit hooks to every ranged gun hit, V's or an NPC's (AmmoFeedSystem.RollGunHit,
  // ApplyAmmoOnHit). All optional:
  //   <ammo>.aoEffects: status effects; <ammo>.aoEffectChances: each one's chance (missing = 1)
  //   <ammo>.aoShareType ("Thermal", "Chemical" or "Electric") and <ammo>.aoShare: the fraction of
  //     the hit's Physical damage dealt as that type instead
  //   <ammo>.aoMachineBonus: damage factor against drones, mechs, androids, turrets and vehicles
  //   <ammo>.aoNonlethal: a kill knocks the target out instead

  public static func HitEffects(ammo: TweakDBID, out chances: array<Float>) -> array<TweakDBID> {
    let effects: array<TweakDBID> = AOData.GetIDs(AOData.Flat(ammo, "aoEffects"));
    let given: array<Float> = TweakDBInterface.GetFloatArray(AOData.Flat(ammo, "aoEffectChances"));
    ArrayClear(chances);
    let i: Int32 = 0;
    while i < ArraySize(effects) {
      ArrayPush(chances, i < ArraySize(given) ? given[i] : 1.0);
      i += 1;
    }
    return effects;
  }

  // The effect V gets for `effect`: vanilla gives V its own Player versions of burning, poison,
  // bleeding and shock (DamageSystem.ProcessStatusEffectApplicationStats); anything else is unchanged.
  public static func PlayerEffect(effect: TweakDBID) -> TweakDBID {
    let name: String = TDBID.ToStringDEBUG(effect);
    switch name {
      case "BaseStatusEffect.Burning":
      case "BaseStatusEffect.MediumBurning":
        return t"BaseStatusEffect.PlayerBurning";
      case "BaseStatusEffect.Poisoned":
        return t"BaseStatusEffect.PlayerPoisoned";
      case "BaseStatusEffect.Bleeding":
        return t"BaseStatusEffect.PlayerBleeding";
      case "BaseStatusEffect.EMP":
        return t"BaseStatusEffect.PlayerElectrocuted";
      default:
        return effect;
    }
  }

  // A round's effect chance is per shot: each of a shot's `pellets` hits rolls this, so a shot that
  // lands them all applies the effect with `chance`.
  public static func PelletChance(chance: Float, pellets: Int32) -> Float {
    if pellets <= 1 || chance >= 1.0 || chance <= 0.0 {
      return chance;
    }
    return 1.0 - PowF(1.0 - chance, 1.0 / Cast<Float>(pellets));
  }

  // The fraction of Physical damage moved to `damageType`; 0 if the round moves none.
  public static func DamageShare(ammo: TweakDBID, out damageType: gamedataDamageType) -> Float {
    let name: String = TweakDBInterface.GetString(AOData.Flat(ammo, "aoShareType"), "");
    let share: Float = TweakDBInterface.GetFloat(AOData.Flat(ammo, "aoShare"), 0.0);
    if StrLen(name) == 0 || share <= 0.0 {
      return 0.0;
    }
    damageType = IntEnum<gamedataDamageType>(Cast<Int32>(EnumValueFromString("gamedataDamageType", name)));
    return MinF(1.0, share);
  }

  public static func MachineBonus(ammo: TweakDBID) -> Float {
    return TweakDBInterface.GetFloat(AOData.Flat(ammo, "aoMachineBonus"), 1.0);
  }

  public static func IsNonlethal(ammo: TweakDBID) -> Bool {
    return TweakDBInterface.GetBool(AOData.Flat(ammo, "aoNonlethal"), false);
  }

  // Drones, mechs, androids and turrets (ScriptedPuppet.IsMechanical), and vehicles.
  public static func IsMachine(target: ref<GameObject>) -> Bool {
    if !IsDefined(target) {
      return false;
    }
    let puppet: ref<ScriptedPuppet> = target as ScriptedPuppet;
    return target.IsVehicle() || target.IsDrone() || target.IsTurret() || (IsDefined(puppet) && puppet.IsMechanical());
  }
}

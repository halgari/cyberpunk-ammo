module AmmoOverhaul

// Runs once while TweakDB loads, after the YAML is applied. For every caliber, finds the weapons
// carrying one of its weaponTags, sets their ammo to the caliber's default and gives them a clone
// of their blueprint with the caliber's feed slot added. Cloning each weapon's own blueprint keeps
// the NoMuzzle/NoScope/Collectible variants intact. Also turns off the engine's random ammo drop
// on NPC death: NPCs leave the ammo they actually carried instead (NpcAmmo).
public class AmmoFeedTweak extends ScriptableTweak {

  private let m_sourceBlueprints: array<TweakDBID>;
  private let m_elements: array<TweakDBID>;
  private let m_clones: array<TweakDBID>;

  protected cb func OnApply() -> Void {
    let weapons: array<ref<TweakDBRecord>> = TweakDBInterface.GetRecords(n"gamedataWeaponItem_Record");
    let calibers: array<String> = AOData.Calibers();
    ModLog(n"AmmoOverhaul", IntToString(ArraySize(calibers)) + " caliber(s), " + IntToString(ArraySize(weapons)) + " weapon records");
    for caliber in calibers {
      this.ApplyCaliber(caliber, weapons);
    }
    this.DisableAmmoDrops();
  }

  private func DisableAmmoDrops() -> Void {
    let changed: Int32 = 0;
    for record in TweakDBInterface.GetRecords(n"gamedataCharacter_Record") {
      let character: ref<Character_Record> = record as Character_Record;
      if IsDefined(character) && character.DropsAmmoOnDeathChance() > 0.0 {
        TweakDBManager.SetFlat(AOData.Flat(character.GetID(), "dropsAmmoOnDeathChance"), ToVariant(0.0));
        TweakDBManager.UpdateRecord(character.GetID());
        changed += 1;
      }
    }
    ModLog(n"AmmoOverhaul", "turned off the random ammo drop of " + IntToString(changed) + " characters");
  }

  private func ApplyCaliber(caliber: String, weapons: array<ref<TweakDBRecord>>) -> Void {
    let ammo: TweakDBID = AOData.DefaultAmmo(caliber);
    let tags: array<CName> = AOData.WeaponTags(caliber);
    let element: TweakDBID = AOData.FeedElement(caliber);
    let patched: Int32 = 0;
    if !TDBID.IsValid(ammo) || ArraySize(tags) == 0 {
      ModLog(n"AmmoOverhaul", "caliber " + caliber + ": missing defaultAmmo or weaponTags, skipped");
      return;
    }
    for record in weapons {
      let weapon: ref<WeaponItem_Record> = record as WeaponItem_Record;
      if IsDefined(weapon) && AmmoFeedTweak.HasAnyTag(weapon, tags) {
        let id: TweakDBID = weapon.GetID();
        TweakDBManager.SetFlat(AOData.Flat(id, "ammo"), ToVariant(ammo));
        let blueprint: TweakDBID = TweakDBInterface.GetForeignKey(AOData.Flat(id, "blueprint"), TDBID.None());
        if TDBID.IsValid(blueprint) && TDBID.IsValid(element) {
          TweakDBManager.SetFlat(AOData.Flat(id, "blueprint"), ToVariant(this.WithElement(blueprint, element)));
        }
        TweakDBManager.UpdateRecord(id);
        patched += 1;
      }
    }
    ModLog(n"AmmoOverhaul", "caliber " + caliber + ": patched " + IntToString(patched) + " weapon records" + (TDBID.IsValid(element) ? "" : " (no feed element)"));
  }

  private static func HasAnyTag(weapon: ref<WeaponItem_Record>, tags: array<CName>) -> Bool {
    for tag in tags {
      if weapon.TagsContains(tag) {
        return true;
      }
    }
    return false;
  }

  // Returns a blueprint identical to `blueprint` whose root element also holds `element`.
  private func WithElement(blueprint: TweakDBID, element: TweakDBID) -> TweakDBID {
    let i: Int32 = 0;
    while i < ArraySize(this.m_sourceBlueprints) {
      if this.m_sourceBlueprints[i] == blueprint && this.m_elements[i] == element {
        return this.m_clones[i];
      }
      i += 1;
    }
    // Clone IDs only need to be unique; they are derived from the source plus a per-clone index.
    let suffix: String = "AO_" + IntToString(ArraySize(this.m_clones));
    let root: TweakDBID = TweakDBInterface.GetForeignKey(AOData.Flat(blueprint, "rootElement"), TDBID.None());
    let newRoot: TweakDBID = AOData.Flat(root, suffix);
    TweakDBManager.CloneRecord(newRoot, root);
    let children: array<TweakDBID> = TweakDBInterface.GetForeignKeyArray(AOData.Flat(root, "childElements"));
    ArrayPush(children, element);
    TweakDBManager.SetFlat(AOData.Flat(newRoot, "childElements"), ToVariant(children));
    TweakDBManager.UpdateRecord(newRoot);

    let newBlueprint: TweakDBID = AOData.Flat(blueprint, suffix);
    TweakDBManager.CloneRecord(newBlueprint, blueprint);
    TweakDBManager.SetFlat(AOData.Flat(newBlueprint, "rootElement"), ToVariant(newRoot));
    TweakDBManager.UpdateRecord(newBlueprint);

    ArrayPush(this.m_sourceBlueprints, blueprint);
    ArrayPush(this.m_elements, element);
    ArrayPush(this.m_clones, newBlueprint);
    return newBlueprint;
  }
}

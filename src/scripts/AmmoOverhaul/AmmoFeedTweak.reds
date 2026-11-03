module AmmoOverhaul

// Runs once while TweakDB loads, after the YAML is applied. Gives every weapon the caliber
// AOData.FindCaliber picks (a user override, else the calibers' weaponTags or weaponRecords), sets
// its ammo to the caliber's default and gives it a clone of its blueprint with the caliber's feed
// slot added. Then applies the user's ammo weight multipliers. Cloning each weapon's own blueprint keeps
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
    this.ApplyCalibers(calibers, weapons);
    this.ScaleWeights(calibers);
    this.DisableAmmoDrops();
  }

  // One pass over the guns: each goes to AOData.FindCaliber's answer, so the user's overrides
  // and the runtime lookup always agree.
  private func ApplyCalibers(calibers: array<String>, weapons: array<ref<TweakDBRecord>>) -> Void {
    let patched: array<Int32>;
    let usable: array<Bool>;
    for caliber in calibers {
      let tags: array<CName> = AOData.WeaponTags(caliber);
      let records: array<TweakDBID> = AOData.WeaponRecords(caliber);
      let ok: Bool = TDBID.IsValid(AOData.DefaultAmmo(caliber)) && ArraySize(tags) + ArraySize(records) > 0;
      if !ok {
        ModLog(n"AmmoOverhaul", "caliber " + caliber + ": missing defaultAmmo or weapons, skipped");
      }
      ArrayPush(usable, ok);
      ArrayPush(patched, 0);
    }
    let overridden: Int32 = 0;
    let warned: array<String>;
    for record in weapons {
      let weapon: ref<WeaponItem_Record> = record as WeaponItem_Record;
      if IsDefined(weapon) {
        let raw: String = AOData.UserCaliberRaw(weapon);
        if StrLen(raw) > 0 {
          let ammo: ref<Item_Record> = weapon.Ammo();
          if !weapon.TagsContains(n"RangedWeapon") || !IsDefined(ammo) || !ammo.TagsContains(n"Ammo") {
            this.WarnOnce(warned, "override \"" + raw + "\" on a weapon that isn't a gun firing ammo, ignored");
          } else if StrLen(AOData.UserCaliber(weapon)) == 0 {
            this.WarnOnce(warned, "unknown caliber \"" + raw + "\" in an override, ignored");
          } else {
            overridden += 1;
          }
        }
        let i: Int32 = ArrayFindFirst(calibers, AOData.FindCaliber(weapon.GetID()));
        if i >= 0 && usable[i] {
          this.Patch(weapon, calibers[i]);
          patched[i] += 1;
        }
      }
    }
    let i: Int32 = 0;
    while i < ArraySize(calibers) {
      if usable[i] {
        let element: TweakDBID = AOData.FeedElement(calibers[i]);
        ModLog(n"AmmoOverhaul", "caliber " + calibers[i] + ": patched " + IntToString(patched[i]) + " weapon records" + (TDBID.IsValid(element) ? "" : " (no feed element)"));
      }
      i += 1;
    }
    ModLog(n"AmmoOverhaul", "user overrides decided " + IntToString(overridden) + " weapon records");
  }

  private func WarnOnce(out warned: array<String>, text: String) -> Void {
    if !ArrayContains(warned, text) {
      ArrayPush(warned, text);
      ModLog(n"AmmoOverhaul", text);
    }
  }

  // Applies the user's weight multipliers (AOData.WeightScale) and records each round's unscaled
  // weight as <ammo>.aoBaseWeight for the NPC loot cap. Rounds share weight modifiers with the
  // round they're based on, so a rescaled round gets its own copies (<ammo>.aoWeight<n>).
  private func ScaleWeights(calibers: array<String>) -> Void {
    let done: array<TweakDBID>;
    let scaled: Int32 = 0;
    for caliber in calibers {
      let scale: Float = AOData.CaliberWeightScale(caliber);
      for ammo in AOData.CaliberAmmo(caliber) {
        if !ArrayContains(done, ammo) {
          ArrayPush(done, ammo);
          if this.ScaleWeight(ammo, scale * AOData.RoundWeightScale(ammo)) {
            scaled += 1;
          }
        }
      }
    }
    ModLog(n"AmmoOverhaul", IntToString(ArraySize(done)) + " rounds, " + IntToString(scaled) + " reweighted by user overrides");
  }

  private func ScaleWeight(ammo: TweakDBID, scale: Float) -> Bool {
    let modifiers: array<TweakDBID> = TweakDBInterface.GetForeignKeyArray(AOData.Flat(ammo, "statModifiers"));
    let kept: array<TweakDBID>;
    let base: Float = 0.0;
    let n: Int32 = 0;
    for id in modifiers {
      let modifier: ref<ConstantStatModifier_Record> = TweakDBInterface.GetRecord(id) as ConstantStatModifier_Record;
      if IsDefined(modifier) && Equals(modifier.StatType().StatType(), gamedataStatType.Weight) && Equals(modifier.ModifierType(), n"Additive") {
        base += modifier.Value();
        if scale != 1.0 {
          let copy: TweakDBID = AOData.Flat(ammo, "aoWeight" + IntToString(n));
          TweakDBManager.CloneRecord(copy, id);
          TweakDBManager.SetFlat(AOData.Flat(copy, "value"), ToVariant(modifier.Value() * scale));
          TweakDBManager.UpdateRecord(copy);
          id = copy;
          n += 1;
        }
      }
      ArrayPush(kept, id);
    }
    TweakDBManager.SetFlat(AOData.Flat(ammo, "aoBaseWeight"), ToVariant(base));
    if n > 0 {
      TweakDBManager.SetFlat(AOData.Flat(ammo, "statModifiers"), ToVariant(kept));
      TweakDBManager.UpdateRecord(ammo);
    }
    return n > 0;
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

  // Sets the gun's ammo to the caliber's default and gives it a blueprint with the feed slot.
  private func Patch(weapon: ref<WeaponItem_Record>, caliber: String) -> Void {
    let id: TweakDBID = weapon.GetID();
    let element: TweakDBID = AOData.FeedElement(caliber);
    TweakDBManager.SetFlat(AOData.Flat(id, "ammo"), ToVariant(AOData.DefaultAmmo(caliber)));
    let blueprint: TweakDBID = TweakDBInterface.GetForeignKey(AOData.Flat(id, "blueprint"), TDBID.None());
    if TDBID.IsValid(blueprint) && TDBID.IsValid(element) {
      TweakDBManager.SetFlat(AOData.Flat(id, "blueprint"), ToVariant(this.WithElement(blueprint, element)));
    }
    TweakDBManager.UpdateRecord(id);
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

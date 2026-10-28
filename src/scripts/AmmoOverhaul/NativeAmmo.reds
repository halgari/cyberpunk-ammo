module AmmoOverhaul

// Gives one spawned gun its own ammo type through the native plugin.
//
// The engine copies a gun's ammo type from its record into the spawned weapon object and uses
// that copy from then on. The plugin can read and write the copy, but its offset isn't known
// ahead of time (it isn't in the RTTI and may move between game patches), so the first gun given
// a different ammo type in a session locates it: of the places in the object holding the record's
// ammo ID, it's the one that, once overwritten, makes the engine report the new ammo's inventory
// count as the gun's total. A failed check is undone. Later guns reuse the offset after checking
// it still holds an ammo ID.
public abstract class NativeAmmo {

  // Ammo the weapon object currently uses, or an invalid ID when the offset isn't known yet.
  public static func Current(weapon: ref<WeaponObject>, offset: Int32) -> TweakDBID {
    return offset > 0 ? AO_ReadAmmoField(weapon, offset) : TDBID.None();
  }

  // Makes `weapon` use `ammo`. `offset` is the known field offset (0 if not located yet) and is
  // updated when the field is located or found to have moved. False if the gun couldn't be
  // changed (e.g. it isn't fully spawned yet and the field doesn't hold its ammo).
  public static func Apply(owner: ref<GameObject>, weapon: ref<WeaponObject>, ammo: TweakDBID, out offset: Int32) -> Bool {
    if offset > 0 {
      let current: TweakDBID = AO_ReadAmmoField(weapon, offset);
      if current == ammo {
        return true;
      }
      if NativeAmmo.IsAmmo(current) && AO_WriteAmmoField(weapon, offset, current, ammo) {
        return true;
      }
      AmmoFeedSystem.Log("ammo field at " + IntToString(offset) + " holds " + TDBID.ToStringDEBUG(current) + ", locating it again");
      offset = 0;
    }
    let recordAmmo: TweakDBID = NativeAmmo.RecordAmmo(weapon);
    if recordAmmo == ammo {
      // Nothing to change, and nothing to verify a candidate against.
      return true;
    }
    let ts: ref<TransactionSystem> = GameInstance.GetTransactionSystem(owner.GetGame());
    let wanted: Int32 = ts.GetItemQuantity(owner, ItemID.CreateQuery(ammo));
    let before: Int32 = ts.GetItemQuantity(owner, ItemID.CreateQuery(recordAmmo));
    for candidate in AO_FindAmmoFields(weapon, recordAmmo) {
      if AO_WriteAmmoField(weapon, candidate, recordAmmo, ammo) {
        if weapon.GetTotalAmmoCount() == wanted {
          if wanted != before {
            AmmoFeedSystem.Log("ammo field located at " + IntToString(candidate));
            offset = candidate;
          }
          // With equal counts candidates can't be told apart: keep the write, locate again next time.
          return true;
        }
        AO_WriteAmmoField(weapon, candidate, ammo, recordAmmo);
      }
    }
    return false;
  }

  private static func RecordAmmo(weapon: ref<WeaponObject>) -> TweakDBID {
    let record: ref<WeaponItem_Record> = TweakDBInterface.GetWeaponItemRecord(ItemID.GetTDBID(weapon.GetItemID()));
    return IsDefined(record) && IsDefined(record.Ammo()) ? record.Ammo().GetID() : TDBID.None();
  }

  private static func IsAmmo(id: TweakDBID) -> Bool {
    let record: ref<Item_Record> = TweakDBInterface.GetItemRecord(id);
    return IsDefined(record) && IsDefined(record.ItemType()) && Equals(record.ItemType().Type(), gamedataItemType.Con_Ammo);
  }
}

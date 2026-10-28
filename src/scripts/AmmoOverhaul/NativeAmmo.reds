module AmmoOverhaul

// Gives one spawned gun its own ammo type through the native plugin.
//
// The engine copies a gun's ammo type from its record into the spawned weapon object, twice: the
// ammo the gun is loaded with and uses (+0x2e4 on 2.50), and the ammo it wants (+0x4a8). When the
// two differ the engine has an ammo change pending (HasAmmoChangeRequest) and carries it out by
// reloading into the wanted ammo, so both are written. The plugin can read and write them, but
// their offsets aren't known ahead of time (they aren't in the RTTI and may move between game
// patches), so the first gun given a different ammo type in a session locates them among the
// places in the object holding the old ammo ID:
//   - the loaded ammo is the one that, once overwritten, makes the engine report the new ammo's
//     inventory count as the gun's total;
//   - the wanted ammo is the one that, once overwritten, clears the pending change.
// A failed check is undone. Later guns reuse the offsets after checking they still hold an ammo ID.
public abstract class NativeAmmo {

  // Ammo the weapon object currently uses, or an invalid ID when the offset isn't known yet.
  public static func Current(weapon: ref<WeaponObject>, offset: Int32) -> TweakDBID {
    return offset > 0 ? AO_ReadAmmoField(weapon, offset) : TDBID.None();
  }

  // Makes `weapon` use `ammo`. The offsets are the known field offsets (0 if not located yet) and
  // are updated when a field is located or found to have moved. False if the gun couldn't be
  // changed (e.g. it isn't fully spawned yet and the field doesn't hold its ammo).
  public static func Apply(owner: ref<GameObject>, weapon: ref<WeaponObject>, ammo: TweakDBID, out offset: Int32, out wantedOffset: Int32) -> Bool {
    let previous: TweakDBID = ammo;
    if !NativeAmmo.ApplyLoaded(owner, weapon, ammo, offset, previous) {
      return false;
    }
    NativeAmmo.ApplyWanted(weapon, ammo, offset, previous, wantedOffset);
    return true;
  }

  // The loaded ammo. `previous` is what the field held before.
  private static func ApplyLoaded(owner: ref<GameObject>, weapon: ref<WeaponObject>, ammo: TweakDBID, out offset: Int32, out previous: TweakDBID) -> Bool {
    if offset > 0 {
      let current: TweakDBID = AO_ReadAmmoField(weapon, offset);
      if current == ammo {
        return true;
      }
      if NativeAmmo.IsAmmo(current) && AO_WriteAmmoField(weapon, offset, current, ammo) {
        previous = current;
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
          previous = recordAmmo;
          return true;
        }
        AO_WriteAmmoField(weapon, candidate, ammo, recordAmmo);
      }
    }
    return false;
  }

  // The wanted ammo, once the loaded ammo (at `offset`) has been changed from `previous`.
  private static func ApplyWanted(weapon: ref<WeaponObject>, ammo: TweakDBID, offset: Int32, previous: TweakDBID, out wantedOffset: Int32) -> Void {
    if wantedOffset > 0 {
      let current: TweakDBID = AO_ReadAmmoField(weapon, wantedOffset);
      if current == ammo || (NativeAmmo.IsAmmo(current) && AO_WriteAmmoField(weapon, wantedOffset, current, ammo)) {
        return;
      }
      AmmoFeedSystem.Log("wanted ammo field at " + IntToString(wantedOffset) + " holds " + TDBID.ToStringDEBUG(current) + ", locating it again");
      wantedOffset = 0;
    }
    let old: TweakDBID = previous != ammo ? previous : NativeAmmo.RecordAmmo(weapon);
    if old == ammo {
      return;
    }
    let pending: Bool = weapon.HasAmmoChangeRequest();
    for candidate in AO_FindAmmoFields(weapon, old) {
      if candidate != offset && AO_WriteAmmoField(weapon, candidate, old, ammo) {
        if !pending {
          // Nothing to verify against: keep the write, locate again next time.
          return;
        }
        if !weapon.HasAmmoChangeRequest() {
          AmmoFeedSystem.Log("wanted ammo field located at " + IntToString(candidate));
          wantedOffset = candidate;
          return;
        }
        AO_WriteAmmoField(weapon, candidate, ammo, old);
      }
    }
  }

  // Empties the magazine of `weapon` without touching the inventory, by writing the magazine
  // count that follows the ammo field (+0x10 on 2.50). Only if that field holds the count the
  // engine reports and the next one the capacity, so a different layout fails instead of
  // writing somewhere else.
  public static func Unload(owner: ref<GameObject>, weapon: ref<WeaponObject>, ammoOffset: Int32) -> Bool {
    if ammoOffset <= 0 {
      return false;
    }
    let magOffset: Int32 = ammoOffset + 16;
    let mag: Int32 = Cast<Int32>(WeaponObject.GetMagazineAmmoCount(weapon));
    let capacity: Int32 = Cast<Int32>(WeaponObject.GetMagazineCapacity(weapon));
    if capacity <= 0 || AO_ReadInt32(weapon, magOffset) != mag || AO_ReadInt32(weapon, magOffset + 4) != capacity {
      return false;
    }
    if mag == 0 {
      return true;
    }
    if !AO_WriteInt32(weapon, magOffset, mag, 0) {
      return false;
    }
    weapon.GetSharedData().SetUint(GetAllBlackboardDefs().Weapon.MagazineAmmoCount, 0u);
    WeaponObject.SendAmmoUpdateEvent(owner, weapon);
    return true;
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

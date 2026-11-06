module AmmoOverhaul

// Vanilla magazine refunds keep the gun's round. Shinobi 50's 20% on a dash or slide
// (CeaselessLeadAmmoEffector, Proficiencies.Reflexes_50) and ValentinosFrenzyEffector refill
// through a SetAmmoCountEvent of WeaponObject.GetAmmoType, which is the weapon record's ammo: the
// caliber's default round. The engine loaded that instead, and the safety net in AmmoFeedSystem
// then emptied the gun. While a refund runs, V's guns answer GetAmmoType with the round they're
// loaded with. Everywhere else it stays the record's ammo (the vehicle top-up gives that round
// free).

@addField(WeaponObject)
public let aoRefunding: Bool;

public abstract class MagRefill {

  public static func Mark(owner: ref<GameObject>, on: Bool) -> Void {
    if !IsDefined(owner as PlayerPuppet) {
      return;
    }
    for weapon in ScriptedPuppet.GetActiveWeapons(owner) {
      if IsDefined(weapon) {
        weapon.aoRefunding = on;
      }
    }
  }
}

@wrapMethod(CeaselessLeadAmmoEffector)
private final func ProcessAction(owner: ref<GameObject>) -> Void {
  MagRefill.Mark(owner, true);
  wrappedMethod(owner);
  MagRefill.Mark(owner, false);
}

@wrapMethod(ValentinosFrenzyEffector)
private final func ProcessAction(owner: ref<GameObject>) -> Void {
  MagRefill.Mark(owner, true);
  wrappedMethod(owner);
  MagRefill.Mark(owner, false);
}

@wrapMethod(WeaponObject)
public final static func GetAmmoType(weapon: wref<WeaponObject>) -> ItemID {
  if IsDefined(weapon) && weapon.aoRefunding {
    let ammo: TweakDBID = AOData.LoadedAmmo(weapon.GetOwner(), weapon);
    if TDBID.IsValid(ammo) {
      return ItemID.CreateQuery(ammo);
    }
  }
  return wrappedMethod(weapon);
}

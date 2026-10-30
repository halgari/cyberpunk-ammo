module AmmoOverhaul

// Mule Kick rounds (Legendary; <ammo>.aoMuleKick, docs/superpowers/specs/2026-10-29-legendary-rounds-design.md):
//   - each of V's shots shoves V away from the aim, with the push jump pads use (PSMImpulse):
//     forward, V goes back; at the floor, V goes up. NPCs firing it don't move;
//   - a hit knocks the target down; Elite, Boss and MaxTac NPCs stagger instead. A hit on V knocks
//     V down.
// Every pellet that lands comes through OnHit, so one effect per target per shot.

@addField(ScriptedPuppet)
public let aoMuleKickAt: Float;

public abstract class MuleKick {

  // A shot's pellets land together; anything this far apart is another shot.
  public static func Gate() -> Float {
    return 0.3;
  }

  // What a hit does to an NPC of `rarity`.
  public static func NpcEffect(rarity: String) -> TweakDBID {
    let tough: Bool = Equals(rarity, "Elite") || Equals(rarity, "Boss") || Equals(rarity, "MaxTac");
    return tough ? t"BaseStatusEffect.ForceStagger" : t"BaseStatusEffect.Knockdown";
  }

  // V fired: from ShootEvents.OnEnter, the shooting state, so only a shot that really goes off.
  public static func OnShot(player: ref<PlayerPuppet>, weapon: ref<WeaponObject>) -> Void {
    if !IsDefined(player) || !IsDefined(weapon) || !AOData.MuleKick(AOData.LoadedAmmo(player, weapon)) {
      return;
    }
    if VehicleComponent.IsMountedToVehicle(player.GetGame(), player) {
      return;
    }
    MuleKick.Shove(player);
  }

  public static func Shove(player: ref<PlayerPuppet>) -> Void {
    let event: ref<PSMImpulse> = new PSMImpulse();
    event.id = n"impulse";
    event.impulse = GameInstance.GetCameraSystem(player.GetGame()).GetActiveCameraForward() * -TweakDBInterface.GetFloat(t"AmmoOverhaul.muleKickShove", 14.0);
    player.QueueEvent(event);
    AmmoFeedSystem.Log("mule kick: V shoved");
  }

  // A Mule Kick hit (from AmmoFeedSystem.ApplyAmmoOnHit).
  public static func OnHit(attackData: ref<AttackData>, target: ref<GameObject>) -> Void {
    let puppet: ref<ScriptedPuppet> = target as ScriptedPuppet;
    if !IsDefined(puppet) {
      return;
    }
    let now: Float = CookOff.Now(puppet.GetGame());
    if puppet.aoMuleKickAt > 0.0 && now - puppet.aoMuleKickAt < MuleKick.Gate() {
      return;
    }
    puppet.aoMuleKickAt = now;
    let npc: ref<NPCPuppet> = puppet as NPCPuppet;
    let rarity: String = IsDefined(npc) ? EnumValueToString("gamedataNPCRarity", Cast<Int64>(EnumInt(npc.GetNPCRarity()))) : "";
    attackData.AddStatusEffect(MuleKick.NpcEffect(rarity), 1.0);
  }
}

@wrapMethod(ShootEvents)
protected final func OnEnter(stateContext: ref<StateContext>, scriptInterface: ref<StateGameScriptInterface>) -> Void {
  wrappedMethod(stateContext, scriptInterface);
  MuleKick.OnShot(scriptInterface.executionOwner as PlayerPuppet, this.GetWeaponObject(scriptInterface));
}

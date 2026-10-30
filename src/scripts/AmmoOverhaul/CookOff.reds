module AmmoOverhaul

// Cook-off rounds (Legendary; <ammo>.aoCookOff, docs/superpowers/specs/2026-10-29-legendary-rounds-design.md):
//   - a kill with one sets off a blast at the body (AmmoOverhaul.CookOffBlast, core.yaml: 35% of
//     each target's max health), which hurts everyone near it, V included;
//   - a hit on V sets off the grenade V has selected, on V, if it has a charge: its own attack for
//     the look and effects (a script-started grenade attack does little damage), the Cook-off blast
//     for the damage, and one charge taken off.
// Both go off a frame later, outside the hit that caused them. Any later hit clears the mark, so a
// kill by a blast (or anything else after the Cook-off hit) sets off nothing more.

// When this NPC last took a Cook-off hit, and from whom; a death right after it is that hit's kill.
@addField(NPCPuppet)
public let aoCookOffAt: Float;

@addField(NPCPuppet)
public let aoCookOffBy: wref<GameObject>;

// When V's grenade last cooked off.
@addField(PlayerPuppet)
public let aoCookedAt: Float;

public abstract class CookOff {

  public static func Now(game: GameInstance) -> Float {
    return EngineTime.ToFloat(GameInstance.GetSimTime(game));
  }

  public static func Clear(target: ref<GameObject>) -> Void {
    let npc: ref<NPCPuppet> = target as NPCPuppet;
    if IsDefined(npc) {
      npc.aoCookOffAt = 0.0;
    }
  }

  // A Cook-off hit by `instigator` on `target` (from AmmoFeedSystem.ApplyAmmoOnHit).
  public static func OnHit(instigator: ref<GameObject>, target: ref<GameObject>) -> Void {
    let npc: ref<NPCPuppet> = target as NPCPuppet;
    if IsDefined(npc) {
      npc.aoCookOffAt = CookOff.Now(npc.GetGame());
      npc.aoCookOffBy = instigator;
      return;
    }
    let player: ref<PlayerPuppet> = target as PlayerPuppet;
    if IsDefined(player) {
      CookOffCallback.Schedule(instigator, player, player.GetWorldPosition(), true);
    }
  }

  public static func OnDeath(npc: ref<NPCPuppet>) -> Void {
    if npc.aoCookOffAt <= 0.0 || CookOff.Now(npc.GetGame()) - npc.aoCookOffAt > 0.5 {
      return;
    }
    npc.aoCookOffAt = 0.0;
    let instigator: ref<GameObject> = npc.aoCookOffBy;
    CookOffCallback.Schedule(IsDefined(instigator) ? instigator : npc, npc, npc.GetWorldPosition(), false);
  }

  public static func Blast(instigator: ref<GameObject>, source: ref<GameObject>, attack: TweakDBID, at: Vector4) -> Void {
    let effect: ref<Attack_GameEffect> = RPGManager.PrepareGameEffectAttack(source.GetGame(), instigator, source, attack, at);
    if IsDefined(effect) {
      effect.StartAttack();
    }
  }

  // One grenade throw's cost from the `GrenadesCharges` pool, as the game takes it for a throw
  // (perks can halve it for some grenades).
  public static func ChargeSize(player: ref<PlayerPuppet>) -> Float {
    return Cast<Float>(player.GetGrenadeThrowCost());
  }

  // Sets off V's selected grenade on V if it has a charge; false (nothing done) otherwise.
  public static func CookPlayerGrenade(instigator: ref<GameObject>, player: ref<PlayerPuppet>) -> Bool {
    let gadget: ItemID = EquipmentSystem.GetData(player).GetActiveGadget();
    if !ItemID.IsValid(gadget) {
      return false;
    }
    let attack: TweakDBID = TweakDBInterface.GetForeignKey(AOData.Flat(ItemID.GetTDBID(gadget), "attack"), TDBID.None());
    let pools: ref<StatPoolsSystem> = GameInstance.GetStatPoolsSystem(player.GetGame());
    let id: StatsObjectID = Cast<StatsObjectID>(player.GetEntityID());
    let charge: Float = CookOff.ChargeSize(player);
    if charge <= 0.0 || pools.GetStatPoolValue(id, gamedataStatPoolType.GrenadesCharges, false) < charge - 0.01 {
      return false;
    }
    // Several hits in one frame each queue a cook-off; the pool change may not be in yet, so one
    // per half second.
    let now: Float = CookOff.Now(player.GetGame());
    if player.aoCookedAt > 0.0 && now - player.aoCookedAt < 0.5 {
      return false;
    }
    player.aoCookedAt = now;
    pools.RequestChangingStatPoolValue(id, gamedataStatPoolType.GrenadesCharges, -charge, player, false, false);
    ConsumablesChargesHelper.HotkeyRefresh(player.GetGame());
    let at: Vector4 = player.GetWorldPosition();
    at.Z += 1.0;
    if TDBID.IsValid(attack) {
      CookOff.Blast(instigator, player, attack, at);
    }
    CookOff.Blast(instigator, player, t"AmmoOverhaul.CookOffBlast", at);
    AmmoFeedSystem.Log("cook-off: V's " + TDBID.ToStringDEBUG(ItemID.GetTDBID(gadget)) + " went off");
    return true;
  }
}

public class CookOffCallback extends DelayCallback {
  public let instigator: wref<GameObject>;
  public let target: wref<GameObject>;
  public let at: Vector4;
  public let onPlayer: Bool;

  public static func Schedule(instigator: ref<GameObject>, target: ref<GameObject>, at: Vector4, onPlayer: Bool) -> Void {
    let callback: ref<CookOffCallback> = new CookOffCallback();
    callback.instigator = instigator;
    callback.target = target;
    callback.at = at;
    callback.onPlayer = onPlayer;
    GameInstance.GetDelaySystem(target.GetGame()).DelayCallback(callback, 0.0, false);
  }

  public func Call() -> Void {
    let instigator: ref<GameObject> = this.instigator;
    let target: ref<GameObject> = this.target;
    if !IsDefined(target) {
      return;
    }
    if !IsDefined(instigator) {
      instigator = target;
    }
    if this.onPlayer {
      CookOff.CookPlayerGrenade(instigator, target as PlayerPuppet);
      return;
    }
    let at: Vector4 = this.at;
    at.Z += 0.5;
    CookOff.Blast(instigator, target, t"AmmoOverhaul.CookOffBlast", at);
    AmmoFeedSystem.Log("cook-off: blast at " + TDBID.ToStringDEBUG((target as NPCPuppet).GetRecordID()));
  }
}

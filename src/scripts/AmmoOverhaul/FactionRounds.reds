module AmmoOverhaul

// Faction rounds (docs/superpowers/specs/2026-10-30-faction-rounds-design.md): rounds of tiers 5 to
// 8 (Rare, Epic, Common and Uncommon quality) that only NPCs of their faction roll (AOData.FactionOf) and that reach V as their loot. Most
// are stats and hit data like any round. What's here:
//   - the faction roll, and what a gun shop on the faction's turf adds to its stock;
//   - Redliners (<ammo>.aoSelfJam): a shot can jam the shooter's own gun, V's or an NPC's;
//   - Parts-pullers (<ammo>.aoPartsPuller): V's kill leaves crafting components of the round's
//     grade on the body. An NPC firing one gets nothing from it;
//   - Santa Muerte (<ammo>.aoHeadEffect): a status effect on a headshot;
//   - Cease and Desist (<ammo>.aoStopChance) and Leg Day (<ammo>.aoLegChance): a stagger or crippled
//     legs, per shot and by the target's rank;
//   - Protein Loads (<ammo>.aoPumped): a kill stacks AmmoOverhaul.Pumped on the shooter, V or NPC.

// The Parts-pullers round that last hit this NPC and when; a death right after it is that hit's kill.
@addField(NPCPuppet)
public let aoPartsAt: Float;

@addField(NPCPuppet)
public let aoPartsAmmo: TweakDBID;

// The kill's round, until the components are in the body's loot.
@addField(NPCPuppet)
public let aoPartsKill: TweakDBID;

// The Protein Loads shooter that last hit this NPC and when, read like the Parts-pullers mark.
@addField(NPCPuppet)
public let aoPumpAt: Float;

@addField(NPCPuppet)
public let aoPumpBy: wref<GameObject>;

public abstract class FactionRounds {

  // A faction's selectors for `caliber` below Epic, of any of those tiers: one bucket for the NPC
  // roll, so a Scav's rounds come up alike whatever their quality.
  private static func BelowEpic(caliber: String, faction: String) -> array<TweakDBID> {
    let selectors: array<TweakDBID>;
    for tier in [5, 7, 8] {
      for selector in AOData.SelectorsForFaction(caliber, faction, tier) {
        ArrayPush(selectors, selector);
      }
    }
    return selectors;
  }

  // A faction round for a gun of `caliber`, invalid if the rolls miss: Epic with its own chance, then
  // the rest. Each of a roll's rounds is as likely.
  public static func Roll(caliber: String, rarity: String, faction: String) -> TweakDBID {
    if StrLen(faction) == 0 {
      return TDBID.None();
    }
    let epic: array<TweakDBID> = AOData.SelectorsForFaction(caliber, faction, 6);
    if ArraySize(epic) > 0 && RandF() < AOData.FactionChance(rarity, faction, true) {
      return epic[RandRange(0, ArraySize(epic))];
    }
    let rest: array<TweakDBID> = FactionRounds.BelowEpic(caliber, faction);
    if ArraySize(rest) > 0 && RandF() < AOData.FactionChance(rarity, faction, false) {
      return rest[RandRange(0, ArraySize(rest))];
    }
    return TDBID.None();
  }

  // What a turf gun shop adds to a stock it builds: its faction's Common-quality rounds every time,
  // and now and then one or two stacks of the Uncommon and Rare ones, or of the rounds the shop lists
  // itself (<vendor>.aoTurfAmmo: Arasaka's Shinobi, the one Epic any shop sells), in its own stack size.
  public static func TurfStock(vendor: TweakDBID, faction: String) -> array<AOStack> {
    let stacks: array<AOStack>;
    let extras: array<TweakDBID> = AOData.GetIDs(AOData.Flat(vendor, "aoTurfAmmo"));
    let size: Int32 = TweakDBInterface.GetInt(AOData.Flat(vendor, "aoTurfStack"), TweakDBInterface.GetInt(t"AmmoOverhaul.turfStack", 30));
    for caliber in AOData.Calibers() {
      for selector in AOData.SelectorsForFaction(caliber, faction, 7) {
        ArrayPush(stacks, AOStack(AOData.SelectorAmmo(caliber, selector), size));
      }
      for tier in [5, 8] {
        for selector in AOData.SelectorsForFaction(caliber, faction, tier) {
          ArrayPush(extras, AOData.SelectorAmmo(caliber, selector));
        }
      }
    }
    if ArraySize(extras) > 0 && RandF() < TweakDBInterface.GetFloat(t"AmmoOverhaul.turfChance", 0.25) {
      let count: Int32 = Min(RandRange(1, 3), ArraySize(extras));
      while count > 0 {
        let at: Int32 = RandRange(0, ArraySize(extras));
        ArrayPush(stacks, AOStack(extras[at], size));
        ArrayErase(extras, at);
        count -= 1;
      }
    }
    return stacks;
  }

  // `shooter` fired a round of `ammo`: from ShootEvents.OnEnter for V, NpcAmmo.TakeShot for NPCs.
  public static func OnShot(shooter: ref<GameObject>, ammo: TweakDBID) -> Void {
    let chance: Float = AOData.SelfJam(ammo);
    if chance > 0.0 && RandF() < chance {
      StatusEffectHelper.ApplyStatusEffect(shooter, t"AmmoOverhaul.RedlinerJam");
      AmmoFeedSystem.Log("redliner: " + TDBID.ToStringDEBUG(ammo) + " jammed its gun");
    }
  }

  public static func ClearParts(target: ref<GameObject>) -> Void {
    let npc: ref<NPCPuppet> = target as NPCPuppet;
    if IsDefined(npc) {
      npc.aoPartsAt = 0.0;
      npc.aoPumpAt = 0.0;
    }
  }

  // V hit `target` with a Parts-pullers round (from AmmoFeedSystem.ApplyAmmoOnHit).
  public static func MarkParts(target: ref<GameObject>, ammo: TweakDBID) -> Void {
    let npc: ref<NPCPuppet> = target as NPCPuppet;
    if IsDefined(npc) {
      npc.aoPartsAt = CookOff.Now(npc.GetGame());
      npc.aoPartsAmmo = ammo;
    }
  }

  // `shooter` hit `target` with a Protein Loads round (from AmmoFeedSystem.ApplyAmmoOnHit).
  public static func MarkPump(target: ref<GameObject>, shooter: ref<GameObject>) -> Void {
    let npc: ref<NPCPuppet> = target as NPCPuppet;
    if IsDefined(npc) {
      npc.aoPumpAt = CookOff.Now(npc.GetGame());
      npc.aoPumpBy = shooter;
    }
  }

  // Whether Cease and Desist staggers an NPC of `rarity`.
  public static func Stops(rarity: String) -> Bool {
    return !Equals(rarity, "Boss") && !Equals(rarity, "MaxTac");
  }

  // What Cease and Desist does to `rarity`, empty for V: ForceStagger never ends on V and plays
  // nothing there, BlockBroken is V's own stagger.
  public static func StopEffect(rarity: String) -> TweakDBID {
    return StrLen(rarity) == 0 ? t"BaseStatusEffect.BlockBroken" : t"BaseStatusEffect.ForceStagger";
  }

  // What Leg Day does to `rarity`, empty for V, who goes down. Machines have no legs to cripple.
  public static func LegEffect(rarity: String, mechanical: Bool) -> TweakDBID {
    if StrLen(rarity) == 0 {
      return t"BaseStatusEffect.Knockdown";
    }
    let tough: Bool = Equals(rarity, "Elite") || Equals(rarity, "Boss") || Equals(rarity, "MaxTac");
    return tough || mechanical ? t"BaseStatusEffect.ForceStagger" : t"AmmoOverhaul.CrippledLegs";
  }

  // A hit by any gun that passed the effect gate (from AmmoFeedSystem.ApplyAmmoOnHit). Each pellet
  // that lands comes through here; the Mule Kick gate keeps it to one stagger or cripple per shot.
  public static func OnHit(attackData: ref<AttackData>, target: ref<GameObject>, ammo: TweakDBID, pellets: Int32) -> Void {
    let puppet: ref<ScriptedPuppet> = target as ScriptedPuppet;
    if !IsDefined(puppet) {
      return;
    }
    let head: TweakDBID = AOData.HeadEffect(ammo);
    if TDBID.IsValid(head) {
      if target.IsPlayer() && (attackData.HasFlag(hitFlag.Headshot) || RandF() < AOData.HeadFallback(ammo)) {
        attackData.AddStatusEffect(AOData.PlayerEffect(head), 1.0);
      } else {
        if !target.IsPlayer() && attackData.HasFlag(hitFlag.Headshot) {
          attackData.AddStatusEffect(head, 1.0);
        }
      }
    }
    let stop: Float = AOData.StopChance(ammo);
    let legs: Float = AOData.LegChance(ammo);
    if stop <= 0.0 && legs <= 0.0 || target.IsDrone() {
      return;
    }
    let now: Float = CookOff.Now(puppet.GetGame());
    if puppet.aoMuleKickAt > 0.0 && now - puppet.aoMuleKickAt < MuleKick.Gate() {
      return;
    }
    let rarity: String = MuleKick.Rarity(puppet);
    if stop > 0.0 && FactionRounds.Stops(rarity) && RandF() < AOData.PelletChance(stop, pellets) {
      puppet.aoMuleKickAt = now;
      attackData.AddStatusEffect(FactionRounds.StopEffect(rarity), 1.0);
    }
    if legs > 0.0 && RandF() < AOData.PelletChance(legs, pellets) {
      puppet.aoMuleKickAt = now;
      attackData.AddStatusEffect(FactionRounds.LegEffect(rarity, puppet.IsMechanical()), 1.0);
    }
  }

  public static func OnDeath(npc: ref<NPCPuppet>) -> Void {
    if npc.aoPumpAt > 0.0 && CookOff.Now(npc.GetGame()) - npc.aoPumpAt <= 0.5 && IsDefined(npc.aoPumpBy) {
      StatusEffectHelper.ApplyStatusEffect(npc.aoPumpBy, t"AmmoOverhaul.Pumped");
      AmmoFeedSystem.Log("protein loads: pumped " + TDBID.ToStringDEBUG(npc.GetRecordID()));
    }
    npc.aoPumpAt = 0.0;
    if npc.aoPartsAt <= 0.0 || CookOff.Now(npc.GetGame()) - npc.aoPartsAt > 0.5 {
      return;
    }
    npc.aoPartsAt = 0.0;
    npc.aoPartsKill = npc.aoPartsAmmo;
  }

  // Puts a kill's components on the body, after death has wiped its inventory (NpcAmmo.TopUpLoot).
  public static func GiveParts(npc: ref<NPCPuppet>) -> Void {
    if !TDBID.IsValid(npc.aoPartsKill) {
      return;
    }
    let quality: gamedataQuality = TweakDBInterface.GetItemRecord(npc.aoPartsKill).Quality().Type();
    let parts: TweakDBID = RPGManager.GetCraftingMaterialRecord(quality).GetID();
    npc.aoPartsKill = TDBID.None();
    GameInstance.GetTransactionSystem(npc.GetGame()).GiveItem(npc, ItemID.CreateQuery(parts), TweakDBInterface.GetInt(t"AmmoOverhaul.partsPullerGive", 2));
    AmmoFeedSystem.Log("parts-pullers: components left on " + TDBID.ToStringDEBUG(npc.GetRecordID()));
  }
}

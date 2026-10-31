module AmmoOverhaul

// Faction rounds (docs/superpowers/specs/2026-10-30-faction-rounds-design.md): rounds of tiers 5 to
// 8 (Rare, Epic, Common and Uncommon quality) that only NPCs of their faction roll (AOData.FactionOf) and that reach V as their loot. Most
// are stats and hit data like any round. What's here:
//   - the faction roll, and what a gun shop on the faction's turf adds to its stock;
//   - Redliners (<ammo>.aoSelfJam): a shot can jam the shooter's own gun, V's or an NPC's;
//   - Parts-pullers (<ammo>.aoPartsPuller): V's kill leaves crafting components of the round's
//     grade on the body. An NPC firing one gets nothing from it.

// The Parts-pullers round that last hit this NPC and when; a death right after it is that hit's kill.
@addField(NPCPuppet)
public let aoPartsAt: Float;

@addField(NPCPuppet)
public let aoPartsAmmo: TweakDBID;

// The kill's round, until the components are in the body's loot.
@addField(NPCPuppet)
public let aoPartsKill: TweakDBID;

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
  // and now and then one or two stacks of the Uncommon and Rare ones. Nobody sells Epic.
  public static func TurfStock(faction: String) -> array<AOStack> {
    let stacks: array<AOStack>;
    let extras: array<TweakDBID>;
    let size: Int32 = TweakDBInterface.GetInt(t"AmmoOverhaul.turfStack", 30);
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

  public static func OnDeath(npc: ref<NPCPuppet>) -> Void {
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

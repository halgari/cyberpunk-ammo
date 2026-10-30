module AmmoOverhaul

// Faction rounds (docs/superpowers/specs/2026-10-30-faction-rounds-design.md): rounds of tiers 5, 6
// and 7 that only NPCs of their faction roll (AOData.FactionOf) and that reach V as their loot. Most
// are stats and hit data like any round. What's here:
//   - the faction roll;
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

  // A faction round for a gun of `caliber`, invalid if the rolls miss: Epic with its own chance, then
  // Rare, which takes in the faction's Common rounds. Each of a roll's rounds is as likely.
  public static func Roll(caliber: String, rarity: String, faction: String) -> TweakDBID {
    if StrLen(faction) == 0 {
      return TDBID.None();
    }
    let epic: array<TweakDBID> = AOData.SelectorsForFaction(caliber, faction, 6);
    if ArraySize(epic) > 0 && RandF() < AOData.FactionChance(rarity, true) {
      return epic[RandRange(0, ArraySize(epic))];
    }
    let rare: array<TweakDBID> = AOData.SelectorsForFaction(caliber, faction, 5);
    for selector in AOData.SelectorsForFaction(caliber, faction, 7) {
      ArrayPush(rare, selector);
    }
    if ArraySize(rare) > 0 && RandF() < AOData.FactionChance(rarity, false) {
      return rare[RandRange(0, ArraySize(rare))];
    }
    return TDBID.None();
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

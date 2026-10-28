-- Spawns a test NPC 8 m in front of an invulnerable player, tagged AO_Test.
-- Set REC first to pick the record. Then run npc-fight.lua to make it hostile.
local p = Game.GetPlayer()
Game.GetGodModeSystem():AddGodMode(p:GetEntityID(), gameGodModeType.Invulnerable, CName.new("AO_Test"))
local spec = DynamicEntitySpec.new()
spec.recordID = TweakDBID.new(REC or "Character.dtn_tyger_claws_biker1_ranged1_nue_wa")
local pos, fwd = p:GetWorldPosition(), p:GetWorldForward()
spec.position = Vector4.new(pos.x + fwd.x * 8, pos.y + fwd.y * 8, pos.z, 1)
spec.orientation = EulerAngles.ToQuat(EulerAngles.new(0, 0, 0))
spec.alwaysSpawned = true
spec.tags = { "AO_Test" }
print("spawning", Game.GetDynamicEntitySystem():CreateEntity(spec))

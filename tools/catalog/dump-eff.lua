local function s(id) return id and TDBID.ToStringDEBUG(id) or "" end
local f=io.open("effectors.tsv","w")
local want={gamedataTriggerAttackEffector_Record={"attackRecord","attackPositionSlotName"},gamedataAddHitFlagToAttackEffector_Record={"hitFlag"},gamedataOverrideRangedAttackPackageEffector_Record={"attackPackage"},gamedataAddStatusEffectToAttackEffector_Record={"statusEffect","isRandom","applicationChance"},gamedataApplyStatusEffectEffector_Record={"statusEffect"},gamedataApplyStatusEffectByChanceEffector_Record={"statusEffect","chance"},gamedataModifyAttackCritChanceEffector_Record={"value"}}
for cls,fields in pairs(want) do
  for _,r in ipairs(TweakDB:GetRecords(cls)) do
    local id=s(r:GetID()); local out={cls,id}
    for _,fl in ipairs(fields) do local v=TweakDB:GetFlat(id.."."..fl); if type(v)=="userdata" and pcall(function() return TDBID.ToStringDEBUG(v) end) then v=TDBID.ToStringDEBUG(v) end; table.insert(out, fl.."="..tostring(v)) end
    f:write(table.concat(out,"\t").."\n")
  end
end
-- status effects
for _,r in ipairs(TweakDB:GetRecords("gamedataStatusEffect_Record")) do
  local id=s(r:GetID()); local t=r:StatusEffectType() and tostring(r:StatusEffectType():Type()) or ""
  f:write("SE\t"..id.."\t"..t.."\n")
end
-- attacks
for _,cl in ipairs({"gamedataAttack_GameEffect_Record","gamedataAttack_Projectile_Record","gamedataAttack_Record"}) do
  for _,r in ipairs(TweakDB:GetRecords(cl)) do f:write("ATK\t"..cl.."\t"..s(r:GetID()).."\n") end
end
f:close() print("ok")

local ids={"Items.Preset_Achilles_Default","Items.Preset_Ajax_Default","Items.Preset_Ashura_Default","Items.Preset_Borg4a_Default","Items.Preset_Burya_Default","Items.Preset_Carnage_Default","Items.Preset_Chao_Default","Items.Preset_Copperhead_Default","Items.Preset_Crusher_Default","Items.Preset_Defender_Default","Items.Preset_Dian_Default","Items.Preset_Grad_Default","Items.Preset_Grit_Default","Items.Preset_Guillotine_Default","Items.Preset_Hercules_Default","Items.Preset_HMG_Default","Items.Preset_Igla_Default","Items.Preset_Kappa_Default","Items.Preset_Kenshin_Default","Items.Preset_Kolac_Default","Items.Preset_Kyubi_Default","Items.Preset_Lexington_Default","Items.Preset_Liberty_Default","Items.Preset_MA70_Default","Items.Preset_Masamune_Default","Items.Preset_Metel_Default","Items.Preset_Nekomata_Default","Items.Preset_Nova_Default","Items.Preset_Nue_Default","Items.Preset_Omaha_Default","Items.Preset_Osprey_Default","Items.Preset_Overture_Default","Items.Preset_Palica_Default","Items.Preset_Pozhar_Default","Items.Preset_Pulsar_Default","Items.Preset_Quasar_Default","Items.Preset_Saratoga_Default","Items.Preset_Satara_Default","Items.Preset_Senkoh_Default","Items.Preset_Shingen_Default","Items.Preset_Sidewinder_Default","Items.Preset_Sor22_Default","Items.Preset_Tactician_Default","Items.Preset_Testera_Default","Items.Preset_Ticon_Default","Items.Preset_Umbra_Default","Items.Preset_Unity_Default","Items.Preset_Warden_Default","Items.Preset_Yukimura_Default","Items.Preset_Zhuo_Default","Items.Preset_Rasetsu_Prototype","Items.Preset_Silverhand_3516"}
local st={"MagazineCapacity","DamagePerHit","ProjectilesPerShot","CycleTime","AttacksPerSecond","EffectiveRange","ReloadTime","EmptyReloadTime","RicochetCount","ChargeTime","FullAutoOnFullCharge","NumShotsToFire","PhysicalDamage","ThermalDamage","ElectricDamage","ChemicalDamage","CritChance","HeadshotDamageMultiplier","SmartGunProjectileVelocity","SmartGunTargetAcquisitionRange","CanWeaponIgnoreArmor","TechPierceChargeLevel","Weight","RecoilKickMax","SpreadDefaultX"}

local p=Game.GetPlayer(); local ts=Game.GetTransactionSystem(); local ss=Game.GetStatsSystem()
local f=io.open("stats.tsv","w"); f:write("id\t"..table.concat(st,"\t").."\n")
for _,id in ipairs(ids) do
  if TweakDB:GetRecord(id) then
    local iid=ItemID.FromTDBID(id)
    ts:GiveItem(p, iid, 1)
    local d=ts:GetItemData(p, iid)
    local row={id}
    for _,s in ipairs(st) do local ok,v=pcall(function() return d:GetStatValueByType(gamedataStatType[s]) end); table.insert(row, ok and string.format("%.3g", v) or "?") end
    f:write(table.concat(row,"\t").."\n")
    ts:RemoveItem(p, iid, 1)
  end
end
f:close() print("done")

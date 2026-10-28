-- Task 5: NPCs carry their gun's Uncommon round when they roll it. Run by npc.sh after spawning
-- plain and fitted test gangers and letting them draw. Prints each test NPC, then asserts.
local ts = Game.GetTransactionSystem()
local FEEDS = { Lexington = "AttachmentSlots.AO_AmmoFeed_Power_9mm", Omaha = "AttachmentSlots.AO_AmmoFeed_Tech_Light",
  Yukimura = "AttachmentSlots.AO_AmmoFeed_Smart_10" }
local SEL_AMMO = { ["Items.AO_Feed_9mm_Mushrooms"] = "Ammo.AO_9mm_HollowPoint", ["Items.AO_Feed_5mm_Sleevers"] = "Ammo.AO_TLight_Sabot",
  ["Items.AO_Feed_10mm_Dumbfires"] = "Ammo.AO_S10_Dumbfire" }
local DEFAULT = { Lexington = "Ammo.HandgunAmmo", Omaha = "Ammo.AO_TLight_Slug", Yukimura = "Ammo.AO_S10_Standard" }
local UNCOMMON = { Lexington = "Ammo.AO_9mm_HollowPoint", Omaha = "Ammo.AO_TLight_Sabot", Yukimura = "Ammo.AO_S10_Dumbfire" }
-- NPC guns have no DamagePerHit (NPC damage comes from elsewhere), so check a stat each Uncommon
-- changes that NPC guns do carry: stat name, Uncommon value relative to Common ("+" = difference,
-- "x" = ratio, "~" = only different: NPC Omahas have a ChargeTime of 0, so a ratio means nothing).
local STAT = { Lexington = { "CanWeaponIgnoreArmor", "+", -0.5 }, Omaha = { "ChargeTime", "~", 0 },
  Yukimura = { "SmartGunHitProbability", "x", 0 } }
local plainUncommon, plainCommon, drawn = 0, 0, 0
local damage = {}  -- gun -> { common = stat, uncommon = stat } of plain gangers (STAT[gun])
local list = Game.GetDynamicEntitySystem():GetTagged("AO_Test")
AO_EXPECT = {}  -- entity hash -> the one round its body should drop (npcloot.lua)
for _, npc in ipairs(list) do
  local recName = str(npc:GetRecordID())
  local w = ScriptedPuppet.GetActiveWeapon(npc)
  if w then
    drawn = drawn + 1
    local gunName = str(w:GetItemID().id)
    local gun = gunName:match("Preset_(%a+)_")
    local d = ts:GetItemData(npc, w:GetItemID())
    local slot = TweakDBID.new(FEEDS[gun] or "")
    local part = "none"
    if d and d:HasPartInSlot(slot) then part = str(d:GetItemPart(slot):GetItemID().id) end
    local _, items = ts:GetItemList(npc)
    local ammo = {}
    for _, it in ipairs(items or {}) do
      local n = str(it:GetID().id)
      if n:find("^Ammo%.") then ammo[n] = ts:GetItemQuantity(npc, it:GetID()) end
    end
    local stacks = {}
    for n, q in pairs(ammo) do table.insert(stacks, n .. " " .. q) end
    print(recName .. " | " .. gunName .. " | feed " .. part .. " | " .. table.concat(stacks, ", "))
    local expected = SEL_AMMO[part] or DEFAULT[gun]
    if recName:find("AO_Test_Plain_") and ammo[UNCOMMON[gun]] then expected = UNCOMMON[gun] end
    local dmg = STAT[gun] and Game.GetStatsSystem():GetStatValue(d:GetStatsObjectID(), gamedataStatType[STAT[gun][1]]) or 0
    print("    " .. (STAT[gun] and STAT[gun][1] or "-") .. " " .. dmg)
    AO_EXPECT[tostring(npc:GetEntityID().hash)] = { name = recName, ammo = expected }
    check(recName .. " carries its gun's round", expected and ammo[expected] and ammo[expected] > 0, "expected " .. tostring(expected))
    local others = 0
    for n, _ in pairs(ammo) do if n ~= expected then others = others + 1 end end
    check(recName .. " carries no other round", others == 0)
    if recName:find("AO_Test_Plain_") then
      check(recName .. " has no part fitted", part == "none", part)
      damage[gun] = damage[gun] or {}
      if expected == UNCOMMON[gun] then
        plainUncommon = plainUncommon + 1; damage[gun].uncommon = dmg
      else
        plainCommon = plainCommon + 1; damage[gun].common = dmg
      end
    else
      check(recName .. " keeps its preset Uncommon", SEL_AMMO[part] ~= nil, part)
    end
  end
end
check("test NPCs drawn", drawn > 0, tostring(#list) .. " tagged")
for gun, d in pairs(damage) do
  local st = STAT[gun]
  if d.common and d.uncommon then
    local ok
    if st[2] == "~" then ok = math.abs(d.uncommon - d.common) > 0.001
    else
      local got = st[2] == "+" and d.uncommon - d.common or (d.common ~= 0 and d.uncommon / d.common or d.uncommon)
      ok = math.abs(got - st[3]) < 0.01
    end
    check(gun .. " Uncommon " .. st[1] .. " " .. st[2] .. st[3], ok, "common " .. d.common .. " uncommon " .. d.uncommon)
  else
    print("note: " .. gun .. " has no Common/Uncommon pair this run, " .. st[1] .. " not compared")
  end
end
check("some plain gangers rolled the Uncommon", plainUncommon > 0, plainUncommon .. " of " .. (plainUncommon + plainCommon))
check("some plain gangers kept the Common", plainCommon > 0, plainCommon .. " of " .. (plainUncommon + plainCommon))
report()

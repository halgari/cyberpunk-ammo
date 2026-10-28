-- AOTestKit: a CET window for testing Ammo Overhaul by hand. It shows while the CET overlay is
-- open. Spawn enemies by gun type in front of you, watch their ammo, kill or remove them, and
-- read the mod's log. The hotkeys (CET overlay -> Hotkeys tab, bind them yourself) work
-- without the overlay. Installed by tools/linux/dev-install.sh.

local TAG = "AO_Test"

-- Hostile on spawn regardless of where you are. Rarity in brackets sets how many magazines
-- they carry (AmmoOverhaul.npcMagazines.*).
local ENEMIES = {
  { label = "Handgun ganger [Normal]", rec = "Character.dtn_tyger_claws_biker1_ranged1_nue_wa" },
  { label = "SMG scavenger [Weak]", rec = "Character.lch_scavenger_grunt2_ranged2_pulsar_wa" },
  { label = "Rifle 6th Street [Normal]", rec = "Character.gle_sixthstreet_veteran3_ranged2_ajax_ma" },
  { label = "Shotgun NCPD [Rare]", rec = "Character.nok_ncpd_enforcer_shotgun2_tactician_ma_rare" },
  { label = "Sniper Kurtz [Rare]", rec = "Character.combat_zone_gate_kurtz_recon_sniper2_achilles_ma_rare" },
  { label = "Dual-wield Valentino [Elite]", rec = "Character.valentinos_elite3_ranged3_dual_ma_elite" },
  { label = "HMG gunner [Elite] (unlimited)", rec = "Character.ina_03_wraiths_strong_gunner3_hmg_mb_elite" },
  { label = "Mushrooms Lexington ganger [Normal]", rec = "Character.AO_Test_Ganger_9mm_Mushrooms" },
  { label = "Sleevers Omaha ganger [Normal]", rec = "Character.AO_Test_Ganger_5mm_Sleevers" },
  { label = "Dumbfires Yukimura ganger [Normal]", rec = "Character.AO_Test_Ganger_10mm_Dumbfires" },
}

local state = {
  overlay = false,
  count = 1,
  distance = 12,
  godMode = true,
  hostile = {},   -- entity hash -> true once made hostile
  rows = {},
  trail = "",
  nextRefresh = 0,
  message = "",
}

local function player() return Game.GetPlayer() end

local function setGodMode(on)
  local p = player()
  if not p then return end
  local gms = Game.GetGodModeSystem()
  if on then
    gms:AddGodMode(p:GetEntityID(), gameGodModeType.Invulnerable, CName.new("AO_TestKit"))
  else
    gms:RemoveGodMode(p:GetEntityID(), gameGodModeType.Invulnerable, CName.new("AO_TestKit"))
  end
end

local function testNPCs()
  local ok, list = pcall(function() return Game.GetDynamicEntitySystem():GetTagged(TAG) end)
  return ok and list or {}
end

local function spawn(rec, count)
  local p = player()
  if not p then return end
  local pos, fwd = p:GetWorldPosition(), p:GetWorldForward()
  local right = Vector4.new(fwd.y, -fwd.x, 0, 0)
  for i = 1, count do
    local side = (i - (count + 1) / 2) * 2.5
    local spec = DynamicEntitySpec.new()
    spec.recordID = TweakDBID.new(rec)
    spec.position = Vector4.new(pos.x + fwd.x * state.distance + right.x * side,
      pos.y + fwd.y * state.distance + right.y * side, pos.z, 1)
    -- Face the player.
    spec.orientation = EulerAngles.ToQuat(EulerAngles.new(0, 0, -math.deg(math.atan2(-fwd.x, -fwd.y))))
    spec.alwaysSpawned = true
    spec.tags = { TAG }
    Game.GetDynamicEntitySystem():CreateEntity(spec)
  end
  if state.godMode then setGodMode(true) end
  state.message = "spawned " .. count .. " x " .. rec
end

local function makeHostile(npc)
  local p = player()
  npc:GetAttitudeAgent():SetAttitudeTowards(p:GetAttitudeAgent(), EAIAttitude.AIA_Hostile)
  npc:GetTargetTrackerComponent():AddThreat(p, true, p:GetWorldPosition(), 1.0, -1.0, false)
end

local function forEachNPC(fn)
  local n = 0
  for _, npc in ipairs(testNPCs()) do
    fn(npc)
    n = n + 1
  end
  return n
end

local function killAll()
  local n = forEachNPC(function(npc) if not npc:IsDead() then npc:Kill(nil, false, false) end end)
  state.message = "killed " .. n
end

local function despawnAll()
  local n = forEachNPC(function(npc) Game.GetDynamicEntitySystem():DeleteEntity(npc:GetEntityID()) end)
  state.hostile = {}
  state.message = "removed " .. n
end

-- The slice kit: the three guns, their six selectors and 60 of each round.
local KIT_GUNS = { "Items.Preset_Lexington_Default", "Items.Preset_Omaha_Default", "Items.Preset_Yukimura_Default" }
local KIT_SELECTORS = { "Items.AO_Feed_9mm_Ball", "Items.AO_Feed_9mm_Mushrooms", "Items.AO_Feed_5mm_RailSlugs",
  "Items.AO_Feed_5mm_Sleevers", "Items.AO_Feed_10mm_Seekers", "Items.AO_Feed_10mm_Dumbfires" }
local KIT_ROUNDS = { "Ammo.HandgunAmmo", "Ammo.AO_9mm_HollowPoint", "Ammo.AO_TLight_Slug", "Ammo.AO_TLight_Sabot",
  "Ammo.AO_S10_Standard", "Ammo.AO_S10_Dumbfire" }

local function giveKit()
  for _, id in ipairs(KIT_GUNS) do Game.AddToInventory(id, 1) end
  for _, id in ipairs(KIT_SELECTORS) do Game.AddToInventory(id, 1) end
  for _, id in ipairs(KIT_ROUNDS) do Game.AddToInventory(id, 60) end
  state.message = "gave Lexington, Omaha, Yukimura, 6 selectors, 60 of each round"
end

local function ammoOf(owner)
  local ts = Game.GetTransactionSystem()
  local ok, items = ts:GetItemList(owner)
  local parts = {}
  for _, it in ipairs(items or {}) do
    local name = TDBID.ToStringDEBUG(it:GetID().id)
    if name:find("^Ammo%.") then
      table.insert(parts, name:sub(6) .. " " .. ts:GetItemQuantity(owner, it:GetID()))
    end
  end
  return #parts > 0 and table.concat(parts, ", ") or "none"
end

local function refresh()
  local p = player()
  if not p then return end
  local rows = {}
  for _, npc in ipairs(testNPCs()) do
    local key = tostring(npc:GetEntityID().hash)
    if not state.hostile[key] and not npc:IsDead() then
      if pcall(makeHostile, npc) then state.hostile[key] = true end
    end
    local w = ScriptedPuppet.GetActiveWeapon(npc)
    local gun, mag = "-", "-"
    if w then
      gun = TDBID.ToStringDEBUG(w:GetItemID().id):gsub("^Items%.Preset_", "")
      mag = WeaponObject.GetMagazineAmmoCount(w) .. "/" .. WeaponObject.GetMagazineCapacity(w)
    end
    table.insert(rows, {
      name = TDBID.ToStringDEBUG(npc:GetRecordID()):gsub("^Character%.", ""),
      status = npc:IsDead() and "dead" or (npc:IsIncapacitated() and "down" or "alive"),
      dist = string.format("%.0f m", Vector4.Distance(npc:GetWorldPosition(), p:GetWorldPosition())),
      gun = gun, mag = mag, ammo = ammoOf(npc),
    })
  end
  state.rows = rows
  local ok, sys = pcall(function() return Game.GetScriptableSystemsContainer():Get("AmmoOverhaul.AmmoFeedSystem") end)
  state.trail = ok and sys and sys:Trail() or "(AmmoOverhaul not loaded)"
end

local function lastLines(text, n)
  local lines = {}
  for line in text:gmatch("[^\n]+") do table.insert(lines, line) end
  return table.concat(lines, "\n", math.max(1, #lines - n + 1))
end

registerForEvent("onOverlayOpen", function() state.overlay = true end)
registerForEvent("onOverlayClose", function() state.overlay = false end)

registerForEvent("onUpdate", function()
  local now = os.clock()
  if now >= state.nextRefresh then
    state.nextRefresh = now + 0.5
    pcall(refresh)
  end
end)

registerForEvent("onDraw", function()
  if not state.overlay then return end
  if ImGui.Begin("Ammo Overhaul test kit") then
    ImGui.Text("Spawn hostile enemies in front of you:")
    state.count = ImGui.SliderInt("How many", state.count, 1, 5)
    state.distance = ImGui.SliderInt("Distance (m)", state.distance, 5, 40)
    for _, e in ipairs(ENEMIES) do
      if ImGui.Button(e.label) then spawn(e.rec, state.count) end
    end
    ImGui.Separator()
    local god, changed = ImGui.Checkbox("Invulnerable", state.godMode)
    if changed then state.godMode = god; setGodMode(god) end
    if ImGui.Button("Kill test enemies") then killAll() end
    ImGui.SameLine()
    if ImGui.Button("Remove test enemies") then despawnAll() end
    ImGui.SameLine()
    if ImGui.Button("Give slice kit") then giveKit() end
    if state.message ~= "" then ImGui.Text(state.message) end
    ImGui.Separator()
    ImGui.Text("You: " .. (player() and ammoOf(player()) or "-"))
    ImGui.Text("Test enemies (gun, magazine, ammo carried):")
    if #state.rows == 0 then ImGui.Text("  none") end
    for _, r in ipairs(state.rows) do
      ImGui.Text(string.format("  %s  [%s, %s]", r.name, r.status, r.dist))
      ImGui.Text(string.format("      %s  %s  ammo: %s", r.gun, r.mag, r.ammo))
    end
    ImGui.Separator()
    ImGui.Text("Mod log (latest last):")
    ImGui.TextWrapped(lastLines(state.trail, 12))
  end
  ImGui.End()
end)

registerHotkey("ao_spawn_handgun", "Spawn handgun ganger", function() spawn(ENEMIES[1].rec, state.count) end)
registerHotkey("ao_spawn_rifle", "Spawn rifle enemy", function() spawn(ENEMIES[3].rec, state.count) end)
registerHotkey("ao_spawn_shotgun", "Spawn shotgun enemy", function() spawn(ENEMIES[4].rec, state.count) end)
registerHotkey("ao_kill", "Kill test enemies", killAll)
registerHotkey("ao_remove", "Remove test enemies", despawnAll)

-- For scripted checks: GetMod("AOTestKit").spawn(...) from another CET mod.
return { spawn = spawn, killAll = killAll, despawnAll = despawnAll, giveKit = giveKit, refresh = refresh, state = state, enemies = ENEMIES }

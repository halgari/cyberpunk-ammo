#!/usr/bin/env bash
# The full in-game suite. Run right after a game restart (swap.sh needs a fresh session) and not
# while anyone plays: it draws guns, spawns NPCs and moves V. Exits 1 if any check fails.
# Not included: slice/section.lua (needs a person on the weapon screen). parity.sh runs last and is
# reported but doesn't gate: its Crusher phases can lose their NPC to the rig's respawn.
cd "$(dirname "$0")/../../.."
C=tools/snippets/calibers; S=tools/snippets/slice; K="$C/check.sh"
# lootdupe/lootcap spawn their NPC on the first run and check on the second.
twice() { echo "$K $1 >/dev/null 2>&1; sleep 12; $K $1"; }
# roll.lua's tooltip check needs a Unity drawn (feed-kit hands out the kit on its first run).
UNITY='tools/linux/cet.sh "Game.AddToInventory(\"Items.Preset_Unity_Default\", 1)" >/dev/null; sleep 2;
  for i in 1 2; do tools/linux/cet.sh "GUN=\"Items.Preset_Unity_Default\"; $(cat tools/snippets/feed-kit.lua)" >/dev/null; sleep 4; done;'
# hidden.lua's backpack check needs a selector held before it runs: Mushrooms rounds make the sync
# hand one out (the backpack's item map lags a moment behind the inventory).
MUSH='TweakDBID.new("Ammo.AO_9mm_HollowPoint")'
HIDDEN="tools/linux/cet.sh 'Game.AddToInventory(\"Ammo.AO_9mm_HollowPoint\", 10)' >/dev/null; sleep 3; $K calibers/hidden.lua;
  tools/linux/cet.sh 'Game.GetTransactionSystem():RemoveItemByTDBID(Game.GetPlayer(), $MUSH, 10)' >/dev/null"
$C/all-pass.sh \
  "$S/swap.sh" \
  "$K calibers/records.lua calibers/vanilla.lua calibers/distribution.lua calibers/icons.lua calibers/parity.lua" \
  "CET_T=60 $K calibers/crafting.lua" "$C/crafting.sh" \
  "python3 tools/icons/check_parts.py" \
  "$UNITY $K calibers/roll.lua" \
  "$K slice/records.lua slice/icons.lua slice/vendors.lua slice/loot.lua" \
  "$K slice/rarity.lua >/dev/null; sleep 6; $K slice/rarity2.lua" \
  "$S/uncommon.sh" "$C/uncommon2.sh" "$C/slugs.sh" "$C/spread.sh" \
  "$S/npc.sh" "$S/npcdrop.sh" "$C/npc.sh" "$C/ping.sh" \
  "$(twice calibers/lootdupe.lua)" "$(twice calibers/lootcap.lua)" \
  "$HIDDEN" "$C/sync.sh" "$C/roll.sh" "$C/legendary.sh"
status=$?
(( status == 2 )) && exit 2
echo "-- parity.sh (not gating):"
timeout 900 $C/parity.sh 2>/dev/null | grep -E '^(PASS|FAIL|==)'
exit $status

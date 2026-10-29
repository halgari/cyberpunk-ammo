#!/usr/bin/env bash
# The full in-game suite. Run right after a game restart (swap.sh needs a fresh session) and not
# while anyone plays: it draws guns, spawns NPCs and moves V. Exits 1 if any check fails.
# Not included: slice/section.lua (needs a person on the weapon screen); roll.sh runs last and is
# reported but doesn't gate (its hit rig is flaky, see docs/TESTING.md).
cd "$(dirname "$0")/../../.."
C=tools/snippets/calibers; S=tools/snippets/slice; K="$C/check.sh"
# lootdupe/lootcap spawn their NPC on the first run and check on the second.
twice() { echo "$K $1 >/dev/null 2>&1; sleep 12; $K $1"; }
# roll.lua's tooltip check needs a Unity drawn (feed-kit hands out the kit on its first run).
UNITY='tools/linux/cet.sh "Game.AddToInventory(\"Items.Preset_Unity_Default\", 1)" >/dev/null; sleep 2;
  for i in 1 2; do tools/linux/cet.sh "GUN=\"Items.Preset_Unity_Default\"; $(cat tools/snippets/feed-kit.lua)" >/dev/null; sleep 4; done;'
$C/all-pass.sh \
  "$S/swap.sh" \
  "$K calibers/records.lua calibers/vanilla.lua calibers/distribution.lua calibers/icons.lua" \
  "python3 tools/icons/check_parts.py" \
  "$UNITY $K calibers/roll.lua" \
  "$K slice/records.lua slice/icons.lua slice/vendors.lua slice/loot.lua" \
  "$K slice/rarity.lua >/dev/null; sleep 6; $K slice/rarity2.lua" \
  "$S/uncommon.sh" "$C/uncommon2.sh" "$C/slugs.sh" \
  "$S/npc.sh" "$S/npcdrop.sh" "$C/npc.sh" \
  "$(twice calibers/lootdupe.lua)" "$(twice calibers/lootcap.lua)"
status=$?
echo "-- roll.sh (not gating):"
$C/roll.sh 2>/dev/null | grep -E '^(PASS|FAIL|==)'
exit $status

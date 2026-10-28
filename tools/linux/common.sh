# Shared paths for the Linux (Lutris / GE-Proton) dev tools. Source this; don't run it.
# Override any of these from the environment if the install moves.
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
PREFIX="${PREFIX:-/home/tbaldrid/Games/gog/cyberpunk-2077}"
GAME_DIR="${GAME_DIR:-$PREFIX/drive_c/GOG Games/Cyberpunk 2077}"
SAVES_DIR="${SAVES_DIR:-$PREFIX/drive_c/users/steamuser/Saved Games/CD Projekt Red/Cyberpunk 2077}"
SETTINGS_DIR="${SETTINGS_DIR:-$PREFIX/drive_c/users/steamuser/AppData/Local/CD Projekt Red/Cyberpunk 2077}"
LUTRIS_GAME_ID="${LUTRIS_GAME_ID:-1}"
HARNESS_DIR="$GAME_DIR/bin/x64/plugins/cyber_engine_tweaks/mods/AOHarness"
TESTKIT_DIR="$GAME_DIR/bin/x64/plugins/cyber_engine_tweaks/mods/AOTestKit"

# Windows tools (redscript-cli) run on the same GE-Proton the game uses, never system wine, and
# in their own prefix, never the game's. umu-run drops console output, so they call Proton's
# bundled wine binary directly.
PROTON="${PROTON:-$HOME/.local/share/Steam/compatibilitytools.d/GE-Proton11-11-x86_64}"
TOOLS_PREFIX="${TOOLS_PREFIX:-$HOME/.cache/ammo-overhaul/proton-prefix}"
proton_wine() { WINEPREFIX="$TOOLS_PREFIX" WINEDEBUG=-all "$PROTON/files/bin/wine" "$@" 2>&1 | grep -v -E 'MESA|pci id|dri2'; }

# The game process's command line is its Windows path (its name is just "GameThread"); anchoring
# on the drive letter keeps shells and umu wrappers that merely mention the exe from matching.
GAME_PROCESS='^[A-Z]:.*\\bin\\x64\\Cyberpunk2077\.exe'
game_running() { pgrep -f "$GAME_PROCESS" >/dev/null; }

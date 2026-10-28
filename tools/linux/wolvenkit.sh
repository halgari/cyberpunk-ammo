#!/usr/bin/env bash
# Runs the Windows WolvenKit console (tools/wolvenkit-win, release "WolvenKit.Console") on
# GE-Proton in the tools prefix, never the game's. The prefix needs the .NET 10 runtime in
# C:\Program Files\dotnet (the portable win-x64 zip unpacked there). Paths passed in must be
# Windows paths (Z:/...).
#   tools/linux/wolvenkit.sh export Z:/path/file.xbm -o Z:/out --uext png
set -euo pipefail
source "$(dirname "$0")/common.sh"
cli="$ROOT/tools/wolvenkit-win/WolvenKit.CLI.exe"
[[ -f "$cli" ]] || { echo "missing $cli: unzip WolvenKit.Console-<version>.zip there" >&2; exit 2; }
DOTNET_ROOT='C:\Program Files\dotnet' proton_wine "$cli" "$@"

#!/usr/bin/env bash
# Cross-compiles a RED4ext plugin from native/<Name>/ into build/native/<Name>.dll with clang-cl
# and lld-link, against the Windows CRT/SDK from xwin. [--deploy] copies it into the game.
#   tools/linux/build-native.sh AOProbe [--deploy]
# One-time setup (accepts Microsoft's license for the CRT/SDK files):
#   cargo install xwin --locked
#   xwin --accept-license --arch x86_64 splat --output ~/.cache/ammo-overhaul/xwin
#   git clone --depth 1 https://github.com/WopsS/RED4ext.SDK.git ~/.cache/ammo-overhaul/RED4ext.SDK
set -euo pipefail
source "$(dirname "$0")/common.sh"

name="${1:?plugin name}"
deploy="${2:-}"
cache="$HOME/.cache/ammo-overhaul"
xwin="$cache/xwin"
sdk="$cache/RED4ext.SDK"
src="$ROOT/native/$name"
out="$ROOT/build/native"
mkdir -p "$out"

# The SDK includes RED4ext/rtti/ in places but the folder is RTTI/ (fine on Windows only).
[[ -e "$sdk/include/RED4ext/rtti" ]] || ln -s RTTI "$sdk/include/RED4ext/rtti"

# The SDK's CMake normally generates this.
version="$sdk/include/RED4ext/Version.hpp"
if [[ ! -f "$version" ]]; then
  sed -e 's/@PROJECT_VERSION_MAJOR@/1/' -e 's/@PROJECT_VERSION_MINOR@/0/' -e 's/@PROJECT_VERSION_PATCH@/0/' \
    "$sdk/cmake/Version.hpp.in" > "$version"
fi

clang-cl --target=x86_64-pc-windows-msvc /std:c++20 /O2 /MD /EHsc /W3 /nologo \
  -Wno-unused-command-line-argument -Wno-microsoft-include -Wno-pragma-pack -Wno-c++23-extensions -Wno-reorder-ctor -Wno-invalid-offsetof \
  /DWIN32_LEAN_AND_MEAN /DNOMINMAX /DUNICODE /D_UNICODE \
  /imsvc "$xwin/crt/include" /imsvc "$xwin/sdk/include/ucrt" /imsvc "$xwin/sdk/include/um" /imsvc "$xwin/sdk/include/shared" \
  /I "$sdk/include" \
  /c "$src"/*.cpp /Fo"$out/"

lld-link /nologo /DLL /OUT:"$out/$name.dll" "$out"/*.obj \
  /LIBPATH:"$xwin/crt/lib/x86_64" /LIBPATH:"$xwin/sdk/lib/um/x86_64" /LIBPATH:"$xwin/sdk/lib/ucrt/x86_64" \
  kernel32.lib user32.lib
rm -f "$out"/*.obj
echo "built $out/$name.dll"

if [[ "$deploy" == "--deploy" ]]; then
  dst="$GAME_DIR/red4ext/plugins/$name"
  mkdir -p "$dst"
  cp "$out/$name.dll" "$dst/"
  echo "deployed red4ext/plugins/$name"
fi

# Builds dist/AmmoOverhaul.zip laid out relative to the game root, so it can be extracted
# into any Cyberpunk 2077 install (or a mod manager). With -Deploy, also copies the files
# into the local game directory.
param(
    [string]$GameDir = "C:\Program Files\GOG Galaxy\Games\Cyberpunk 2077",
    [switch]$Deploy
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$dist = Join-Path $root 'dist'
$stage = Join-Path $dist 'stage'
$zip = Join-Path $dist 'AmmoOverhaul.zip'

Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
$layout = @{
    'src\scripts' = 'r6\scripts'
    'src\tweaks'  = 'r6\tweaks'
}
foreach ($from in $layout.Keys) {
    $dst = Join-Path $stage $layout[$from]
    New-Item -ItemType Directory -Force $dst | Out-Null
    Copy-Item (Join-Path $root "$from\*") $dst -Recurse
}
# The native plugin is cross-built on Linux (tools/linux/build-native.sh AmmoOverhaul).
$plugin = Join-Path $root 'build\native\AmmoOverhaul.dll'
if (-not (Test-Path $plugin)) { throw "missing ${plugin}: build it with tools/linux/build-native.sh AmmoOverhaul" }
$pluginDir = Join-Path $stage 'red4ext\plugins\AmmoOverhaul'
New-Item -ItemType Directory -Force $pluginDir | Out-Null
Copy-Item $plugin $pluginDir

Remove-Item $zip -ErrorAction SilentlyContinue
& (Join-Path $PSScriptRoot 'zip.ps1') -Source $stage -Destination $zip
# The test guide and log collector travel next to the zip, not inside the game folder.
Copy-Item (Join-Path $root 'docs\TESTING.md'), (Join-Path $PSScriptRoot 'collect-logs.ps1'), (Join-Path $PSScriptRoot 'zip.ps1') $dist
Write-Output "built $zip"

if ($Deploy) {
    # Replace the mod's own folders wholesale so deleted source files don't linger in the game.
    foreach ($dir in 'r6\scripts\AmmoOverhaul', 'r6\tweaks\AmmoOverhaul', 'red4ext\plugins\AmmoOverhaul') {
        Remove-Item (Join-Path $GameDir $dir) -Recurse -Force -ErrorAction SilentlyContinue
    }
    Copy-Item (Join-Path $stage '*') $GameDir -Recurse -Force
    Write-Output "deployed to $GameDir"
}

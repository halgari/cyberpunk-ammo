# Installs (or with -Remove, removes) the dev-only helpers: intro skip, autoload of the test
# save, the AOHarness CET console, and a desktop shortcut that skips the start screen.
param(
    [string]$GameDir = "C:\Program Files\GOG Galaxy\Games\Cyberpunk 2077",
    [switch]$Remove
)
$ErrorActionPreference = 'Stop'
$scripts = Join-Path $GameDir 'r6\scripts\AODev'
$shortcut = Join-Path ([Environment]::GetFolderPath('Desktop')) 'Cyberpunk 2077 (dev).lnk'

if ($Remove) {
    Remove-Item $scripts -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item (Join-Path $GameDir 'bin\x64\plugins\cyber_engine_tweaks\mods\AOHarness') -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item $shortcut -ErrorAction SilentlyContinue
    Write-Output 'dev helpers removed'
    return
}

New-Item -ItemType Directory -Force $scripts | Out-Null
Copy-Item (Join-Path $PSScriptRoot 'dev-scripts\*.reds') $scripts -Force
& (Join-Path $PSScriptRoot 'cet.ps1') -Install -GameDir $GameDir

$shell = New-Object -ComObject WScript.Shell
$lnk = $shell.CreateShortcut($shortcut)
$lnk.TargetPath = Join-Path $GameDir 'bin\x64\Cyberpunk2077.exe'
$lnk.Arguments = '--launcher-skip -skipStartScreen'
$lnk.WorkingDirectory = Join-Path $GameDir 'bin\x64'
$lnk.Save()
Write-Output "installed dev helpers; shortcut: $shortcut"

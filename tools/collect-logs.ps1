# Zips every log the mod and its frameworks write, for sending back after a test session.
# Run from any machine: .\collect-logs.ps1 -GameDir "D:\Games\Cyberpunk 2077"
# Needs zip.ps1 next to it.
param(
    [string]$GameDir = "C:\Program Files\GOG Galaxy\Games\Cyberpunk 2077",
    [string]$Out = (Join-Path ([Environment]::GetFolderPath('Desktop')) 'AmmoOverhaul-logs.zip')
)
$ErrorActionPreference = 'Stop'
$GameDir = $GameDir.TrimEnd('\')
$stage = Join-Path ([IO.Path]::GetTempPath()) 'AmmoOverhaul-logs'
Remove-Item $stage -Recurse -Force -ErrorAction SilentlyContinue
New-Item -ItemType Directory -Force $stage | Out-Null
foreach ($dir in 'r6\logs', 'red4ext\logs', 'red4ext\plugins', 'bin\x64\plugins\cyber_engine_tweaks') {
    $src = Join-Path $GameDir $dir
    if (-not (Test-Path $src)) { continue }
    foreach ($log in Get-ChildItem $src -Recurse -File -Filter *.log) {
        $dst = Join-Path $stage $log.FullName.Substring($GameDir.Length + 1)
        New-Item -ItemType Directory -Force (Split-Path $dst) | Out-Null
        Copy-Item $log.FullName $dst
    }
}
Remove-Item $Out -ErrorAction SilentlyContinue
& (Join-Path $PSScriptRoot 'zip.ps1') -Source $stage -Destination $Out
Write-Output "wrote $Out"

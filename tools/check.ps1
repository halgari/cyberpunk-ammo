# Compile-checks the mod's redscript against the vanilla 2.5 bundle plus the framework
# scripts, the same inputs the game's scc uses at launch. Needs reference/final.redscripts.vanilla
# (a copy of the unmodded r6/cache/final.redscripts) and tools/redscript-cli.exe.
param(
    [string]$GameDir = "C:\Program Files\GOG Galaxy\Games\Cyberpunk 2077"
)
$ErrorActionPreference = 'Stop'
$root = Split-Path $PSScriptRoot
$bundle = Join-Path $root 'reference\final.redscripts.vanilla'
$out = Join-Path ([IO.Path]::GetTempPath()) 'ammo-overhaul-check.redscripts'

$src = @(Join-Path $root 'src\scripts')
foreach ($plugin in 'TweakXL', 'ArchiveXL', 'Codeware') {
    $dir = Join-Path $GameDir "red4ext\plugins\$plugin\Scripts"
    if (Test-Path $dir) { $src += $dir }
}

$cliArgs = @('compile', '-b', $bundle, '-o', $out)
foreach ($s in $src) { $cliArgs += @('-s', $s) }
& (Join-Path $PSScriptRoot 'redscript-cli.exe') @cliArgs
if ($LASTEXITCODE -ne 0) { throw "redscript compile failed ($LASTEXITCODE)" }
Remove-Item $out -ErrorAction SilentlyContinue

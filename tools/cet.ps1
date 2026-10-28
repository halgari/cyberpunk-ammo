# Runs Lua inside the running game through the AOHarness CET mod and prints the result.
#   .\cet.ps1 'print(Game.GetPlayer():GetLevel())'
#   .\cet.ps1 -File snippet.lua
#   .\cet.ps1 -Install        # (re)deploys the harness mod; takes effect on next game launch
param(
    [Parameter(Position = 0)][string]$Code,
    [string]$File,
    [int]$TimeoutSec = 15,
    [switch]$Install,
    [string]$GameDir = "C:\Program Files\GOG Galaxy\Games\Cyberpunk 2077"
)
$ErrorActionPreference = 'Stop'
$mod = Join-Path $GameDir 'bin\x64\plugins\cyber_engine_tweaks\mods\AOHarness'

if ($Install) {
    New-Item -ItemType Directory -Force $mod | Out-Null
    Copy-Item (Join-Path $PSScriptRoot 'harness\init.lua') $mod -Force
    Write-Output "installed $mod"
    return
}

if ($File) { $Code = Get-Content $File -Raw }
if (-not $Code) { throw 'no code given' }
if (-not (Get-Process Cyberpunk2077 -ErrorAction SilentlyContinue)) { throw 'game is not running' }

$id = [Guid]::NewGuid().ToString('N').Substring(0, 8)
$out = Join-Path $mod 'out.log'
$offset = if (Test-Path $out) { (Get-Item $out).Length } else { 0 }
$utf8 = New-Object Text.UTF8Encoding($false)
[IO.File]::WriteAllText((Join-Path $mod 'cmd.lua'), "-- id: $id`n$Code`n", $utf8)

$deadline = (Get-Date).AddSeconds($TimeoutSec)
while ((Get-Date) -lt $deadline) {
    if ((Test-Path $out) -and (Get-Item $out).Length -gt $offset) {
        $text = [IO.File]::ReadAllText($out, $utf8)
        $begin = $text.IndexOf("@@begin $id")
        $end = $text.IndexOf("@@end $id")
        if ($begin -ge 0 -and $end -gt $begin) {
            $body = $text.Substring($begin + "@@begin $id".Length, $end - $begin - "@@begin $id".Length)
            Write-Output $body.Trim()
            return
        }
    }
    Start-Sleep -Milliseconds 250
}
throw "no response within $TimeoutSec s (game paused/unfocused, still loading, or harness not installed?)"

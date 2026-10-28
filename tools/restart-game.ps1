# Dev only: kills Cyberpunk 2077 (if running) and relaunches it in the logged-in user's desktop
# session, then waits until the AOHarness answers (the dev autoload brings it straight into the save).
# A plain Start-Process from a service/SSH shell would run the game in session 0, invisible and
# without a display, so the launch goes through an interactive scheduled task instead.
param(
    [string]$GameDir = "C:\Program Files\GOG Galaxy\Games\Cyberpunk 2077",
    [int]$TimeoutSec = 240,
    [switch]$NoWait
)
$ErrorActionPreference = 'Stop'
$task = 'AODevLaunchCyberpunk'
$exe = Join-Path $GameDir 'bin\x64\Cyberpunk2077.exe'

$running = Get-Process Cyberpunk2077 -ErrorAction SilentlyContinue
if ($running) {
    $running | Stop-Process -Force
    $running | Wait-Process -Timeout 30 -ErrorAction SilentlyContinue
}

$action = New-ScheduledTaskAction -Execute $exe -Argument '--launcher-skip -skipStartScreen' -WorkingDirectory (Split-Path $exe)
$principal = New-ScheduledTaskPrincipal -UserId "$env:USERDOMAIN\$env:USERNAME" -LogonType Interactive
Register-ScheduledTask -TaskName $task -Action $action -Principal $principal -Force | Out-Null
Start-ScheduledTask -TaskName $task
Write-Output 'game launching'
if ($NoWait) { return }

$deadline = (Get-Date).AddSeconds($TimeoutSec)
while ((Get-Date) -lt $deadline) {
    Start-Sleep 10
    if (-not (Get-Process Cyberpunk2077 -ErrorAction SilentlyContinue)) { continue }
    try {
        # The main menu has a player puppet too; only a loaded save is out of pre-game.
        $r = & (Join-Path $PSScriptRoot 'cet.ps1') 'return tostring(Game.GetSystemRequestsHandler():IsPreGame()) .. " " .. tostring(Game.GetPlayer() ~= nil)' -TimeoutSec 5 -GameDir $GameDir
        if ($r -match '=> false true') {
            # Scriptable systems get OnPlayerAttach a few seconds after pre-game ends.
            Start-Sleep 15
            Write-Output 'in game'
            return
        }
    } catch { }
}
throw "game not in a save after $TimeoutSec s"

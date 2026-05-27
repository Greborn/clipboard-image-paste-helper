param(
    [switch]$Startup
)

$ErrorActionPreference = 'Stop'

$skillRoot = Split-Path -Parent $PSScriptRoot
$helper = Join-Path $PSScriptRoot 'terminal-image-paste.ahk'

if (-not (Test-Path $helper)) {
    throw "Missing helper: $helper"
}

$autohotkey = Get-Command 'AutoHotkey64.exe' -ErrorAction SilentlyContinue
if (-not $autohotkey) {
    $autohotkey = Get-Command 'AutoHotkey.exe' -ErrorAction SilentlyContinue
}

$autohotkeyPath = if ($autohotkey) { $autohotkey.Source } else { $null }

if (-not $autohotkeyPath) {
    $candidatePaths = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\AutoHotkey\v2\AutoHotkey64.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\AutoHotkey\v2\AutoHotkey32.exe'),
        'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe',
        'C:\Program Files\AutoHotkey\v2\AutoHotkey32.exe'
    )

    $autohotkeyPath = $candidatePaths | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}

if (-not $autohotkeyPath) {
    throw 'AutoHotkey v2 was not found. Install it first, for example: winget install AutoHotkey.AutoHotkey'
}

Start-Process -FilePath $autohotkeyPath -ArgumentList "`"$helper`"" -WindowStyle Hidden
Write-Output "Started terminal image paste helper from $skillRoot"

if ($Startup) {
    $startupDir = [Environment]::GetFolderPath('Startup')
    $shortcutPath = Join-Path $startupDir 'Terminal Image Paste Helper.lnk'
    $shell = New-Object -ComObject WScript.Shell
    $shortcut = $shell.CreateShortcut($shortcutPath)
    $shortcut.TargetPath = $autohotkeyPath
    $shortcut.Arguments = "`"$helper`""
    $shortcut.WorkingDirectory = $PSScriptRoot
    $shortcut.Save()
    Write-Output "Added startup shortcut: $shortcutPath"
}

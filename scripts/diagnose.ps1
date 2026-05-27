$ErrorActionPreference = 'Continue'

$root = Join-Path $env:TEMP 'cli-clipboard-images'
$manifest = Join-Path $root 'manifest.tsv'
$startup = Join-Path ([Environment]::GetFolderPath('Startup')) 'Terminal Image Paste Helper.lnk'

function Find-AutoHotkey {
    $commands = @(
        (Get-Command 'AutoHotkey64.exe' -ErrorAction SilentlyContinue),
        (Get-Command 'AutoHotkey.exe' -ErrorAction SilentlyContinue)
    ) | Where-Object { $_ }

    if ($commands) {
        return $commands[0].Source
    }

    $candidatePaths = @(
        (Join-Path $env:LOCALAPPDATA 'Programs\AutoHotkey\v2\AutoHotkey64.exe'),
        (Join-Path $env:LOCALAPPDATA 'Programs\AutoHotkey\v2\AutoHotkey32.exe'),
        'C:\Program Files\AutoHotkey\v2\AutoHotkey64.exe',
        'C:\Program Files\AutoHotkey\v2\AutoHotkey32.exe'
    )

    return $candidatePaths | Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
}

$autohotkeyPath = Find-AutoHotkey
$processes = Get-Process | Where-Object { $_.ProcessName -like 'AutoHotkey*' }
$images = if (Test-Path -LiteralPath $root) {
    Get-ChildItem -LiteralPath $root -Filter '*.png' -ErrorAction SilentlyContinue |
        Sort-Object LastWriteTime -Descending |
        Select-Object -First 5 FullName, Length, LastWriteTime
} else {
    @()
}

[pscustomobject]@{
    AutoHotkeyPath = $autohotkeyPath
    HelperProcessCount = @($processes).Count
    StartupShortcutExists = Test-Path -LiteralPath $startup
    TempRootExists = Test-Path -LiteralPath $root
    ManifestExists = Test-Path -LiteralPath $manifest
    RecentImageCount = @($images).Count
} | Format-List

if ($processes) {
    'AutoHotkey processes:'
    $processes | Select-Object ProcessName, Id, CPU, WorkingSet64 | Format-Table -AutoSize
}

if (Test-Path -LiteralPath $manifest) {
    'Recent manifest entries:'
    Get-Content -LiteralPath $manifest | Select-Object -Last 10
}

if ($images) {
    'Recent temporary images:'
    $images | Format-Table -AutoSize
}

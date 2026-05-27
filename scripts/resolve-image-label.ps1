param(
    [Parameter(Mandatory = $true)]
    [string]$Label
)

$ErrorActionPreference = 'Stop'

$root = Join-Path $env:TEMP 'cli-clipboard-images'
$manifest = Join-Path $root 'manifest.tsv'

if (-not (Test-Path -LiteralPath $manifest)) {
    Write-Error "Image manifest was not found: $manifest"
    exit 2
}

$normalized = $Label.Trim()
$normalized = $normalized.TrimStart('[').TrimEnd(']')

$match = Get-Content -LiteralPath $manifest |
    Where-Object {
        $parts = $_ -split "`t"
        $parts.Count -ge 2 -and $parts[0] -eq $normalized
    } |
    Select-Object -Last 1

if (-not $match) {
    Write-Error "No clipboard image label found for [$normalized]."
    exit 3
}

$path = ($match -split "`t")[1]
if (-not (Test-Path -LiteralPath $path)) {
    Write-Error "The temporary image for [$normalized] no longer exists: $path"
    exit 4
}

Write-Output $path

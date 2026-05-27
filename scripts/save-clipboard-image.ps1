param(
    [Parameter(Mandatory = $true)]
    [string]$Path
)

$ErrorActionPreference = 'Stop'

Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$image = [System.Windows.Forms.Clipboard]::GetImage()
if ($null -eq $image) {
    Write-Error 'The clipboard does not contain an image.'
    exit 2
}

$directory = Split-Path -Parent $Path
if ($directory) {
    New-Item -ItemType Directory -Force -Path $directory | Out-Null
}

try {
    $image.Save($Path, [System.Drawing.Imaging.ImageFormat]::Png)
    Write-Output $Path
}
finally {
    $image.Dispose()
}

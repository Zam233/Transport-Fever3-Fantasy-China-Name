# sync_mod.ps1 - Sync a mod into the game folder while PRESERVING
# _metadata/mod.io_fileid.txt.
#
# Why: the game writes _metadata/mod.io_fileid.txt when a mod is uploaded. It is
# the only local record of which mod.io entry a staged mod maps to; without it
# the Mod Hub offers Upload instead of Update, and updating would create a second
# listing. A plain "delete the folder and copy" sync destroys it.
#
# NOTE: this file is ASCII-ONLY on purpose. Windows PowerShell 5.1 decodes
# BOM-less UTF-8 as ANSI/GBK, which corrupts CJK text in the script body. Any
# non-ASCII path must be passed as an argument, never hardcoded here.
#
# Usage:
#   .\tools\sync_mod.ps1 -ModName cn_names -Src "<source dir>"
#   .\tools\sync_mod.ps1 -ModName cn_names -Src "<source dir>" -Dest "<...>\local\mods"

param(
    [Parameter(Mandatory = $true)]
    [string]$ModName,

    [Parameter(Mandatory = $true)]
    [string]$Src,

    [string]$Dest = "C:\Program Files (x86)\Steam\userdata\167294663\3493540\local\staging_area"
)

if (-not (Test-Path $Src)) {
    Write-Host "ERROR: source not found: $Src"
    exit 1
}

$target = Join-Path $Dest $ModName
$fidPath = Join-Path $target "_metadata\mod.io_fileid.txt"

$keep = $null
if (Test-Path $fidPath) {
    $keep = (Get-Content $fidPath -Raw).Trim()
}

if (Test-Path $target) {
    Remove-Item $target -Recurse -Force
}
Copy-Item $Src -Destination $Dest -Recurse -Force

if ($keep) {
    $dir = Join-Path $target "_metadata"
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    Set-Content -Path (Join-Path $dir "mod.io_fileid.txt") -Value $keep -NoNewline
    Write-Host "preserved mod.io_fileid.txt = $keep"
} else {
    Write-Host "no mod.io_fileid.txt found (first upload?)"
}

$mj = Get-Content (Join-Path $target "mod.json") -Raw | ConvertFrom-Json
Write-Host "synced (revision $($mj.revision))"

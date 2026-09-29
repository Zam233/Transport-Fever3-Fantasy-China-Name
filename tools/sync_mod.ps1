# sync_mod.ps1 - 安全同步：把源目录同步到投放位置，但**保留**游戏生成的
# _metadata/mod.io_fileid.txt（它是"更新已有 mod.io 条目"的凭据，删了就只会
# 变成"新上传"）。默认同步到 staging_area，可用 -Dest 指定 mods 目录。
param(
  [Parameter(Mandatory = $true)][string]$ModName,
  [string]$Dest = "C:\Program Files (x86)\Steam\userdata\167294663\3493540\local\staging_area",
  [string]$Src  = "K:\幻想中文名称\cn_names"
)
$target = Join-Path $Dest $ModName
$fid = Join-Path $target "_metadata\mod.io_fileid.txt"
$keep = if (Test-Path $fid) { Get-Content $fid -Raw } else { $null }

if (Test-Path $target) { Remove-Item $target -Recurse -Force }
Copy-Item $Src -Destination $Dest -Recurse -Force

if ($keep) {
  New-Item -ItemType Directory -Force -Path (Join-Path $target "_metadata") | Out-Null
  Set-Content -Path (Join-Path $target "_metadata\mod.io_fileid.txt") -Value $keep -NoNewline
  Write-Host "preserved mod.io_fileid.txt: $($keep.Trim())"
} else {
  Write-Host "no mod.io_fileid.txt present (first upload?)"
}
Write-Host "synced $Src -> $target"
# lint51.ps1 - Lua 5.1 / LuaJIT compatibility checker
#
# Why: this machine only has texlua (Lua 5.3) available, while the TF3 runtime
#      is likely Lua 5.1 / LuaJIT. Bitwise operators introduced in Lua 5.3 are
#      a SYNTAX ERROR under 5.1 and would make the mod fail to load entirely.
#
# NOTE: this file is intentionally ASCII-only. Windows PowerShell 5.1 decodes
#       BOM-less UTF-8 as ANSI/GBK, which corrupts non-ASCII text and breaks
#       parsing. Keep this script pure ASCII.
#
# Usage:
#     & .\tools\lint51.ps1 -Path <directory>

param(
  [Parameter(Mandatory = $true)]
  [string]$Path
)

$ErrorActionPreference = 'Stop'

# (regex pattern, description)
$patterns = @(
  @{ re = '(?<![~<>=])~(?!=)';          desc = 'bitwise XOR ~  (Lua 5.3+)' },
  @{ re = '<<|>>';                      desc = 'shift << >>  (Lua 5.3+)' },
  @{ re = '(?<![<>=&])&(?![&=])';       desc = 'bitwise AND &  (Lua 5.3+)' },
  @{ re = '(?<!\|)\|(?!\|)';            desc = 'bitwise OR |  (Lua 5.3+)' },
  @{ re = '//';                         desc = 'floor division //  (Lua 5.3+)' },
  @{ re = '\bgoto\s+\w+';               desc = 'goto statement  (Lua 5.2+)' },
  @{ re = '::\w+::';                    desc = 'label ::name::  (Lua 5.2+)' },
  @{ re = 'math\.type\b';               desc = 'math.type  (Lua 5.3+)' },
  @{ re = '\bmath\.maxinteger\b';       desc = 'math.maxinteger  (Lua 5.3+)' },
  @{ re = '\bmath\.mininteger\b';       desc = 'math.mininteger  (Lua 5.3+)' },
  @{ re = '\btable\.move\b';            desc = 'table.move  (Lua 5.3+)' },
  @{ re = '\butf8\.';                   desc = 'utf8 library  (Lua 5.3+)' },
  @{ re = '\bstring\.pack\b';           desc = 'string.pack  (Lua 5.3+)' },
  @{ re = '\bstring\.unpack\b';         desc = 'string.unpack  (Lua 5.3+)' },
  @{ re = '\bmath\.tointeger\b';        desc = 'math.tointeger  (Lua 5.3+)' },
  @{ re = '\bcoroutine\.isyieldable\b'; desc = 'coroutine.isyieldable  (Lua 5.3+)' }
)

# Strip Lua comments and string literals so we do not flag text inside them.
function Strip-LuaNoise {
  param([string]$Text)

  $sb = New-Object System.Text.StringBuilder
  $i = 0
  $n = $Text.Length
  while ($i -lt $n) {
    $c = $Text[$i]

    # long comment: --[[ ... ]] or --[==[ ... ]==]
    if ($c -eq '-' -and ($i + 1) -lt $n -and $Text[$i + 1] -eq '-') {
      $m = [regex]::Match($Text.Substring($i), '^--\[(=*)\[[\s\S]*?\]\1\]')
      if ($m.Success) { $i += $m.Length; [void]$sb.Append("`n"); continue }
      $j = $Text.IndexOf("`n", $i)
      if ($j -lt 0) { $j = $n }
      $i = $j
      continue
    }

    # long string: [[ ... ]] or [==[ ... ]==]
    if ($c -eq '[') {
      $m = [regex]::Match($Text.Substring($i), '^\[(=*)\[[\s\S]*?\]\1\]')
      if ($m.Success) { $i += $m.Length; [void]$sb.Append('""'); continue }
    }

    # short string: "..." or '...'
    if ($c -eq '"' -or $c -eq "'") {
      $quote = $c
      $i++
      while ($i -lt $n) {
        if ($Text[$i] -eq '\') { $i += 2; continue }
        if ($Text[$i] -eq $quote) { $i++; break }
        if ($Text[$i] -eq "`n") { break }
        $i++
      }
      [void]$sb.Append('""')
      continue
    }

    [void]$sb.Append($c)
    $i++
  }
  return $sb.ToString()
}

$files = Get-ChildItem -Path $Path -Recurse -Include *.lua,*.script -File -ErrorAction SilentlyContinue
if (-not $files) {
  Write-Host "No .lua/.script files found under: $Path" -ForegroundColor Yellow
  exit 0
}

$total = 0
foreach ($f in $files) {
  $raw = [System.IO.File]::ReadAllText($f.FullName, [System.Text.Encoding]::UTF8)
  $clean = Strip-LuaNoise -Text $raw
  $cleanLines = $clean -split "`n"

  foreach ($p in $patterns) {
    for ($ln = 0; $ln -lt $cleanLines.Count; $ln++) {
      $line = $cleanLines[$ln]
      if ([regex]::IsMatch($line, $p.re)) {
        $total++
        Write-Host ("[5.1-INCOMPATIBLE] {0}:{1}  ->  {2}" -f $f.Name, ($ln + 1), $p.desc) -ForegroundColor Red
        Write-Host ("                   {0}" -f $line.Trim()) -ForegroundColor DarkGray
      }
    }
  }
}

Write-Host ""
if ($total -eq 0) {
  Write-Host ("PASS: scanned {0} Lua file(s), no Lua 5.1 incompatible syntax found." -f $files.Count) -ForegroundColor Green
  exit 0
} else {
  Write-Host ("FAIL: {0} Lua 5.1 incompatible occurrence(s) found." -f $total) -ForegroundColor Red
  exit 1
}

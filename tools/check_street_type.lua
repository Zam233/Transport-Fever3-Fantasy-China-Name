--[[--------------------------------------------------------------------------
  check_street_type.lua - Verify street output is road-like, not settlement-like.

  The user asked: streets should be ROAD names, so why did "Shijiazhuang"
  (a village name) appear? The regional generic table mixes settlement generics
  (zhuang / tun / cun / bao / hot / sumu / gacha / linka / bazaar) with road
  generics, so a street template could end in a village generic.

  The offending suffix list is passed in on the command line (UTF-8) to avoid
  any CJK literal in this source file:
      texlua tools/check_street_type.lua <suffix1> <suffix2> ...

  Usage: texlua tools/check_street_type.lua
         (with suffixes supplied by the PowerShell wrapper)
--------------------------------------------------------------------------]]

local ROOT = "C:/Program Files (x86)/Steam/userdata/167294663/3493540/local/mods/cn_names/"

_G._ = function(s) return s end

local cache = {}
local nativeRequire = require
_G.require = function(name)
  if cache[name] ~= nil then return cache[name] end
  local rest = name:match("^[%w_]+::/(.+)$")
  if rest then
    local f = io.open(ROOT .. "content/" .. rest, "rb")
    if not f then error("not found: " .. rest) end
    local s = f:read("*a"); f:close()
    if s:sub(1, 3) == "\239\187\191" then s = s:sub(4) end
    local c, e = load(s, "@" .. rest)
    if not c then error("syntax " .. rest .. ": " .. tostring(e)) end
    local ok, mod = pcall(c)
    if not ok then error("runtime " .. rest .. ": " .. tostring(mod)) end
    cache[name] = mod
    return mod
  end
  return nativeRequire(name)
end

-- settlement suffixes come from argv (UTF-8), so this file stays ASCII
local SETTLEMENT = {}
for i = 1, #(arg or {}) do SETTLEMENT[#SETTLEMENT + 1] = arg[i] end
if #SETTLEMENT == 0 then
  print("no suffix list supplied; pass them as argv")
  os.exit(2)
end

local entry = dofile(ROOT .. "content/names/names.script.lua")
local D = entry.data()

local STYLES = { "han", "ocean", "subarctic", "west", "mixed" }
local hits = {}
local total = 0

for _, style in ipairs(STYLES) do
  local names = D.streetsNameScriptFn({ style = style, seed = "roadtype" },
                                      { num = 600, lang = "zh_CN" })
  for _, nm in ipairs(names) do
    total = total + 1
    for _, suf in ipairs(SETTLEMENT) do
      if #suf <= #nm and nm:sub(-#suf) == suf then
        hits[#hits + 1] = style .. ":" .. nm
        break
      end
    end
  end
end

print("checked " .. total .. " street names across " .. #STYLES .. " styles")
if #hits == 0 then
  print("PASS: no street name ends in a settlement generic (all road-like).")
  print("")
  for _, style in ipairs(STYLES) do
    local names = D.streetsNameScriptFn({ style = style, seed = "sample" },
                                        { num = 10, lang = "zh_CN" })
    print("  " .. style .. ": " .. table.concat(names, " "))
  end
  os.exit(0)
else
  print("FAIL: " .. #hits .. " settlement-like street name(s):")
  for i = 1, math.min(#hits, 20) do print("  " .. hits[i]) end
  os.exit(1)
end

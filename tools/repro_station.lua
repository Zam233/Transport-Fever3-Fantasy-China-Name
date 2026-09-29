--[[--------------------------------------------------------------------------
  repro_station.lua - Reproduce the station-name bug.

  Reported symptom: the FIRST station gets a proper name (Renmin Road), then
  every following one falls back to the game default ("Stop #1", "Stop #2"...).

  Station naming calls the street function once per station, i.e. many calls
  with num = 1. This tool exercises that pattern plus a few adjacent ones.

  Usage: texlua tools/repro_station.lua
--------------------------------------------------------------------------]]

-- Target install path: argv[1] overrides; default probes staging_area then mods.
local DEFAULT_ROOTS = {
  "C:/Program Files (x86)/Steam/userdata/167294663/3493540/local/staging_area/cn_names/",
  "C:/Program Files (x86)/Steam/userdata/167294663/3493540/local/mods/cn_names/",
}
local ROOT = (arg and arg[1]) or nil
if ROOT and ROOT ~= "" then
  if ROOT:sub(-1) ~= "/" then ROOT = ROOT .. "/" end
else
  for _, cand in ipairs(DEFAULT_ROOTS) do
    local p = io.open(cand .. "mod.json", "rb")
    if p then p:close(); ROOT = cand; break end
  end
end
if not ROOT then
  print("could not find an installed copy; pass the path as argv[1]")
  os.exit(2)
end

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

local D = dofile(ROOT .. "content/names/names.script.lua").data()

local function join(t, n)
  local o = {}
  for i = 1, math.min(n or #t, #t) do o[i] = t[i] end
  return table.concat(o, " ")
end

print("============================================================")
print("A) station pattern: many calls with num = 1")
print("============================================================")
for _, style in ipairs({ "han", "ocean", "subarctic", "west", "mixed" }) do
  local got, empty, first = {}, 0, nil
  for i = 1, 40 do
    local r = D.streetsNameScriptFn({ style = style }, { num = 1, lang = "zh_CN" })
    if i == 1 then first = r end
    if type(r) ~= "table" or #r == 0 then empty = empty + 1 end
    if type(r) == "table" and r[1] then got[#got + 1] = r[1] end
  end
  local uniq, seen = 0, {}
  for _, v in ipairs(got) do if not seen[v] then seen[v] = true; uniq = uniq + 1 end end
  print(string.format("  %-10s 40 calls(num=1): returned=%d empty=%d distinct=%d",
        style, #got, empty, uniq))
  print("             first 12: " .. join(got, 12))
end

print("")
print("============================================================")
print("B) larger batch requests")
print("============================================================")
for _, n in ipairs({ 5, 50, 500, 2000, 5000 }) do
  -- reset between cases so each starts from a fresh pool
  local genmod = require("cn_names::/scripts/streetnamegen.lua")
  genmod.reset()
  local r = D.streetsNameScriptFn({ style = "han" }, { num = n, lang = "zh_CN" })
  print(string.format("  num=%-6d -> returned %d", n, type(r) == "table" and #r or -1))
end

print("")
print("============================================================")
print("C) num = -1 (all)")
print("============================================================")
do
  local genmod = require("cn_names::/scripts/streetnamegen.lua")
  genmod.reset()
  local all = D.streetsNameScriptFn({ style = "han" }, { num = -1, lang = "zh_CN" })
  print("  num=-1 -> returned " .. (type(all) == "table" and #all or -1))
  local all2 = D.streetsNameScriptFn({ style = "han" }, { num = -1, lang = "zh_CN" })
  print("  num=-1 again -> returned " .. (type(all2) == "table" and #all2 or -1)
        .. "   (second call should be 0 or a safe fallback of 1)")
  -- after exhaustion a normal request must STILL work (top-up path)
  local after = D.streetsNameScriptFn({ style = "han" }, { num = 3, lang = "zh_CN" })
  print("  then num=3 -> returned " .. (type(after) == "table" and #after or -1)
        .. "   : " .. (type(after) == "table" and table.concat(after, " ") or ""))
end

print("")
print("============================================================")
print("D) town pattern for comparison: many calls with num = 1")
print("============================================================")
for _, style in ipairs({ "han" }) do
  local got = {}
  for i = 1, 10 do
    local r = D.townsNameScriptFn({ style = style }, { num = 1, lang = "zh_CN" })
    got[#got + 1] = (type(r) == "table" and r[1]) or ("<EMPTY:" .. tostring(#(r or {})) .. ">")
  end
  print("  towns: " .. join(got, 10))
end

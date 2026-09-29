--[[--------------------------------------------------------------------------
  diag_pool.lua - Instrument pool construction to find why it runs dry.

  Observed: num=5000 returns 1, num=-1 returns 1, num=2000 returns 605.
  Hypothesis space:
    H1 pool is built with a small maxTotal (so it is genuinely ~605 long)
    H2 pool is rebuilt on every call and the cursor never persists
    H3 pool key differs between calls, so a fresh empty pool is used each time

  Usage: texlua tools/diag_pool.lua
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
    if not f then error("not found " .. rest) end
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

local gen = require("cn_names::/scripts/streetnamegen.lua")
local data = require("cn_names::/scripts/streetname_data.lua")
gen.setData(data)

-- H1: ask the generator directly, bypassing the pool/cursor layer
print("[H1] generateProfile direct output sizes")
for _, prof in ipairs({
  { "north" },
  { "north", "wu", "lingnan", "central" },
}) do
  local res = gen.generateProfile(prof, { maxTotal = 2000 })
  print(string.format("   regions=%-38s produced=%-5d templates=%-4d suffixPool=%d",
        table.concat(prof, "+"), res.stats.produced, res.stats.templates,
        res.stats.suffixPool or -1))
  local rj = {}
  for k, v in pairs(res.stats.rejects or {}) do rj[#rj + 1] = k .. "=" .. v end
  table.sort(rj)
  print("     rejects: " .. table.concat(rj, " "))
end

-- H1b: bigger maxTotal
print("")
print("[H1b] same, maxTotal = 20000")
for _, prof in ipairs({
  { "north" },
  { "north", "wu", "lingnan", "central" },
}) do
  local res = gen.generateProfile(prof, { maxTotal = 20000 })
  print(string.format("   regions=%-38s produced=%-6d attempts=%d",
        table.concat(prof, "+"), res.stats.produced, res.stats.attempts))
end

-- H2/H3: watch the internal pool/cursor across calls
print("")
print("[H2/H3] internal pool state across repeated request() calls")
gen.reset()
local D = dofile(ROOT .. "content/names/names.script.lua").data()

local function dump(label)
  local pools = gen._pools or {}
  local keys = {}
  for k in pairs(pools) do keys[#keys + 1] = k end
  table.sort(keys)
  print("   " .. label)
  for _, k in ipairs(keys) do
    print(string.format("     key=%-40s len=%-6d cursor=%s",
          k, #pools[k], tostring((gen._cursor or {})[k])))
  end
end

D.streetsNameScriptFn({ style = "han" }, { num = 1, lang = "zh_CN" })
dump("after num=1")
D.streetsNameScriptFn({ style = "han" }, { num = 20, lang = "zh_CN" })
dump("after num=20")
D.streetsNameScriptFn({ style = "han" }, { num = 5000, lang = "zh_CN" })
dump("after num=5000")
D.streetsNameScriptFn({ style = "han" }, { num = -1, lang = "zh_CN" })
dump("after num=-1")

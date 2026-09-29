--[[--------------------------------------------------------------------------
  bench_street.lua - Measure where the street generator spends time.

  Report: frame rate collapses as soon as a station is selected. Suspects:
    S1 generateProfile (pool build) is being re-run on every call
    S2 topUp re-generates ~5000 names whenever the pool is drained
    S3 buildThemePools / buildSuffixPools are rebuilt per call
    S4 per-call string work (seed hashing, splitTokens) is expensive

  Usage: texlua tools/bench_street.lua
--------------------------------------------------------------------------]]

local ROOT = "K:/幻想中文名称/cn_names/"

local nativeRequire = require
local cache = {}
_G._ = function(s) return s end
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

local data = require("cn_names::/scripts/streetname_data.lua")
local gen  = require("cn_names::/scripts/streetnamegen.lua")
gen.setData(data)

local function ms(t0, t1) return (t1 - t0) * 1000 end

--======================================================= component costs ==
print("=== component costs ===")

local t0 = os.clock()
for _ = 1, 20 do gen.buildThemePools() end
print(string.format("  buildThemePools      x20 : %8.1f ms  (%.2f ms each)", ms(t0, os.clock()), ms(t0, os.clock()) / 20))

t0 = os.clock()
for _ = 1, 20 do gen.buildSuffixPools({ "north", "wu", "lingnan", "central" }) end
print(string.format("  buildSuffixPools     x20 : %8.1f ms  (%.2f ms each)", ms(t0, os.clock()), ms(t0, os.clock()) / 20))

t0 = os.clock()
for _ = 1, 200 do gen.getLookups() end
print(string.format("  getLookups (cached) x200 : %8.1f ms", ms(t0, os.clock())))

--======================================================= pool build cost ==
print("")
print("=== pool build cost (cold) ===")
local PROF = { "north", "wu", "lingnan", "central" }
for _, cap in ipairs({ 500, 1200, 5000 }) do
  t0 = os.clock()
  local res = gen.generateProfile(PROF, { maxTotal = 20000, allCap = cap })
  local dt = ms(t0, os.clock())
  print(string.format("  generateProfile cap=%-5d produced=%-5d : %8.1f ms", cap, res.stats.produced, dt))
end

--=========================================== hot path: repeated request ==
print("")
print("=== hot path: repeated calls (what the UI may do) ===")

local function bench(label, fn, n)
  -- warm up
  fn()
  local t = os.clock()
  for _ = 1, n do fn() end
  local dt = ms(t, os.clock())
  print(string.format("  %-42s x%-5d : %8.1f ms  (%.3f ms per call)", label, n, dt, dt / n))
end

gen.reset(); gen.seed("bench")
bench("requestAll, pool has stock", function()
  gen.requestAll(PROF, { maxTotal = 20000, allCap = 5000 })
end, 200)

gen.reset(); gen.seed("bench2")
gen.requestAll(PROF, { maxTotal = 20000, allCap = 5000 })   -- drain
bench("requestAll, pool DRAINED (topUp path)", function()
  gen.requestAll(PROF, { maxTotal = 20000, allCap = 5000 })
end, 20)

gen.reset(); gen.seed("bench3")
bench("request num=1 (station pattern)", function()
  gen.request(PROF, { num = 1 }, { maxTotal = 20000, allCap = 5000 })
end, 500)

-- single-region: drains fast, so topUp runs often
gen.reset(); gen.seed("bench4")
gen.requestAll({ "northwest", "mongol" }, { maxTotal = 20000, allCap = 5000 })
bench("requestAll single-region DRAINED", function()
  gen.requestAll({ "northwest", "mongol" }, { maxTotal = 20000, allCap = 5000 })
end, 10)

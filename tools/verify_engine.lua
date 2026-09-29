--[[--------------------------------------------------------------------------
  verify_engine.lua - Simulate the TF3 engine load path against the INSTALLED mod.

  NOTE: this file is intentionally ASCII-only (no CJK). Windows PowerShell
  mangles non-ASCII text in .lua sources written through it, which corrupted
  an earlier version of this script. Keep it pure ASCII.

  Why this tool exists: the previous mod loaded fine in local unit tests but
  failed in game with "Value is not a table [key = personNameScriptFn]",
  because the entry returned a table directly instead of wrapping it in data().
  Local tests took the return value directly, so they never caught it.
  This tool loads exactly like the engine does: load -> call data() -> take fn.

  Usage: texlua tools/verify_engine.lua
--------------------------------------------------------------------------]]

-- Target install path. Override with argv[1] (e.g. the staging_area copy).
-- Default: the staging_area copy, since that is what the game loads when both
-- a staging_area and a manual-install copy exist (StagingArea has priority).
local DEFAULT_ROOTS = {
  "C:/Program Files (x86)/Steam/userdata/167294663/3493540/local/staging_area/cn_names/",
  "C:/Program Files (x86)/Steam/userdata/167294663/3493540/local/mods/cn_names/",
}

local ROOT = (arg and arg[1]) or nil
if ROOT and ROOT ~= "" then
  if ROOT:sub(-1) ~= "/" then ROOT = ROOT .. "/" end
else
  for _, cand in ipairs(DEFAULT_ROOTS) do
    local probe = io.open(cand .. "mod.json", "rb")
    if probe then probe:close(); ROOT = cand; break end
  end
end
if not ROOT then
  print("could not find an installed copy; pass the path as argv[1]")
  os.exit(2)
end

-- engine-provided translation function
_G._ = function(s) return s end

-- require stub: map "cn_names::/path" to <mod>/content/path
local nativeRequire = require
local cache = {}
_G.require = function(name)
  if cache[name] ~= nil then return cache[name] end
  local rest = name:match("^[%w_]+::/(.+)$")
  if rest then
    local path = ROOT .. "content/" .. rest
    local f = io.open(path, "rb")
    if not f then error("module file not found: " .. path) end
    local s = f:read("*a"); f:close()
    if s:sub(1, 3) == "\239\187\191" then s = s:sub(4) end
    local c, e = load(s, "@" .. rest)
    if not c then error("syntax error in " .. rest .. ": " .. tostring(e)) end
    local ok, mod = pcall(c)
    if not ok then error("runtime error in " .. rest .. ": " .. tostring(mod)) end
    cache[name] = mod
    return mod
  end
  return nativeRequire(name)
end

local pass, fail = 0, 0
local function check(cond, label, detail)
  if cond then
    pass = pass + 1
  else
    fail = fail + 1
    print("  [FAIL] " .. label .. (detail ~= nil and ("  -> " .. tostring(detail)) or ""))
  end
end

local function readFile(p)
  local f = io.open(p, "rb"); if not f then return nil end
  local s = f:read("*a"); f:close()
  if s:sub(1, 3) == "\239\187\191" then s = s:sub(4) end
  return s
end

print("============================================================")
print("Engine load path verification")
print(ROOT)
print("============================================================")

--====================================================== 1. entry file ==
print("")
print("[1] entry file content/names/names.script.lua")

local entrySrc = readFile(ROOT .. "content/names/names.script.lua")
check(entrySrc ~= nil, "entry file exists")
if not entrySrc then os.exit(1) end

local entryChunk, entryErr = load(entrySrc, "@names.script.lua")
check(entryChunk ~= nil, "entry file parses", entryErr)

local okEnter, entryRet = pcall(entryChunk)
check(okEnter, "entry file executes", entryRet)

-- KEY: the engine calls data()
local hasData = (type(entryRet) == "table") and (type(entryRet.data) == "function")
check(hasData, "entry exports data() (engine obtains the function table from it)",
      type(entryRet))
if not hasData then
  print("")
  print("Entry is unusable; aborting.")
  os.exit(1)
end

local okData, D = pcall(entryRet.data)
check(okData, "data() callable", D)
check(type(D) == "table", "data() returns a table (the earlier failure point)", type(D))
if type(D) ~= "table" then os.exit(1) end

check(type(D.personNameScriptFn) == "function", "has personNameScriptFn")
check(type(D.townsNameScriptFn) == "function", "has townsNameScriptFn")
check(type(D.streetsNameScriptFn) == "function", "has streetsNameScriptFn")

--======================================================= 2. name sets ==
print("")
print("[2] name set files (*.names.lua)")

local EXPECT = { "han", "ocean", "subarctic", "west", "mixed" }
for _, key in ipairs(EXPECT) do
  local src = readFile(ROOT .. "content/names/" .. key .. ".names.lua")
  check(src ~= nil, key .. ".names.lua exists")
  if src then
    local chunk, e = load(src, "@" .. key)
    check(chunk ~= nil, key .. " parses", e)
    if chunk then
      _G.data = nil
      local ok, chunkErr = pcall(chunk)
      check(ok, key .. " executes", chunkErr)
      -- NOTE: a .names.lua DEFINES a global data() rather than returning a
      -- function. So after executing the chunk we must read _G.data.
      local dataFn = _G.data
      check(type(dataFn) == "function", key .. " defines global data()", type(dataFn))
      if type(dataFn) == "function" then
        local ok2, tbl = pcall(dataFn)
        check(ok2 and type(tbl) == "table", key .. " data() returns table", tbl)
        if ok2 and type(tbl) == "table" then
          check(type(tbl.name) == "string", key .. " has name")
          check(tbl.townNamesScript ~= nil, key .. " has townNamesScript")
          check(tbl.streetNamesScript ~= nil, key .. " has streetNamesScript")
          check(tbl.personNamesScript ~= nil, key .. " has personNamesScript")
        end
      end
      _G.data = nil
    end
  end
end

--=================================================== 3. five styles ==
print("")
print("[3] actual output per style (simulating engine calls)")

for _, style in ipairs(EXPECT) do
  -- per-style seed so each style is independently deterministic
  local cap = { style = style, seed = "verify-" .. style }

  local okT, towns = pcall(D.townsNameScriptFn, cap, { num = 12, lang = "zh_CN" })
  check(okT, style .. " town call does not error", towns)
  check(type(towns) == "table" and #towns == 12,
        style .. " town returns 12", type(towns) == "table" and #towns or towns)

  local okS, streets = pcall(D.streetsNameScriptFn, cap, { num = 12, lang = "zh_CN" })
  check(okS, style .. " street call does not error", streets)
  check(type(streets) == "table" and #streets == 12,
        style .. " street returns 12", type(streets) == "table" and #streets or streets)

  -- person name MUST be a string (the base game returns a string)
  local okP, male = pcall(D.personNameScriptFn, cap, { isMale = true, lang = "zh_CN" })
  check(okP and type(male) == "string" and #male > 0,
        style .. " male name returns string", male)
  local okP2, female = pcall(D.personNameScriptFn, cap, { isMale = false, lang = "zh_CN" })
  check(okP2 and type(female) == "string" and #female > 0,
        style .. " female name returns string", female)

  --[[ REGRESSION: repeated calls must give DIFFERENT names.
    A bug shipped where the person function re-seeded the RNG on every call
    with a constant seed, so every resident got the identical name
    (observed: all males "Wang Binchen"). This check would have caught it.
  ]]
  local seen = {}
  local distinct = 0
  for _ = 1, 30 do
    local nm = D.personNameScriptFn(cap, { isMale = true, lang = "zh_CN" })
    if type(nm) == "string" and not seen[nm] then
      seen[nm] = true
      distinct = distinct + 1
    end
  end
  check(distinct >= 20,
        style .. " 30 male calls give >=20 distinct names (no re-seed bug)",
        "distinct=" .. distinct)

  local seenF, distinctF = {}, 0
  for _ = 1, 30 do
    local nm = D.personNameScriptFn(cap, { isMale = false, lang = "zh_CN" })
    if type(nm) == "string" and not seenF[nm] then
      seenF[nm] = true
      distinctF = distinctF + 1
    end
  end
  check(distinctF >= 20,
        style .. " 30 female calls give >=20 distinct names (no re-seed bug)",
        "distinct=" .. distinctF)

  if type(towns) == "table" and type(streets) == "table" then
    print("  " .. style)
    print("    towns  : " .. table.concat(towns, " ", 1, 6))
    print("    streets: " .. table.concat(streets, " ", 1, 6))
    print("    persons: " .. tostring(male) .. " / " .. tostring(female))
  end
end

--================================================ 4. num < 0 contract ==
print("")
print("[4] num < 0 returns all")

local okAll, allStreets = pcall(D.streetsNameScriptFn, { style = "han" }, { num = -1, lang = "zh_CN" })
check(okAll and type(allStreets) == "table" and #allStreets > 100,
      "han streets full set > 100", okAll and #allStreets or allStreets)

local okAll2, allTowns = pcall(D.townsNameScriptFn, { style = "han" }, { num = -1, lang = "zh_CN" })
check(okAll2 and type(allTowns) == "table" and #allTowns > 100,
      "han towns full set > 100", okAll2 and #allTowns or allTowns)

--=========================================== 5. real place compliance ==
print("")
print("[5] compliance check: no real province/city names in street output")

local REAL = {
  "\228\184\173\229\155\189", -- placeholder replaced below
}
-- Build the real-name list from UTF-8 byte escapes to keep this file ASCII-only.
local REAL_NAMES = {
  "\229\140\151\228\186\172", -- Beijing
  "\228\184\138\230\181\183", -- Shanghai
  "\229\141\151\228\186\172", -- Nanjing
  "\229\164\169\230\180\165", -- Tianjin
  "\233\135\141\229\186\134", -- Chongqing
  "\229\185\191\229\183\158", -- Guangzhou
  "\230\173\166\230\177\137", -- Wuhan
  "\232\165\191\229\174\137", -- Xian
  "\230\136\144\233\131\189", -- Chengdu
  "\230\157\173\229\183\158", -- Hangzhou
  "\232\139\143\229\183\158", -- Suzhou
  "\229\174\129\230\179\162", -- Ningbo
  "\231\166\143\229\183\158", -- Fuzhou
  "\229\142\166\233\151\168", -- Xiamen
  "\230\152\134\230\152\142", -- Kunming
  "\232\180\181\233\152\179", -- Guiyang
  "\229\133\176\229\183\158", -- Lanzhou
  "\233\131\145\229\183\158", -- Zhengzhou
  "\230\181\142\229\141\151", -- Jinan
  "\233\157\146\229\178\155", -- Qingdao
  "\229\164\167\232\191\158", -- Dalian
  "\230\178\136\233\152\179", -- Shenyang
  "\233\149\191\230\152\165", -- Changchun
  "\233\149\191\230\178\153", -- Changsha
  "\229\141\151\230\152\140", -- Nanchang
  "\229\144\136\232\130\165", -- Hefei
  "\229\141\151\229\174\129", -- Nanning
}
for _, v in ipairs(REAL_NAMES) do REAL[#REAL + 1] = v end

local realHit = {}
for _, style in ipairs(EXPECT) do
  local streets = D.streetsNameScriptFn({ style = style, seed = "comp" },
                                        { num = 400, lang = "zh_CN" })
  for _, nm in ipairs(streets) do
    for _, rp in ipairs(REAL) do
      if nm:find(rp, 1, true) then
        realHit[#realHit + 1] = style .. ":" .. nm
        break
      end
    end
  end
end
check(#realHit == 0, "2000 street names contain no real city name",
      #realHit > 0 and table.concat(realHit, " ", 1, math.min(6, #realHit)) or nil)

--============================================ 6. streets must be ROADS ==
print("")
print("[6] street names must be road-like, not settlement-like")

-- Settlement generics that must never terminate a street name.
-- UTF-8 byte escapes because this file must stay ASCII-only.
local SETTLE = {
  "\229\186\132",             -- zhuang
  "\229\177\175",             -- tun
  "\230\157\221",             -- cun
  "\229\175\168",             -- zhai
  "\229\160\161",             -- bao
  "\229\160\161\229\173\144", -- baozi
  "\229\186\151",             -- dian
  "\233\147\186",             -- pu
  "\232\144\165",             -- ying
  "\229\174\152",             -- guan
  "\230\151\151",             -- qi
  "\230\181\169\231\137\185", -- hot
  "\232\139\143\230\156\168", -- sumu
  "\229\152\142\230\159\165", -- gacha
  "\230\158\151\229\141\161", -- linka
  "\229\183\180\230\137\142", -- bazaar
  "\232\137\190\233\135\140", -- aili
  "\230\183\150\229\176\148", -- naoer
  "\233\131\173\229\139\146", -- guole
}
local settleHit = {}
local settleTotal = 0
for _, style in ipairs(EXPECT) do
  local streets = D.streetsNameScriptFn({ style = style, seed = "roadtype" },
                                        { num = 500, lang = "zh_CN" })
  for _, nm in ipairs(streets) do
    settleTotal = settleTotal + 1
    for _, suf in ipairs(SETTLE) do
      if #suf <= #nm and nm:sub(-#suf) == suf then
        settleHit[#settleHit + 1] = style .. ":" .. nm
        break
      end
    end
  end
end
check(#settleHit == 0,
      settleTotal .. " street names end in a road generic, not a settlement generic",
      #settleHit > 0 and table.concat(settleHit, " ", 1, math.min(6, #settleHit)) or nil)

--=============================================== 7. pool exhaustion =====
print("")
print("[7] pool exhaustion (the station-name bug)")

--[[ REGRESSION: the reported bug was "first station gets Renmin Road, then every
  later one falls back to Stop #1, Stop #2...". Root cause: the street pool was
  only 1200 long and, once drained, request() returned an EMPTY table, so the
  game used its default names. These assertions lock that down:
    (a) many single-item calls (station pattern) all return a name
    (b) a request larger than the old pool size is fully satisfied
    (c) after the pool is drained, further requests top it up instead of failing
]]
local genmod = require("cn_names::/scripts/streetnamegen.lua")

-- (a) station pattern: num = 1 repeatedly
genmod.reset()
local singles, singlesEmpty = {}, 0
for _ = 1, 300 do
  local r = D.streetsNameScriptFn({ style = "han" }, { num = 1, lang = "zh_CN" })
  if type(r) ~= "table" or #r == 0 then singlesEmpty = singlesEmpty + 1
  else singles[#singles + 1] = r[1] end
end
local uniqS, seenS = 0, {}
for _, v in ipairs(singles) do
  if not seenS[v] then seenS[v] = true; uniqS = uniqS + 1 end
end
check(singlesEmpty == 0, "300 single-item street calls all return a name",
      "empty=" .. singlesEmpty)
check(uniqS >= 200, "300 single-item street calls give >=200 distinct names",
      "distinct=" .. uniqS)

-- (b) request bigger than the old 1200 pool
genmod.reset()
local big = D.streetsNameScriptFn({ style = "han" }, { num = 3000, lang = "zh_CN" })
check(type(big) == "table" and #big == 3000,
      "num=3000 is fully satisfied (old pool was only 1200)",
      type(big) == "table" and #big or big)

-- (c) drain via num=-1, then a normal request must still work (top-up path)
genmod.reset()
local drained = D.streetsNameScriptFn({ style = "han" }, { num = -1, lang = "zh_CN" })
local afterDrain = D.streetsNameScriptFn({ style = "han" }, { num = 5, lang = "zh_CN" })
check(type(drained) == "table" and #drained > 1000,
      "num=-1 returns a full set (>1000)", type(drained) == "table" and #drained or drained)
check(type(afterDrain) == "table" and #afterDrain == 5,
      "after draining, num=5 still returns 5 (pool tops up)",
      type(afterDrain) == "table" and #afterDrain or afterDrain)

-- (d) draining twice must not hand out the same names again
genmod.reset()
local first = D.streetsNameScriptFn({ style = "wu" }, { num = -1, lang = "zh_CN" })
local second = D.streetsNameScriptFn({ style = "wu" }, { num = -1, lang = "zh_CN" })
local dupCross = 0
if type(first) == "table" and type(second) == "table" and #second > 0 then
  local setF = {}
  for _, v in ipairs(first) do setF[v] = true end
  for _, v in ipairs(second) do if setF[v] then dupCross = dupCross + 1 end end
end
check(dupCross == 0, "two consecutive full drains share no names",
      "overlap=" .. dupCross)

-- (e) THE ACTUAL IN-GAME BUG: the game calls with num = -1 REPEATEDLY.
-- Observed in game as marker "DBG-c11-n-1-oEMPTY": the street function had been
-- called 11 times, always with num = -1, and from the 2nd call onward it got an
-- EMPTY table, so stations fell back to default names (Stop #1, Stop #2, ...).
genmod.reset()
local emptyCalls, sizes = 0, {}
for _ = 1, 12 do
  local r = D.streetsNameScriptFn({ style = "west" }, { num = -1, lang = "zh_CN" })
  local n = (type(r) == "table") and #r or -1
  sizes[#sizes + 1] = n
  if n <= 0 then emptyCalls = emptyCalls + 1 end
end
check(emptyCalls == 0,
      "12 consecutive num=-1 calls ALL return names (never empty)",
      "empty=" .. emptyCalls .. " sizes=" .. table.concat(sizes, ","))

print("")
print(string.rep("=", 60))
print(string.format("passed %d, failed %d", pass, fail))
if fail > 0 then
  print("ENGINE PATH VERIFICATION FAILED - do not test in game yet.")
  os.exit(1)
end
print("ENGINE PATH VERIFICATION PASSED - the mod loads and generates as the engine does.")
os.exit(0)

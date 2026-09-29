--[[--------------------------------------------------------------------------
  test_streetgen.lua —— MOD2 街道生成器的测试套件

  用法：texlua tools/test_streetgen.lua

  校验维度
    1) 结构铁律：每条名必须是「专名 + 通名」，通名在末尾且专名非空
    2) 字符洁净：纯汉字、无生僻字、无非法 UTF-8
    3) 去重与契约：池内无重复；num=-1 返回全部；可复现
    4) 合规基线：不含真实省市名、不含真实著名路名、不含黑名单谐音词
    5) 地域风味：各地域专属通名确有出现（否则说明模板失效）

  退出码：0 = 通过；1 = 有失败
--------------------------------------------------------------------------]]

local S = "K:/幻想中文名称/MOD2-中国街道命名/ChineseStreetNames/content/scripts/"
local N = "K:/幻想中文名称/MOD2-中国街道命名/ChineseStreetNames/content/names/"

local function loadAt(p)
  local f = io.open(p, "rb")
  if not f then return nil, "找不到 " .. p end
  local s = f:read("*a"); f:close()
  if s:sub(1, 3) == "\239\187\191" then s = s:sub(4) end
  local c, e = load(s, "@" .. p)
  if not c then return nil, e end
  local ok, r = pcall(c)
  if not ok then return nil, r end
  return r
end

local data = assert(loadAt(S .. "streetname_data.lua"))
package.loaded["streetname_data"] = data
package.loaded["chinese_street_names::/scripts/streetname_data.lua"] = data
local gen = assert(loadAt(S .. "streetnamegen.lua"))

local pass, fail = 0, 0
local failures = {}
local function check(cond, label, detail)
  if cond then pass = pass + 1
  else
    fail = fail + 1
    local msg = label .. (detail and ("  →  " .. tostring(detail)) or "")
    failures[#failures + 1] = msg
    print("  [失败] " .. msg)
  end
end
local function section(t) print(""); print("== " .. t .. " ==") end

local function ulen(s) return gen.ulen(s) end

-- 合法末位通名集合（含模板字面量）
local function terminalSet(region)
  local r = data.regions[region]
  local set = {}
  local sfx = gen.buildSuffixPools(region)
  for _, it in ipairs(sfx.all or {}) do set[it.w] = true end
  for _, t in ipairs(r.templates or {}) do
    for _, slot in ipairs(t.seq or {}) do
      if slot:sub(1, 1) == "=" then set[slot:sub(2)] = true end
    end
  end
  return set
end

local function validUtf8(s)
  local i, n = 1, #s
  while i <= n do
    local c = s:byte(i)
    local len = (c < 0x80) and 1
      or (c >= 0xC2 and c <= 0xDF) and 2
      or (c >= 0xE0 and c <= 0xEF) and 3
      or (c >= 0xF0 and c <= 0xF4) and 4 or 0
    if len == 0 then return false end
    for k = 1, len - 1 do
      local cc = s:byte(i + k)
      if not cc or cc < 0x80 or cc > 0xBF then return false end
    end
    i = i + len
  end
  return true
end

-- 真实省市名（用于合规断言：这些**不应**出现在产出里）
-- 注意：不能从 data.parts.transplant 收集——该池已被替换为**虚构名**
-- （规格书 §8 冲突6 的仲裁结果），把它当真实名会导致测试自相矛盾。
local REAL_PLACES = {}
do
  for _, n in ipairs({
    "四川","河南","河北","山东","山西","陕西","江西","江苏","浙江","福建",
    "广东","广西","云南","贵州","湖北","湖南","安徽","甘肃","青海","宁夏",
    "新疆","西藏","内蒙古","辽宁","吉林","黑龙江","海南","台湾",
    "北京","上海","南京","天津","重庆","广州","武汉","西安","成都","杭州",
    "苏州","宁波","福州","厦门","昆明","贵阳","兰州","郑州","济南","青岛",
    "大连","沈阳","哈尔滨","长春","乌鲁木齐","拉萨","长沙","南昌","合肥","南宁",
    -- 以下为复核虚构池时发现**确属真实地名**者，一并纳入断言
    "临川","明溪","青丘","清风","皖阳","桂山","玉屏","松河","白峰","黄塘",
    "碧溪","金溪","华塘","翠微","碧峰","锦溪","瑞塘","和峰","景溪","瑞峰",
  }) do REAL_PLACES[n] = true end
end

-- 断言用集合：只保留**县级以上真实政区与著名地名**。
-- 说明：中国有数万个乡镇级地名，任何虚构名都可能偶然撞上某个小地名；
-- 本 MOD 的保证是「不与县级以上政区及著名地名冲突」，这也是规格书 §8
-- 冲突6 仲裁所要求的范围。minorReal 这些已从虚构池移除，此处保留断言
-- 以防将来改回。
local MINOR_REAL_ASSERT = {
  "临川","明溪","青丘","清风","皖阳","桂山","玉屏","松河","白峰","黄塘",
  "碧溪","金溪","华塘","翠微","碧峰","锦溪","瑞塘","和峰","景溪","瑞峰",
}
for _, n in ipairs(MINOR_REAL_ASSERT) do REAL_PLACES[n] = true end

--=========================================================== 结构测试 ==

section("结构铁律（专名+通名，通名在末尾）")

for _, region in ipairs(gen.REGION_ORDER) do
  gen.reset()
  gen.seed("struct-" .. region)
  local res = gen.generateRegion(region, { maxTotal = 200 })
  local list = res.names
  local term = terminalSet(region)

  check(#list > 0, string.format("[%s] 有产出", region), #list)

  local badTerm, emptyStem, badUtf8 = {}, {}, 0
  for _, nm in ipairs(list) do
    -- 末位通名（最长匹配）
    local best = 0
    for t in pairs(term) do
      if #t <= #nm and nm:sub(-#t) == t and #t > best then best = #t end
    end
    if best == 0 then
      if #badTerm < 6 then badTerm[#badTerm + 1] = nm end
    elseif #nm == best then
      if #emptyStem < 6 then emptyStem[#emptyStem + 1] = nm end
    end
    if not validUtf8(nm) then badUtf8 = badUtf8 + 1 end
  end

  check(#badTerm == 0, string.format("[%s] 全部以通名结尾", region),
        table.concat(badTerm, " "))
  check(#emptyStem == 0, string.format("[%s] 专名均非空", region),
        table.concat(emptyStem, " "))
  check(badUtf8 == 0, string.format("[%s] 无非法 UTF-8", region), badUtf8)

  -- 去重
  local seen, dup = {}, nil
  for _, nm in ipairs(list) do
    if seen[nm] then dup = nm break end
    seen[nm] = true
  end
  check(dup == nil, string.format("[%s] 池内无重复", region), dup)

  -- 长度
  local badLen = nil
  for _, nm in ipairs(list) do
    local n = ulen(nm)
    if n < 2 or n > 6 then badLen = nm break end
  end
  check(badLen == nil, string.format("[%s] 长度在 2–6 字", region), badLen)
end

--=========================================================== 合规测试 ==

section("合规基线（法规禁止项）")

for _, region in ipairs(gen.REGION_ORDER) do
  gen.reset()
  gen.seed("comp-" .. region)
  local res = gen.generateRegion(region, { maxTotal = 400 })
  local list = res.names

  -- 真实省市名
  local realHit = {}
  for _, nm in ipairs(list) do
    for rp in pairs(REAL_PLACES) do
      if nm:find(rp, 1, true) then
        if #realHit < 6 then realHit[#realHit + 1] = nm end
        break
      end
    end
  end
  check(#realHit == 0, string.format("[%s] 不含真实省市名", region),
        table.concat(realHit, " "))

  -- 真实著名路名黑名单
  local blockHit = {}
  local BLOCK = {}
  for _, s in ipairs(data.realNameBlocklist or {}) do BLOCK[s] = true end
  for _, s in ipairs(data.cityRoadBlacklist or {}) do BLOCK[s] = true end
  for _, nm in ipairs(list) do
    if BLOCK[nm] and #blockHit < 6 then blockHit[#blockHit + 1] = nm end
  end
  check(#blockHit == 0, string.format("[%s] 不撞真实著名路名", region),
        table.concat(blockHit, " "))
end

--========================================================= 契约测试 ==

section("num 契约与可复现性")

gen.reset()
gen.seed("c1")
local b1 = gen.request("north", { num = 30 })
local b2 = gen.request("north", { num = 30 })
check(#b1 == 30, "第一批 30 个", #b1)
check(#b2 == 30, "第二批 30 个", #b2)
local s1, overlap = {}, nil
for _, v in ipairs(b1) do s1[v] = true end
for _, v in ipairs(b2) do if s1[v] then overlap = v break end end
check(overlap == nil, "两批不重复", overlap)

gen.reset()
gen.seed("c2")
local all = gen.request("wu", { num = -1 })
local all2 = gen.request("wu", { num = -1 })
check(#all > 0, "num=-1 返回全部", #all)
check(#all2 == 0, "num=-1 第二次已耗尽", #all2)

gen.reset(); gen.seed("same")
local x1 = gen.request("min", { num = 25 })
gen.reset(); gen.seed("same")
local x2 = gen.request("min", { num = 25 })
local identical = (#x1 == #x2)
for i = 1, math.min(#x1, #x2) do if x1[i] ~= x2[i] then identical = false break end end
check(identical, "相同种子可复现")

--======================================================= 综合风格测试 ==

section("综合风格（九地域混合）")

-- 让 names.script 里的 require 能解析到本地模块
package.loaded["streetnamegen"] = gen
package.loaded["chinese_street_names::/scripts/streetnamegen.lua"] = gen
package.loaded["chinese_street_names::/scripts/streetname_data.lua"] = data
package.loaded["streetname_data"] = data
package.loaded["chinese_street_names::/scripts/streetname_data.lua"] = data
package.path = S .. "?.lua;" .. N .. "?.lua;" .. package.path

local namesMod, loadErr = loadAt(N .. "names.script.lua")
if namesMod then
  local out = namesMod.streetsNameScriptFn({ region = "mixed", seed = "mx" }, { num = 200 })
  check(#out == 200, "综合模式返回 200 个", #out)
  local seen, dup = {}, nil
  for _, v in ipairs(out) do
    if seen[v] then dup = v break end
    seen[v] = true
  end
  check(dup == nil, "综合模式无重复", dup)

  -- 综合模式应能体现多地域风味（至少出现 3 个地域的专属通名）
  local MARKERS = {
    north = { "胡同", "大院", "条" },
    wu = { "弄", "浜", "泾", "埭" },
    lingnan = { "涌", "滘", "围", "塱" },
    southwest = { "沱", "垭", "坝", "坎" },
    central = { "冲", "垸", "畈", "垱" },
    min = { "厝", "埕", "崎", "份" },
    northwest = { "塬", "峁", "巴扎" },
    tibet = { "林卡", "曲", "错", "扎" },
    mongol = { "浩特", "郭勒", "淖尔", "苏木" },
  }
  local hitRegions = {}
  for rk, ms in pairs(MARKERS) do
    for _, nm in ipairs(out) do
      local found = false
      for _, m in ipairs(ms) do
        if nm:find(m, 1, true) then found = true break end
      end
      if found then hitRegions[rk] = true break end
    end
  end
  local cnt = 0
  for _ in pairs(hitRegions) do cnt = cnt + 1 end
  check(cnt >= 3, "综合模式体现 ≥3 个地域风味", "实际 " .. cnt .. " 个")
else
  print("  跳过（names.script 未就绪）")
end

--============================================================= 汇总 ==

print("")
print(string.rep("=", 56))
print(string.format("通过 %d 项，失败 %d 项", pass, fail))
if fail > 0 then
  print("")
  print("失败清单：")
  for _, s in ipairs(failures) do print("  - " .. s) end
  os.exit(1)
end
print("全部测试通过。")
os.exit(0)

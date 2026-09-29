--[[--------------------------------------------------------------------------
  test_namegen.lua —— namegen.lua 的单元测试

  用法：
      texlua tools/test_namegen.lua

  两种模式：
    1. 合成样本模式：用内联的迷你词表验证生成器逻辑（不依赖数据导出）
    2. 真实数据模式：若 MOD1 的 townname_data.lua 已生成，则对它跑全量回归

  退出码：0 = 全部通过；1 = 有失败。
--------------------------------------------------------------------------]]

-- 让 require 能找到 MOD1 的生成器
local MOD1_SCRIPTS = "K:/幻想中文名称/MOD1-中国城市名称集/ChineseTownNames/content/scripts/"
local MOD1_NAMES   = "K:/幻想中文名称/MOD1-中国城市名称集/ChineseTownNames/content/names/"

local realRequire = require
local function loadModule(name, searchDirs)
  for _, dir in ipairs(searchDirs) do
    local path = dir .. name .. ".lua"
    local f = io.open(path, "rb")
    if f then
      local src = f:read("*a")
      f:close()
      if src:sub(1, 3) == "\239\187\191" then src = src:sub(4) end
      local chunk, err = load(src, "@" .. path)
      if not chunk then error("加载失败 " .. path .. ": " .. tostring(err)) end
      return chunk()
    end
  end
  -- 找不到就退回系统 require
  return realRequire(name)
end

local gen = loadModule("namegen", { MOD1_SCRIPTS, MOD1_NAMES })
package.loaded["chinese_town_names::/scripts/namegen.lua"] = gen
package.loaded["chinese_town_names::/scripts/townname_data.lua"] = true

--=========================================================== 测试框架 ==

local pass, fail = 0, 0
local failures = {}

local function check(cond, label, detail)
  if cond then
    pass = pass + 1
  else
    fail = fail + 1
    failures[#failures + 1] = label .. (detail and ("  →  " .. tostring(detail)) or "")
    print("  [失败] " .. label .. (detail and ("  →  " .. tostring(detail)) or ""))
  end
end

local function section(t)
  print("")
  print("== " .. t .. " ==")
end

-- UTF-8 字符数
local function ulen(s) return gen.ulen(s) end

--====================================================== 合成样本词表 ==

-- 刻意构造一个最小的汉地风格词表：模板末位为通名
local mockHan = {
  templates = {
    { id = "H1", weight = 30, seq = { "single", "suffix" } },        -- 2 字
    { id = "H8", weight = 20, seq = { "direction", "single", "suffix" } }, -- 3 字
    { id = "H5", weight = 15, seq = { "surname", "=家", "suffix" } }, -- 3 字
    { id = "H10", weight = 10, seq = { "color", "terrain_suffix" } }, -- 2 字
  },
  suffixes = {
    { w = "州", weight = 20 }, { w = "县", weight = 10 },
    { w = "镇", weight = 15 }, { w = "庄", weight = 15 },
    { w = "城", weight = 10 }, { w = "堡", weight = 8 },
  },
  terrain_suffix = {
    { w = "山", weight = 10 }, { w = "河", weight = 10 },
    { w = "湖", weight = 8 },  { w = "泉", weight = 6 },
  },
  auspicious_suffix = { { w = "安", weight = 5 }, { w = "宁", weight = 5 } },
  parts = {
    single      = { { w = "临" }, { w = "望" }, { w = "怀" }, { w = "永" }, { w = "长" } },
    direction   = { { w = "东" }, { w = "西" }, { w = "南" }, { w = "北" } },
    surname     = { { w = "张" }, { w = "王" }, { w = "李" }, { w = "赵" } },
    color       = { { w = "青" }, { w = "黄" }, { w = "白" }, { w = "金" } },
  },
  constraints = { minLen = 2, maxLen = 4 },
  banned = {
    chars = { "死", "亡" },
    suffixes = {},
    realNames = { "长安", "东州" },
  },
}

--=========================================================== 测试用例 ==

section("基础工具")

-- UTF-8 长度
check(ulen("长安") == 2, "ulen 中文 2 字", ulen("长安"))
check(ulen("张家庄") == 3, "ulen 中文 3 字", ulen("张家庄"))
check(ulen("abc") == 3, "ulen ASCII", ulen("abc"))
check(ulen("") == 0, "ulen 空串", ulen(""))

-- 随机数范围
gen.seed("range-test")
local inRange = true
for _ = 1, 2000 do
  local r = gen.rand(10)
  if r < 0 or r > 9 then inRange = false break end
end
check(inRange, "rand(10) 恒在 [0,9]")

-- 随机数分布（粗略均匀性）
gen.seed("dist-test")
local buckets = {}
for i = 1, 10 do buckets[i] = 0 end
for _ = 1, 20000 do
  local r = gen.rand(10) + 1
  buckets[r] = buckets[r] + 1
end
local minB, maxB = math.huge, 0
for i = 1, 10 do
  if buckets[i] < minB then minB = buckets[i] end
  if buckets[i] > maxB then maxB = buckets[i] end
end
-- 期望每个桶 2000，允许 ±40%
check(minB > 1200 and maxB < 2800, "rand 分布大致均匀",
      string.format("min=%d max=%d", minB, maxB))

-- sample 无重复且数量正确
gen.seed("sample-test")
local pool = {}
for i = 1, 10 do pool[i] = "n" .. i end
local got = gen.sample(pool, 5)
local seenS = {}
local dupS = false
for _, v in ipairs(got) do
  if seenS[v] then dupS = true end
  seenS[v] = true
end
check(#got == 5, "sample 返回 5 个", #got)
check(not dupS, "sample 无重复")
check(#pool == 10, "sample 不修改原数组", #pool)

-- sample 请求数超过池大小
local got2 = gen.sample(pool, 99)
check(#got2 == 10, "sample 超量请求返回全池", #got2)

section("构词（合成样本）")

gen.seed("compose-test")
local res = gen.generatePool(mockHan, "mockHan", { maxTotal = 300 })
check(res.stats.produced > 0, "生成池非空", res.stats.produced)

-- 每个名字都必须以通名结尾
local suffixSet = {}
for _, s in ipairs(mockHan.suffixes) do suffixSet[s.w] = true end
for _, s in ipairs(mockHan.terrain_suffix) do suffixSet[s.w] = true end

local badTail = {}
for _, name in ipairs(res.names) do
  local tail2 = name:sub(-3)   -- 末 1 个汉字（UTF-8 3 字节）
  local ok = false
  for suf in pairs(suffixSet) do
    if tail2 == suf then ok = true break end
  end
  if not ok then badTail[#badTail + 1] = name end
end
check(#badTail == 0, "全部名字以通名结尾", table.concat(badTail, ","))

-- 无重复
local seenN = {}
local dupN = nil
for _, name in ipairs(res.names) do
  if seenN[name] then dupN = name break end
  seenN[name] = true
end
check(dupN == nil, "生成池内无重复", dupN)

-- 长度约束
local badLen = {}
for _, name in ipairs(res.names) do
  local n = ulen(name)
  if n < 2 or n > 4 then badLen[#badLen + 1] = name end
end
check(#badLen == 0, "全部满足 2–4 字约束", table.concat(badLen, ","))

-- 禁用字过滤
local badChar = nil
for _, name in ipairs(res.names) do
  if name:find("死", 1, true) or name:find("亡", 1, true) then badChar = name break end
end
check(badChar == nil, "禁用字未出现", badChar)

-- 真实地名黑名单过滤
local hadReal = nil
for _, name in ipairs(res.names) do
  if name == "长安" or name == "东州" then hadReal = name break end
end
check(hadReal == nil, "真实地名黑名单生效", hadReal)

section("num 契约（去重池）")

gen.reset()
gen.seed("contract-test")
local batch1 = gen.request(mockHan, "mockHan", { num = 10 })
local batch2 = gen.request(mockHan, "mockHan", { num = 10 })
check(#batch1 == 10, "第一批返回 10 个", #batch1)
check(#batch2 == 10, "第二批返回 10 个", #batch2)

local overlap = nil
local set1 = {}
for _, n in ipairs(batch1) do set1[n] = true end
for _, n in ipairs(batch2) do
  if set1[n] then overlap = n break end
end
check(overlap == nil, "两批之间不重复", overlap)

-- num = -1 返回全部剩余
gen.reset()
gen.seed("contract-all")
local all = gen.request(mockHan, "mockHan", { num = -1 })
check(#all > 0, "num=-1 返回全部", #all)
local all2 = gen.request(mockHan, "mockHan", { num = -1 })
check(#all2 == 0, "num=-1 第二次已耗尽", #all2)

-- 池耗尽时不报错、不重名
gen.reset()
gen.seed("exhaust")
local huge = gen.request(mockHan, "mockHan", { num = 99999 })
local seenH = {}
local dupH = nil
for _, n in ipairs(huge) do
  if seenH[n] then dupH = n break end
  seenH[n] = true
end
check(dupH == nil, "超量请求仍不重名", dupH)

section("可复现性")

gen.reset(); gen.seed("same")
local a1 = gen.request(mockHan, "mockHan", { num = 20 })
gen.reset(); gen.seed("same")
local a2 = gen.request(mockHan, "mockHan", { num = 20 })
local identical = (#a1 == #a2)
if identical then
  for i = 1, #a1 do
    if a1[i] ~= a2[i] then identical = false break end
  end
end
check(identical, "相同种子产生相同序列")

gen.reset(); gen.seed("diffA")
local b1 = gen.request(mockHan, "mockHan", { num = 20 })
gen.reset(); gen.seed("diffB")
local b2 = gen.request(mockHan, "mockHan", { num = 20 })
local sameCount = 0
for i = 1, math.min(#b1, #b2) do
  if b1[i] == b2[i] then sameCount = sameCount + 1 end
end
check(sameCount < #b1, "不同种子产生不同序列", "相同位置数=" .. sameCount)

--===================================================== 真实数据模式 ==

section("真实数据（若已导出）")

local realData = nil
local f = io.open(MOD1_SCRIPTS .. "townname_data.lua", "rb")
if f then
  local src = f:read("*a")
  f:close()
  if src:sub(1, 3) == "\239\187\191" then src = src:sub(4) end
  local chunk, err = load(src, "@townname_data.lua")
  if chunk then
    local ok, mod = pcall(chunk)
    if ok then realData = mod else print("  数据模块执行失败：" .. tostring(mod)) end
  else
    print("  数据模块语法错误：" .. tostring(err))
  end
else
  print("  未找到 townname_data.lua，跳过真实数据回归。")
end

if realData and realData.town then
  for _, key in ipairs({ "han", "ocean", "northwest", "subarctic" }) do
    local style = realData.town[key]
    if not style then
      check(false, "真实数据含风格 " .. key)
    else
      gen.reset()
      gen.seed(key)
      local r = gen.generatePool(style, key, { maxTotal = 500 })
      local produced = r.stats.produced
      local label = string.format("[%s] 生成 %d 个", key, produced)
      check(produced >= 100, label .. "（期望 ≥100）")

      -- 末位通名检查：直接复用生成器的 buildPools 作为权威通名来源。
      -- （夹具自己重新解析原始数据极易产生假阳性——已因此误报过两轮。）
      local pools = gen.buildPools(style)
      local sfx = {}
      for _, slot in ipairs({ "suffix", "terrain_suffix", "auspicious_suffix" }) do
        for _, it in ipairs(pools[slot] or {}) do sfx[it.w] = true end
      end
      -- 模板里的字面量通名（如 "=州"、"=家"）也要算作合法末位
      for _, t in ipairs(gen.buildTemplates(style, pools)) do
        for _, s in ipairs(t.seq) do
          if s:sub(1, 1) == "=" then sfx[s:sub(2)] = true end
        end
      end

      local bad = 0
      for _, name in ipairs(r.names) do
        local best = 0
        for s in pairs(sfx) do
          if #s <= #name and name:sub(-#s) == s and #s > best then best = #s end
        end
        if best == 0 then bad = bad + 1 end
      end
      check(bad == 0, string.format("[%s] 全部以通名结尾（异常 %d/%d）", key, bad, #r.names))
    end
  end
else
  print("  跳过（数据未就绪）")
end

--====================================== 词汇纯净度回归（用户要求） ======

section("词汇纯净度（物产词 / 华人信仰词）")

if realData and realData.town then
  -- 校验分两层，避免用子串匹配做语义断言（松岭含"松"却是合法地名）：
  --   层 1（池级）：被禁的单字物产不得出现在任何专名池里
  --   层 2（产出级）：被禁的多字物产词不得出现在任何生成结果里
  local SINGLE_PRODUCTS = {
    "鲛", "鲨", "鲸", "蚌", "珠", "鲍", "鲎", "螺", "蚝", "贝",
    "虾", "蟹", "鲟", "鲤", "椰", "蔗", "椒", "檀", "漆",
    "瓜", "棉", "枣", "参", "鳇", "鲑", "貂", "鹿", "狍",
    "獾", "狐", "鹤", "蕨", "蘑", "柏", "槐", "樟", "枫",
    "桐", "桑", "梨", "茶", "竹", "莲", "荷", "菊", "荔",
    "蒲", "芦", "芷", "蓼",
  }
  local MULTI_PRODUCTS = {
    "珊瑚", "玳瑁", "槟榔", "榴莲", "胡椒", "豆蔻", "沉香",
    "苏木", "橡胶", "树胶", "燕窝", "红毛", "红毛丹", "山竹",
    "沙枣", "红柳", "梭梭", "芦苇", "甘草", "葡萄", "苜蓿",
    "海参", "大马哈", "哈什", "哈什蚂", "蕨菜", "木耳",
    "松子", "蓝莓", "都柿", "红松", "白桦", "水獭", "野鸭",
  }
  local FAITH_GOOD = { "三宝", "天后", "观音", "关帝", "关公", "天妃", "水仙" }

  local PRODUCT_KEYS = { "han", "ocean", "northwest", "subarctic" }

  -- 层 1：池级
  local poolLeak = {}
  for _, key in ipairs(PRODUCT_KEYS) do
    local style = realData.town[key]
    if style then
      local pools = gen.buildPools(style)
      for slot, items in pairs(pools) do
        for _, it in ipairs(items) do
          for _, bad in ipairs(SINGLE_PRODUCTS) do
            if it.w == bad then
              poolLeak[#poolLeak + 1] = string.format("%s.%s=%s", key, slot, bad)
            end
          end
        end
      end
    end
  end
  check(#poolLeak == 0,
        string.format("池级：单字物产未进任何池（泄漏 %d）", #poolLeak),
        table.concat(poolLeak, " ", 1, math.min(8, #poolLeak)))

  -- 层 2：产出级
  for _, key in ipairs(PRODUCT_KEYS) do
    local style = realData.town[key]
    if style then
      gen.reset()
      local r = gen.generatePool(style, key, { maxTotal = 800 })
      local hit = {}
      for _, name in ipairs(r.names) do
        for _, bad in ipairs(MULTI_PRODUCTS) do
          if name:find(bad, 1, true) then
            hit[#hit + 1] = name
            break
          end
        end
      end
      check(#hit == 0,
            string.format("[%s] 产出级：无多字物产词（命中 %d）", key, #hit),
            table.concat(hit, " ", 1, math.min(6, #hit)))
    end
  end

  -- 海洋中国：信仰词应确实出现（不是被过度过滤掉）
  local oceanStyle = realData.town.ocean
  if oceanStyle then
    gen.reset()
    local r = gen.generatePool(oceanStyle, "ocean", { maxTotal = 800 })
    local faithHits, faithSample = 0, {}
    for _, name in ipairs(r.names) do
      for _, g in ipairs(FAITH_GOOD) do
        if name:find(g, 1, true) then
          faithHits = faithHits + 1
          if #faithSample < 10 then faithSample[#faithSample + 1] = name end
          break
        end
      end
    end
    check(faithHits > 0,
          "[ocean] 华人信仰词（三宝/天后等）有产出",
          "命中 " .. faithHits .. " 个：" .. table.concat(faithSample, " "))
  end
else
  print("  跳过（数据未就绪）")
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

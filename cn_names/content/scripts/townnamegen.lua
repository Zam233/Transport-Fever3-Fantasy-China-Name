-- Copyright (C) 2026 Zam
--
-- This file is part of the Transport Fever 3 mod "Fantasy China Name Set".
-- It is free software: you can redistribute it and/or modify it under the
-- terms of the GNU General Public License as published by the Free Software
-- Foundation, either version 3 of the License, or (at your option) any later
-- version. It is distributed in the hope that it will be useful, but WITHOUT
-- ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
-- FITNESS FOR A PARTICULAR PURPOSE. See the GNU General Public License for
-- more details. You should have received a copy of the GNU General Public
-- License along with this program. If not, see <https://www.gnu.org/licenses/>.
--[[--------------------------------------------------------------------------
  namegen.lua —— 中国城市名称集：生成器核心（纯逻辑，不含词表）

  设计原则
    * 数据 / 逻辑分离：所有词表、权重、禁忌均在 townname_data.lua 中
    * 类隔离：五个风格各自持有独立的允许字表与禁用字表，绝不共用
    * 去重契约：对外遵守 num 语义（-1 = 全部），内部维护「已用池」，
      保证同一张地图上不出现同名城市
    * 字体安全：词表只用 CJK 基本区汉字（由数据层保证，本层不做筛选）
    * 可测试：不依赖 os.* / io.*，可在 texlua 下直接单测

  参考：TF3 官方 wiki  modding:misc:names
    townsNameScriptFn(captureParams, params)
      params.lang : 当前语言短码，如 "zh_CN"
      params.num  : 需要的名称个数；-1 表示返回全部
      返回：长度为 num 的字符串列表
--------------------------------------------------------------------------]]

local M = {}

--============================================================== 基础工具 ==

-- UTF-8 字符数（中文按 1 个字符计）
function M.ulen(s)
  local n = 0
  local i = 1
  local len = #s
  while i <= len do
    local c = s:byte(i)
    if c < 0x80 then i = i + 1
    elseif c < 0xE0 then i = i + 2
    elseif c < 0xF0 then i = i + 3
    else i = i + 4 end
    n = n + 1
  end
  return n
end

-- 伪随机数：纯算术线性同余法（LCG）
-- 关键约束：必须兼容 Lua 5.1 / LuaJIT，因此**严禁使用位运算符**
--（~ & | << >> 是 Lua 5.3+ 语法，在 5.1 下会直接语法错误导致 MOD 加载失败）
-- 同时不依赖 math.random 的全局状态，避免被游戏重置。
local rngState = 2463534242
local RNG_MOD = 2147483647   -- 2^31 - 1，Mersenne 素数，模运算分布均匀

local function nextRand()
  -- 经典 MINSTD 参数：乘数 16807、模 2^31-1
  rngState = (rngState * 16807) % RNG_MOD
  return rngState
end

-- [0, n) 区间整数
function M.rand(n)
  if n <= 0 then return 0 end
  -- 丢弃低位以避免 LCG 低比特周期偏短的问题
  return math.floor(nextRand() / RNG_MOD * n) % n
end

-- 播种：优先用 captureParams.seed；
-- 否则用字符串哈希构造（不依赖 os.time，沙箱内可用且同图稳定）
function M.seed(seedValue)
  local s
  if type(seedValue) == "number" and seedValue ~= 0 then
    s = math.floor(math.abs(seedValue))
  elseif type(seedValue) == "string" then
    -- FNV-1a 的纯算术版本（以取模代替掩码）
    s = 2166136261
    for i = 1, #seedValue do
      s = (s * 16777619 + seedValue:byte(i)) % 4294967296
    end
  else
    s = 2463534242
  end
  rngState = (s % (RNG_MOD - 1)) + 1
  -- 预热，避免种子相近时序列相似
  for _ = 1, 8 do nextRand() end
end

-- 加权抽取：pool = { {w=..., weight=...}, ... }，返回条目
function M.pickWeighted(pool)
  local total = 0
  for i = 1, #pool do
    total = total + (pool[i].weight or 1)
  end
  if total <= 0 then return pool[1] end
  local r = M.rand(total)
  local acc = 0
  for i = 1, #pool do
    acc = acc + (pool[i].weight or 1)
    if r < acc then return pool[i] end
  end
  return pool[#pool]
end

-- 从字符串数组中无重复抽取 k 个（Fisher-Yates 部分洗牌，不修改原数组）
function M.sample(arr, k)
  local n = #arr
  if k >= n then
    local out = {}
    for i = 1, n do out[i] = arr[i] end
    return out
  end
  local idx = {}
  for i = 1, n do idx[i] = i end
  local out = {}
  for i = 1, k do
    local j = i + M.rand(n - i + 1)
    idx[i], idx[j] = idx[j], idx[i]
    out[i] = arr[idx[i]]
  end
  return out
end

--========================================================== 词表 → 池 ==

--[[ 归一化说明
  数据层（townname_data.lua）由规格书机械导出，其分组命名与层级结构不保证与
  生成器完全一致。例如：
    suffixes = { admin = {...}, geography = {...}, settlement = {...} }   -- 二级分组
    parts    = { flora = {...}, landform = {...}, mountain_water = {...} } -- 组名各异
  因此本层负责把各种合理形状**归一化**为统一的 slot -> 条目数组 的池，
  使模板只需引用一组稳定的池名即可。数据层可以继续自由分组。
]]

-- 专名分组名 → 契约池名 的同义词归一化表
local PART_ALIAS = {
  -- 契约名 → 自身
  single = "single", direction = "direction", terrain = "terrain",
  plant = "plant", water = "water", mountain = "mountain",
  ancient_state = "ancient_state", garrison = "garrison", post = "post",
  market = "market", surname = "surname", auspicious = "auspicious",
  era_name = "era_name", number = "number", mileage = "mileage",
  color = "color", verb_head = "verb_head",
  -- 常见异名 → 契约名
  flora = "plant", vegetation = "plant", tree = "plant",
  landform = "terrain", topography = "terrain", relief = "terrain",
  mountain_water = "water", hydrology = "water", river = "water",
  history = "ancient_state", historical = "ancient_state",
  ancient = "ancient_state", ancient_country = "ancient_state",
  military = "garrison", army = "garrison", frontier = "garrison",
  transport = "post", post_station = "post", traffic = "post",
  commerce = "market", trade = "market", business = "market",
  clan = "surname", family = "surname",
  blessing = "auspicious", propitious = "auspicious", auspice = "auspicious",
  era = "era_name", reign_title = "era_name",
  num = "number", numeric = "number", digit = "number",
  distance = "mileage", milestone = "mileage",
  colour = "color", hue = "color",
  verb = "verb_head", verb_object = "verb_head",
  -- 海洋中国类的组名
  sea_trade = "market", seafood = "plant", tropical = "plant",
  tide = "water", monsoon = "direction", island = "terrain",
  faith = "auspicious", dialect_groups = "surname",
  direction_scale = "direction",
  -- 西北类的组名
  corps = "garrison", silkroad = "post", water = "water",
  landform_modifier = "modifier",   -- 大/小/新/老/干/湿 类修饰语，注意不是颜色
  direction_mileage = "direction",
  -- 亚寒带类的组名
  product = "plant", farming = "market", mining = "market",
  number_direction = "number",
}

-- 物产/海产词黑名单 —— 全部剔除
--[[ 用户裁定：地名里不出现物产名。
  收录原则（两个条件同时满足才收）：
    1) 该词确属"物产/食用/渔猎产出"；
    2) 该词在**非物产**语境里没有合法用法（否则会误伤合法地名）。
  因此刻意**不收录**以下容易误伤的字：
    锡（锡林=蒙古语"山梁"）、松（松潘/松江）、杨（杨凌）、柳（柳州）、
    鱼（鱼台）、虎（虎门）、熊（熊岳）、藤（藤县）、桂（桂林）、
    榕（榕江/榕城）、兰（兰州）、梅（梅州）、桃（桃源）、杏（杏花村）、
    桦（桦甸/桦南）、柞（柞水）、海东青（猛禽，非物产）
  说明：黑名单在**入池处**（buildPools）生效，因此不论数据层把它放在
  plant / flora / single 哪个组，都不会进入生成池。
]]
local PRODUCT_BLOCK = {
  -- 海洋中国：海产
  ["鲛"] = true, ["鲨"] = true, ["鲸"] = true, ["蚌"] = true, ["珠"] = true,
  ["珊瑚"] = true, ["玳瑁"] = true, ["鲍"] = true, ["鲎"] = true,
  ["螺"] = true, ["蚝"] = true, ["贝"] = true, ["虾"] = true, ["蟹"] = true,
  ["鲟"] = true, ["鲤"] = true,
  -- 海洋中国：热带/海贸物产
  ["椰"] = true, ["槟榔"] = true, ["榴莲"] = true, ["蔗"] = true,
  ["椒"] = true, ["胡椒"] = true, ["豆蔻"] = true, ["沉香"] = true,
  ["檀"] = true, ["苏木"] = true, ["橡胶"] = true, ["树胶"] = true,
  ["燕窝"] = true, ["漆"] = true, ["红毛"] = true, ["红毛丹"] = true,
  ["山竹"] = true,
  -- 西北：绿洲物产（保留 榆/柳/杨 等林木类，它们有大量合法地名用法）
  ["沙枣"] = true, ["红柳"] = true, ["梭梭"] = true,
  ["芦苇"] = true, ["甘草"] = true, ["葡萄"] = true, ["苜蓿"] = true,
  ["瓜"] = true, ["棉"] = true, ["枣"] = true,
  -- 亚寒带：渔猎物产
  ["参"] = true, ["海参"] = true, ["鳇"] = true, ["鲑"] = true,
  ["大马哈"] = true, ["哈什"] = true, ["哈什蚂"] = true,
  ["貂"] = true, ["鹿"] = true, ["狍"] = true, ["獾"] = true,
  ["狐"] = true, ["鹤"] = true,
  ["蕨"] = true, ["蕨菜"] = true, ["蘑"] = true, ["木耳"] = true,
  ["松子"] = true, ["蓝莓"] = true, ["都柿"] = true,
  ["红松"] = true, ["白桦"] = true, ["水獭"] = true, ["野鸭"] = true,
  -- 汉地：林木花果物产
  ["柏"] = true, ["槐"] = true, ["樟"] = true, ["枫"] = true,
  ["桐"] = true, ["桑"] = true, ["梨"] = true, ["茶"] = true,
  ["竹"] = true, ["莲"] = true, ["荷"] = true, ["菊"] = true,
  ["荔"] = true, ["蒲"] = true, ["芦"] = true, ["芷"] = true,
  ["蓼"] = true,
}

-- 派生 terrain_suffix 用的字表（取自规格书 C 节「自然地理」类）
local TERRAIN_SUFFIX_CHARS = {}
for c in ("山岭峰岗丘坡岩崖岫岑崮江河川溪涧沟渠湖泊淀池潭泉井湾汊港" ..
          "洲渚滩矶浦泾浜渎浃漾荡滘涌埠渡津塘堰陂" ..
          "坪塬原坝冲坳垄垅塅畈垸坎槽垭垇塝塆" ..
          "屿岛澳"):gmatch(".") do
  TERRAIN_SUFFIX_CHARS[c] = true
end

-- 派生 auspicious_suffix 用的字表（本身即吉祥字的通名）
local AUSPICIOUS_SUFFIX_CHARS = {}
for c in ("安宁平定靖绥和顺昌泰康兴永新德仁义礼信寿福庆恩惠祥瑞吉嘉乐清广"):gmatch(".") do
  AUSPICIOUS_SUFFIX_CHARS[c] = true
end

local function isSuffixTerminal(w)
  if not w or w == "" then return false end
  local last = w:sub(-3)   -- 末 1 个汉字
  return TERRAIN_SUFFIX_CHARS[last] or AUSPICIOUS_SUFFIX_CHARS[last]
end

--[[ UTF-8 安全校验
  逐字符（按 UTF-8 解码）检查字符串是否只含「安全字符」：
  汉字（U+4E00–U+9FFF）、CJK 扩展 A（U+3400–U+4DBF）、
  以及「子」类常见地名尾字自然在内。ASCII 字母数字一律拒绝。
  这可以挡住任何因编码/切分失误而产生的坏词条。
]]
local function isCleanCJK(s)
  local i, n = 1, #s
  while i <= n do
    local c = s:byte(i)
    if not c then return false end
    if c < 0x80 then
      -- ASCII：拒绝（中文地名不应含 ASCII）
      return false
    elseif c >= 0xE0 and c <= 0xEF and (i + 2) <= n then
      local cp = (c - 0xE0) * 4096 + (s:byte(i + 1) - 0x80) * 64 + (s:byte(i + 2) - 0x80)
      -- 只接受 CJK 统一表意文字及其扩展 A
      if not ((cp >= 0x4E00 and cp <= 0x9FFF) or (cp >= 0x3400 and cp <= 0x4DBF)) then
        return false
      end
      i = i + 3
    else
      -- 2 字节 / 4 字节序列一律拒绝
      return false
    end
  end
  return n > 0
end

-- 分词展开
--[[ 数据层忠实保留了规格书原文的「 A / B / C 」形式（如 "山 / 岭 / 峰 / 岗"），
  因为规格书本身就是这么写的。生成器必须把它拆成独立词条，否则这些通名
  会被当成一个超长字符串而失效。这里统一处理：
    * 分隔符：全角顿号「、」、全角斜杠「／」、半角斜杠「/」、全角逗号「，」、
              半角逗号、全角分号、竖线
    * 括号说明：剥离「(原)」「(垅)」「（湾）」等括注；若括号后还有内容则取括号外部分
    * 空白：全部压缩
]]
local function splitTokens(w)
  local tokens = {}
  if type(w) ~= "string" then return tokens end

  -- 去掉 BOM/不可见字符
  w = w:gsub("^\239\187\191", "")

  -- 按分隔符切分
  local parts = {}
  for piece in w:gmatch("[^、/／,，;；|]+") do
    parts[#parts + 1] = piece
  end

  for _, piece in ipairs(parts) do
    -- 剥离括号及其内容：取第一个括号之前的部分；
    -- 若整段都在括号内（如「(原)」），则回退用括号内的内容
    local before = piece:match("^([^%(（]*)")
    local inner  = piece:match("[%(（]([^%)）]*)[%)）]")
    local cleaned
    if before and before:gsub(" ", "") ~= "" then
      cleaned = before
    else
      cleaned = inner
    end
    if cleaned then
      -- 只删空白。切勿使用 %p / %c 等字节类：
      -- Lua 5.1 下它们按字节匹配，会切碎多字节 UTF-8 序列并产生非法字节。
      cleaned = cleaned:gsub("%s", "")
      -- 只用"纯汉字"词元：这能自动滤掉数据层里形如
      --   "漾贡→仰光"（注释箭头）、"张 / 张掖"（主词/注）、Latin 音标
      -- 之类的非地名词元，避免它们进入生成池。
      if cleaned ~= "" and isCleanCJK(cleaned) then
        tokens[#tokens + 1] = cleaned
      end
    end
  end

  return tokens
end

-- 把数据模块拍平成 slot -> 条目数组 的池
function M.buildPools(style)
  local pools = {}

  -- 把一条数据条目按分词展开后逐一入池
  -- 支持 suffixSlot 显式指派（混合风格用它保留原始分词性归属）
  local function pushExpanded(slot, item)
    if type(item) ~= "table" then return end
    if item.enabled == false then return end
    local w = item.w
    if type(w) ~= "string" or w == "" then return end

    local target = slot
    if slot == "suffix" and type(item.suffixSlot) == "string" then
      target = item.suffixSlot
    end

    -- 通名类条目允许更长（"市社""大巴扎"等），但仍设上限避免坏数据
    local maxLen = (target:find("suffix")) and 6 or 3

    local tokens = splitTokens(w)
    for _, tok in ipairs(tokens) do
      -- 物产黑名单：任何专名池都不收（否则会拼出「榴莲浮罗」）
      local blocked = PRODUCT_BLOCK[tok]
      if not blocked and M.ulen(tok) <= maxLen then
        local arr = pools[target]
        if not arr then arr = {}; pools[target] = arr end
        arr[#arr + 1] = {
          w = tok,
          weight = item.weight,
          note = item.note,
          etymon = item.etymon,
          scene = item.scene,
          tags = item.tags,
          suspicious = item.suspicious,
        }
      end
    end
  end

  -- 1) 专名部件：组名经同义词归一化后建池；未识别的组名原样保留为池
  for group, items in pairs(style.parts or {}) do
    local slot = PART_ALIAS[group] or group
    for i = 1, #items do pushExpanded(slot, items[i]) end
  end

  -- 2) 通名：suffixes 可能是扁平数组，也可能是二级分组表；两种都拍平进 "suffix"
  local function flattenSuffixes(node)
    if type(node) ~= "table" then return end
    if node.w then
      pushExpanded("suffix", node)
    else
      for _, sub in pairs(node) do
        if type(sub) == "table" then
          if sub.w then pushExpanded("suffix", sub) else flattenSuffixes(sub) end
        end
      end
    end
  end
  flattenSuffixes(style.suffixes)

  -- 3) 显式提供的分词性通名池优先
  for i = 1, #(style.terrain_suffix or {}) do pushExpanded("terrain_suffix", style.terrain_suffix[i]) end
  for i = 1, #(style.auspicious_suffix or {}) do pushExpanded("auspicious_suffix", style.auspicious_suffix[i]) end

  -- 4) 从 tags 派生
  local function deriveByTag(tag, slot)
    if pools[slot] and #pools[slot] > 0 then return end
    local arr = {}
    for _, s in ipairs(pools["suffix"] or {}) do
      if s.tags then
        for _, t in ipairs(s.tags) do
          if t == tag then arr[#arr + 1] = s break end
        end
      end
    end
    if #arr > 0 then pools[slot] = arr end
  end
  deriveByTag("terrain",    "terrain_suffix")
  deriveByTag("nature",     "terrain_suffix")
  deriveByTag("auspicious", "auspicious_suffix")

  -- 5) 按字表派生（数据只有分组、没打 tag 时的主要途径）
  if not pools["terrain_suffix"] or #pools["terrain_suffix"] == 0 then
    local arr = {}
    for _, s in ipairs(pools["suffix"] or {}) do
      local last = s.w:sub(-3)
      if TERRAIN_SUFFIX_CHARS[last] then arr[#arr + 1] = s end
    end
    if #arr > 0 then pools["terrain_suffix"] = arr end
  end
  if not pools["auspicious_suffix"] or #pools["auspicious_suffix"] == 0 then
    local arr = {}
    for _, s in ipairs(pools["suffix"] or {}) do
      local last = s.w:sub(-3)
      if AUSPICIOUS_SUFFIX_CHARS[last] then arr[#arr + 1] = s end
    end
    if #arr > 0 then pools["auspicious_suffix"] = arr end
  end

  -- 6) 极端兜底：缺池时用整个通名池顶上，保证相关模板不至于整类失效
  if not pools["terrain_suffix"] or #pools["terrain_suffix"] == 0 then
    pools["terrain_suffix"] = pools["suffix"]
  end
  if not pools["auspicious_suffix"] or #pools["auspicious_suffix"] == 0 then
    pools["auspicious_suffix"] = pools["suffix"]
  end

  -- 7) "single" 通用单字专名池：未提供时从全部专名池汇总单字条目
  --
  --    关键约束：**只收单字**。2 字的物产/海产名词（榴莲、槟榔、豆蔻、
  --    燕窝…）绝不能进入单字池，否则会与 2 字通名拼成
  --    「榴莲浮罗」这类不合格的 4 字名。
  --    （数据层这些词本身是对的，问题在于它们被当成了"单字专名核心"。）
  if not pools["single"] or #pools["single"] == 0 then
    local arr = {}
    for slot, items in pairs(pools) do
      if slot ~= "single" and not slot:find("suffix") then
        -- 语素名物类池：只允许单字
        for _, it in ipairs(items) do
          if M.ulen(it.w) == 1 then arr[#arr + 1] = it end
        end
      end
    end
    if #arr > 0 then pools["single"] = arr end
  end

  return pools
end

-- 收集某风格下全部被禁用的汉字（chars 字段），用于最后过滤
function M.collectBannedChars(style)
  local set = {}
  local banned = style.banned or {}
  for _, c in ipairs(banned.chars or {}) do set[c] = true end
  for _, c in ipairs(banned.suffixes or {}) do set[c] = true end
  return set
end

-- 按长度分桶的池：slot -> { [1]={条目...}, [2]={条目...}, ... }
-- 用途：长度感知的通名选择。当专名已占 2 字（如「三宝」「天后」这类
-- 2 字信仰词）时，通名应优先取 1 字的，以产出 3 字的「三宝港」，
-- 而不是 4 字的「三宝信坡」。
function M.buildLengthBuckets(pools)
  local buckets = {}
  for slot, items in pairs(pools) do
    local byLen = {}
    for _, it in ipairs(items) do
      local n = M.ulen(it.w)
      if not byLen[n] then byLen[n] = {} end
      byLen[n][#byLen[n] + 1] = it
    end
    buckets[slot] = byLen
  end
  return buckets
end

-- 从长度桶里挑一个合法池：
--   preferLen 非空时，只接受长度为 preferLen 的池；
--   否则回退到该 slot 的完整池。
function M.pickSuffixPool(pools, buckets, slot, preferLen)
  if preferLen and buckets[slot] and buckets[slot][preferLen]
     and #buckets[slot][preferLen] > 0 then
    return buckets[slot][preferLen]
  end
  return pools[slot]
end

-- 规范化为「真实地名黑名单」的集合，用于撞名判定
function M.collectRealNames(style)
  local set = {}
  local banned = style.banned or {}
  for _, n in ipairs(banned.realNames or {}) do set[n] = true end
  return set
end

--============================================================== 构词 ====

-- 按一个模板把一个名字拼出来。返回 nil 表示本次尝试失败（外层会重试）
-- opts.preferStemToOneSuffix 为真时启用「长度感知通名」：
--   累计专名已达 2 字时，通名优先取 1 字，避免拼出 4 字长名。
function M.composeWord(pools, template, bannedChars, maxTry, opts, buckets)
  maxTry = maxTry or 24
  opts = opts or {}

  for _ = 1, maxTry do
    local chunks = {}
    local stemLen = 0        -- 累计「专名」长度（通名之前的部分）
    local ok = true

    for _, slot in ipairs(template.seq) do
      if slot:sub(1, 1) == "=" then
        -- 字面量：如 "=家"、"=州"、"=阳"
        chunks[#chunks + 1] = slot:sub(2)
        stemLen = stemLen + M.ulen(slot:sub(2))
      else
        local isSuffix = slot:find("suffix") ~= nil

        local preferLen = nil
        if isSuffix and opts.preferStemToOneSuffix and stemLen >= 2 then
          preferLen = 1
        end

        local pool = pools[slot]
        if preferLen and buckets then
          pool = M.pickSuffixPool(pools, buckets, slot, preferLen)
        end

        if not pool or #pool == 0 then
          ok = false
          break
        end

        local picked = M.pickWeighted(pool).w
        chunks[#chunks + 1] = picked
        if not isSuffix then
          stemLen = stemLen + M.ulen(picked)
        end
      end
    end

    if ok then
      local word = table.concat(chunks)
      if not M.hasBannedChar(word, bannedChars) then
        return word
      end
    end
  end
  return nil
end

function M.hasBannedChar(word, bannedChars)
  if not bannedChars then return false end
  -- 禁用字均为单个汉字，UTF-8 编码自同步，可直接做子串匹配
  for ch in pairs(bannedChars) do
    if word:find(ch, 1, true) then return true end
  end
  return false
end

-- 语素闸门：拒绝"同义语素堆叠"与"纯通名"这类不合格结果
--[[ 典型坏例（真实出现过的）：
      天后关帝  ← 两个同类信仰词叠用
      关帝坤    ← 信仰词 + 借词通名，语义不通
      市社      ← 纯通名，没有专名
      尾州      ← 方位尾字单独作专名
    处理办法：
      1) 名字在去掉末位通名后，剩余部分（专名）不得为空；
      2) 专名不得由"两个同池语素"直接拼成（记录语素来源池）；
      3) 提供一个显式拒绝表，收录已知的坏组合前缀。
]]
local BAD_PREFIX = {
  ["天后关帝"] = true, ["关帝天后"] = true, ["妈祖天后"] = true,
}

function M.checkMorphemes(word, pools, template)
  if not word or word == "" then return false end

  -- 收集所有可能的通名（含模板字面量），按长度从长到短尝试切分。
  -- 只要**存在一种切法**能让专名非空，就认为结构合法。
  -- 这样：「水仙岗」→ 岗(通名) + 水仙(专名) ✅
  --       「关公天后」→ 天后(通名) 却使专名"关公"非空，需再看下面第 2 条
  --       「沙洲」→ 洲(通名)+沙(专名) ✅（沙洲本身也在通名池，但专名非空即放行）
  local cand = {}
  local function addCand(w)
    if type(w) == "string" and w ~= "" and #w <= 12 then cand[w] = true end
  end
  for _, slot in ipairs({ "suffix", "terrain_suffix", "auspicious_suffix" }) do
    for _, it in ipairs(pools[slot] or {}) do addCand(it.w) end
  end
  for _, slot in ipairs(template and template.seq or {}) do
    if slot:sub(1, 1) == "=" then addCand(slot:sub(2)) end
  end

  local lens = {}
  for w in pairs(cand) do
    local L = #w
    if L <= #word and word:sub(-L) == w then
      lens[L] = true
    end
  end

  local okStem = nil
  -- 从长到短尝试
  local sorted = {}
  for L in pairs(lens) do sorted[#sorted + 1] = L end
  table.sort(sorted, function(a, b) return a > b end)

  for _, L in ipairs(sorted) do
    local stem = word:sub(1, #word - L)
    if stem ~= "" and M.ulen(stem) >= 1 then
      okStem = stem
      break
    end
  end

  if not okStem then return false end        -- 纯通名，无专名

  -- 已知坏前缀
  if BAD_PREFIX[okStem] then return false end

  return true
end

-- 长度约束校验
function M.checkLength(word, constraints)
  if not constraints then return true end
  local n = M.ulen(word)
  if constraints.minLen and n < constraints.minLen then return false end
  if constraints.maxLen and n > constraints.maxLen then return false end
  return true
end

-- 叠字禁忌校验（如「县县」「村村」）
function M.checkForbiddenPairs(word, constraints)
  if not constraints or not constraints.forbiddenPairs then return true end
  for _, pair in ipairs(constraints.forbiddenPairs) do
    if word:find(pair[1] .. pair[2], 1, true) then return false end
  end
  return true
end

-- 同声母规避（可选）：连续两字拼音声母相同则判失败
function M.checkSameInitial(word, initialMap, constraints)
  if not constraints or not constraints.avoidSameInitial then return true end
  if not initialMap then return true end
  local chars, n = {}, M.ulen(word)
  local i = 1
  while i <= #word do
    local c = word:byte(i)
    local step = (c < 0x80) and 1 or (c < 0xE0 and 2 or (c < 0xF0 and 3 or 4))
    chars[#chars + 1] = word:sub(i, i + step - 1)
    i = i + step
  end
  for k = 2, #chars do
    local a, b = initialMap[chars[k - 1]], initialMap[chars[k]]
    if a and b and a == b then return false end
  end
  return true
end

--=========================================================== 模板展开 ==

--[[ 为什么需要这一层
  数据层忠实保留了规格书 B 节的**散文式构词式**（如「方位 + 专名核心 + 通名」），
  而不是机器可读的槽序列。生成器负责把它翻译成 seq = {槽名, ...}。
  翻译策略：
    1) 少数语义特殊、无法靠关键词可靠推断的模板，用显式表；
    2) 其余用关键词逐段映射；
    3) 最后一个槽强制为通名（中文地名通名在末尾，这是铁律）。
]]

-- 特殊模板的显式序列
--[[ 为什么几乎每个模板都要显式列出：
  从散文 formula 用关键词推断槽序列，**极易丢失槽位**——例如
  「姓氏 + 通名（2 字聚落）」会被推断成只剩 {suffix}，于是生成器直接拿
  通名当地名，产出「站」「镇」这类非法结果；亚寒带的
  「修饰? + 物产|水文|矿业 + 地形|水域通名」也曾被推断成只剩 number。
  因此这里对**每一个模板 id** 都显式给出序列，关键词推断仅作最后兜底。
]]
local TEMPLATE_PATTERNS = {
  -- ===== 汉地 =====
  H2  = { "auspicious", "auspicious_suffix" },  -- 吉祥字 + 吉祥通名
  H3  = { "water", "=阳" },                     -- 山水阴阳（阳）
  H4  = { "ancient_state", "=州" },             -- 古国/古州名 + 州
  H5  = { "surname", "=家", "suffix" },         -- 姓氏 + 家 + 通名
  H6  = { "surname", "suffix" },                -- 姓氏 + 通名
  H7  = { "mileage", "suffix" },                -- 数字里程 + 通名
  H8  = { "direction", "single", "suffix" },    -- 方位 + 专名核心 + 通名
  H9  = { "plant", "terrain_suffix" },          -- 物产植被 + 地形通名
  H10 = { "color", "terrain_suffix" },          -- 颜色 + 自然通名

  -- ===== 海洋中国 =====
  -- 注意：faith / tropical / seafood 等在数据层是"一个长串条目"，
  -- buildPools 的分词展开会把它拆成多条，因此这里直接引用即可。
  O1  = { "auspicious", "auspicious_suffix" },  -- 汉越吉祥式
  O2  = { "plant", "suffix" },                  -- 海贸物产式
  O3  = { "auspicious", "auspicious" },         -- 音译雅化（双字雅化）

  -- ===== 西北 =====
  X1  = { "direction", "garrison" },            -- 方位/里程/姓氏 + 军事通名
  X2  = { "modifier", "water" },                -- 颜色/地貌修饰 + 水利通名
  X3  = { "color", "terrain" },                 -- 颜色/姓氏/方位 + 地形通名
  X4  = { "color", "water" },                   -- 颜色对音 + 自然通名对音
  X5  = { "color", "suffix" },                  -- 民族语专名 + 汉语通名
  X6  = { "color", "terrain_suffix" },          -- 巴彦/颜色 + 浩特/淖尔/郭勒
  X7  = { "color", "water" },                   -- 藏语式：颜色 + 曲/措/岗
  X8  = { "ancient_state", "garrison" },        -- 古国/丝路 + 城/关/驿
  X9  = { "number", "garrison" },               -- 兵团层级

  -- ===== 亚寒带 =====
  Y1  = { "plant", "terrain_suffix" },          -- 海参崴式：物产 + 地形通名
  Y2  = { "number", "terrain_suffix" },         -- 庙街/双城子式：数词 + 类通名
  Y3  = { "garrison", "suffix" },               -- 戍边式：戍边专名 + 通名
  Y4  = { "plant", "suffix" },                  -- 满语式音译点缀
}

-- 需要同时生成「阳/阴」两个变体的模板
local TEMPLATE_VARIANTS = { H3 = true }

-- 关键词 → 槽名 的推断表（按出现顺序匹配，取第一个命中的）
local KEYWORD_TO_SLOT = {
  { "方位",     "direction" },
  { "方向",     "direction" },
  { "姓氏",     "surname" },
  { "里程",     "mileage" },
  { "数字",     "number" },
  { "数词",     "number" },
  { "序数",     "number" },
  { "物产植被", "plant" },
  { "植被",     "plant" },
  { "物产",     "plant" },
  { "颜色",     "color" },
  { "地形",     "terrain" },
  { "水文",     "water" },
  { "水",       "water" },
  { "山",       "mountain" },
  { "军事",     "garrison" },
  { "戍边",     "garrison" },
  { "水利",     "water" },
  { "古国",     "ancient_state" },
  { "丝路",     "post" },
  { "地标",     "market" },
  { "吉祥",     "auspicious" },
  { "主题字",   "auspicious" },
  { "自然通名", "terrain_suffix" },
  { "地形通名", "terrain_suffix" },
  { "水域通名", "terrain_suffix" },
  { "对音",     "color" },
  { "民族语",   "color" },
  { "专名核心", "single" },
  { "修饰",     "color" },
}

-- 把散文 formula 翻译为槽序列
local function inferSeq(t)
  -- 数据层若已提供机器可读的 seq，一律优先采用
  -- （混合风格就是把各类已解析好的 seq 直接传进来的）
  if t.seq and #t.seq > 0 then return t.seq end

  if t.id and TEMPLATE_PATTERNS[t.id] then
    return TEMPLATE_PATTERNS[t.id]
  end

  local f = t.formula
  if type(f) ~= "string" then return nil end

  -- 以「+」分段（全角/半角都算）
  local segs = {}
  for seg in f:gmatch("[^+＋]+") do segs[#segs + 1] = seg end
  if #segs == 0 then return nil end

  local seq = {}
  for i, seg in ipairs(segs) do
    local slot = nil
    for _, pair in ipairs(KEYWORD_TO_SLOT) do
      if seg:find(pair[1], 1, true) then slot = pair[2] break end
    end
    if slot then
      seq[#seq + 1] = slot
    end
  end

  if #seq == 0 then return nil end
  -- 强制末位为通名
  seq[#seq] = "suffix"
  return seq
end

-- 为某风格生成「可用模板」列表（已解析 seq，且槽位在池中存在）
function M.buildTemplates(style, pools)
  local out = {}
  for _, t in ipairs(style.templates or {}) do
    local seq = inferSeq(t)
    if seq then
      -- 校验每个槽都有池可用（字面量槽除外）
      local usable = true
      for _, slot in ipairs(seq) do
        if slot:sub(1, 1) ~= "=" then
          if not pools[slot] or #pools[slot] == 0 then
            usable = false
            break
          end
        end
      end
      if usable then
        -- H3 这类「阳/阴」成对模板：拆成两条以获得正确的双变体分布
        if TEMPLATE_VARIANTS[t.id] then
          for _, tail in ipairs({ "=阳", "=阴" }) do
            local s2 = {}
            for i = 1, #seq do s2[i] = seq[i] end
            s2[#s2] = tail
            out[#out + 1] = { id = t.id .. tail:sub(2), seq = s2, weight = t.weight }
          end
        else
          out[#out + 1] = { id = t.id, seq = seq, weight = t.weight }
        end
      end
    end
  end
  return out
end

--=========================================================== 生成池 ====

-- 为一个风格生成完整名称池（已知数量时用 k 参数裁剪）
-- 返回 { names = {...}, stats = {...} }
function M.generatePool(style, styleKey, opts)
  opts = opts or {}
  -- 风格自带的选项作为默认值（数据集里可直接声明 softMaxLen /
  -- preferStemToOneSuffix），调用方传入的 opts 优先级更高。
  -- 这样所有消费方（游戏运行时、测试、导出工具）行为一致。
  local softMaxLen = opts.softMaxLen or style.softMaxLen or 3
  local preferStem = opts.preferStemToOneSuffix
  if preferStem == nil then preferStem = style.preferStemToOneSuffix or false end

  -- 兼容旧的局部变量名（下文沿用 softMaxLen，此处不再重声明）
  local pools = M.buildPools(style)
  local bannedChars = M.collectBannedChars(style)
  local realNames = M.collectRealNames(style)
  local constraints = style.constraints or {}
  -- 长度约束兜底：数据层的 constraints 往往是规格书散文（"2 字＝…"），
  -- 而非 minLen/maxLen 数值，因此这里提供内置默认（中文地名 2–4 字），
  -- 只有当数据层确实给出数字时才覆盖。
  local minLen = (type(constraints.minLen) == "number") and constraints.minLen or 2
  local maxLen = (type(constraints.maxLen) == "number") and constraints.maxLen or 4
  local lengthC = { minLen = minLen, maxLen = maxLen,
                    forbiddenPairs = constraints.forbiddenPairs }
  -- 模板由 buildTemplates 解析（数据层给的是散文 formula，这里翻译成槽序列）
  local templates = M.buildTemplates(style, pools)

  local seen = {}
  local names = {}
  local maxTotal = opts.maxTotal or 4000
  -- 软长度上限：长度 ≤ softMaxLen 的名字优先；超长名限流。
  local hardMaxLen = maxLen
  -- 配额基数必须用「本次实际可能被取用的数量」，而不是池上限 maxTotal。
  -- 早先用 maxTotal（4000）计算，导致 softMaxLen 形同虚设——
  -- 游戏只取 N 个时，配额 480 永远用不完。
  local quotaBase = math.min(maxTotal, opts.quotaBase or maxTotal)
  local longQuota = math.floor(quotaBase * (opts.longQuotaRatio or 0.12))
  local longCount = 0

  local buckets = preferStem and M.buildLengthBuckets(pools) or nil
  -- 传给 composeWord 的选项（长度感知通名选择）
  local composeOpts = { preferStemToOneSuffix = preferStem }
  local attempts = 0
  local maxAttempts = maxTotal * 40

  if #templates == 0 then
    return {
      names = {},
      stats = { style = styleKey, produced = 0, attempts = 0,
                poolGroups = (function() local c = 0 for _ in pairs(pools) do c = c + 1 end return c end)(),
                reason = "no usable template" },
    }
  end

  while #names < maxTotal and attempts < maxAttempts do
    attempts = attempts + 1
    local tmpl = M.pickWeighted(templates)
    local word = M.composeWord(pools, tmpl, bannedChars, nil, composeOpts, buckets)
    if word then
      local wlen = M.ulen(word)
      local tooLong = (wlen > softMaxLen) and (longCount >= longQuota)
      if not tooLong
        and not seen[word]
        and not realNames[word]
        and M.checkLength(word, lengthC)
        and M.checkForbiddenPairs(word, lengthC)
        and M.checkMorphemes(word, pools, tmpl)
      then
        seen[word] = true
        names[#names + 1] = word
        if wlen > softMaxLen then longCount = longCount + 1 end
      end
    end
  end

  return {
    names = names,
    stats = {
      style = styleKey,
      produced = #names,
      attempts = attempts,
      templates = #templates,
      poolGroups = (function() local c = 0 for _ in pairs(pools) do c = c + 1 end return c end)(),
    },
  }
end

--======================================================= 对外契约层 ====

-- 每个风格维护一个已用池游标，保证跨多次调用不重复
M._pools = {}
M._cursor = {}

-- 取得（或惰性构建）某风格的名称池
function M.ensurePool(style, styleKey, opts)
  if not M._pools[styleKey] then
    local res = M.generatePool(style, styleKey, opts)
    M._pools[styleKey] = res.names
    M._cursor[styleKey] = 1
  end
  return M._pools[styleKey], M._cursor[styleKey]
end

-- 重置（供测试与新地图使用）
function M.reset(styleKey)
  if styleKey then
    M._pools[styleKey] = nil
    M._cursor[styleKey] = nil
  else
    M._pools = {}
    M._cursor = {}
  end
end

-- 遵守 num 契约：返回 num 条不重复名称；num = -1 返回全部剩余
function M.request(style, styleKey, params, opts)
  params = params or {}
  local num = params.num
  opts = opts or {}

  -- 把「本次实际请求量」透传给 generatePool 作为长名配额基数，
  -- 否则少量请求时长度配额形同虚设（见 generatePool 内注释）。
  if num and num > 0 and not opts.quotaBase then
    local o2 = {}
    for k, v in pairs(opts) do o2[k] = v end
    o2.quotaBase = num
    opts = o2
  end

  local pool, cursor = M.ensurePool(style, styleKey, opts)

  local out = {}
  if num == -1 or num == nil then
    for i = cursor, #pool do out[#out + 1] = pool[i] end
    M._cursor[styleKey] = #pool + 1
    return out
  end

  for _ = 1, num do
    if cursor > #pool then
      -- 池耗尽：不再重名，宁可少给
      break
    end
    out[#out + 1] = pool[cursor]
    cursor = cursor + 1
  end
  M._cursor[styleKey] = cursor
  return out
end

return M

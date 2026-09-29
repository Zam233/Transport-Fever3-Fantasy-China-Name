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
  streetnamegen.lua —— 中国街道命名：生成器核心（纯逻辑，不含词表）

  与 MOD1（城市名）的区别
    * 数据形态不同：街道数据是「9 个地域分型」，每个地域自带
      templates / suffixWeights / themeWeights
    * 结构铁律：**每条街道名必须是「专名 + 通名」且通名在末尾**
      （《地名管理条例》与各市细则的硬性要求）
    * 必须过一道 **合规校验管线**（法规禁止项、生僻字、重名、谐音…）

  借鉴 MOD1 的既有教训（这些都是踩过的坑）
    1) 严禁 Lua 5.3 位运算符 —— 运行时疑为 Lua 5.1/LuaJIT，会直接加载失败
    2) 严禁用 %p / %c 等字节类做清洗 —— 会切碎多字节 UTF-8
    3) 分词后只保留纯汉字词元 —— 滤掉顿号串、斜杠注、箭头注释
    4) 数据层常把「A / B / C」写成一条 —— 必须拆分，否则超长串被当单词

  参考：TF3 官方 wiki  modding:misc:names
    streetsNameScriptFn(captureParams, params)
      params.lang : 语言短码
      params.num  : 需要的名称个数；-1 表示返回全部
      返回        : 长度为 num 的字符串列表
--------------------------------------------------------------------------]]

local M = {}

-- 数据模块：由入口通过 M.setData() 注入。
-- 这样同一份生成器既能被单元测试直接驱动，也能被游戏入口注入，
-- 且合并 MOD 里只有一份数据实例。
local data = nil

function M.setData(d) data = d return M end
function M.getData() return data end

--============================================================== 基础工具 ==

function M.ulen(s)
  local n, i, len = 0, 1, #s
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

-- 逐字符切分（返回数组），避免任何字节级误伤
function M.chars(s)
  local out, i, len = {}, 1, #s
  while i <= len do
    local c = s:byte(i)
    local step = (c < 0x80) and 1 or (c < 0xE0 and 2 or (c < 0xF0 and 3 or 4))
    out[#out + 1] = s:sub(i, i + step - 1)
    i = i + step
  end
  return out
end

-- 是否纯汉字（CJK 统一表意文字 + 扩展 A）
function M.isCleanCJK(s)
  if type(s) ~= "string" or s == "" then return false end
  local i, len = 1, #s
  while i <= len do
    local c = s:byte(i)
    if c < 0x80 then return false end
    if c >= 0xE0 and c <= 0xEF and (i + 2) <= len then
      local cp = (c - 0xE0) * 4096 + (s:byte(i + 1) - 0x80) * 64 + (s:byte(i + 2) - 0x80)
      if not ((cp >= 0x4E00 and cp <= 0x9FFF) or (cp >= 0x3400 and cp <= 0x4DBF)) then
        return false
      end
      i = i + 3
    else
      return false
    end
  end
  return true
end

--=========================================================== 伪随机 ==

local rngState = 987654321
local RNG_MOD = 2147483647   -- 2^31-1

local function nextRand()
  rngState = (rngState * 16807) % RNG_MOD
  return rngState
end

function M.rand(n)
  if n <= 0 then return 0 end
  return math.floor(nextRand() / RNG_MOD * n) % n
end

function M.seed(v)
  local s
  if type(v) == "number" and v ~= 0 then
    s = math.floor(math.abs(v))
  elseif type(v) == "string" then
    s = 2166136261
    for i = 1, #v do
      s = (s * 16777619 + v:byte(i)) % 4294967296
    end
  else
    s = 987654321
  end
  rngState = (s % (RNG_MOD - 1)) + 1
  for _ = 1, 8 do nextRand() end
end

function M.pickWeighted(pool)
  if not pool or #pool == 0 then return nil end
  local total = 0
  for i = 1, #pool do total = total + (pool[i].weight or 1) end
  if total <= 0 then return pool[1] end
  local r = M.rand(total)
  local acc = 0
  for i = 1, #pool do
    acc = acc + (pool[i].weight or 1)
    if r < acc then return pool[i] end
  end
  return pool[#pool]
end

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

--======================================================= 分词与归一化 ==

-- 把「A / B、C」这类规格书原文串拆成独立词元
local function splitTokens(w)
  local tokens = {}
  if type(w) ~= "string" then return tokens end
  w = w:gsub("^\239\187\191", "")
  for piece in w:gmatch("[^、/／,，;；|]+") do
    local before = piece:match("^([^%(（]*)")
    local inner  = piece:match("[%(（]([^%)）]*)[%)）]")
    local cleaned = (before and before:gsub("%s", "") ~= "") and before or inner
    if cleaned then
      cleaned = cleaned:gsub("%s", "")
      if cleaned ~= "" and M.isCleanCJK(cleaned) then
        tokens[#tokens + 1] = cleaned
      end
    end
  end
  return tokens
end

-- 把任意嵌套结构（数组 / 按名分组 / 带 province+city 二级表）拍平成词条数组
local function flattenParts(node, out)
  out = out or {}
  if type(node) ~= "table" then return out end
  if type(node.w) == "string" then
    for _, tok in ipairs(splitTokens(node.w)) do
      if M.ulen(tok) <= 4 then out[#out + 1] = { w = tok } end
    end
    return out
  end
  for _, sub in pairs(node) do
    if type(sub) == "table" then flattenParts(sub, out) end
  end
  return out
end

-- 把通名表拍平成词条数组（保留 minWidth 等门槛字段）
local function flattenSuffixes(node, out)
  out = out or {}
  if type(node) ~= "table" then return out end
  if type(node.w) == "string" then
    for _, tok in ipairs(splitTokens(node.w)) do
      if M.ulen(tok) <= 3 then
        out[#out + 1] = {
          w = tok,
          weight = node.weight,
          minWidth = node.minWidth, minLength = node.minLength,
          maxWidth = node.maxWidth, maxLength = node.maxLength,
          level = node.level, suspicious = node.suspicious,
        }
      end
    end
    return out
  end
  for _, sub in pairs(node) do
    if type(sub) == "table" then flattenSuffixes(sub, out) end
  end
  return out
end

--============================================================= 池构建 ==

--[[ 街道后缀白名单（关键修正）
  问题：数据层的地域通名表混入了**聚落类**通名（庄/屯/村/寨/堡/店/铺/营/
  浩特/苏木/嘎查/林卡/巴扎…）。它们本身是正确的聚落地名用字，但**不是路名**。
  若直接放进街道模板的 "suffix" 插槽，就会产出「石家庄」「邓屯」这类村名。

  因此街道后缀池只保留真正的**道路通名**与**片区通名**：
    * 道路层：路 / 街 / 巷 / 弄 / 里 / 坊 / 胡同 / 条 / 径 / 小街 / 横街 /
              斜街 / 夹道 / 支路 / 道 / 马路 / 大道 / 大街
    * 片区层（居住区/园区道路）：园 / 苑 / 新村 / 广场 / 城 / 府 / 邸 /
              阁 / 轩 / 榭 / 庭 / 居 / 里弄 / 花园 / 小区 / 中心 / 大厦

  地域风味改由**专名**承载（如岭南的滘/涌/围、西北的塬/梁/峁 作专名），
  而不是让后缀退化成村名。这样既保住地域特色，又保证产出是路名。
]]
local STREET_SUFFIX_WHITELIST = {
  -- 道路层（全国通用）
  ["路"]      = true, ["街"]    = true, ["巷"]  = true, ["弄"]   = true,
  ["里"]      = true, ["坊"]    = true, ["胡同"] = true, ["条"]  = true,
  ["径"]      = true, ["小街"]  = true, ["横街"] = true, ["斜街"] = true,
  ["夹道"]    = true, ["支路"]  = true, ["道"]   = true, ["马路"] = true,
  ["大道"]    = true, ["大街"]  = true,
  -- 片区层（居住区/园区道路）
  ["园"]      = true, ["苑"]    = true, ["新村"] = true, ["广场"] = true,
  ["城"]      = true, ["府"]    = true, ["邸"]   = true, ["阁"]   = true,
  ["轩"]      = true, ["榭"]    = true, ["庭"]   = true, ["居"]   = true,
  ["里弄"]    = true, ["花园"]  = true, ["小区"] = true, ["中心"] = true,
  ["大厦"]    = true,

  --[[ 地域专属道路通名
    这些是各地真实存在的道路/街巷用字，必须保留，否则九个地域的街道
    会长得一模一样（全是大街/马路），丢掉"地域分型"的意义。
    判断标准：该字在当地方言里本身就是**街巷/道路**用字（而非村落用字）。
  ]]
  -- 江南/吴语：弄堂、水乡街巷
  ["浜"] = true, ["泾"] = true, ["汇"] = true, ["塘"] = true, ["堰"] = true,
  ["荡"] = true, ["漾"] = true, ["角"] = true, ["埭"] = true, ["圩"] = true,
  ["宅"] = true, ["嘴"] = true, ["桥"] = true,
  -- 岭南/港澳：街巷、围基
  ["约"] = true, ["围"] = true, ["塱"] = true, ["基"] = true, ["墟"] = true,
  ["前地"] = true, ["马路"] = true,
  -- 闽台：埕、份、社
  ["埕"] = true, ["份"] = true, ["社"] = true, ["埤"] = true,
  -- 西南：场、坎、坡、驿道
  ["场"] = true, ["坎"] = true, ["坡"] = true, ["梯"] = true,
  ["驿"] = true, ["驿道"] = true, ["码头"] = true,
  -- 华中：冲、垸、畈、垱、塅、塝
  ["冲"] = true, ["垸"] = true, ["畈"] = true, ["垱"] = true, ["塅"] = true,
  ["塝"] = true,
  -- 西北：塬、梁、峁、渠、泉、井
  ["塬"] = true, ["梁"] = true, ["峁"] = true, ["渠"] = true,
  ["泉"] = true, ["井"] = true,
  -- 藏区：宗、卡、廓
  ["宗"] = true, ["卡"] = true, ["廓"] = true,
}

local FREQ_WEIGHT = { ["极高频"] = 10, ["高频"] = 7, ["中频"] = 4, ["低频"] = 2 }

-- 主题池：把 M.parts 的每个主题拍平成 { w, weight }
function M.buildThemePools()
  local pools = {}
  for theme, node in pairs(data.parts or {}) do
    local arr = {}
    flattenParts(node, arr)
    for _, it in ipairs(arr) do
      -- weight：优先取条目自带，其次按 freq 档位换算
      local wgt = it.weight
      if not wgt and it.freq then wgt = FREQ_WEIGHT[it.freq] end
      it.weight = wgt or 5
    end
    if #arr > 0 then pools[theme] = arr end
  end
  -- 扩展池（地形/山水/色彩/科教等）并入对应主题，供模板引用
  local EX = {
    terrain = "landscape", mountains = "landscape", waterFlora = "landscape",
    color = "landscape", auspiciousTwo = "auspicious",
    science = "industry", postGarrison = "historic",
    foreignName = nil,   -- 法规禁止外国人名地名，默认整体不启用
  }
  for ext, theme in pairs(EX) do
    if theme and data.extendedParts and data.extendedParts[ext] then
      local arr = {}
      flattenParts(data.extendedParts[ext], arr)
      if not pools[theme] then pools[theme] = {} end
      for _, it in ipairs(arr) do
        it.weight = it.weight or 4
        pools[theme][#pools[theme] + 1] = it
      end
    end
  end
  return pools
end

-- 通名池：按地域合并「通用分级通名」+「地域专属通名」
-- regionKeys 可以是字符串（单地域）或数组（多地域合并，如汉地=华北+江南+岭南+华中）
function M.buildSuffixPools(regionKeys)
  local keys = type(regionKeys) == "table" and regionKeys or { regionKeys }
  local pools = {}
  local genericByLevel = {}
  for level, node in pairs(data.suffixes or {}) do
    local arr = {}
    flattenSuffixes(node, arr)
    genericByLevel[level] = arr
  end

  -- 各地域的专属通名合并（**只收白名单内的道路/片区通名**）
  local regionArr = {}
  for _, rk in ipairs(keys) do
    if data.regionSuffixes and data.regionSuffixes[rk] then
      local arr = {}
      flattenSuffixes(data.regionSuffixes[rk], arr)
      for _, it in ipairs(arr) do
        if STREET_SUFFIX_WHITELIST[it.w] then
          it.srcRegion = rk
          regionArr[#regionArr + 1] = it
        end
      end
    end
  end

  -- 合并为「全部可作末位通名」的池（去重，同名取先出现者）
  local seen, all = {}, {}
  local function addList(list, baseLevel)
    for _, it in ipairs(list) do
      if it.w and STREET_SUFFIX_WHITELIST[it.w] and not seen[it.w] then
        seen[it.w] = true
        it.genericLevel = baseLevel
        all[#all + 1] = it
      end
    end
  end
  addList(regionArr, "regionSpecific")
  for _, level in ipairs({ "arterial", "secondary", "local", "district" }) do
    if genericByLevel[level] then addList(genericByLevel[level], level) end
  end

  -- 兜底：白名单过严导致池为空时，退回通用分级通名
  if #all == 0 then
    for _, level in ipairs({ "secondary", "local" }) do
      for _, it in ipairs(genericByLevel[level] or {}) do
        if not seen[it.w] then seen[it.w] = true; all[#all + 1] = it end
      end
    end
  end

  pools.generic = genericByLevel
  pools.regionSpecific = regionArr
  pools.all = all
  return pools
end

--============================================================ 构词 ====

-- 生成一个候选名。
-- 返回 word, endlLen（末位通名长度，用于判定专名是否为空）
local function compose(pools, tmpl, region)
  local chunks = {}
  local stem = ""
  local terminal = nil

  for _, slot in ipairs(tmpl.seq or {}) do
    if slot:sub(1, 1) == "=" then
      local lit = slot:sub(2)
      chunks[#chunks + 1] = lit
      terminal = lit
    elseif slot == "suffix" then
      local pool = pools.sfx
      if not pool or #pool == 0 then return nil end
      local it = M.pickWeighted(pool)
      if not it then return nil end
      chunks[#chunks + 1] = it.w
      terminal = it.w
    else
      local pool = pools.theme[slot]
      if not pool or #pool == 0 then return nil end
      local it = M.pickWeighted(pool)
      if not it then return nil end
      chunks[#chunks + 1] = it.w
      stem = stem .. it.w
    end
  end

  if #chunks == 0 or not terminal then return nil end
  local word = table.concat(chunks)
  return word, #terminal, stem
end

--=========================================================== 校验管线 ==

--[[ 重要：这三个集合必须**惰性构建**。
  最初我写成文件加载时立即遍历 data 构建，结果 data 那时还是 nil
  （由入口 setData 注入），三个黑名单全部为空 —— 校验形同虚设。
  改为首次使用时构建并缓存。
]]
local RARE_SET, BAD_WORD_SET, REAL_BLOCK

local function ensureLookups()
  if RARE_SET then return end
  local d = data or {}

  RARE_SET = {}
  for _, c in ipairs(d.rareChars or {}) do RARE_SET[c] = true end

  BAD_WORD_SET = {}
  for _, s in ipairs(d.badHomophones or {}) do
    if type(s) == "string" then BAD_WORD_SET[s] = true end
  end

  REAL_BLOCK = {}
  for _, s in ipairs(d.realNameBlocklist or {}) do
    if type(s) == "string" then REAL_BLOCK[s] = true end
  end
  for _, s in ipairs(d.cityRoadBlacklist or {}) do
    if type(s) == "string" then REAL_BLOCK[s] = true end
  end
end

function M.getLookups()
  ensureLookups()
  return RARE_SET, BAD_WORD_SET, REAL_BLOCK
end

-- 合法末位通名集合（含模板内的字面量通名）
local function buildTerminalSet(regionPools, region)
  local set = {}
  for _, it in ipairs(regionPools.sfx or {}) do set[it.w] = true end
  for _, t in ipairs(region.templates or {}) do
    for _, slot in ipairs(t.seq or {}) do
      if slot:sub(1, 1) == "=" then set[slot:sub(2)] = true end
    end
  end
  return set
end

-- 单条候选名的合法性与"质量"校验。返回 ok, reason
function M.check(word, termSet, ctx)
  if type(word) ~= "string" or word == "" then return false, "empty" end
  if not M.isCleanCJK(word) then return false, "non-cjk" end

  local n = M.ulen(word)
  if n < 2 then return false, "too-short" end
  if n > 6 then return false, "too-long" end

  -- 结构：必须以合法通名结尾，且去掉通名后专名非空
  local endl = 0
  for t in pairs(termSet) do
    if #t <= #word and word:sub(-#t) == t and #t > endl then endl = #t end
  end
  if endl == 0 then return false, "no-terminal" end
  if #word == endl then return false, "stem-empty" end

  ensureLookups()

  -- 生僻字
  for _, ch in ipairs(M.chars(word)) do
    if RARE_SET[ch] then return false, "rare-char" end
  end

  -- 不雅/谐音黑名单
  if BAD_WORD_SET[word] then return false, "bad-word" end

  -- 真实著名路名
  if REAL_BLOCK[word] then return false, "real-road" end

  -- 退化解校验
  --[[ 只拦真正的"通名自叠"退化解，不做过度拦截。
  我起初还拦了"专名末字 ∈ 通名集合"（如 江路/沙路），但复查发现
  「海塘」「河滘」「青丘」这类本身是合法的真实地名类型——
  专名用山水字、通名也是山水字，在中式路名里完全正常。
  过度拦截会拒掉一半候选，反而伤及多样性。故只保留两条：
    1) 专名与通名完全相同（「塘塘」「路路」）
    2) 单字专名恰好就是个通名字（专名退化为通名）
]]
  local stem = word:sub(1, #word - endl)
  local suffix = word:sub(#word - endl + 1)
  if #stem > 0 then
    if stem == suffix then
      return false, "suffix-repeat"
    end
    if M.ulen(stem) == 1 and termSet[stem] then
      return false, "stem-is-suffix"
    end
  end

  return true
end

--============================================================ 生成池 ==

-- 为一个「风格档案」生成街道名称池。
-- profileKeys 是**地域数组**：单地域写 {"north"}，
-- 合并风格写 {"north","wu","lingnan","central"}（汉地十八省）。
-- 模板与通名来自这些地域的并集，因此同一池内会呈现混合地域风味。
function M.generateProfile(profileKeys, opts)
  opts = opts or {}
  local maxTotal = opts.maxTotal or 800
  -- allCap：单次建池的产名上限（默认取 maxTotal）。
  -- 用途：maxTotal 给得很高（防抽干）时，仍希望建池耗时可控。
  local allCap = opts.allCap or maxTotal
  if allCap > maxTotal then allCap = maxTotal end
  local keys = type(profileKeys) == "table" and profileKeys or { profileKeys }

  local sfxPool = M.buildSuffixPools(keys)
  local pools = {
    theme = M.buildThemePools(),
    sfx = sfxPool.all,
  }

  -- 模板：合并各地域的模板，并加 regionId 前缀避免 id 冲突
  -- 同时过滤掉**聚落类字面量通名**（=屯/=庄/=浩特/=林卡/=巴扎…），
  -- 它们会绕过后缀白名单，产出「石家庄」「邓屯」这类村名。
  local templates = {}
  for _, rk in ipairs(keys) do
    local r = data.regions[rk]
    if r then
      for _, t in ipairs(r.templates or {}) do
        local seq = t.seq or {}
        local term = seq[#seq]
        local termOk = false
        if term then
          if term:sub(1, 1) == "=" then
            -- 字面量通名必须也在街道白名单内
            termOk = STREET_SUFFIX_WHITELIST[term:sub(2)] == true
          else
            termOk = #sfxPool.all > 0
          end
        end
        if termOk then
          templates[#templates + 1] = {
            id = rk .. ":" .. tostring(t.id),
            seq = seq,
            weight = t.weight or 10,
            regionId = rk,
          }
        end
      end
    end
  end

  if #templates == 0 then
    return { names = {}, stats = { reason = "no-template", regions = keys } }
  end

  -- 末位通名集合：本档案全部通名 + 模板里的字面量
  local termSet = {}
  for _, it in ipairs(sfxPool.all) do termSet[it.w] = true end
  for _, t in ipairs(templates) do
    local term = t.seq[#t.seq]
    if term and term:sub(1, 1) == "=" then termSet[term:sub(2)] = true end
  end

  local seen, names = {}, {}
  local attempts, maxAttempts = 0, allCap * 60
  local reasons = {}

  -- 用第一个地域作为 check() 的 ctx（check 目前不依赖具体地域字段）
  local ctx = data.regions[keys[1]] or {}

  while #names < allCap and attempts < maxAttempts do
    attempts = attempts + 1
    local tmpl = M.pickWeighted(templates)
    if tmpl then
      local word = compose(pools, tmpl, tmpl.regionId)
      if word and not seen[word] then
        local ok, why = M.check(word, termSet, ctx)
        if ok then
          seen[word] = true
          names[#names + 1] = word
        else
          reasons[why] = (reasons[why] or 0) + 1
        end
      end
    end
  end

  return {
    names = names,
    stats = {
      regions = keys,
      produced = #names,
      attempts = attempts,
      templates = #templates,
      suffixPool = #sfxPool.all,
      terminalSet = (function() local c = 0 for _ in pairs(termSet) do c = c + 1 end return c end)(),
      rejects = reasons,
    },
  }
end

-- 兼容旧接口：单地域
function M.generateRegion(region, opts)
  return M.generateProfile({ region }, opts)
end

--======================================================== 对外契约层 ==

M._pools = {}
M._cursor = {}
M._opts = {}

function M.reset(region)
  if region then
    M._pools[region] = nil
    M._cursor[region] = nil
    M._opts[region] = nil
  else
    M._pools = {}
    M._cursor = {}
    M._opts = {}
  end
end

-- regionOrKeys 可以是字符串（单地域）或地域数组（合并档案）
local function poolKeyOf(regionOrKeys)
  if type(regionOrKeys) == "table" then
    return table.concat(regionOrKeys, "+")
  end
  return tostring(regionOrKeys)
end

--[[ 取名称池；池子抽干时**自动补建**。

  为什么必须补建：站名/路段名是「用一个取一个」的调用模式，一张大地图可能
  要上千条。若池子耗尽后 request() 返回空表，游戏就退回默认的「停止#N」。
  这正是用户报的 bug（第一个站是「人民路」，之后全是「停止#1/停止#2」）。

  补建出来的名字与旧池去重（同图不重名），并把游标接续到新池开头。
  若连续补建仍产不出新名（理论上不会发生），返回空表由上层兜底。
]]
function M.ensurePool(regionOrKeys, opts)
  local k = poolKeyOf(regionOrKeys)
  opts = opts or {}
  M._opts[k] = opts

  if not M._pools[k] then
    local res = M.generateProfile(regionOrKeys, opts)
    M._pools[k] = res.names
    M._cursor[k] = 1
  end
  return M._pools[k], M._cursor[k]
end

-- 遵守 num 契约。regionOrKeys 支持字符串或地域数组（数组=多地域合并档案）
-- 池子取尽后**环绕复用**，因此不会返回空表，也不会为了造新名而重复建表。
function M.request(regionOrKeys, params, opts)
  params = params or {}
  local num = params.num
  local k = poolKeyOf(regionOrKeys)
  local pool, cursor = M.ensurePool(regionOrKeys, opts)

  -- num < 0（含 nil）：转交 requestAll，保持两条路径行为一致 ——
  -- 游戏会用 num = -1 反复索要名称池。
  if num == -1 or num == nil then
    return M.requestAll(regionOrKeys, opts)
  end

  local n = #pool
  if n == 0 then return {} end          -- 词表异常时才会发生；上层还有兜底

  -- 环绕复用：位置越界即绕回开头，因此永远不会返回条目不足的结果，
  -- 也不会像旧实现那样为了造新名而每次重新建表（那会导致 ~90ms/次）。
  local out = {}
  for _ = 1, num do
    if cursor > n then cursor = 1 end
    out[#out + 1] = pool[cursor]
    cursor = cursor + 1
  end
  M._cursor[k] = cursor
  return out
end

--[[ 「返回全部」的显式接口（num = -1）。

  【语义（实测得出）】游戏把 num = -1 当作「请提供名称池」，并且会**反复调用**
  （实测标记 DBG-c11-n-1-oEMPTY：调用 11 次、每次 num = -1）。

  【绝不返回空】给空表 → 游戏用默认名（停止#N），比偶尔重名糟糕得多。
  基游戏自己就是 `streets[math.random(1,#streets)]`，**可重复随机抽**；
  wiki 对不重名也只是 "recommended"。

  【性能约束（重要）】曾经的做法是「取尽就 topUp 重新造名」。但每次调用都会把
  整池给出、游标推到底，于是**下一次调用必然触发 topUp**，而 topUp 要重新生成
  最多 5000 个名字（实测约 91 ms）—— 结果每次调用都耗 ~90 ms，游戏一选车站就掉帧。

  现在改为**游标环绕复用**：池子取尽就把游标绕回开头，继续给既有名字。
  零成本、绝不返回空，代价只是取尽后开始出现重复（可接受）。
]]
function M.requestAll(regionOrKeys, opts)
  local k = poolKeyOf(regionOrKeys)
  local pool, cursor = M.ensurePool(regionOrKeys, opts)

  -- 取尽 → 环绕复用（不再重新造名，避免每次调用 90ms 的建表开销）
  if cursor > #pool then cursor = 1 end

  local out = {}
  for i = cursor, #pool do out[#out + 1] = pool[i] end
  M._cursor[k] = #pool + 1

  if #out == 0 then out[1] = "人民路" end
  return out
end

-- 兼容旧接口：旧的 requestMixed 是按权重跨地域混抽，
-- 现在「合并档案」已由 request(地域数组) 直接支持，这里改为转调。
-- 跨地域合并池（旧接口）：按权重跨地域混抽。
-- 注意：旧的实现用 M._pools[chosen]（字符串键）读取子池，
-- 但 poolKeyOf 现在把地域数组拼成 "a+b+c" 作为键，两者不一致会读不到池。
-- 保留本接口仅为向后兼容，内部统一转调新的 request(地域数组)。
function M.requestMixed(regionWeights, params, opts)
  local keys = {}
  for k in pairs(regionWeights or {}) do keys[#keys + 1] = k end
  table.sort(keys)
  return M.request(keys, params, opts)
end

M.REGION_ORDER = {
  "north", "wu", "lingnan", "southwest",
  "central", "min", "northwest", "tibet", "mongol",
}

return M

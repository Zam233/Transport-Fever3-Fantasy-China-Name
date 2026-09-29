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
  names.script.lua —— 中国名称集：对外契约入口（合并 MOD）

  ★ 关键结构（这是先前失败的原因）
  基游戏 base/content/names.zip 内的 names.script.lua 是：

      function data()
      return { personNameScriptFn = ..., townsNameScriptFn = ..., streetsNameScriptFn = ... }
      end

  即**必须把返回表包在 data() 里**。我最初直接 `return {...}`，引擎调 data()
  得到 nil，于是报「Value is not a table [key = personNameScriptFn]」，
  人名生成失败并连带城市名退回「城镇1/城镇2」。现按基游戏写法修正。

  ★ 五套名称集与「城市↔街道」对应（用户指定）
      汉地十八省 = 城市:汉地        街道:华北 + 江南 + 岭南 + 华中
      海洋中国   = 城市:海洋中国    街道:闽台 + 西南
      亚寒带     = 城市:亚寒带      街道:东北（华北）
      西北       = 城市:西北        街道:内蒙古 + 西北
      综合       = 城市:四类加权    街道:全部九地域

  说明：TF3 只有一个「名称集」选项，同时决定城镇名、道路名与居民姓名，
  因此每个名称集必须同时提供城镇与街道两套生成器（见游戏内 tooltip
  「改变游戏中城镇、道路名称和居民姓名的来源地区。」）。

  对外契约（与基游戏完全一致）
    townsNameScriptFn(captureParams, params)   params.num < 0 表示返回全部
    streetsNameScriptFn(captureParams, params) params.num < 0 表示返回全部
    personNameScriptFn(captureParams, params)  params.isMale
--------------------------------------------------------------------------]]

-- 带 modId 前缀的绝对路径（相对路径在资源系统里会解析到本文件目录）
local townData   = require("cn_names::/scripts/townname_data.lua")
local streetData = require("cn_names::/scripts/streetname_data.lua")
local townGen    = require("cn_names::/scripts/townnamegen.lua")
local streetGen  = require("cn_names::/scripts/streetnamegen.lua")

streetGen.setData(streetData)

--=========================================================== 风格档案 ==

-- cityKey  -> townname_data.lua 里的 M.town 键
-- regions  -> streetname_data.lua 里的 M.regions 键数组
local PROFILES = {
  han = {
    cityKey = "han",
    regions = { "north", "wu", "lingnan", "central" },
  },
  ocean = {
    cityKey = "ocean",
    regions = { "min", "southwest" },
  },
  subarctic = {
    cityKey = "subarctic",
    regions = { "north" },
  },
  west = {
    cityKey = "northwest",
    regions = { "northwest", "mongol" },
  },
  mixed = {
    cityKey = "mixed",
    regions = { "north", "wu", "lingnan", "southwest", "central",
                "min", "northwest", "tibet", "mongol" },
  },
}

-- 兼容旧命名（名称集文件里可能写 northwest 或 mixed）
local ALIAS = {
  northwest = "west",
  nw = "west",
  ["northwest+mongol"] = "west",
}

local function resolveProfile(captureParams)
  local p = type(captureParams) == "table" and captureParams or {}
  local key = p.style or p.region or "han"
  key = ALIAS[key] or key
  if not PROFILES[key] then
    key = "han"          -- 容错：写错时回退汉地，绝不让引擎崩
  end
  return key, PROFILES[key]
end

--======================================================== 混合风格构建 ==

--[[ townname_data.lua 里只有 han / ocean / northwest / subarctic 四类，
   **没有 mixed 键** —— 混合风格须在运行时把四类的**已归一化池**合并出来。
   （这正是先前 mixed 与 han 产出完全相同的原因：取不到 mixed 就回落到了 han。）
  合并逻辑沿用 MOD1 中已验证的做法：经 townGen.buildPools 归一化后再合并，
  并保留 suffixSlot 归属，避免池被过度过滤。]]
local STYLE_KEYS = { "han", "ocean", "northwest", "subarctic" }

local mixedWeights = townData.mixedWeights or {
  han = 4, ocean = 2, northwest = 2, subarctic = 1,
}

local mixedCityStyle = nil
local function getMixedCityStyle()
  if mixedCityStyle then return mixedCityStyle end

  local mixed = {
    parts = {}, suffixes = {}, templates = {},
    banned = { chars = {}, realNames = {}, suffixes = {} },
  }
  local bannedSeen = {}

  for _, key in ipairs(STYLE_KEYS) do
    local st = townData.town[key]
    if st then
      local w = mixedWeights[key] or 1
      local pools = townGen.buildPools(st)

      for slot, items in pairs(pools) do
        if slot:find("suffix") then
          for _, it in ipairs(items) do
            mixed.suffixes[#mixed.suffixes + 1] = {
              w = it.w, suffixSlot = slot, weight = (it.weight or 1) * w,
            }
          end
        else
          if not mixed.parts[slot] then mixed.parts[slot] = {} end
          for _, it in ipairs(items) do
            mixed.parts[slot][#mixed.parts[slot] + 1] = {
              w = it.w, weight = (it.weight or 1) * w,
            }
          end
        end
      end

      for _, t in ipairs(townGen.buildTemplates(st, pools)) do
        mixed.templates[#mixed.templates + 1] = {
          id = key .. ":" .. t.id, seq = t.seq, weight = (t.weight or 1) * w,
        }
      end

      for _, n in ipairs((st.banned or {}).realNames or {}) do
        mixed.banned.realNames[#mixed.banned.realNames + 1] = n
      end
      for _, c in ipairs((st.banned or {}).chars or {}) do
        local ch = type(c) == "table" and c.w or c
        if type(ch) == "string" and not bannedSeen[ch] then
          bannedSeen[ch] = true
          mixed.banned.chars[#mixed.banned.chars + 1] = ch
        end
      end
    end
  end

  mixedCityStyle = mixed
  return mixed
end

--=============================================================== 城市名 ==

local function townsFn(captureParams, params)
  params = params or {}
  local key, prof = resolveProfile(captureParams)

  local style
  if prof.cityKey == "mixed" then
    style = getMixedCityStyle()
  else
    style = townData.town[prof.cityKey]
  end
  if not style then style = townData.town.han end

  townGen.seed((captureParams and captureParams.seed) or key)

  local opts = { maxTotal = 4000 }
  if style.softMaxLen then opts.softMaxLen = style.softMaxLen end
  if style.softMaxLen and style.softMaxLen < 4 then
    opts.quotaBase = 600
    opts.longQuotaRatio = 0.06
  end

  local out = townGen.request(style, key, params, opts)
  -- 兜底：任何异常都返回至少一个合法名，避免引擎拿到空表后回退成「城镇N」
  if type(out) ~= "table" or #out == 0 then
    return { "新安" }
  end
  return out
end

--=============================================================== 街道名 ==

local function streetsFn(captureParams, params)
  params = params or {}
  local key, prof = resolveProfile(captureParams)

  streetGen.seed((captureParams and captureParams.seed) or key)

  --[[ 池子与「永不返回空」的保证
    实测（诊断标记 DBG-c11-n-1-oEMPTY）：游戏用 num = -1 反复索要名称池，
    一旦拿到空表就退回默认的「停止#N」。
    因此：
      * maxTotal 给足 20000（allCap 单次建池 5000），避免大图抽干；
      * requestAll / request 在取尽时自动补建，仍造不出新名则从头复用
        —— 宁可偶尔重名，也绝不给空表（详见 streetnamegen.requestAll 注释）。
  ]]
  local opts = { maxTotal = 20000, allCap = 5000 }

  -- 注意：prof.regions 本身就是地域数组，不能再包一层 {}
  -- （包成 {{...}} 会让 poolKeyOf 对表做 concat 而报错）
  local want = params.num
  local out
  if want == -1 or want == nil then
    out = streetGen.requestAll(prof.regions, opts)
  else
    out = streetGen.request(prof.regions, { num = want }, opts)
  end

  -- 兜底：仍为空时返回一条合法路名，绝不让引擎拿到空表
  if type(out) ~= "table" or #out == 0 then
    return { "人民路" }
  end
  return out
end

--=============================================================== 人 名 ==

local SURNAMES = {
  "赵","钱","孙","李","周","吴","郑","王","冯","陈","褚","卫","蒋","沈",
  "韩","杨","朱","秦","许","何","吕","张","孔","曹","严","华","金","魏",
  "陶","姜","谢","邹","喻","柏","水","窦","章","云","苏","潘","葛","范",
  "彭","鲁","韦","昌","马","苗","凤","花","方","俞","任","袁","柳","唐",
  "罗","高","林","梁","宋","郭","洪","程","傅","邓","曾","叶","阎","余",
}

local MALE_CHARS = {
  "伟","强","军","磊","涛","斌","锋","刚","勇","杰","鹏","辉","明","亮",
  "浩","宇","晨","宏","立","建","国","华","志","远","航","森","楠","霖",
}

local FEMALE_CHARS = {
  "芳","娟","敏","静","丽","艳","娜","秀","霞","燕","玲","婷","洁","颖",
  "雪","梅","兰","菊","荷","月","云","欣","怡","妍","莉","薇","蕾","蓉",
}

-- 注意：基游戏的人名函数返回**字符串**（见 names.script.lua 第 9-35 行），
-- 不要返回表。
--[[ 只播种一次的辅助器（修 bug）
  问题：人名函数原先**每次调用都 reseed**，而种子只由
  isMale + lang + key 决定 —— 这些值在一局游戏里恒定不变，
  于是每次都得到**完全相同的随机序列**，导致所有人名都一样
  （实测：男名连调 10 次全是「彭国斌」，女名全是「方怡蕾」）。

  修法：同一 key（不同性别/语言算不同 key）只在**首次**播种，
  之后 RNG 状态自然推进，连续调用就会产出不同的名字。
  显式传入不同 seed（测试用）时会重新播种，保证测试可复现。

  注意：城市名/街道名函数没有这个问题 —— 它们的种子只播一次，
  之后靠已用池游标逐个推进。
]]
local seedCache = {}
local function seedOnce(key, seedValue)
  if seedCache[key] ~= seedValue then
    seedCache[key] = seedValue
    townGen.seed(seedValue)
  end
end

--[[ 取一个"本局随机"的种子。
  为什么要向 math.random 借随机性：我们自己的 RNG 是自实现的确定性 LCG，
  math.random 则由引擎在启动时播种。若不借用，那么**每局游戏的人名序列
  都会完全一样**（所有地图的王斌晨都还是王斌晨）。
  做法：用引擎的 math.random 取一个偏移量，再交给我们的确定性 RNG，
  这样既有局间差异，又能保持同一局内可复现。
]]
local function runSeed(bucket)
  local r = 0
  if type(math.random) == "function" then
    local ok, v = pcall(math.random, 1, 1000000000)
    if ok and type(v) == "number" then r = v end
  end
  return bucket .. "#" .. tostring(r)
end

local function personFn(captureParams, params)
  params = params or {}
  local key = resolveProfile(captureParams)
  -- 按 性别+语言+风格 分桶：各桶独立推进
  local bucket = tostring(params.isMale) .. tostring(params.lang) .. key
  local seedValue = (captureParams and captureParams.seed) or runSeed("person")
  seedOnce("person|" .. bucket, seedValue)

  local surname = SURNAMES[townGen.rand(#SURNAMES) + 1]
  local pool = params.isMale and MALE_CHARS or FEMALE_CHARS
  local given = pool[townGen.rand(#pool) + 1] .. pool[townGen.rand(#pool) + 1]
  return surname .. given
end

--=========================================================== 资源定义 ==

-- 必须包在 data() 里（与基游戏 names.script.lua 一致）
function data()
  return {
    personNameScriptFn  = personFn,
    townsNameScriptFn   = townsFn,
    streetsNameScriptFn = streetsFn,
  }
end

-- 便于本地测试直接驱动
return {
  data = data,
  _townsFn = townsFn,
  _streetsFn = streetsFn,
  _personFn = personFn,
  _PROFILES = PROFILES,
}

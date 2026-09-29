--[[--------------------------------------------------------------------------
  export_names.lua —— 导出四类（含综合）完整产出清单，供人工复核

  用法：texlua tools/export_names.lua [每类个数，默认 600]
  产出：
    build/产出清单-城市名.md          人读清单（分风格、含统计）
    build/产出-汉地.txt 等 5 个纯名单   一行一名，便于比对/取用
--------------------------------------------------------------------------]]

local N = tonumber(arg and arg[1]) or 600

local SCRIPTS = "K:/幻想中文名称/MOD1-中国城市名称集/ChineseTownNames/content/scripts/"
local NAMES   = "K:/幻想中文名称/MOD1-中国城市名称集/ChineseTownNames/content/names/"
local OUT     = "K:/幻想中文名称/build/"

local function loadAt(path)
  local f = io.open(path, "rb")
  if not f then return nil, "找不到 " .. path end
  local src = f:read("*a"); f:close()
  if src:sub(1, 3) == "\239\187\191" then src = src:sub(4) end
  local chunk, err = load(src, "@" .. path)
  if not chunk then return nil, err end
  local ok, res = pcall(chunk)
  if not ok then return nil, res end
  return res
end

local gen  = assert(loadAt(SCRIPTS .. "namegen.lua"))
local data = assert(loadAt(SCRIPTS .. "townname_data.lua"))

package.loaded["namegen"] = gen
package.loaded["townname_data"] = data
package.path = SCRIPTS .. "?.lua;" .. NAMES .. "?.lua;" .. package.path
local namesMod = assert(loadAt(NAMES .. "names.script.lua"))

local LABELS = {
  han = "汉地十八省", ocean = "海洋中国",
  northwest = "西北", subarctic = "亚寒带", mixed = "综合（四类加权混合）",
}
local ORDER = { "han", "ocean", "northwest", "subarctic", "mixed" }

local function ulen(s) return gen.ulen(s) end

-- 收集某风格合法的末位通名集合
local function suffixSet(style)
  local pools = gen.buildPools(style)
  local s = {}
  for _, slot in ipairs({ "suffix", "terrain_suffix", "auspicious_suffix" }) do
    for _, it in ipairs(pools[slot] or {}) do s[it.w] = true end
  end
  for _, t in ipairs(gen.buildTemplates(style, pools)) do
    for _, x in ipairs(t.seq) do
      if x:sub(1, 1) == "=" then s[x:sub(2)] = true end
    end
  end
  return s
end

-- UTF-8 合法性
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

local function analyse(list, sfx)
  local stat = {
    n = #list,
    lenDist = {},
    suffixDist = {},
    badTail = {},
    badUtf8 = 0,
    dup = {},
    seen = {},
  }
  for _, name in ipairs(list) do
    -- 长度
    local L = ulen(name)
    stat.lenDist[L] = (stat.lenDist[L] or 0) + 1
    -- UTF-8
    if not validUtf8(name) then stat.badUtf8 = stat.badUtf8 + 1 end
    -- 重复
    if stat.seen[name] then
      stat.dup[#stat.dup + 1] = name
    else
      stat.seen[name] = true
    end
    -- 末位通名（最长匹配）
    local best = nil
    if sfx then
      for s in pairs(sfx) do
        if #s <= #name and name:sub(-#s) == s then
          if not best or #s > #best then best = s end
        end
      end
    end
    if best then
      stat.suffixDist[best] = (stat.suffixDist[best] or 0) + 1
    else
      stat.badTail[#stat.badTail + 1] = name
    end
  end
  return stat
end

local function topSorted(t, limit)
  local arr = {}
  for k, v in pairs(t) do arr[#arr + 1] = { k = k, v = v } end
  table.sort(arr, function(a, b)
    if a.v ~= b.v then return a.v > b.v end
    return a.k < b.k
  end)
  local out = {}
  for i = 1, math.min(limit or #arr, #arr) do
    out[#out + 1] = string.format("%s(%d)", arr[i].k, arr[i].v)
  end
  return out
end

--=========================================================== 生成与导出 ==

local md = {}
local function w(s) md[#md + 1] = s end

w("# 中国城市名称集 —— 四类产出清单")
w("")
w("> 由 `tools/export_names.lua` 生成。四类各自独立成池，**同一类内不重复**；")
w("> 「综合」为四类加权混合（汉 4 : 海 2 : 西 2 : 寒 1）。")
w("> 全部地名为虚构，不含真实城市名，避开黑名单。")
w("")

-- 目录
w("## 目录")
w("")
for _, key in ipairs(ORDER) do
  w(string.format("- [%s](#%s)", LABELS[key], key))
end
w("")
w("---")
w("")

local allStats = {}

for _, key in ipairs(ORDER) do
  local list
  if key == "mixed" then
    list = namesMod.townsNameScriptFn({ style = "mixed", seed = "export" },
                                      { num = N, lang = "zh_CN" })
  else
    local pool = gen.generatePool(data.town[key], key, { maxTotal = N })
    list = pool.names
  end

  -- 末位通名集合（混合风格用四类并集）
  local sfx = {}
  if key == "mixed" then
    for _, k2 in ipairs({ "han", "ocean", "northwest", "subarctic" }) do
      for s in pairs(suffixSet(data.town[k2])) do sfx[s] = true end
    end
  else
    sfx = suffixSet(data.town[key])
  end

  local st = analyse(list, sfx)
  allStats[key] = st

  w(string.format("<a id=\"%s\"></a>", key))
  w(string.format("## %s", LABELS[key]))
  w("")
  w(string.format("共 **%d** 个。", st.n))
  w("")
  w("| 统计项 | 结果 |")
  w("|---|---|")
  w(string.format("| 重复 | %d |", #st.dup))
  w(string.format("| 末位非通名 | %d |", #st.badTail))
  w(string.format("| 非法 UTF-8 | %d |", st.badUtf8))
  w(string.format("| 字数分布 | %s |", table.concat(topSorted(st.lenDist, 8), " ")))
  w(string.format("| 通名 Top12 | %s |", table.concat(topSorted(st.suffixDist, 12), " ")))
  w("")

  if #st.badTail > 0 then
    w("**末位非通名样例**：" .. table.concat(st.badTail, " ", 1, math.min(10, #st.badTail)))
    w("")
  end

  -- 名单（每行 8 个，对齐显示）
  w("**完整名单**")
  w("")
  w("```")
  for i = 1, #list do
    io.write("")
    local padded = list[i]
    -- 简单对齐：按显示宽度补空格（中文算 2）
    local width = 0
    for _ in padded:gmatch("[^\128-\191]") do width = width + 1 end
    w(padded .. string.rep(" ", math.max(0, 14 - width * 2)))
    if i % 6 == 0 then w("") end
  end
  if #list % 6 ~= 0 then w("") end
  w("```")
  w("")
  w("---")
  w("")
end

-- 汇总
w("## 汇总")
w("")
w("| 风格 | 产出 | 重复 | 末位非通名 | 非法UTF8 |")
w("|---|---|---|---|---|")
local tot, totDup, totBad, totUtf = 0, 0, 0, 0
for _, key in ipairs(ORDER) do
  local st = allStats[key]
  w(string.format("| %s | %d | %d | %d | %d |",
    LABELS[key], st.n, #st.dup, #st.badTail, st.badUtf8))
  tot = tot + st.n
  totDup = totDup + #st.dup
  totBad = totBad + #st.badTail
  totUtf = totUtf + st.badUtf8
end
w(string.format("| **合计** | **%d** | **%d** | **%d** | **%d** |",
  tot, totDup, totBad, totUtf))
w("")

-- 写 Markdown
local fmd = assert(io.open(OUT .. "产出清单-城市名.md", "wb"))
fmd:write(table.concat(md, "\n"))
fmd:close()

-- 写纯名单（一行一名）
for _, key in ipairs(ORDER) do
  local list
  if key == "mixed" then
    list = namesMod.townsNameScriptFn({ style = "mixed", seed = "export" },
                                      { num = N, lang = "zh_CN" })
  else
    list = gen.generatePool(data.town[key], key, { maxTotal = N }).names
  end
  local fp = assert(io.open(OUT .. "产出-" .. LABELS[key]:gsub("（.*", "") .. ".txt", "wb"))
  fp:write(table.concat(list, "\n"))
  fp:close()
end

print(string.format("已导出 %d 个风格，共 %d 个名字", #ORDER, tot))
print(string.format("汇总：重复 %d，末位非通名 %d，非法UTF8 %d", totDup, totBad, totUtf))
print("人读清单：build/产出清单-城市名.md")

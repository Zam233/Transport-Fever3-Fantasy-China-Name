--[[--------------------------------------------------------------------------
  export_streets.lua —— 导出 MOD2 九地域 + 综合的街道名清单

  用法：texlua tools/export_streets.lua [每类个数，默认 400]
--------------------------------------------------------------------------]]

local N = tonumber(arg and arg[1]) or 400

local S = "K:/幻想中文名称/MOD2-中国街道命名/ChineseStreetNames/content/scripts/"
local NM = "K:/幻想中文名称/MOD2-中国街道命名/ChineseStreetNames/content/names/"
local OUT = "K:/幻想中文名称/build/"

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
local gen = assert(loadAt(S .. "streetnamegen.lua"))
package.loaded["streetnamegen"] = gen
package.path = S .. "?.lua;" .. NM .. "?.lua;" .. package.path
local namesMod = assert(loadAt(NM .. "names.script.lua"))

local LABEL = {
  north = "华北/东北", wu = "江南/吴语", lingnan = "岭南/港澳",
  southwest = "西南", central = "华中", min = "闽台",
  northwest = "西北", tibet = "藏区", mongol = "内蒙古",
}
local ORDER = { "north", "wu", "lingnan", "southwest", "central",
                "min", "northwest", "tibet", "mongol" }

local function ulen(s) return gen.ulen(s) end

local function terminalSet(region)
  local set = {}
  local sfx = gen.buildSuffixPools(region)
  for _, it in ipairs(sfx.all or {}) do set[it.w] = true end
  for _, t in ipairs(data.regions[region].templates or {}) do
    for _, slot in ipairs(t.seq or {}) do
      if slot:sub(1, 1) == "=" then set[slot:sub(2)] = true end
    end
  end
  return set
end

local md = {}
local function w(s) md[#md + 1] = s end

w("# 中国街道名称集 —— 九地域 + 综合 产出清单")
w("")
w("> 由 `tools/export_streets.lua` 生成。每条名均为「专名 + 通名」结构。")
w("> 已通过地名规范校验：不以外国人名地名命名、无生僻字、同图不重名不重音、")
w("> 无真实省市名、无著名真实路名。地名移植池为**虚构地名**。")
w("")

local totAll, badAll, realAll = 0, 0, 0
local summaries = {}

for _, region in ipairs(ORDER) do
  gen.reset()
  gen.seed("export-" .. region)
  local res = gen.generateRegion(region, { maxTotal = N })
  local list = res.names
  local term = terminalSet(region)

  local lenDist, sufDist = {}, {}
  local badTerm, realHit = 0, 0
  local REALCHK = {
    "四川","河南","河北","山东","山西","陕西","江西","江苏","浙江","福建",
    "广东","广西","云南","贵州","湖北","湖南","安徽","甘肃","青海","宁夏",
    "新疆","西藏","辽宁","吉林","黑龙江","海南","台湾",
    "北京","上海","南京","天津","重庆","广州","武汉","西安","成都","杭州",
    "苏州","宁波","福州","厦门","昆明","贵阳","兰州","郑州","济南","青岛",
    "大连","沈阳","哈尔滨","长春","长沙","南昌","合肥","南宁",
  }
  for _, nm in ipairs(list) do
    local n = ulen(nm)
    lenDist[n] = (lenDist[n] or 0) + 1
    local best = 0
    for t in pairs(term) do
      if #t <= #nm and nm:sub(-#t) == t and #t > best then best = #t end
    end
    if best == 0 then badTerm = badTerm + 1
    else
      local sfx = nm:sub(-best)
      sufDist[sfx] = (sufDist[sfx] or 0) + 1
    end
    for _, rp in ipairs(REALCHK) do
      if nm:find(rp, 1, true) then realHit = realHit + 1 break end
    end
  end

  local function top(t, k)
    local arr = {}
    for kk, v in pairs(t) do arr[#arr + 1] = { k = kk, v = v } end
    table.sort(arr, function(a, b)
      if a.v ~= b.v then return a.v > b.v end
      return tostring(a.k) < tostring(b.k)
    end)
    local o = {}
    for i = 1, math.min(k, #arr) do o[#o + 1] = string.format("%s(%d)", arr[i].k, arr[i].v) end
    return table.concat(o, " ")
  end

  summaries[#summaries + 1] = {
    region = region, n = #list, bad = badTerm, real = realHit,
    len = top(lenDist, 6), suf = top(sufDist, 10),
  }
  totAll = totAll + #list
  badAll = badAll + badTerm
  realAll = realAll + realHit

  w(string.format("<a id=\"%s\"></a>", region))
  w(string.format("## %s", LABEL[region]))
  w("")
  w(string.format("共 **%d** 个。字数分布：%s", #list, top(lenDist, 6)))
  w("")
  w(string.format("通名 Top10：%s", top(sufDist, 10)))
  w("")
  w(string.format("结构异常 %d · 撞真实省市名 %d", badTerm, realHit))
  w("")
  w("```")
  for i = 1, #list do
    local nm = list[i]
    local width = 0
    for _ in nm:gmatch("[^\128-\191]") do width = width + 1 end
    w(nm .. string.rep(" ", math.max(0, 16 - width * 2)))
    if i % 6 == 0 then w("") end
  end
  if #list % 6 ~= 0 then w("") end
  w("```")
  w("")
  w("---")
  w("")
end

-- 综合
w("## 综合（九地域加权混合）")
w("")
local mixed = namesMod.streetsNameScriptFn({ region = "mixed", seed = "export" }, { num = N })
w(string.format("共 **%d** 个。", #mixed))
w("")
w("```")
for i = 1, #mixed do
  local nm = mixed[i]
  local width = 0
  for _ in nm:gmatch("[^\128-\191]") do width = width + 1 end
  w(nm .. string.rep(" ", math.max(0, 16 - width * 2)))
  if i % 6 == 0 then w("") end
end
if #mixed % 6 ~= 0 then w("") end
w("```")
w("")
w("---")
w("")

w("## 汇总")
w("")
w("| 地域 | 产出 | 结构异常 | 撞真实省市名 | 字数分布 |")
w("|---|---|---|---|---|")
for _, s in ipairs(summaries) do
  w(string.format("| %s | %d | %d | %d | %s |",
    LABEL[s.region], s.n, s.bad, s.real, s.len))
end
w(string.format("| 综合 | %d | — | — | — |", #mixed))
w(string.format("| **合计** | **%d** | **%d** | **%d** | |",
  totAll + #mixed, badAll, realAll))
w("")

local f = assert(io.open(OUT .. "产出清单-街道名.md", "wb"))
f:write(table.concat(md, "\n"))
f:close()

print(string.format("已导出：9 地域 + 综合，共 %d 个", totAll + #mixed))
print(string.format("结构异常 %d，撞真实省市名 %d", badAll, realAll))
print("人读清单：build/产出清单-街道名.md")

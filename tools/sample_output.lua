--[[--------------------------------------------------------------------------
  sample_output.lua —— 抽样查看各风格实际产出

  用法：texlua tools/sample_output.lua [每类个数]
--------------------------------------------------------------------------]]

local N = tonumber(arg and arg[1]) or 25

local MOD1_SCRIPTS = "K:/幻想中文名称/MOD1-中国城市名称集/ChineseTownNames/content/scripts/"
local MOD1_NAMES   = "K:/幻想中文名称/MOD1-中国城市名称集/ChineseTownNames/content/names/"

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

local gen  = assert(loadAt(MOD1_SCRIPTS .. "namegen.lua"))
local data = assert(loadAt(MOD1_SCRIPTS .. "townname_data.lua"))

package.loaded["namegen"] = gen
package.loaded["townname_data"] = data
package.path = MOD1_SCRIPTS .. "?.lua;" .. MOD1_NAMES .. "?.lua;" .. package.path

local namesMod = assert(loadAt(MOD1_NAMES .. "names.script.lua"))

local LABELS = {
  han = "汉地十八省", ocean = "海洋中国",
  northwest = "西北", subarctic = "亚寒带",
}

local function ulen(s) return gen.ulen(s) end

local function lenStats(list)
  local d = {}
  for _, n in ipairs(list) do
    local k = ulen(n); d[k] = (d[k] or 0) + 1
  end
  local ks = {}
  for k in pairs(d) do ks[#ks + 1] = k end
  table.sort(ks)
  local out = {}
  for _, k in ipairs(ks) do out[#out + 1] = string.format("%d字×%d", k, d[k]) end
  return table.concat(out, " ")
end

-- 末位通名频次（用整池统计，样本太小看不出分布）
local function suffixDist(pool, limit)
  local d = {}
  -- 用池里所有通名做后缀匹配（取最长匹配）
  local tails = {}
  for _, key in ipairs({ "han", "ocean", "northwest", "subarctic" }) do
    local st = data.town[key]
    for _, s in ipairs(st.suffixes or {}) do
      local w = tostring(s.w or "")
      -- 斜杠串要拆
      for tok in w:gmatch("[^、/／]+") do
        tok = tok:gsub("%s", ""):gsub("[%(（].*", "")
        if tok ~= "" and ulen(tok) <= 3 then tails[tok] = true end
      end
    end
  end
  for _, nm in ipairs(pool) do
    local best = nil
    for t in pairs(tails) do
      if #t <= #nm and nm:sub(-#t) == t then
        if not best or #t > #best then best = t end
      end
    end
    if best then d[best] = (d[best] or 0) + 1 end
  end
  local arr = {}
  for k, v in pairs(d) do arr[#arr + 1] = { k = k, v = v } end
  table.sort(arr, function(a, b) return a.v > b.v end)
  local out = {}
  for i = 1, math.min(limit or 12, #arr) do
    out[#out + 1] = arr[i].k .. "(" .. arr[i].v .. ")"
  end
  return table.concat(out, " ")
end

print(string.rep("=", 72))
print("中国城市名称集 —— 实际产出抽样")
print(string.rep("=", 72))

for _, key in ipairs({ "han", "ocean", "northwest", "subarctic" }) do
  gen.reset()
  local pool = gen.generatePool(data.town[key], key, { maxTotal = 600 })
  local list = pool.names
  print("")
  print(string.format("【%s】共生成 %d 个   字数分布：%s",
        LABELS[key] or key, #list, lenStats(list)))
  print(string.format("   通名分布：%s", suffixDist(list, 10)))
  print("   样例：")
  for i = 1, math.min(N, #list) do
    io.write("     " .. string.format("%-6s", list[i]))
    if i % 6 == 0 then io.write("\n") end
  end
  io.write("\n")
end

-- 混合风格
print("")
print(string.rep("-", 72))
print("【综合（四类加权混合）】")
local mixed = namesMod.townsNameScriptFn({ style = "mixed", seed = "demo" }, { num = N * 2, lang = "zh_CN" })
local mlist = {}
for i, v in ipairs(mixed) do mlist[i] = v end
print(string.format("   产出 %d 个   字数分布：%s", #mlist, lenStats(mlist)))
print("   样例：")
for i = 1, #mlist do
  io.write("     " .. string.format("%-6s", mlist[i]))
  if i % 6 == 0 then io.write("\n") end
end
io.write("\n")

-- 人名与站名
print("")
print(string.rep("-", 72))
print("【居民人名】")
io.write("   男：")
for i = 1, 8 do io.write(namesMod.personNameScriptFn({ seed = "m" .. i }, { isMale = true, lang = "zh_CN" }) .. " ") end
io.write("\n   女：")
for i = 1, 8 do io.write(namesMod.personNameScriptFn({ seed = "f" .. i }, { isMale = false, lang = "zh_CN" }) .. " ") end
io.write("\n")

print("")
print(string.rep("-", 72))
print("【车站/街道默认名（MOD1 轻量版）】")
for _, key in ipairs({ "han", "ocean", "northwest", "subarctic" }) do
  local st = namesMod.streetsNameScriptFn({ style = key, seed = key }, { num = 6 })
  print(string.format("   %-10s %s", LABELS[key] or key, table.concat(st, " ")))
end

print("")
print(string.rep("=", 72))

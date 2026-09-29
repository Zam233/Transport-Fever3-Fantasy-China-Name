local ROOT = "K:/幻想中文名称/cn_names/"
_G._ = function(s) return s end
local cache = {}
_G.require = function(name)
  if cache[name] ~= nil then return cache[name] end
  local rest = name:match("^[%w_]+::/(.+)$")
  if rest then
    local f = io.open(ROOT.."content/"..rest, "rb"); if not f then error("nf "..rest) end
    local s=f:read("*a"); f:close()
    if s:sub(1,3)=="\239\187\191" then s=s:sub(4) end
    local c=assert(load(s,"@"..rest)); local ok,m=pcall(c)
    if not ok then error("rt "..rest..": "..tostring(m)) end
    cache[name]=m; return m
  end
  error("unresolved "..name)
end
local D = dofile(ROOT.."content/names/names.script.lua").data()

for _, style in ipairs({"han","ocean","subarctic","west","mixed"}) do
  local seen, n = {}, 0
  local samples = {}
  for i = 1, 60 do
    local nm = D.personNameScriptFn({ style = style }, { isMale = true, lang = "zh_CN" })
    if not seen[nm] then seen[nm] = true; n = n + 1 end
    if i <= 8 then samples[#samples+1] = nm end
  end
  print(string.format("  %-10s 60 次男名 -> %d 个不重复   样例: %s", style, n, table.concat(samples, " ")))
end
print("")
for _, style in ipairs({"han","ocean"}) do
  local seen, n = {}, 0
  for i = 1, 60 do
    local nm = D.personNameScriptFn({ style = style }, { isMale = false, lang = "zh_CN" })
    if not seen[nm] then seen[nm] = true; n = n + 1 end
  end
  print(string.format("  %-10s 60 次女名 -> %d 个不重复", style, n))
end

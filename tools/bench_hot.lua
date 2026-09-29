local ROOT = "K:/幻想中文名称/cn_names/"
local function loadf(p) local f=io.open(p,"rb"); local s=f:read("*a"); f:close()
  if s:sub(1,3)=="\239\187\191" then s=s:sub(4) end return assert(load(s,"@"..p))() end
local data = loadf(ROOT.."content/scripts/streetname_data.lua")
local gen  = loadf(ROOT.."content/scripts/streetnamegen.lua")
gen.setData(data)
local PROF = {"north","wu","lingnan","central"}
local OPTS = { maxTotal = 20000, allCap = 5000 }

-- 统计 generateProfile 调用次数
local origGen = gen.generateProfile
local genCalls = 0
gen.generateProfile = function(...) genCalls = genCalls + 1; return origGen(...) end

gen.reset(); gen.seed("b")
-- 冷启动一次
genCalls = 0
local t0 = os.clock()
local r1 = gen.requestAll(PROF, OPTS)
local d1 = (os.clock()-t0)*1000
print(string.format("冷调用: %.1f ms, 返回 %d 条, generateProfile 调用 %d 次", d1, #r1, genCalls))

-- 热调用
genCalls = 0
t0 = os.clock()
for i = 1, 5 do gen.requestAll(PROF, OPTS) end
local d2 = (os.clock()-t0)*1000
print(string.format("热调用 x5: 共 %.1f ms (%.1f ms/次), generateProfile 调用 %d 次", d2, d2/5, genCalls))

-- 看池子状态
local keys = {}
for k,v in pairs(gen._pools) do keys[#keys+1] = k.."(len="..#v..")" end
print("池子: "..table.concat(keys, ", "))
local cur = {}
for k,v in pairs(gen._cursor) do cur[#cur+1] = k.."="..tostring(v) end
print("游标: "..table.concat(cur, ", "))

-- 再热调用 20 次，看是否每次都快
t0 = os.clock()
for i = 1, 20 do gen.requestAll(PROF, OPTS) end
print(string.format("热调用 x20: %.1f ms (%.1f ms/次)", (os.clock()-t0)*1000, (os.clock()-t0)*1000/20))

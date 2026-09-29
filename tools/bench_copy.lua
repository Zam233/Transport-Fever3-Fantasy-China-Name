-- 微基准：单独测「复制 5000 条名字」到底要多久
local ROOT = "K:/幻想中文名称/cn_names/"
local function loadf(p) local f=io.open(p,"rb"); local s=f:read("*a"); f:close()
  if s:sub(1,3)=="\239\187\191" then s=s:sub(4) end return assert(load(s,"@"..p))() end
local data = loadf(ROOT.."content/scripts/streetname_data.lua")
local gen  = loadf(ROOT.."content/scripts/streetnamegen.lua")
gen.setData(data)

local t0 = os.clock()
local res = gen.generateProfile({"north","wu","lingnan","central"}, { maxTotal = 20000, allCap = 5000 })
print(string.format("建池 5000 条: %.1f ms", (os.clock()-t0)*1000))
local pool = res.names
print("池子长度: "..#pool)

-- A) 纯复制数组
t0 = os.clock()
local acc = 0
for _ = 1, 200 do
  local out = {}
  for i = 1, #pool do out[i] = pool[i] end
  acc = acc + #out
end
print(string.format("A) 纯复制数组 x200: %.1f ms (%.3f ms/次)  acc=%d", (os.clock()-t0)*1000, (os.clock()-t0)*1000/200, acc))

-- B) for i=cursor,#pool 带游标（每次从头，模拟 requestAll 但不清空游标）
t0 = os.clock()
acc = 0
for _ = 1, 200 do
  local out = {}
  local n = 0
  for i = 1, #pool do n = n + 1; out[n] = pool[i] end
  acc = acc + n
end
print(string.format("B) 逐条赋给新表 x200: %.1f ms (%.3f ms/次)", (os.clock()-t0)*1000, (os.clock()-t0)*1000/200))

-- C) table.concat 序列化（看字符串总量）
t0 = os.clock()
local total = 0
for _ = 1, 200 do total = total + #table.concat(pool, "") end
print(string.format("C) table.concat x200: %.1f ms, 每池字节约 %d", (os.clock()-t0)*1000, total/200))

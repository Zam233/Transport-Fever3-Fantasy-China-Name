--[[--------------------------------------------------------------------------
  syntax_check.lua —— 用 Lua 编译器校验所有资源脚本的语法

  为什么需要：TF3 的 .names.lua / .script 文件本质上都是 Lua 源码，
  但游戏只有在加载时才会报语法错误，届时表现为 MOD 直接不可用。
  本工具在本地用 texlua 的 load() 对每个文件做「只编译不执行」的检查。

  用法：
      texlua tools/syntax_check.lua <目录1> [目录2 ...]

  退出码：0 = 全部通过；1 = 存在语法错误。
--------------------------------------------------------------------------]]

local function listLuaFiles(dir)
  local files = {}
  -- texlua 下用 io.popen 调 dir /b（Windows）
  local cmd = 'dir /b /s "' .. dir .. '\\*.lua" 2>nul'
  local p = io.popen(cmd)
  if p then
    for line in p:lines() do
      if line and #line > 0 then files[#files + 1] = line end
    end
    p:close()
  end
  -- .script 后缀也要检查
  local cmd2 = 'dir /b /s "' .. dir .. '\\*.script" 2>nul'
  local p2 = io.popen(cmd2)
  if p2 then
    for line in p2:lines() do
      if line and #line > 0 then files[#files + 1] = line end
    end
    p2:close()
  end
  return files
end

local function readAll(path)
  local f = io.open(path, "rb")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  return content
end

local total, failed = 0, 0

for _, dir in ipairs(arg or {}) do
  local files = listLuaFiles(dir)
  for _, path in ipairs(files) do
    total = total + 1
    local src = readAll(path)
    if not src then
      print(string.format("[读取失败] %s", path))
      failed = failed + 1
    else
      -- 去掉 UTF-8 BOM（若有），否则 load 会报错
      if src:sub(1, 3) == "\239\187\191" then
        src = src:sub(4)
      end
      local chunk, err = load(src, "@" .. path)
      if not chunk then
        failed = failed + 1
        print(string.format("[语法错误] %s", path))
        print("           " .. tostring(err))
      else
        print(string.format("[通过] %s", path))
      end
    end
  end
end

print("")
if failed == 0 then
  print(string.format("语法检查通过：%d 个文件。", total))
  os.exit(0)
else
  print(string.format("语法检查失败：%d / %d 个文件有错误。", failed, total))
  os.exit(1)
end

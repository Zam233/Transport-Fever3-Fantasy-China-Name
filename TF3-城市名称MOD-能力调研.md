# Transport Fever 3 MOD 开发能力调研 —— 自定义「城市名称集」支持情况

> 结论先行：**支持。** TF3 把命名系统整体重构成了独立的 `.names.lua` **资源类型**（type `names`），
> 城市名、街道名、人名都可以由 MOD 自带脚本动态生成，并作为「名称集（name set）」出现在游戏设置里供玩家选择。
> 注意：**不能用 TF1/TF2 的 `res/config/name2/<region>/<lang>/towns.lua` 静态写法移植**，TF3 是另一套机制。

---

## 一、TF3 的官方资料源

| 页面 | 地址 |
|---|---|
| MOD 手册入口 | https://wiki.transportfever3.com/doku.php?id=modding:start |
| **Names（命名系统）** | https://wiki.transportfever3.com/doku.php?id=modding:misc:names |
| Resource Types & Structure | https://wiki.transportfever3.com/doku.php?id=modding:general:resourcetypes |
| Mod Definition（目录结构） | https://wiki.transportfever3.com/doku.php?id=modding:general:moddefinition |
| Mod Parameters & Scripts | https://wiki.transportfever3.com/doku.php?id=modding:general:modscripts |

---

## 二、TF3 命名系统的核心机制

### 2.1 名称集由 `.names.lua` 定义

wiki 原文给的骨架（type `names`）：

```lua
function data()
  return {
    name = _("English"),

    personNamesScript = {
      fileName = "/names/names.script@personNameScriptFn",
      params   = { ... },
    },
    townNamesScript = {
      fileName = "/names/names.script@townsNameScriptFn",
      params   = { ... },
    },
    streetNamesScript = {
      fileName = "/names/names.script@streetsNameScriptFn",
      params   = { ... },
    },
  }
end
```

- `name` —— **在游戏设置里显示的名称集名字**，玩家靠它选择用哪套城市名。
- 三块脚本引用分别对应 **人名 / 城市名 / 街道（站名）名**。
- `fileName` 采用统一格式 `资源引用@函数名`，指向该脚本 `data()` 返回表里的一个函数键。

### 2.2 城市名生成函数的签名（重点）

`townNamesScriptFn` 收到的参数：

| 参数 | 内容 |
|---|---|
| `captureParams` | `.names.lua` 里该引用旁边写的 `params = {...}`（即**本 MOD 自己的参数**） |
| `params.lang` | 当前游戏语言短码，如 `en` |
| `params.num`  | **需要返回的城市名个数**；若为 `-1` 表示「返回全部」 |

返回值：**长度为 `num` 的字符串列表**，例如 `"Adelaide"`。

> wiki 明确提示：**要保证返回结果不重复**，因此名称池要足够大，
> 否则同一张地图上会出现多个同名城市。

街道名函数（`streetNameScriptFn`）签名与城市名**完全一致**（`lang` / `num` / `-1` 语义相同），只是返回街道名。
人名函数（`personNameScriptFn`）略有不同：额外收一个 `isMale` 布尔值来决定返回男名还是女名，
基游戏提供 `content/names/personnameutil.lua`，内含若干**名字片段列表**，可引用拼接成完整人名。

### 2.3 两种「城市名」语义要分清

1. **城市名池**（town names）—— 地图生成时城市随机取名，即上面的 `townNamesScript`。
2. **站点/街道名**（street names）—— 车站默认名、道路名，走 `streetNamesScript`。
   想「中文地名」通常两套都要做，否则城市叫中文、车站还叫 `Main Street`。

---

## 三、MOD 里的文件放在哪

TF3 官方 MOD 目录结构（来自 Mod Definition）：

```
mods/
  <author>_<modname>/          # 目录名无功能意义；建议与 modId 一致
    _metadata/
      modinfo.json             # MOD 展示名/描述/标签
      description.html         # 可选
      0.png                    # 可选
    content/                   # 所有游戏资源都放这里，建议模仿基游戏结构
    mod.script.tl              # 可选，mod.json 引用的可执行脚本
    mod.json                   # 技术定义（含 id）
    strings.json               # 可选，多语言文案
```

关键规则（**容易踩坑**）：

- **TF3 的资源不按文件夹区分，而是按文件后缀区分**（wiki 原文：
  "the game resources are not distinguished by their folder, but by their individual file endings"）。
  所以真正起作用的是 `.names.lua` 这个后缀；放在 `content/names/` 只是**与基游戏保持一致的最佳实践**。
- 路径引用支持三种：
  - `"/assets/.../file.mdl"` —— 当前 MOD
  - `"::/tex/logo.dds"` —— 基游戏内容
  - `"mod_id::/tex/logo.dds"` —— 指定 MOD
  - **不允许 `../` 回退父目录**。
- 所有文本文件须 **UTF-8 无 BOM**。
- 目录名只能用 `A-Z a-z 0-9 _ .`。
- 与 TF1/TF2 不同，**modId 后面不再带 `_3` 这类大版本号**。

---

## 四、能不能做「中文城市名集」——结论与要点

**能，而且这正是官方预留的扩展点。** 需要注意的实操点：

1. **命名集是「可选列表」而非「覆盖」**。玩家在设置里选择名称集，
   MOD 提供的名称集与基游戏名称集并列出现，靠 `name = _("...")` 区分。
   想让它成为默认还要玩家手动选。
2. **中文标签要用 localizations**。`name` 里包的 `_()` 是翻译函数，
   中文显示名应通过 `strings.json`（本地化）提供，而不是硬写中文。
3. **单文件即可跑通**，无需修改基游戏文件，也不依赖外部注入。
4. **要自己实现 `num` 的截取逻辑**。因为游戏会问「要 num 个名字」，
   标准做法是内部持有一个大池子，然后用 `num == -1` 判断返回全部、否则无重复随机/顺序取 `num` 个。
5. **量与去重**：wiki 只给了「建议足够多」的定性要求，没有硬下限数值；
   参考基游戏套路的规模（TF1 英文城镇名表约 900 条量级）比较稳妥。
6. **可选：用 mod 参数让玩家自选**。`mod.json` 的 `params` 支持
   `Button / Slider / ComboBox / IconButton / CheckBox` 五种 uiType，
   配合 `.names.lua` 的 `captureParams` 可以做「北方风格/南方风格/自定义导入」之类的开关。
   另有 `preRunFn / runFn / postRunFn` 三个脚本钩子，其参数是
   `configDict`（含所选气候、经济与**名称列表**）和 `allModParams`。

---

## 五、可直接改造的中文名称集模板（骨架）

> 下列代码按 wiki 记录的 schema 编写，**未经游戏实测**，函数名/文件夹请按自己 MOD 的实际路径对齐。

`content/names/ug_chinese_towns.names.lua`

```lua
function data()
  return {
    name = _("Chinese Towns"),

    -- 城市名
    townNamesScript = {
      fileName = "ug_chinese_names::/names/chinese.script@townNames",
      params = { style = 1 },
    },

    -- 街道 / 车站名
    streetNamesScript = {
      fileName = "ug_chinese_names::/names/chinese.script@streetNames",
      params = { style = 1 },
    },
  }
end
```

`content/names/chinese.script`（同目录，后缀按实际资源类型）

```lua
local TOWNS = {
  -- 把中文城市名池放这里
  "北京", "上海", "广州", "深圳", "天津", "重庆", "成都", "杭州",
  "南京", "武汉", "西安", "苏州", "长沙", "郑州", "青岛", "沈阳",
  -- ... 建议数百条以上
}

local STREETS = {
  "中山路", "人民路", "解放路", "建设路", "和平路", "新华路",
  -- ...
}

-- 无重复取 n 个
local function pick(pool, n)
  if n == nil or n < 0 or n > #pool then n = #pool end
  local copy = {}
  for i = 1, #pool do copy[i] = pool[i] end
  local out = {}
  for i = 1, n do
    local k = math.random(1, #copy)
    out[i] = copy[k]
    table.remove(copy, k)
  end
  return out
end

function data()
  return {
    townNames = function(captureParams, params)
      return pick(TOWNS, params.num)
    end,

    streetNames = function(captureParams, params)
      return pick(STREETS, params.num)
    end,
  }
end
```

---

## 六、一句话总结

TF3 **官方支持**自定义城市名称集：新建一个 `.names.lua` 资源文件，
用 `townNamesScript`（城市名）＋ `streetNamesScript`（街道/站名）指向自己的生成函数，
函数按 `params.num` 返回 `num` 条**不重复**的名称即可；
名称集会自动进入游戏设置的名称列表供选择。**不要照搬 TF2 的 `res/config/name2/.../towns.lua` 静态数组写法。**

# tools/ — 开发与自检工具

这些工具让你**不启动游戏**就能验证 MOD 的大部分行为。它们不随 MOD 发布，
只用于开发。

## 校验类

| 工具 | 作用 |
|---|---|
| `syntax_check.lua` | 语法检查。用 Lua 编译器「只编译不执行」地校验所有 `.lua` / `.names.lua` / `.script.lua`。游戏只在加载时才会报语法错误，届时表现为 MOD 直接不可用。 |
| `lint51.ps1` | **Lua 5.1 兼容性检查**。TF3 运行时疑为 Lua 5.1 / LuaJIT，而 Lua 5.3 引入的位运算符（`~ & \| << >>`）在 5.1 下是**语法错误**，会让 MOD 直接加载失败。本机只有 texlua（5.3），查不出这类问题，故用此脚本扫描。纯 ASCII（PowerShell 5.1 会把无 BOM 的 UTF-8 按 GBK 解码而破坏脚本）。 |
| `verify_engine.lua` | **最重要的一个**。严格按引擎方式加载：`load` 文件 → **调 `data()`** → 取函数表 → 调用三大人名/城镇/道路函数。断言包括：入口导出 `data()`、5 个名称集可加载、返回类型正确、`num < 0` 返回全量、**重复调用产出不同人名**、道路名不含真实省市名、道路名不以聚落通名结尾。 |
| `check_street_type.lua` | 道路名 / 聚落名判定。聚落后缀通过**命令行参数**传入（UTF-8），以免源文件含 CJK 而被 PowerShell 破坏。 |
| `check_person_variety.lua` | 人名多样性：连续多次调用是否产出不同名字。专防「所有人同名」这类回归。 |

## 测试类

| 工具 | 作用 |
|---|---|
| `test_namegen.lua` | 城镇名生成器单元测试：UTF-8 长度、RNG 分布、采样去重、构词约束、`num` 契约、可复现性、词汇纯净度（物产词 / 信仰词）。 |
| `test_streetgen.lua` | 道路名生成器测试：结构铁律、合规基线、`num` 契约、综合风格、地域风味。 |

## 导出类

| 工具 | 作用 |
|---|---|
| `export_names.lua` | 导出城镇名清单（Markdown + 纯名单），含字数/通名分布与合规统计。 |
| `export_streets.lua` | 导出道路名清单（九地域 + 综合）。 |
| `sample_output.lua` | 快速抽样查看各类产出效果。 |

## 用法

```powershell
# 语法
texlua tools/syntax_check.lua cn_names

# Lua 5.1 兼容性
pwsh -File tools/lint51.ps1 -Path cn_names

# 引擎加载路径验证（改完代码必跑）
texlua tools/verify_engine.lua

# 单元测试
texlua tools/test_namegen.lua
texlua tools/test_streetgen.lua
```

## 两个踩坑记录（写在这里以免重犯）

1. **`verify_engine.lua` 最初只测「调用不报错 + 返回类型」**，没测「重复调用是否产出不同名字」。
   结果「每次调用都重新播种」这个 bug 一路溜到游戏里，表现为所有居民同名。
   现在已补上多样性断言。

2. **`syntax_check.lua` 与 `lint51.ps1` 只能查出「语法」层面的问题**。
   真正致命的那次是「入口没把返回表包进 `data()`」—— 语法完全正确，
   只有按引擎方式调用才暴露。所以 `verify_engine.lua` 是必须的。

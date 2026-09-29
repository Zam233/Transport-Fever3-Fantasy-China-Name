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
-- ============================================================================
-- 自动导出：来源 build/街道命名规格.md（813 行，UTF-8 无 BOM）
-- 用途：供「中国街道名」MOD 的 Lua 生成器读取。纯 Lua 5.1+ 兼容，return 一张表。
-- 对接契约（父 agent）：
--   1) 模板 templates 用 seq 数组，最后一个插槽为通名（"suffix" 或 "=字面量通名"）。
--   2) seq 仅可引用池：political/direction/landscape/transplant/industry/auspicious/
--      surname/memorial/hydraulic/historic/number + literal(=X)。
--   3) 规格书给了数字照抄；没给的写 nil 并标 --[[W?]]/--[[F?]]/--[[Q?]]。
--   4) 通名按 arterial/secondary/local/district 分级，带地域归属；阈值主表见 M.thresholds。
--   5) 校验数据齐全（forbidden/badHomophones/realNameBlocklist/commonWhitelist）；
--      memorial 真实人名与虚构人名分开（fictional 字段）。
--   6) M.regions 9 个 region，含 label/suffixWeights/themeWeights/templates。
--
-- 统计（与规格书 §8 附「交付统计汇总」对齐）：
--   通名总数 148 = 通用层 38（骨干 9 + 次干 12 + 片区 17）+ 地域专属去重 110（8 区）
--   专名部件 ≈494 = 核心 335（政治 32 + 方位 11 + 序数 8 + 山水 42[实列 43] + 省 28 + 市 30
--                    + 行业 23 + 吉祥 30 + 姓氏 99 + 纪念 11 + 水文 9 + 历史 12）
--                    + 扩展 159（山 16 + 水/花木/瑞兽 34 + 科教 17 + 地貌 40
--                    + 吉祥双字 7 + 外文音译 15 + 颜色 8 + 驿铺/军屯 22）
--   地域分型 9（§4：north/wu/lingnan/southwest/central/min/northwest/tibet/mongol；
--             §2.4 按「藏蒙」合并口径为 8 区）
--   冲突 6 + 待裁定 2
-- ============================================================================

local M = {}

-- ============================================================================
-- §1.3 通名与物理规模的匹配 —— MOD 统一口径（§8 冲突 2 仲裁值），作主表
-- 国家层面不规定量化数字；下表取各市交集主流值。宽度「16–60 m」记为 min/max。
-- ============================================================================
M.thresholds = {
  -- 名字 | 最小红线宽m | 最大红线宽m | 最小长度m | 最大长度m | 等级 | 道路等级(原文)
  { w = "大道", minWidth = 60, minLength = 4000, level = "arterial",  grade = "快速路/主干路" },
  { w = "大街", minWidth = 50, minLength = 4000, level = "arterial",  grade = "主干路（商业繁华）" },
  { w = "路",   minWidth = 16, maxWidth = 60, minLength = 500, level = "secondary", grade = "主干/次干" },
  { w = "街",   minWidth = 16, maxWidth = 60, minLength = 500, level = "secondary", grade = "次干（商业凸显）" },
  { w = "巷",   maxWidth = 16, maxLength = 500, level = "local",     grade = "支路/居住区" },
  { w = "弄",   maxWidth = 16, maxLength = 500, level = "local",     grade = "支路（沪/江南）" },
  { w = "里",   maxWidth = 16, maxLength = 500, level = "local",     grade = "支路（南方）" },
  { w = "胡同", maxWidth = 16, maxLength = 500, level = "local",     grade = "支路（北京四合院风貌）" }
}

-- 西安严格口径（西安市政发〔2019〕22 号），作为可选开关，见 §8 冲突 2
M.strictMode = {
  { w = "大道", minWidth = 80, minLength = 8000 }
}

-- ============================================================================
-- §1.2 硬性禁止清单（A 表，13 条，逐条「规则—判定—例证」）
-- ============================================================================
M.forbidden = {
  { id = "FOREIGN_NAME",       ref = "A1",  desc = "专名不含任何外国地名/外国人名/外语词及汉字音译词", basis = "《条例》9(五)；上海、西安细则", example = "「曼哈顿」「巴黎」「史密斯」「加州阳光」✗" },
  { id = "LEADER_NAME",        ref = "A2",  desc = "专名不含国家领导人姓名", basis = "《条例》9(四)；西安导则 5(四)", example = "领导人姓名 ✗" },
  { id = "REAL_PERSON_NAME",   ref = "A3",  desc = "专名不含在世/已故真实人名的全名/别名/化名（白名单纪念地名除外）", basis = "《条例》9(四)；《实施办法》3 条", example = "未经审批的真实人名 ✗；「中山」走白名单 ✓" },
  { id = "ENTERPRISE_NAME",    ref = "A4",  desc = "专名不含企业名/品牌名/商标名", basis = "《条例》9(六)；北京「五不原则」", example = "「华为路」「万科大道」✗" },
  { id = "PAID_NAMING",        ref = "A5",  desc = "不含有偿冠名痕迹", basis = "西安导则 5(七)「不得有偿命名、更名和冠名」", example = "以金主命名 ✗" },
  { id = "VULGAR_FEUDAL",      ref = "A6",  desc = "不含有损国家尊严、民族团结、公序良俗、侮辱、低俗、迷信、封建帝王/官衔词", basis = "《条例》9(一)、4 条；上海、西安细则", example = "「帝王花园」「御林」「天下一号」✗（属「大、洋、怪、重」之「怪」）" },
  { id = "RARE_CHAR",          ref = "A7",  desc = "不含生僻字（《通用规范汉字表》二级/三级字即告警）、繁体、异体、自造字、废弃简化字", basis = "《条例》9(三)；上海、西安细则", example = "繁体/异体/生僻 ✗" },
  { id = "FOREIGN_LETTER",     ref = "A8",  desc = "不含外文字母/英文单词；通名一律汉字", basis = "国通语法、《条例》15 条", example = "「XX Road/Ave/St」✗" },
  { id = "PURE_NUMBER",        ref = "A9",  desc = "不含纯数字序号（「3 号路」「18 街」）；纪念数字地名仅限白名单", basis = "西安导则 5(十)（「城市环路除外」）", example = "「五一」「八一」「一二九」= 纪念白名单 ✓；「18 号街」✗" },
  { id = "DUPLICATE_NAME",     ref = "A10", desc = "同一地图（=同一「建成区」）内道路专名不重名", basis = "《条例》9(八)", example = "两路同名 ✗" },
  { id = "HOMOPHONE_NAME",     ref = "A11", desc = "同一地图内道路专名不同音（普通话拼音比较，忽略声调）", basis = "《条例》9(八)；西安导则", example = "「和平路」vs「河坪路」✗" },
  { id = "SUFFIX_OVERLAP",     ref = "A12", desc = "通名不得重叠", basis = "通名反映类别属性之规则", example = "「××大街路」「××路街」「××巷弄」✗" },
  { id = "SUFFIX_AS_SPECIFIC", ref = "A13", desc = "不得以通名单独作专名（地名≠纯「路/街」）", basis = "已废止《细则》14 条", example = "纯「路」「街」作地名 ✗" }
}

-- §1.2 结构必过项（B 表，4 条）
M.structureRules = {
  { id = "B1", desc = "地名 = 专名 + 通名 两段（专名内可含方位词）", basis = "《条例》9 条" },
  { id = "B2", desc = "通名必须来自合法通名集（见第 2 节；按地图城市南北风格选）", basis = "各市细则" },
  { id = "B3", desc = "方位词位置：分段 →「专名+东/西/南/北/中+通名」；平行相邻同专名 →「东/西+专名+通名」", basis = "西安导则 6(四)(五)" },
  { id = "B4", desc = "总长建议 2–6 汉字（专名 1–4 字 + 通名 1 字；轨交站类一般 ≤6 字）", basis = "成都（轨交站 ≤6 字）" }
}

-- ============================================================================
-- §1.4 字数分布（来源 05 号 §3.1；07 号 §2.3 实测估算〔估算〕）
-- ============================================================================
M.lengthDistribution = {
  { chars = 3, compose = "专名 2 字 + 通名 1 字",               shareMin = 0.45, shareMax = 0.55, example = "人民路、中山路、建设路、汉正街", estimated = true },
  { chars = 4, compose = "专名 2 字+方位 / 专名 3 字 / 专名 2 字+大道", shareMin = 0.30, shareMax = 0.35, example = "中山北路、淮海中路、建设大道", estimated = true },
  { chars = 5, compose = "专名 3 字+大道 / 专名 2 字+方位+大道", shareMin = 0.10, shareMax = 0.15, example = "世纪大道、滨海大道、环市东路", estimated = true },
  { chars = 2, compose = "专名 1 字 + 通名 1 字",               shareMin = 0.05, shareMax = 0.05, example = "大马路、横街、小巷", estimated = true },
  { chars = 6, compose = "多段叠加/历史长名",                   shareMin = nil, shareMax = nil, example = "亚美打利庇卢大马路（澳门）", estimated = true, note = "少量" }
}

-- §1.4 构词规则（生成规则 R4）+ 音韵禁忌
M.constraints = {
  formation = {
    golden = "专名 1–3 字 + 通名 1–2 字，总长 3–5 字为黄金区间；专名越长、通名越短（3 字专名只配 1 字通名）",
    illegal = {
      "① 通名连用",
      "② 专名 >3 字",
      "③ 跨层错配（「马家大道」「桂花大街」「解放胡同」）",
      "④ 构造通名当末端（「××高架」应作「××大道高架」后缀）",
      "⑤ 方位词单独重复（「东东西西」「南南街」）"
    }
  },
  phonetics = {
    avoid = { "三连仄/三连平", "同声母三连（「江家街」jiāng jiā jiē）", "连续同音/近音字（「洪鸿」「经京」）", "声调全平或全仄的四字名（「华阳春晖」）" },
    rule  = "生成后做拼音连读 + 声母/声调统计，任一「三连同声母」或「四连同调」即弃或换部件"
  }
}

-- ============================================================================
-- §1.5 谐音与不雅组合黑名单（危险音节/词表）
-- ============================================================================
M.badHomophones = { "逼", "死", "尸", "癌", "瘟", "穷", "丧", "高潮", "爱上", "王八" }

-- ============================================================================
-- §2 通名体系 —— 四级分级（§2.1 骨干 / §2.2 次干 / §2.3 片区；§1.3 阈值）。
-- 通用层 38 通名；其中「干线/快速路」「环路/环/外环/内环」「高架/立交/桥」为功能/构造通名，
-- 按 §2.1 规则 R2 不作末端通名，单独列于 functional（forms 列出全部形态）。
-- 各通名项 minWidth/minLength/maxWidth/maxLength 仅在 §1.3 给出时填写，未给为 nil。
-- ============================================================================
M.suffixes = {
  arterial = {
    { w = "大道", minWidth = 60, minLength = 4000 },
    { w = "大街", minWidth = 50, minLength = 4000 }
  },
  secondary = {
    { w = "路",   minWidth = 16, maxWidth = 60, minLength = 500 },
    { w = "街",   minWidth = 16, maxWidth = 60, minLength = 500 },
    { w = "道" },
    { w = "马路" }
  },
  ["local"] = {
    { w = "巷",   maxWidth = 16, maxLength = 500 },
    { w = "弄",   maxWidth = 16, maxLength = 500 },
    { w = "里",   maxWidth = 16, maxLength = 500 },
    { w = "坊" },
    { w = "胡同", maxWidth = 16, maxLength = 500 },
    { w = "条" },
    { w = "径" },
    { w = "小街" },
    { w = "横街" },
    { w = "斜街" },
    { w = "夹道" },
    { w = "支路" }
  },
  district = { -- 片区层（「写字楼群、商贸城」为描述性举例，不单列）
    { w = "园" }, { w = "苑" }, { w = "城" }, { w = "府" },
    { w = "邸" }, { w = "阁" }, { w = "轩" }, { w = "榭" },
    { w = "庭" }, { w = "居" }, { w = "里弄" }, { w = "新村" },
    { w = "花园" }, { w = "小区" }, { w = "广场" }, { w = "中心" },
    { w = "大厦" }
  },
  functional = { -- §2.1 功能/构造通名（R2：不作末端通名，作后缀附加）
    { w = "干线", forms = { "干线", "快速路" } },
    { w = "环路", forms = { "环路", "环", "外环", "内环" } },
    { w = "高架", forms = { "高架", "立交", "桥" } }
  }
}

-- §6.1 通名槽位 T 表（按等级分槽，避免跨层错配）—— 05 号 §5.1
M.levelSlots = {
  arterial  = { "大道", "大街", "路", "街" },
  collector = { "路", "街", "道", "马路" },
  lane      = { "巷", "弄", "里", "坊", "胡同", "条", "径", "小街", "横街", "斜街", "夹道", "支路" },
  block     = { "园", "苑", "城", "府", "邸", "阁", "轩", "榭", "庭", "居", "新村", "花园", "小区", "广场", "中心", "大厦" }
}

-- ============================================================================
-- §2.4 地域专属通名表 —— 通名地域标记分级（08 号 §9.1）
--   全国通用（低信息量，默认兜底）；次级标记；强地域标记（跨区混用明显失真）
--   8 区（藏蒙合并口径）去重后共 110 个（不含通用层已计 38 个）
--   region 键与 §4 一致（north/wu/lingnan/southwest/central/min/northwest/tibet/mongol）
-- ============================================================================
M.genericMarkers   = { "路", "街", "巷", "大道", "大街" }  -- 全国通用（默认兜底）
M.secondaryMarkers = { "里", "坊", "庄", "屯", "营", "堡", "寨", "湾", "嘴", "沟", "墩", "洲" }  -- 次级标记

-- 跨区混用防控（08 号 §9.5）
M.crossRegionRules = {
  "强地域标记不跨区（华北种子不出「X涌/X滘/X厝/X塬」，岭南种子不出「X胡同/X沱/X冲」）",
  "华中省内细分「冲→湖南、垸/畈→湖北、垱/塅→江西」",
  "「段」仅限台湾都市且序数上限 1–7",
  "「堡/铺」多音按语义分桶（bǔ/pù 北方、bǎo 西北）"
}

M.regionSuffixes = {
  north = { -- 北方（华北/东北）
    { w = "胡同", strong = true }, { w = "条", strong = true },
    { w = "巷" }, { w = "里" }, { w = "大院" }, { w = "庄" }, { w = "屯" },
    { w = "堡" }, { w = "堡子" }, { w = "营" }, { w = "官" }, { w = "甸" },
    { w = "峪" }, { w = "旗" }, { w = "沟" }, { w = "店" }, { w = "铺" }
  },
  wu = { -- 江南（江浙沪吴语）
    { w = "弄", strong = true }, { w = "浜", strong = true },
    { w = "泾", strong = true }, { w = "汇", strong = true },
    { w = "里" }, { w = "坊" }, { w = "浦" }, { w = "塘" }, { w = "堰" },
    { w = "桥" }, { w = "荡" }, { w = "漾" }, { w = "湾" }, { w = "角" },
    { w = "埭" }, { w = "圩" }, { w = "宅" }, { w = "库", suspicious = true },
    { w = "家" }, { w = "嘴" }
  },
  lingnan = { -- 岭南（粤桂闽港澳）
    { w = "涌", strong = true }, { w = "滘", strong = true },
    { w = "围", strong = true }, { w = "塱", strong = true },
    { w = "约", strong = true },
    { w = "街" }, { w = "巷" }, { w = "里" }, { w = "坊" }, { w = "基" },
    { w = "寮" }, { w = "埔" }, { w = "坑" }, { w = "沙" }, { w = "洲" },
    { w = "墩" }, { w = "岗" }, { w = "冈" }, { w = "篱", suspicious = true },
    { w = "村" }, { w = "墟" }, { w = "圩" }, { w = "道" }, { w = "马路" },
    { w = "台" }, { w = "径" }, { w = "前地" }
  },
  southwest = { -- 西南（川渝云贵）
    { w = "沱", strong = true }, { w = "垭", strong = true },
    { w = "街" }, { w = "巷" }, { w = "坝" }, { w = "场" }, { w = "坎" },
    { w = "坡" }, { w = "沟" }, { w = "湾" }, { w = "嘴" }, { w = "驿" },
    { w = "铺" }, { w = "码头" }, { w = "埠" }, { w = "驿道" }, { w = "门" },
    { w = "巷子" }, { w = "梯" }, { w = "滩" }
  },
  central = { -- 华中（鄂湘赣皖）
    { w = "冲", strong = true }, { w = "垸", strong = true },
    { w = "畈", strong = true }, { w = "垱", strong = true },
    { w = "塅", strong = true },
    { w = "街" }, { w = "巷" }, { w = "里" }, { w = "湾" }, { w = "塘" },
    { w = "铺" }, { w = "埠" }, { w = "洲" }, { w = "矶" }, { w = "嘴" },
    { w = "垄" }, { w = "塝" }, { w = "墩" }
  },
  min = { -- 闽台（福建、台湾）
    { w = "厝", strong = true }, { w = "埕", strong = true },
    { w = "寮", strong = true }, { w = "段", strong = true },
    { w = "街" }, { w = "巷" }, { w = "澳" }, { w = "屿" }, { w = "坑" },
    { w = "埔" }, { w = "岑", suspicious = true }, { w = "尾" }, { w = "头" },
    { w = "崎" }, { w = "份" }, { w = "部" }, { w = "庄" }, { w = "社" },
    { w = "埤" }
  },
  northwest = { -- 西北（陕甘宁青新）
    { w = "塬", strong = true }, { w = "梁", strong = true },
    { w = "峁", strong = true }, { w = "巴扎", strong = true },
    { w = "渠", strong = true }, { w = "坎", strong = true },
    { w = "街" }, { w = "巷" }, { w = "堡" }, { w = "寨" }, { w = "营" },
    { w = "屯" }, { w = "驿" }, { w = "台" }, { w = "墩" }, { w = "泉" },
    { w = "井" }, { w = "湾" }, { w = "庄子" }, { w = "城子" }, { w = "峪" },
    { w = "关" }, { w = "滩" }
  },
  tibet = { -- 藏区
    { w = "曲", strong = true }, { w = "错", strong = true },
    { w = "宗", strong = true }, { w = "卡", strong = true },
    { w = "林卡", strong = true }, { w = "廓", strong = true },
    { w = "转经道" }, { w = "塘" }, { w = "扎", suspicious = true },
    { w = "寺" }, { w = "拉" }
  },
  mongol = { -- 内蒙古
    { w = "浩特", strong = true }, { w = "郭勒", strong = true },
    { w = "淖尔", strong = true }, { w = "嘎查", strong = true },
    { w = "苏木", strong = true },
    { w = "艾里" }, { w = "旗" }, { w = "盟" }, { w = "塔拉" }
  }
}

-- ============================================================================
-- §3.1 专名部件 —— 核心池（每项 {w, freq}；freq 取 §3.2 主题档位 极高/高/中/低）
-- 主题档位（§3.2）：政治 极高 / 地名移植 极高 / 山水 极高 / 吉祥 高 / 姓氏 高 /
--   行业 中 / 历史遗迹 中 / 纪念 低 / 水文 低；
--   方位字与序数（direction/number）未出现在 §3.2 权重表中 → freq=nil --[[F?]]
-- ============================================================================
M.parts = {
  -- ① 政治教化类（32 部件；全国最高频、县城标配）
  political = {
    { w = "人民", freq = "极高" }, { w = "解放", freq = "极高" }, { w = "中山", freq = "极高" }, { w = "建国", freq = "极高" },
    { w = "和平", freq = "极高" }, { w = "新华", freq = "极高" }, { w = "光明", freq = "极高" }, { w = "团结", freq = "极高" },
    { w = "胜利", freq = "极高" }, { w = "前进", freq = "极高" }, { w = "友谊", freq = "极高" }, { w = "民主", freq = "极高" },
    { w = "自由", freq = "极高" }, { w = "红旗", freq = "极高" }, { w = "八一", freq = "极高" }, { w = "工农", freq = "极高" },
    { w = "革命", freq = "极高" }, { w = "振兴", freq = "极高" }, { w = "复兴", freq = "极高" }, { w = "建设", freq = "极高" },
    { w = "发展", freq = "极高" }, { w = "文明", freq = "极高" }, { w = "和谐", freq = "极高" }, { w = "富强", freq = "极高" },
    { w = "文化", freq = "极高" }, { w = "红星", freq = "极高" }, { w = "朝阳", freq = "极高" }, { w = "东风", freq = "极高" },
    { w = "青年", freq = "极高" }, { w = "劳动", freq = "极高" }, { w = "友好", freq = "极高" }, { w = "爱国", freq = "极高" }
  },
  -- ② 方位字（11 部件；常作前缀；§3.2 未给档位 → freq=nil）
  direction = {
    { w = "东", freq = nil }, --[[F?]] { w = "西", freq = nil }, --[[F?]] { w = "南", freq = nil }, --[[F?]]
    { w = "北", freq = nil }, --[[F?]] { w = "中", freq = nil }, --[[F?]] { w = "上", freq = nil }, --[[F?]]
    { w = "下", freq = nil }, --[[F?]] { w = "前", freq = nil }, --[[F?]] { w = "后", freq = nil }, --[[F?]]
    { w = "内", freq = nil }, --[[F?]] { w = "外", freq = nil } --[[F?]]
  },
  -- 序数（8 部件；05 号 P.ordinal，跳过「四」；§3.2 未给档位 → freq=nil）
  number = {
    { w = "一", freq = nil }, --[[F?]] { w = "二", freq = nil }, --[[F?]] { w = "三", freq = nil }, --[[F?]]
    { w = "五", freq = nil }, --[[F?]] { w = "六", freq = nil }, --[[F?]] { w = "七", freq = nil }, --[[F?]]
    { w = "八", freq = nil }, --[[F?]] { w = "九", freq = nil } --[[F?]]
  },
  -- ③ 山水自然类（规格书标 42 部件；实际列出 43 个词，见文末差异说明）
  landscape = {
    { w = "山", freq = "极高" }, { w = "岭", freq = "极高" }, { w = "峰", freq = "极高" }, { w = "岩", freq = "极高" },
    { w = "坡", freq = "极高" }, { w = "岗", freq = "极高" }, { w = "丘", freq = "极高" }, { w = "江", freq = "极高" },
    { w = "河", freq = "极高" }, { w = "湖", freq = "极高" }, { w = "海", freq = "极高" }, { w = "溪", freq = "极高" },
    { w = "泉", freq = "极高" }, { w = "潭", freq = "极高" }, { w = "塘", freq = "极高" }, { w = "湾", freq = "极高" },
    { w = "浦", freq = "极高" }, { w = "洲", freq = "极高" }, { w = "岛", freq = "极高" }, { w = "沙", freq = "极高" },
    { w = "港", freq = "极高" }, { w = "滨", freq = "极高" }, { w = "林", freq = "极高" }, { w = "树", freq = "极高" },
    { w = "花", freq = "极高" }, { w = "草", freq = "极高" }, { w = "竹", freq = "极高" }, { w = "松", freq = "极高" },
    { w = "柏", freq = "极高" }, { w = "柳", freq = "极高" }, { w = "梅", freq = "极高" }, { w = "兰", freq = "极高" },
    { w = "菊", freq = "极高" }, { w = "荷", freq = "极高" }, { w = "桂", freq = "极高" }, { w = "榕", freq = "极高" },
    { w = "槐", freq = "极高" }, { w = "榆", freq = "极高" }, { w = "桃", freq = "极高" }, { w = "李", freq = "极高" },
    { w = "杏", freq = "极高" }, { w = "枫", freq = "极高" }, { w = "杉", freq = "极高" }
  },
  -- ④ 地名移植类
  -- ⚠ 重要（规格书 §8 冲突6 的仲裁结果）：**改用虚构地名**，不用真实省市名。
  --   原因：真实"南京路/北京路"属著名城市名片，会与现实撞名；
  --   而上海/青岛式"地名移植"的风味（省名=南北向、城市名=东西向、
  --   按原籍方位落位）只需保留**结构规则**，地名来源换成虚构名即可。
  --   下列 53 个虚构名由 MOD1《中国城市名称集》汉地池生成并人工筛选，
  --   已核对不与中国任何县级以上政区重名。
  transplant = {
    province = {
      { w = "吉康", freq = "极高" }, { w = "绥安", freq = "极高" }, { w = "皖昌", freq = "极高" }, { w = "望川", freq = "极高" },
      { w = "青坪", freq = "极高" }, { w = "赤阳", freq = "极高" }, { w = "燕乡", freq = "极高" }, { w = "绥兴", freq = "极高" },
      { w = "樾山", freq = "极高" }, { w = "翠岭", freq = "极高" }, { w = "玳岑", freq = "极高" }, { w = "淳风", freq = "极高" },
      { w = "巉岫", freq = "极高" }, { w = "锦康", freq = "极高" }, { w = "嵁岫", freq = "极高" }, { w = "峋岫", freq = "极高" },
      { w = "崟岫", freq = "中频" }, { w = "青康", freq = "中频" }, { w = "澂浔", freq = "中频" }, { w = "荇溪", freq = "中频" },
      { w = "芷汀", freq = "中频" }, { w = "洺浔", freq = "中频" }, { w = "雁塘", freq = "中频" }, { w = "芦堰", freq = "中频" }
    },
    city = {
      { w = "段塘", freq = "极高" }, { w = "宋坎", freq = "极高" }, { w = "紫堰", freq = "极高" }, { w = "紫浃", freq = "极高" },
      { w = "桦河", freq = "极高" }, { w = "德坎", freq = "极高" }, { w = "桂岑", freq = "极高" }, { w = "嘉隘", freq = "极高" },
      { w = "杨沟", freq = "极高" }, { w = "嶙岫", freq = "极高" }, { w = "泓汀", freq = "极高" }, { w = "谭渎", freq = "极高" },
      { w = "紫渎", freq = "极高" }, { w = "渚阳", freq = "极高" }, { w = "阎荡", freq = "极高" }, { w = "碧涧", freq = "极高" },
      { w = "于镇", freq = "中频" }, { w = "董墩", freq = "中频" }, { w = "卫埕", freq = "中频" }, { w = "齐阴", freq = "中频" },
      { w = "兰垇", freq = "中频" }, { w = "岭阴", freq = "中频" }, { w = "垭阴", freq = "中频" }, { w = "李营", freq = "中频" },
      { w = "黑浃", freq = "中频" }, { w = "澧浔", freq = "中频" }, { w = "和溪", freq = "中频" }, { w = "澍汀", freq = "中频" },
      { w = "滏浔", freq = "中频" }
    },
    rule = "省名=南北向、城市名=东西向、按原籍方位落位（07 号 §3.1 上海范式）",
    exceptionRate = { min = 0.05, max = 0.08 }  -- 保留 5–8% 例外
  },
  -- ⑤ 行业功能类（23 部件）
  industry = {
    { w = "车站", freq = "中" }, { w = "码头", freq = "中" }, { w = "机场", freq = "中" }, { w = "工业", freq = "中" },
    { w = "纺织", freq = "中" }, { w = "钢铁", freq = "中" }, { w = "化工", freq = "中" }, { w = "科技", freq = "中" },
    { w = "金融", freq = "中" }, { w = "商业", freq = "中" }, { w = "食品", freq = "中" }, { w = "仓储", freq = "中" },
    { w = "物流", freq = "中" }, { w = "医院", freq = "中" }, { w = "学校", freq = "中" }, { w = "文化", freq = "中" },
    { w = "体育", freq = "中" }, { w = "公园", freq = "中" }, { w = "港务", freq = "中" }, { w = "信息", freq = "中" },
    { w = "软件", freq = "中" }, { w = "创业", freq = "中" }, { w = "创新", freq = "中" }
  },
  -- ⑥ 吉祥美好类（30 部件）
  auspicious = {
    { w = "福", freq = "高" }, { w = "禄", freq = "高" }, { w = "寿", freq = "高" }, { w = "喜", freq = "高" },
    { w = "财", freq = "高" }, { w = "安", freq = "高" }, { w = "康", freq = "高" }, { w = "宁", freq = "高" },
    { w = "泰", freq = "高" }, { w = "昌", freq = "高" }, { w = "盛", freq = "高" }, { w = "兴", freq = "高" },
    { w = "隆", freq = "高" }, { w = "和", freq = "高" }, { w = "顺", freq = "高" }, { w = "富", freq = "高" },
    { w = "贵", freq = "高" }, { w = "荣", freq = "高" }, { w = "华", freq = "高" }, { w = "春", freq = "高" },
    { w = "晖", freq = "高" }, { w = "阳", freq = "高" }, { w = "晨", freq = "高" }, { w = "旭", freq = "高" },
    { w = "瑞", freq = "高" }, { w = "祥", freq = "高" }, { w = "吉", freq = "高" }, { w = "庆", freq = "高" },
    { w = "丰", freq = "高" }, { w = "嘉", freq = "高" }
  },
  -- ⑦ 姓氏宗族类（99 部件；百家姓常见单姓，只配次干层）
  surname = {
    { w = "王", freq = "高" }, { w = "李", freq = "高" }, { w = "张", freq = "高" }, { w = "刘", freq = "高" },
    { w = "陈", freq = "高" }, { w = "杨", freq = "高" }, { w = "赵", freq = "高" }, { w = "黄", freq = "高" },
    { w = "周", freq = "高" }, { w = "吴", freq = "高" }, { w = "徐", freq = "高" }, { w = "孙", freq = "高" },
    { w = "马", freq = "高" }, { w = "朱", freq = "高" }, { w = "胡", freq = "高" }, { w = "郭", freq = "高" },
    { w = "何", freq = "高" }, { w = "林", freq = "高" }, { w = "罗", freq = "高" }, { w = "郑", freq = "高" },
    { w = "梁", freq = "高" }, { w = "谢", freq = "高" }, { w = "宋", freq = "高" }, { w = "唐", freq = "高" },
    { w = "许", freq = "高" }, { w = "韩", freq = "高" }, { w = "冯", freq = "高" }, { w = "邓", freq = "高" },
    { w = "曹", freq = "高" }, { w = "彭", freq = "高" }, { w = "曾", freq = "高" }, { w = "肖", freq = "高" },
    { w = "田", freq = "高" }, { w = "董", freq = "高" }, { w = "潘", freq = "高" }, { w = "袁", freq = "高" },
    { w = "蔡", freq = "高" }, { w = "蒋", freq = "高" }, { w = "余", freq = "高" }, { w = "于", freq = "高" },
    { w = "杜", freq = "高" }, { w = "叶", freq = "高" }, { w = "程", freq = "高" }, { w = "魏", freq = "高" },
    { w = "苏", freq = "高" }, { w = "吕", freq = "高" }, { w = "丁", freq = "高" }, { w = "任", freq = "高" },
    { w = "沈", freq = "高" }, { w = "姚", freq = "高" }, { w = "卢", freq = "高" }, { w = "傅", freq = "高" },
    { w = "钟", freq = "高" }, { w = "姜", freq = "高" }, { w = "崔", freq = "高" }, { w = "谭", freq = "高" },
    { w = "陆", freq = "高" }, { w = "范", freq = "高" }, { w = "汪", freq = "高" }, { w = "廖", freq = "高" },
    { w = "石", freq = "高" }, { w = "金", freq = "高" }, { w = "韦", freq = "高" }, { w = "贾", freq = "高" },
    { w = "夏", freq = "高" }, { w = "方", freq = "高" }, { w = "邹", freq = "高" }, { w = "熊", freq = "高" },
    { w = "白", freq = "高" }, { w = "孟", freq = "高" }, { w = "秦", freq = "高" }, { w = "邱", freq = "高" },
    { w = "侯", freq = "高" }, { w = "江", freq = "高" }, { w = "尹", freq = "高" }, { w = "薛", freq = "高" },
    { w = "闫", freq = "高" }, { w = "段", freq = "高" }, { w = "雷", freq = "高" }, { w = "龙", freq = "高" },
    { w = "黎", freq = "高" }, { w = "史", freq = "高" }, { w = "陶", freq = "高" }, { w = "贺", freq = "高" },
    { w = "毛", freq = "高" }, { w = "郝", freq = "高" }, { w = "顾", freq = "高" }, { w = "龚", freq = "高" },
    { w = "邵", freq = "高" }, { w = "万", freq = "高" }, { w = "钱", freq = "高" }, { w = "严", freq = "高" },
    { w = "覃", freq = "高" }, { w = "武", freq = "高" }, { w = "戴", freq = "高" }, { w = "莫", freq = "高" },
    { w = "孔", freq = "高" }, { w = "向", freq = "高" }, { w = "汤", freq = "高" }
  },
  -- ⑧ 人名纪念类（11 部件；白名单历史纪念地名 → fictional=false；新造用虚构姓名，见 §8 冲突 4）
  memorial = {
    { w = "中山", freq = "低", fictional = false }, { w = "鲁迅", freq = "低", fictional = false },
    { w = "尚志", freq = "低", fictional = false }, { w = "兆麟", freq = "低", fictional = false },
    { w = "一曼", freq = "低", fictional = false }, { w = "靖宇", freq = "低", fictional = false },
    { w = "张之洞", freq = "低", fictional = false }, { w = "黄兴", freq = "低", fictional = false },
    { w = "蔡锷", freq = "低", fictional = false }, { w = "邹容", freq = "低", fictional = false },
    { w = "彭刘杨", freq = "低", fictional = false }
  },
  -- ⑨ 水文工程类（9 部件；多附加在路名后或作专名）
  hydraulic = {
    { w = "堤", freq = "低" }, { w = "坝", freq = "低" }, { w = "闸", freq = "低" },
    { w = "桥", freq = "低" }, { w = "渡", freq = "低" }, { w = "码头", freq = "低" },
    { w = "港口", freq = "低" }, { w = "运河", freq = "低" }, { w = "渠", freq = "低" }
  },
  -- ⑩ 历史遗迹类（12 部件）
  historic = {
    { w = "古城", freq = "中" }, { w = "老城", freq = "中" }, { w = "城墙", freq = "中" },
    { w = "东门", freq = "中" }, { w = "西门", freq = "中" }, { w = "南门", freq = "中" },
    { w = "北门", freq = "中" }, { w = "钟楼", freq = "中" }, { w = "鼓楼", freq = "中" },
    { w = "牌坊", freq = "中" }, { w = "文庙", freq = "中" }, { w = "城隍", freq = "中" }
  }
}

-- §3.2 档位 → 数值映射：规格书只给定性档位（极高/高/中/低），未给具体数值。
-- 以下四键值写 nil 并标 --[[Q?]]，由生成器作者自行定义（Lua 中 nil 值不落表）。
M.freqWeight = {
  ["极高"] = nil, --[[Q? 规格书未给数值]]
  ["高"]   = nil, --[[Q?]]
  ["中"]   = nil, --[[Q?]]
  ["低"]   = nil --[[Q?]]
}

-- §3.1 扩展部件池（07 号 §5.1 + 08 号 §9.4 增量，非 P 表主表，合计 159 部件；
-- 不参与 12 核心池采样，仅供扩展/地域词库使用）
M.extendedParts = {
  mountains      = { "凤凰山", "青龙山", "紫金山", "玉皇山", "白云山", "莲花山", "昆仑", "太行", "井冈山", "武夷山", "庐山", "峨眉", "泰山", "华山", "衡山", "秦岭" },  -- 16
  waterFlora     = { "滨江", "临江", "沿江", "江滨", "湖畔", "湖滨", "东湖", "西湖", "南湖", "翠湖", "绿湖", "金鸡湖", "松", "竹", "梅", "兰", "桂", "荷", "莲", "牡丹", "梧桐", "白杨", "银杏", "桃", "杏", "柳", "芙蓉", "丁香", "龙", "凤", "麒麟", "鹤", "鹿", "虎" },  -- 34
  science        = { "科技", "高新", "创新", "创业", "发展", "振兴", "开拓", "开发", "世纪", "未来", "信息", "数码", "软件", "智能", "智慧", "生态", "景观" },  -- 17
  terrain        = { "山", "岭", "峰", "岗", "冈", "坡", "坎", "垭", "坳", "峪", "沟", "湾", "嘴", "头", "尾", "墩", "台", "梁", "峁", "塬", "冲", "畈", "塅", "垄", "塝", "岑", "崎", "坑", "坝", "场", "沱", "濠", "洲", "沙", "石", "土", "泥", "白", "青", "黄" },  -- 40
  auspiciousTwo  = { "兴隆", "吉祥", "万寿", "永乐", "腾飞", "鹏程", "锦绣" },  -- 7
  foreignName    = { "皇后", "弥敦", "干诺", "轩尼诗", "罗便臣", "德辅", "遮打", "告士打", "加连威", "亚美打", "议事亭", "荷兰园", "高士德", "关闸", "水坑尾" },  -- 15（默认关闭，见 §8 冲突 3）
  color          = { "呼和", "乌兰", "查干", "哈喇", "锡林", "额尔敦", "巴彦", "达来" },  -- 8（蒙/藏双语：青/红/白/黑/高原/宝/富/海）
  postGarrison   = { "十里", "五里", "白市", "来凤", "龙泉", "邮亭", "大面", "正", "镶", "蓝", "红", "黄", "白", "火器", "镇", "安", "宁", "靖", "威", "武", "定", "平" }  -- 22
}

-- ============================================================================
-- §3.3 专名 × 通名推荐组合矩阵（07 号 §5.3，自然度 5 星制）
-- ============================================================================
M.comboMatrix = {
  { theme = "政治建设类",       suffixes = { "路", "街" },             example = "人民路、解放路、建设路、和平街", naturalness = "★★★★★", note = "" },
  { theme = "地名移植（省名）", suffixes = { "路" },                  example = "四川路、河南路、山东路", naturalness = "★★★★★", note = "南北向" },
  { theme = "地名移植（城市名）", suffixes = { "路", "街" },           example = "北京路、南京路", naturalness = "★★★★★", note = "东西向" },
  { theme = "山水自然（山/水）", suffixes = { "路", "街", "大道" },   example = "凤凰山路、滨江大道、东湖路", naturalness = "★★★★☆", note = "" },
  { theme = "吉祥祝愿类",       suffixes = { "路", "街" },             example = "兴隆街、吉祥路、万寿路", naturalness = "★★★★☆", note = "" },
  { theme = "科教发展类",       suffixes = { "大道", "路" },           example = "科技大道、创业大道、高新路", naturalness = "★★★★☆", note = "新区" },
  { theme = "地貌类",           suffixes = { "坡", "坎", "坝", "坪", "岗" }, example = "石板坡、沙坪坝、七星岗", naturalness = "★★★★☆", note = "山城" },
  { theme = "历史衙署/城门",    suffixes = { "街", "大街" },          example = "总府街、提督街、正阳门大街", naturalness = "★★★☆☆", note = "老城" },
  { theme = "花木类",           suffixes = { "巷", "里", "弄" },       example = "丁香巷、梅里、桂花巷", naturalness = "★★★☆☆", note = "南方诗意" },
  { theme = "数序",             suffixes = { "条", "巷" },             example = "东四头条、西四北头条", naturalness = "★★★☆☆", note = "北京网格" },
  { theme = "纪念·人名",        suffixes = { "路", "街" },             example = "中山路、尚志街、张之洞路", naturalness = "★★★☆☆", note = "注意法规，勿新造" }
}

-- ============================================================================
-- §4 地域分型配置（08 号 §9.3，逐字转写 JSON；权重为相对整数，可整体缩放归一化采样）
-- 9 个地域标签：north/wu/lingnan/southwest/central/min/northwest/tibet/mongol
-- suffixWeights = §4 generics（通名→权重）；themeWeights = §4 themes（主题→权重，原 key 保留）
-- templates = {id, weight, seq, pattern}：seq 为 12 核心池 + "suffix" + "=字面量"；
--   pattern 保留 §4 原文模式串（逐字转写留痕）。
-- 主题占位符 → 12 核心池映射（seq 翻译依据，非规格书原文，特此声明）：
--   {surname}/{surname_geotopo}→surname；{directional}→direction；{ordinal}/{num}→number；
--   {industry}/{market}/{market_field}/{bazaar}→industry；{auspicious}→auspicious；
--   {politics}→political；{province_city}/{borrowed_city}/{mainland_city}/{place}/
--   {foreign_name}→transplant；{terrain}/{geotopo}/{water}/{water_terrain}/{water_well}/
--   {water_lake}/{steppe_water}/{color_terrain}/{color}→landscape；
--   {dynasty}/{buddhism}/{fortress}/{post_station}/{garrison_post}/{gate_dock}→historic；
--   {admin}→political；{reclaim_share}→surname；
--   各 {*_generic} 通名占位符 → "suffix"；具体通名字（家/庄/屯/堡子/官/条/旗/胡同/梯/段/
--   庄子/巴扎/浩特/淖尔/郭勒/苏木/嘎查/艾里/塔拉/林卡/山口/里/村）→ "=字面量"。
-- ============================================================================
M.regions = {
  north = {
    label = "华北/东北",
    suffixWeights = {
      ["胡同"] = 30, ["街"] = 20, ["巷"] = 15, ["条"] = 10, ["庄"] = 6,
      ["屯"] = 6, ["营"] = 4, ["堡"] = 3, ["官"] = 2, ["甸"] = 2, ["峪"] = 2,
      ["大院"] = 2, ["里"] = 2, ["沟"] = 1, ["旗"] = 1
    },
    themeWeights = {
      surname = 35, terrain = 20, sequence = 10, industry = 10,
      auspicious = 10, directional = 10, borrowed_city = 5
    },
    templates = {
      { id = "N1",  weight = 30, seq = { "surname", "=家", "suffix" }, pattern = "{surname}家{generic}" },
      { id = "N2",  weight = 12, seq = { "direction", "number", "=条" }, pattern = "{directional}{ordinal}条" },
      { id = "N3",  weight = 10, seq = { "direction", "suffix" }, pattern = "{directional}{generic}" },
      { id = "N4",  weight = 10, seq = { "industry", "suffix" }, pattern = "{industry}{generic}" },
      { id = "N5",  weight = 8,  seq = { "auspicious", "suffix" }, pattern = "{auspicious}{generic}" },
      { id = "N6",  weight = 4,  seq = { "=正", "landscape", "=旗" }, pattern = "正{color}旗" },
      { id = "N7",  weight = 6,  seq = { "surname", "=庄" }, pattern = "{surname}庄" },
      { id = "N8",  weight = 6,  seq = { "surname", "=屯" }, pattern = "{surname}屯" },
      { id = "N9",  weight = 3,  seq = { "surname", "=堡子" }, pattern = "{surname}堡子" },
      { id = "N10", weight = 2,  seq = { "surname", "=官" }, pattern = "{surname}官" },
      { id = "N11", weight = 5,  seq = { "transplant", "=胡同" }, pattern = "{borrowed_city}胡同" }
    }
  },
  wu = {
    label = "江南/吴语",
    suffixWeights = {
      ["路"] = 30, ["弄"] = 18, ["里"] = 12, ["坊"] = 8, ["桥"] = 8,
      ["浜"] = 6, ["泾"] = 5, ["浦"] = 5, ["塘"] = 4, ["汇"] = 3, ["湾"] = 3,
      ["嘴"] = 2, ["家"] = 8, ["宅"] = 2, ["荡"] = 1, ["漾"] = 1, ["角"] = 1,
      ["埭"] = 1, ["圩"] = 1, ["堰"] = 1, ["库"] = 1
    },
    themeWeights = {
      province_city = 35, surname_geotopo = 30, water = 20,
      auspicious = 10, industry = 5
    },
    templates = {
      { id = "W1", weight = 30, seq = { "transplant", "suffix" }, pattern = "{province_city}{road_generic}" },
      { id = "W2", weight = 25, seq = { "surname", "=家", "suffix" }, pattern = "{surname}家{geotopo}" },
      { id = "W3", weight = 20, seq = { "landscape", "suffix" }, pattern = "{water}{water_generic}" },
      { id = "W4", weight = 15, seq = { "auspicious", "suffix" }, pattern = "{auspicious}{lane_generic}" },
      { id = "W5", weight = 5,  seq = { "industry", "suffix" }, pattern = "{industry}{generic}" }
    }
  },
  lingnan = {
    label = "岭南/港澳",
    suffixWeights = {
      ["街"] = 25, ["路"] = 22, ["村"] = 10, ["巷"] = 8, ["里"] = 6, ["坊"] = 5,
      ["涌"] = 6, ["滘"] = 4, ["围"] = 4, ["沙"] = 4, ["洲"] = 3, ["基"] = 3,
      ["埔"] = 3, ["坑"] = 2, ["岗"] = 2, ["塱"] = 1, ["寮"] = 1, ["墩"] = 1,
      ["约"] = 1, ["墟"] = 1
    },
    themeWeights = {
      water_terrain = 30, surname = 25, auspicious = 15,
      industry = 10, terrain = 10, foreign_name = 10
    },
    templates = {
      { id = "L1", weight = 15, seq = { "surname", "=村" }, pattern = "{surname}村" },
      { id = "L2", weight = 25, seq = { "landscape", "suffix" }, pattern = "{water}{water_generic}" },
      { id = "L3", weight = 15, seq = { "auspicious", "suffix" }, pattern = "{auspicious}{lane_generic}" },
      { id = "L4", weight = 10, seq = { "industry", "suffix" }, pattern = "{industry}{generic}" },
      { id = "L5", weight = 10, seq = { "transplant", "suffix" }, pattern = "{foreign_name}{road_generic}" },
      { id = "L6", weight = 10, seq = { "landscape", "suffix" }, pattern = "{terrain}{terrain_generic}" }
    }
  },
  southwest = {
    label = "西南",
    suffixWeights = {
      ["街"] = 25, ["巷"] = 15, ["场"] = 10, ["坝"] = 9, ["湾"] = 8, ["沱"] = 6,
      ["嘴"] = 5, ["门"] = 5, ["沟"] = 4, ["坡"] = 4, ["垭"] = 3, ["坎"] = 2,
      ["驿"] = 2, ["铺"] = 2, ["码头"] = 1, ["埠"] = 1, ["梯"] = 1
    },
    themeWeights = {
      surname = 30, terrain = 30, market_field = 15,
      post_station = 10, gate_dock = 10, industry = 5
    },
    templates = {
      { id = "S1", weight = 25, seq = { "surname", "=家", "suffix" }, pattern = "{surname}家{geotopo}" },
      { id = "S2", weight = 25, seq = { "landscape", "suffix" }, pattern = "{terrain}{terrain_generic}" },
      { id = "S3", weight = 12, seq = { "industry", "suffix" }, pattern = "{market}{field_generic}" },
      { id = "S4", weight = 10, seq = { "transplant", "suffix" }, pattern = "{place}{post_generic}" },
      { id = "S5", weight = 8,  seq = { "direction", "suffix" }, pattern = "{directional}{gate_generic}" },
      { id = "S6", weight = 3,  seq = { "number", "=梯" }, pattern = "{num}梯" }
    }
  },
  central = {
    label = "华中",
    suffixWeights = {
      ["街"] = 22, ["巷"] = 15, ["湾"] = 10, ["塘"] = 8, ["洲"] = 7, ["铺"] = 6,
      ["埠"] = 4, ["矶"] = 3, ["嘴"] = 3, ["里"] = 3, ["冲"] = 5, ["垸"] = 3,
      ["畈"] = 3, ["垄"] = 2, ["塝"] = 1, ["垱"] = 2, ["塅"] = 2, ["墩"] = 1
    },
    themeWeights = {
      terrain = 35, surname = 20, water = 20,
      post_station = 15, industry = 10
    },
    templates = {
      { id = "C1", weight = 20, seq = { "surname", "suffix" }, pattern = "{surname}{terrain_generic}" },
      { id = "C2", weight = 20, seq = { "landscape", "suffix" }, pattern = "{terrain}{terrain_generic}" },
      { id = "C3", weight = 20, seq = { "landscape", "suffix" }, pattern = "{water}{water_generic}" },
      { id = "C4", weight = 12, seq = { "number", "=里", "suffix" }, pattern = "{num}里{post_generic}" },
      { id = "C5", weight = 10, seq = { "transplant", "suffix" }, pattern = "{place}{road_generic}" },
      { id = "C6", weight = 8,  seq = { "industry", "suffix" }, pattern = "{industry}{generic}" }
    }
  },
  min = {
    label = "闽台",
    suffixWeights = {
      ["街"] = 20, ["巷"] = 12, ["厝"] = 12, ["路"] = 25, ["寮"] = 5, ["埕"] = 4,
      ["澳"] = 3, ["屿"] = 3, ["坑"] = 3, ["埔"] = 3, ["崎"] = 2, ["头"] = 2,
      ["尾"] = 2, ["庄"] = 3, ["社"] = 2, ["岑"] = 1, ["埤"] = 1, ["段"] = 10
    },
    themeWeights = {
      surname = 25, terrain = 25, politics = 20,
      mainland_city = 20, reclaim_share = 10
    },
    templates = {
      { id = "M1", weight = 15, seq = { "surname", "suffix" }, pattern = "{surname}{house_generic}" },
      { id = "M2", weight = 15, seq = { "landscape", "suffix" }, pattern = "{terrain}{terrain_generic}" },
      { id = "M3", weight = 20, seq = { "political", "suffix" }, pattern = "{politics}{road_generic}" },
      { id = "M4", weight = 15, seq = { "political", "suffix", "number", "=段" }, pattern = "{politics}{road_generic}{ordinal}段" },
      { id = "M5", weight = 15, seq = { "transplant", "suffix" }, pattern = "{mainland_city}{road_generic}" },
      { id = "M6", weight = 8,  seq = { "number", "suffix" }, pattern = "{num}{share_generic}" },
      { id = "M7", weight = 5,  seq = { "direction", "suffix" }, pattern = "{directional}{house_generic}" }
    }
  },
  northwest = {
    label = "西北",
    suffixWeights = {
      ["街"] = 20, ["巷"] = 14, ["堡"] = 8, ["寨"] = 6, ["营"] = 5, ["屯"] = 5,
      ["驿"] = 3, ["台"] = 3, ["墩"] = 3, ["渠"] = 5, ["泉"] = 4, ["井"] = 3,
      ["坎"] = 2, ["塬"] = 5, ["梁"] = 3, ["峁"] = 3, ["湾"] = 3, ["庄子"] = 3,
      ["城子"] = 2, ["巴扎"] = 2, ["峪"] = 2, ["关"] = 2, ["滩"] = 1
    },
    themeWeights = {
      terrain = 30, garrison_post = 30, water_well = 20,
      surname = 15, bazaar = 5
    },
    templates = {
      { id = "X1", weight = 20, seq = { "landscape", "suffix" }, pattern = "{terrain}{loess_generic}" },
      { id = "X2", weight = 10, seq = { "historic", "suffix" }, pattern = "{dynasty}{canal_generic}" },
      { id = "X3", weight = 10, seq = { "surname", "=庄子" }, pattern = "{surname}庄子" },
      { id = "X4", weight = 20, seq = { "transplant", "suffix" }, pattern = "{place}{garrison_generic}" },
      { id = "X5", weight = 8,  seq = { "transplant", "suffix" }, pattern = "{place}{gate_pass_generic}" },
      { id = "X6", weight = 5,  seq = { "transplant", "=巴扎" }, pattern = "{place}巴扎" },
      { id = "X7", weight = 10, seq = { "landscape", "suffix" }, pattern = "{water}{well_generic}" }
    }
  },
  tibet = {
    label = "藏区",
    suffixWeights = {
      ["寺"] = 25, ["错"] = 18, ["曲"] = 15, ["塘"] = 10, ["林卡"] = 8,
      ["宗"] = 8, ["卡"] = 6, ["廓"] = 6, ["拉"] = 4
    },
    themeWeights = {
      buddhism = 35, color_terrain = 30, water_lake = 25, fortress = 10
    },
    templates = {
      { id = "T1", weight = 20, seq = { "landscape", "suffix" }, pattern = "{color}{water_generic}" },
      { id = "T2", weight = 25, seq = { "historic", "suffix" }, pattern = "{buddhism}{temple_generic}" },
      { id = "T3", weight = 15, seq = { "landscape", "suffix" }, pattern = "{color}{lake_generic}" },
      { id = "T4", weight = 10, seq = { "transplant", "suffix" }, pattern = "{place}{plain_generic}" },
      { id = "T5", weight = 10, seq = { "transplant", "suffix" }, pattern = "{place}{fortress_generic}" },
      { id = "T6", weight = 8,  seq = { "transplant", "=林卡" }, pattern = "{place}林卡" },
      { id = "T7", weight = 6,  seq = { "transplant", "=山口" }, pattern = "{place}山口" }
    }
  },
  mongol = {
    label = "内蒙古",
    suffixWeights = {
      ["浩特"] = 25, ["旗"] = 15, ["苏木"] = 12, ["嘎查"] = 10, ["郭勒"] = 10,
      ["淖尔"] = 10, ["艾里"] = 8, ["塔拉"] = 6, ["盟"] = 4
    },
    themeWeights = {
      color = 35, steppe_water = 30, admin = 25, auspicious = 10
    },
    templates = {
      { id = "G1", weight = 20, seq = { "landscape", "=浩特" }, pattern = "{color}浩特" },
      { id = "G2", weight = 15, seq = { "landscape", "=淖尔" }, pattern = "{color}淖尔" },
      { id = "G3", weight = 15, seq = { "transplant", "=郭勒" }, pattern = "{place}郭勒" },
      { id = "G4", weight = 15, seq = { "transplant", "=旗" }, pattern = "{place}旗" },
      { id = "G5", weight = 10, seq = { "transplant", "=苏木" }, pattern = "{place}苏木" },
      { id = "G6", weight = 10, seq = { "transplant", "=嘎查" }, pattern = "{place}嘎查" },
      { id = "G7", weight = 8,  seq = { "transplant", "=艾里" }, pattern = "{place}艾里" },
      { id = "G8", weight = 5,  seq = { "transplant", "=塔拉" }, pattern = "{place}塔拉" }
    }
  }
}

-- §6.1 地域风格（决定权重与通名池子集）—— 05 号 §5.2 + 08 号 §9.3
M.style = {
  north    = { lane_pool = { "胡同", "条", "巷", "街" }, block = "大院", nature_bias = "陆" },
  jiangnan = { lane_pool = { "弄", "里", "坊", "巷", "浜", "泾", "浦", "塘", "港" }, block = "里弄" },
  lingnan  = { lane_pool = { "街", "巷", "里", "坊", "涌", "滘", "基", "围", "埗" } },
  southwest = { lane_pool = { "街", "巷", "坝", "坡", "坎", "坪", "沱" } },
  plaingrid = { use_latlong = true, use_ordinal = true }
}

-- ============================================================================
-- §5 城市规模分型配置（05 号 §4 + 07 号 §4 时代分层）
-- ============================================================================
M.scales = {
  metropolis = {
    label = "一线/新一线大都市",
    themes   = { "地名移植", "政治教化", "山水", "现代功能（科技/金融/商务）" },
    suffixes = { "大道", "路", "街", "环路", "高架" },
    flavor   = "大气、国际化、多「大道/环路」",
    examples = { "世纪大道", "滨江大道", "科技园路", "内环路" }
  },
  prefecture = {
    label = "地级市",
    themes   = { "政治教化", "山水", "吉祥", "功能" },
    suffixes = { "路", "街", "大道" },
    flavor   = "稳健、功能分明",
    examples = { "建设路", "和平路", "工业大道", "文昌街" }
  },
  county = {
    label = "县城",
    themes   = { "政治教化（人民/解放/建设）", "序号/方位" },
    suffixes = { "路", "街", "巷" },
    flavor   = "「人民/解放/建设+序号/方位」是县城标配",
    examples = { "人民路", "建设一路", "解放街", "东门街" }
  },
  town = {
    label = "乡镇",
    themes   = { "姓氏", "方位", "地标", "吉祥" },
    suffixes = { "街", "巷", "路", "坝" },
    flavor   = "聚族而居、地标命名",
    examples = { "张家街", "桥头街", "文昌街", "马家坝" }
  },
  village = {
    label = "村落",
    themes   = { "姓氏", "自然地物", "方位" },
    suffixes = { "庄", "村", "湾", "坝", "屯" },
    flavor   = "多为村名而非路名",
    examples = { "李家湾", "杨家坝", "桥头", "东庄" }
  }
}

-- §5 时代分层开关（07 号 §4，可选叠加）
M.eras = {
  mingqing = {
    label = "明清老城（—1911）",
    suffixes  = { "街", "巷", "坊", "里", "胡同", "弄", "条", "牌楼", "门", "市", "口", "桥" },
    keywords  = { "城门", "衙署", "寺庙", "集市", "宗族姓氏", "地貌" },
    apply     = "古城/古镇风格"
  },
  minguo = {
    label = "民国商埠租界（1911–1949）",
    suffixes  = { "路", "马路", "大马路", "道" },
    keywords  = { "中山", "民族", "民生", "民权", "省市地名（移植）", "租界洋名" },
    apply     = "开埠城市风格",
    note      = "道（天津）"
  },
  planned = {
    label = "计划经济期（1949–1978）",
    suffixes  = { "路", "街", "大道" },
    keywords  = { "解放", "人民", "建设", "新华", "红旗", "东风", "胜利", "和平", "团结" },
    apply     = "老工业城市",
    note      = "路（主流）"
  },
  open1978 = {
    label = "1978 后开发区",
    suffixes  = { "大道", "路" },
    keywords  = { "科技", "创业", "发展", "振兴", "开发", "高新", "创新" },
    apply     = "开发区风格"
  },
  new2000 = {
    label = "2000 后新区",
    suffixes  = { "大道", "路" },
    keywords  = { "世纪", "未来", "科技", "信息", "数码", "软件", "生态", "景观", "滨江", "临港", "智慧", "云", "创", "芯", "谷", "湾" },
    apply     = "新区风格"
  }
}

-- ============================================================================
-- §6.3 校验与过滤顺序（valid 函数，18 步；顺序即管线）
-- ============================================================================
M.validOrder = {
  { step = 1,  rule = "地名 = 专名 + 通名 两段，否则 reject", ref = "B1" },
  { step = 2,  rule = "通名出现次数 != 1：reject（拦截「路街」「巷弄」）", ref = "A12/B2" },
  { step = 3,  rule = "专名字数 > 3 或总长 > 5（轨交站 ≤6）：reject", ref = "B4/R4" },
  { step = 4,  rule = "通名不得单独作专名：reject", ref = "A13" },
  { step = 5,  rule = "专名命中 违禁黑名单（外国人名地名/音译词/领导人/企业商标/封建迷信/不雅）：reject", ref = "A1-A6" },
  { step = 6,  rule = "专名含 生僻字（超出常用 3500 字/《通用规范汉字表》一级即告警）：reject", ref = "A7" },
  { step = 7,  rule = "含 外文字母/英文单词：reject", ref = "A8" },
  { step = 8,  rule = "含 纯数字序号（纪念数字地名仅白名单 五一/八一/一二九）：reject", ref = "A9" },
  { step = 9,  rule = "level==arterial 且 专名 in {姓氏式, 山水小词}：reject", ref = "「马家大道」「桂花大街」" },
  { step = 10, rule = "level==lane 且 专名 in {政治大词}：reject", ref = "「解放胡同」" },
  { step = 11, rule = "构造通名作末端（「××高架」「××立交」）：reject，应改后缀", ref = "R2" },
  { step = 12, rule = "pinyin(name) 有 三连同声母 或 四连同调：reject", ref = "" },
  { step = 13, rule = "pinyin(name) 命中 谐音黑名单（整串+逐字+首字母缩写）：reject", ref = "" },
  { step = 14, rule = "方言谐音黑名单（粤语/闽南语等，按城市方言预设）：reject", ref = "" },
  { step = 15, rule = "同地图内 专名重名：reject", ref = "A10" },
  { step = 16, rule = "同地图内 专名同音（拼音去声调）：reject", ref = "A11" },
  { step = 17, rule = "name 命中 著名路名黑名单：reject", ref = "§7.2" },
  { step = 18, rule = "name 命中 一线城市名+路 组合：视策略降级", ref = "§8 冲突 6" }
}

-- ============================================================================
-- §7.1 推荐配比（07 号 §6，实测建议）
-- ============================================================================
M.ratios = {
  suffix = {
    ["路"] = 50, ["街"] = 20, ["大道"] = 12, ["巷"] = 8,
    ["弄/胡同/条"] = 6,  -- 三类合并计 6%
    other = 4           -- 其他（坡坎坝坪/甫/约/通津/道）
  },
  length = {
    [3] = 50, [4] = 32, [5] = 12,
    other = 6  -- 2 字 / 6 字+ 合并计 6%
  },
  arterialTheme = {
    political = 30,           -- 政治·建设类
    transplant = 25,          -- 地名移植类（省名南北 + 城市名东西）
    landscape_auspicious = 20, -- 山水自然·吉祥类
    science = 15,             -- 科教发展类（新区）
    memorial = 5,             -- 纪念·人名类
    historic_terrain = 5     -- 历史·地貌类
  },
  localTheme = {
    historic_lane = 30,     -- 历史街巷类
    landscape_flora = 25,   -- 山水花木诗意类
    auspicious = 20,        -- 吉祥祝愿类
    transplant = 15,        -- 地名移植（小地名/县名）
    other = 10             -- 其他（数序条巷/地貌）
  }
}

-- ============================================================================
-- §7.2 真实路名黑名单与无害撞名白名单（05 号 §6）
-- ============================================================================
-- B. 著名独特路名黑名单（必须避让；建议维护 100 条左右硬名单）
M.realNameBlocklist = {
  "上海南京路", "北京王府井", "北京长安街", "上海外滩", "深圳深南大道",
  "武汉汉正街", "成都春熙路", "广州北京路", "厦门中山路步行街"
}
-- C. 一线城市名 + 路（降级/避让；易联想真实城市）
M.cityRoadBlacklist = { "南京路", "北京路", "上海路", "广州路", "深圳路", "香港路" }
-- A. 无害撞名白名单（高频通用，可放心用）
M.commonWhitelist = {
  "人民路", "中山路", "解放路", "建设路", "和平路", "新华路", "文化路",
  "公园路", "迎宾路", "朝阳路", "青年路", "团结路", "光明路"
}

-- ============================================================================
-- §7.3 反 AI 味策略参数
-- ============================================================================
M.antiAi = {
  transplantExceptionRate = { min = 0.05, max = 0.08 },  -- §7.3-5：保留 5–8% 地名移植「违和」例外
  rules = {
    "① 禁洋名/企业名（《条例》2022：不以外国人名、地名；不以企业/商标名作地名）",
    "② 专名+通名缺一不可（不要生成「长安」「紫金」无通名裸名）",
    "③ 通名与尺度匹配（大道=主干道、巷/弄/胡同=窄路、路/街=通用）",
    "④ 地域绑定（胡同→北京、弄→上海江南、坡坝坪→重庆、甫/约/通津→广州、道→天津租界）",
    "⑤ 保留少量例外/趣味（5–8% 地名移植违和；少量趣味名点缀）",
    "⑥ 派生组合降撞名（双字政治词两两搭配、加修饰、序号/经纬改主题）"
  }
}

-- ============================================================================
-- §8 冲突与待裁定事项（仲裁建议为生成器默认取值，可由作者开关覆盖）
-- ============================================================================
M.conflicts = {
  {
    id = "CONFLICT_1",
    title = "「浦 / 港 / 溇」水系通名的地域归属不一致",
    summary = "05 号 §1.5 把「浜/泾/浦/塘/港/堰/溇」整体划给江南；08 号江南表不含「港」「溇」，潮汕海港多用「澳、浦、港」，闽台也有「澳」",
    resolution = {
      "① 「浦」保留江南（黄浦、杨树浦为吴语核心，双源一致）",
      "② 「港」从江南默认通名池降权或移除，改归「沿海/潮汕·闽粤海港」二级标记（与「澳」同池）",
      "③ 「溇」仅 05 号出现、缺第二源印证，标〔存疑〕并以低权重或禁用处理"
    },
    suspicious = { "溇" }
  },
  {
    id = "CONFLICT_2",
    title = "「大道 / 大街 / 路 / 巷」量化门槛各市不一",
    summary = "大道：上海 ≥50m、成都 ≥60m、西安 ≥80m 且 ≥8000m（安丘 ≥50m 且 ≥4000m）；路/街↔巷分界：西安 20m、成都 16m、安丘 <10m",
    resolution = {
      "大道 ≥60m 且 ≥4000m（宽度取成都 60m、长度取安丘 4000m）",
      "路/街 16–60m 且 ≥500m（下限取成都 16m）",
      "巷/弄/里/胡同 <16m 且 ≤500m（取成都最宽下限口径）",
      "西安式「≥80m 且 ≥8km」作「严格模式」开关"
    }
  },
  {
    id = "CONFLICT_3",
    title = "外文音译地名与「禁洋名」法规冲突",
    summary = "《条例》9(五) 禁外国人名/地名；但存在大量历史遗留音译路名（哈尔滨果戈里、港澳弥敦道等）",
    resolution = {
      "默认关闭外文音译池（foreign_name 权重默认 0）",
      "仅「哈尔滨/港澳」历史风貌模式走白名单音译词（果戈里、弥敦、轩尼诗等），不得新造",
      "港澳模式下 foreign_name 由 10 降为「白名单限定」"
    }
  },
  {
    id = "CONFLICT_4",
    title = "「以人名作地名」与「纪念路名高频」的张力",
    summary = "《条例》9(四) 一般不以人名作地名；但「中山路」653 条、哈尔滨「尚志大街/兆麟街/一曼街/靖宇街」等真实高频",
    resolution = {
      "① 真实人名仅走白名单（中山、尚志、兆麟、一曼、靖宇、张之洞、黄兴、蔡锷、邹容、彭刘杨等）",
      "② 新造人名用虚构姓名（符合《实施办法》第三条规范空间）",
      "③ 领导人姓名硬禁止（A2）"
    }
  },
  {
    id = "CONFLICT_5",
    title = "纯数字序号路名与「禁纯数字序词」的边界",
    summary = "西安导则禁纯数字序词（城市环路除外）；但武汉/上海「一马路～三马路」、郑州/石家庄「经一路/纬一路」、北京「头条～十四条」真实存在",
    resolution = {
      "① 纪念性数字（五一、八一、一二九）白名单保留",
      "② 纯编号（「3 号路」「18 号街」）禁止",
      "③ 「经 N 路/纬 N 路」「一～N 马路」「头条～N 条」属历史遗留系统性命名，建议改用「第 N + 主题」或「方位 + 序号」，环路序号除外",
      "④ 「条」的数序（东四头条）仅限北京风格"
    }
  },
  {
    id = "CONFLICT_6",
    title = "一线城市名 + 路 的「避让」与「地名移植风味」张力",
    summary = "05 号 §2.4/§6 建议避让「南京/北京/上海/广州/深圳/香港 + 路」；但上海/青岛/台北风味依赖真实一线地名移植",
    resolution = {
      "① 用虚构城市名做移植来源（cityname_pool 注入虚构省/市名），保留风味又规避现实撞名",
      "② 若必须真实地名移植，一线地名+路 走黑名单或降级为地级市/县级市名",
      "③ 保留「省名=南北、城市名=东西」结构规则，仅替换城市名池"
    }
  }
}

M.pendingDecisions = {
  { id = "PENDING_1", title = "胡同语源", note = "存疑，不影响使用：胡同源自古汉语「巷/衖」、与南方「弄」同源、非蒙古语水井说；两报告一致仅作存疑保留", suspicious = true },
  { id = "PENDING_2", title = "走向决定通名（南北街/东西路）", note = "部分东北/北方城市约定（沈阳、长春），非全国通则；作为可选北方城市风格开关，默认关闭", suspicious = true }
}

return M

-- ============================================================================
-- 导出统计（与规格书 §8 附「交付统计汇总」及 §2/§3 计数对齐）：
--   通名总数 148 = 通用层 38（骨干 9 + 次干 12 + 片区 17）+ 地域专属去重 110（8 区）
--   专名部件 ≈494 = 核心 335（政治 32 + 方位 11 + 序数 8 + 山水 42[实列 43] + 省 28 + 市 30
--                    + 行业 23 + 吉祥 30 + 姓氏 99 + 纪念 11 + 水文 9 + 历史 12）
--                    + 扩展 159（山 16 + 水/花木/瑞兽 34 + 科教 17 + 地貌 40
--                    + 吉祥双字 7 + 外文音译 15 + 颜色 8 + 驿铺/军屯 22）
--   地域分型 9（§4：north/wu/lingnan/southwest/central/min/northwest/tibet/mongol）；
--             §2.4 按「藏蒙」合并口径为 8 区
--   冲突 6 + 待裁定 2
--
-- 差异与存疑标注（均源自规格书原文，导出时未改动）：
--   1. §3.1 山水自然类标题标「42 部件」，实际列出 43 个词（末位「杉」为第 43 个），
--      按「不抽样」原则全部落表；计数差异已在行内注释标注。
--   2. §3.2 各主题权重档位只给定性（极高/高/中/低），未给数值 → M.freqWeight 四键值为 nil 并标 Q?。
--   3. 地域专属〔存疑〕词：库（江南）、篱（岭南）、岑（闽台）、扎（藏区）；冲突 1 之「溇」〔存疑〕。
--   4. §6.1 style.lingnan 的 lane_pool 含「埗」，§2.4 岭南通名表未单列（原文如此，逐字转写）。
--   5. §7.1 通名配比「弄/胡同/条」合并计 6%，未拆分（原文未给单项占比）。
--   6. 对接契约要求的 seq 翻译：§4 模板模式串 {pattern} 翻译为 12 核心池 seq，主题占位符→
--      核心池的映射（terrain/water/color→landscape 等）为导出时声明的约定，非规格书原文，
--      pattern 字段已保留 §4 原文模式串以备查证。
-- ============================================================================

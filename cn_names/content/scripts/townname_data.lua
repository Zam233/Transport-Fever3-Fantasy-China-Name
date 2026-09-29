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
-- 自动导出：来源 build/城市命名规格-四类.md
-- 本文件仅含数据，不含生成逻辑
--
-- 导出日期：__EXPORT_DATE__（占位，待回填）
--
-- 说明：
--   * A–H 八节机械转写，未新增规格书之外的语言事实。
--   * 规格书所有「权重建议/权重」列均为「未给出」，故所有 weight = nil（--[[W?]]），
--     无一编造；仅海洋/亚寒带模板的权重列出现定性标注（「报告标主」「报告标≤10% 混入」），
--     已原样存入 weightNote。
--   * 规格书以「—」表示空（无备注/无含义），导出为 nil。
--   * 模板 seq：最后一个插槽必为通名（suffix / terrain_suffix / auspicious_suffix / =字面量）。
--     其余插槽 = parts 池名（下方对照）或字面量（以 = 开头）。音译/特殊式（无插槽序列）seq = nil。
--   * D 节部件已「拆字/拆词」：顿号/斜杠串拆成独立条目，每字/词一条 {w=..., weight=nil, note=...}。
--     拆字后每条继承原行的备注（note）；备注若特指某变体（如「崮为…」「堡多音」），仅对该字有效。
--   * C 节通名（suffixes）保持「一行一条」，w 为原样多词串（如「道 / 路」「山 / 岭 / 峰…」），未拆字。
--   * 真实地名黑名单斜杠变体（如「西贡/柴棍」）已拆为独立条目，未新增名称。
--
-- parts 池名对照（规格书 D 节组名 → 池名）：
--   canonical：single（单字专名核心总池）、direction（方位）、terrain（地形地貌）、plant（物产植被）、
--     water（水流水体）、mountain（山体）、ancient_state（古国/古九州/古郡县）、garrison（军事屯戍）、
--     post（交通驿传）、market（商贸市集）、surname（姓氏，含复姓）、auspicious（吉祥教化）、
--     era_name（年号）、number（数字）、mileage（里程）、color（颜色）、verb_head（动宾首字）
--   分类特有（规格书有、canonical 无的）：ocean 用 faith（华人信仰）、dialect（方言群偏好）；
--     northwest 用 modifier（地貌修饰）、corps（兵团命名部件）；subarctic 用 mining（矿业）、farming（屯垦）。
--   suffixes 子类（group 字段）：见各类内注释。
--
-- 统计（通名= suffixes 行数；部件= parts 拆字后条目数）：
--   han       通名 19 ｜ 部件 374(+single) ｜ 模板 11 行(H3 拆 2 条 seq) ｜ banned.chars 11
--   ocean     通名 29 ｜ 部件 128(+single) ｜ 模板  4 ｜ banned.chars 13
--   northwest 通名 97 ｜ 部件 165(+single) ｜ 模板 10 ｜ banned.chars  9
--   subarctic 通名 25 ｜ 部件 117(+single) ｜ 模板  5 ｜ banned.chars  8

local M = {}

M.STYLES = { "han", "ocean", "northwest", "subarctic" }

M.town = {

  ---------------------------------------------------------------------------
  -- 汉地（传统「汉地十八省」）
  ---------------------------------------------------------------------------
  han = {

    -- A. 风格定义与辨识特征
    style = {
      [=[「专名 + 通名」二元结构，中心语后置（head-final）：专名前置修饰、通名后置表类，如"洛（洛水）+ 阳"。]=],
      [=[山水阴阳强约束：山南水北为「阳」、山北水南为「阴」，「X 阳 / X 阴」的前字必为山名或水名。]=],
      [=[通名地域分布是强约束：泾/浜/浦/渎/浃/埭 不出华北；涌/滘/围/基/寮/埔 不出岭南；坝/场/垭/槽/坎 为西南/陕南；冲/垄/塅 为湘赣；厝/寮/澳/屿/崙 为闽台——「区域 × 通名」必须匹配。]=],
      [=[姓氏宗族聚落是最普遍命名方式：X 家庄 / X 家村 / X 家屯 / X 家营。]=],
      [=[通名可「专名化」后向上叠加更高层级通名：景德镇 → 景德镇市、石家庄 → 石家庄市。]=],
    },

    -- B. 构词模板（seq 末位 = 通名）
    templates = {
      { id = "H1", formula = [=[单字专名 + 单字通名（2 字，城市主力）]=], seq = { "single", "suffix" }, weight = nil, note = [=[长安、苏州；2 字县名约占绝对主体（报告经验估计 85%+）]=] }, --[[W?]]
      { id = "H2", formula = [=[吉祥字 + 吉祥通名]=], seq = { "auspicious", "auspicious_suffix" }, weight = nil, note = [=[长安、永安、昌平（吉祥字配安/宁/平/昌/兴/顺/和/泰/康/靖）]=] }, --[[W?]]
      { id = "H3a", formula = [=[山水阴阳：水/山名 + 阳]=], seq = { "single", "=阳" }, weight = nil, note = [=[洛阳；须能自洽解释方位]=] }, --[[W?]]
      { id = "H3b", formula = [=[山水阴阳：水/山名 + 阴]=], seq = { "single", "=阴" }, weight = nil, note = [=[江阴；须能自洽解释方位]=] }, --[[W?]]
      { id = "H4", formula = [=[古国/古州名 + 州]=], seq = { "ancient_state", "=州" }, weight = nil, note = [=[兖州、扬州（古九州字配「州」）]=] }, --[[W?]]
      { id = "H5", formula = [=[姓氏 + 家 + 通名（3 字聚落）]=], seq = { "surname", "=家", "suffix" }, weight = nil, note = [=[张家庄、李家堡；报告称可「单类量产大量可信乡镇名」]=] }, --[[W?]]
      { id = "H6", formula = [=[姓氏 + 通名（2 字聚落）]=], seq = { "surname", "suffix" }, weight = nil, note = [=[王庄、李村、张营]=] }, --[[W?]]
      { id = "H7", formula = [=[数字 + 里程 + 通名]=], seq = { "mileage", "suffix" }, weight = nil, note = [=[十里铺、三十里铺、五里亭]=] }, --[[W?]]
      { id = "H8", formula = [=[方位 + 专名核心 + 通名]=], seq = { "direction", "single", "suffix" }, weight = nil, note = [=[东山、西湖、北桥（方位一律前置）]=] }, --[[W?]]
      { id = "H9", formula = [=[物产植被 + 地形通名]=], seq = { "plant", "terrain_suffix" }, weight = nil, note = [=[桐乡、茶陵、竹溪、枣庄、桂林]=] }, --[[W?]]
      { id = "H10", formula = [=[颜色 + 自然通名]=], seq = { "color", "terrain_suffix" }, weight = nil, note = [=[白沙、青浦、黄浦]=] }, --[[W?]]
      { id = "gen", formula = [=[（通用骨架）[修饰/定位成分] + 专名核心 + 通名]=], seq = { "single", "suffix" }, weight = nil, note = [=[修饰=方位·数字·颜色·大小；专名核心=特征词；通名=类型词]=] }, --[[W?]]
    },

    -- C. 通名表（一行一条；group = 子类）
    suffixes = {
      -- 行政层级
      { w = "省", etymon = [=[元代行省]=], scene = [=[最高层级]=], weight = nil, note = [=[虚构城市名一般不用]=], group = "admin" }, --[[W?]]
      { w = "道 / 路", etymon = [=[唐道、宋金元路]=], scene = [=[中高层政区]=], weight = nil, note = [=[宋元「路」可作古名残留]=], group = "admin" }, --[[W?]]
      { w = "府", etymon = [=[唐都督府→明清统县政区]=], scene = [=[明清统县]=], weight = nil, note = [=[专名多双字：广州府、开封府]=], group = "admin" }, --[[W?]]
      { w = "州", etymon = [=[上古「水中可居曰州」]=], scene = [=[极高频城名通名]=], weight = nil, note = [=[专名几乎必为单字：苏州、杭州；忌叠用]=], group = "admin" }, --[[W?]]
      { w = "郡", etymon = [=[秦汉郡县制]=], scene = [=[古名/雅名]=], weight = nil, note = [=[已不通行，仅历史素材]=], group = "admin" }, --[[W?]]
      { w = "县", etymon = [=[秦郡县制起，最稳定]=], scene = [=[县级]=], weight = nil, note = [=[专名多双字或单字古县]=], group = "admin" }, --[[W?]]
      { w = "厅", etymon = [=[清代新设政区]=], scene = [=[边疆/新垦区]=], weight = nil, note = [=[汉地十八省较少用]=], group = "admin" }, --[[W?]]
      { w = "镇", etymon = [=[唐军镇→宋市镇→现代基层]=], scene = [=[市镇/乡级]=], weight = nil, note = [=[现代与市/县不同层级]=], group = "admin" }, --[[W?]]
      { w = "乡 / 里 / 坊", etymon = [=[先秦乡里→宋坊市]=], scene = [=[基层聚落/城市里坊]=], weight = nil, note = [=[里坊为城内街区（平康里、永和坊）]=], group = "admin" }, --[[W?]]
      -- 自然地理
      { w = "山 / 岭 / 峰 / 岗 / 丘 / 坡 / 岩 / 崖 / 岫 / 岑 / 崮", etymon = [=[山体/岗丘]=], scene = [=[全国]=], weight = nil, note = [=[崮为鲁中特有方山（孟良崮）]=], group = "geography" }, --[[W?]]
      { w = "江 / 河 / 川 / 溪 / 涧 / 沟 / 渠 / 湖 / 泊 / 淀 / 池 / 潭 / 泉 / 井 / 湾 / 汊 / 港", etymon = [=[水流/水体]=], scene = [=[全国]=], weight = nil, note = nil, group = "geography" }, --[[W?]]
      { w = "洲 / 渚 / 滩 / 矶 / 浦 / 泾 / 浜 / 渎 / 浃 / 漾 / 荡 / 滘 / 涌 / 汊 / 埠 / 渡 / 津 / 塘 / 堰 / 陂", etymon = [=[水中洲渚/河汊/水边聚落]=], scene = [=[洲渚滩矶全国；泾浜浦渎浃江南；涌滘岭南]=], weight = nil, note = nil, group = "geography" }, --[[W?]]
      { w = "坪 / 塬(原) / 坝 / 冲 / 坳 / 垄(垅) / 塅 / 畈 / 垸 / 坎 / 槽 / 垭 / 垇 / 塝 / 塆(湾)", etymon = [=[平/洼/台/谷地]=], scene = [=[坪=华南；塬=黄土台地；坝场垭槽=西南；冲垄塅=湘赣；畈垸塆=两湖]=], weight = nil, note = nil, group = "geography" }, --[[W?]]
      -- 人文/军事/交通/商贸/聚落
      { w = "卫 / 所 / 营 / 屯 / 堡 / 寨 / 关 / 隘 / 卡 / 哨 / 墩 / 台 / 戍 / 镇", etymon = [=[明卫所制、军屯驻堡]=], scene = [=[卫所→城名；屯堡寨营→聚落]=], weight = nil, note = [=[堡多音：bǎo 堡垒 / pù 铺 / bǔ 有围墙村镇]=], group = "settlement" }, --[[W?]]
      { w = "驿 / 铺 / 站 / 塘 / 汛 / 渡 / 津 / 桥 / 梁 / 埠 / 亭 / 台", etymon = [=[驿站递铺（十里一铺）]=], scene = [=[驿→城名；铺店站→交通聚落]=], weight = nil, note = [=[铺常配里程：十里铺]=], group = "settlement" }, --[[W?]]
      { w = "集 / 市 / 店 / 铺 / 坊 / 墟 / 圩 / 场 / 街 / 码头", etymon = [=[定期集市→定居聚落]=], scene = [=[集店华北中原；墟圩岭南闽赣；场街西南]=], weight = nil, note = [=[集多配数字/姓氏]=], group = "settlement" }, --[[W?]]
      { w = "庄 / 村 / 屯 / 营 / 店 / 堡 / 寨 / 屋 / 楼 / 宅 / 家", etymon = [=[宗族聚族而居]=], scene = [=[姓氏聚落]=], weight = nil, note = [=[姓氏（或姓氏+家）+ 通名]=], group = "settlement" }, --[[W?]]
      { w = "埠 / 浦 / 港 / 津 / 码头 / 渡", etymon = [=[水运码头]=], scene = [=[水域商埠]=], weight = nil, note = [=[港近代多指海港]=], group = "settlement" }, --[[W?]]
      { w = "厝 / 寮 / 澳 / 屿 / 崙(仑) / 坑 / 埔 / 埕 / 头 / 尾 / 社", etymon = [=[闽语"厝/寮"=房屋/棚屋；澳=港湾；屿=岛]=], scene = [=[闽台/潮汕聚落]=], weight = nil, note = [=[厝/寮常配姓氏或方位]=], group = "settlement" }, --[[W?]]
    },

    -- 自然地理通名（供 H9/H10 用，= suffixes 中 group=geography 的 4 行）
    terrain_suffix = {
      { w = "山 / 岭 / 峰 / 岗 / 丘 / 坡 / 岩 / 崖 / 岫 / 岑 / 崮", weight = nil, note = [=[崮为鲁中特有方山（孟良崮）]=] }, --[[W?]]
      { w = "江 / 河 / 川 / 溪 / 涧 / 沟 / 渠 / 湖 / 泊 / 淀 / 池 / 潭 / 泉 / 井 / 湾 / 汊 / 港", weight = nil, note = nil }, --[[W?]]
      { w = "洲 / 渚 / 滩 / 矶 / 浦 / 泾 / 浜 / 渎 / 浃 / 漾 / 荡 / 滘 / 涌 / 汊 / 埠 / 渡 / 津 / 塘 / 堰 / 陂", weight = nil, note = nil }, --[[W?]]
      { w = "坪 / 塬(原) / 坝 / 冲 / 坳 / 垄(垅) / 塅 / 畈 / 垸 / 坎 / 槽 / 垭 / 垇 / 塝 / 塆(湾)", weight = nil, note = nil }, --[[W?]]
    },

    -- 吉祥通名（供 H2 用，源 H2 备注：安/宁/平/昌/兴/顺/和/泰/康/靖）
    auspicious_suffix = {
      { w = "安", weight = nil, note = nil }, --[[W?]]
      { w = "宁", weight = nil, note = nil }, --[[W?]]
      { w = "平", weight = nil, note = nil }, --[[W?]]
      { w = "昌", weight = nil, note = nil }, --[[W?]]
      { w = "兴", weight = nil, note = nil }, --[[W?]]
      { w = "顺", weight = nil, note = nil }, --[[W?]]
      { w = "和", weight = nil, note = nil }, --[[W?]]
      { w = "泰", weight = nil, note = nil }, --[[W?]]
      { w = "康", weight = nil, note = nil }, --[[W?]]
      { w = "靖", weight = nil, note = nil }, --[[W?]]
    },

    -- D. 专名部件表（拆字；meaning = 原行含义，note = 原行备注）
    parts = {
      -- 山体
      mountain = {
        { w = "山", weight = nil, note = [=[例：庐山、梅岭、凤岗、孟良崮]=] }, { w = "岭", weight = nil, note = [=[例：庐山、梅岭、凤岗、孟良崮]=] }, { w = "峰", weight = nil, note = [=[例：庐山、梅岭、凤岗、孟良崮]=] }, { w = "岗", weight = nil, note = [=[例：庐山、梅岭、凤岗、孟良崮]=] }, { w = "丘", weight = nil, note = [=[例：庐山、梅岭、凤岗、孟良崮]=] },
        { w = "岩", weight = nil, note = [=[例：庐山、梅岭、凤岗、孟良崮]=] }, { w = "崖", weight = nil, note = [=[例：庐山、梅岭、凤岗、孟良崮]=] }, { w = "岫", weight = nil, note = [=[例：庐山、梅岭、凤岗、孟良崮]=] }, { w = "岑", weight = nil, note = [=[例：庐山、梅岭、凤岗、孟良崮]=] }, { w = "崮", weight = nil, note = [=[例：庐山、梅岭、凤岗、孟良崮]=] },
      },
      -- 水流水体 + 水边
      water = {
        { w = "江", weight = nil, note = [=[例：椒江、清河、洛川、巢湖]=] }, { w = "河", weight = nil, note = [=[例：椒江、清河、洛川、巢湖]=] }, { w = "川", weight = nil, note = [=[例：椒江、清河、洛川、巢湖]=] }, { w = "溪", weight = nil, note = [=[例：椒江、清河、洛川、巢湖]=] }, { w = "涧", weight = nil, note = [=[例：椒江、清河、洛川、巢湖]=] },
        { w = "沟", weight = nil, note = [=[例：椒江、清河、洛川、巢湖]=] }, { w = "渠", weight = nil, note = [=[例：椒江、清河、洛川、巢湖]=] }, { w = "湖", weight = nil, note = [=[例：椒江、清河、洛川、巢湖]=] }, { w = "泊", weight = nil, note = [=[例：椒江、清河、洛川、巢湖]=] }, { w = "淀", weight = nil, note = [=[例：椒江、清河、洛川、巢湖]=] },
        { w = "池", weight = nil, note = [=[例：椒江、清河、洛川、巢湖]=] }, { w = "潭", weight = nil, note = [=[例：椒江、清河、洛川、巢湖]=] }, { w = "泉", weight = nil, note = [=[例：椒江、清河、洛川、巢湖]=] }, { w = "井", weight = nil, note = [=[例：椒江、清河、洛川、巢湖]=] },
        { w = "洲", weight = nil, note = [=[例：瓜洲、采石矶、黄浦]=] }, { w = "渚", weight = nil, note = [=[例：瓜洲、采石矶、黄浦]=] }, { w = "滩", weight = nil, note = [=[例：瓜洲、采石矶、黄浦]=] }, { w = "矶", weight = nil, note = [=[例：瓜洲、采石矶、黄浦]=] }, { w = "浦", weight = nil, note = [=[例：瓜洲、采石矶、黄浦]=] },
        { w = "泾", weight = nil, note = [=[例：瓜洲、采石矶、黄浦]=] }, { w = "陂", weight = nil, note = [=[例：瓜洲、采石矶、黄浦]=] },
      },
      -- 地形地貌
      terrain = {
        { w = "坪", weight = nil, note = [=[分布见通名表]=] }, { w = "塬", weight = nil, note = [=[分布见通名表]=] }, { w = "坝", weight = nil, note = [=[分布见通名表]=] }, { w = "冲", weight = nil, note = [=[分布见通名表]=] }, { w = "坳", weight = nil, note = [=[分布见通名表]=] },
        { w = "垄", weight = nil, note = [=[分布见通名表]=] }, { w = "塅", weight = nil, note = [=[分布见通名表]=] }, { w = "畈", weight = nil, note = [=[分布见通名表]=] }, { w = "垸", weight = nil, note = [=[分布见通名表]=] }, { w = "塘", weight = nil, note = [=[分布见通名表]=] },
        { w = "堰", weight = nil, note = [=[分布见通名表]=] }, { w = "陂", weight = nil, note = [=[分布见通名表]=] }, { w = "滩", weight = nil, note = [=[分布见通名表]=] }, { w = "矶", weight = nil, note = [=[分布见通名表]=] }, { w = "坎", weight = nil, note = [=[分布见通名表]=] },
        { w = "槽", weight = nil, note = [=[分布见通名表]=] }, { w = "垭", weight = nil, note = [=[分布见通名表]=] }, { w = "氹", weight = nil, note = [=[分布见通名表]=] },
      },
      -- 方位（含山水阴阳）
      direction = {
        { w = "东", weight = nil, note = [=[现代一律前置（东山、西湖）；古雅可后置（江左、江西）]=] }, { w = "西", weight = nil, note = [=[现代一律前置（东山、西湖）；古雅可后置（江左、江西）]=] }, { w = "南", weight = nil, note = [=[现代一律前置（东山、西湖）；古雅可后置（江左、江西）]=] }, { w = "北", weight = nil, note = [=[现代一律前置（东山、西湖）；古雅可后置（江左、江西）]=] }, { w = "中", weight = nil, note = [=[现代一律前置（东山、西湖）；古雅可后置（江左、江西）]=] },
        { w = "上", weight = nil, note = [=[现代一律前置（东山、西湖）；古雅可后置（江左、江西）]=] }, { w = "下", weight = nil, note = [=[现代一律前置（东山、西湖）；古雅可后置（江左、江西）]=] }, { w = "内", weight = nil, note = [=[现代一律前置（东山、西湖）；古雅可后置（江左、江西）]=] }, { w = "外", weight = nil, note = [=[现代一律前置（东山、西湖）；古雅可后置（江左、江西）]=] }, { w = "前", weight = nil, note = [=[现代一律前置（东山、西湖）；古雅可后置（江左、江西）]=] },
        { w = "后", weight = nil, note = [=[现代一律前置（东山、西湖）；古雅可后置（江左、江西）]=] }, { w = "左", weight = nil, note = [=[现代一律前置（东山、西湖）；古雅可后置（江左、江西）]=] }, { w = "右", weight = nil, note = [=[现代一律前置（东山、西湖）；古雅可后置（江左、江西）]=] }, { w = "里", weight = nil, note = [=[现代一律前置（东山、西湖）；古雅可后置（江左、江西）]=] }, { w = "表", weight = nil, note = [=[现代一律前置（东山、西湖）；古雅可后置（江左、江西）]=] },
        { w = "首", weight = nil, note = [=[现代一律前置（东山、西湖）；古雅可后置（江左、江西）]=] }, { w = "尾", weight = nil, note = [=[现代一律前置（东山、西湖）；古雅可后置（江左、江西）]=] },
        { w = "阳", weight = nil, note = [=[山南水北为阳、山北水南为阴]=] }, { w = "阴", weight = nil, note = [=[山南水北为阳、山北水南为阴]=] },
      },
      -- 物产与植被
      plant = {
        { w = "柳", weight = nil, note = [=[例：柳州、松江、樟树、桂林]=] }, { w = "松", weight = nil, note = [=[例：柳州、松江、樟树、桂林]=] }, { w = "柏", weight = nil, note = [=[例：柳州、松江、樟树、桂林]=] }, { w = "槐", weight = nil, note = [=[例：柳州、松江、樟树、桂林]=] }, { w = "樟", weight = nil, note = [=[例：柳州、松江、樟树、桂林]=] },
        { w = "枫", weight = nil, note = [=[例：柳州、松江、樟树、桂林]=] }, { w = "桐", weight = nil, note = [=[例：柳州、松江、樟树、桂林]=] }, { w = "杨", weight = nil, note = [=[例：柳州、松江、樟树、桂林]=] }, { w = "榕", weight = nil, note = [=[例：柳州、松江、樟树、桂林]=] }, { w = "椰", weight = nil, note = [=[例：柳州、松江、樟树、桂林]=] },
        { w = "桑", weight = nil, note = [=[例：柳州、松江、樟树、桂林]=] }, { w = "枣", weight = nil, note = [=[例：柳州、松江、樟树、桂林]=] }, { w = "梨", weight = nil, note = [=[例：柳州、松江、樟树、桂林]=] }, { w = "茶", weight = nil, note = [=[例：柳州、松江、樟树、桂林]=] }, { w = "竹", weight = nil, note = [=[例：柳州、松江、樟树、桂林]=] },
        { w = "梅", weight = nil, note = [=[例：柳州、松江、樟树、桂林]=] }, { w = "桂", weight = nil, note = [=[例：柳州、松江、樟树、桂林]=] },
        { w = "莲", weight = nil, note = [=[例：莲花、兰溪、桃源、芷江]=] }, { w = "荷", weight = nil, note = [=[例：莲花、兰溪、桃源、芷江]=] }, { w = "兰", weight = nil, note = [=[例：莲花、兰溪、桃源、芷江]=] }, { w = "菊", weight = nil, note = [=[例：莲花、兰溪、桃源、芷江]=] }, { w = "桃", weight = nil, note = [=[例：莲花、兰溪、桃源、芷江]=] },
        { w = "杏", weight = nil, note = [=[例：莲花、兰溪、桃源、芷江]=] }, { w = "荔", weight = nil, note = [=[例：莲花、兰溪、桃源、芷江]=] }, { w = "蒲", weight = nil, note = [=[例：莲花、兰溪、桃源、芷江]=] }, { w = "芦", weight = nil, note = [=[例：莲花、兰溪、桃源、芷江]=] }, { w = "芷", weight = nil, note = [=[例：莲花、兰溪、桃源、芷江]=] },
        { w = "蓼", weight = nil, note = [=[例：莲花、兰溪、桃源、芷江]=] }, { w = "茅", weight = nil, note = [=[例：莲花、兰溪、桃源、芷江]=] },
      },
      -- 历史政区与古国（古国 + 古九州 + 古郡县）
      ancient_state = {
        { w = "吴", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "越", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "楚", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "秦", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "晋", weight = nil, note = [=[例：吴县、晋阳、滕州]=] },
        { w = "齐", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "鲁", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "燕", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "韩", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "赵", weight = nil, note = [=[例：吴县、晋阳、滕州]=] },
        { w = "魏", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "宋", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "陈", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "蔡", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "郑", weight = nil, note = [=[例：吴县、晋阳、滕州]=] },
        { w = "卫", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "曹", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "莒", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "邾", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "滕", weight = nil, note = [=[例：吴县、晋阳、滕州]=] },
        { w = "薛", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "邓", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "黄", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "蓼", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "六", weight = nil, note = [=[例：吴县、晋阳、滕州]=] },
        { w = "巢", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "舒", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "皖", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "郧", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "鄢", weight = nil, note = [=[例：吴县、晋阳、滕州]=] },
        { w = "邛", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "蜀", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "巴", weight = nil, note = [=[例：吴县、晋阳、滕州]=] }, { w = "滇", weight = nil, note = [=[例：吴县、晋阳、滕州]=] },
        { w = "冀", weight = nil, note = [=[例：兖州、扬州、徐州]=] }, { w = "兖", weight = nil, note = [=[例：兖州、扬州、徐州]=] }, { w = "青", weight = nil, note = [=[例：兖州、扬州、徐州]=] }, { w = "徐", weight = nil, note = [=[例：兖州、扬州、徐州]=] }, { w = "扬", weight = nil, note = [=[例：兖州、扬州、徐州]=] },
        { w = "荆", weight = nil, note = [=[例：兖州、扬州、徐州]=] }, { w = "豫", weight = nil, note = [=[例：兖州、扬州、徐州]=] }, { w = "梁", weight = nil, note = [=[例：兖州、扬州、徐州]=] }, { w = "雍", weight = nil, note = [=[例：兖州、扬州、徐州]=] }, { w = "幽", weight = nil, note = [=[例：兖州、扬州、徐州]=] },
        { w = "并", weight = nil, note = [=[例：兖州、扬州、徐州]=] }, { w = "益", weight = nil, note = [=[例：兖州、扬州、徐州]=] }, { w = "凉", weight = nil, note = [=[例：兖州、扬州、徐州]=] }, { w = "交", weight = nil, note = [=[例：兖州、扬州、徐州]=] },
        { w = "会稽", weight = nil, note = [=[余姚/句容/无锡 越吴语底层，词源存疑]=] }, { w = "琅琊", weight = nil, note = [=[余姚/句容/无锡 越吴语底层，词源存疑]=] }, { w = "太原", weight = nil, note = [=[余姚/句容/无锡 越吴语底层，词源存疑]=] }, { w = "汝南", weight = nil, note = [=[余姚/句容/无锡 越吴语底层，词源存疑]=] }, { w = "颍川", weight = nil, note = [=[余姚/句容/无锡 越吴语底层，词源存疑]=] },
        { w = "南阳", weight = nil, note = [=[余姚/句容/无锡 越吴语底层，词源存疑]=] }, { w = "涿", weight = nil, note = [=[余姚/句容/无锡 越吴语底层，词源存疑]=] }, { w = "涪", weight = nil, note = [=[余姚/句容/无锡 越吴语底层，词源存疑]=] }, { w = "蓟", weight = nil, note = [=[余姚/句容/无锡 越吴语底层，词源存疑]=] }, { w = "邺", weight = nil, note = [=[余姚/句容/无锡 越吴语底层，词源存疑]=] },
        { w = "郢", weight = nil, note = [=[余姚/句容/无锡 越吴语底层，词源存疑]=] }, { w = "姑蔑", weight = nil, note = [=[余姚/句容/无锡 越吴语底层，词源存疑]=] }, { w = "余姚", weight = nil, note = [=[余姚/句容/无锡 越吴语底层，词源存疑]=], suspicious = true }, { w = "句容", weight = nil, note = [=[余姚/句容/无锡 越吴语底层，词源存疑]=], suspicious = true }, { w = "无锡", weight = nil, note = [=[余姚/句容/无锡 越吴语底层，词源存疑]=], suspicious = true },
      },
      -- 军事屯戍
      garrison = {
        { w = "卫", weight = nil, note = [=[例：天津卫、张家寨、雁门关]=] }, { w = "所", weight = nil, note = [=[例：天津卫、张家寨、雁门关]=] }, { w = "营", weight = nil, note = [=[例：天津卫、张家寨、雁门关]=] }, { w = "屯", weight = nil, note = [=[例：天津卫、张家寨、雁门关]=] }, { w = "堡", weight = nil, note = [=[例：天津卫、张家寨、雁门关]=] },
        { w = "寨", weight = nil, note = [=[例：天津卫、张家寨、雁门关]=] }, { w = "关", weight = nil, note = [=[例：天津卫、张家寨、雁门关]=] }, { w = "隘", weight = nil, note = [=[例：天津卫、张家寨、雁门关]=] }, { w = "卡", weight = nil, note = [=[例：天津卫、张家寨、雁门关]=] }, { w = "哨", weight = nil, note = [=[例：天津卫、张家寨、雁门关]=] },
        { w = "墩", weight = nil, note = [=[例：天津卫、张家寨、雁门关]=] }, { w = "台", weight = nil, note = [=[例：天津卫、张家寨、雁门关]=] },
      },
      -- 交通驿传
      post = {
        { w = "驿", weight = nil, note = [=[例：龙泉驿、风陵渡、天津]=] }, { w = "铺", weight = nil, note = [=[例：龙泉驿、风陵渡、天津]=] }, { w = "站", weight = nil, note = [=[例：龙泉驿、风陵渡、天津]=] }, { w = "塘", weight = nil, note = [=[例：龙泉驿、风陵渡、天津]=] }, { w = "汛", weight = nil, note = [=[例：龙泉驿、风陵渡、天津]=] },
        { w = "渡", weight = nil, note = [=[例：龙泉驿、风陵渡、天津]=] }, { w = "津", weight = nil, note = [=[例：龙泉驿、风陵渡、天津]=] }, { w = "桥", weight = nil, note = [=[例：龙泉驿、风陵渡、天津]=] }, { w = "梁", weight = nil, note = [=[例：龙泉驿、风陵渡、天津]=] }, { w = "埠", weight = nil, note = [=[例：龙泉驿、风陵渡、天津]=] },
      },
      -- 商贸市集
      market = {
        { w = "集", weight = nil, note = [=[例：辛集、沙市、驻马店、牛场]=] }, { w = "市", weight = nil, note = [=[例：辛集、沙市、驻马店、牛场]=] }, { w = "店", weight = nil, note = [=[例：辛集、沙市、驻马店、牛场]=] }, { w = "铺", weight = nil, note = [=[例：辛集、沙市、驻马店、牛场]=] }, { w = "坊", weight = nil, note = [=[例：辛集、沙市、驻马店、牛场]=] },
        { w = "墟", weight = nil, note = [=[例：辛集、沙市、驻马店、牛场]=] }, { w = "圩", weight = nil, note = [=[例：辛集、沙市、驻马店、牛场]=] }, { w = "场", weight = nil, note = [=[例：辛集、沙市、驻马店、牛场]=] }, { w = "街", weight = nil, note = [=[例：辛集、沙市、驻马店、牛场]=] },
      },
      -- 姓氏宗族（含复姓）
      surname = {
        { w = "张", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "王", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "李", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "赵", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "刘", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "陈", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "杨", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "黄", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "周", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "吴", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "徐", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "孙", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "胡", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "朱", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "高", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "林", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "何", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "郭", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "马", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "罗", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "梁", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "宋", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "郑", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "谢", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "韩", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "唐", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "冯", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "于", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "董", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "萧", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "程", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "曹", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "袁", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "邓", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "许", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "傅", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "沈", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "曾", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "彭", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "吕", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "苏", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "卢", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "蒋", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "蔡", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "贾", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "丁", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "魏", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "薛", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "叶", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "阎", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "余", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "潘", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "杜", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "戴", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "夏", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "钟", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "汪", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "田", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "任", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "姜", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "范", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "方", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "石", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "姚", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "谭", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "廖", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "邹", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "熊", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "金", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "陆", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "郝", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "孔", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "白", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "崔", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "康", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "毛", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "邱", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "秦", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "江", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "史", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "顾", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "侯", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "邵", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "孟", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "龙", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "万", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "段", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "雷", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "钱", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "汤", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "尹", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "黎", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "易", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "常", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "武", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "乔", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "贺", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "赖", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "龚", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] }, { w = "文", weight = nil, note = [=[配 家/庄/村/屯/营/店/堡/寨/屋/楼/宅]=] },
        { w = "欧阳", weight = nil, note = [=[例：诸葛村、司马村]=] }, { w = "诸葛", weight = nil, note = [=[例：诸葛村、司马村]=] }, { w = "司马", weight = nil, note = [=[例：诸葛村、司马村]=] },
      },
      -- 吉祥教化（年号另入 era_name）
      auspicious = {
        { w = "安", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "宁", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "平", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "定", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "靖", weight = nil, note = [=[例：长安、延安、保定、南昌]=] },
        { w = "绥", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "和", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "顺", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "昌", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "泰", weight = nil, note = [=[例：长安、延安、保定、南昌]=] },
        { w = "康", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "兴", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "永", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "新", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "德", weight = nil, note = [=[例：长安、延安、保定、南昌]=] },
        { w = "仁", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "义", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "礼", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "信", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "寿", weight = nil, note = [=[例：长安、延安、保定、南昌]=] },
        { w = "福", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "庆", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "恩", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "惠", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "祥", weight = nil, note = [=[例：长安、延安、保定、南昌]=] },
        { w = "瑞", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "吉", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "嘉", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "乐", weight = nil, note = [=[例：长安、延安、保定、南昌]=] }, { w = "清", weight = nil, note = [=[例：长安、延安、保定、南昌]=] },
        { w = "广", weight = nil, note = [=[例：长安、延安、保定、南昌]=] },
      },
      -- 年号
      era_name = {
        { w = "绍兴", weight = nil, note = [=[设县/州时以当朝年号命名]=] }, { w = "景德", weight = nil, note = [=[设县/州时以当朝年号命名]=] }, { w = "政和", weight = nil, note = [=[设县/州时以当朝年号命名]=] }, { w = "嘉定", weight = nil, note = [=[设县/州时以当朝年号命名]=] }, { w = "宝庆", weight = nil, note = [=[设县/州时以当朝年号命名]=] },
        { w = "庆元", weight = nil, note = [=[设县/州时以当朝年号命名]=] }, { w = "淳化", weight = nil, note = [=[设县/州时以当朝年号命名]=] }, { w = "景泰", weight = nil, note = [=[设县/州时以当朝年号命名]=] }, { w = "天宝", weight = nil, note = [=[设县/州时以当朝年号命名]=] }, { w = "广德", weight = nil, note = [=[设县/州时以当朝年号命名]=] },
        { w = "永昌", weight = nil, note = [=[设县/州时以当朝年号命名]=] }, { w = "元和", weight = nil, note = [=[设县/州时以当朝年号命名]=] },
      },
      -- 数字与顺序（里程另入 mileage）
      number = {
        { w = "一", weight = nil, note = [=[例：三门峡、九江、十堰]=] }, { w = "二", weight = nil, note = [=[例：三门峡、九江、十堰]=] }, { w = "三", weight = nil, note = [=[例：三门峡、九江、十堰]=] }, { w = "四", weight = nil, note = [=[例：三门峡、九江、十堰]=] }, { w = "五", weight = nil, note = [=[例：三门峡、九江、十堰]=] },
        { w = "六", weight = nil, note = [=[例：三门峡、九江、十堰]=] }, { w = "七", weight = nil, note = [=[例：三门峡、九江、十堰]=] }, { w = "八", weight = nil, note = [=[例：三门峡、九江、十堰]=] }, { w = "九", weight = nil, note = [=[例：三门峡、九江、十堰]=] }, { w = "十", weight = nil, note = [=[例：三门峡、九江、十堰]=] },
        { w = "双", weight = nil, note = [=[例：三门峡、九江、十堰]=] }, { w = "头", weight = nil, note = [=[例：汕头、水头、沙尾]=] }, { w = "尾", weight = nil, note = [=[例：汕头、水头、沙尾]=] }, { w = "上", weight = nil, note = [=[例：汕头、水头、沙尾]=] }, { w = "下", weight = nil, note = [=[例：汕头、水头、沙尾]=] },
      },
      -- 里程
      mileage = {
        { w = "五里", weight = nil, note = [=[配铺/店/桥/亭/墩]=] }, { w = "十里", weight = nil, note = [=[配铺/店/桥/亭/墩]=] }, { w = "二十里", weight = nil, note = [=[配铺/店/桥/亭/墩]=] }, { w = "三十里", weight = nil, note = [=[配铺/店/桥/亭/墩]=] },
      },
      -- 颜色（可前置修饰）
      color = {
        { w = "金", weight = nil, note = [=[例：白沙、青浦、黄浦]=] }, { w = "银", weight = nil, note = [=[例：白沙、青浦、黄浦]=] }, { w = "青", weight = nil, note = [=[例：白沙、青浦、黄浦]=] }, { w = "黄", weight = nil, note = [=[例：白沙、青浦、黄浦]=] }, { w = "白", weight = nil, note = [=[例：白沙、青浦、黄浦]=] },
        { w = "黑", weight = nil, note = [=[例：白沙、青浦、黄浦]=] }, { w = "赤", weight = nil, note = [=[例：白沙、青浦、黄浦]=] }, { w = "紫", weight = nil, note = [=[例：白沙、青浦、黄浦]=] }, { w = "翠", weight = nil, note = [=[例：白沙、青浦、黄浦]=] }, { w = "碧", weight = nil, note = [=[例：白沙、青浦、黄浦]=] },
      },
      -- 动宾首字（古雅地名）
      verb_head = {
        { w = "驻", weight = nil, note = [=[例：驻马店、望都、怀安；通名前置特例慎用]=] }, { w = "临", weight = nil, note = [=[例：驻马店、望都、怀安；通名前置特例慎用]=] }, { w = "望", weight = nil, note = [=[例：驻马店、望都、怀安；通名前置特例慎用]=] }, { w = "怀", weight = nil, note = [=[例：驻马店、望都、怀安；通名前置特例慎用]=] }, { w = "镇", weight = nil, note = [=[例：驻马店、望都、怀安；通名前置特例慎用]=] },
        { w = "靖", weight = nil, note = [=[例：驻马店、望都、怀安；通名前置特例慎用]=] }, { w = "安", weight = nil, note = [=[例：驻马店、望都、怀安；通名前置特例慎用]=] }, { w = "宁", weight = nil, note = [=[例：驻马店、望都、怀安；通名前置特例慎用]=] },
      },
      -- 单字专名核心总池（跨主题合并去重：山/水/地形/物产/古国/吉祥/动宾/颜色/数字）
      single = {
        { w = "山" }, { w = "岭" }, { w = "峰" }, { w = "岗" }, { w = "丘" }, { w = "岩" }, { w = "崖" }, { w = "岫" }, { w = "岑" }, { w = "崮" },
        { w = "江" }, { w = "河" }, { w = "川" }, { w = "溪" }, { w = "涧" }, { w = "沟" }, { w = "渠" }, { w = "湖" }, { w = "泊" }, { w = "淀" },
        { w = "池" }, { w = "潭" }, { w = "泉" }, { w = "井" }, { w = "洲" }, { w = "渚" }, { w = "滩" }, { w = "矶" }, { w = "浦" }, { w = "泾" },
        { w = "陂" }, { w = "坪" }, { w = "塬" }, { w = "坝" }, { w = "冲" }, { w = "坳" }, { w = "垄" }, { w = "塅" }, { w = "畈" }, { w = "垸" },
        { w = "塘" }, { w = "堰" }, { w = "坎" }, { w = "槽" }, { w = "垭" }, { w = "氹" },
        { w = "柳" }, { w = "松" }, { w = "柏" }, { w = "槐" }, { w = "樟" }, { w = "枫" }, { w = "桐" }, { w = "杨" }, { w = "榕" }, { w = "椰" },
        { w = "桑" }, { w = "枣" }, { w = "梨" }, { w = "茶" }, { w = "竹" }, { w = "梅" }, { w = "桂" }, { w = "莲" }, { w = "荷" }, { w = "兰" },
        { w = "菊" }, { w = "桃" }, { w = "杏" }, { w = "荔" }, { w = "蒲" }, { w = "芦" }, { w = "芷" }, { w = "蓼" }, { w = "茅" },
        { w = "吴" }, { w = "越" }, { w = "楚" }, { w = "秦" }, { w = "晋" }, { w = "齐" }, { w = "鲁" }, { w = "燕" }, { w = "韩" }, { w = "赵" },
        { w = "魏" }, { w = "宋" }, { w = "陈" }, { w = "蔡" }, { w = "郑" }, { w = "卫" }, { w = "曹" }, { w = "莒" }, { w = "邾" }, { w = "滕" },
        { w = "薛" }, { w = "邓" }, { w = "黄" }, { w = "蓼" }, { w = "六" }, { w = "巢" }, { w = "舒" }, { w = "皖" }, { w = "郧" }, { w = "鄢" },
        { w = "邛" }, { w = "蜀" }, { w = "巴" }, { w = "滇" }, { w = "冀" }, { w = "兖" }, { w = "青" }, { w = "徐" }, { w = "扬" }, { w = "荆" },
        { w = "豫" }, { w = "梁" }, { w = "雍" }, { w = "幽" }, { w = "并" }, { w = "益" }, { w = "凉" }, { w = "交" },
        { w = "安" }, { w = "宁" }, { w = "平" }, { w = "定" }, { w = "靖" }, { w = "绥" }, { w = "和" }, { w = "顺" }, { w = "昌" }, { w = "泰" },
        { w = "康" }, { w = "兴" }, { w = "永" }, { w = "新" }, { w = "德" }, { w = "仁" }, { w = "义" }, { w = "礼" }, { w = "信" }, { w = "寿" },
        { w = "福" }, { w = "庆" }, { w = "恩" }, { w = "惠" }, { w = "祥" }, { w = "瑞" }, { w = "吉" }, { w = "嘉" }, { w = "乐" }, { w = "清" },
        { w = "广" }, { w = "驻" }, { w = "临" }, { w = "望" }, { w = "怀" }, { w = "镇" },
        { w = "金" }, { w = "银" }, { w = "青" }, { w = "黄" }, { w = "白" }, { w = "黑" }, { w = "赤" }, { w = "紫" }, { w = "翠" }, { w = "碧" },
        { w = "一" }, { w = "二" }, { w = "三" }, { w = "四" }, { w = "五" }, { w = "六" }, { w = "七" }, { w = "八" }, { w = "九" }, { w = "十" },
        { w = "双" }, { w = "头" }, { w = "尾" }, { w = "上" }, { w = "下" },
      },
    },

    -- E. 音频与结构约束
    constraints = {
      [=[字数分布：2 字＝单字专名＋单字通名（县名绝对主体、城名高频）；3 字＝双字专名＋单字通名 / 姓氏＋家＋通名 / 数字＋通名（乡镇名主体、城名次之）；4 字少见（汉区多来自少数民族译音，不属本类）。]=],
      [=[平仄：通名尾字偏好平声收尾（州/阳/阴/关/津/庄/村/桥/塘/城/门/安/宁/平/昌/兴/河/溪/湖/山多为平声）；偏好平仄交错，2 字名常见「平平」「仄平」；避免同一声调三连、双声叠韵相邻、拗口。]=],
      [=[方位与山水次序：方位词现代一律前置（东山/西湖/北桥/南关）；古雅用法可后置（江左/江右/江东/江西）。]=],
      [=[阴阳强约束：前缀必为山名或水名，且须能自洽解释为「位于某山/水之南/北」。]=],
      [=[通名禁忌：同一通名不得自叠（县县/村村/州州/集集）；同义/同层级通名不得堆叠（县+镇、州+府）；双通名连用须语义复合（城关镇、堡寨、屯堡、塘汛、洲岛）。]=],
      [=[非法组合：区域与通名库不匹配即非法（见 A 第 3 条）。]=],
    },

    -- F. 语源对音表：不适用（纯汉语体系）
    translit = nil,
    translitNote = [=[不适用（本类为纯汉语体系）。原报告仅提及少量方言/古越语底层转音，无系统对音表：吴语通名字（浜、泾、浦、渎、浃、埭、𡍲）、粤语（涌、滘、塱/朗、埗、氹）、闽语（厝、寮、澳、屿、崙、坑、埔、埕）、湘赣（冲、垄、塅、塆）、川渝（坝、场、垭、槽、坎、碚）；越/侗台语底层字（番禺、姑苏、郁林）及转音例（辛集、白坭、大朗、深水埗），其中番禺、姑苏、辛集均标注存疑。]=],

    -- G. 负向约束与真实地名黑名单
    banned = {
      chars     = { "送", "终", "死", "亡", "败", "衰", "绝", "病", "灾", "劫", "瘟" },
      suffixes  = {},
      words     = { "世民", "玄烨", "弘历", "中山", "志丹" },
      realNames = { "金陵", "临安", "会稽", "汝南", "颍川", "石家庄", "景德镇", "周庄", "凤凰", "丽江", "长安", "南昌", "武汉", "南京", "成都" },
      rules = {
        [=[禁止/慎用字：与「送/终/死/亡/败/衰/绝/病/灾/劫/瘟」同音近音的不吉谐音；帝王名讳常用字（世民/玄烨/弘历等）古风语境慎用；1949 年起「不以人名作地名」（历史遗留人名地名如中山、志丹等仅作已知素材，不作生成）。]=],
        [=[禁止的通名组合：通名自叠、同层级堆叠（见 E）。]=],
        [=[区域-通名硬约束：江南不用涌/滘，岭南不用泾/浜（详见 A 第 3 条）。]=],
        [=[真实地名黑名单：全国县级以上政区名 + 历史著名府州郡县名（金陵、临安、会稽、汝南、颍川…）+ 知名乡镇/聚落名（石家庄、景德镇、周庄、凤凰、丽江…）；另须避与真实地名同音（规避与长安、南昌、武汉、南京、成都等同音近音）。]=],
        [=[市县同名：避免生成「X 市」与「X 县」同名造成混乱。]=],
      },
    },

    -- H. 生成算法要点
    algorithm = {
      [=[定地域 → 选定对应通名库（华北/江南/岭南/华中/西南/闽台 六亚型）。]=],
      [=[抽取专名 → 从专名部件表按来源抽取 1 个核心字/词。]=],
      [=[拼装 → 依 10 条构词规则（H1–H10）从 2–4 字骨架成词。]=],
      [=[过滤 → 过 8 道禁忌：撞真实地名、通名自叠/同层级堆叠、阴阳逻辑自洽、平仄（三同调/双声叠韵）、不吉谐音、避讳字、区域-通名匹配、去重。]=],
      [=[查真实地名表 + 输出去重（Set 去重、记录随机种子可复现）。]=],
    },
  },

  ---------------------------------------------------------------------------
  -- 海洋中国（南洋华人主导的东南亚港口与聚落）
  ---------------------------------------------------------------------------
  ocean = {

    style = {
      [=[通名用海贸词（港/埠/洲/屿/浦/澳/坡/叻/巴刹），而非中原的城/镇/州/县/堡/驿。]=],
      [=[专名密集出现热带物产字（椰/槟/榴莲/胡椒/沉香/苏木/锡/燕窝）。]=],
      [=[出现借词汉写音节（叻/曼/丹/坡/巴刹/布路/洛坤）。]=],
      [=[出现闽粤客方言字（厝/寮/坑/墟/围/涌/埗/岙），且按「帮口」分群（闽南/潮州/广府/客家/海南/福州）。]=],
      [=[双关雅化名（泗水/仰光/巨港/西贡——音近洋名、义近吉祥/地理），是最地道的「海洋中国」风格；另有三宝/大唐/妈祖/大伯公/公司等华人特有词作专名。]=],
    },

    templates = {
      { id = "O1", formula = [=[汉越吉祥式：吉祥字/主题字 + 吉祥字/地理字（2 字，可加行政通名）]=], seq = { "auspicious", "auspicious", "suffix" }, weight = nil, note = [=[新安、隆平、顺海、广南、嘉定；带通名：安平埠、富寿坊（通名可选）]=] }, --[[W?]]
      { id = "O2", formula = [=[海贸物产式：热带物产/海产/海贸字 + 通名（2–3 字）]=], seq = { "plant", "suffix" }, weight = nil, note = [=[槟榔屿、胡椒港、锡港、椰港、珠澳、燕窝岛]=] }, --[[W?]]
      { id = "O3", formula = [=[音译雅化式：音首音节 → 谐音 2 字 → 雅化（2–4 字）]=], seq = nil, weight = nil, note = [=[报告标注「最难、最地道」；模板：Surabaya→泗水、Yangon→仰光、Palembang→巨港（使用 translit 表）]=] }, --[[W?]]
      { id = "gen", formula = [=[（通用公式）[吉祥字/物产/海贸字] + [正式通名]，或 [谐音双字] + [雅化通名]]=], seq = { "single", "suffix" }, weight = nil, note = [=[一页速查公式]=] }, --[[W?]]
    },

    suffixes = {
      -- 汉语固有通名（正式聚落名）
      { w = "港", etymon = [=[海港/河港]=], scene = [=[一级港口城]=], weight = nil, note = [=[巨港、岘港、三宝港]=], group = "chinese" }, --[[W?]]
      { w = "埠", etymon = [=[码头/商埠]=], scene = [=[商埠]=], weight = nil, note = [=[新埠、石叻埠]=], group = "chinese" }, --[[W?]]
      { w = "埠头", etymon = [=[码头聚落]=], scene = [=[港市分区]=], weight = nil, note = [=[老埠头、新埠头（坤甸、山口洋）]=], group = "chinese" }, --[[W?]]
      { w = "澳", etymon = [=[海湾可泊处]=], scene = [=[小海湾港]=], weight = nil, note = [=[闽粤沿海惯例]=], group = "chinese" }, --[[W?]]
      { w = "湾", etymon = [=[海湾]=], scene = [=[滨海聚落]=], weight = nil, note = [=[各类 XX 湾]=], group = "chinese" }, --[[W?]]
      { w = "浦", etymon = [=[水滨]=], scene = [=[江口聚落]=], weight = nil, note = [=[南浦、林邑浦]=], group = "chinese" }, --[[W?]]
      { w = "津 / 渡", etymon = [=[渡口]=], scene = [=[渡口小聚落]=], weight = nil, note = nil, group = "chinese" }, --[[W?]]
      { w = "洲", etymon = [=[水中沙洲/海岛]=], scene = [=[岛城]=], weight = nil, note = [=[星洲、河洲县]=], group = "chinese" }, --[[W?]]
      { w = "屿", etymon = [=[小岛]=], scene = [=[海岛]=], weight = nil, note = [=[槟榔屿、鹿屿]=], group = "chinese" }, --[[W?]]
      { w = "岙", etymon = [=[山间海湾（闽浙）]=], scene = [=[背山面海小港]=], weight = nil, note = nil, group = "chinese" }, --[[W?]]
      { w = "寮", etymon = [=[棚屋/工棚]=], scene = [=[矿场、垦场]=], weight = nil, note = nil, group = "chinese" }, --[[W?]]
      { w = "厝", etymon = [=[房屋（闽南）]=], scene = [=[闽南帮村落]=], weight = nil, note = nil, group = "chinese" }, --[[W?]]
      { w = "冈 / 岗", etymon = [=[山岗]=], scene = [=[高地聚落]=], weight = nil, note = nil, group = "chinese" }, --[[W?]]
      { w = "京", etymon = [=[京城/首都]=], scene = [=[首都雅称]=], weight = nil, note = [=[暹京、泰京]=], group = "chinese" }, --[[W?]]
      -- 借词汉写通名
      { w = "坡", etymon = [=[-pur / Lumpur（城/泥）]=], scene = [=[口语/别称]=], weight = nil, note = [=[新加坡、吉隆坡、石叻坡]=], group = "loanword" }, --[[W?]]
      { w = "叻", etymon = [=[Selat（海峡）]=], scene = [=[口语/别称]=], weight = nil, note = [=[石叻、叻埠]=], group = "loanword" }, --[[W?]]
      { w = "巴刹", etymon = [=[pasar（市场）]=], scene = [=[市集名]=], weight = nil, note = nil, group = "loanword" }, --[[W?]]
      { w = "公司", etymon = [=[kongsi（会党/矿场组织）]=], scene = [=[会党组织名]=], weight = nil, note = [=[兰芳公司、和顺公司]=], group = "loanword" }, --[[W?]]
      { w = "丹绒", etymon = [=[Tanjung（海角）]=], scene = [=[海角专名]=], weight = nil, note = [=[丹绒本纳加]=], group = "loanword" }, --[[W?]]
      { w = "布路 / 浮罗", etymon = [=[Pulau（岛）]=], scene = [=[岛专名]=], weight = nil, note = [=[布路槟榔]=], group = "loanword" }, --[[W?]]
      { w = "洛坤 / 六坤", etymon = [=[Nakhon（城）]=], scene = [=[城专名]=], weight = nil, note = [=[洛坤]=], group = "loanword" }, --[[W?]]
      { w = "曼", etymon = [=[Bang（河畔聚落）]=], scene = [=[河畔聚落专名]=], weight = nil, note = [=[曼谷]=], group = "loanword" }, --[[W?]]
      -- 越南式行政通名
      { w = "城庯", etymon = [=[thành phố（城市，字面「城＋街市」）]=], scene = [=[市]=], weight = nil, note = [=[河仙市＝城庯河僊]=], group = "vietnamese" }, --[[W?]]
      { w = "市社", etymon = [=[thị xã（市镇/县级市）]=], scene = [=[县级市]=], weight = nil, note = [=[会安市社]=], group = "vietnamese" }, --[[W?]]
      { w = "县", etymon = [=[huyện]=], scene = [=[县]=], weight = nil, note = [=[坚良县]=], group = "vietnamese" }, --[[W?]]
      { w = "社", etymon = [=[xã]=], scene = [=[乡/社]=], weight = nil, note = [=[顺安社、仙海社]=], group = "vietnamese" }, --[[W?]]
      { w = "坊", etymon = [=[phường]=], scene = [=[城区坊]=], weight = nil, note = [=[平山坊、东湖坊]=], group = "vietnamese" }, --[[W?]]
      { w = "省", etymon = [=[tỉnh]=], scene = [=[省]=], weight = nil, note = [=[广南省]=], group = "vietnamese" }, --[[W?]]
      { w = "庯", etymon = [=[phố（街市/店铺）]=], scene = [=[街市]=], weight = nil, note = [=[锦铺坊（Cẩm Phô）]=], group = "vietnamese" }, --[[W?]]
    },

    -- 自然地理类通名（汉语固有通名中的自然类，供地形通名使用）
    terrain_suffix = {
      { w = "港", weight = nil, note = [=[巨港、岘港、三宝港]=] }, --[[W?]]
      { w = "埠", weight = nil, note = [=[新埠、石叻埠]=] }, --[[W?]]
      { w = "澳", weight = nil, note = [=[闽粤沿海惯例]=] }, --[[W?]]
      { w = "湾", weight = nil, note = [=[各类 XX 湾]=] }, --[[W?]]
      { w = "浦", weight = nil, note = [=[南浦、林邑浦]=] }, --[[W?]]
      { w = "津 / 渡", weight = nil, note = nil }, --[[W?]]
      { w = "洲", weight = nil, note = [=[星洲、河洲县]=] }, --[[W?]]
      { w = "屿", weight = nil, note = [=[槟榔屿、鹿屿]=] }, --[[W?]]
      { w = "岙", weight = nil, note = nil }, --[[W?]]
      { w = "冈 / 岗", weight = nil, note = nil }, --[[W?]]
    },

    -- 吉祥通名（源 auspicious 池「汉越吉祥式主力」）
    auspicious_suffix = {
      { w = "新", weight = nil, note = nil }, --[[W?]]
      { w = "安", weight = nil, note = nil }, --[[W?]]
      { w = "隆", weight = nil, note = nil }, --[[W?]]
      { w = "平", weight = nil, note = nil }, --[[W?]]
      { w = "顺", weight = nil, note = nil }, --[[W?]]
      { w = "泰", weight = nil, note = nil }, --[[W?]]
      { w = "和", weight = nil, note = nil }, --[[W?]]
      { w = "永", weight = nil, note = nil }, --[[W?]]
      { w = "福", weight = nil, note = nil }, --[[W?]]
      { w = "禄", weight = nil, note = nil }, --[[W?]]
      { w = "光", weight = nil, note = nil }, --[[W?]]
      { w = "华", weight = nil, note = nil }, --[[W?]]
      { w = "富", weight = nil, note = nil }, --[[W?]]
      { w = "贵", weight = nil, note = nil }, --[[W?]]
      { w = "兴", weight = nil, note = nil }, --[[W?]]
      { w = "明", weight = nil, note = nil }, --[[W?]]
      { w = "清", weight = nil, note = nil }, --[[W?]]
      { w = "荣", weight = nil, note = nil }, --[[W?]]
      { w = "嘉", weight = nil, note = nil }, --[[W?]]
      { w = "定", weight = nil, note = nil }, --[[W?]]
      { w = "会", weight = nil, note = nil }, --[[W?]]
      { w = "义", weight = nil, note = nil }, --[[W?]]
      { w = "仁", weight = nil, note = nil }, --[[W?]]
      { w = "德", weight = nil, note = nil }, --[[W?]]
      { w = "信", weight = nil, note = nil }, --[[W?]]
    },

    parts = {
      -- 海贸与舟船 → market
      market = {
        { w = "船", weight = nil, note = nil }, { w = "帆", weight = nil, note = nil }, { w = "舵", weight = nil, note = nil }, { w = "锚", weight = nil, note = nil }, { w = "舶", weight = nil, note = nil },
        { w = "舟", weight = nil, note = nil }, { w = "艚", weight = nil, note = nil }, { w = "艋", weight = nil, note = nil }, { w = "缆", weight = nil, note = nil }, { w = "桅", weight = nil, note = nil },
        { w = "篷", weight = nil, note = nil }, { w = "桨", weight = nil, note = nil }, { w = "货", weight = nil, note = nil }, { w = "栈", weight = nil, note = nil }, { w = "市", weight = nil, note = nil },
        { w = "墟", weight = nil, note = nil },
      },
      -- 海产 → plant（物产）
      plant = {
        { w = "鲛", weight = nil, note = nil }, { w = "鲸", weight = nil, note = nil }, { w = "蚌", weight = nil, note = nil }, { w = "珠", weight = nil, note = nil }, { w = "珊瑚", weight = nil, note = nil },
        { w = "玳瑁", weight = nil, note = nil }, { w = "鲍", weight = nil, note = nil }, { w = "鲎", weight = nil, note = nil }, { w = "螺", weight = nil, note = nil }, { w = "蚝", weight = nil, note = nil },
        { w = "贝", weight = nil, note = nil }, { w = "虾", weight = nil, note = nil }, { w = "蟹", weight = nil, note = nil }, { w = "鲟", weight = nil, note = nil }, { w = "鲤", weight = nil, note = nil },
        -- 热带物产
        { w = "椰", weight = nil, note = nil }, { w = "槟榔", weight = nil, note = nil }, { w = "榴莲", weight = nil, note = nil }, { w = "蔗", weight = nil, note = nil }, { w = "椒", weight = nil, note = nil },
        { w = "豆蔻", weight = nil, note = nil }, { w = "沉香", weight = nil, note = nil }, { w = "檀", weight = nil, note = nil }, { w = "苏木", weight = nil, note = nil }, { w = "藤", weight = nil, note = nil },
        { w = "橡胶", weight = nil, note = nil }, { w = "锡", weight = nil, note = nil }, { w = "金", weight = nil, note = nil }, { w = "燕窝", weight = nil, note = nil }, { w = "漆", weight = nil, note = nil },
        { w = "榕", weight = nil, note = nil }, { w = "红毛丹", weight = nil, note = nil }, { w = "山竹", weight = nil, note = nil },
      },
      -- 潮汐与洋流 → water
      water = {
        { w = "潮", weight = nil, note = nil }, { w = "汐", weight = nil, note = nil }, { w = "汛", weight = nil, note = nil }, { w = "涨", weight = nil, note = nil }, { w = "退", weight = nil, note = nil },
        { w = "涛", weight = nil, note = nil }, { w = "澜", weight = nil, note = nil }, { w = "浪", weight = nil, note = nil }, { w = "涌", weight = nil, note = nil }, { w = "流", weight = nil, note = nil },
        -- 季风与信风
        { w = "风", weight = nil, note = nil }, { w = "信", weight = nil, note = nil }, { w = "帆", weight = nil, note = nil }, { w = "候", weight = nil, note = nil }, { w = "洋", weight = nil, note = nil },
      },
      -- 岛礁沙洲地貌 → terrain
      terrain = {
        { w = "屿", weight = nil, note = nil }, { w = "洲", weight = nil, note = nil }, { w = "沙", weight = nil, note = nil }, { w = "礁", weight = nil, note = nil }, { w = "滩", weight = nil, note = nil },
        { w = "浅", weight = nil, note = nil }, { w = "埕", weight = nil, note = nil }, { w = "渚", weight = nil, note = nil }, { w = "矶", weight = nil, note = nil }, { w = "岬", weight = nil, note = nil },
        { w = "岙", weight = nil, note = nil },
      },
      -- 华人信仰
      faith = {
        { w = "妈祖", weight = nil, note = [=[派生式：××妈祖庙/天后宫→缩为妈祖港、天后澳、三宝垄]=] }, { w = "天后", weight = nil, note = [=[派生式：××妈祖庙/天后宫→缩为妈祖港、天后澳、三宝垄]=] }, { w = "观音", weight = nil, note = [=[派生式：××妈祖庙/天后宫→缩为妈祖港、天后澳、三宝垄]=] }, { w = "关帝", weight = nil, note = [=[派生式：××妈祖庙/天后宫→缩为妈祖港、天后澳、三宝垄]=] }, { w = "关公", weight = nil, note = [=[派生式：××妈祖庙/天后宫→缩为妈祖港、天后澳、三宝垄]=] },
        { w = "大伯公", weight = nil, note = [=[派生式：××妈祖庙/天后宫→缩为妈祖港、天后澳、三宝垄]=] }, { w = "清水祖师", weight = nil, note = [=[派生式：××妈祖庙/天后宫→缩为妈祖港、天后澳、三宝垄]=] }, { w = "三宝", weight = nil, note = [=[派生式：××妈祖庙/天后宫→缩为妈祖港、天后澳、三宝垄]=] }, { w = "天妃", weight = nil, note = [=[派生式：××妈祖庙/天后宫→缩为妈祖港、天后澳、三宝垄]=] }, { w = "王爷", weight = nil, note = [=[派生式：××妈祖庙/天后宫→缩为妈祖港、天后澳、三宝垄]=] },
        { w = "水仙", weight = nil, note = [=[派生式：××妈祖庙/天后宫→缩为妈祖港、天后澳、三宝垄]=] }, { w = "福德", weight = nil, note = [=[派生式：××妈祖庙/天后宫→缩为妈祖港、天后澳、三宝垄]=] },
      },
      -- 吉祥字
      auspicious = {
        { w = "新", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "安", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "隆", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "平", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "顺", weight = nil, note = [=[汉越吉祥式主力]=] },
        { w = "泰", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "和", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "永", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "福", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "禄", weight = nil, note = [=[汉越吉祥式主力]=] },
        { w = "光", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "华", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "富", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "贵", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "兴", weight = nil, note = [=[汉越吉祥式主力]=] },
        { w = "明", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "清", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "荣", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "嘉", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "定", weight = nil, note = [=[汉越吉祥式主力]=] },
        { w = "会", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "义", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "仁", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "德", weight = nil, note = [=[汉越吉祥式主力]=] }, { w = "信", weight = nil, note = [=[汉越吉祥式主力]=] },
      },
      -- 方位/规模
      direction = {
        { w = "大", weight = nil, note = nil }, { w = "中", weight = nil, note = nil }, { w = "东", weight = nil, note = nil }, { w = "南", weight = nil, note = nil }, { w = "西", weight = nil, note = nil },
        { w = "北", weight = nil, note = nil }, { w = "上", weight = nil, note = nil }, { w = "下", weight = nil, note = nil }, { w = "旧", weight = nil, note = nil }, { w = "新", weight = nil, note = nil },
        { w = "巨", weight = nil, note = nil }, { w = "小", weight = nil, note = nil },
      },
      -- 宗族与方言群命名偏好（分帮）
      dialect = {
        { w = "厝", weight = nil, note = [=[闽南帮偏好字，「××厝/××洋」，大伯公]=] }, { w = "寮", weight = nil, note = [=[闽南帮偏好字，「××厝/××洋」，大伯公]=] }, { w = "洋", weight = nil, note = [=[闽南帮偏好字，「××厝/××洋」，大伯公]=] }, { w = "垵", weight = nil, note = [=[闽南帮偏好字，「××厝/××洋」，大伯公]=] }, { w = "礁", weight = nil, note = [=[闽南帮偏好字，「××厝/××洋」，大伯公]=] },
        { w = "埕", weight = nil, note = [=[闽南帮偏好字，「××厝/××洋」，大伯公]=] }, { w = "澳", weight = nil, note = [=[闽南帮偏好字，「××厝/××洋」，大伯公]=] },
        { w = "埠头", weight = nil, note = [=[潮州帮偏好字，「××埠头」，潮阳/揭阳音对音]=] }, { w = "港", weight = nil, note = [=[潮州帮偏好字，「××埠头」，潮阳/揭阳音对音]=] }, { w = "寨", weight = nil, note = [=[潮州帮偏好字，「××埠头」，潮阳/揭阳音对音]=] }, { w = "市", weight = nil, note = [=[潮州帮偏好字，「××埠头」，潮阳/揭阳音对音]=] },
        { w = "墟", weight = nil, note = [=[广府帮偏好字，「××墟/××涌」]=] }, { w = "围", weight = nil, note = [=[广府帮偏好字，「××墟/××涌」]=] }, { w = "涌", weight = nil, note = [=[广府帮偏好字，「××墟/××涌」]=] }, { w = "埗", weight = nil, note = [=[广府帮偏好字，「××墟/××涌」]=] }, { w = "澳", weight = nil, note = [=[广府帮偏好字，「××墟/××涌」]=] },
        { w = "坑", weight = nil, note = [=[客家帮偏好字，「××坑/××围」，河婆话，公司]=] }, { w = "屋", weight = nil, note = [=[客家帮偏好字，「××坑/××围」，河婆话，公司]=] }, { w = "围", weight = nil, note = [=[客家帮偏好字，「××坑/××围」，河婆话，公司]=] }, { w = "岗", weight = nil, note = [=[客家帮偏好字，「××坑/××围」，河婆话，公司]=] }, { w = "峯", weight = nil, note = [=[客家帮偏好字，「××坑/××围」，河婆话，公司]=] },
        { w = "洋", weight = nil, note = [=[客家帮偏好字，「××坑/××围」，河婆话，公司]=] },
        { w = "坡", weight = nil, note = [=[海南帮偏好字，「××坡」]=] }, { w = "港", weight = nil, note = [=[海南帮偏好字，「××坡」]=] }, { w = "市", weight = nil, note = [=[海南帮偏好字，「××坡」]=] },
        { w = "厝", weight = nil, note = [=[福州帮偏好字，「××屿/××澳」]=] }, { w = "屿", weight = nil, note = [=[福州帮偏好字，「××屿/××澳」]=] }, { w = "澳", weight = nil, note = [=[福州帮偏好字，「××屿/××澳」]=] },
      },
      -- 单字专名核心总池（海洋中国：物产/海贸/水文/岛礁/吉祥/方位 单字合并）
      single = {
        { w = "船" }, { w = "帆" }, { w = "舵" }, { w = "锚" }, { w = "舶" }, { w = "舟" }, { w = "艚" }, { w = "艋" }, { w = "缆" }, { w = "桅" },
        { w = "篷" }, { w = "桨" }, { w = "货" }, { w = "栈" }, { w = "市" }, { w = "墟" },
        { w = "鲛" }, { w = "鲸" }, { w = "蚌" }, { w = "珠" }, { w = "珊瑚" }, { w = "玳瑁" }, { w = "鲍" }, { w = "鲎" }, { w = "螺" }, { w = "蚝" },
        { w = "贝" }, { w = "虾" }, { w = "蟹" }, { w = "鲟" }, { w = "鲤" },
        { w = "椰" }, { w = "槟榔" }, { w = "榴莲" }, { w = "蔗" }, { w = "椒" }, { w = "豆蔻" }, { w = "沉香" }, { w = "檀" }, { w = "苏木" }, { w = "藤" },
        { w = "橡胶" }, { w = "锡" }, { w = "金" }, { w = "燕窝" }, { w = "漆" }, { w = "榕" }, { w = "红毛丹" }, { w = "山竹" },
        { w = "潮" }, { w = "汐" }, { w = "汛" }, { w = "涨" }, { w = "退" }, { w = "涛" }, { w = "澜" }, { w = "浪" }, { w = "涌" }, { w = "流" },
        { w = "风" }, { w = "信" }, { w = "帆" }, { w = "候" }, { w = "洋" },
        { w = "屿" }, { w = "洲" }, { w = "沙" }, { w = "礁" }, { w = "滩" }, { w = "浅" }, { w = "埕" }, { w = "渚" }, { w = "矶" }, { w = "岬" },
        { w = "岙" },
        { w = "新" }, { w = "安" }, { w = "隆" }, { w = "平" }, { w = "顺" }, { w = "泰" }, { w = "和" }, { w = "永" }, { w = "福" }, { w = "禄" },
        { w = "光" }, { w = "华" }, { w = "富" }, { w = "贵" }, { w = "兴" }, { w = "明" }, { w = "清" }, { w = "荣" }, { w = "嘉" }, { w = "定" },
        { w = "会" }, { w = "义" }, { w = "仁" }, { w = "德" }, { w = "信" },
        { w = "大" }, { w = "中" }, { w = "东" }, { w = "南" }, { w = "西" }, { w = "北" }, { w = "上" }, { w = "下" }, { w = "旧" }, { w = "新" },
        { w = "巨" }, { w = "小" },
      },
    },

    constraints = {
      [=[字数：汉越/华人自造名 2–3 字为主；音译名 2–4 字（曼谷、巴邻旁、苏腊巴亚）。]=],
      [=[音节尾：闭口尾 -m（金 kim、心 tâm）、鼻音尾 -n/-ng（安 an、隆 long）、入声尾 -p/-t/-k（叻 -k、甲 -p、福 -k；汉越音转 -c）、开音节（河 Hà、巴 ba）。]=],
      [=[「海洋中国」可辨识差异（6 条）：通名用海贸词；专名密集热带物产字；借词汉写音节；闽粤客方言字；双关雅化名；三宝/大唐/妈祖/大伯公/公司作专名。]=],
      [=[帮口一致：同一城不得混用跨帮方言字（闽南「厝」与广府「墟」不拼在同一聚落名里）。]=],
      [=[通名单一：一个名字只保留一个通名（「槟榔屿港」冗余）。]=],
    },

    translit = {
      { group = "汉越音（Sino-Vietnamese）高频吉祥字对音", entries = {
        { from = "河", w = "Hà" }, { from = "海", w = "Hải" }, { from = "江", w = "Giang" },
        { from = "山", w = "Sơn" }, { from = "湖", w = "Hồ" }, { from = "洲/珠", w = "Châu" },
        { from = "安", w = "An" }, { from = "平", w = "Bình" }, { from = "泰", w = "Thái" },
        { from = "顺", w = "Thuận" }, { from = "和", w = "Hòa/Hoà" }, { from = "永", w = "Vĩnh" },
        { from = "福", w = "Phúc" }, { from = "禄", w = "Lộc" }, { from = "寿", w = "Thọ" },
        { from = "新", w = "Tân" }, { from = "兴", w = "Hưng" }, { from = "隆/龙", w = "Long" },
        { from = "明", w = "Minh" }, { from = "光", w = "Quang" }, { from = "华", w = "Hoa" },
        { from = "富", w = "Phú" }, { from = "贵", w = "Quý" }, { from = "金", w = "Kim" },
        { from = "玉", w = "Ngọc" }, { from = "宝", w = "Bảo" }, { from = "广", w = "Quảng" },
        { from = "东", w = "Đông" }, { from = "南", w = "Nam" }, { from = "西", w = "Tây" },
        { from = "城", w = "Thành" }, { from = "港", w = "Cảng" }, { from = "口", w = "Khẩu" },
        { from = "镇", w = "Trấn" }, { from = "会", w = "Hội" }, { from = "定", w = "Định" },
        { from = "义", w = "Nghĩa" }, { from = "仁", w = "Nhân" }, { from = "德", w = "Đức" },
      } },
      { group = "马来语/印尼语对音（闽南、潮州、客家帮口音）", entries = {
        { from = "Bang", w = "曼/班/邦", meaning = [=[河畔聚落]=], note = [=[曼谷]=] },
        { from = "Kuala", w = "吉隆", meaning = nil, note = [=[吉隆坡（Lumpur＝泥）]=] },
        { from = "Tanjung", w = "丹绒", meaning = [=[海角]=], note = nil },
        { from = "Pulau", w = "布路/浮罗", meaning = [=[岛]=], note = [=[布路槟榔]=] },
        { from = "-pur/-pura", w = "坡", meaning = [=[城]=], note = [=[Singapura→新加坡]=] },
        { from = "Selat", w = "石叻", meaning = [=[海峡]=], note = [=[闽南 sek-lat]=] },
        { from = "pasar", w = "巴刹", meaning = [=[市场]=], note = nil },
        { from = "kongsi", w = "公司", meaning = [=[会党/组织]=], note = [=[中文借出又回流]=] },
        { from = "Pontianak", w = "坤甸", meaning = [=[（马来传说）]=], note = nil },
      } },
      { group = "泰语/缅语/高棉语对音（简）", entries = {
        { from = "Bang", w = "曼", meaning = [=[河畔聚落]=], note = [=[按潮州话]=] },
        { from = "Nakhon", w = "洛坤/六坤", meaning = [=[城]=], note = nil },
        { from = "Krung", w = "恭贴", meaning = [=[京城]=], note = nil },
        { from = "Yangon", w = "漾贡→仰光", meaning = nil, note = [=[雅化]=] },
        { from = "Bago/Pegu", w = "勃固", meaning = nil, note = nil },
        { from = "Mergui", w = "丹老", meaning = nil, note = nil },
        { from = "Piem", w = "边", meaning = [=[港口/出海口]=], note = [=[河仙故地]=] },
        { from = "Sài Gòn", w = "柴棍→西贡", meaning = nil, note = [=[高棉语，华人雅化]=] },
      } },
      { group = "音译模拟器对音映射（伪造「像东南亚地名」）", entries = {
        { from = "/ka/", w = "吉/加/甲" }, { from = "/ku/", w = "古/谷" },
        { from = "/ki/", w = "基/己" }, { from = "/la/", w = "拉/罗/喇" },
        { from = "/li/", w = "里/利" }, { from = "/lu/", w = "鲁/六" },
        { from = "/ma/", w = "马/麻/妈" }, { from = "/mi/", w = "米/美" },
        { from = "/mu/", w = "武/木" }, { from = "/ta/", w = "打/达/丹" },
        { from = "/tan/", w = "丹/单" }, { from = "/tang/", w = "堂/丹绒" },
        { from = "/na/", w = "那/拿" }, { from = "/nang/", w = "南/难" },
        { from = "/sa/", w = "沙/三/苏" }, { from = "/si/", w = "西/泗" },
        { from = "/su/", w = "苏/素" }, { from = "/pa/", w = "巴/巴刹" },
        { from = "/pu/", w = "布/浮罗" }, { from = "/pur/", w = "坡" },
        { from = "/nga/", w = "雅/衙" }, { from = "/ban/", w = "班/曼/万" },
        { from = "/bang/", w = "曼/邦" },
      } },
    },
    translitNote = [=[注：汉字「龙」与「隆」汉越音同为 Long，二者可互换（隆表兴旺、龙表祥瑞）。汉越音保留中古音（-m、入声 -c 尾），故越南式中文名天然带闭口尾与入声尾。]=],

    banned = {
      chars     = { "死", "亡", "崩", "沉", "陷", "绝", "败", "瘟", "疫", "鬼", "尸", "灾", "祸" },
      suffixes  = {},
      words     = {},
      realNames = {
        "河内", "升龙", "顺化", "岘港", "会安", "嘉定", "西贡", "柴棍", "河仙", "金瓯", "芹苴",
        "曼谷", "清迈", "合艾", "普吉", "洛坤",
        "马六甲", "满剌加", "槟城", "槟榔屿", "吉隆坡", "新加坡", "星洲", "石叻",
        "坤甸", "山口洋", "三宝垄", "巨港", "旧港", "巴邻旁", "泗水", "苏腊巴亚",
        "马尼拉", "吕宋", "宿务", "三宝颜",
        "仰光", "漾贡", "勃固", "丹老",
        "金边", "暹粒",
        "三宝山", "兰芳", "东万律", "和顺", "三条沟", "大唐总长",
      },
      rules = {
        [=[禁止/慎用字：死、亡、崩、沉、陷、绝、败、瘟、疫、鬼、尸、灾、祸（不雅/凶字）；敏感词、粗口、政治人物名同音。]=],
        [=[禁止的通名组合：通名堆叠（「槟榔屿港」冗余，只留一个通名）；跨帮方言字混用。]=],
        [=[真实地名黑名单（比对含同义/近音变体）：越南（河内、升龙、顺化、岘港、会安、嘉定、西贡/柴棍、河仙、金瓯、芹苴…）；泰国（曼谷、清迈、合艾、普吉、洛坤…）；马来半岛（马六甲/满剌加、槟城/槟榔屿、吉隆坡、新加坡/星洲/石叻…）；印尼（坤甸、山口洋、三宝垄、巨港/旧港/巴邻旁、泗水/苏腊巴亚…）；菲律宾（马尼拉、吕宋、宿务、三宝颜…）；缅甸（仰光/漾贡、勃固、丹老…）；柬埔寨（金边、暹粒…）；郑和/公司（三宝垄、三宝颜、三宝山、兰芳、东万律、和顺、三条沟、大唐总长）。]=],
        [=[同音避让：前 2 字同音变体也避（「泗水」→「四水/思水」）；「安平」可、「北平/上海/广州」不可。]=],
      },
    },

    algorithm = {
      [=[选生成器：A 汉越吉祥式（越南/占城/柬埔寨沿海）、B 海贸物产式（马来半岛/爪哇/苏门答腊/婆罗洲/菲律宾）、C 音译雅化式（最难最地道）。]=],
      [=[A 式：吉祥字/主题字 + 吉祥字/地理字，2 字，可加行政通名（城庯/市社/坊/社/县/省）。]=],
      [=[B 式：热带物产/海产/海贸字 + 通名，2–3 字。]=],
      [=[C 式：取假马来语词音首音节 → 用闽/粤/客方言读音挑 2 个谐音字 → 替换 1–2 字为近音吉祥/地理字，构成「既音近又雅」双关。]=],
      [=[音译模拟器：构造假马来语词（多开音节 -ang/-an/-ong/-ung）→ 用对音映射回汉字 → 加雅化通名/吉祥字收尾「汉化」。]=],
      [=[过滤：避真实地名（黑名单+同音变体）、避不雅凶字、避现代专名雷同、音近去歧义、帮口一致、通名单一、去重。]=],
    },
  },

  ---------------------------------------------------------------------------
  -- 西北（陕西/甘肃/宁夏/青海/新疆/内蒙古西部）
  ---------------------------------------------------------------------------
  northwest = {

    style = {
      [=[苍凉/干旱感：沙、漠、戈壁、滩、荒、碱、旱、干等字入名（沙湾、碱滩、戈壁滩）。]=],
      [=[水与堡的对立：泉/井/渠/坝/涝坝/海子（珍贵水利）+ 堡/寨/营/屯（军事驻防）并置（五家渠、吴忠堡、甜水井）。]=],
      [=[颜色对音：维吾尔语阿克（白）/喀拉（黑）/克孜勒（红）/阔克（青），蒙古语乌兰（红）/查干（白）/呼和（青），直接作专名（克孜勒苏、乌兰浩特）。]=],
      [=[长音译词：3–4 字突厥/蒙古语音译，读起来「异域腔」（克拉玛依、巴彦淖尔、呼和浩特）。]=],
      [=[干旱地貌通名 + 军镇链条 + 丝路古国：塬/梁/峁/滩/海子/涝坝/崾岘；卫/所/堡/营/屯/墩/铺/驿/关；楼兰/龟兹/于阗/疏勒/高昌。]=],
    },

    templates = {
      { id = "X1", formula = [=[汉语-军事：方位/里程/姓氏 + 军事通名]=], seq = { "direction", "suffix" }, weight = nil, note = [=[五里墩、十里铺、张家堡、东营（前缀亦可 mileage/surname）]=] }, --[[W?]]
      { id = "X2", formula = [=[汉语-水利：颜色/地貌修饰/物产 + 水利通名]=], seq = { "color", "suffix" }, weight = nil, note = [=[甜水井、七里井、沙河、红柳沟、柳泉（前缀亦可 modifier/plant）]=] }, --[[W?]]
      { id = "X3", formula = [=[汉语-地形：颜色/姓氏/方位 + 地形通名]=], seq = { "color", "terrain_suffix" }, weight = nil, note = [=[南梁、北塬、张家峁、白鹿原、红崖、沙湾（前缀亦可 surname/direction）]=] }, --[[W?]]
      { id = "X4", formula = [=[维语-对音：颜色对音 + 自然通名对音]=], seq = nil, weight = nil, note = [=[克孜勒苏（红水）、喀拉库勒（黑湖）、阔克塔格（青山）；使用维吾尔语 translit 表]=] }, --[[W?]]
      { id = "X5", formula = [=[维语-混合：民族语专名 + 汉语通名]=], seq = nil, weight = nil, note = [=[拜城（富城）、英吉沙尔、阔纳城（旧城）；民族语专名 + 汉语通名]=] }, --[[W?]]
      { id = "X6", formula = [=[蒙语-对音：巴彦/巴音 + 自然通名，或 颜色对音 + 浩特/淖尔/郭勒]=], seq = nil, weight = nil, note = [=[巴彦淖尔（富湖）、乌兰浩特（红城）；使用蒙古语 translit 表]=] }, --[[W?]]
      { id = "X7", formula = [=[藏语-对音：颜色 + 曲/措/岗]=], seq = nil, weight = nil, note = [=[那曲（黑河）、措温布（青湖）、岗日（雪山）；使用藏语 translit 表]=] }, --[[W?]]
      { id = "X8", formula = [=[古国/丝路：古国名 + 城/关/驿]=], seq = { "ancient_state", "suffix" }, weight = nil, note = [=[楼兰城、龟兹驿、高昌城、焉耆驿]=] }, --[[W?]]
      { id = "X9", formula = [=[兵团-层级：师部城（X1–X8）+ 数字团 + 数字连]=], seq = nil, weight = nil, note = [=[石河子 + 一四七团 + 三连；使用 corps 池 + 特殊层级逻辑]=] }, --[[W?]]
      { id = "gen", formula = [=[通用次序：[方位/里程/颜色/姓氏/物产/形容词] + 通名]=], seq = { "single", "suffix" }, weight = nil, note = [=[修饰语在前（东湖、南梁、张家堡、柳沟、大营）]=] }, --[[W?]]
    },

    suffixes = {
      -- 军事驻防
      { w = "城", etymon = [=[城墙围合聚落]=], scene = [=[城]=], weight = nil, note = [=[兰州、银川、吴忠（吴忠堡转）]=], group = "military" }, --[[W?]]
      { w = "镇", etymon = [=[军事重镇/集镇]=], scene = [=[镇]=], weight = nil, note = [=[武威、清水镇]=], group = "military" }, --[[W?]]
      { w = "卫", etymon = [=[明代军事卫所]=], scene = [=[卫所]=], weight = nil, note = [=[中卫、前卫]=], group = "military" }, --[[W?]]
      { w = "所", etymon = [=[千户所]=], scene = [=[卫所]=], weight = nil, note = [=[平罗所、靖远所（存疑个例）]=], group = "military", suspicious = true }, --[[W?]]
      { w = "营", etymon = [=[驻军营盘]=], scene = [=[驻军]=], weight = nil, note = [=[大营、西营、五营]=], group = "military" }, --[[W?]]
      { w = "堡", etymon = [=[有墙村寨（读 bǔ）]=], scene = [=[村寨]=], weight = nil, note = [=[吴忠堡、洪水堡]=], group = "military" }, --[[W?]]
      { w = "堡子", etymon = [=[堡的双音节化]=], scene = [=[村寨]=], weight = nil, note = [=[陕北/宁夏极多]=], group = "military" }, --[[W?]]
      { w = "寨", etymon = [=[木石栅寨]=], scene = [=[村寨]=], weight = nil, note = [=[张家寨、清涧寨]=], group = "military" }, --[[W?]]
      { w = "屯", etymon = [=[屯田驻点]=], scene = [=[屯垦]=], weight = nil, note = [=[北屯、柳屯]=], group = "military" }, --[[W?]]
      { w = "墩", etymon = [=[烽火台土墩]=], scene = [=[烽燧]=], weight = nil, note = [=[五里墩、十里墩、烟墩]=], group = "military" }, --[[W?]]
      { w = "台", etymon = [=[瞭望台/墩台]=], scene = [=[瞭望]=], weight = nil, note = [=[烽台、望台、双台]=], group = "military" }, --[[W?]]
      { w = "烽", etymon = [=[烽燧]=], scene = [=[烽火]=], weight = nil, note = [=[烽火台]=], group = "military" }, --[[W?]]
      { w = "戍", etymon = [=[戍边驻点]=], scene = [=[戍边]=], weight = nil, note = [=[罕用，多并入史书地名]=], group = "military" }, --[[W?]]
      { w = "关", etymon = [=[关隘]=], scene = [=[关隘]=], weight = nil, note = [=[嘉峪关、玉门关、阳关]=], group = "military" }, --[[W?]]
      { w = "隘", etymon = [=[险要隘口]=], scene = [=[隘口]=], weight = nil, note = [=[石峡隘、铁门关]=], group = "military" }, --[[W?]]
      { w = "口", etymon = [=[山口/河口]=], scene = [=[山口河口]=], weight = nil, note = [=[磴口、阿拉山口]=], group = "military" }, --[[W?]]
      -- 水利绿洲
      { w = "泉", etymon = [=[泉眼]=], scene = [=[水利]=], weight = nil, note = [=[酒泉、甘泉、玉泉]=], group = "water" }, --[[W?]]
      { w = "井", etymon = [=[水井]=], scene = [=[水利]=], weight = nil, note = [=[甜水井、七里井]=], group = "water" }, --[[W?]]
      { w = "渠", etymon = [=[引水渠]=], scene = [=[灌溉]=], weight = nil, note = [=[五家渠、满城渠、汉渠]=], group = "water" }, --[[W?]]
      { w = "河", etymon = [=[河流]=], scene = [=[河流]=], weight = nil, note = [=[临河、沙河]=], group = "water" }, --[[W?]]
      { w = "坝", etymon = [=[拦水坝]=], scene = [=[水利]=], weight = nil, note = [=[大坝]=], group = "water" }, --[[W?]]
      { w = "堰", etymon = [=[挡水堰]=], scene = [=[水利]=], weight = nil, note = [=[古堰、双堰]=], group = "water" }, --[[W?]]
      { w = "湖", etymon = [=[湖泊]=], scene = [=[水域]=], weight = nil, note = [=[东湖]=], group = "water" }, --[[W?]]
      { w = "海子", etymon = [=[内陆小湖/水塘]=], scene = [=[水域]=], weight = nil, note = [=[蒙古语 naγur「湖」方言化，宁夏/内蒙古极多]=], group = "water" }, --[[W?]]
      { w = "涝坝", etymon = [=[蓄水塘（西北方言）]=], scene = [=[水利]=], weight = nil, note = [=[涝坝、老涝坝]=], group = "water" }, --[[W?]]
      { w = "水库", etymon = [=[现代水库]=], scene = [=[水利]=], weight = nil, note = [=[青铜峡水库周边]=], group = "water" }, --[[W?]]
      -- 地形（黄土高原核心）
      { w = "塬", etymon = [=[顶部平坦黄土台地]=], scene = [=[地形]=], weight = nil, note = [=[洛川塬、董志塬]=], group = "landform" }, --[[W?]]
      { w = "梁", etymon = [=[长条黄土山脊]=], scene = [=[地形]=], weight = nil, note = [=[陕北「某某梁」]=], group = "landform" }, --[[W?]]
      { w = "峁", etymon = [=[浑圆孤丘]=], scene = [=[地形]=], weight = nil, note = [=[神木「某某峁」]=], group = "landform" }, --[[W?]]
      { w = "川", etymon = [=[河谷平地]=], scene = [=[地形]=], weight = nil, note = [=[米脂川、洛川、铜川]=], group = "landform" }, --[[W?]]
      { w = "原", etymon = [=[塬的古/雅写]=], scene = [=[地形]=], weight = nil, note = [=[白鹿原、五丈原]=], group = "landform" }, --[[W?]]
      { w = "坪", etymon = [=[山间/河边平地]=], scene = [=[地形]=], weight = nil, note = [=[清坪、庙坪]=], group = "landform" }, --[[W?]]
      { w = "滩", etymon = [=[河滩/沙地/戈壁滩]=], scene = [=[地形]=], weight = nil, note = [=[河滩、碱滩、荒滩]=], group = "landform" }, --[[W?]]
      { w = "沟", etymon = [=[沟壑]=], scene = [=[地形]=], weight = nil, note = [=[柳沟、红柳沟]=], group = "landform" }, --[[W?]]
      { w = "岔", etymon = [=[沟谷分岔]=], scene = [=[地形]=], weight = nil, note = [=[三岔、岔口]=], group = "landform" }, --[[W?]]
      { w = "湾", etymon = [=[河湾/山湾]=], scene = [=[地形]=], weight = nil, note = [=[沙湾、河湾]=], group = "landform" }, --[[W?]]
      { w = "岘", etymon = [=[山口/垭口]=], scene = [=[地形]=], weight = nil, note = [=[青石岘（存疑个例）]=], group = "landform", suspicious = true }, --[[W?]]
      { w = "崾岘", etymon = [=[塬上鞍部隘口]=], scene = [=[地形]=], weight = nil, note = [=[陕北特征词]=], group = "landform" }, --[[W?]]
      { w = "畔", etymon = [=[边缘/山畔]=], scene = [=[地形]=], weight = nil, note = [=[塬畔、河畔、柳畔]=], group = "landform" }, --[[W?]]
      -- 聚落双音节（西北特色）
      { w = "城子", etymon = [=[小城]=], scene = [=[聚落]=], weight = nil, note = [=[城子、古城子、黑城子]=], group = "settlement" }, --[[W?]]
      { w = "庄子", etymon = [=[村庄]=], scene = [=[聚落]=], weight = nil, note = [=[张家庄子、高庄子]=], group = "settlement" }, --[[W?]]
      { w = "堡子", etymon = [=[有墙村]=], scene = [=[聚落]=], weight = nil, note = [=[王堡子、刘堡子]=], group = "settlement" }, --[[W?]]
      -- 少数民族语汉写通名
      { w = "阿克", etymon = [=[白（维吾尔语 aq）]=], scene = [=[颜色专名]=], weight = nil, note = [=[阿克苏（白水）]=], group = "ethnic" }, --[[W?]]
      { w = "喀拉/喀喇", etymon = [=[黑（维 qara）]=], scene = [=[颜色专名]=], weight = nil, note = [=[喀拉喀什河]=], group = "ethnic" }, --[[W?]]
      { w = "克孜勒", etymon = [=[红（维 qizil）]=], scene = [=[颜色专名]=], weight = nil, note = [=[克孜勒苏（红水）]=], group = "ethnic" }, --[[W?]]
      { w = "阔克/库克", etymon = [=[蓝/青/绿（维 kök）]=], scene = [=[颜色专名]=], weight = nil, note = [=[阔克苏（绿水）]=], group = "ethnic" }, --[[W?]]
      { w = "萨热克/色日克", etymon = [=[黄（维 seriq）]=], scene = [=[颜色专名]=], weight = nil, note = [=[色日克（存疑个例）]=], group = "ethnic", suspicious = true }, --[[W?]]
      { w = "塔格", etymon = [=[山（维 tagh）]=], scene = [=[自然通名]=], weight = nil, note = [=[库木塔格（沙山）]=], group = "ethnic" }, --[[W?]]
      { w = "库木", etymon = [=[沙（维 qum）]=], scene = [=[自然通名]=], weight = nil, note = [=[库木塔格沙漠]=], group = "ethnic" }, --[[W?]]
      { w = "萨依", etymon = [=[河滩/戈壁滩/干河床（维 say）]=], scene = [=[自然通名]=], weight = nil, note = [=[阿克萨依（白滩）]=], group = "ethnic" }, --[[W?]]
      { w = "库勒", etymon = [=[湖（维 köl）]=], scene = [=[自然通名]=], weight = nil, note = [=[喀拉库勒（黑湖）]=], group = "ethnic" }, --[[W?]]
      { w = "达里亚", etymon = [=[河（维 darya）]=], scene = [=[自然通名]=], weight = nil, note = [=[塔里木河]=], group = "ethnic" }, --[[W?]]
      { w = "苏", etymon = [=[水（维 su）]=], scene = [=[自然通名]=], weight = nil, note = [=[阿克苏、克孜勒苏]=], group = "ethnic" }, --[[W?]]
      { w = "布拉克", etymon = [=[泉（维 bulaq）]=], scene = [=[自然通名]=], weight = nil, note = [=[麦盖提布拉克（存疑个例）]=], group = "ethnic", suspicious = true }, --[[W?]]
      { w = "慕士", etymon = [=[冰（维 muz）]=], scene = [=[自然通名]=], weight = nil, note = [=[慕士塔格（冰山）]=], group = "ethnic" }, --[[W?]]
      { w = "墩", etymon = [=[土丘/高台（维 döng）]=], scene = [=[地形通名]=], weight = nil, note = [=[喀拉墩（黑土丘）]=], group = "ethnic" }, --[[W?]]
      { w = "铁热克", etymon = [=[杨树（维 terek）]=], scene = [=[植被通名]=], weight = nil, note = [=[铁热克（拜城）]=], group = "ethnic" }, --[[W?]]
      { w = "托格拉克", etymon = [=[胡杨（维 toghraq）]=], scene = [=[植被通名]=], weight = nil, note = [=[托格拉克（胡杨乡）]=], group = "ethnic" }, --[[W?]]
      { w = "阔什", etymon = [=[双/一对（维 qosh）]=], scene = [=[数词]=], weight = nil, note = [=[阔什塔格（双山）]=], group = "ethnic" }, --[[W?]]
      { w = "库什", etymon = [=[鸟（维 qush）]=], scene = [=[动物]=], weight = nil, note = [=[与「阔什」不同词]=], group = "ethnic" }, --[[W?]]
      { w = "巴格", etymon = [=[园/果园（维 bagh）]=], scene = [=[人文]=], weight = nil, note = [=[巴格乡]=], group = "ethnic" }, --[[W?]]
      { w = "巴扎", etymon = [=[集市（维 bazar）]=], scene = [=[商贸]=], weight = nil, note = [=[喀什巴扎]=], group = "ethnic" }, --[[W?]]
      { w = "阔纳", etymon = [=[旧/老（维 kona）]=], scene = [=[状态]=], weight = nil, note = [=[阔纳（旧城）]=], group = "ethnic" }, --[[W?]]
      { w = "英吉/英", etymon = [=[新（维 yengi）]=], scene = [=[状态]=], weight = nil, note = [=[英吉沙（新城）]=], group = "ethnic" }, --[[W?]]
      { w = "买里", etymon = [=[村/街区（维 mahalla）]=], scene = [=[聚落]=], weight = nil, note = [=[英买里（新村）]=], group = "ethnic" }, --[[W?]]
      { w = "吾斯塘", etymon = [=[渠（维 östeng）]=], scene = [=[水利]=], weight = nil, note = [=[英吾斯塘（新渠）]=], group = "ethnic" }, --[[W?]]
      { w = "拜", etymon = [=[富（维 bay）]=], scene = [=[状态]=], weight = nil, note = [=[拜城（富＋汉语「城」）]=], group = "ethnic" }, --[[W?]]
      { w = "阿瓦提", etymon = [=[繁荣/兴旺（维 awat）]=], scene = [=[状态]=], weight = nil, note = [=[阿瓦提县]=], group = "ethnic" }, --[[W?]]
      { w = "萨拉依/沙尔", etymon = [=[驿站/客店（维 saray）]=], scene = [=[建筑]=], weight = nil, note = [=[英吉沙尔（新城/新客店）]=], group = "ethnic" }, --[[W?]]
      { w = "塔什", etymon = [=[石（维 tash）]=], scene = [=[自然]=], weight = nil, note = [=[塔什库尔干（石头城）]=], group = "ethnic" }, --[[W?]]
      { w = "亚尔", etymon = [=[崖/河岸（维 yar）]=], scene = [=[地形]=], weight = nil, note = [=[吐鲁番亚尔]=], group = "ethnic" }, --[[W?]]
      { w = "阿勒泰", etymon = [=[金山（哈 altay）]=], scene = [=[自然]=], weight = nil, note = [=[阿勒泰地区]=], group = "ethnic" }, --[[W?]]
      { w = "托海", etymon = [=[河湾/灌木林（哈 toqay）]=], scene = [=[自然]=], weight = nil, note = [=[可可托海]=], group = "ethnic" }, --[[W?]]
      { w = "布尔津", etymon = [=[三岁公驼/骆驼放牧地（哈 burqin）]=], scene = [=[自然]=], weight = nil, note = [=[存疑]=], group = "ethnic", suspicious = true }, --[[W?]]
      { w = "吉木乃", etymon = [=[蒙古语借词（哈 jeminay）]=], scene = [=[自然]=], weight = nil, note = [=[存疑]=], group = "ethnic", suspicious = true }, --[[W?]]
      { w = "呼和/库库", etymon = [=[蓝/青（蒙 köke/höh）]=], scene = [=[颜色专名]=], weight = nil, note = [=[呼和浩特（青城）]=], group = "ethnic" }, --[[W?]]
      { w = "浩特", etymon = [=[城/聚落（蒙 qota/hot）]=], scene = [=[聚落通名]=], weight = nil, note = [=[乌兰浩特、锡林浩特]=], group = "ethnic" }, --[[W?]]
      { w = "乌兰", etymon = [=[红（蒙 ulaan）]=], scene = [=[颜色专名]=], weight = nil, note = [=[乌兰浩特（红城）]=], group = "ethnic" }, --[[W?]]
      { w = "查干/察罕", etymon = [=[白（蒙 chagaan）]=], scene = [=[颜色专名]=], weight = nil, note = [=[查干淖尔（白湖）]=], group = "ethnic" }, --[[W?]]
      { w = "哈拉/哈日", etymon = [=[黑（蒙 qara/har）]=], scene = [=[颜色专名]=], weight = nil, note = [=[哈拉乌素（黑水）]=], group = "ethnic" }, --[[W?]]
      { w = "巴彦/巴音", etymon = [=[富饶（蒙 bayan）]=], scene = [=[状态专名]=], weight = nil, note = [=[巴彦淖尔（富饶的湖）]=], group = "ethnic" }, --[[W?]]
      { w = "淖尔/诺尔", etymon = [=[湖（蒙 naγur/nuur）]=], scene = [=[自然通名]=], weight = nil, note = [=[巴彦淖尔、查干淖尔]=], group = "ethnic" }, --[[W?]]
      { w = "郭勒/高勒", etymon = [=[河（蒙 γool/gol）]=], scene = [=[自然通名]=], weight = nil, note = [=[巴音郭楞、锡林郭勒]=], group = "ethnic" }, --[[W?]]
      { w = "乌拉/乌勒", etymon = [=[山（蒙 aγula/uul）]=], scene = [=[自然通名]=], weight = nil, note = [=[巴音乌拉]=], group = "ethnic" }, --[[W?]]
      { w = "苏木", etymon = [=[乡/区（蒙 sumu）]=], scene = [=[政区]=], weight = nil, note = [=[各旗苏木]=], group = "ethnic" }, --[[W?]]
      { w = "嘎查", etymon = [=[村（蒙 gachaa）]=], scene = [=[政区]=], weight = nil, note = [=[各苏木嘎查]=], group = "ethnic" }, --[[W?]]
      { w = "达坂/达瓦", etymon = [=[山口（蒙 dabaan）]=], scene = [=[地形]=], weight = nil, note = [=[达坂城]=], group = "ethnic" }, --[[W?]]
      { w = "塔拉/塔勒", etymon = [=[草原/平原（蒙 tal(a)）]=], scene = [=[地形]=], weight = nil, note = [=[巴音塔拉]=], group = "ethnic" }, --[[W?]]
      { w = "库伦/库勒", etymon = [=[围栏/城（蒙 küriye/hüree）]=], scene = [=[聚落]=], weight = nil, note = [=[库伦旗]=], group = "ethnic" }, --[[W?]]
      { w = "鄂尔多斯", etymon = [=[宫帐（群）（蒙 ordos）]=], scene = [=[聚落]=], weight = nil, note = [=[鄂尔多斯]=], group = "ethnic" }, --[[W?]]
      { w = "锡林", etymon = [=[山梁/丘陵（蒙 shiliin）]=], scene = [=[地形]=], weight = nil, note = [=[锡林郭勒]=], group = "ethnic" }, --[[W?]]
      { w = "曲/楚", etymon = [=[水/河（藏 chu）]=], scene = [=[自然通名]=], weight = nil, note = [=[那曲（黑河）]=], group = "ethnic" }, --[[W?]]
      { w = "措/错", etymon = [=[湖（藏 mtsho）]=], scene = [=[自然通名]=], weight = nil, note = [=[措温布（青海湖）、纳木措]=], group = "ethnic" }, --[[W?]]
      { w = "岗/贡", etymon = [=[雪山/山（藏 gangs）]=], scene = [=[自然通名]=], weight = nil, note = [=[岗日]=], group = "ethnic" }, --[[W?]]
      { w = "拉", etymon = [=[神（藏 lha）]=], scene = [=[宗教]=], weight = nil, note = [=[拉加（存疑）、天峻]=], group = "ethnic" }, --[[W?]]
      { w = "宗", etymon = [=[城堡/县（藏 rdzong）]=], scene = [=[政区]=], weight = nil, note = [=[青海各「宗」]=], group = "ethnic" }, --[[W?]]
      { w = "塘/唐", etymon = [=[平原/坝子（藏 thang）]=], scene = [=[地形]=], weight = nil, note = [=[玉树各「塘」]=], group = "ethnic" }, --[[W?]]
    },

    -- 自然地理通名（地形 + 水利，供 X3 地形通名使用）
    terrain_suffix = {
      { w = "塬", weight = nil, note = [=[洛川塬、董志塬]=] }, { w = "梁", weight = nil, note = [=[陕北「某某梁」]=] }, { w = "峁", weight = nil, note = [=[神木「某某峁」]=] }, { w = "川", weight = nil, note = [=[米脂川、洛川、铜川]=] }, { w = "原", weight = nil, note = [=[白鹿原、五丈原]=] },
      { w = "坪", weight = nil, note = [=[清坪、庙坪]=] }, { w = "滩", weight = nil, note = [=[河滩、碱滩、荒滩]=] }, { w = "沟", weight = nil, note = [=[柳沟、红柳沟]=] }, { w = "岔", weight = nil, note = [=[三岔、岔口]=] }, { w = "湾", weight = nil, note = [=[沙湾、河湾]=] },
      { w = "岘", weight = nil, note = [=[青石岘（存疑个例）]=] }, { w = "崾岘", weight = nil, note = [=[陕北特征词]=] }, { w = "畔", weight = nil, note = [=[塬畔、河畔、柳畔]=] },
      { w = "泉", weight = nil, note = [=[酒泉、甘泉、玉泉]=] }, { w = "井", weight = nil, note = [=[甜水井、七里井]=] }, { w = "渠", weight = nil, note = [=[五家渠、满城渠、汉渠]=] }, { w = "河", weight = nil, note = [=[临河、沙河]=] }, { w = "坝", weight = nil, note = [=[大坝]=] },
      { w = "堰", weight = nil, note = [=[古堰、双堰]=] }, { w = "湖", weight = nil, note = [=[东湖]=] }, { w = "海子", weight = nil, note = [=[蒙古语 naγur「湖」方言化，宁夏/内蒙古极多]=] }, { w = "涝坝", weight = nil, note = [=[涝坝、老涝坝]=] }, { w = "水库", weight = nil, note = [=[青铜峡水库周边]=] },
    },

    -- 吉祥通名（西北无显式吉祥通名清单，留空）
    auspicious_suffix = {},

    parts = {
      -- 军事屯戍
      garrison = {
        { w = "卫", weight = nil, note = [=[例：中卫、吴忠堡、嘉峪关、北屯]=] }, { w = "所", weight = nil, note = [=[例：中卫、吴忠堡、嘉峪关、北屯]=] }, { w = "营", weight = nil, note = [=[例：中卫、吴忠堡、嘉峪关、北屯]=] }, { w = "屯", weight = nil, note = [=[例：中卫、吴忠堡、嘉峪关、北屯]=] }, { w = "堡", weight = nil, note = [=[例：中卫、吴忠堡、嘉峪关、北屯]=] },
        { w = "墩", weight = nil, note = [=[例：中卫、吴忠堡、嘉峪关、北屯]=] }, { w = "烽", weight = nil, note = [=[例：中卫、吴忠堡、嘉峪关、北屯]=] }, { w = "台", weight = nil, note = [=[例：中卫、吴忠堡、嘉峪关、北屯]=] }, { w = "戍", weight = nil, note = [=[例：中卫、吴忠堡、嘉峪关、北屯]=] }, { w = "镇", weight = nil, note = [=[例：中卫、吴忠堡、嘉峪关、北屯]=] },
        { w = "关", weight = nil, note = [=[例：中卫、吴忠堡、嘉峪关、北屯]=] }, { w = "堡子", weight = nil, note = [=[例：中卫、吴忠堡、嘉峪关、北屯]=] },
      },
      -- 水利与绿洲
      water = {
        { w = "泉", weight = nil, note = [=[例：酒泉、甜水井、五家渠、涝坝]=] }, { w = "井", weight = nil, note = [=[例：酒泉、甜水井、五家渠、涝坝]=] }, { w = "渠", weight = nil, note = [=[例：酒泉、甜水井、五家渠、涝坝]=] }, { w = "河", weight = nil, note = [=[例：酒泉、甜水井、五家渠、涝坝]=] }, { w = "坝", weight = nil, note = [=[例：酒泉、甜水井、五家渠、涝坝]=] },
        { w = "堰", weight = nil, note = [=[例：酒泉、甜水井、五家渠、涝坝]=] }, { w = "湖", weight = nil, note = [=[例：酒泉、甜水井、五家渠、涝坝]=] }, { w = "海子", weight = nil, note = [=[例：酒泉、甜水井、五家渠、涝坝]=] }, { w = "涝坝", weight = nil, note = [=[例：酒泉、甜水井、五家渠、涝坝]=] }, { w = "水库", weight = nil, note = [=[例：酒泉、甜水井、五家渠、涝坝]=] },
      },
      -- 地形
      terrain = {
        { w = "塬", weight = nil, note = [=[例：洛川塬、董志塬、米脂川、三岔]=] }, { w = "梁", weight = nil, note = [=[例：洛川塬、董志塬、米脂川、三岔]=] }, { w = "峁", weight = nil, note = [=[例：洛川塬、董志塬、米脂川、三岔]=] }, { w = "坪", weight = nil, note = [=[例：洛川塬、董志塬、米脂川、三岔]=] }, { w = "川", weight = nil, note = [=[例：洛川塬、董志塬、米脂川、三岔]=] },
        { w = "沟", weight = nil, note = [=[例：洛川塬、董志塬、米脂川、三岔]=] }, { w = "岔", weight = nil, note = [=[例：洛川塬、董志塬、米脂川、三岔]=] }, { w = "湾", weight = nil, note = [=[例：洛川塬、董志塬、米脂川、三岔]=] }, { w = "滩", weight = nil, note = [=[例：洛川塬、董志塬、米脂川、三岔]=] }, { w = "岘", weight = nil, note = [=[例：洛川塬、董志塬、米脂川、三岔]=] },
        { w = "崾岘", weight = nil, note = [=[例：洛川塬、董志塬、米脂川、三岔]=] }, { w = "畔", weight = nil, note = [=[例：洛川塬、董志塬、米脂川、三岔]=] },
      },
      -- 方位与里程
      direction = {
        { w = "东", weight = nil, note = nil }, { w = "西", weight = nil, note = nil }, { w = "南", weight = nil, note = nil }, { w = "北", weight = nil, note = nil }, { w = "上", weight = nil, note = nil },
        { w = "下", weight = nil, note = nil }, { w = "头", weight = nil, note = nil }, { w = "尾", weight = nil, note = nil }, { w = "里", weight = nil, note = nil },
      },
      mileage = {
        { w = "五里", weight = nil, note = [=[配墩/铺/店；丝路驿铺活化石]=] }, { w = "七里", weight = nil, note = [=[配墩/铺/店；丝路驿铺活化石]=] }, { w = "十里", weight = nil, note = [=[配墩/铺/店；丝路驿铺活化石]=] }, { w = "二十里", weight = nil, note = [=[配墩/铺/店；丝路驿铺活化石]=] }, { w = "三十里", weight = nil, note = [=[配墩/铺/店；丝路驿铺活化石]=] },
        { w = "五十里", weight = nil, note = [=[配墩/铺/店；丝路驿铺活化石]=] },
      },
      number = {
        { w = "五", weight = nil, note = [=[里程型]=] }, { w = "七", weight = nil, note = [=[里程型]=] }, { w = "十", weight = nil, note = [=[里程型]=] }, { w = "二十", weight = nil, note = [=[里程型]=] }, { w = "三十", weight = nil, note = [=[里程型]=] },
      },
      -- 物产植被
      plant = {
        { w = "柳", weight = nil, note = [=[例：榆林、柳沟、红柳沟、胡杨河、葡萄沟]=] }, { w = "杨", weight = nil, note = [=[例：榆林、柳沟、红柳沟、胡杨河、葡萄沟]=] }, { w = "榆", weight = nil, note = [=[例：榆林、柳沟、红柳沟、胡杨河、葡萄沟]=] }, { w = "沙枣", weight = nil, note = [=[例：榆林、柳沟、红柳沟、胡杨河、葡萄沟]=] }, { w = "红柳", weight = nil, note = [=[例：榆林、柳沟、红柳沟、胡杨河、葡萄沟]=] },
        { w = "胡杨", weight = nil, note = [=[例：榆林、柳沟、红柳沟、胡杨河、葡萄沟]=] }, { w = "梭梭", weight = nil, note = [=[例：榆林、柳沟、红柳沟、胡杨河、葡萄沟]=] }, { w = "芦苇", weight = nil, note = [=[例：榆林、柳沟、红柳沟、胡杨河、葡萄沟]=] }, { w = "甘草", weight = nil, note = [=[例：榆林、柳沟、红柳沟、胡杨河、葡萄沟]=] }, { w = "瓜", weight = nil, note = [=[例：榆林、柳沟、红柳沟、胡杨河、葡萄沟]=] },
        { w = "葡萄", weight = nil, note = [=[例：榆林、柳沟、红柳沟、胡杨河、葡萄沟]=] }, { w = "棉", weight = nil, note = [=[例：榆林、柳沟、红柳沟、胡杨河、葡萄沟]=] }, { w = "苜蓿", weight = nil, note = [=[例：榆林、柳沟、红柳沟、胡杨河、葡萄沟]=] }, { w = "枣", weight = nil, note = [=[例：榆林、柳沟、红柳沟、胡杨河、葡萄沟]=] },
      },
      -- 颜色（汉语）
      color = {
        { w = "红", weight = nil, note = [=[例：红崖、黑山、白水、青石峡]=] }, { w = "黑", weight = nil, note = [=[例：红崖、黑山、白水、青石峡]=] }, { w = "白", weight = nil, note = [=[例：红崖、黑山、白水、青石峡]=] }, { w = "青", weight = nil, note = [=[例：红崖、黑山、白水、青石峡]=] }, { w = "黄", weight = nil, note = [=[例：红崖、黑山、白水、青石峡]=] },
        { w = "灰", weight = nil, note = [=[例：红崖、黑山、白水、青石峡]=] },
      },
      -- 地貌修饰
      modifier = {
        { w = "大", weight = nil, note = [=[例：大营、小寨、新城、沙湾、碱滩]=] }, { w = "小", weight = nil, note = [=[例：大营、小寨、新城、沙湾、碱滩]=] }, { w = "新", weight = nil, note = [=[例：大营、小寨、新城、沙湾、碱滩]=] }, { w = "老", weight = nil, note = [=[例：大营、小寨、新城、沙湾、碱滩]=] }, { w = "旧", weight = nil, note = [=[例：大营、小寨、新城、沙湾、碱滩]=] },
        { w = "高", weight = nil, note = [=[例：大营、小寨、新城、沙湾、碱滩]=] }, { w = "平", weight = nil, note = [=[例：大营、小寨、新城、沙湾、碱滩]=] }, { w = "沙", weight = nil, note = [=[例：大营、小寨、新城、沙湾、碱滩]=] }, { w = "碱", weight = nil, note = [=[例：大营、小寨、新城、沙湾、碱滩]=] }, { w = "荒", weight = nil, note = [=[例：大营、小寨、新城、沙湾、碱滩]=] },
        { w = "甘", weight = nil, note = [=[例：大营、小寨、新城、沙湾、碱滩]=] }, { w = "甜", weight = nil, note = [=[例：大营、小寨、新城、沙湾、碱滩]=] }, { w = "苦", weight = nil, note = [=[例：大营、小寨、新城、沙湾、碱滩]=] },
      },
      -- 姓氏
      surname = {
        { w = "张", weight = nil, note = [=[配庄/堡/梁/峁/寨]=] }, { w = "王", weight = nil, note = [=[配庄/堡/梁/峁/寨]=] }, { w = "李", weight = nil, note = [=[配庄/堡/梁/峁/寨]=] }, { w = "赵", weight = nil, note = [=[配庄/堡/梁/峁/寨]=] }, { w = "刘", weight = nil, note = [=[配庄/堡/梁/峁/寨]=] },
        { w = "陈", weight = nil, note = [=[配庄/堡/梁/峁/寨]=] }, { w = "杨", weight = nil, note = [=[配庄/堡/梁/峁/寨]=] }, { w = "马", weight = nil, note = [=[配庄/堡/梁/峁/寨]=] }, { w = "吴", weight = nil, note = [=[配庄/堡/梁/峁/寨]=] }, { w = "周", weight = nil, note = [=[配庄/堡/梁/峁/寨]=] },
        { w = "高", weight = nil, note = [=[配庄/堡/梁/峁/寨]=] }, { w = "韩", weight = nil, note = [=[配庄/堡/梁/峁/寨]=] }, { w = "魏", weight = nil, note = [=[配庄/堡/梁/峁/寨]=] }, { w = "石", weight = nil, note = [=[配庄/堡/梁/峁/寨]=] }, { w = "白", weight = nil, note = [=[配庄/堡/梁/峁/寨]=] },
        { w = "乔", weight = nil, note = [=[配庄/堡/梁/峁/寨]=] }, { w = "雷", weight = nil, note = [=[配庄/堡/梁/峁/寨]=] }, { w = "党", weight = nil, note = [=[配庄/堡/梁/峁/寨]=] },
        { w = "张家", weight = nil, note = [=[例：张家堡、王家梁、刘家峁]=] }, { w = "王家", weight = nil, note = [=[例：张家堡、王家梁、刘家峁]=] }, { w = "刘家", weight = nil, note = [=[例：张家堡、王家梁、刘家峁]=] },
      },
      -- 吉祥教化 / 帝王号
      auspicious = {
        { w = "安", weight = nil, note = [=[例：延安、平安、永昌、武威、定西、靖远、绥德]=] }, { w = "平", weight = nil, note = [=[例：延安、平安、永昌、武威、定西、靖远、绥德]=] }, { w = "永", weight = nil, note = [=[例：延安、平安、永昌、武威、定西、靖远、绥德]=] }, { w = "昌", weight = nil, note = [=[例：延安、平安、永昌、武威、定西、靖远、绥德]=] }, { w = "宁", weight = nil, note = [=[例：延安、平安、永昌、武威、定西、靖远、绥德]=] },
        { w = "靖", weight = nil, note = [=[例：延安、平安、永昌、武威、定西、靖远、绥德]=] }, { w = "绥", weight = nil, note = [=[例：延安、平安、永昌、武威、定西、靖远、绥德]=] }, { w = "定", weight = nil, note = [=[例：延安、平安、永昌、武威、定西、靖远、绥德]=] }, { w = "和", weight = nil, note = [=[例：延安、平安、永昌、武威、定西、靖远、绥德]=] }, { w = "顺", weight = nil, note = [=[例：延安、平安、永昌、武威、定西、靖远、绥德]=] },
        { w = "兴", weight = nil, note = [=[例：延安、平安、永昌、武威、定西、靖远、绥德]=] }, { w = "丰", weight = nil, note = [=[例：延安、平安、永昌、武威、定西、靖远、绥德]=] }, { w = "康", weight = nil, note = [=[例：延安、平安、永昌、武威、定西、靖远、绥德]=] }, { w = "乐", weight = nil, note = [=[例：延安、平安、永昌、武威、定西、靖远、绥德]=] },
        { w = "武威", weight = nil, note = [=[例：武威（武功军威）、张掖（张国臂掖）]=] }, { w = "张掖", weight = nil, note = [=[例：武威（武功军威）、张掖（张国臂掖）]=] }, { w = "敦煌", weight = nil, note = [=[例：武威（武功军威）、张掖（张国臂掖）]=] },
      },
      -- 丝路商贸 / 古国
      market = {
        { w = "驿", weight = nil, note = [=[例：沙州驿、柳园、十里铺、巴扎]=] }, { w = "店", weight = nil, note = [=[例：沙州驿、柳园、十里铺、巴扎]=] }, { w = "铺", weight = nil, note = [=[例：沙州驿、柳园、十里铺、巴扎]=] }, { w = "集", weight = nil, note = [=[例：沙州驿、柳园、十里铺、巴扎]=] }, { w = "巴扎", weight = nil, note = [=[例：沙州驿、柳园、十里铺、巴扎]=] },
      },
      ancient_state = {
        { w = "楼兰", weight = nil, note = [=[现名：库车、和田、喀什、吐鲁番等]=] }, { w = "龟兹", weight = nil, note = [=[现名：库车、和田、喀什、吐鲁番等]=] }, { w = "于阗", weight = nil, note = [=[现名：库车、和田、喀什、吐鲁番等]=] }, { w = "疏勒", weight = nil, note = [=[现名：库车、和田、喀什、吐鲁番等]=] }, { w = "高昌", weight = nil, note = [=[现名：库车、和田、喀什、吐鲁番等]=] },
        { w = "鄯善", weight = nil, note = [=[现名：库车、和田、喀什、吐鲁番等]=] }, { w = "焉耆", weight = nil, note = [=[现名：库车、和田、喀什、吐鲁番等]=] }, { w = "姑墨", weight = nil, note = [=[现名：库车、和田、喀什、吐鲁番等]=] }, { w = "莎车", weight = nil, note = [=[现名：库车、和田、喀什、吐鲁番等]=] }, { w = "乌孙", weight = nil, note = [=[现名：库车、和田、喀什、吐鲁番等]=] },
        { w = "车师", weight = nil, note = [=[现名：库车、和田、喀什、吐鲁番等]=] }, { w = "精绝", weight = nil, note = [=[现名：库车、和田、喀什、吐鲁番等]=] },
      },
      -- 兵团命名部件
      corps = {
        { w = "石河", weight = nil, note = [=[例：石河子（石滩+河）、五家渠（五户人家的渠）]=] }, { w = "双河", weight = nil, note = [=[例：石河子（石滩+河）、五家渠（五户人家的渠）]=] }, { w = "五家渠", weight = nil, note = [=[例：石河子（石滩+河）、五家渠（五户人家的渠）]=] }, { w = "北屯", weight = nil, note = [=[例：石河子（石滩+河）、五家渠（五户人家的渠）]=] }, { w = "昆玉", weight = nil, note = [=[例：石河子（石滩+河）、五家渠（五户人家的渠）]=] },
        { w = "胡杨河", weight = nil, note = [=[例：石河子（石滩+河）、五家渠（五户人家的渠）]=] }, { w = "新星", weight = nil, note = [=[例：石河子（石滩+河）、五家渠（五户人家的渠）]=] }, { w = "白杨", weight = nil, note = [=[例：石河子（石滩+河）、五家渠（五户人家的渠）]=] }, { w = "铁门关", weight = nil, note = [=[例：石河子（石滩+河）、五家渠（五户人家的渠）]=] },
        { w = "阿拉尔", weight = nil, note = [=[例：阿拉尔（维 Aral 河洲）、可克达拉（哈 绿色原野）]=] }, { w = "图木舒克", weight = nil, note = [=[例：阿拉尔（维 Aral 河洲）、可克达拉（哈 绿色原野）]=] }, { w = "可克达拉", weight = nil, note = [=[例：阿拉尔（维 Aral 河洲）、可克达拉（哈 绿色原野）]=] },
      },
      -- 单字专名核心总池
      single = {
        { w = "卫" }, { w = "所" }, { w = "营" }, { w = "屯" }, { w = "堡" }, { w = "墩" }, { w = "烽" }, { w = "台" }, { w = "戍" }, { w = "镇" }, { w = "关" }, { w = "堡子" },
        { w = "泉" }, { w = "井" }, { w = "渠" }, { w = "河" }, { w = "坝" }, { w = "堰" }, { w = "湖" }, { w = "海子" }, { w = "涝坝" }, { w = "水库" },
        { w = "塬" }, { w = "梁" }, { w = "峁" }, { w = "坪" }, { w = "川" }, { w = "沟" }, { w = "岔" }, { w = "湾" }, { w = "滩" }, { w = "岘" }, { w = "崾岘" }, { w = "畔" },
        { w = "东" }, { w = "西" }, { w = "南" }, { w = "北" }, { w = "上" }, { w = "下" }, { w = "头" }, { w = "尾" }, { w = "里" },
        { w = "五里" }, { w = "七里" }, { w = "十里" }, { w = "二十里" }, { w = "三十里" }, { w = "五十里" }, { w = "五" }, { w = "七" }, { w = "十" }, { w = "二十" }, { w = "三十" },
        { w = "柳" }, { w = "杨" }, { w = "榆" }, { w = "沙枣" }, { w = "红柳" }, { w = "胡杨" }, { w = "梭梭" }, { w = "芦苇" }, { w = "甘草" }, { w = "瓜" }, { w = "葡萄" }, { w = "棉" }, { w = "苜蓿" }, { w = "枣" },
        { w = "红" }, { w = "黑" }, { w = "白" }, { w = "青" }, { w = "黄" }, { w = "灰" },
        { w = "大" }, { w = "小" }, { w = "新" }, { w = "老" }, { w = "旧" }, { w = "高" }, { w = "平" }, { w = "沙" }, { w = "碱" }, { w = "荒" }, { w = "甘" }, { w = "甜" }, { w = "苦" },
        { w = "张" }, { w = "王" }, { w = "李" }, { w = "赵" }, { w = "刘" }, { w = "陈" }, { w = "杨" }, { w = "马" }, { w = "吴" }, { w = "周" }, { w = "高" }, { w = "韩" }, { w = "魏" }, { w = "石" }, { w = "白" }, { w = "乔" }, { w = "雷" }, { w = "党" },
        { w = "安" }, { w = "平" }, { w = "永" }, { w = "昌" }, { w = "宁" }, { w = "靖" }, { w = "绥" }, { w = "定" }, { w = "和" }, { w = "顺" }, { w = "兴" }, { w = "丰" }, { w = "康" }, { w = "乐" },
        { w = "驿" }, { w = "店" }, { w = "铺" }, { w = "集" }, { w = "巴扎" },
        { w = "楼兰" }, { w = "龟兹" }, { w = "于阗" }, { w = "疏勒" }, { w = "高昌" }, { w = "鄯善" }, { w = "焉耆" }, { w = "姑墨" }, { w = "莎车" }, { w = "乌孙" }, { w = "车师" }, { w = "精绝" },
      },
    },

    constraints = {
      [=[字数：2 字＝西北汉语标准形（银川、兰州、酒泉、武威、榆林、吴忠）；3 字＝双音节通名（城子/庄子/堡子/海子）或民族语双音节（阿克苏、克孜勒）；4 字＝长音译词（克拉玛依、巴彦淖尔、呼和浩特）。]=],
      [=[构词次序（汉语）：专名（修饰）在前、通名（中心）在后。]=],
      [=[双语并行模式（四选一）：①汉语专名+汉语通名；②民族语专名整体音译（无汉语通名）；③民族语专名+汉语通名（拜城）；④同地双名并行（汉语名+民族语对音名）。]=],
      [=[拗口禁忌：避免四字全阴平/全仄声、连续同声母叠字（「苦苦库」）；避免双入声；以舒声字收尾。]=],
      [=[译字规范：民族语对音用字固定（阿克/喀拉/克孜勒/阔克/巴彦/浩特），不得自由换字（阿克不写「阿客」、克孜勒不写「柯孜勒」）。]=],
      [=[通名重叠禁忌：避免「XX城城」「XX堡堡」，一个地名只保留一个通名。]=],
      [=[谐音禁忌：避开不吉/贬义谐音（库=苦、克=克、沙=杀、塞、枯、死、荒）。]=],
    },

    translit = {
      { group = "维吾尔语（南疆为主）", entries = {
        { from = "aq", latin = "aq", w = "阿克", meaning = [=[白]=] },
        { from = "qara", latin = "qara", w = "喀拉/喀喇", meaning = [=[黑]=] },
        { from = "qizil", latin = "qizil", w = "克孜勒", meaning = [=[红]=] },
        { from = "kök", latin = "kök", w = "阔克/库克", meaning = [=[蓝/青/绿]=] },
        { from = "sarïq", latin = "seriq", w = "萨热克/色日克", meaning = [=[黄（色日克存疑个例）]=], suspicious = true },
        { from = "tagh", latin = "tagh", w = "塔格", meaning = [=[山]=] },
        { from = "qum", latin = "qum", w = "库木", meaning = [=[沙]=] },
        { from = "say", latin = "say", w = "萨依", meaning = [=[河滩/戈壁滩/干河床]=] },
        { from = "köl", latin = "köl", w = "库勒", meaning = [=[湖]=] },
        { from = "darya", latin = "darya", w = "达里亚", meaning = [=[河]=] },
        { from = "su", latin = "su", w = "苏", meaning = [=[水]=] },
        { from = "bulaq", latin = "bulaq", w = "布拉克", meaning = [=[泉（麦盖提布拉克存疑个例）]=], suspicious = true },
        { from = "muz", latin = "muz", w = "慕士", meaning = [=[冰]=] },
        { from = "döng", latin = "döng", w = "墩", meaning = [=[土丘/高台]=] },
        { from = "terek", latin = "terek", w = "铁热克", meaning = [=[杨树]=] },
        { from = "toghraq", latin = "toghraq", w = "托格拉克", meaning = [=[胡杨]=] },
        { from = "qosh", latin = "qosh", w = "阔什", meaning = [=[双/一对]=] },
        { from = "qush", latin = "qush", w = "库什", meaning = [=[鸟]=] },
        { from = "bagh", latin = "bagh", w = "巴格", meaning = [=[园/果园]=] },
        { from = "bazar", latin = "bazar", w = "巴扎", meaning = [=[集市]=] },
        { from = "kona", latin = "kona", w = "阔纳", meaning = [=[旧/老]=] },
        { from = "yengi", latin = "yengi", w = "英吉/英", meaning = [=[新]=] },
        { from = "mahalla", latin = "mahalla", w = "买里", meaning = [=[村/街区]=] },
        { from = "östeng", latin = "östeng", w = "吾斯塘", meaning = [=[渠]=] },
        { from = "bay", latin = "bay", w = "拜", meaning = [=[富]=] },
        { from = "awat", latin = "awat", w = "阿瓦提", meaning = [=[繁荣/兴旺]=] },
        { from = "saray", latin = "saray", w = "萨拉依/沙尔", meaning = [=[驿站/客店]=] },
        { from = "tash", latin = "tash", w = "塔什", meaning = [=[石]=] },
        { from = "yar", latin = "yar", w = "亚尔", meaning = [=[崖/河岸]=] },
      } },
      { group = "哈萨克语（北疆/伊犁/阿勒泰）", entries = {
        { from = "altay", w = "阿勒泰", meaning = [=[金山（altan 金）]=], note = nil },
        { from = "kök", w = "阔克/科克", meaning = [=[蓝/绿]=], note = nil },
        { from = "toqay", w = "托海", meaning = [=[河湾/灌木林/河漫滩]=], note = nil },
        { from = "bulaq", w = "布拉克", meaning = [=[泉]=], note = [=[布尔津（存疑）]=], suspicious = true },
        { from = "burqin", w = "布尔津", meaning = [=[三岁公驼/骆驼放牧地]=], note = [=[存疑]=], suspicious = true },
        { from = "jeminay", w = "吉木乃", meaning = [=[蒙古语借词]=], note = [=[存疑]=], suspicious = true },
        { from = "tarbaghatai", w = "塔尔巴哈台", meaning = [=[旱獭山（蒙古语）]=], note = nil },
      } },
      { group = "蒙古语（内蒙古西部/青海海西/新疆部分地区）", entries = {
        { from = "köke/höh", w = "呼和/库库", meaning = [=[蓝/青]=] },
        { from = "qota/hot", w = "浩特", meaning = [=[城/聚落]=] },
        { from = "ulaan", w = "乌兰", meaning = [=[红]=] },
        { from = "chagaan", w = "查干/察罕", meaning = [=[白]=] },
        { from = "qara/har", w = "哈拉/哈日", meaning = [=[黑]=] },
        { from = "bayan", w = "巴彦/巴音", meaning = [=[富饶]=] },
        { from = "naγur/nuur", w = "淖尔/诺尔", meaning = [=[湖]=] },
        { from = "γool/gol", w = "郭勒/高勒", meaning = [=[河]=] },
        { from = "aγula/uul", w = "乌拉/乌勒", meaning = [=[山]=] },
        { from = "sumu", w = "苏木", meaning = [=[乡/区]=] },
        { from = "gachaa", w = "嘎查", meaning = [=[村]=] },
        { from = "dabaan", w = "达坂/达瓦", meaning = [=[山口]=] },
        { from = "tal(a)", w = "塔拉/塔勒", meaning = [=[草原/平原]=] },
        { from = "küriye/hüree", w = "库伦/库勒", meaning = [=[围栏/城]=] },
        { from = "ordos", w = "鄂尔多斯", meaning = [=[宫帐（群）]=] },
        { from = "shiliin", w = "锡林", meaning = [=[山梁/丘陵]=] },
      } },
      { group = "藏语（青海为主）", entries = {
        { from = "chu", w = "曲/楚", meaning = [=[水/河]=] },
        { from = "mtsho", w = "措/错", meaning = [=[湖]=] },
        { from = "gangs", w = "岗/贡", meaning = [=[雪山/山]=] },
        { from = "lha", w = "拉", meaning = [=[神（拉加存疑）]=], suspicious = true },
        { from = "rdzong", w = "宗", meaning = [=[城堡/县]=] },
        { from = "thang", w = "塘/唐", meaning = [=[平原/坝子]=] },
      } },
    },
    translitNote = [=[裕固语、东乡语语料少、成片汉化，虚构时慎用/不用（近似可用蒙古/突厥语部件）。]=],

    banned = {
      chars     = { "库", "克", "沙", "塞", "枯", "死", "荒", "贫", "崮" },
      suffixes  = {},
      words     = { "旱灾" },
      realNames = {
        "嘉峪关", "玉门关", "阳关", "萧关", "铁门关", "武威", "张掖", "酒泉", "敦煌", "中卫", "吴忠", "阿克苏", "喀什", "克拉玛依", "呼和浩特", "包头", "鄂尔多斯", "巴彦淖尔",
        "石河子", "阿拉尔", "图木舒克", "五家渠", "北屯", "双河", "可克达拉", "昆玉", "胡杨河", "新星", "白杨",
        "楼兰", "龟兹", "于阗", "疏勒", "高昌", "塔里木", "天山", "祁连",
      },
      rules = {
        [=[禁止/慎用字：消极谐音（库=苦、克=克、沙=杀、塞、枯、死、荒、贫、旱灾）；「崮」等非西北地貌通名。]=],
        [=[禁止的通名组合：通名重叠（专名与通名同字重复「沙沙」「堡堡」）；叠床架屋（XX城城）。]=],
        [=[译字规范：民族语对音用字固定，不得自由换字（阿克不写「阿客」、喀拉不写「卡拉」、克孜勒不写「柯孜勒」）。]=],
        [=[真实地名黑名单：①县级以上政区名全避（陕甘宁青新内蒙古西部全部地级市/县/县级市/区）；②著名军镇/关隘/绿洲（嘉峪关、玉门关、阳关、萧关、铁门关、武威、张掖、酒泉、敦煌、中卫、吴忠、阿克苏、喀什、克拉玛依、呼和浩特、包头、鄂尔多斯、巴彦淖尔）；③兵团师部城市名全避（石河子、阿拉尔、图木舒克、五家渠、北屯、铁门关、双河、可克达拉、昆玉、胡杨河、新星、白杨）；④著名自然地名/古国名慎用（楼兰、龟兹、于阗、疏勒、高昌、塔里木、天山、祁连，可用但需变形）。]=],
      },
    },

    algorithm = {
      [=[选模式：纯汉语 / 民族语对音 / 混合 / 双语双名 四选一。]=],
      [=[抽取部件：按语义域从专名部件表（方位/里程/颜色/地貌修饰/物产植被/姓氏/吉祥）与通名表（军事/水利/地形/聚落）抽取。]=],
      [=[拼装：依规则 X1–X9 成词；汉语式＝修饰语+通名；民族语式＝颜色对音+自然通名对音（或民族语专名+汉语通名）。]=],
      [=[兵团层级（可选）：师部城 + 数字团（如"一四七团"）+ 数字连。]=],
      [=[过滤：通名重叠、消极谐音、译字规范、声调平衡、避让真实名（§7 四级黑名单 + 自检 8 项）。]=],
    },
  },

  ---------------------------------------------------------------------------
  -- 亚寒带（外满洲 / 今俄罗斯远东）
  ---------------------------------------------------------------------------
  subarctic = {

    style = {
      [=[特化通名：崴/泡/岗/砬子/甸子/卡伦/窝棚/地窨子 出现即锁定北疆/关东。]=],
      [=[渔猎物产专名：鲟/鳇/鲑/大马哈/貂/狍/獾/海东青/参 直指寒地渔猎经济。]=],
      [=[满语式三音节音译：乌苏里/图们/吉林/宁古塔/阿勒楚喀/齐齐哈尔/尼布楚 的「乌/苏/图/吉/宁/喀/楚/齐/库/呼」音型。]=],
      [=[寒冷水文意象：冰/雪/霜/凌/冻/寒 大量入名。]=],
      [=[数词 + 通名的朴素构词：双城子 / 三姓 / 六十四屯（不用中原式的 ×州/×县）。]=],
      [=[方位 + 江/岭：以「江（黑龙江）」为基准坐标（江东/江北/外兴安岭）。]=],
    },

    templates = {
      { id = "Y1", formula = [=[海参崴式（主）：修饰? + 物产|水文|矿业 + 地形|水域通名]=], seq = { "plant", "terrain_suffix" }, weight = nil, weightNote = [=[报告标「主」]=], note = [=[白桦岗、鲟鱼泡、砂金沟（修饰? 可选前置；物产|水文|矿业亦可取 water/mining）]=] },
      { id = "Y2", formula = [=[庙街/双城子式：数词|方位|地标 + 类通名(+子)]=], seq = { "number", "suffix" }, weight = nil, note = [=[双城子、三姓、江左屯（前缀亦可 direction）]=] }, --[[W?]]
      { id = "Y3", formula = [=[戍边式：方位|修饰 + 戍边通名]=], seq = { "direction", "suffix" }, weight = nil, note = [=[北卡伦、老营、青哨（前缀亦可 modifier）]=] }, --[[W?]]
      { id = "Y4", formula = [=[满语音译点缀：满语词根组合再音译]=], seq = nil, weight = nil, weightNote = [=[报告标「≤10% 混入」]=], note = [=[依兰必喇（三河）、宁古霍屯（六城）、安巴哈达（大崖）；使用满语 translit 表]=] },
      { id = "gen", formula = [=[两大范式：海参崴式（[物产|特征|数词]+[地形通名]，三段式）；庙街式（[地标|数词|方位|概念]+[类通名](+子/儿)，两段式）]=], seq = { "single", "suffix" }, weight = nil, note = nil }, --[[W?]]
    },

    suffixes = {
      -- 地形
      { w = "崴 / 崴子", etymon = [=[水湾、海湾、山湾（东北方言 wǎi）]=], scene = [=[地形]=], weight = nil, note = [=[海参崴；「崴子」为最典型北疆通名]=], group = "landform" }, --[[W?]]
      { w = "泡 / 泡子", etymon = [=[湖沼、水泡子（黑土地带）]=], scene = [=[地形]=], weight = nil, note = [=[海兰泡]=], group = "landform" }, --[[W?]]
      { w = "岗 / 冈 / 岡", etymon = [=[山岗、沙岗、高阜]=], scene = [=[地形]=], weight = nil, note = [=[兴凯湖沙岗]=], group = "landform" }, --[[W?]]
      { w = "砬子 / 砬", etymon = [=[巨石崖、陡峭石壁（东北方言 lá）]=], scene = [=[地形]=], weight = nil, note = [=[白石砬子]=], group = "landform" }, --[[W?]]
      { w = "岭 / 甸子", etymon = [=[山岭 / 草甸、湿地]=], scene = [=[地形]=], weight = nil, note = [=[外兴安岭；甸/甸子=草甸湿地]=], group = "landform" }, --[[W?]]
      { w = "沟 / 岔", etymon = [=[沟谷 / 岔口]=], scene = [=[地形]=], weight = nil, note = [=[老沟、胭脂沟]=], group = "landform" }, --[[W?]]
      -- 居所 / 屯垦
      { w = "屯", etymon = [=[屯落、村屯]=], scene = [=[居所]=], weight = nil, note = [=[江东六十四屯、孟家屯、黑河屯]=], group = "dwelling" }, --[[W?]]
      { w = "窝棚 / 窝堡", etymon = [=[简易渔猎居所]=], scene = [=[居所]=], weight = nil, note = [=[三江平原常见]=], group = "dwelling" }, --[[W?]]
      { w = "地窨子 / 地窨", etymon = [=[半地穴式居所（严冬防寒）]=], scene = [=[居所]=], weight = nil, note = [=[亚寒带特有，强辨识]=], group = "dwelling" }, --[[W?]]
      { w = "城子", etymon = [=[小城/土城 + 子缀]=], scene = [=[居所]=], weight = nil, note = [=[双城子]=], group = "dwelling" }, --[[W?]]
      { w = "连 / 队", etymon = [=[近现代农垦区划]=], scene = [=[屯垦]=], weight = nil, note = [=[北大荒农垦「×连/×队」]=], group = "dwelling" }, --[[W?]]
      -- 戍边 / 军事
      { w = "卡伦", etymon = [=[哨所（满语 karun）]=], scene = [=[戍边]=], weight = nil, note = [=[漠河八卡伦]=], group = "military" }, --[[W?]]
      { w = "哨 / 台 / 墩", etymon = [=[边防哨、烽台、瞭望墩]=], scene = [=[戍边]=], weight = nil, note = [=[烽燧体系]=], group = "military" }, --[[W?]]
      { w = "营 / 水师营", etymon = [=[驻军、水军驻地]=], scene = [=[戍边]=], weight = nil, note = [=[黑龙江城水师营]=], group = "military" }, --[[W?]]
      { w = "堡 / 城 / 卫 / 所", etymon = [=[城堡、卫所]=], scene = [=[戍边]=], weight = nil, note = [=[五常堡、勃利州（城）]=], group = "military" }, --[[W?]]
      -- 水域
      { w = "江 / 河 / 溪 / 汊", etymon = [=[河流各形态]=], scene = [=[水域]=], weight = nil, note = [=[黑龙江、乌苏里江]=], group = "water" }, --[[W?]]
      { w = "岛 / 渚 / 屿", etymon = [=[岛屿]=], scene = [=[水域]=], weight = nil, note = [=[库页岛、黑瞎子岛]=], group = "water" }, --[[W?]]
      { w = "泡 / 沼 / 洼 / 甸", etymon = [=[湖沼湿地]=], scene = [=[水域]=], weight = nil, note = [=[与地形类部分重叠]=], group = "water" }, --[[W?]]
      -- 生产 / 仓储
      { w = "仓", etymon = [=[粮仓]=], scene = [=[生产]=], weight = nil, note = [=[拉林仓（清军屯粮）]=], group = "production" }, --[[W?]]
      { w = "盐场", etymon = [=[盐场]=], scene = [=[生产]=], weight = nil, note = [=[滨海盐场]=], group = "production" }, --[[W?]]
      { w = "金矿 / 金沟 / 砂金 / 老金沟", etymon = [=[金矿]=], scene = [=[生产]=], weight = nil, note = [=[漠河金矿、老沟、胭脂沟]=], group = "production" }, --[[W?]]
      { w = "参场 / 貂场 / 渔场", etymon = [=[渔猎采集场]=], scene = [=[生产]=], weight = nil, note = [=[参场、貂场]=], group = "production" }, --[[W?]]
      { w = "木营 / 木城 / 林场 / 林子", etymon = [=[伐木营、林场]=], scene = [=[生产]=], weight = nil, note = [=[林海伐木]=], group = "production" }, --[[W?]]
      { w = "船厂", etymon = [=[造船地]=], scene = [=[生产]=], weight = nil, note = [=[吉林市绰号「船厂」]=], group = "production" }, --[[W?]]
      { w = "站 / 台 / 铺", etymon = [=[驿站]=], scene = [=[生产/交通]=], weight = nil, note = [=[漠河为江上驿站]=], group = "production" }, --[[W?]]
    },

    -- 自然地理通名（地形 + 水域）
    terrain_suffix = {
      { w = "崴 / 崴子", weight = nil, note = [=[海参崴；「崴子」为最典型北疆通名]=] }, { w = "泡 / 泡子", weight = nil, note = [=[海兰泡]=] }, { w = "岗 / 冈 / 岡", weight = nil, note = [=[兴凯湖沙岗]=] }, { w = "砬子 / 砬", weight = nil, note = [=[白石砬子]=] }, { w = "岭 / 甸子", weight = nil, note = [=[外兴安岭；甸/甸子=草甸湿地]=] },
      { w = "沟 / 岔", weight = nil, note = [=[老沟、胭脂沟]=] },
      { w = "江 / 河 / 溪 / 汊", weight = nil, note = [=[黑龙江、乌苏里江]=] }, { w = "岛 / 渚 / 屿", weight = nil, note = [=[库页岛、黑瞎子岛]=] }, { w = "泡 / 沼 / 洼 / 甸", weight = nil, note = [=[与地形类部分重叠]=] },
    },

    -- 吉祥通名（亚寒带无吉祥字主题，留空）
    auspicious_suffix = {},

    parts = {
      -- 寒地物产与渔猎 → plant（物产，含渔猎动物）
      plant = {
        { w = "参", weight = nil, note = nil }, { w = "海参", weight = nil, note = nil }, { w = "珠", weight = nil, note = nil }, { w = "鲟", weight = nil, note = nil }, { w = "鳇", weight = nil, note = nil },
        { w = "鲑", weight = nil, note = nil }, { w = "大马哈", weight = nil, note = nil }, { w = "鱼", weight = nil, note = nil }, { w = "哈什蚂", weight = nil, note = nil },
        { w = "貂", weight = nil, note = nil }, { w = "鹿", weight = nil, note = nil }, { w = "狍", weight = nil, note = nil }, { w = "獾", weight = nil, note = nil }, { w = "熊", weight = nil, note = nil },
        { w = "虎", weight = nil, note = nil }, { w = "水獭", weight = nil, note = nil }, { w = "狐", weight = nil, note = nil },
        { w = "鹰", weight = nil, note = nil }, { w = "海东青", weight = nil, note = nil }, { w = "雁", weight = nil, note = nil }, { w = "鹤", weight = nil, note = nil }, { w = "野鸭", weight = nil, note = nil },
        { w = "桦", weight = nil, note = nil }, { w = "松", weight = nil, note = nil }, { w = "柞", weight = nil, note = nil }, { w = "椴", weight = nil, note = nil }, { w = "柳", weight = nil, note = nil },
        { w = "榆", weight = nil, note = nil }, { w = "落叶松", weight = nil, note = nil }, { w = "红松", weight = nil, note = nil }, { w = "白桦", weight = nil, note = nil },
        { w = "苔", weight = nil, note = nil }, { w = "蕨", weight = nil, note = nil }, { w = "蕨菜", weight = nil, note = nil }, { w = "蘑", weight = nil, note = nil }, { w = "松茸", weight = nil, note = nil },
        { w = "木耳", weight = nil, note = nil }, { w = "蓝莓", weight = nil, note = nil }, { w = "都柿", weight = nil, note = nil }, { w = "松子", weight = nil, note = nil },
      },
      -- 水文形态（寒冷意象）
      water = {
        { w = "冰", weight = nil, note = nil }, { w = "雪", weight = nil, note = nil }, { w = "霜", weight = nil, note = nil }, { w = "寒", weight = nil, note = nil }, { w = "冻", weight = nil, note = nil },
        { w = "凌", weight = nil, note = nil }, { w = "凌汛", weight = nil, note = nil }, { w = "汛", weight = nil, note = nil }, { w = "泡", weight = nil, note = nil }, { w = "沼", weight = nil, note = nil },
        { w = "洼", weight = nil, note = nil }, { w = "甸", weight = nil, note = nil }, { w = "湾", weight = nil, note = nil }, { w = "滩", weight = nil, note = nil }, { w = "沙", weight = nil, note = nil },
        { w = "淤", weight = nil, note = nil },
      },
      -- 军事戍边
      garrison = {
        { w = "营", weight = nil, note = nil }, { w = "哨", weight = nil, note = nil }, { w = "卡", weight = nil, note = nil }, { w = "台", weight = nil, note = nil }, { w = "堡", weight = nil, note = nil },
        { w = "城", weight = nil, note = nil }, { w = "卫", weight = nil, note = nil }, { w = "所", weight = nil, note = nil }, { w = "镇", weight = nil, note = nil }, { w = "关", weight = nil, note = nil },
        { w = "隘", weight = nil, note = nil }, { w = "墩", weight = nil, note = nil }, { w = "寨", weight = nil, note = nil },
      },
      -- 矿业
      mining = {
        { w = "金", weight = nil, note = nil }, { w = "煤", weight = nil, note = nil }, { w = "铁", weight = nil, note = nil }, { w = "砂金", weight = nil, note = nil }, { w = "银", weight = nil, note = nil },
        { w = "矿", weight = nil, note = nil }, { w = "老金", weight = nil, note = nil }, { w = "胭脂", weight = nil, note = nil }, { w = "胭脂沟", weight = nil, note = nil },
      },
      -- 屯垦
      farming = {
        { w = "屯", weight = nil, note = nil }, { w = "窝棚", weight = nil, note = nil }, { w = "地窨子", weight = nil, note = nil }, { w = "连", weight = nil, note = nil }, { w = "队", weight = nil, note = nil },
        { w = "仓", weight = nil, note = nil }, { w = "场", weight = nil, note = nil }, { w = "垦", weight = nil, note = nil }, { w = "荒", weight = nil, note = nil },
      },
      -- 数词 / 方位 / 修饰
      number = {
        { w = "单", weight = nil, note = [=[例：双城子、三姓、六十四屯]=] }, { w = "双", weight = nil, note = [=[例：双城子、三姓、六十四屯]=] }, { w = "三", weight = nil, note = [=[例：双城子、三姓、六十四屯]=] }, { w = "五", weight = nil, note = [=[例：双城子、三姓、六十四屯]=] }, { w = "六", weight = nil, note = [=[例：双城子、三姓、六十四屯]=] },
        { w = "七", weight = nil, note = [=[例：双城子、三姓、六十四屯]=] }, { w = "八", weight = nil, note = [=[例：双城子、三姓、六十四屯]=] }, { w = "九", weight = nil, note = [=[例：双城子、三姓、六十四屯]=] }, { w = "十", weight = nil, note = [=[例：双城子、三姓、六十四屯]=] }, { w = "百", weight = nil, note = [=[例：双城子、三姓、六十四屯]=] },
      },
      direction = {
        { w = "东", weight = nil, note = [=[以黑龙江为基准坐标]=] }, { w = "西", weight = nil, note = [=[以黑龙江为基准坐标]=] }, { w = "南", weight = nil, note = [=[以黑龙江为基准坐标]=] }, { w = "北", weight = nil, note = [=[以黑龙江为基准坐标]=] }, { w = "江左", weight = nil, note = [=[以黑龙江为基准坐标]=] },
        { w = "江右", weight = nil, note = [=[以黑龙江为基准坐标]=] }, { w = "岭外", weight = nil, note = [=[以黑龙江为基准坐标]=] }, { w = "岭北", weight = nil, note = [=[以黑龙江为基准坐标]=] },
      },
      modifier = {
        { w = "青", weight = nil, note = nil }, { w = "白", weight = nil, note = nil }, { w = "黑", weight = nil, note = nil }, { w = "老", weight = nil, note = nil }, { w = "大", weight = nil, note = nil },
        { w = "小", weight = nil, note = nil }, { w = "新", weight = nil, note = nil }, { w = "旧", weight = nil, note = nil }, { w = "孤", weight = nil, note = nil }, { w = "卧", weight = nil, note = nil },
      },
      -- 单字专名核心总池
      single = {
        { w = "参" }, { w = "海参" }, { w = "珠" }, { w = "鲟" }, { w = "鳇" }, { w = "鲑" }, { w = "大马哈" }, { w = "鱼" }, { w = "哈什蚂" },
        { w = "貂" }, { w = "鹿" }, { w = "狍" }, { w = "獾" }, { w = "熊" }, { w = "虎" }, { w = "水獭" }, { w = "狐" },
        { w = "鹰" }, { w = "海东青" }, { w = "雁" }, { w = "鹤" }, { w = "野鸭" },
        { w = "桦" }, { w = "松" }, { w = "柞" }, { w = "椴" }, { w = "柳" }, { w = "榆" }, { w = "落叶松" }, { w = "红松" }, { w = "白桦" },
        { w = "苔" }, { w = "蕨" }, { w = "蕨菜" }, { w = "蘑" }, { w = "松茸" }, { w = "木耳" }, { w = "蓝莓" }, { w = "都柿" }, { w = "松子" },
        { w = "冰" }, { w = "雪" }, { w = "霜" }, { w = "寒" }, { w = "冻" }, { w = "凌" }, { w = "凌汛" }, { w = "汛" }, { w = "泡" }, { w = "沼" }, { w = "洼" }, { w = "甸" }, { w = "湾" }, { w = "滩" }, { w = "沙" }, { w = "淤" },
        { w = "营" }, { w = "哨" }, { w = "卡" }, { w = "台" }, { w = "堡" }, { w = "城" }, { w = "卫" }, { w = "所" }, { w = "镇" }, { w = "关" }, { w = "隘" }, { w = "墩" }, { w = "寨" },
        { w = "金" }, { w = "煤" }, { w = "铁" }, { w = "砂金" }, { w = "银" }, { w = "矿" }, { w = "老金" }, { w = "胭脂" }, { w = "胭脂沟" },
        { w = "屯" }, { w = "窝棚" }, { w = "地窨子" }, { w = "连" }, { w = "队" }, { w = "仓" }, { w = "场" }, { w = "垦" }, { w = "荒" },
        { w = "单" }, { w = "双" }, { w = "三" }, { w = "五" }, { w = "六" }, { w = "七" }, { w = "八" }, { w = "九" }, { w = "十" }, { w = "百" },
        { w = "东" }, { w = "西" }, { w = "南" }, { w = "北" }, { w = "江左" }, { w = "江右" }, { w = "岭外" }, { w = "岭北" },
        { w = "青" }, { w = "白" }, { w = "黑" }, { w = "老" }, { w = "大" }, { w = "小" }, { w = "新" }, { w = "旧" }, { w = "孤" }, { w = "卧" },
      },
    },

    constraints = {
      [=[字数分布：2 字＝音译或极简自造（伯力、庙街、依兰、珲春、瑷珲、漠河、五常）；3 字＝自造或音译（海参崴、双城子、海兰泡、宁古塔、尼布楚、雅克萨）；4 字＝满语音译（阿勒楚喀、齐齐哈尔、吉林乌拉、外兴安岭）；≥5 字＝描述性长名（江东六十四屯），罕见慎用。]=],
      [=[两大范式：海参崴式（三段式：物产/特征/数词 + 地形通名）；庙街式（两段式：地标/数词/方位/概念 + 类通名 + 子/儿）。]=],
      [=[满语式音译音型：双音节 + 汉语通名（乌苏里+江、兴凯+湖、海兰+泡、漠+河）；三音节独立（宁古塔、尼布楚、雅克萨）；AABB 叠字（齐齐哈尔）；高频音译字「乌/苏/图/吉/宁/喀/楚/库/齐/呼/穆/雅/勒」。]=],
      [=[满语通名词根（可作后缀）：ula（江）、hoton（城）、bira（河）、hada（崖）、alin（山）、karun（哨/卡伦）、mudan（弯）、boo（屯/房）。]=],
      [=[应避免的「像中原」组合：×州/×县/×府/×郡/×阳/×阴/×陵；南方/关内物产（茶/竹/桂/樟/梅/樱/荷/莲）；园林化书卷气词汇（栖霞/听雨/流觞/兰亭/锦绣）；现代行政区划词（新区/开发区/高新区/产业园）。]=],
      [=[语源自洽：纯汉语自造或满语音译，二者不混杂词。]=],
    },

    translit = {
      { group = "满语通名词根（可作后缀/对音）", entries = {
        { from = "ula", latin = "ula", meaning = [=[江]=], note = [=[乌苏里、吉林乌拉、牡丹江]=] },
        { from = "hoton", latin = "hoton", meaning = [=[城]=], note = [=[宁古霍屯（模拟）、阿勒楚喀城]=] },
        { from = "bira", latin = "bira", meaning = [=[河]=], note = [=[漠河（mo bira）、依兰必喇（模拟）]=] },
        { from = "hada", latin = "hada", meaning = [=[崖]=], note = [=[库页（sahaliyan ula angga hada）]=] },
        { from = "alin", latin = "alin", meaning = [=[山]=], note = [=[外兴安岭]=] },
        { from = "karun", latin = "karun", meaning = [=[哨/卡伦]=], note = [=[卡伦]=] },
        { from = "mudan", latin = "mudan", meaning = [=[弯]=], note = [=[牡丹江（弯曲的江）]=] },
        { from = "boo", latin = "boo", meaning = [=[屯/房]=], note = [=[海兰泡（Hailan Boo 榆树屯）]=] },
      } },
      { group = "满语式音译高频音型与高频字", entries = {
        { category = [=[结尾音型]=], content = [=[-乌拉 / -图们 / -吉林 / -宁古 / -阿勒楚喀]=] },
        { category = [=[高频音译字]=], content = [=[乌、苏、图、吉、宁、喀、楚、库、齐、呼、穆、雅、勒]=] },
        { category = [=[三音节独立音译]=], content = [=[宁古塔、尼布楚、雅克萨、珲春（双字）]=] },
        { category = [=[AABB 叠字]=], content = [=[齐齐哈尔]=] },
      } },
      { group = "数词对音（满语音译，含「塔」为 -ta 音译非汉字「塔」义）", entries = {
        { from = "ilan", w = "依兰", meaning = [=[三（ilan hala＝三姓）]=] },
        { from = "ninggun", w = "宁古", meaning = [=[六（ningguta＝每六个）]=] },
      } },
    },
    translitNote = [=[警示：R4/Y4 生成的「满语式音型模拟」，其满语义仅当词根确证时才成立；写进设定时应仅作「音译地名」处理，不附会虚构的满语义。]=],

    banned = {
      chars     = { "茶", "竹", "桂", "樟", "梅", "樱", "荷", "莲" },
      suffixes  = { "州", "县", "府", "郡", "阳", "阴", "陵", "新区", "开发区", "高新区", "新城" },
      words     = {},
      realNames = { "海参崴", "庙街", "伯力", "双城子", "海兰泡", "尼布楚", "雅克萨", "瑷珲", "珲春", "依兰", "宁古塔", "三姓", "阿勒楚喀", "吉林", "齐齐哈尔", "漠河" },
      rules = {
        [=[禁止字/通名：中原通名（州/县/府/郡/阳/阴/陵）；现代通名（新区/开发区/高新区/新城）；关内/南方物产（茶/竹/桂/樟/梅/樱/荷/莲）。]=],
        [=[禁止组合：语源混杂（纯汉语自造与满语音译不混词）；编辑距离 < 1 的近撞（「鲟鱼泡」vs「鲟鱼泡子」）。]=],
        [=[音近避让：与真实地名拼音/谐音近似（「海参湾」撞「海参崴」联想）→ 丢弃或降级。]=],
        [=[真实地名黑名单：外满洲/东北全部真实地名（海参崴、庙街、伯力、双城子、海兰泡、尼布楚、雅克萨、瑷珲、珲春、依兰、宁古塔、三姓、阿勒楚喀、吉林、齐齐哈尔、漠河…）+ 全国县级以上行政区划名 + 知名聚落名。]=],
        [=[联想避让：禁「同首段专名」变体（真实「海参崴」→ 禁「海参×」全系）。]=],
      },
    },

    algorithm = {
      [=[定范式：海参崴式（主）/ 庙街式 / 戍边式 三选一，满语音译（Y4）仅 ≤10% 点缀。]=],
      [=[抽取部件：从专名部件表（物产/水文/戍边/矿业/屯垦/数词/方位/修饰）与通名表（地形/水域/居所/戍边/生产）抽取。]=],
      [=[拼装：Y1＝修饰? + 物产|水文|矿业 + 地形|水域通名（白桦岗）；Y2＝数词|方位|地标 + 类通名(+子)（双城子）；Y3＝方位|修饰 + 戍边通名（北卡伦）；Y4＝满语词根组合再音译（依兰必喇）。]=],
      [=[过滤：精确命中真实地名→丢弃；含中原/现代/关内物产→丢弃；近撞（编辑距离 < 1）→丢弃；音近真实名→丢弃或降级；去重。]=],
      [=[产量参考：部件库 P≈60、T≈40、修饰/数词/方位≈30，R1 组合空间约 3.3 万，过滤后稳定产出数百至数千不重复名。]=],
    },
  },
}

-- 通名门槛（街道用，城市名留空表即可）
M.thresholds = {}

return M

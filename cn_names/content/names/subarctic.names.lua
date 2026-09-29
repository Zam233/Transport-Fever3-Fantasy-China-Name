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
--[[--------------------------------------------------------------------------
  subarctic.names.lua —— 名称集：中国·亚寒带

  城市命名：东北（华北）
  街道命名：东北（华北）

  注意：TF3 只有一个「名称集」选项，它**同时**决定城镇名、道路名与居民姓名
  （游戏内 tooltip：改变游戏中城镇、道路名称和居民姓名的来源地区）。
  因此本名称集同时提供 townNamesScript 与 streetNamesScript。
--------------------------------------------------------------------------]]

function data()
  return {
    name = _("nameset_subarctic"),

    personNamesScript = {
      fileName = "/names/names.script@personNameScriptFn",
      params = { style = "subarctic" },
    },

    townNamesScript = {
      fileName = "/names/names.script@townsNameScriptFn",
      params = { style = "subarctic" },
    },

    streetNamesScript = {
      fileName = "/names/names.script@streetsNameScriptFn",
      params = { style = "subarctic" },
    },
  }
end
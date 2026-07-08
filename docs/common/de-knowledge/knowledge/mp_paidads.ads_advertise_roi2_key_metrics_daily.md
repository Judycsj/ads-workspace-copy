<!-- ads-workspace-gdoc-sync: gdoc_id=15SOJ9GJ-WpMKGdUITHW-uig-lmcFB6qpN996BGG5O-o gdoc_url=https://docs.google.com/document/d/15SOJ9GJ-WpMKGdUITHW-uig-lmcFB6qpN996BGG5O-o/edit -->

# mp_paidads.ads_advertise_roi2_key_metrics_daily

**分层**：ADS（应用数据服务层）
**主键**：`grass_region + grass_date + ads_id + pricing_type`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日（T+1，覆盖前一自然日数据）
**引用频次**：0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表是付费广告（ROI2 模式）广告位维度的**每日核心指标汇总表**，粒度为 `grass_region × grass_date × ads_id × pricing_type`，仅覆盖 placement = 40 的搜索/展示广告位，且排除 pricing_type = 29 的计费类型。表中同时汇聚了 ROI2 口径（基于广告花费与 GMV 的常规 ROI 衡量）和 ROI3 口径（叠加优惠券 Voucher 维度的增强 ROI 衡量）的绩效指标，是广告效果分析、ROI 达标评估、预算管理及 Rapid Boost 功能监控的**核心数据底座**。

本表的核心价值体现在以下几个场景：（1）**ROI 达标度分析**：通过 `roi_ratio_group`（14 日口径）和 `roi_ratio_group_7d`（7 日口径）等预计算分组字段，可快速评估广告 ROI 相对目标值的偏差分布；（2）**Rapid Boost 效果监控**：提供 `is_rapid_boost_toggle_on_1d/7d`、`roi_ratio_group_7d_for_rapid_boost` 等字段，支撑 Rapid Boost 功能的开关率与 ROI 达标追踪；（3）**广告质量分层**：通过 `is_new_ads`、`is_cold_start_stage`、`is_active_ads` 等标签字段，支持广告冷启动、新老广告的差异化分析。

各地区按本地时区参数化调度，消费数据以各地区本地时间（`tz_type = 'local'`）为准进行汇总，确保广告绩效数据与本地业务时间对齐。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `tz_type` | string | 时区类型，固定写入值为 `'local'`（本地时区），查询时必须指定 |
| `grass_region` | string | 市场/地区标识（大写），如 `'MY'`、`'TH'`，按各地区参数化调度 |
| `grass_date` | date | 业务日期（本地时区），格式 `yyyy-MM-dd`，对应 `BIZ_YESTERDAY` |

---

### 维度：主键与广告基本属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `ads_id` | bigint | 广告 ID，与 `pricing_type` 联合构成唯一广告标识 |
| `placement` | bigint | 广告位 ID，本表固定为 `40`（搜索/展示广告位） |
| `pricing_type` | int | 计费类型，本表排除 `29`，与 `ads_id` 联合作为主键 |
| `campaign_id` | bigint | 广告计划 ID |
| `shop_id` | bigint | 店铺 ID |
| `item_id` | bigint | 商品 ID |
| `ads_create_datetime` | string | 广告创建时间（字符串格式） |
| `ads_status` | bigint | 广告状态码 |
| `campaign_status` | tinyint | 广告计划状态码 |

---

### 维度：广告分类与商家属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `level1_global_be_category` | struct<level1_global_be_category_id:bigint, level1_global_be_category:string> | 全球一级后台类目（含 ID 和名称）。⚠️ 为 struct 复合类型，查询时需用 `.level1_global_be_category_id` 或 `.level1_global_be_category` 访问子字段 |
| `level2_global_be_category` | struct<level2_global_be_category_id:bigint, level2_global_be_category:string> | 全球二级后台类目（含 ID 和名称）。⚠️ 同上，为 struct 复合类型 |
| `level3_global_be_category` | struct<level3_global_be_category_id:bigint, level3_global_be_category:string> | 全球三级后台类目（含 ID 和名称）。⚠️ 同上，为 struct 复合类型 |
| `seller_type_1p` | string | 卖家类型，标识是否为 1P（自营）卖家 |
| `is_cb_shop` | tinyint | 是否跨境店铺（Cross-Border），1=是，0=否 |
| `is_cb_sip_affiliated` | tinyint | 是否隶属于跨境 SIP（Shop-in-Shop）计划，1=是，0=否 |
| `is_local_sip_affiliated` | tinyint | 是否隶属于本地 SIP 计划，1=是，0=否 |

---

### 维度：广告状态与质量标签

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `is_active_ads` | tinyint | 是否活跃广告（当日有展示或有花费或有宽泛订单），1=是，0=否 |
| `is_new_ads` | tinyint | 是否新广告（过去 14 日内无展示记录），1=是，0=否 |
| `is_cold_start_stage` | tinyint | 是否处于冷启动阶段，通过广告 Tag 位第 34 位解析，取当日最新一条有展示记录推断 |
| `is_limited_budget` | tinyint | 当日广告计划是否受预算限制（`budget_usd ≠ 9999999999` 视为受限），1=是，0=否 |
| `is_ocpm_1d` | tinyint | 当日是否为 oCPM 出价模式，1=是，0=否 |
| `is_rapid_boost_toggle_on_1d` | tinyint | 当日是否开启 Rapid Boost 功能，1=是，0=否 |
| `is_rapid_boost_toggle_on_7d` | tinyint | 过去 7 日内是否曾开启 Rapid Boost 功能，1=是，0=否 |

---

### 维度：ROI 目标与推荐值

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `target_roi` | double | 广告计划设定的目标 ROI 值（来自 `dim_campaign`，即卖家设置的 `roi_two`） |
| `is_valid_roi` | string | ROI 有效性判断：`'valid'`（target_roi ≤ suggest_value_3 × 1.25）、`'higher'`（目标值偏高）、`'null'`（无推荐值）。⚠️ 为派生分类字段，不可用于数值聚合 |
| `suggest_value_1` | double | 系统推荐 ROI 值第 1 档（来自 `final_value_list[0]`） |
| `suggest_value_2` | double | 系统推荐 ROI 值第 2 档（来自 `final_value_list[1]`） |
| `suggest_value_3` | double | 系统推荐 ROI 值第 3 档（来自 `final_value_list[2]`），用于 `is_valid_roi` 判断阈值 |

---

### 维度：ROI 分组标签

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `roi_ratio_group` | string | 基于 14 日广告花费与 GMV 比率（本地货币口径）的 ROI 分组，取值：`'0-0.5'`/`'0.5-0.75'`/`'0.75-1'`/`'1-1.25'`/`'1.25-2'`/`'2+'`/`'no gmv'`/`'no rev'`/`'no data'`。⚠️ 为预计算分类字段，不可直接 SUM，不同分组的边界基于本地货币 ROI ratio |
| `roi_ratio_group_7d` | string | 基于 7 日广告花费与 GMV 比率（本地货币口径）的 ROI 分组，取值：`'0-0.5'`/`'0.5-0.8'`/`'0.8-1'`/`'1-1.2'`/`'1.2-2'`/`'2+'`/`'no gmv'`/`'no rev'`/`'no data'`。⚠️ 同上，为预计算分类字段 |
| `roi_ratio_group_7d_for_rapid_boost` | string | 针对 Rapid Boost 的 7 日 ROI 分组（基于 ROI 上限 `roi_upper_bound` 口径），仅当 `is_rapid_boost_toggle_on_7d = 1` 时有值，否则为 null，取值：`'0-0.7'`/`'0.7-1'`/`'1+'`/`'no gmv'`/`'no rev'`/`'no data'`。⚠️ 为预计算分类字段，且与常规 ROI 分组口径不同 |
| `seller_setting_roi_ratio_group_7d_for_rapid_boost` | string | 基于卖家设定 `target_roi` 的 Rapid Boost 7 日 ROI 分组（分母为 `target_roi × roi2_ads_revenue_7d_usd`），仅当 `is_rapid_boost_toggle_on_7d = 1` 时有值，取值同 `roi_ratio_group_7d_for_rapid_boost`。⚠️ 与 `roi_ratio_group_7d_for_rapid_boost` 使用不同 ROI 口径，注意区分 |
| `seller_setting_roi_ratio_group_7d` | string | 基于卖家设定 `target_roi` 的 7 日全量 ROI 分组（分母为 `target_roi × roi2_ads_revenue_7d_usd`），取值：`'0-0.5'`/`'0.5-0.8'`/`'0.8-1'`/`'1-1.2'`/`'1.2-2'`/`'2+'`/`'no gmv'`/`'no rev'`/`'no data'`。⚠️ 为预计算分类字段，与 `roi_ratio_group_7d` 口径不同（后者基于系统 CIR） |

---

### 指标：ROI2 广告绩效（当日，1d）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `roi2_ads_revenue_usd` | double | 当日广告花费（USD），对应 `ads_expenditure_amt_usd` 汇总 |
| `roi2_ads_click_cnt` | bigint | 当日去重点击数（deduplicated_click_cnt） |
| `roi2_ads_impression_cnt` | bigint | 当日展示数 |
| `roi2_broad_gmv_usd` | double | 当日宽泛口径 GMV（USD），含广告带来的间接订单 |
| `roi2_broad_order_cnt` | bigint | 当日宽泛口径订单数 |
| `roi2_direct_gmv_usd` | double | 当日直接口径 GMV（USD），即广告直接带来的订单 GMV |
| `roi2_direct_order_cnt` | bigint | 当日直接口径订单数 |
| `roi2_cpa_usd` | double | 当日单次点击均价（USD），计算方式：`avg(target_cir × item_price / 100000.0 / exchange_rate)`，仅对当日有展示的记录取均值。⚠️ 为预计算均值字段，不可直接 SUM；跨广告汇总需用原始花费与点击重新计算 |
| `roi2_cps_dedup_click_cnt` | bigint | 当日 CPS 口径去重点击数 |
| `roi2_valid_budget_usd` | double | 当日广告计划有效预算（USD），来自 `ads_campaign_valid_budget_1d` 汇总 |
| `roi2_advv_1d_usd` | double | 当日广告价值（Ads Value）估值（USD），计算为 `broad_gmv_amt_usd × target_cir` 当日加总 |
| `roi2_paid_broad_gmv_usd_1d` | double | 当日付费宽泛口径 GMV（USD） |
| `roi2_paid_broad_order_cnt_1d` | bigint | 当日付费宽泛口径订单数 |
| `roi2_paid_advv_usd_1d` | double | 当日付费广告价值估值（USD），计算为 `paid_broad_gmv_usd × target_cir` 当日加总 |

---

### 指标：ROI2 广告绩效（近 7 日，7d）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `roi2_ads_revenue_7d_usd` | double | 过去 7 日广告花费（USD）累计 |
| `roi2_advv_7d_usd` | double | 过去 7 日广告价值估值（USD），计算为 `broad_gmv_amt_usd × target_cir` 7 日加总 |
| `roi2_broad_gmv_usd_7d` | double | 过去 7 日宽泛口径 GMV（USD），`null` 时已 coalesce 为 0 |
| `roi2_broad_order_cnt_7d` | bigint | 过去 7 日宽泛口径订单数 |
| `roi2_direct_order_cnt_7d` | bigint | 过去 7 日直接口径订单数 |
| `roi2_cpa_usd_7d` | double | 过去 7 日单次点击均价（USD），为 7 日有展示记录的均值。⚠️ 为预计算均值字段，不可直接 SUM；跨广告汇总需用原始数据重新计算 |
| `roi2_valid_budget_usd_7d` | double | 过去 7 日广告计划有效预算（USD）累计（7 日内每日有效预算之和） |
| `roi2_paid_broad_gmv_usd_7d` | double | 过去 7 日付费宽泛口径 GMV（USD）累计 |
| `roi2_paid_broad_order_cnt_7d` | bigint | 过去 7 日付费宽泛口径订单数累计 |
| `roi2_paid_advv_usd_7d` | double | 过去 7 日付费广告价值估值（USD），计算为 `paid_broad_gmv_usd × target_cir` 7 日加总 |

---

### 指标：ROI2 广告绩效（近 14 日，14d）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `roi2_ads_revenue_14d_usd` | double | 过去 14 日广告花费（USD）累计 |
| `roi2_advv_14d_usd` | double | 过去 14 日广告价值估值（USD），计算为 `broad_gmv_amt_usd × target_cir` 14 日加总 |

---

### 指标：ROI3 广告绩效（含 Voucher 维度，当日）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `roi3_ads_revenue_usd` | double | ROI3 口径当日广告花费（USD），仅统计有 `bid_voucher_id` 的曝光对应花费 |
| `roi3_voucher_revenue_usd` | double | ROI3 口径当日 Voucher 对应广告花费（USD），按 Voucher 扣减比例拆分 |
| `roi3_ads_click_cnt` | bigint | ROI3 口径当日点击数（仅含 bid_voucher_id 的展示） |
| `roi3_ads_impression_cnt` | bigint | ROI3 口径当日展示数（仅含 bid_voucher_id 的展示） |
| `roi3_broad_gmv_usd` | double | ROI3 口径当日宽泛 GMV（USD） |
| `roi3_broad_order_cnt` | bigint | ROI3 口径当日宽泛订单数 |
| `roi3_direct_gmv_usd` | double | ROI3 口径当日直接 GMV（USD） |
| `roi3_direct_order_cnt` | bigint | ROI3 口径当日直接订单数 |
| `roi3_ads_voucher_click_cnt` | bigint | ROI3 口径当日展示广告 Voucher 标签的广告点击数（来自 tracking 表） |
| `roi3_ads_voucher_impression_cnt` | bigint | ROI3 口径当日展示广告 Voucher 标签的广告曝光数（来自 tracking 表） |
| `has_roi3_bid_voucher_impression` | tinyint | 当日是否存在 bid voucher 类型的展示，1=是，0=否。⚠️ 派生标记字段，不可 SUM 用于计数，如需统计广告数量需 COUNT |
| `has_roi3_best_voucher_impression` | tinyint | 当日是否存在 best voucher 类型的展示，1=是，0=否。⚠️ 同上 |
| `has_roi3_voucher_impression` | tinyint | 当日是否存在任意 Voucher 类型的广告展示，1=是，0=否。⚠️ 同上 |

---

### 指标：Rapid Boost 专项

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `non_rapid_ads_rev_usd_1d` | double | 当日非 Rapid Boost 广告花费（USD）。⚠️ DDL 中有定义但当前 ETL INSERT 语句未见明确赋值，可能为预留字段或写入时为 null，使用前请核实 |
| `non_rapid_ads_rev_usd_7d` | double | 过去 7 日非 Rapid Boost 广告花费（USD）。⚠️ 同上 |
| `non_rapid_advv_usd_1d` | double | 当日非 Rapid Boost 广告价值估值（USD）。⚠️ 同上 |
| `non_rapid_advv_usd_7d` | double | 过去 7 日非 Rapid Boost 广告价值估值（USD）。⚠️ 同上 |
| `rapid_ads_rev_usd_1d` | double | 当日 Rapid Boost 广告花费（USD）。⚠️ 同上，ETL INSERT 语句中未见明确赋值 |
| `rapid_ads_rev_usd_7d` | double | 过去 7 日 Rapid Boost 广告花费（USD）。⚠️ 同上 |
| `rapid_advv_usd_1d` | double | 当日 Rapid Boost 广告价值估值（USD）。⚠️ 同上 |
| `rapid_advv_usd_7d` | double | 过去 7 日 Rapid Boost 广告价值估值（USD）。⚠️ 同上 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**同时指定以下分区字段，避免全表扫描导致资源浪费或数据重复：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 本表当前仅写入 `'local'` 分区，不过滤将导致扫描空分区、拉低查询效率 |
| `grass_region` | `grass_region = 'MY'`（示例） | 遗漏将跨地区汇总，导致数据混淆 |
| `grass_date` | `grass_date = '2025-01-01'` 或范围过滤 | 遗漏将触发全历史分区扫描，极大增加计算成本 |

### 不可直接 SUM 的字段

以下字段为预计算比率、均值或分类字段，**不可直接 SUM 聚合**：

| 字段 | 问题 | 正确做法 |
|------|------|----------|
| `roi_ratio_group` | 预计算字符串分类，无数值意义 | 仅用于 `GROUP BY` 或 `COUNT`，不聚合 |
| `roi_ratio_group_7d` | 同上 | 同上 |
| `roi_ratio_group_7d_for_rapid_boost` | 同上，且仅 Rapid Boost 开启时有值 | 同上，注意 null 值过滤 |
| `seller_setting_roi_ratio_group_7d` | 同上 | 同上 |
| `seller_setting_roi_ratio_group_7d_for_rapid_boost` | 同上 | 同上 |
| `is_valid_roi` | 字符串分类字段 | 仅用于过滤或 `GROUP BY` |
| `roi2_cpa_usd` | 预计算均值，跨行 SUM 无意义 | 需用 `SUM(roi2_ads_revenue_usd) / SUM(roi2_ads_click_cnt)` 重新计算 |
| `roi2_cpa_usd_7d` | 同上（7 日均值） | 需用 `SUM(roi2_ads_revenue_7d_usd) / SUM(roi2_cps_dedup_click_cnt)` 或对应分子分母重新计算 |
| `has_roi3_bid_voucher_impression` | 0/1 标记，SUM 含义为"有该类型的广告数"，需明确语义 | 如需统计广告数用 `COUNT(CASE WHEN has_roi3_bid_voucher_impression = 1 THEN 1 END)` |
| `has_roi3_best_voucher_impression` | 同上 | 同上 |
| `has_roi3_voucher_impression` | 同上 | 同上 |
| `is_active_ads`、`is_new_ads`、`is_cold_start_stage`、`is_limited_budget`、`is_ocpm_1d`、`is_rapid_boost_toggle_on_1d`、`is_rapid_boost_toggle_on_7d`、`is_cb_shop` 等 0/1 标记字段 | SUM 结果为"符合条件的记录数"，需明确业务语义 | 建议用 `COUNT(CASE WHEN field = 1 THEN 1 END)` 或 `SUM(field)` 仅在明确需要求和时使用 |
| `level1/2/3_global_be_category`（struct 类型） | 复合类型，不可直接聚合 | 取子字段：`level1_global_be_category.level1_global_be_category_id` |

### 时效性说明

- **多时间窗口字段并存**：本表在同一分区内同时存储当日（1d）、7 日（7d）和 14 日（14d）滚动窗口指标。7d/14d 字段是从 `grass_date` 往前回溯对应天数的汇总值，**不应将不同日期分区的 7d/14d 字段相加**，否则会造成重复计数。
- **ROI 分组字段的时效性**：`roi_ratio_group`（14d 口径）的计算窗口为 `[PREV_15D, PREV_2D]`（排除最近 2 日），即昨日和前日不含在内；`roi_ratio_group_7d` 的计算窗口为 `[PREV_7D, BIZ_YESTERDAY]`，两者时间窗口不同，对比时需注意口径差异。
- **`non_rapid_*` / `rapid_*` 系列字段**：ETL SQL 中未见明确写入逻辑，建议取用前通过 `IS NULL` 检查确认数据是否已就绪。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` | 提供广告当日花费、点击、展示、GMV、订单等基础绩效指标（ROI2 口径，1d 维度） |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 提供多日历史绩效数据，用于计算 7d/14d 滚动窗口指标、ROI3 口径指标、冷启动阶段标签及 Rapid Boost 相关标记 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 提供每日汇率，用于本地货币与 USD 换算（主要用于 `roi2_cpa_usd` 计算） |
| `mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live` | 提供广告计划每日有效预算，汇总为当日及 7 日有效预算指标 |
| `mp_paidads.dim_campaign__reg_s0_live` | 提供广告计划维度信息，包含目标 ROI（`roi_two`）和系统推荐值列表（`final_value_list`） |
| `mkplpaidads_data.dwd_advertise_tracking_item_di__reg_s0_live` | 提供广告追踪明细，用于统计 ROI3 口径的 Voucher 曝光和点击数 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.ads_advertise_mkt_1d__reg_s0_live
  （当日花费/点击/展示/GMV/订单，placement=40，pricing_type≠29）
           │
           ▼
      [CTE: roi2_ads_1d]  ←─────────────────────────────────────────────┐
           │                                                              │
           │                                                              │
mp_paidads.dwd_advertise_performance_di__reg_s0_live                     │
  （15日历史绩效，用于7d/14d窗口聚合 + ROI3指标 + 冷启动）              │
mp_order.dim_exchange_rate__reg_s0_live（汇率）                          │
           │                                                              │
           ▼                                                              │
      [CTE: roi2_ads_nd]                                                  │
           │                                                              │
mp_paidads.dwd_advertise_performance_di__reg_s0_live                     │
  （仅当日有展示，取最新记录的冷启动标签）                               │
           │                                                              │
           ▼                                                              │
  [CTE: perf_cold_start_stage]                                           │
           │                                                              │
mkplpaidads_data.dwd_advertise_tracking_item_di__reg_s0_live             │
  （当日Voucher曝光/点击，operation in (1,2)，bid_voucher相关）         │
           │                                                              │
           ▼                                                              │
      [CTE: roi3_tracking]                                               │
           │                                                              │
mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live                     │
  （7日预算汇总）                                                         │
           │                                                              │
mp_paidads.dim_campaign__reg_s0_live                                      │
  （target_roi + suggest_value 1/2/3）                                   │
           │                                                              │
           ▼                                                              │
      [LEFT JOIN 汇总]  ─────────────────────────────────────────────────┘
           │
           ▼ INSERT OVERWRITE PARTITION(tz_type='local', grass_region, grass_date)
ads_advertise_roi2_key_metrics_daily__reg_s0_live
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `roi2_ads_1d` | `ads_advertise_mkt_1d__reg_s0_live` | 过滤 placement=40、pricing_type≠29、活跃广告，按 ads_id + pricing_type 聚合当日花费、点击、展示、GMV、订单等基础指标 |
| `roi2_ads_nd` | `dwd_advertise_performance_di__reg_s0_live` + `dim_exchange_rate__reg_s0_live` | 读取过去 15 日历史数据，计算 14d/7d/1d 滚动窗口的花费、GMV、ADVV、ROI ratio、ROI 分组标签、CPA、ROI3 指标及 Rapid Boost 相关标记 |
| `roi3_tracking` | `dwd_advertise_tracking_item_di__reg_s0_live` | 从 item 级追踪日志中统计当日 Voucher 相关的曝光和点击数（bid voucher / best voucher / ads voucher label） |
| `perf_cold_start_stage` | `dwd_advertise_performance_di__reg_s0_live` | 取当日有展示的最新一条记录，通过 `bit_get(ad_tag, 34)` 解析冷启动阶段标签 |

### 注意事项

1. **时间窗口参数说明**：ETL 使用调度参数 `${BIZ_YESTERDAY}`（业务昨日）、`${PREV_7D}`（7 日前）、`${PREV_14D}`（14 日前）、`${PREV_15D}`（15 日前）、`${PREV_2D}`（2 日前）动态计算各时间窗口边界。`roi_ratio_group`（14d）的实际计算范围为 `[PREV_15D, PREV_2D]`，排除最近 2 日，与 `roi_ratio_group_7d` 的 `[PREV_7D, BIZ_YESTERDAY]` 口径不一致，使用时须注意。

2. **ROI ratio 计算口径差异**：`roi_ratio_group` 和 `roi_ratio_group_7d` 均使用**本地货币（local）**计算 ratio（`broad_gmv_amt_local × target_cir / expenditure_amt_local`），而对应的 `roi2_advv_*_usd`、`roi2_ads_revenue_*_usd` 字段为 **USD 口径**，两者分母不同，不可混用。

3. **ROI3 双数据源**：ROI3 指标来自两张表：花费/GMV/订单等来自 `dwd_advertise_performance_di`（通过 `bid_rerank_trace` JSON 字段过滤），曝光/点击来自 `dwd_advertise_tracking_item_di`（tracking 日志），两张表统计口径存在差异，聚合时需注意。

4. **seller_setting 系列字段的 ROI 口径**：`seller_setting_roi_ratio_group_7d` 和 `seller_setting_roi_ratio_group_7d_for_rapid_boost` 使用 `target_roi`（卖家设定值）作为分母，即 `roi2_broad_gmv_usd_7d / target_roi / roi2_ads_revenue_7d_usd`；而 `roi_ratio_group_7d` 使用系统 `target_cir` 作为分母，两者含义不同，对比时需明确使用哪套口径。

5. **广告活跃定义**：`is_active_ads = 1` 的条件为"当日有展示（`is_ads_active=1`）或有任意绩效（`has_performance=1`）"，与 `is_new_ads = 1`（近 14 日内无展示）可能同时为 1（当日首次有绩效但此前 14 日无展示），业务分析时注意标签语义。

6. **`rapid_*` / `non_rapid_*` 字段**：DDL 中定义了 8 个 Rapid Boost 拆分字段（`rapid_ads_rev_usd_1d` 等），但当前 ETL INSERT 语句中未见对应赋值逻辑，这些字段在现有数据中可能为 null，使用前建议先行核实。

---

*文档生成时间：2026-05-20*
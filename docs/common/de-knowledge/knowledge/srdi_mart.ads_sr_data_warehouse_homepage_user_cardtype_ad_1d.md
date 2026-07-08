<!-- ads-workspace-gdoc-sync: gdoc_id=1oY8Q7kPlRdcWhm6xJ0Tr6wR216jhcc57n0j5ipwTy44 gdoc_url=https://docs.google.com/document/d/1oY8Q7kPlRdcWhm6xJ0Tr6wR216jhcc57n0j5ipwTy44/edit -->

# srdi_mart.ads_sr_data_warehouse_homepage_user_cardtype_ad_1d

**分层：** ADS（应用数据服务层）
**主键：** `user_id` + `card_type` + `is_ads`（分区内唯一）
**分区：** `grass_region`（站点/区域）、`local_date`（本地日期）
**更新频率：** 每日一次（T+1）
**访问频次：** 671 次

---

## 业务描述

本表为首页（Daily Discover/Homepage）用户粒度的卡片类型 × 广告维度聚合宽表，每行记录某用户在某一天、某站点下，在特定卡片类型（`card_type`）和广告/自然流量标识（`is_ads`）下的曝光、点击、浏览、购买及广告变现等行为指标。

**核心业务场景：**
- 首页各卡片类型的用户行为分析（曝光、点击、转化、时长）
- 广告 vs 自然流量用户层面的效果对比
- 广告变现指标（营收、广义/狭义 GMV、订单量）归因到用户层面
- A/B 实验分组关联，支持实验效果评估（通过 `exp_group_ids`）
- 用户购买类型、平台、版本维度的分层分析

**适合回答的问题：**
- 不同卡片类型下，各用户的曝光量、点击率、转化率分布如何？
- 广告用户与自然用户在停留时长、GMV 上的差异？
- 首页广告带来的营收和订单量如何？
- 某实验组用户在首页各卡片上的行为表现如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/区域标识，如 `SG`、`MY` 等，所有查询必须指定 |
| `local_date` | date | 数据所属本地日期（T 日），所有查询必须指定 |

### 维度：用户与流量标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户唯一标识 |
| `user_purchase_type` | string | 用户购买类型标签（如新用户、老用户等），来自用户标签维表 |
| `platform` | string | 用户所在平台（如 iOS、Android 等） |
| `app_version_prefix` | string | App 版本号前缀 |
| `card_type` | string | 卡片类型，原始值来自 DWS 层；聚合行使用特殊占位值：`__ALL__`（全卡片汇总）、`__ITEM_FEED__`（商品流卡片聚合：item/item_feed_card/item_mix_feed_card）、`__MP__`（主流卡片聚合，排除 dp/insurance/food/local service） |
| `is_ads` | bigint | 是否广告流量标识：`1` 表示广告，`0` 表示自然流量 |
| `location` | bigint | 卡片在首页中的位置（取最大值聚合） |
| `exp_group_ids` | array\<bigint\> | 用户所属 A/B 实验分组 ID 集合，来自实验分组维表，经白名单过滤 |

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 用户该卡片类型下的曝光次数 |
| `click_cnt` | bigint | 用户该卡片类型下的点击次数 |
| `ppv_cnt` | bigint | 落地页浏览次数（Page PV Count） |
| `minippv_cnt` | bigint | 小程序页面浏览次数 |
| `vv` | bigint | 视频/内容播放次数（Video View） |

### 指标：转化与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 用户在该卡片类型下产生的订单数（来自 DWS 层，可能含小数） |
| `gmv` | double | 用户在该卡片类型下产生的 GMV（美元） |
| `pc2_gmv` | double | PC2 口径 GMV（美元），特定归因口径下的成交金额 |

### 指标：时长与互动深度

| 字段 | 类型 | 说明 |
|---|---|---|
| `self_duration` | double | 用户在首页卡片自身页面的停留时长（秒） |
| `landing_page_duration` | double | 用户在落地页的停留时长（秒） |
| `pdp_page_duration` | double | 用户在商品详情页（PDP）的停留时长（秒） |
| `total_duration` | double | 总时长 = `self_duration` + `landing_page_duration` + `pdp_page_duration`（ETL 计算，NULL 视为 0） |
| `internal_scroll_depth` | bigint | 用户在首页内部的滚动深度（取最大值聚合） |

### 指标：广告变现

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_revenue` | double | 广告营收（美元），来自广告投放域，Daily Discover 场景下的广告收入 |
| `ads_narrow_gmv` | double | 广告狭义 GMV（美元），即直接归因广告的 GMV（`ads_gmv_usd`） |
| `ads_broad_gmv` | double | 广告广义 GMV（美元），包含间接归因的 GMV（`ads_broad_gmv_usd`） |
| `ads_item_gmv` | double | 广告商品 GMV（美元），仅统计 `if_ads_item=1` 的 omni GMV |
| `ads_narrow_order_cnt` | bigint | 广告狭义订单数（直接归因） |
| `ads_broad_order_cnt` | bigint | 广告广义订单数（含间接归因） |
| `ads_item_order_cnt` | double | 广告商品订单数，仅统计 `if_ads_item=1` 的 omni 订单量 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`** 和 **`local_date`** 为双分区键，查询时**必须同时指定**，否则将触发全表扫描，产生巨大资源消耗。
- 示例：`WHERE grass_region = 'SG' AND local_date = '2024-01-01'`

### card_type 特殊值说明

| `card_type` 值 | 含义 |
|---|---|
| 原始字符串（如 `item`、`dp` 等） | DWS 层原始卡片类型，细粒度明细行 |
| `__ALL__` | 全卡片类型汇总（按 `user_id` + `is_ads` 聚合） |
| `__ITEM_FEED__` | 商品流卡片聚合（item / item_feed_card / item_mix_feed_card） |
| `__MP__` | 主流卡片聚合（排除 dp/insurance/food/local service） |

- **查询单一卡片明细时，务必过滤排除 `__ALL__`、`__ITEM_FEED__`、`__MP__`**，否则会产生重复计数。
- 聚合行与明细行共存于同一分区，不可将 `card_type` 维度直接 GROUP BY 求 SUM，需根据业务口径选择正确的 `card_type` 范围。

### 不可直接 SUM 的字段

- **`location`**：聚合时取 MAX，代表卡片最大位置，不可 SUM。
- **`internal_scroll_depth`**：聚合时取 MAX，不可 SUM。
- **`exp_group_ids`**：数组类型，不可 SUM；用于实验过滤时需使用 `ARRAY_CONTAINS` 等函数展开。
- **广告变现字段（`ads_revenue`、`ads_*_gmv`、`ads_*_order_cnt`）**：仅在 `card_type = '__ALL__'` 且 `is_ads = 1` 的行中有意义，其他 `card_type` 行中该类字段被置为 `0`。跨 `card_type` 聚合广告指标时，应仅使用 `card_type = '__ALL__'` 的行，**不可对所有行 SUM**。
- **`order_cnt`、`ads_item_order_cnt`**：类型为 `double`，可能含小数，聚合时需注意精度。

### 时效性说明

- 本表为 `_1d` 日表，存储 T 日数据，通常在 T+1 完成更新。
- 不包含历史累计（`_td`）或滚动窗口（`_nd`）数据，跨天分析需按 `local_date` 分区遍历。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_homepage_user_cardtype_ad_1d` | 主数据源，提供用户 × 卡片类型 × 广告标识的行为明细指标（曝光、点击、转化、时长等） |
| `mp_paidads.dws_advertise_user_exp_common_feature_performance_1d__reg_s0_live` | 广告域用户表现数据源，提供 Daily Discover 场景下用户级别的广告营收、GMV、订单等变现指标 |
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | A/B 实验分组维表，提供 homepage 白名单和 homepage_other 白名单过滤规则 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | A/B 实验用户分组维表，提供用户所属实验分组（经 assignment log 和白名单过滤） |
| `srdi_mart.dim_sr_data_warehouse_user_label` | 用户标签维表，为广告域用户补充 `platform`、`app_version_prefix`、`user_purchase_type` 属性 |

---

## ETL 逻辑摘要

### 数据流

```
dws_sr_data_warehouse_homepage_user_cardtype_ad_1d
    │
    ├─ 明细行（原始 card_type）
    ├─ 聚合行（__ALL__、__ITEM_FEED__、__MP__）
    │
    └─> user_cardtype_ad_data（含行为指标，ads_* 字段占位为 0）
            │
            ├─ mp_paidads 广告变现数据 + dim_user_label 补充属性
            │       └─> 广告行（card_type='__ALL__'，行为指标占位为 0）
            │
            └─> user_union_all_data（行为指标 + 广告变现指标 UNION ALL）
                    │
                    └─> aggregated_data_result（按 user_id + card_type + is_ads 聚合）
                            │
                            ├─ LEFT JOIN user_exp_result（A/B 实验分组，含白名单过滤）
                            │
                            └─> INSERT OVERWRITE 目标表（按 grass_region + local_date 分区写入）
```

### 关键步骤

**Step 1 — `user_cardtype_ad_data`（Temporary View）**
从 DWS 层读取当日数据，通过 `UNION ALL` 生成四类行：
- 原始细粒度明细行（保留真实 `card_type`）
- `__ALL__`：全卡片按 `user_id + is_ads` 汇总
- `__ITEM_FEED__`：仅限 `item`/`item_feed_card`/`item_mix_feed_card` 卡片汇总
- `__MP__`：排除 `dp`/`insurance`/`food`/`local service` 后的主流卡片汇总
- 所有广告变现字段（`ads_revenue` 等）在本步骤中占位为 `0`
- `total_duration` 由 `self_duration + landing_page_duration + pdp_page_duration` 计算（NULL 视为 0）

**Step 2 — `exp_filter_homepage_other` / `exp_filter_homepage`（Temporary Views）**
分别从 `dim_sr_data_warehouse_abtest_group` 提取 `is_homepage_other_whitelist=1` 和 `is_homepage_whitelist=1` 的实验分组 ID。

**Step 3 — `exp_filter_homepage_other_result`（Temporary View）**
通过 LEFT JOIN + `WHERE IS NULL` 过滤，保留仅属于 homepage_other 白名单、但不属于 homepage 白名单的实验组 ID，形成互斥的 other 组过滤集。

**Step 4 — `user_exp_result`（Temporary View）**
从 `dim_sr_data_warehouse_abtest_user_group` 获取用户实验分组，合并两类用户：
- 满足 `is_assignment_log=1` 且 `is_homepage_whitelist=1` 的用户分组
- 满足 `is_assignment_log=1` 且分组属于 homepage_other 互斥集的用户分组
最终按 `user_id` 聚合为 `exp_group_ids` 数组。

**Step 5 — `user_union_all_data`（Temporary View）**
将 Step 1 的行为指标数据与广告变现数据合并（`UNION ALL`）：
- 行为数据行：来自 Step 1，广告变现字段为 `0`
- 广告变现行：从 `mp_paidads` 域聚合 `Daily Discover` 场景广告指标，`card_type` 固定为 `'__ALL__'`，行为指标占位为 `0`，通过 LEFT JOIN `dim_user_label` 补充用户属性

**Step 6 — `aggregated_data_result`（Temporary View）**
对 `user_union_all_data` 按 `user_id + card_type + is_ads` 分组聚合，合并行为指标（SUM）和广告变现指标（SUM），`location`、`internal_scroll_depth` 取 MAX，用户属性取 MAX。

**Step 7 — INSERT OVERWRITE（最终写入）**
将 `aggregated_data_result` LEFT JOIN `user_exp_result` 补充实验分组，按 `grass_region + local_date` 分区写入目标表。

### 注意事项

- **广告变现字段仅在 `card_type = '__ALL__'` 且 `is_ads = 1` 行有效**，其余行均为占位值 `0`，分析时需严格过滤。
- **行为指标与广告变现指标来自不同数据域**，通过 UNION ALL 拼接再聚合，两类指标在逻辑上不对等，不可混用进行 CTR/ROI 等比率计算。
- **`__ALL__`、`__ITEM_FEED__`、`__MP__` 与明细 `card_type` 行之间存在重叠**，直接 SUM 所有 `card_type` 会产生重复计算，使用时必须明确选择单一口径。
- ETL 为单文件单写入（`multi_writer = false`），每次执行 `INSERT OVERWRITE` 覆盖对应 `grass_region + local_date` 分区，历史分区不受影响。
- `exp_group_ids` 经过白名单过滤，仅包含 homepage 相关实验分组，不代表用户参与的全部实验。

---

*文档生成时间：2026-05-17*
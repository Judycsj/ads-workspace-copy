<!-- ads-workspace-gdoc-sync: gdoc_id=1P06RdvHyqa6jDmhC9pu5RHR3zH4fGyvXoOsccgsCZZ0 gdoc_url=https://docs.google.com/document/d/1P06RdvHyqa6jDmhC9pu5RHR3zH4fGyvXoOsccgsCZZ0/edit -->

# mp_paidads.ads_item_supply_1d

**分层：** ADS（应用数据层）
**主键：** `item_id` + `shop_id` + `tz_type` + `grass_region` + `grass_date`
**分区：** `tz_type` / `grass_region` / `grass_date`
**更新频率：** 每日（T+1）
**引用频次：** 1 次（候选表范围内统计）

---

## 业务描述

本表以商品（Item）为最细粒度，汇总每个商品在单日（1d）内的付费广告投放绩效指标，并同步关联该商品过去 30 天的平台大盘 GMV、订单量及曝光量等基线数据，用于衡量商品的广告供给能力与平台自然流量体量之间的关系。核心使用场景包括：广告商品健康度监控、广告渗透率分析（付费曝光 vs 平台总曝光）、商品维度 ROI 评估以及广告供给端选品策略制定。

本表同时携带商品所属店铺的属性标签（是否 CB 店铺、是否 SIP 店铺、卖家类型）以及一至三级全球后端类目，支持多维度下钻分析，是付费广告商品供给域最重要的宽表之一。

各地区按本地时区参数化调度，统一写入 `tz_type = 'local'` 分区，覆盖所有已上线的电商市场。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型。当前 ETL 仅写入 `'local'`（各地区本地时区）分区，查询时须指定 `tz_type = 'local'` |
| `grass_region` | string | 地区代码（大写），如 `'MX'`、`'TH'` 等；各地区按本地时区参数化调度 |
| `grass_date` | date | 数据日期（本地时区），每日更新，为主要过滤分区键 |

### 维度：主键与店铺属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺 ID，与 `item_id` 联合构成商品唯一标识 |
| `item_id` | bigint | 商品 ID，核心分析粒度 |
| `is_sip_shop` | tinyint | 是否为 SIP（Service Item Provider）店铺，取值 0/1。SIP 含本地 SIP（`is_local_sip_affiliated=1`）和跨境 SIP（`is_cb_sip_affiliated=1`）两类，任一满足即标记为 1 |
| `is_cb_shop` | tinyint | 是否为跨境（Cross-Border）店铺，取值 0/1 |
| `seller_type_1p` | string | 卖家类型，标识是否为具有跨境 listing 或店铺的卖家（1P） |
| `is_active_ads_item` | tinyint | 是否为活跃广告商品，取值 0/1。满足 `is_ads_active=1`（广告状态开启）或 `has_performance=1`（存在广告绩效数据）任一条件即为 1 |

### 维度：商品类目

| 字段 | 类型 | 说明 |
|------|------|------|
| `level1_global_be_category` | struct<level1_global_be_category_id:bigint, level1_global_be_category:string> | 一级全球后端类目，结构体类型，含类目 ID 和类目名称。⚠️ Struct 类型，查询时需用 `.level1_global_be_category_id` 或 `.level1_global_be_category` 访问子字段，不可直接 GROUP BY 整列聚合 |
| `level2_global_be_category` | struct<level2_global_be_category_id:bigint, level2_global_be_category:string> | 二级全球后端类目，结构体类型，含类目 ID 和类目名称。⚠️ 同上，查询需展开子字段 |
| `level3_global_be_category` | struct<level3_global_be_category_id:bigint, level3_global_be_category:string> | 三级全球后端类目（最细粒度），结构体类型，含类目 ID 和类目名称。⚠️ 同上，查询需展开子字段 |

### 指标：广告绩效（单日，1d）

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_expenditure_amt_usd_1d` | double | 当日广告消耗金额（USD），税前口径，不含过期金额，未做汇率平滑（not flated）|
| `ads_impression_cnt_1d` | bigint | 当日广告曝光次数 |
| `ads_deduct_click_cnt_1d` | bigint | 当日广告扣费点击次数（计费口径） |
| `ads_cps_click_cnt_1d` | bigint | 当日 CPS（Cost Per Sale）广告点击次数 |
| `ads_direct_order_cnt_1d` | bigint | 当日广告直接带单订单数（Direct Order，归因窗口内直接点击后成交） |
| `ads_broad_order_cnt_1d` | bigint | 当日广告广泛带单订单数（Broad Order，含间接归因订单） |
| `ads_direct_order_gmv_usd_1d` | double | 当日广告直接带单 GMV（USD） |
| `ads_direct_order_gmv_1d` | double | 当日广告直接带单 GMV（本地货币） |
| `ads_broad_order_gmv_usd_1d` | double | 当日广告广泛带单 GMV（USD） |
| `ads_broad_order_gmv_1d` | double | 当日广告广泛带单 GMV（本地货币） |

### 指标：平台大盘基线（近 30 日，30d）

| 字段 | 类型 | 说明 |
|------|------|------|
| `platform_placed_order_cnt_30d` | bigint | 过去 30 日商品平台总下单量（含付费与自然流量）。⚠️ 本表以 `grass_date` 为结尾日期的滚动 30 天窗口，跨日期分区直接 SUM 会造成重复计算，需选定单一 `grass_date` 分区使用 |
| `platform_gmv_usd_30d` | decimal(25,10) | 过去 30 日商品平台总 GMV（USD）。⚠️ 同上，为滚动 30 天累计值，跨分区 SUM 存在重复计数风险 |
| `platform_gmv_30d` | decimal(25,10) | 过去 30 日商品平台总 GMV（本地货币）。⚠️ 同上，为滚动 30 天累计值，跨分区 SUM 存在重复计数风险 |
| `platform_impression_cnt_30d` | bigint | 过去 30 日商品平台总曝光次数（来源于 `srdi_mart` 平台基准数据）。⚠️ 同上，为滚动 30 天累计值，跨分区 SUM 存在重复计数风险 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下三个分区字段**，否则将触发全表扫描，导致性能劣化或账单激增：

| 分区字段 | 推荐过滤方式 | 遗漏后果 |
|----------|-------------|----------|
| `tz_type` | `tz_type = 'local'` | 当前 ETL 仅产出 `local` 分区，遗漏此条件将扫描全部分区元数据，且过滤下推失效 |
| `grass_region` | `grass_region = 'XX'`（大写地区码） | 全地区扫描，数据量成倍放大 |
| `grass_date` | `grass_date = '2025-01-01'` 或指定日期范围 | 未加日期限制将扫描全量历史分区 |

### 不可直接 SUM 的字段

| 字段 | 问题原因 | 正确处理方式 |
|------|---------|-------------|
| `platform_placed_order_cnt_30d` | 滚动 30 日预聚合值，跨 `grass_date` SUM 导致重复计算 | 仅取单一 `grass_date` 分区，不得跨日期累加 |
| `platform_gmv_usd_30d` | 同上 | 同上 |
| `platform_gmv_30d` | 同上 | 同上 |
| `platform_impression_cnt_30d` | 同上 | 同上 |
| `level1/2/3_global_be_category` | Struct 类型，不可整列 GROUP BY / SUM | 使用 `.level1_global_be_category_id`、`.level1_global_be_category` 等子字段 |

> **说明**：`ads_*_1d` 系列字段为单日加总值，在同一 `grass_date` 分区内按 `shop_id` 或类目维度 SUM 是安全的。

### 时效性说明

- `platform_*_30d` 字段为以 **`grass_date` 为截止日**的滚动 30 天累计值，反映过去 30 天的平台大盘体量。
- 查询最新数据时，取 **最新可用 `grass_date`** 的分区即可获得最近 30 天基线；若需按日趋势对比，须理解相邻两个 `grass_date` 的值存在大量重叠天数，不可对其差值进行业务解读。
- 广告绩效指标（`ads_*_1d`）为当日新增，无跨日重叠问题，可正常按日趋势分析。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_order.dws_item_gmv_nd__reg_s0_live` | 提供商品维度过去 30 日平台 GMV、下单量基线数据（`placed_order_cnt_30d`、`gmv_30d`、`gmv_usd_30d`），同时作为 base 商品集（过滤 `placed_order_cnt_30d > 0`） |
| `mp_seller.dim_shop_ext__reg_s0_live` | 提供店铺维度属性，包括 `is_cb_shop`（是否跨境店铺） |
| `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` | 提供商品维度单日广告绩效指标，含消耗、曝光、点击、订单、GMV 等，并携带卖家类型、SIP 标签、类目信息 |
| `srdi_mart.dws_sr_data_warehouse_platform_item_level_benchmark_1d` | 提供商品维度过去 30 日平台总曝光次数（`imp_cnt`），来源于平台基准数据，按 `feature_detail='__ALL__'` 且 `scenario_tag='__ALL__'` 全场景汇总 |

---

## ETL 逻辑摘要

### 数据流

```
mp_order.dws_item_gmv_nd__reg_s0_live
  (placed_order_cnt_30d > 0，作为 base 商品集)
            │
            │  LEFT JOIN on shop_id
            ▼
mp_seller.dim_shop_ext__reg_s0_live
  (补充 is_cb_shop 店铺属性)
            │
            │  LEFT JOIN on shop_id + item_id
            ▼
mp_paidads.ads_advertise_mkt_1d__reg_s0_live
  (按 shop_id+item_id+卖家属性+类目 GROUP BY，
   HAVING has_performance=1 OR is_ads_active=1)
            │
            │  LEFT JOIN on item_id
            ▼
srdi_mart.dws_sr_data_warehouse_platform_item_level_benchmark_1d
  (按 item_id GROUP BY，SUM(imp_cnt) 近30日)
            │
            ▼
mp_paidads.ads_item_supply_1d__reg_s0_live
  PARTITION(tz_type='local', grass_region, grass_date)
```

### 关键 CTE 说明

本 ETL 未使用命名 CTE，采用内联子查询结构：

| 子查询别名 | 来源表 | 作用 |
|-----------|--------|------|
| `base_item` | `mp_order.dws_item_gmv_nd__reg_s0_live` | 定义商品基础集合（30 日有下单记录），并携带 30 日平台 GMV/订单量 |
| `dim_shop` | `mp_seller.dim_shop_ext__reg_s0_live` | 补充店铺跨境属性（`is_cb_shop`） |
| `ads_metric_caled` | `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` | 按商品粒度汇总单日广告绩效，并派生 `is_sip_shop`、`is_active_ads_item`、类目等字段 |
| `platform_impr` | `srdi_mart.dws_sr_data_warehouse_platform_item_level_benchmark_1d` | 按商品汇总近 30 日平台总曝光（`platform_impression_cnt_30d`） |

### 注意事项

1. **商品集合口径**：Base 商品集以 `mp_order.dws_item_gmv_nd__reg_s0_live` 中 `placed_order_cnt_30d > 0` 为准，即过去 30 天有下单的商品才会出现在本表，**零订单商品不入库**。若需分析无订单商品的广告投放，本表不适用。

2. **广告指标 LEFT JOIN 后存在 NULL**：`ads_metric_caled` 是 LEFT JOIN，部分商品当日无广告投放，广告绩效字段（`ads_expenditure_amt_usd_1d` 等）会为 `NULL`，聚合时需使用 `COALESCE(field, 0)` 或 `SUM` 时注意 NULL 忽略行为。

3. **`is_active_ads_item` 定义**：`is_ads_active=1`（广告计划状态激活）或 `has_performance=1`（当日存在广告绩效）任一满足即为 1。若该商品无广告数据（LEFT JOIN 未命中），则 `is_active_ads_item = 0`。

4. **平台曝光数据来源差异**：`platform_impression_cnt_30d` 来源于 `srdi_mart` 的平台基准数据（`feature_detail='__ALL__'`，`scenario_tag='__ALL__'`），口径为全场景全特征汇总；而 `ads_impression_cnt_1d` 来源于广告侧投放数据，两者口径不同，不可直接相减计算自然流量曝光。

5. **`ads_expenditure_amt_usd_1d` 口径说明**：税前、不含过期广告金额、未做汇率平滑（not flated），与财务口径可能存在差异，使用时须对齐口径。

6. **`platform_*_30d` 滚动窗口**：`platform_placed_order_cnt_30d`、`platform_gmv_*_30d` 来自 `mp_order.dws_item_gmv_nd__reg_s0_live` 的预聚合字段；`platform_impression_cnt_30d` 则在 ETL 中实时聚合 `PREV_30D` 至 `grass_date` 区间，两类字段的 30 日窗口定义一致，但数据来源不同。

7. **各地区参数化调度**：`${region}`、`${grass_date}`、`${PREV_30D}` 为调度模板参数，各地区按本地时区独立调度，文档中所有地区相关示例值均为模板实例，不代表任何单一市场限制。

---

*文档生成时间：2026-04-22*
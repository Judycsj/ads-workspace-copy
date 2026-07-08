<!-- ads-workspace-gdoc-sync: gdoc_id=18OuAMabKS00e8wrYY3HvNvp_D-oEUV3SFpginp_yPLg gdoc_url=https://docs.google.com/document/d/18OuAMabKS00e8wrYY3HvNvp_D-oEUV3SFpginp_yPLg/edit -->

# mp_paidads.dws_item_performance_nd

**分层**：DWS（数据汇总层 / Data Warehouse Summary）
**主键**：`item_id`（在同一分区内唯一）
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度，写入前一自然日（`BIZ_YESTERDAY`）分区，各地区按本地时区参数化调度
**引用频次**：0（末端 ADS 层表，未被其他候选表直接引用）

---

## 业务描述

本表是商品（Item）维度的广告绩效汇总宽表，以商品为粒度，融合了平台大盘流量数据与付费广告数据，提供 1 天、7 天、14 天、30 天多个回溯时间窗口的核心指标快照。表名后缀 `nd` 意指"N-Day"滚动窗口，每日全量覆盖写入，是广告效果分析、商品投放诊断、ROI 评估等场景的核心数据源。

典型使用场景包括：商品广告投放效果排行榜、广告 GMV 与平台 GMV 占比分析、新品投放效果评估、广告主花费与收入的 ROI 监控，以及商品在不同时间窗口的流量漏斗对比分析。表中同时保留本地货币（local）和美元（usd）双币种金额字段，可支持跨地区的统一口径汇总及各地区本地化报表需求。

本表属于末端宽表，已完成多来源数据的整合与多时间窗口的预聚合，下游可直接按业务需求过滤分区后使用，无需再对原始明细做复杂 JOIN，显著降低查询复杂度和计算成本。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型。当前写入值固定为 `'local'`（本地时区）；查询时**必须指定**，否则将扫描全表所有时区分区 |
| `grass_region` | string | 地区编码（大写），如 `'MY'`、`'TH'` 等；各地区通过 `${region}` 参数化调度独立写入 |
| `grass_date` | date | 业务日期，格式 `yyyy-MM-dd`，对应 `BIZ_YESTERDAY`（调度日前一自然日）；查询时**必须指定**具体日期或日期范围 |

---

### 维度：商品基础信息

| 字段 | 类型 | 说明 |
|------|------|------|
| `item_id` | bigint | 商品 ID，本表主键 |
| `shop_id` | bigint | 店铺 ID，来源于商品维表 `dim_item` |
| `item_create_timestamp` | bigint | 商品创建时间戳（Unix 毫秒级或秒级，以源表为准） |
| `item_create_datetime` | string | 商品创建时间，字符串格式（如 `'2024-01-01 08:00:00'`）；`is_new_item_30d` 即基于此字段与 30 日前日期比较得出 ⚠️ 存储为字符串，做日期比较时需先转换为 DATE 类型 |
| `level1_category_id` | bigint | 一级类目 ID（Global BE 分类体系） |
| `level1_category_name` | string | 一级类目名称 |
| `level2_category_id` | bigint | 二级类目 ID |
| `level2_category_name` | string | 二级类目名称 |
| `level3_category_id` | bigint | 三级类目 ID |
| `level3_category_name` | string | 三级类目名称 |

---

### 维度：商品广告状态标签

| 字段 | 类型 | 说明 |
|------|------|------|
| `is_ads_item_1d` | tinyint | 该商品在统计日（`BIZ_YESTERDAY`）是否有激活状态的 Product Ads；1=有，0=无。NULL 值已用 `COALESCE` 转为 0 |
| `is_ads_item_7d` | tinyint | 该商品在近 7 天是否有激活状态的 Product Ads；1=有，0=无。NULL 值已用 `COALESCE` 转为 0 ⚠️ 此字段源于 `dim_ads_item` 固定赋值 `1`，仅当该商品出现在 7 日窗口的广告维表中才存在记录，逻辑等价于"7 日内曾有活跃广告" |
| `is_gms_ads_item_1d` | tinyint | 该商品在统计日是否有 GMS 类广告（`pricing_type IN (24, 27)`）；1=有，0=无。NULL 值已用 `COALESCE` 转为 0 |
| `is_new_item_30d` | tinyint | 商品创建时间是否在近 30 天内；1=是（新品），0=否 ⚠️ 该值按分区日期计算，仅反映写入当日的新品判断，不随时间自动更新 |

---

### 指标：平台大盘曝光与点击

| 字段 | 类型 | 说明 |
|------|------|------|
| `platform_impression_cnt_1d` | bigint | 商品在平台的曝光次数（近 1 天滚动汇总） |
| `platform_impression_cnt_7d` | bigint | 商品在平台的曝光次数（近 7 天滚动汇总） |
| `platform_impression_cnt_30d` | bigint | 商品在平台的曝光次数（近 30 天滚动汇总） |
| `platform_click_cnt_1d` | bigint | 商品在平台的点击次数（近 1 天） |
| `platform_click_cnt_7d` | bigint | 商品在平台的点击次数（近 7 天） |
| `platform_click_cnt_30d` | bigint | 商品在平台的点击次数（近 30 天） |

---

### 指标：平台大盘订单与 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `platform_order_cnt_1d` | bigint | 商品在平台的成交订单数（近 1 天） |
| `platform_order_cnt_7d` | bigint | 商品在平台的成交订单数（近 7 天） |
| `platform_order_cnt_14d` | bigint | 商品在平台的成交订单数（近 14 天） |
| `platform_order_cnt_30d` | bigint | 商品在平台的成交订单数（近 30 天） |
| `platform_gmv_usd_1d` | double | 商品在平台的 GMV（美元，近 1 天） |
| `platform_gmv_usd_7d` | double | 商品在平台的 GMV（美元，近 7 天） |
| `platform_gmv_usd_14d` | double | 商品在平台的 GMV（美元，近 14 天） |
| `platform_gmv_usd_30d` | double | 商品在平台的 GMV（美元，近 30 天） |
| `platform_gmv_local_1d` | double | 商品在平台的 GMV（本地货币，近 1 天）⚠️ 注意：该字段在 DDL 字段列表中存在，但当前 ETL SQL 未见对应的本地货币计算逻辑，可能为预留字段或由其他流程填充，使用前请核实数据完整性 |
| `platform_gmv_local_7d` | double | 商品在平台的 GMV（本地货币，近 7 天）⚠️ 同上，请核实数据完整性 |
| `platform_gmv_local_14d` | double | 商品在平台的 GMV（本地货币，近 14 天）⚠️ 同上，请核实数据完整性 |
| `platform_gmv_local_30d` | double | 商品在平台的 GMV（本地货币，近 30 天）⚠️ 同上，请核实数据完整性 |

---

### 指标：广告曝光与点击

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_impression_cnt_1d` | bigint | 商品广告曝光次数（近 1 天） |
| `ads_impression_cnt_7d` | bigint | 商品广告曝光次数（近 7 天） |
| `ads_impression_cnt_30d` | bigint | 商品广告曝光次数（近 30 天） |
| `ads_click_cnt_1d` | bigint | 商品广告点击次数（近 1 天） |
| `ads_click_cnt_7d` | bigint | 商品广告点击次数（近 7 天） |
| `ads_click_cnt_30d` | bigint | 商品广告点击次数（近 30 天） |

---

### 指标：广告宽口径订单与 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_broad_order_cnt_1d` | bigint | 广告带来的宽口径订单数（近 1 天）；包含点击后一定归因窗口内的所有订单 |
| `ads_broad_order_cnt_7d` | bigint | 广告宽口径订单数（近 7 天） |
| `ads_broad_order_cnt_30d` | bigint | 广告宽口径订单数（近 30 天） |
| `ads_broad_gmv_amt_local_1d` | double | 广告宽口径 GMV（本地货币，近 1 天） |
| `ads_broad_gmv_amt_local_7d` | double | 广告宽口径 GMV（本地货币，近 7 天） |
| `ads_broad_gmv_amt_local_30d` | double | 广告宽口径 GMV（本地货币，近 30 天） |
| `ads_broad_gmv_amt_usd_1d` | double | 广告宽口径 GMV（美元，近 1 天） |
| `ads_broad_gmv_amt_usd_7d` | double | 广告宽口径 GMV（美元，近 7 天） |
| `ads_broad_gmv_amt_usd_30d` | double | 广告宽口径 GMV（美元，近 30 天） |

---

### 指标：广告付费口径订单与 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_paid_broad_order_cnt_1d` | bigint | 广告付费宽口径订单数（近 1 天）；相较 broad 口径，仅计入付费流量带来的订单 |
| `ads_paid_broad_order_cnt_7d` | bigint | 广告付费宽口径订单数（近 7 天） |
| `ads_paid_broad_order_cnt_30d` | bigint | 广告付费宽口径订单数（近 30 天） |
| `ads_paid_broad_order_gmv_1d` | double | 广告付费宽口径 GMV（本地货币，近 1 天） |
| `ads_paid_broad_order_gmv_7d` | double | 广告付费宽口径 GMV（本地货币，近 7 天） |
| `ads_paid_broad_order_gmv_30d` | double | 广告付费宽口径 GMV（本地货币，近 30 天） |
| `ads_paid_broad_order_gmv_usd_1d` | double | 广告付费宽口径 GMV（美元，近 1 天） |
| `ads_paid_broad_order_gmv_usd_7d` | double | 广告付费宽口径 GMV（美元，近 7 天） |
| `ads_paid_broad_order_gmv_usd_30d` | double | 广告付费宽口径 GMV（美元，近 30 天） |

---

### 指标：广告花费

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_expenditure_amt_local_1d` | double | 广告花费（本地货币，近 1 天） |
| `ads_expenditure_amt_local_7d` | double | 广告花费（本地货币，近 7 天） |
| `ads_expenditure_amt_local_30d` | double | 广告花费（本地货币，近 30 天） |
| `ads_expenditure_amt_usd_1d` | double | 广告花费（美元，近 1 天） |
| `ads_expenditure_amt_usd_7d` | double | 广告花费（美元，近 7 天） |
| `ads_expenditure_amt_usd_30d` | double | 广告花费（美元，近 30 天） |

---

### 指标：广告毛收入

| 字段 | 类型 | 说明 |
|------|------|------|
| `gross_ads_revenue_usd_1d` | double | 广告毛收入（美元，近 1 天）；来源于 `dws_advertise_net_ads_revenue_1d`，经 ads_id → item_id 映射后汇总 |
| `gross_ads_revenue_usd_7d` | double | 广告毛收入（美元，近 7 天） |
| `gross_ads_revenue_usd_30d` | double | 广告毛收入（美元，近 30 天）；仅统计 `gross_ads_revenue_usd_1d > 0` 的记录 ⚠️ 过滤条件会导致负向修正数据被排除，与其他指标口径不完全一致 |

---

### 指标：算法价格（预留/扩展字段）

| 字段 | 类型 | 说明 |
|------|------|------|
| `algo_item_price` | double | 算法侧商品价格（本地货币）⚠️ 当前 ETL SQL 中未见此字段的计算逻辑，可能为预留字段或由其他流程写入，使用前请核实是否有效 |
| `algo_item_price_usd` | double | 算法侧商品价格（美元）⚠️ 同上，请核实数据完整性 |
| `algo_paid_item_price` | double | 算法侧付费商品价格（本地货币）⚠️ 同上，请核实数据完整性 |
| `algo_paid_item_price_usd` | double | 算法侧付费商品价格（美元）⚠️ 同上，请核实数据完整性 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**指定以下三个分区字段，否则将触发全表扫描，造成严重的资源浪费和查询超时：

| 分区字段 | 推荐值 / 示例 | 遗漏后果 |
|----------|--------------|----------|
| `tz_type` | **必须指定 `'local'`**，当前仅写入该值 | 扫描所有时区分区（如未来扩展多时区将导致数据重复） |
| `grass_region` | 如 `'MY'`、`'TH'`、`'PH'` 等大写地区码 | 全地区混合扫描，数据量翻倍且无法区分地区 |
| `grass_date` | 指定具体日期或日期范围，如 `grass_date = '2024-06-01'` | 扫描全量历史分区，极易触发 OOM 或超时 |

```sql
-- 标准查询模板
SELECT *
FROM mp_paidads.dws_item_performance_nd__reg_s0_live
WHERE tz_type = 'local'
  AND grass_region = 'MY'
  AND grass_date = '2024-06-01'
```

### 不可直接 SUM 的字段

本表所有指标均为**预聚合的滚动窗口累计值**，在以下场景需特别注意：

| 场景 | 错误用法 | 正确用法 |
|------|----------|----------|
| 跨多个 `grass_date` 分区求多日合计 | `SUM(ads_expenditure_amt_usd_7d)` over multiple dates | 仅取**单一最新日期**分区的 `_7d` 字段，该字段已包含过去 7 天数据；多分区叠加会造成重复计数 |
| 计算 CTR（点击率） | 直接使用某个派生比率 | 用 `ads_click_cnt_1d / NULLIF(ads_impression_cnt_1d, 0)` 重新计算 |
| 计算 ROAS | 无专用字段 | 用 `ads_broad_gmv_amt_usd_1d / NULLIF(ads_expenditure_amt_usd_1d, 0)` 计算 |
| 计算广告渗透率 | 无专用字段 | 用 `ads_impression_cnt_1d / NULLIF(platform_impression_cnt_1d, 0)` 计算 |
| 跨地区汇总本地货币金额 | `SUM(ads_broad_gmv_amt_local_7d)` over multiple regions | 本地货币不可跨地区直接加总，请改用 `_usd` 字段做跨地区汇总 |

> **核心原则**：`_7d`、`_14d`、`_30d` 后缀字段是在**单分区内**已完成的多日滚动聚合，应把每个分区当作一个完整快照使用；如需分析趋势，应拉取**连续多日的 `_1d` 字段**而非多日的 `_7d` 字段。

### 时效性说明

- 每日调度写入 `grass_date = BIZ_YESTERDAY`（调度日前一自然日），当日数据**次日方可查询**。
- 如需获取最新数据，应查询 `grass_date = CURRENT_DATE - 1`，不要使用 `MAX(grass_date)` 动态查找（成本高），建议在业务看板中固定参数化传入。
- `_30d` 字段依赖过去 30 天分区的上游数据；若上游存在回刷，30 日滚动值也会在次日刷新后自动更正。
- `gross_ads_revenue_usd_*` 来源于独立的广告净收入表，存在轻微数据延迟，与花费类字段可能存在 1 天口径差；对账时请关注上游 `dws_advertise_net_ads_revenue_1d` 的数据就绪时间。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `traffic_omni_oa.dws_user_item_feature_sales_funnel_metrics_1d__reg_sensitive_live` | 提供商品平台大盘曝光、点击、订单、GMV（USD）等流量漏斗指标，按 `local_date` 滚动取 1/7/14/30 天 |
| `mp_item.dim_item__reg_s0_live` | 商品维表，提供 `shop_id`、创建时间、三级类目信息 |
| `mp_paidads.dim_advertise__reg_s0_live` | 广告维表，用于判断商品是否有活跃广告（`is_ads_item_1d/7d`、`is_gms_ads_item_1d`），以及 `ads_id → item_id` 的映射 |
| `mp_paidads.dws_advertise_performance_1d__reg_s0_live` | 广告每日绩效明细，提供广告曝光、点击、宽口径订单、花费、宽口径 GMV（双币种）及付费宽口径订单/GMV |
| `mp_paidads.dws_advertise_net_ads_revenue_1d__reg_s0_live` | 广告毛收入每日明细，按 `ads_id` 汇总后映射至 `item_id`，提供 `gross_ads_revenue_usd` 的 1/7/30 日滚动值 |

---

## ETL 逻辑摘要

### 数据流

```
traffic_omni_oa.dws_user_item_feature_sales_funnel_metrics_1d__reg_sensitive_live
    │  (local_date in [PREV_30D, BIZ_YESTERDAY], 按 is_today/is_7d/is_14d/is_30d 条件聚合)
    ▼
[CTE: item_base_data]  ── 平台大盘 impression/click/order/gmv_usd (1d/7d/14d/30d)
    │
    ├──────────────────────────────────────────────────────────────────┐
    │                                                                  │
mp_item.dim_item__reg_s0_live                    mp_paidads.dim_advertise__reg_s0_live
    │  (tz_type='local', grass_date=BIZ_YESTERDAY)     │  (grass_date in [PREV_7D, BIZ_YESTERDAY])
    ▼                                                  ▼
[CTE: dim_item]                              [CTE: dim_ads_item]
shop_id, item 创建信息, 三级类目              is_ads_item_1d/7d, is_gms_ads_item_1d
    │                                                  │
    └──────────────┬───────────────────────────────────┘
                   │
mp_paidads.dws_advertise_performance_1d__reg_s0_live
    │  (tz_type='local', grass_date in [PREV_30D, BIZ_YESTERDAY])
    ▼
[CTE: item_ads_data]  ── 广告 impression/click/order/expenditure/gmv (1d/7d/30d)
                   │
mp_paidads.dws_advertise_net_ads_revenue_1d__reg_s0_live
    │  (tz_type='local', gross_ads_revenue_usd_1d > 0)
    ├─► 先按 ads_id 聚合 gross revenue (1d/7d/30d)
    ├─► LEFT JOIN dim_advertise 获取 ads_id → item_id 映射
    ▼
[CTE: item_gross_ads_revenue]  ── gross_ads_revenue_usd (1d/7d/30d)
                   │
                   ▼
    item_base_data (驱动表，以平台有流量的商品为主体)
        LEFT JOIN dim_item             ON item_id
        LEFT JOIN dim_ads_item         ON item_id
        LEFT JOIN item_ads_data        ON item_id
        LEFT JOIN item_gross_ads_revenue ON item_id
                   │
                   ▼
    INSERT OVERWRITE
    mp_paidads.dws_item_performance_nd__reg_s0_live
    PARTITION (tz_type='local', grass_region, grass_date=BIZ_YESTERDAY)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `item_base_data` | `traffic_omni_oa.dws_user_item_feature_sales_funnel_metrics_1d__reg_sensitive_live` | 以商品为粒度，利用 CASE WHEN 条件 SUM 将过去 30 天的每日明细行折叠为 1d/7d/14d/30d 四个滚动窗口的平台大盘指标（曝光、点击、订单、GMV_USD）；作为主驱动表，决定最终结果集的商品范围 |
| `dim_item` | `mp_item.dim_item__reg_s0_live` | 取最新日期快照，补充商品的店铺归属、创建时间及三级类目信息 |
| `dim_ads_item` | `mp_paidads.dim_advertise__reg_s0_live` | 统计近 7 天内有活跃 Product Ads 的商品，以及当日是否有 GMS 类广告，生成三个标签字段 |
| `item_ads_data` | `mp_paidads.dws_advertise_performance_1d__reg_s0_live` | 同 `item_base_data` 逻辑，将广告绩效每日明细折叠为 1d/7d/30d 三个窗口的广告指标（注意：无 14d 窗口） |
| `item_gross_ads_revenue` | `mp_paidads.dws_advertise_net_ads_revenue_1d__reg_s0_live` + `dim_advertise` | 先按 `ads_id` 聚合毛收入（含 1d/7d/30d 窗口），再通过广告维表将 `ads_id` 映射到 `item_id` 后二次聚合；**仅包含 `gross_ads_revenue_usd_1d > 0` 的记录** |

### 注意事项

1. **驱动表决定数据范围**：最终结果以 `item_base_data`（平台流量数据）为主体，仅包含在过去 30 天内有平台曝光或点击行为的商品；**无平台流量的纯新品或下架商品不会出现在本表中**，即使该商品有广告投放记录。

2. **广告数据 LEFT JOIN 可能产生 NULL**：`item_ads_data` 和 `item_gross_ads_revenue` 均以 LEFT JOIN 接入，若某商品有平台流量但无广告数据，广告相关字段将为 NULL（非 0）；查询时需使用 `COALESCE(field, 0)` 做空值处理。

3. **`is_ads_item_7d` 字段逻辑**：在 `dim_ads_item` CTE 中，该字段直接赋值为常量 `1`，而非聚合计算——含义是"只要该 `item_id` 出现在 7 天广告维表结果集中，即标记为 1"；未出现则因 LEFT JOIN 保持 NULL（最终 `COALESCE` 为 0）。

4. **`gross_ads_revenue` 的正值过滤**：源表过滤了 `gross_ads_revenue_usd_1d > 0`，负值（如退款调整）被排除，导致该字段可能略高于实际净收入，与花费类字段做 ROI 计算时应注意口径差异。

5. **`platform_gmv_local_*` 与 `algo_*` 字段**：DDL 中声明了这 8 个字段，但当前 ETL INSERT 语句中未见对应赋值逻辑，疑为预留扩展字段，实际值可能全为 NULL；使用前请通过 `SELECT` 验证。

6. **时间窗口不对称**：平台大盘指标提供 1d/7d/**14d**/30d 四个窗口，而广告指标仅提供 1d/7d/30d 三个窗口（无 14d），在做广告与平台指标对比时需注意窗口对齐。

7. **参数化调度**：ETL 模板中的 `${region}`、`${BIZ_YESTERDAY}`、`${PREV_7D}`、`${PREV_30D}` 等均为调度参数，各地区独立调度写入各自分区，文档中出现的具体地区代码仅为参数示例，不代表覆盖范围限制。

---

*文档生成时间：2026-05-20*
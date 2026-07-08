# ads_advertise_take_rate_v2_1d 表说明

## 1. 表概述

| 属性            | 值                                                                             |
| ------------- | ----------------------------------------------------------------------------- |
| ClickHouse 表名 | `mkplpaidads_search_ads_ads_debug.ads_advertise_take_rate_v2_1d__reg_s0_live` |
| 查询集群          | SG ClickHouse                                                                 |
| 主过滤字段         | `grass_date` (日期), `grass_region` (地区), `tz_type` (时区类型)                      |
| 覆盖地区          | ID, PH, SG, TH, TW, MY, VN, BR                                                |
| 更新频率          | 每日                                                                            |
| 数据层           | ADS (Application Data Service)                                                |

## 2. 如何查询

### 2.1 ClickHouse 查询

take_rate 表已迁移到 SG ClickHouse，统一通过 curl + Basic Auth 查询，SQL 末尾追加 `FORMAT TabSeparatedWithNames`。

查询前先做 partition freshness check：对目标 `grass_date` / `grass_region` / `tz_type` 检查 `count() > 0`。若目标 partition 缺失，报告数据源 freshness warning，不切换到其他查询引擎补数。

### 2.2 ClickHouse 集群

| 集群      | 适用 Region                                                            | URL                                                  | 数据库名                                   |
| ------- | -------------------------------------------------------------------- | ---------------------------------------------------- | -------------------------------------- |
| SG (默认) | TAKE_RATE / OVERALL / SUPPLY_BUDGET 全部 8 region（含 BR）；UNION 表非 BR 部分 | `clickhouse-office-only-ytl.data-infra.shopee.io`    | `mkplpaidads_search_ads_ads_debug`     |
| US-VA2  | 仅 UNION 表 BR 部分                                                      | `clickhouse-office-only-us-va2.data-infra.shopee.io` | `mkplpaidads_search_ads_ads_diagnosis` |

**SG 集群**（默认）：

```bash
curl -s -u 'mkplpaidads_search_ads-cluster_mkplpaidads_mkplpaidads_search_ads_online:b46o8QVbhaN5' \
  --data-binary @- \
  'https://clickhouse-office-only-ytl.data-infra.shopee.io' <<'SQL'
YOUR_SQL_HERE
FORMAT TabSeparatedWithNames
SQL
```

**US-VA2 集群**（仅 UNION 表 BR 数据）：

```bash
curl -s -u 'mkplpaidads_search_ads-cluster_us_2replicas_online:b46o8QVbhaN5' \
  --data-binary @- \
  'https://clickhouse-office-only-us-va2.data-infra.shopee.io' <<'SQL'
YOUR_SQL_HERE
FORMAT TabSeparatedWithNames
SQL
```

### 2.3 ClickHouse 可用表

| 别名        | 表名                                                                            | 集群          | 用途                                                      |
| --------- | ----------------------------------------------------------------------------- | ----------- | ------------------------------------------------------- |
| TAKE_RATE | `mkplpaidads_search_ads_ads_debug.ads_advertise_take_rate_v2_1d__reg_s0_live` | SG          | take_rate 大盘和 entrance / pricingType / seller_type 维度拆解 |
| OVERALL   | `mkplpaidads_search_ads_ads_debug.ads_overall_key_metrics_daily__reg_s0_live` | SG          | 大盘核心指标（take_rate, net_ads_rev）                          |
| UNION     | `{DB}.ads_union_key_metrics_daily__reg_s0_live`                               | 按 region 选择 | 广告主维度明细（campaign/ads/shop 粒度）                           |
| STATUS    | `mkplpaidads_search_ads_ads_debug.dwd_ads_index_status_live`                  | 始终 SG       | 广告状态变更                                                  |

> **`{DB}` 规则（仅 UNION 表）**：`grass_region` ≠ BR → `mkplpaidads_search_ads_ads_debug`（SG 集群）；`grass_region` = BR → `mkplpaidads_search_ads_ads_diagnosis`（US-VA2 集群）。TAKE_RATE 表始终走 SG 集群。

## 3. 表核心用途

Take Rate 大盘分析的核心数据源，每条记录为一个 `(日期, 地区, 入口, pricing_type, 卖家类型)` 维度组合的日聚合指标。表同时包含**广告侧指标**（收入、曝光、点击、GMV）和**平台侧指标**（平台 GMV、平台曝光），可直接计算：

```
take_rate = (net_ads_rev - roi3_voucher_cost) / platform_gmv
```

### 核心公式关系

```
take_rate = rev / platform_gmv
rev = ecpm × adload × platform_imp
rev = advv × cost_ratio
rev = valid_budget × budget_usage
ecpm = coef × pctr × pcr × item_price × sold_cnt / troi
cpm = 1000 * net_ads_rev / ads_imp
cpc = net_ads_rev / ads_click
```

## 4. 字段定义

### 4.1 分区与维度字段

| 字段                  | 类型     | 说明                                                                                                              |
| ------------------- | ------ | --------------------------------------------------------------------------------------------------------------- |
| `grass_date`        | date   | 数据日期（分区）                                                                                                        |
| `grass_region`      | string | 地区（分区）：ID, PH, SG, TH, TW, MY, VN, BR                                                                           |
| `tz_type`           | string | 时区类型（分区）：`regional`（区域时区，最常用）/ `local`（本地时区，Brand/Live Ads 场景）                                                  |
| `entry_point`       | string | 流量入口明细（如 You May Also Like, Daily Discover, Global Search 等）                                                    |
| `traffic_type`      | string | 流量类型（按 entrance 聚合）：Search, Daily Discover, You May Also Like, Video, Livestream 等                              |
| `pricing_type`      | int    | 计费类型：1/2=Manual, 3/4=Simple, 8=TargetROI1, 11=TargetROI2, 15=SimpleROI2, 9/10/14=LiveAds, 18=ROI3, 27=AdGroup 等 |
| `main_product_type` | string | 广告主产品线（按 pricing_type + placement 映射）：Manual, Simple, Target ROI2, Shop Ads, Live Ads 等                         |
| `product_type`      | string | 广告产品线（二级分类）                                                                                                     |
| `sub_product_type`  | string | 广告子产品线（三级分类）：如 video_roi2.0                                                                                     |

### 4.2 卖家属性字段

| 字段                        | 类型      | 说明                                                      |
| ------------------------- | ------- | ------------------------------------------------------- |
| `seller_type`             | string  | 卖家类型（如 MYCB, CNCB, Local）                               |
| `seller_type_1p`          | string  | 1P 卖家类型（如 Local SCS, SCS, Lovito, Unknown）；计算净收入时需排除 1P |
| `is_cb_shop`              | tinyint | 是否跨境卖家（1=是, 0=否）                                        |
| `is_cb_sip_affiliated`    | tinyint | 是否跨境 SIP 关联卖家                                           |
| `is_local_sip_affiliated` | tinyint | 是否本地 SIP 关联卖家                                           |

### 4.3 广告收入指标（分子侧）

| 字段                               | 类型     | 说明                                            | 是否可累加 | 数据源                              |
| -------------------------------- | ------ | --------------------------------------------- | ----- | -------------------------------- |
| `raw_ads_rev_usd`                | double | 原始广告收入（**含税**，商家实际扣费，USD）                     | ✅ 可累加 | dwd_advertiser_deduction_di      |
| `ads_rev_usd`                    | double | 广告收入（**除税**）= raw_ads_rev_usd / (1 + VAT)，USD | ✅ 可累加 | 基于 raw_ads_rev_usd 计算            |
| `gross_ads_rev_usd`              | double | 广告毛收入（USD，**推荐使用**）                           | ✅ 可累加 | dws_advertise_net_ads_revenue_1d |
| `net_ads_rev_usd`                | double | 净广告收入（USD，扣退货退款）                              | ✅ 可累加 | dws_advertise_net_ads_revenue_1d |
| `net_ads_rev_excl_sip_usd_1d`    | double | 净广告收入（USD，不含 SIP，**推荐使用**）                    | ✅ 可累加 | dws_advertise_net_ads_revenue_1d |
| `free_ads_rev_usd`               | double | 免费券金额（税前，不含 free-to-paid）                     | ✅ 可累加 | dws_advertise_net_ads_revenue_1d |
| `sip_free_credit_revenue_usd_1d` | double | SIP 免费券扣费金额                                   | ✅ 可累加 | dws_advertise_net_ads_revenue_1d |
| `expired_amt_usd`                | double | 过期券金额（除税，含 SCS/SIP/Lovito/GOV）                | ✅ 可累加 | dws_advertise_net_ads_revenue_1d |

### 4.4 广告效果指标

| 字段            | 类型     | 说明                              | 是否可累加 | 数据源                                |
| ------------- | ------ | ------------------------------- | ----- | ---------------------------------- |
| `ads_imp`     | bigint | 广告曝光次数，ads_load 分子              | ✅ 可累加 | RNG / Display / Video / Livestream |
| `ads_click`   | bigint | 广告点击次数（OCPM 用去重点击）              | ✅ 可累加 | RNG / Display                      |
| `ads_order`   | bigint | 广告 direct 归因订单量（placed 口径）      | ✅ 可累加 | Performance 表                      |
| `ads_gmv_usd` | double | 广告 direct 归因 GMV（placed 口径，USD） | ✅ 可累加 | Performance 表                      |

### 4.5 平台大盘指标（分母侧）

> **重要**：平台指标在按 entry_point/pricing_type 等维度 GROUP BY 时会重复，聚合时必须用 `SUM(DISTINCT ...)` 去重。所有平台指标仅在 `region/date/tz_type` 维度下可累加，**不可**跨 entry_point / pricing_type 直接 SUM。

| 字段                            | 类型     | 说明                                 | 聚合方式                | 数据源                               |
| ----------------------------- | ------ | ---------------------------------- | ------------------- | --------------------------------- |
| `platform_gmv`                | double | 平台 GMV（Placed 口径，**Local 货币**）     | `SUM(DISTINCT ...)` | Order 表                           |
| `platform_gmv_excl_testorder` | double | 平台 GMV（不含测试订单，Placed 口径）           | `SUM(DISTINCT ...)` | Order 表                           |
| `platform_nmv`                | double | 平台 NMV（Net 口径，**Local 货币**）        | `SUM(DISTINCT ...)` | Order 表                           |
| `platform_imp`                | bigint | 平台大盘总曝光次数                          | `SUM(DISTINCT ...)` | Traffic Omni                      |
| `entry_point_imp`             | bigint | 流量入口总曝光（organic + ads），ads_load 分母 | `SUM(DISTINCT ...)` | Traffic Omni / Video / Livestream |

### 4.6 券成本指标

| 字段                                       | 类型     | 说明                              | 是否可累加                   | 数据源                       |
| ---------------------------------------- | ------ | ------------------------------- | ----------------------- | ------------------------- |
| `ads_voucher_omni_platform_nmv_cost`     | double | 广告券成本（全平台，Net 口径，Local）         | ❌ 仅 region/date/tz_type | Order 表 + Voucher 表       |
| `ads_voucher_omni_platform_nmv_cost_usd` | double | 广告券成本（全平台，Net 口径，USD）           | ❌ 仅 region/date/tz_type | Order 表 + Voucher 表       |
| `ads_voucher_ads_nmv_cost`               | double | 广告券成本（广告 broad 归因，Net 口径，Local） | ✅ 可累加                   | Performance 表 + Voucher 表 |
| `ads_voucher_ads_nmv_cost_usd`           | double | 广告券成本（广告 broad 归因，Net 口径，USD）   | ✅ 可累加                   | Performance 表 + Voucher 表 |
| `ads_voucher_ads_part_amt_usd`           | double | 广告券成本（广告承担部分，Net 口径，USD）        | ❌ 仅 region/date/tz_type | Performance 表 + Voucher 表 |

### 4.7 反欺诈与订单状态指标

> 以下字段均为 ❌ 仅在 `region/date/tz_type` 维度下可累加。每个口径同时提供 USD 和 Local 货币两个版本。

| 字段                                  | 类型     | 说明                                    | 数据源     |
| ----------------------------------- | ------ | ------------------------------------- | ------- |
| `platform_antifraud_gmv_usd`        | double | 平台 GMV（剔除反作弊，Placed 口径，USD）           | Order 表 |
| `platform_antifraud_gmv`            | double | 平台 GMV（剔除反作弊，Placed 口径，Local）         | Order 表 |
| `platform_antifraud_order_fraction` | double | 平台订单量（剔除反作弊，Placed 口径）                | Order 表 |
| `platform_paid_gmv_usd`             | double | 平台 GMV（Paid 口径，USD）                   | Order 表 |
| `platform_paid_gmv`                 | double | 平台 GMV（Paid 口径，Local）                 | Order 表 |
| `platform_paid_order_fraction`      | double | 平台订单量（Paid 口径）                        | Order 表 |
| `platform_confirmed_gmv_usd`        | double | 平台 GMV（Confirm 口径，USD）                | Order 表 |
| `platform_confirmed_gmv`            | double | 平台 GMV（Confirm 口径，Local）              | Order 表 |
| `platform_confirmed_order_fraction` | double | 平台订单量（Confirm 口径）                     | Order 表 |
| `platform_complete_gmv_usd`         | double | 平台 GMV（Complete 口径，USD）               | Order 表 |
| `platform_complete_gmv`             | double | 平台 GMV（Complete 口径，Local）             | Order 表 |
| `platform_complete_order_fraction`  | double | 平台订单量（Complete 口径）                    | Order 表 |
| `platform_cancel_gmv_usd`           | double | 平台 GMV（Cancel 口径，USD）                 | Order 表 |
| `platform_cancel_gmv`               | double | 平台 GMV（Cancel 口径，Local）               | Order 表 |
| `platform_cancel_order_fraction`    | double | 平台订单量（Cancel 口径）                      | Order 表 |
| `platform_return_gmv_usd`           | double | 平台 GMV（Return 口径，USD）                 | Order 表 |
| `platform_return_gmv`               | double | 平台 GMV（Return 口径，Local）               | Order 表 |
| `platform_return_order_fraction`    | double | 平台订单量（Return 口径）                      | Order 表 |
| `platform_net_order_fraction`       | double | 平台订单量（Net 口径，剔除 cancel/return/refund） | Order 表 |
| `omni_platform_nmv`                 | double | 平台 NMV（Net 口径，Local）                  | Order 表 |
| `omni_platform_nmv_usd`             | double | 平台 NMV（Net 口径，USD）                    | Order 表 |

### 4.8 COD 混合口径指标

> 以下字段针对 COD（货到付款）场景提供混合口径，均为 ❌ 仅 `region/date/tz_type` 可累加。

| 字段 | 类型 | 说明 | 数据源 |
|------|------|------|--------|
| `platform_paid_with_confirmed_cod_gmv_usd` | double | 平台 GMV（非 COD 取 Paid，COD 取 Confirm，USD） | Order 表 |
| `platform_paid_with_confirmed_cod_gmv` | double | 平台 GMV（非 COD 取 Paid，COD 取 Confirm，Local） | Order 表 |
| `platform_paid_order_with_confirmed_cod_fraction` | double | 平台订单量（非 COD 取 Paid，COD 取 Confirm） | Order 表 |
| `platform_paid_with_placed_cod_gmv_usd` | double | 平台 GMV（非 COD 取 Paid，COD 取 Placed，USD） | Order 表 |
| `platform_paid_with_placed_cod_gmv` | double | 平台 GMV（非 COD 取 Paid，COD 取 Placed，Local） | Order 表 |
| `platform_paid_order_with_placed_cod_fraction` | double | 平台订单量（非 COD 取 Paid，COD 取 Placed） | Order 表 |

### 4.9 直播指标

| 字段 | 类型 | 说明 | 是否可累加 | 数据源 |
|------|------|------|-----------|--------|
| `live_total_entry_point_imp` | bigint | Live 场景总曝光（organic + ads） | ❌ 仅 region/date/tz_type | Livestream 表 |
| `live_total_ads_imp` | bigint | Live 场景广告曝光 | ❌ 仅 region/date/tz_type | Livestream 表 |

## 5. 查询约定

### 5.1 必备过滤条件

```sql
WHERE grass_date = toDate('YYYY-MM-DD')
  AND tz_type = 'regional'  -- 大盘分析默认用 regional
  AND grass_region IN ('ID', 'MY', 'PH', 'SG', 'TH', 'TW', 'VN', 'BR')
```

### 5.2 tz_type 选择

| 值 | 使用场景 |
|------|------|
| `regional` | **默认**，大盘 take_rate 分析、日报、周报（10/12 查询使用） |
| `local` | Brand Ads / Live Ads 专项分析 |

### 5.3 平台指标去重

平台 GMV、平台曝光等字段在按广告维度 GROUP BY 时会重复，**必须**用 `DISTINCT` 去重：

```sql
SUM(DISTINCT platform_gmv) AS platform_gmv
SUM(DISTINCT platform_gmv_excl_testorder) AS platform_gmv
SUM(DISTINCT platform_imp) AS platform_imp
SUM(DISTINCT entry_point_imp) AS entry_point_imp
```

### 5.4 排除 1P 卖家

计算净收入时通常需排除 1P（SCS/Lovito）卖家：

```sql
SUM(CASE WHEN seller_type_1p NOT IN ('Local SCS', 'SCS', 'Lovito')
         THEN net_ads_rev_usd END) AS net_ads_rev_excl_1p
```

## 6. 常用衍生指标

| 衍生指标 | 计算公式 |
|----------|----------|
| Take Rate（净） | `(net_ads_rev - roi3_voucher_cost) / platform_gmv` |
| Take Rate（毛） | `gross_ads_rev_usd / platform_gmv` |
| Take Rate（排除 1P+SIP） | `net_ads_rev_excl_1p_sip / platform_gmv` |
| Ad Load（曝光渗透率） | `ads_imp / platform_imp` |
| CTR | `ads_click / ads_imp` |
| Realized CPM（净收入口径） | `1000 * net_ads_rev_usd / ads_imp` |
| Realized CPC（净收入口径） | `net_ads_rev_usd / ads_click` |
| 广告 ROI | `ads_gmv_usd / ads_rev_usd` |
| 广告 GMV 渗透率 | `ads_gmv_usd / platform_gmv` |

### 6.1 TR 达标率 / fulfillment 补充字段

TAKE_RATE / OVERALL / SUPPLY_BUDGET ClickHouse 主表当前不完整承载 category × item order bucket 的达标率分析。若用户明确要求解释 category own rate effect、budget usage 下降、fulfillment、overbid-underbid 或 item-order-bucket，才读取 tracker / raw sheet 或补充明细表；不要仅因 ClickHouse L0 category own-rate effect 为负就自动读取 tracker。常用字段如下：

| 字段 | 含义 | 诊断用法 |
|------|------|----------|
| `shop_level0_global_be_category` / `cluster` | L0 category | 拆 GMV mix effect 与 category own rate effect |
| `ld_30dorder_tier` | 近 30 天订单 bucket（A:0单、B:1-10单、C:10-100单、D:100单+） | 判断预算增长集中在哪类 seller / item |
| `avg_daily_valid_budget_usd` | 日均有效预算 | 看 budget 增量 |
| `budget_utilization` | 预算使用率 | 看预算是否被消耗 |
| `ads_fulfillment_rate` / `fulfillment_rate` | 达标率 / 履约率 | 看广告调控效率是否下降 |
| `overbid_revenue_share` | overbid 收入占比 | 达标率下降时判断是否超收方向变多 |
| `underbid_revenue_share` | underbid 收入占比 | 达标率下降时判断是否欠收方向变多 |
| `no_gmv_revenue_share` | no-GMV 收入占比 | 排查无 GMV 归因口径 |
| `target_roi_p50/p80/p90` | TROI / ROAS setting 分位 | 验证 ROAS 设置变化是否足以解释 TR drop |

报告中必须说明这些字段来自 tracker / raw data 还是源表重算；如果不可用，写 `fulfillment source unavailable`，不要把达标率当作已检查项。

### 6.2 L0 category source for TR deep dive

TR 的 L0 category deep dive 使用业务类目（例如 FMCG、Fashion、Lifestyle、Electronics），不是基础设施 cluster。数据源优先级：

1. OVERALL ClickHouse 表：`mkplpaidads_search_ads_ads_debug.ads_overall_key_metrics_daily__reg_s0_live.cluster`。`cluster = 'ALL'` 表示不按 cluster 拆分；`cluster != 'ALL'` 是已预聚合的 L0 category / cluster breakdown。
2. Google Sheet tracker：`1bWYzI0QYr8E5U7eYBCX9YbIz-Jscami-5E1E80lTyMQ` 的 `MTD, YTD` tab 中 `by cluster metrics trending` 区块，仅在 ClickHouse L0 category 数据缺失/不完整、表权限失败，或用户明确要求 tracker benchmark 时读取。
3. 同一 tracker 的 `daily_data_raw` tab W 列及以后，仅用于 ClickHouse cluster 数据不可用时的 daily category raw metrics 复算。

OVERALL ClickHouse 推荐查询方式：

```sql
WITH l0 AS (
    SELECT
        grass_date,
        grass_region,
        cluster,
        SUM(net_ads_rev) AS c_net_ads_rev,
        SUM(broad_gmv_usd) AS c_broad_gmv_usd
    FROM mkplpaidads_search_ads_ads_debug.ads_overall_key_metrics_daily__reg_s0_live
    WHERE grass_date BETWEEN toDate('{period_start}') AND toDate('{period_end}')
      AND grass_region = '{region}'
      AND entrance = '{overall_entrance}'
      AND pricing_type = '{overall_pricing_type}'
      AND cluster != 'ALL'
    GROUP BY 1, 2, 3
)
SELECT
    grass_date,
    grass_region,
    cluster,
    c_net_ads_rev AS net_ads_rev,
    c_broad_gmv_usd AS broad_gmv_usd,
    c_net_ads_rev / nullIf(c_broad_gmv_usd, 0) AS category_tr
FROM l0
```

注意：

- 总量对照使用 `cluster = 'ALL'`；L0 breakdown 使用 `cluster != 'ALL'`。不要把 `cluster='ALL'` 与具体 cluster 行一起 SUM，否则会重复计算。
- `cluster != 'ALL'` 行的 `platform_gmv` 不可用；L0 category 的 GMV share、category TR、mix effect、own-rate effect 统一使用 `broad_gmv_usd`。报告中必须标注这是 broad-GMV diagnostic view，不是生产口径 `platform_gmv` TR。
- 若 OVERALL ClickHouse `cluster != 'ALL'` 覆盖目标 Period A/B、region、entrance、pricingType 且 `net_ads_rev` / `broad_gmv_usd` 可用，不要读取 tracker。
- L0 category 正常路径不需要实时 join `shop_id` 或 `mp_paidads.dim_shop_info__reg_s0_live.cluster` 重算。
- `ads_union_key_metrics_daily__reg_s0_live` 的 `shop_level1_global_be_category` / `shop_level2_global_be_category` 只能作为 ads-side category proxy；不要把 proxy 结论写成生产 take-rate L0 category 结论。
- 若 OVERALL cluster 数据缺失/不完整且 tracker fallback 也不可用，报告写 `L0 category source unavailable`，并列出缺失工具 / 权限 / 待跑 SQL。若 OVERALL cluster 数据完整，不要因为未读 tracker 降低 L0 category source 可用性。

## 7. traffic_type → entrance 映射

```sql
CASE
    WHEN traffic_type = 'Search'          THEN 'search'
    WHEN traffic_type = 'Daily Discover'  THEN 'dd'
    WHEN traffic_type = 'You May Also Like' THEN 'ymal'
    WHEN traffic_type = 'Video'           THEN 'video'
    WHEN traffic_type = 'Livestream'      THEN 'live'
    WHEN traffic_type = 'Post Purchase'   THEN 'pp'
    WHEN traffic_type = 'Game'            THEN 'game'
    WHEN traffic_type = 'Brand'           THEN 'brand'
    ELSE 'other'
END AS entrance
```

## 8. pricing_type → 产品名称映射

```sql
CASE
    WHEN entry_point IN ('Shop', 'Shop Game', 'Display') THEN 'Shop Ads'
    WHEN pricing_type IN (1, 2)  THEN 'Manual'
    WHEN pricing_type IN (3, 4)  THEN 'Simple'
    WHEN pricing_type IN (8)     THEN 'Target ROI1'
    WHEN pricing_type IN (11)    THEN 'Target ROI2'
    WHEN pricing_type IN (15)    THEN 'Simple ROI2'
    WHEN pricing_type IN (7)     THEN 'Autoboost'
    WHEN pricing_type IN (13)    THEN 'NPB'
    WHEN pricing_type IN (18)    THEN 'ROI3'
    WHEN pricing_type IN (9, 10, 14) THEN 'Live Ads'
    ELSE 'Others'
END AS main_product_type
```

## 9. 典型查询模式

### 9.1 Take Rate 日报

```sql
SELECT grass_date, grass_region,
    SUM(net_ads_rev_usd) AS net_ads_rev,
    SUM(ads_voucher_ads_nmv_cost_usd) AS roi3_voucher_cost,
    SUM(ads_imp) AS ads_imp,
    SUM(ads_click) AS ads_click,
    SUM(DISTINCT platform_gmv) AS platform_gmv,
    (SUM(net_ads_rev_usd) - SUM(ads_voucher_ads_nmv_cost_usd))
        / SUM(DISTINCT platform_gmv) AS take_rate,
    1000 * SUM(net_ads_rev_usd) / nullIf(SUM(ads_imp), 0) AS cpm,
    SUM(net_ads_rev_usd) / nullIf(SUM(ads_click), 0) AS cpc
FROM mkplpaidads_search_ads_ads_debug.ads_advertise_take_rate_v2_1d__reg_s0_live
WHERE grass_date = toDate('YYYY-MM-DD')
  AND tz_type = 'regional'
  AND grass_region IN ('ID','MY','PH','SG','TH','TW','VN','BR')
GROUP BY 1, 2
```

### 9.2 多维度 GROUPING SETS 汇总

```sql
SELECT grass_date,
    COALESCE(grass_region, 'ALL') AS grass_region,
    COALESCE(entrance, 'ALL') AS entrance,
    COALESCE(pricing_type, 'ALL') AS pricing_type,
    SUM(net_ads_rev_usd) AS net_ads_rev,
    SUM(ads_imp) AS ads_imp,
    SUM(ads_click) AS ads_click,
    SUM(DISTINCT platform_gmv) AS platform_gmv,
    1000 * SUM(net_ads_rev_usd) / nullIf(SUM(ads_imp), 0) AS cpm,
    SUM(net_ads_rev_usd) / nullIf(SUM(ads_click), 0) AS cpc
FROM take_rate_data
GROUP BY GROUPING SETS (
    (grass_date, grass_region, entrance, pricing_type),
    (grass_date, grass_region, entrance),
    (grass_date, grass_region, pricing_type),
    (grass_date, grass_region),
    (grass_date, entrance),
    (grass_date, pricing_type),
    (grass_date)
)
```

### 9.3 按产品类型拆分（需 SELF JOIN 获取去重 platform_gmv）

```sql
-- t1: 按产品维度聚合收入
-- t2: 单独查询 platform_gmv（需 DISTINCT 去重）
-- JOIN on (grass_date, grass_region)
SELECT t1.main_product_type, t1.grass_region, t1.grass_date,
    AVG(t2.platform_gmv) AS platform_gmv,
    SUM(t1.net_ads_rev) AS net_ads_rev
FROM (... GROUP BY grass_date, grass_region, main_product_type) t1
LEFT JOIN (... SUM(DISTINCT platform_gmv) GROUP BY grass_date, grass_region) t2
  ON t1.grass_date = t2.grass_date AND t1.grass_region = t2.grass_region
GROUP BY 1, 2, 3
```

> 来源：[Take Rate 表字段说明 GSheet](https://docs.google.com/spreadsheets/d/1ZrYRw-jdEhdIGxF-NuRcOpKswEvqK_bscvbFtoZW1rU/edit?gid=1594221342#gid=1594221342) "take_rate 表字段" tab

---

## 10. SUPPLY_BUDGET 表

### 10.1 表概述

| 属性            | 值                                                                                                          |
| ------------- | ---------------------------------------------------------------------------------------------------------- |
| ClickHouse 表名 | `mkplpaidads_search_ads_ads_debug.overall_supply_budget_metrics_daily__reg_s0_live`                        |
| 集群            | **SG only**（`clickhouse-office-only-ytl.data-infra.shopee.io`） — 注意：与 OVERALL/UNION 不同，本表**不**按 region 分集群 |
| 覆盖地区          | ID, PH, SG, TH, TW, MY, VN, **BR**（全部 region；BR 数据也在 SG 集群）                                                |
| 分区字段          | `grass_date`, `grass_region`                                                                               |
| 维度字段          | `pricing_type`, `budget_type`                                                                              |
| 更新频率          | 每日                                                                                                         |
| 用途            | 大盘诊断 OR7（预算 / 余额）、OR11（广告规模 / 供给侧）归因                                                                       |

### 10.2 字段定义

#### 10.2.1 分区与维度字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_date` | date | 数据日期（分区） |
| `grass_region` | string | 地区（分区）：ID, PH, SG, TH, TW, MY, VN, BR（全部 region 数据均在 SG 集群） |
| `pricing_type` | string | 计费类型；含 `'all'` 预聚合行 |
| `budget_type` | string | 预算类型：`limited` / `unlimited` / `all`；`unlimited` 对应 `budget_usd=9999999999`，`'all'` 为预聚合行 |

#### 10.2.2 供给侧指标（OR11 归因）

| 字段 | 类型 | 含义 | 口径 |
|------|------|------|------|
| `active_ads_cnt` | bigint | 有曝光的广告数量 | 当日 ads 维度去重计数 |
| `active_advertiser_cnt` | bigint | 有曝光的广告主数量 | 当日 shop 维度去重计数 |

#### 10.2.3 预算 / 余额指标（OR7 归因）

| 字段 | 类型 | 含义 | 口径 |
|------|------|------|------|
| `daily_valid_budget` | double | Campaign 粒度 valid_budget 求和（**USD**） | `SUM(campaign_valid_budget_usd)` |
| `topup_amt_usd` | double | Shop 粒度充值金额求和（**USD**） | `SUM(shop_topup_amt_usd)` |
| `account_balance_usd` | double | Shop 粒度账户余额求和（**USD**） | `SUM(shop_account_balance_usd)` |

### 10.3 查询约定

#### 10.3.1 必备过滤条件

```sql
WHERE grass_date BETWEEN toDate('{period_b_start}') AND toDate('{period_a_end}')
  AND grass_region = '{region}'  -- 支持任意 region，包括 BR
```

#### 10.3.2 预聚合维度处理

`pricing_type` 和 `budget_type` 含 `'all'` 预聚合行。**不要**同时包含 `'all'` 和具体值，会重复计算：

| 查询目标 | WHERE 条件 |
|---------|-----------|
| 大盘总量（不拆分） | `pricing_type='all' AND budget_type='all'` |
| 按 pricing_type 拆分 | `pricing_type!='all' AND budget_type='all'` |
| 按 budget_type 拆分（limited / unlimited） | `pricing_type='all' AND budget_type!='all'` |
| 交叉拆分 pricing_type × budget_type | `pricing_type!='all' AND budget_type!='all'` |

#### 10.3.3 ClickHouse 查询模板

```bash
curl -s -u 'mkplpaidads_search_ads-cluster_mkplpaidads_mkplpaidads_search_ads_online:b46o8QVbhaN5' \
  --data-binary @- \
  'https://clickhouse-office-only-ytl.data-infra.shopee.io' <<'SQL'
SELECT
    grass_date, grass_region,
    SUM(active_ads_cnt) AS active_ads_cnt,
    SUM(active_advertiser_cnt) AS active_advertiser_cnt,
    SUM(daily_valid_budget) AS valid_budget_usd,
    SUM(topup_amt_usd) AS topup_amt_usd,
    SUM(account_balance_usd) AS account_balance_usd
FROM mkplpaidads_search_ads_ads_debug.overall_supply_budget_metrics_daily__reg_s0_live
WHERE grass_date BETWEEN toDate('2026-04-01') AND toDate('2026-04-07')
    AND grass_region = 'ID'
    AND pricing_type = 'all'
    AND budget_type = 'all'
GROUP BY grass_date, grass_region
ORDER BY grass_date ASC
FORMAT TabSeparatedWithNames
SQL
```

### 10.4 与其他表的关系

| 维度 | 本表 | OVERALL 表 |
|------|------|-----------|
| 维度粒度 | `(date, region, pricing_type, budget_type)` | `(date, region, entrance, pricing_type)` |
| entrance 拆分 | ❌ 不支持 | ✅ |
| budget_type 拆分 | ✅ | ❌ |
| 覆盖 region | SG 集群覆盖全部 8 个 region（含 BR） | SG 集群覆盖非 BR；BR 走 US-VA2 |
| 主用途 | OR7 / OR11 归因（供给 + 预算） | 收入 / 漏斗 / 出价 / 预估 / GMV 全量归因 |

<!-- ads-workspace-gdoc-sync: gdoc_id=1usCNYEUP9FG06KT8Oh1uR0INnAH013KkHEuSzsn06w4 gdoc_url=https://docs.google.com/document/d/1usCNYEUP9FG06KT8Oh1uR0INnAH013KkHEuSzsn06w4/edit -->

# mp_paidads.dws_advertise_performance_nd

**分层**：DWS（数据服务层，汇总层）
**主键**：`ads_id` + `placement` + `ads_type` + `shop_id` + `seller_id` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（D+1），按各地区本地时区参数化执行
**引用频次**：2 次（候选表范围内）

---

## 业务描述

本表是广告绩效的多时间窗口汇总宽表，以广告维度（广告 ID、广告类型、投放位置、店铺、卖家）为粒度，预计算 1 天、7 天、30 天、60 天、90 天等滚动窗口下的曝光、点击、订单、GMV、花费及各类派生比率指标。数据来源于每日分区的广告绩效明细表 `dws_advertise_performance_1d__reg_s0_live`，通过滚动窗口聚合后写入，供下游报表、看板及策略分析快速消费，无需在查询层做跨日聚合。

本表同时提供**直接归因（Direct）** 和**广泛归因（Broad）** 两套 GMV、订单及 ROI 指标体系，方便业务在不同归因口径下评估广告效果。ROI、CIR、CTR、CR、CPC 等比率指标均为预计算存储值，查询时可直接使用，但若需跨广告维度汇总，必须回溯分子/分母原始字段重新计算。

典型使用场景包括：广告主绩效日报、广告 ROI 趋势监控、多时间窗口对比分析（如 7 日 vs 30 日趋势）、广告类型 / 投放位置效果对比等。该表通过参数化调度覆盖所有地区，各地区按本地时区独立产出数据。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区键。常见值为 `local`（本地时区）和 `utc`。**查询时必须指定**，推荐使用 `tz_type = 'local'`，否则将产生跨时区重复计算 |
| `grass_region` | string | 地区分区键，存储为大写国家/地区代码（如 `MX`、`BR`）。**查询时必须指定** |
| `grass_date` | date | 日期分区键，标识本条汇总数据的基准日期（即调度日期）。**查询时必须指定**，直接取最新分区即为最新滚动窗口数据 |

---

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告 ID，唯一标识一条广告 |
| `placement` | bigint | 广告投放位置标识。⚠️ 当 `placement = 20` 时，ETL 中强制将 `ads_type` 覆盖为 `'shop_simple'`，查询时需注意此特殊处理逻辑 |
| `ads_type` | string | 广告类型，枚举值包括：`targeting:similar_product`、`keyword:search`、`targeting:daily_discover`、`keyword:simple_mode`、`targeting:ymal`、`targeting:simple_mode_ymal`、`targeting:simple_mode_sp`、`targeting:simple_mode_dd`；当 `placement=20` 时固定为 `shop_simple` |
| `shop_id` | bigint | 店铺 ID |
| `seller_id` | bigint | 卖家 ID |

---

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|------|------|------|
| `impression_cnt_1d` | bigint | 近 1 天广告曝光次数（去重，可能含作弊流量）⚠️ 官方注明可能包含欺诈流量，用于质量分析时需结合反作弊过滤 |
| `impression_cnt_7d` | bigint | 近 7 天广告曝光次数（去重，可能含作弊流量）⚠️ 同上 |
| `impression_cnt_30d` | bigint | 近 30 天广告曝光次数（去重，可能含作弊流量）⚠️ 同上 |
| `impression_cnt_60d` | bigint | 近 60 天广告曝光次数（去重，可能含作弊流量）⚠️ 同上 |
| `impression_cnt_90d` | bigint | 近 90 天广告曝光次数（去重，可能含作弊流量）⚠️ 同上 |
| `click_cnt_1d` | bigint | 近 1 天成功扣费的点击次数 |
| `click_cnt_7d` | bigint | 近 7 天成功扣费的点击次数 |
| `click_cnt_30d` | bigint | 近 30 天成功扣费的点击次数 |
| `click_cnt_60d` | bigint | 近 60 天成功扣费的点击次数 |
| `click_cnt_90d` | bigint | 近 90 天成功扣费的点击次数 |
| `ctr_1d` | double | 近 1 天点击率（CTR）= `click_cnt_1d / impression_cnt_1d`，分母为 0 时取 0.0 ⚠️ 预计算比率，跨广告汇总时不可直接 SUM，需用 `SUM(click_cnt_1d) / SUM(impression_cnt_1d)` 重新计算 |
| `ctr_7d` | double | 近 7 天点击率（CTR）⚠️ 同上 |
| `ctr_30d` | double | 近 30 天点击率（CTR）⚠️ 同上 |
| `ctr_60d` | double | 近 60 天点击率（CTR）⚠️ 同上 |
| `ctr_90d` | double | 近 90 天点击率（CTR）⚠️ 同上 |

---

### 指标：直接归因订单与销量

| 字段 | 类型 | 说明 |
|------|------|------|
| `order_cnt_1d` | bigint | 近 1 天直接归因订单数 |
| `order_cnt_7d` | bigint | 近 7 天直接归因订单数 |
| `order_cnt_30d` | bigint | 近 30 天直接归因订单数 |
| `order_cnt_60d` | bigint | 近 60 天直接归因订单数 |
| `order_cnt_90d` | bigint | 近 90 天直接归因订单数 |
| `paid_order_cnt_ytd_1d` | bigint | 昨日（`is_today=1` 分区）已付款订单数（YTD 口径）⚠️ 仅汇聚当天数据，不反映滚动窗口累计；与 `order_cnt_1d` 口径不同，需区分使用 |
| `confirmed_order_cnt_ytd_1d` | bigint | 昨日（`is_today=1` 分区）已确认订单数（YTD 口径）⚠️ 同上，仅当天口径，非滚动窗口 |
| `ads_items_sold_cnt_1d` | bigint | 近 1 天直接归因订单售出商品总数 |
| `ads_items_sold_cnt_7d` | bigint | 近 7 天直接归因订单售出商品总数 |
| `ads_items_sold_cnt_30d` | bigint | 近 30 天直接归因订单售出商品总数 |
| `ads_items_sold_cnt_60d` | bigint | 近 60 天直接归因订单售出商品总数 |
| `ads_items_sold_cnt_90d` | bigint | 近 90 天直接归因订单售出商品总数 |
| `cr_1d` | double | 近 1 天转化率（CR）= `order_cnt_1d / click_cnt_1d`，分母为 0 时取 0.0 ⚠️ 预计算比率，跨广告汇总时不可直接 SUM，需用 `SUM(order_cnt_1d) / SUM(click_cnt_1d)` 重新计算 |
| `cr_7d` | double | 近 7 天转化率（CR）⚠️ 同上 |
| `cr_30d` | double | 近 30 天转化率（CR）⚠️ 同上 |
| `cr_60d` | double | 近 60 天转化率（CR）⚠️ 同上 |
| `cr_90d` | double | 近 90 天转化率（CR）⚠️ 同上 |

---

### 指标：直接归因 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_gmv_amt_local_1d` | double | 近 1 天直接归因订单 GMV（本地货币） |
| `ads_gmv_amt_local_7d` | double | 近 7 天直接归因订单 GMV（本地货币） |
| `ads_gmv_amt_local_30d` | double | 近 30 天直接归因订单 GMV（本地货币） |
| `ads_gmv_amt_local_60d` | double | 近 60 天直接归因订单 GMV（本地货币） |
| `ads_gmv_amt_local_90d` | double | 近 90 天直接归因订单 GMV（本地货币） |
| `ads_gmv_amt_usd_1d` | double | 近 1 天直接归因订单 GMV（美元） |
| `ads_gmv_amt_usd_7d` | double | 近 7 天直接归因订单 GMV（美元） |
| `ads_gmv_amt_usd_30d` | double | 近 30 天直接归因订单 GMV（美元） |
| `ads_gmv_amt_usd_60d` | double | 近 60 天直接归因订单 GMV（美元） |
| `ads_gmv_amt_usd_90d` | double | 近 90 天直接归因订单 GMV（美元） |

---

### 指标：广告花费

| 字段 | 类型 | 说明 |
|------|------|------|
| `expenditure_amt_local_1d` | double | 近 1 天广告扣费总额（本地货币） |
| `expenditure_amt_local_7d` | double | 近 7 天广告扣费总额（本地货币） |
| `expenditure_amt_local_30d` | double | 近 30 天广告扣费总额（本地货币） |
| `expenditure_amt_local_60d` | double | 近 60 天广告扣费总额（本地货币） |
| `expenditure_amt_local_90d` | double | 近 90 天广告扣费总额（本地货币） |
| `expenditure_amt_usd_1d` | double | 近 1 天广告扣费总额（美元） |
| `expenditure_amt_usd_7d` | double | 近 7 天广告扣费总额（美元） |
| `expenditure_amt_usd_30d` | double | 近 30 天广告扣费总额（美元） |
| `expenditure_amt_usd_60d` | double | 近 60 天广告扣费总额（美元） |
| `expenditure_amt_usd_90d` | double | 近 90 天广告扣费总额（美元） |

---

### 指标：直接归因效率（CPC / CIR / ROI）

| 字段 | 类型 | 说明 |
|------|------|------|
| `cpc_local_1d` | double | 近 1 天每次点击费用 CPC（本地货币）= `expenditure_amt_local_1d / click_cnt_1d` ⚠️ 预计算比率，不可直接 SUM，跨维度汇总需用 `SUM(expenditure_amt_local_1d) / SUM(click_cnt_1d)` |
| `cpc_local_7d` | double | 近 7 天 CPC（本地货币）⚠️ 同上 |
| `cpc_local_30d` | double | 近 30 天 CPC（本地货币）⚠️ 同上 |
| `cpc_local_60d` | double | 近 60 天 CPC（本地货币）⚠️ 同上 |
| `cpc_local_90d` | double | 近 90 天 CPC（本地货币）⚠️ 同上 |
| `cpc_usd_1d` | double | 近 1 天 CPC（美元）⚠️ 预计算比率，不可直接 SUM，跨维度汇总需用 `SUM(expenditure_amt_usd_1d) / SUM(click_cnt_1d)` |
| `cpc_usd_7d` | double | 近 7 天 CPC（美元）⚠️ 同上 |
| `cpc_usd_30d` | double | 近 30 天 CPC（美元）⚠️ 同上 |
| `cpc_usd_60d` | double | 近 60 天 CPC（美元）⚠️ 同上 |
| `cpc_usd_90d` | double | 近 90 天 CPC（美元）⚠️ 同上 |
| `cir_1d` | double | 近 1 天直接归因订单成本收益率（CIR）= `expenditure_amt_local_1d / ads_gmv_amt_local_1d`，为 ROI 的倒数 ⚠️ 预计算比率，不可直接 SUM，跨维度汇总需用分子/分母重新计算 |
| `cir_7d` | double | 近 7 天 CIR ⚠️ 同上 |
| `cir_30d` | double | 近 30 天 CIR ⚠️ 同上 |
| `cir_60d` | double | 近 60 天 CIR ⚠️ 同上 |
| `cir_90d` | double | 近 90 天 CIR ⚠️ 同上 |
| `roi_1d` | double | 近 1 天直接归因 ROI = `ads_gmv_amt_local_1d / expenditure_amt_local_1d`，为 CIR 的倒数 ⚠️ 预计算比率，不可直接 SUM，跨维度汇总需用 `SUM(ads_gmv_amt_local_1d) / SUM(expenditure_amt_local_1d)` |
| `roi_7d` | double | 近 7 天直接归因 ROI ⚠️ 同上 |
| `roi_30d` | double | 近 30 天直接归因 ROI ⚠️ 同上 |
| `roi_60d` | double | 近 60 天直接归因 ROI ⚠️ 同上 |
| `roi_90d` | double | 近 90 天直接归因 ROI ⚠️ 同上 |

---

### 指标：广泛归因 GMV 与订单

| 字段 | 类型 | 说明 |
|------|------|------|
| `broad_gmv_amt_local_1d` | double | 近 1 天广泛归因订单 GMV（本地货币） |
| `broad_gmv_amt_local_7d` | double | 近 7 天广泛归因订单 GMV（本地货币） |
| `broad_gmv_amt_local_30d` | double | 近 30 天广泛归因订单 GMV（本地货币） |
| `broad_gmv_amt_local_60d` | double | 近 60 天广泛归因订单 GMV（本地货币） |
| `broad_gmv_amt_local_90d` | double | 近 90 天广泛归因订单 GMV（本地货币） |
| `broad_gmv_amt_usd_1d` | double | 近 1 天广泛归因订单 GMV（美元） |
| `broad_gmv_amt_usd_7d` | double | 近 7 天广泛归因订单 GMV（美元） |
| `broad_gmv_amt_usd_30d` | double | 近 30 天广泛归因订单 GMV（美元） |
| `broad_gmv_amt_usd_60d` | double | 近 60 天广泛归因订单 GMV（美元） |
| `broad_gmv_amt_usd_90d` | double | 近 90 天广泛归因订单 GMV（美元） |
| `broad_order_cnt_1d` | bigint | 近 1 天广泛归因订单数 |
| `broad_order_cnt_7d` | bigint | 近 7 天广泛归因订单数 |
| `broad_order_cnt_30d` | bigint | 近 30 天广泛归因订单数 |
| `broad_order_cnt_60d` | bigint | 近 60 天广泛归因订单数 |
| `broad_order_cnt_90d` | bigint | 近 90 天广泛归因订单数 |

---

### 指标：广泛归因 ROI

| 字段 | 类型 | 说明 |
|------|------|------|
| `broad_roi_1d` | double | 近 1 天广泛归因 ROI = `broad_gmv_amt_local_1d / expenditure_amt_local_1d` ⚠️ 预计算比率，不可直接 SUM，跨维度汇总需用 `SUM(broad_gmv_amt_local_1d) / SUM(expenditure_amt_local_1d)` |
| `broad_roi_7d` | double | 近 7 天广泛归因 ROI ⚠️ 同上 |
| `broad_roi_30d` | double | 近 30 天广泛归因 ROI ⚠️ 同上 |
| `broad_roi_60d` | double | 近 60 天广泛归因 ROI ⚠️ 同上 |
| `broad_roi_90d` | double | 近 90 天广泛归因 ROI ⚠️ 同上 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，否则将触发全表扫描，造成资源浪费或数据重复：

| 分区字段 | 推荐过滤值 | 遗漏后果 |
|----------|-----------|---------|
| `tz_type` | `tz_type = 'local'`（本地时区口径，与业务对齐） | 同一广告数据按两种时区写入，不过滤将导致数据翻倍 |
| `grass_region` | 指定具体地区，如 `grass_region = 'MX'` | 多地区数据混合，指标无法对应正确货币与业务口径 |
| `grass_date` | 取最新分区或指定日期，如 `grass_date = '2026-04-21'` | 全量历史分区扫描，资源消耗极大 |

**示例：**
```sql
SELECT *
FROM mp_paidads.dws_advertise_performance_nd
WHERE tz_type = 'local'
  AND grass_region = 'MX'
  AND grass_date = '2026-04-21';
```

### 不可直接 SUM 的字段

以下字段为 ETL 预计算的比率/派生值，在行粒度正确但**跨广告维度汇总时不可直接 SUM**：

| 字段组 | 正确的跨维度汇总方式 |
|--------|-------------------|
| `ctr_Xd`（点击率） | `SUM(click_cnt_Xd) / NULLIF(SUM(impression_cnt_Xd), 0)` |
| `cr_Xd`（转化率） | `SUM(order_cnt_Xd) / NULLIF(SUM(click_cnt_Xd), 0)` |
| `cpc_local_Xd`（本地 CPC） | `SUM(expenditure_amt_local_Xd) / NULLIF(SUM(click_cnt_Xd), 0)` |
| `cpc_usd_Xd`（美元 CPC） | `SUM(expenditure_amt_usd_Xd) / NULLIF(SUM(click_cnt_Xd), 0)` |
| `cir_Xd`（成本收益率） | `SUM(expenditure_amt_local_Xd) / NULLIF(SUM(ads_gmv_amt_local_Xd), 0)` |
| `roi_Xd`（直接 ROI） | `SUM(ads_gmv_amt_local_Xd) / NULLIF(SUM(expenditure_amt_local_Xd), 0)` |
| `broad_roi_Xd`（广泛 ROI） | `SUM(broad_gmv_amt_local_Xd) / NULLIF(SUM(expenditure_amt_local_Xd), 0)` |

> 注：`Xd` 代表 `1d`、`7d`、`30d`、`60d`、`90d` 各时间窗口后缀。

此外，以下字段具有特殊口径含义，与其他 `_Xd` 字段不可混用：

| 字段 | 说明 |
|------|------|
| `paid_order_cnt_ytd_1d` | 仅为"昨日"当天的已付款订单数（YTD 快照口径），并非 1 天滚动窗口，不可与 `order_cnt_1d` 相加 |
| `confirmed_order_cnt_ytd_1d` | 仅为"昨日"当天的已确认订单数（YTD 快照口径），同上 |

### 时效性说明

- 本表每日调度一次，每个 `grass_date` 分区存储以该日为基准的**滚动窗口汇总值**（如 `_7d` 表示过去 7 天，`_90d` 表示过去 90 天）。
- 查询最新数据应取**最新 `grass_date` 分区**，即可获得截至昨日的各时间窗口累计值，无需再做跨分区聚合。
- 上游数据存在 D+1 延迟，`grass_date = T` 的数据实际反映 T 日（含）往前各窗口的汇总，T 日数据于 T+1 日调度完成后可用。
- `pricing_type = 29` 的广告数据在 ETL 中被过滤排除，查询结果不包含该类定价类型。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dws_advertise_performance_1d__reg_s0_live` | 每日广告绩效明细表（DWS 日粒度），提供各广告在单日的曝光、点击、订单、GMV、花费、广泛归因等原始汇总值；本表读取近 90 天历史分区并通过滚动窗口标记进行多时间窗口聚合 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dws_advertise_performance_1d__reg_s0_live
    │
    │  WHERE grass_region = '${region}'
    │    AND grass_date BETWEEN (T-89) AND T
    │    AND pricing_type != 29
    │
    ▼
[内层子查询] 滚动窗口标记
    │  - 按 grass_date 打标：is_today / is_7d / is_30d / is_60d / is_90d
    │  - placement=20 时将 ads_type 覆盖为 'shop_simple'
    │
    ▼
[中层聚合] GROUP BY (tz_type, ads_id, placement, ads_type, shop_id, seller_id)
    │  - SUM(CASE WHEN is_Xd=1 THEN metric ELSE 0) → metric_Xd
    │  - 输出各时间窗口的原始计数/金额字段
    │
    ▼
[外层 SELECT] 派生比率计算（COALESCE(分子/分母, 0.0)）
    │  - ctr_Xd = click_cnt_Xd / impression_cnt_Xd
    │  - cir_Xd = expenditure_amt_local_Xd / ads_gmv_amt_local_Xd
    │  - cr_Xd  = order_cnt_Xd / click_cnt_Xd
    │  - cpc_local_Xd = expenditure_amt_local_Xd / click_cnt_Xd
    │  - cpc_usd_Xd   = expenditure_amt_usd_Xd / click_cnt_Xd
    │  - roi_Xd       = ads_gmv_amt_local_Xd / expenditure_amt_local_Xd
    │  - broad_roi_Xd = broad_gmv_amt_local_Xd / expenditure_amt_local_Xd
    │
    ▼
INSERT OVERWRITE
mp_paidads.dws_advertise_performance_nd__reg_s0_live
PARTITION (tz_type, grass_region = upper('${region}'), grass_date = '${grass_date}')
```

### 关键 CTE 说明

本 ETL 无显式 CTE（`WITH` 子句），采用三层嵌套子查询实现：

| 层级 | 来源表 / 输入 | 作用 |
|------|-------------|------|
| 内层子查询（窗口标记层） | `dws_advertise_performance_1d__reg_s0_live` | 过滤地区、日期范围（近 90 天）及 `pricing_type!=29`；按 `grass_date` 与基准日期的差值打标 `is_today`、`is_7d`、`is_30d`、`is_60d`、`is_90d`；对 `placement=20` 修正 `ads_type='shop_simple'` |
| 中层聚合层 | 内层子查询输出 | 按广告维度 GROUP BY，通过 `SUM(CASE WHEN is_Xd=1 ...)` 汇聚各时间窗口的原始量值字段（曝光、点击、订单、GMV、花费等） |
| 外层计算层 | 中层聚合输出 | 在聚合结果基础上计算所有比率派生字段（CTR、CIR、CR、CPC、ROI、Broad ROI），使用 `COALESCE(分子/分母, 0.0)` 处理零分母 |

### 注意事项

1. **`pricing_type = 29` 被排除**：ETL 在内层子查询中过滤掉该定价类型的广告数据，下游分析若需全量广告数据需注意此缺口。

2. **`placement = 20` 的 `ads_type` 覆盖**：当 `placement = 20` 时，无论原始 `ads_type` 为何值，均被强制改写为 `'shop_simple'`。若按 `ads_type` 做下钻分析，需了解此逻辑。

3. **比率字段零分母处理**：所有比率字段在分母为 0 时统一返回 `0.0`（通过 `COALESCE`），而非 `NULL`。若业务需区分"无数据"与"真零值"，需结合分子字段判断。

4. **滚动窗口定义**：各时间窗口的范围定义如下，均含首尾两端：
   - `1d`：`grass_date = T`（仅当日）
   - `7d`：`[T-6, T]`（含今日共 7 天）
   - `30d`：`[T-29, T]`（含今日共 30 天）
   - `60d`：`[T-59, T]`（含今日共 60 天）
   - `90d`：`[T-89, T]`（含今日共 90 天）

5. **参数化调度**：`${region}` 和 `${grass_date}` 为调度模板参数，任务按各地区本地时区独立调度，覆盖所有上线地区。

6. **分区写入方式**：采用 `INSERT OVERWRITE ... PARTITION` 方式，每次调度覆盖写入对应 `(tz_type, grass_region, grass_date)` 分区，历史分区数据不受影响。

---

*文档生成时间：2026-04-22*
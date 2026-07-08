<!-- ads-workspace-gdoc-sync: gdoc_id=15uxayhrBfsR13akvysNUDszFZSquJ3Too7kWFmUnJe0 gdoc_url=https://docs.google.com/document/d/15uxayhrBfsR13akvysNUDszFZSquJ3Too7kWFmUnJe0/edit -->

# mp_paidads.dws_livestream_brand_portal_1d

**分层**：DWS（数据汇总层）
**主键**：`shop_id` + `campaign_id` + `campaign_type` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（D+1），各地区按本地时区参数化调度
**引用频次**：0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表为**直播广告品牌门户日粒度汇总宽表**，以广告系列（Campaign）为核心维度，将直播投放的曝光、转化、GMV 及广告花费等核心指标聚合至天级别，供品牌商家和广告运营团队通过 Brand Portal 等前台产品进行日常投放效果的监控与分析。

表中同时涵盖**大盘归因视角**（`gross_sales`）与**付费订单归因视角**（`paid_order_gmv`）两类 GMV 口径，并提供本地货币与 USD 双币种字段，满足跨地区横向对比的诉求。广告花费数据来自收入明细表，通过 `campaign_type`（即 `pricing_type`）进行精准关联，确保花费与转化归因口径一致。

本表是各地区直播广告品牌经营分析的核心宽表，典型使用场景包括：品牌日报/周报生成、ROAS 计算、直播广告漏斗分析（曝光 → 下单）以及各地区/广告活动的横向对比看板。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型，当前写入值固定为 `'local'`，即按各地区本地时区统计。⚠️ 每次查询**必须**指定 `tz_type = 'local'`，否则将触发全分区扫描。 |
| `grass_region` | string | 地区编码（大写），如 `'MX'`、`'ID'`、`'TH'` 等；各地区独立调度写入。⚠️ 必须指定，避免跨地区全扫。 |
| `grass_date` | date | 数据日期（本地时区），格式 `YYYY-MM-DD`。⚠️ 必须指定，避免全量扫描。 |

---

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺 ID，来源于 `dim_advertise` 维表，通过 `campaign_id` 关联补全；标识该广告系列归属的品牌店铺。 |
| `campaign_id` | bigint | 广告系列 ID，直播广告的核心维度键，过滤条件为 `placement = 3327`（直播位）。 |
| `campaign_type` | int | 广告计费类型，对应上游 `pricing_type`；用于关联广告花费时的精确匹配（`campaign_type = pricing_type`）。⚠️ 该字段为枚举型整数，直接聚合无业务意义，应作为维度过滤或分组使用。 |

---

### 指标：直播流量与转化

| 字段 | 类型 | 说明 |
|------|------|------|
| `views` | bigint | 直播广告曝光量（impression/view 数），来源于 `dwd_livestream_performance_di` 的 `view` 字段汇总。 |
| `orders` | bigint | 下单数（含宽口径归因），来源于 `dwd_livestream_performance_di` 的 `checkout` 字段汇总，代表通过直播广告引导的结算订单数。 |
| `paid_order_cnt` | bigint | 付费订单数（窄口径归因），仅统计实际完成支付的订单数量，与 `paid_order_gmv` 口径一致。 |

---

### 指标：大盘 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `gross_sales` | double | 大盘归因 GMV（本地货币），来源于 `dwd_livestream_performance_di` 的 `broad_gmv` 汇总，采用宽口径归因（含非付费订单）。⚠️ 与 `paid_order_gmv` 归因口径不同，两者不可混用；跨地区对比须使用 `gross_sales_usd`。 |
| `gross_sales_usd` | double | 大盘归因 GMV（USD），为 `gross_sales` 的美元换算值。⚠️ 汇率由上游 DWD 层处理，本表直接存储换算结果，跨日期分析时需注意汇率口径一致性。 |

---

### 指标：付费订单 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_order_gmv` | double | 付费订单 GMV（本地货币），仅统计实际完成支付订单的 GMV，口径窄于 `gross_sales`。⚠️ 跨地区对比须使用 `paid_order_gmv_usd`。 |
| `paid_order_gmv_usd` | double | 付费订单 GMV（USD），为 `paid_order_gmv` 的美元换算值。⚠️ 汇率由上游 DWD 层处理，跨日期分析时需注意汇率口径一致性。 |

---

### 指标：广告花费

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_spend` | double | 广告花费（本地货币），来源于 `dws_advertise_livestream_revenue_1d`，按 `campaign_id` + `pricing_type` 关联聚合。⚠️ 跨地区对比须使用 `ads_spend_usd`；如需计算 ROAS，应使用 `gross_sales / ads_spend` 或 `paid_order_gmv / ads_spend`，不可直接对 ROAS 做 SUM。 |
| `ads_spend_usd` | double | 广告花费（USD），为 `ads_spend` 的美元换算值。⚠️ 汇率由上游 DWD 层处理，跨日期分析时需注意汇率口径一致性。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下三个分区字段**，否则将触发全表分区扫描，导致查询超时或资源爆炸：

| 过滤字段 | 推荐写法 | 说明 |
|----------|----------|------|
| `tz_type` | `tz_type = 'local'` | 当前表仅写入 `'local'` 分区，遗漏该条件将扫描所有 tz_type 分区（即使其他分区为空，元数据扫描仍有开销）。 |
| `grass_region` | `grass_region = 'ID'`（按需替换） | 各地区独立写入，不指定将全量扫描所有地区。 |
| `grass_date` | `grass_date = '2026-04-21'` 或范围过滤 | 不指定将扫描全部历史分区，严禁省略。 |

**示例**：
```sql
SELECT campaign_id, SUM(views), SUM(orders), SUM(ads_spend_usd)
FROM mp_paidads.dws_livestream_brand_portal_1d
WHERE tz_type      = 'local'
  AND grass_region = 'ID'
  AND grass_date   = '2026-04-21'
GROUP BY campaign_id;
```

---

### 不可直接 SUM 的字段

| 字段 | 错误用法 | 正确计算方式 |
|------|----------|-------------|
| `campaign_type` | `SUM(campaign_type)` | 维度字段，仅用于 `GROUP BY` 或 `WHERE` 过滤，无聚合意义。 |
| ROAS（派生） | 对行级 ROAS 直接 SUM | 应先聚合分子分母再相除：`SUM(gross_sales_usd) / NULLIF(SUM(ads_spend_usd), 0)` |
| CVR（派生） | 对行级 CVR 直接 SUM | 应先聚合：`SUM(orders) / NULLIF(SUM(views), 0)` |
| `gross_sales` / `paid_order_gmv` | 跨地区直接 SUM 本地货币字段 | 跨地区聚合须使用 `_usd` 后缀字段（`gross_sales_usd`、`paid_order_gmv_usd`、`ads_spend_usd`）。 |

> **GMV 口径注意**：`gross_sales`（宽口径）与 `paid_order_gmv`（窄口径）归因逻辑不同，同一分析场景中**只能选用一种 GMV 口径**，不可相加或混用。

---

### 时效性说明

- 本表为每日 **D+1** 调度写入，`grass_date = T` 的数据最早在 T+1 调度完成后可用。
- 查询**昨日数据**时，应指定 `grass_date = CURRENT_DATE - 1`。
- 若调度出现延迟，建议通过调度元信息（`synced_at`）或数据质量监控确认最新可用分区后再查询。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dim_advertise__reg_s0_live` | 广告系列维表，提供 `campaign_id` → `shop_id` 的映射；过滤 `placement = 3327` 限定直播广告位 |
| `mp_paidads.dws_advertise_livestream_revenue_1d__reg_s0_live` | 直播广告收入/花费明细汇总表，提供各广告系列的本地货币及 USD 花费数据 |
| `mp_paidads.dwd_livestream_performance_di__reg_s0_live` | 直播广告绩效明细宽表（DWD 层），提供曝光（view）、下单（checkout）、宽口径 GMV（broad_gmv）、付费订单数及 GMV 等原始指标 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_livestream_performance_di__reg_s0_live
  (按 campaign_id + pricing_type 聚合曝光/转化/GMV)
              │
              │  LEFT JOIN on campaign_id
              ▼
mp_paidads.dim_advertise__reg_s0_live
  (placement=3327 过滤直播广告位，补全 shop_id)
              │
              │  LEFT JOIN on campaign_id + pricing_type
              ▼
mp_paidads.dws_advertise_livestream_revenue_1d__reg_s0_live
  (按 campaign_id + pricing_type 聚合广告花费)
              │
              ▼
dws_livestream_brand_portal_1d__reg_s0_live
  PARTITION (tz_type='local', grass_region, grass_date)
  [INSERT OVERWRITE，每日全量覆盖当日分区]
```

> 计算引擎：SparkSQL（Studio 调度任务），各地区通过 `${region}`、`${grass_date}`、`${timezone}` 参数化调度，结果以 Parquet 格式写入 Hive 外部表。

---

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `dim_advertise` | `mp_paidads.dim_advertise__reg_s0_live` | 过滤 `placement = 3327`（直播广告位），按 `campaign_id` + `shop_id` 去重，用于补全直播广告系列的归属店铺。 |
| `revenue` | `mp_paidads.dws_advertise_livestream_revenue_1d__reg_s0_live` | 按 `campaign_id` + `pricing_type` 聚合广告花费（本地货币及 USD），仅取 `tz_type = 'local'` 分区数据。 |
| 主查询（内联子查询 `a`） | `mp_paidads.dwd_livestream_performance_di__reg_s0_live` | 按 `campaign_id` + `pricing_type` 聚合直播广告的曝光、下单、宽口径 GMV、付费订单数及 GMV。 |

---

### 注意事项

1. **LEFT JOIN 导致花费/店铺可能为 NULL**：主查询以 `dwd_livestream_performance_di` 为驱动表，使用 LEFT JOIN 关联维表和花费表。若某 `campaign_id` 在 `dim_advertise` 中不存在（非直播位或维表缺失），则 `shop_id` 为 `NULL`；若花费表无对应记录，则 `ads_spend` / `ads_spend_usd` 为 `NULL`。查询时需注意 `NULL` 处理（如使用 `COALESCE`）。

2. **`placement = 3327` 限定直播广告位**：`dim_advertise` 维表通过 `placement = 3327` 过滤，确保本表仅汇总直播场景下的广告系列，其他广告位的 campaign 不会关联到 `shop_id`。

3. **花费关联使用双键**：`revenue` CTE 与主查询通过 `campaign_id AND campaign_type = pricing_type` 双键 JOIN，避免同一广告系列在不同计费模式下的花费错配，查询花费数据时须同时考虑 `campaign_type` 维度。

4. **INSERT OVERWRITE 全量覆盖**：每次调度对指定 `(tz_type, grass_region, grass_date)` 分区执行 INSERT OVERWRITE，数据为当日全量覆盖，无历史累计逻辑，不存在重复计算风险。

5. **GMV 双口径并存**：`gross_sales` 系列为宽口径（broad_gmv，含所有归因订单），`paid_order_gmv` 系列为窄口径（仅付费完成订单），两者数值差异可能较大，分析时须明确选定口径，避免混用。

6. **各地区参数化调度**：ETL SQL 中出现的具体地区代码和时区仅为调度模板的参数化实例，本表通过 `${region}`、`${grass_date}` 等变量覆盖所有上线地区，各地区按本地时区独立写入对应分区。

---

*文档生成时间：2026-04-22*
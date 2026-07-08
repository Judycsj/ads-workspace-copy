<!-- ads-workspace-gdoc-sync: gdoc_id=1sbFewMlokeXENGl_f7IFp6wNmex0-QNniMhrhOwsoR4 gdoc_url=https://docs.google.com/document/d/1sbFewMlokeXENGl_f7IFp6wNmex0-QNniMhrhOwsoR4/edit -->

# mp_paidads.dws_advertise_revenue_1d

**分层**：DWS（数据汇总层）
**主键**：`ads_id` + `campaign_id` + `shop_id` + `item_id` + `entrance` + `sub_entrance` + `placement` + `pricing_type` + `traffic_source` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日（T+1）
**引用频次**：10 次（候选表范围内）

---

## 业务描述

本表是广告营收日汇总宽表，按广告维度（广告 ID、广告活动、店铺、商品、入口、广告位、计价模式、流量来源等）对每日广告扣费金额进行汇总，同时将扣费细分为四种来源类型：付费额度（带/不带过期时间）与免费额度（带/不带过期时间），并提供本地货币与 USD 双币种口径，满足跨地区横向比较需求。

本表主要服务于广告营收分析、广告主投放效果追踪、广告入口/广告位结构分析等场景。分析师可通过本表快速获取指定地区、指定日期范围内各类广告的日级扣费分布，支撑广告业务的日常监控、周期性报表及归因分析。

本表通过 `tz_type`、`grass_region`、`grass_date` 三级分区管理数据，各地区按本地时区参数化调度，保证各市场数据口径与业务时区对齐。表中所有金额指标均已由源层原始计量单位（/ 100000.0）换算为标准货币单位，并经汇率表转换为 USD，可直接用于金额求和与报表输出。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `tz_type` | string | 时区类型分区。各地区按本地时区调度写入，当前写入值为 `'local'`。查询时**必须**指定此字段以避免全表扫描。 |
| `grass_region` | string | 地区分区，大写形式（如 `'MX'`、`'ID'`）。标识该行数据所属市场。查询时**必须**指定此字段。 |
| `grass_date` | date | 日期分区，格式 `YYYY-MM-DD`。对应广告扣费记录所属的业务日期（本地时区）。查询时**必须**指定此字段或范围过滤。 |

### 维度：主键与广告属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `ads_id` | bigint | 广告 ID，唯一标识一条广告投放记录。 |
| `campaign_id` | bigint | 广告活动 ID，标识广告所属的推广计划。 |
| `shop_id` | bigint | 店铺 ID，标识投放该广告的商家店铺。 |
| `item_id` | bigint | 广告扣费关联的商品 ID，唯一标识被推广商品。 |
| `entrance` | int | 广告入口枚举值，标识广告流量的一级来源入口（如首页、搜索等）。枚举定义参见 [beeshop_ads.proto#L3177](https://git.garena.com/beetalk-server-deprecated/beeshop_common/-/blob/master/protocol/beeshop_ads.proto#L3177)。 |
| `sub_entrance` | int | 次级广告入口，是 `entrance` 的二级细分，主要应用于 DD 和搜索流量场景。 |
| `placement` | bigint | 广告位枚举值，标识广告展示的具体位置。枚举定义参见 [beeshop_ads.proto#L148](https://git.garena.com/beetalk-server-deprecated/beeshop_common/-/blob/master/protocol/beeshop_ads.proto#L148)。 |
| `pricing_type` | int | 广告计价模式枚举值（如 CPC、CPM 等）。枚举定义参见 [beeshop_ads.proto#L269](https://git.garena.com/beetalk-server-deprecated/beeshop_common/-/blob/master/protocol/beeshop_ads.proto#L269)。 |
| `traffic_source` | int | 流量来源类型（如 org、roi1、roi2 等），标识广告流量的组织来源。 |

### 指标：广告扣费总额

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `total_expenditure_amt_local_1d` | double | 当日广告总扣费金额，本地货币单位。源自 DWD 层 `expenditure_amt_local` 直接汇总，已换算为标准货币单位（原始值 / 100000.0 在 DWD 层处理）。 |
| `total_expenditure_amt_usd_1d` | double | 当日广告总扣费金额，USD。由 `total_expenditure_amt_local_1d` 除以当日汇率计算所得。⚠️ 为派生换算字段，跨地区汇总时应使用各地区原始 local 金额分别换算后再加总，避免因汇率差异导致误差。 |

### 指标：付费额度扣费（不带过期时间）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `paid_expenditure_wo_expiry_amt_local_1d` | double | 当日从"付费且无过期时间额度"中扣除的广告费用，本地货币单位。原始值经 / 100000.0 换算。 |
| `paid_expenditure_wo_expiry_amt_usd_1d` | double | 当日从"付费且无过期时间额度"中扣除的广告费用，USD。由对应 local 字段除以当日汇率计算所得。⚠️ 为派生换算字段，跨地区汇总请使用 local 金额重新换算。 |

### 指标：付费额度扣费（带过期时间）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `paid_expenditure_w_expiry_amt_local_1d` | double | 当日从"付费且带过期时间额度"中扣除的广告费用，本地货币单位。原始值经 / 100000.0 换算。 |
| `paid_expenditure_w_expiry_amt_usd_1d` | double | 当日从"付费且带过期时间额度"中扣除的广告费用，USD。由对应 local 字段除以当日汇率计算所得。⚠️ 为派生换算字段，跨地区汇总请使用 local 金额重新换算。 |

### 指标：免费额度扣费（不带过期时间）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `free_expenditure_wo_expiry_amt_local_1d` | double | 当日从"免费且无过期时间额度"中扣除的广告费用，本地货币单位。原始值经 / 100000.0 换算。 |
| `free_expenditure_wo_expiry_amt_usd_1d` | double | 当日从"免费且无过期时间额度"中扣除的广告费用，USD。由对应 local 字段除以当日汇率计算所得。⚠️ 为派生换算字段，跨地区汇总请使用 local 金额重新换算。 |

### 指标：免费额度扣费（带过期时间）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `free_expenditure_w_expiry_amt_local_1d` | double | 当日从"免费且带过期时间额度"中扣除的广告费用，本地货币单位。原始值经 / 100000.0 换算。 |
| `free_expenditure_w_expiry_amt_usd_1d` | double | 当日从"免费且带过期时间额度"中扣除的广告费用，USD。由对应 local 字段除以当日汇率计算所得。⚠️ 为派生换算字段，跨地区汇总请使用 local 金额重新换算。 |

> **额度类型说明**：四类扣费之和理论上等于 `total_expenditure_amt_local_1d`，即：
> `paid_wo_expiry + paid_w_expiry + free_wo_expiry + free_w_expiry = total`。
> 可利用此关系做数据质量校验。

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**同时指定以下三个分区字段，否则将触发全表扫描，导致资源浪费和查询超时：

| 过滤字段 | 推荐写法 | 说明 |
|----------|----------|------|
| `tz_type` | `tz_type = 'local'` | 当前只有 `'local'` 分区写入数据，遗漏此过滤会读取所有 tz_type 分区。 |
| `grass_region` | `grass_region = 'XX'`（大写） | 需指定目标市场的大写地区代码，遗漏将扫描所有地区数据。 |
| `grass_date` | `grass_date = '2024-01-01'` 或范围过滤 | 日期分区，遗漏将导致全历史数据扫描。 |

**示例过滤写法**：
```sql
WHERE tz_type = 'local'
  AND grass_region = 'ID'
  AND grass_date = '2024-01-01'
```

### 不可直接 SUM 的字段

| 字段 | 问题描述 | 正确处理方式 |
|------|----------|-------------|
| `total_expenditure_amt_usd_1d` | 由 local 金额除以各地区当日汇率派生，**不同地区汇率不同**，跨地区直接 SUM 结果有偏差 | 跨地区汇总时，应以 `total_expenditure_amt_local_1d` 为基础，统一使用同一汇率重新换算后再加总；或在同一地区内部 SUM |
| `paid_expenditure_wo_expiry_amt_usd_1d` | 同上，为 local 金额除以汇率的派生值 | 同上 |
| `paid_expenditure_w_expiry_amt_usd_1d` | 同上 | 同上 |
| `free_expenditure_wo_expiry_amt_usd_1d` | 同上 | 同上 |
| `free_expenditure_w_expiry_amt_usd_1d` | 同上 | 同上 |

> **注意**：本地货币金额字段（`*_amt_local_1d`）在同一 `grass_region` 内可直接 SUM；跨地区聚合本地货币金额无业务意义，请勿混合 SUM。

### 时效性说明

- 本表为 **T+1** 更新，`grass_date = CURRENT_DATE - 1` 的分区在每日调度完成后可用。
- 查询"昨日"数据时，请使用 `grass_date = DATE_SUB(CURRENT_DATE, 1)` 而非 `CURRENT_DATE`，避免读取到未完成写入的当日分区（可能为空或不完整）。
- 若需查询最新可用分区，建议先执行 `SHOW PARTITIONS` 确认最新 `grass_date` 后再查询。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告绩效明细事实表，提供每条广告的日级扣费明细（含各类额度分类金额，原始值单位为 1/100000 货币单位），经 GROUP BY 汇总后作为本表的核心事实来源 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供各地区当日本地货币对 USD 的汇率，用于将本地货币金额换算为 USD |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_advertise_performance_di__reg_s0_live
  │  WHERE grass_region = ${upper_region}
  │        AND grass_date = ${grass_date}
  │        AND expenditure_amt_local > 0
  │  GROUP BY ads_id, placement, shop_id, campaign_id,
  │           item_id, entrance, pricing_type,
  │           sub_entrance, traffic_source, grass_region
  │  sum(expense_*_credit_*) / 100000.0  →  local金额
  │  sum(expenditure_amt_local)          →  total local金额
  ↓
  [子查询 a：广告扣费汇总，本地货币]
        │
        │  LEFT JOIN（MAPJOIN hint，广播小表）
        ↓
mp_order.dim_exchange_rate__reg_s0_live
  │  WHERE grass_region = ${upper_region}
  │        AND grass_date = ${grass_date}
  ↓
  [exrate：当日地区汇率]
        │
        │  local金额 / exchange_rate  →  USD金额
        ↓
dws_advertise_revenue_1d__reg_s0_live
  partition(tz_type='local', grass_region=${upper_region}, grass_date=${grass_date})
  [INSERT OVERWRITE，每日全量覆盖当日分区]
```

### 关键 CTE 说明

本 ETL 无显式 CTE，使用内联子查询实现中间逻辑：

| 子查询别名 | 来源表 | 作用 |
|------------|--------|------|
| `a` | `dwd_advertise_performance_di__reg_s0_live` | 按广告维度聚合当日扣费明细，将原始计量单位（×1/100000）转换为标准货币单位，产出四类额度的本地货币金额及总扣费 |
| `exrate` | `dim_exchange_rate__reg_s0_live` | 获取当日地区汇率，以 MAPJOIN（广播 JOIN）方式与汇总结果关联，用于换算 USD 金额 |

### 注意事项

1. **原始金额单位**：DWD 层中 `expense_*_credit_*` 字段的原始值单位为 **1/100000 货币单位**，ETL 中通过 `/ 100000.0` 换算为标准货币单位后写入本表。本表中的 local 金额字段已是标准货币单位，无需再次换算。

2. **过滤条件 `expenditure_amt_local > 0`**：ETL 在源层过滤了无扣费记录（扣费为 0 或负数的行不进入本表），因此本表仅包含实际产生扣费的广告记录，**不代表全量广告投放数据**。如需分析零扣费或负扣费场景，需回溯至 DWD 层。

3. **MAPJOIN 提示**：汇率表 `exrate` 数据量小，ETL 使用 `/*+ MAPJOIN(exrate) */` 将其广播至各 Mapper，避免大表 JOIN 的 Shuffle 开销。

4. **LEFT JOIN 汇率**：汇率表使用 LEFT JOIN，若某地区当日汇率数据缺失，对应行的 USD 金额字段将为 `NULL`，不会导致数据丢失但会影响 USD 口径统计，需关注汇率表数据完整性。

5. **分区写入策略**：ETL 使用 `INSERT OVERWRITE` 覆盖当日分区，支持幂等重跑。如需重跑历史分区，直接重新触发对应日期的调度任务即可，不会影响其他日期分区。

6. **双表结构**：ETL 同时维护两张外表：`dws_advertise_revenue_1d__reg_s0_live`（三级分区：tz_type + grass_region + grass_date，用于跨地区统一查询）和 `dws_advertise_revenue_1d__${region}_s0_live`（单分区：grass_date，location 指向对应地区子路径，用于地区级访问）。两者共享同一底层 Parquet 数据文件，数据完全一致。

---

*文档生成时间：2026-04-22*
<!-- ads-workspace-gdoc-sync: gdoc_id=1WJvtz5jIe9pUhizegjvIyhD7cjtFDom0HzqNBbu9MdI gdoc_url=https://docs.google.com/document/d/1WJvtz5jIe9pUhizegjvIyhD7cjtFDom0HzqNBbu9MdI/edit -->

# mp_paidads.dws_advertiser_livestream_revenue_td

**分层**：DWS（数据服务层 / 汇总宽表）
**主键**：`shop_id` + `streamer_id` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1 滚动累计写入）
**引用频次**：7 次（候选表范围内）

---

## 业务描述

本表记录各地区**广告主直播带货**维度下的**历史累计（To-Date）广告支出**数据，以店铺（`shop_id`）和主播（`streamer_id`）为粒度，按本地时区参数化调度覆盖所有上线地区。每日调度时，将前一日的累计值与当日的日增量（来自 `dws_advertiser_livestream_revenue_1d`）做全量合并，输出截至 `grass_date` 的滚动累计指标。

表中支出指标按**资金性质**（付费 vs 免费赠送）和**是否含过期余额**（w_expiry / wo_expiry）两个维度细分，同时提供本币（local）和美元（usd）两套口径，便于跨地区汇总分析与本地化财务核算。此外，表还沉淀了主播首次 / 最近一次参与直播广告投放的日期，可用于主播活跃度分析、分层运营及漏斗追踪。

典型使用场景包括：计算各市场广告主在特定历史时间截点的累计广告消耗、分析主播广告变现能力的长期趋势、评估付费与免费资源的分配结构，以及为 ROAS / ROI 类报表提供支出侧的基础数据。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型，标识数据所使用的时间基准。当前写入分区固定为 `'local'`，代表各地区按本地时区统计。查询时**必须**指定此字段以避免全表扫描。 |
| `grass_region` | string | 地区代码（大写），如 `'US'`、`'GB'` 等。通过 `${region}` 参数化调度，覆盖所有上线地区。 |
| `grass_date` | date | 数据日期（本地时区），表示累计指标的截止日期（含当日）。 |

### 维度：主键与主播属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 广告主店铺 ID，与 `streamer_id` 共同构成业务主键。 |
| `streamer_id` | bigint | 直播主播 ID，标识具体的主播账号。 |
| `streamer_type` | int | 主播类型编码，区分自播、达人等不同主播身份类型。 |
| `streamer_first_live_ads_date` | string | 该主播在本店铺下**首次**参与直播广告投放的日期（格式：`YYYY-MM-DD`）。由累计逻辑保留历史最早值（`COALESCE(b.streamer_first_live_ads_date, '${grass_date}')`），即首次出现时用当日日期初始化，后续保持不变。⚠️ 为字符串类型，日期比较需显式转换（`CAST(... AS DATE)`），且该字段不随数据回刷自动修正，历史补数时需注意口径一致性。 |
| `streamer_last_live_ads_date` | string | 该主播在本店铺下**最近一次**有直播广告消耗的日期（格式：`YYYY-MM-DD`）。每日由当日日增数据覆盖更新（`COALESCE(a.streamer_last_live_ads_date, b.streamer_last_live_ads_date)`），若当日无消耗则沿用历史值。⚠️ 为字符串类型，日期比较需显式转换；该值反映的是最后一次**有消耗**的日期，不等于最近调度日期。 |

### 指标：总广告支出（累计）

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_expenditure_amt_local_td` | double | 截至 `grass_date` 的**累计总广告支出**（本地货币）。包含付费与免费、含过期与不含过期的全部支出。⚠️ 为滚动累计值，跨分区直接 SUM 会造成重复计算，应仅取所需截止日期分区的值。 |
| `total_expenditure_amt_usd_td` | double | 截至 `grass_date` 的**累计总广告支出**（美元）。⚠️ 同上，为滚动累计值，不可跨分区 SUM。 |

### 指标：付费支出——不含过期余额（累计）

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_expenditure_wo_expiry_amt_local_td` | double | 截至 `grass_date` 的付费广告支出中**不含过期余额**部分（本地货币）。⚠️ 为滚动累计值，不可跨分区 SUM。 |
| `paid_expenditure_wo_expiry_amt_usd_td` | double | 截至 `grass_date` 的付费广告支出中**不含过期余额**部分（美元）。⚠️ 为滚动累计值，不可跨分区 SUM。 |

### 指标：付费支出——含过期余额（累计）

| 字段 | 类型 | 说明 |
|------|------|------|
| `paid_expenditure_w_expiry_amt_local_td` | double | 截至 `grass_date` 的付费广告支出中**含过期余额**部分（本地货币）。⚠️ 为滚动累计值，不可跨分区 SUM。 |
| `paid_expenditure_w_expiry_amt_usd_td` | double | 截至 `grass_date` 的付费广告支出中**含过期余额**部分（美元）。⚠️ 为滚动累计值，不可跨分区 SUM。 |

### 指标：免费支出——不含过期余额（累计）

| 字段 | 类型 | 说明 |
|------|------|------|
| `free_expenditure_wo_expiry_amt_local_td` | double | 截至 `grass_date` 的免费广告资源消耗中**不含过期余额**部分（本地货币）。⚠️ 为滚动累计值，不可跨分区 SUM。 |
| `free_expenditure_wo_expiry_amt_usd_td` | double | 截至 `grass_date` 的免费广告资源消耗中**不含过期余额**部分（美元）。⚠️ 为滚动累计值，不可跨分区 SUM。 |

### 指标：免费支出——含过期余额（累计）

| 字段 | 类型 | 说明 |
|------|------|------|
| `free_expenditure_w_expiry_amt_local_td` | double | 截至 `grass_date` 的免费广告资源消耗中**含过期余额**部分（本地货币）。⚠️ 为滚动累计值，不可跨分区 SUM。 |
| `free_expenditure_w_expiry_amt_usd_td` | double | 截至 `grass_date` 的免费广告资源消耗中**含过期余额**部分（美元）。⚠️ 为滚动累计值，不可跨分区 SUM。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，否则将触发全分区扫描，造成性能浪费甚至查询超时：

| 分区字段 | 推荐写法 | 说明 |
|----------|----------|------|
| `tz_type` | `tz_type = 'local'` | 当前仅写入 `local` 分区，不指定会扫描所有 tz_type 分区 |
| `grass_region` | `grass_region = 'US'`（按需替换） | 大写地区代码，不指定会跨地区全量扫描 |
| `grass_date` | `grass_date = '2026-04-21'` | 指定所需截止日期，不指定会读取所有历史分区数据 |

> ⚠️ 遗漏任意一个分区条件均可能导致读取成倍增加的数据量，在多地区、长历史周期场景下尤为严重。

### 不可直接 SUM 的字段

本表所有 `_td` 后缀指标字段均为**滚动历史累计值**，每个分区存储的是"截至该日期"的总量，而非当日增量。

| 错误用法 | 正确用法 |
|----------|----------|
| `SUM(total_expenditure_amt_usd_td)` 跨多个 `grass_date` | 仅取单一目标日期分区，直接读取该值或按 `shop_id`/`streamer_id` 聚合 |
| 跨地区 `SUM(total_expenditure_amt_local_td)` | 本币口径不可跨地区汇总；跨地区汇总应使用 `_usd_td` 字段并仅取同一 `grass_date` 分区 |

如需计算**某日的单日增量**，请从上游日表 `dws_advertiser_livestream_revenue_1d` 直接获取，或用 `grass_date = T` 的 td 值减去 `grass_date = T-1` 的 td 值（需分两次查询）。

`w_expiry` 与 `wo_expiry` 的关系说明：
- `wo_expiry`（不含过期）：仅计算有效期内的余额消耗，口径更严格
- `w_expiry`（含过期）：包含已过期余额的消耗，数值 ≥ `wo_expiry`
- 两者均不可与 `total_expenditure` 混合计算，需根据业务口径明确选取

### 时效性说明

本表为 **To-Date（历史累计）** 类型表，每日 T+1 调度更新，`grass_date` 分区对应的是本地时区下的数据截止日期。

- 获取**最新累计数据**：查询最新的 `grass_date` 分区（即昨日日期）
- ETL 逻辑中，当日数据从 `dws_advertiser_livestream_revenue_1d` 读取当日增量，与前一日 td 表（`grass_date = T-1`）做 FULL JOIN 累加后写入 `grass_date = T` 分区
- 若当日某 `streamer_id` 无新消耗，其历史累计值仍会从 `T-1` 分区延续写入 `T` 分区，保证数据连续性

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dws_advertiser_livestream_revenue_1d__reg_s0_live` | 提供当日（`grass_date`）直播广告各项支出的日增量指标，作为 FULL JOIN 的左表 |
| `mp_paidads.dws_advertiser_livestream_revenue_td__reg_s0_live`（自身前一日分区） | 提供截至 `grass_date - 1` 的历史累计值，作为 FULL JOIN 的右表，实现滚动累计 |

---

## ETL 逻辑摘要

### 数据流

```
┌─────────────────────────────────────────────────────┐
│  mp_paidads.dws_advertiser_livestream_revenue_1d    │
│  (当日日增量, grass_date = T, tz_type='local')       │
│  CTE: base_data_local                               │
└───────────────────────┬─────────────────────────────┘
                        │ FULL JOIN ON shop_id
                        │ (+ streamer_id 隐式)
┌───────────────────────┼─────────────────────────────┐
│  mp_paidads.dws_advertiser_livestream_revenue_td    │
│  (历史累计值, grass_date = T-1, tz_type='local')     │
│  CTE: revenue_td                                    │
└───────────────────────┼─────────────────────────────┘
                        │
                        ▼
              COALESCE 合并 + 累加
              (当日增量 + 历史累计)
                        │
                        ▼
┌─────────────────────────────────────────────────────┐
│  dws_advertiser_livestream_revenue_td               │
│  (写入 grass_date = T, tz_type='local' 分区)         │
│  INSERT OVERWRITE                                   │
└─────────────────────────────────────────────────────┘
```

> 调度引擎：Spark SQL（Hive External Table，存储格式 PARQUET）
> 写入方式：`INSERT OVERWRITE` 覆盖当日分区，同时通过 `ALTER TABLE ADD PARTITION` 注册 region 视图分区

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `base_data_local` | `dws_advertiser_livestream_revenue_1d__reg_s0_live` | 读取当日（`grass_date = T`）各 shop_id + streamer_id 的直播广告日增量指标，并将当日日期作为 `streamer_last_live_ads_date` |
| `revenue_td` | `dws_advertiser_livestream_revenue_td__reg_s0_live`（自身） | 读取前一日（`grass_date = T-1`）的历史累计值，用于与当日增量叠加，同时携带 `streamer_first_live_ads_date` 历史记录 |

### 注意事项

1. **自引用累计逻辑**：本表通过读取自身前一日分区实现滚动累计，这意味着若历史某天分区数据异常（缺失或错误），会导致后续所有分区的累计值连锁错误，**回刷数据时必须从最早错误日期起逐日顺序重跑**，不可跳跃重跑。

2. **FULL JOIN 口径**：ETL 以 `shop_id` 为关联键做 FULL JOIN，若当日某 `streamer_id` 仅出现在历史 td 表而当日无消耗，其记录仍会被保留写入新分区（累计值不变），保证历史主播不丢失；若某 `streamer_id` 为当日首次出现，其历史累计为 0（`COALESCE(... , 0)` 补零）。

3. **`streamer_first_live_ads_date` 初始化时机**：首次写入时取 `${grass_date}`（当日日期），后续由右表（td 历史分区）的该字段保留，实现"首次出现日期不变"的语义。若在首次出现日之前存在历史补数场景，该字段无法自动回溯修正。

4. **`w_expiry` vs `wo_expiry` 的口径选择**：`w_expiry` 含已过期余额，`wo_expiry` 仅含有效余额消耗。用于 ROI / ROAS 计算时建议明确业务口径，避免混用导致分子分母不一致。

5. **分区注册机制**：ETL 结尾通过 `ALTER TABLE ... ADD PARTITION` 为 region 视图表（`__${region}_s0_live`）注册当日分区，使其直接映射到主表的 `tz_type=local/grass_region=${upper_region}` 路径，两张表物理存储共享同一 HDFS 路径。

6. **各地区按本地时区参数化调度**：`${region}`、`${grass_date}`、`${timezone}` 均为调度模板参数，各地区独立调度，`grass_date` 以各地区本地时区日期为准。

---

*文档生成时间：2026-04-22*
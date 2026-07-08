<!-- ads-workspace-gdoc-sync: gdoc_id=139JKNMqe0nx_2JPpuv15xv9Zp5tJ_qHK20Qe98FPlpc gdoc_url=https://docs.google.com/document/d/139JKNMqe0nx_2JPpuv15xv9Zp5tJ_qHK20Qe98FPlpc/edit -->

# mp_paidads.dws_advertiser_topup_td

**分层**：DWS（数据服务层 / 宽表汇总层）
**主键**：`shop_id` + `seller_id` + `grass_region` + `tz_type`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1）
**引用频次**：0（末端 ADS 层表，未被其他候选表直接引用）

---

## 业务描述

本表是广告主充值行为的**截至今日（To-Date）累计宽表**，以广告主（`seller_id` + `shop_id`）为粒度，汇总其在各地区、各时区下的历史累计充值金额与次数，覆盖手动充值、自动充值、Normal 充值、SRM 触发充值（QSS 及 Seller Mission）、负向充值等全部充值类型，同时记录各类充值的首次/最近发生时间戳。

本表的核心价值在于**免除下游每次查询都需从明细流水表累加历史数据的成本**。通过"昨日快照 + 当日增量 FULL OUTER JOIN"的渐进式累计模式，每日仅处理增量数据即可维护完整的历史累积视图，适用于广告主生命周期分析、充值行为分层、用户价值评估（LTV）以及运营报表等场景。

各地区按本地时区参数化调度，`tz_type` 字段用于区分同一日历日期下不同时区口径的数据，下游查询时需明确指定，以确保数据口径一致。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `tz_type` | string | 时区类型分区键，区分本地时区（`local`）与 UTC 时区（`utc`）口径。⚠️ 查询时必须指定，不同 `tz_type` 下的数据重叠，混用将导致重复计算 |
| `grass_region` | string | 国家/地区分区键，存储为大写地区代码（如 `MY`、`TH`、`VN` 等），各地区独立调度写入 |
| `grass_date` | date | 日期分区键，表示该行数据所属的截至日期（即累计截止到该日期） |

### 维度：主键与广告主属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `shop_id` | bigint | 店铺 ID，广告主所关联的店铺唯一标识 |
| `seller_id` | bigint | 广告主 ID（卖家 ID），与 `shop_id` 共同构成本表业务主键 |

### 指标：综合充值汇总

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `total_topup_amt` | double | 截至今日的充值总金额（本地货币）。⚠️ 为 TD 累计值，跨日期分区直接 SUM 会重复计算，应仅取所需日期分区的单行值 |
| `total_topup_amt_usd` | double | 截至今日的充值总金额（USD）。⚠️ 同上，为 TD 累计值，不可跨日期分区 SUM |
| `topup_times_cnt` | bigint | 截至今日的充值总次数（含自动、手动及 Normal）。⚠️ 为 TD 累计值，不可跨日期分区 SUM |
| `neg_topup_amt` | double | 截至今日的负向充值金额（本地货币），表示退款或冲销类扣减金额。⚠️ 为 TD 累计值，不可跨日期分区 SUM |
| `neg_topup_amt_usd` | double | 截至今日的负向充值金额（USD）。⚠️ 为 TD 累计值，不可跨日期分区 SUM |

### 指标：手动充值（order_type = 3）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `manual_topup_amt` | double | 截至今日手动充值总金额（本地货币，`order_type = 3`）。⚠️ 为 TD 累计值，不可跨日期分区 SUM |
| `manual_topup_amt_usd` | double | 截至今日手动充值总金额（USD，`order_type = 3`）。⚠️ 为 TD 累计值，不可跨日期分区 SUM |
| `manual_topup_times_cnt` | bigint | 截至今日手动充值总次数。⚠️ 为 TD 累计值，不可跨日期分区 SUM |
| `first_manual_topup_timestamp` | bigint | 广告主首次手动充值的 Unix 时间戳（毫秒或秒，需结合业务确认精度）。⚠️ 使用 COALESCE 优先取历史快照值，保证首次时间不被覆盖 |
| `last_manual_topup_timestamp` | bigint | 广告主最近一次手动充值的 Unix 时间戳。⚠️ 使用 COALESCE 优先取当日增量值，保证最新时间及时更新 |

### 指标：自动充值（order_type = 4）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `auto_topup_amt_local` | double | 截至今日自动充值总金额（本地货币，`order_type = 4`）。⚠️ 为 TD 累计值，不可跨日期分区 SUM |
| `auto_topup_amt_usd` | double | 截至今日自动充值总金额（USD，`order_type = 4`）。⚠️ 为 TD 累计值，不可跨日期分区 SUM |
| `auto_topup_times_cnt` | bigint | 截至今日自动充值总次数。⚠️ 为 TD 累计值，不可跨日期分区 SUM |
| `first_auto_topup_timestamp` | bigint | 广告主首次自动充值的 Unix 时间戳。⚠️ COALESCE 优先取历史快照值 |
| `last_auto_topup_timestamp` | bigint | 广告主最近一次自动充值的 Unix 时间戳。⚠️ COALESCE 优先取当日增量值 |

### 指标：Normal 充值（order_type in (2, 6)）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `normal_amt_local` | double | 截至今日 Normal 充值总金额（本地货币，`order_type IN (2, 6)`）。⚠️ 为 TD 累计值，不可跨日期分区 SUM |
| `normal_amt_usd` | double | 截至今日 Normal 充值总金额（USD，`order_type IN (2, 6)`）。⚠️ 为 TD 累计值，不可跨日期分区 SUM |
| `normal_topup_times_cnt` | bigint | 截至今日 Normal 充值总次数。⚠️ 为 TD 累计值，不可跨日期分区 SUM |
| `first_normal_topup_timestamp` | bigint | 广告主首次 Normal 充值的 Unix 时间戳。⚠️ COALESCE 优先取历史快照值 |
| `last_normal_topup_timestamp` | bigint | 广告主最近一次 Normal 充值的 Unix 时间戳。⚠️ COALESCE 优先取当日增量值 |

### 指标：SRM 触发的 QSS 充值

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `srm_topup_amt` | double | 截至今日 SRM 系统（Seller Relationship Management）触发的 QSS（Quick Sales Solution）充值总金额（本地货币）。⚠️ 为 TD 累计值，不可跨日期分区 SUM |
| `srm_topup_amt_usd` | double | 截至今日 SRM 触发 QSS 充值总金额（USD）。⚠️ 为 TD 累计值，不可跨日期分区 SUM |
| `srm_topup_times_cnt` | bigint | 截至今日 SRM 充值总次数。⚠️ 为 TD 累计值，不可跨日期分区 SUM |

### 指标：SRM 触发的 Seller Mission 充值（order_type = 8）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `seller_mission_topup_amt` | double | 截至今日 SRM 系统触发的 Seller Mission 充值总金额（本地货币，`order_type = 8`）。⚠️ 为 TD 累计值，不可跨日期分区 SUM |
| `seller_mission_topup_amt_usd` | double | 截至今日 SRM 触发 Seller Mission 充值总金额（USD，`order_type = 8`）。⚠️ 为 TD 累计值，不可跨日期分区 SUM |

### 指标：全类型充值首次/最近时间戳

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `first_topup_timestamp` | bigint | 广告主首次发生任意类型充值的 Unix 时间戳。⚠️ COALESCE 优先取历史快照值（`b.first_topup_timestamp`），确保首次时间不被当日值覆盖 |
| `last_topup_timestamp` | bigint | 广告主最近一次发生任意类型充值的 Unix 时间戳。⚠️ COALESCE 优先取当日增量值（`a.last_topup_timestamp`），确保最新时间及时更新 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下三个分区字段**，否则将触发全表扫描，消耗大量计算资源并可能返回错误的重复数据：

| 分区字段 | 推荐写法示例 | 遗漏后果 |
|----------|-------------|----------|
| `grass_date` | `grass_date = '2026-04-21'` | 扫描所有历史分区，返回全部历史累计快照，数据量成倍膨胀 |
| `grass_region` | `grass_region = 'MY'` | 扫描所有地区分区，数据重复 |
| `tz_type` | `tz_type = 'local'` | 同一广告主在 `local` 与 `utc` 口径下各存一行，不过滤将导致金额/次数翻倍 |

> **强烈建议**：业务报表场景优先使用 `tz_type = 'local'`，以确保与本地运营口径对齐。

### 不可直接 SUM 的字段

本表所有金额与次数字段均为**截至指定日期的历史累计值（TD，To-Date）**，存在以下使用限制：

1. **不可跨日期分区聚合**：对同一广告主在不同 `grass_date` 分区上 SUM 会导致累计值被重复叠加。正确做法是**固定单个 `grass_date` 分区**查询，即可得到截至该日的累计值。

2. **计算区间增量时需做差值**：若需计算某段时间内的充值增量，应取区间结束日期分区值减去区间开始前一日分区值，例如：
   ```sql
   -- 计算某广告主 4 月份充值金额增量
   SELECT 
     t1.total_topup_amt - t0.total_topup_amt AS april_topup_amt
   FROM (SELECT ... WHERE grass_date = '2026-04-30') t1
   JOIN (SELECT ... WHERE grass_date = '2026-03-31') t0
     ON t1.shop_id = t0.shop_id AND t1.seller_id = t0.seller_id
        AND t1.grass_region = t0.grass_region AND t1.tz_type = t0.tz_type
   ```

3. **时间戳字段不可聚合**：`first_*_timestamp`、`last_*_timestamp` 均为业务语义时间点，不应 SUM，跨广告主比较时应使用 MIN/MAX。

### 时效性说明

本表为 **TD（To-Date）累计快照表**，每个 `grass_date` 分区存储截至该日期的历史累积全量数据。

- **最新数据**：取当前日期 T-1 的分区（即昨日），因为 ETL 在 T 日调度时读取 T 日的日增量（来自 `dws_advertiser_topup_1d`）与 T-1 日的 TD 快照合并后写入 T 日分区。
- **历史对比**：可按需取任意历史日期分区，各分区数据独立完整，无需与其他分区联合即可获得完整的截至当日累计视图。
- **当日实时性**：本表为离线每日批量更新，不反映当日盘中实时充值数据。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dws_advertiser_topup_1d__reg_s0_live` | 日增量表，提供当日（`grass_date`）各广告主的充值金额、次数及时间戳增量数据（子查询 `a`） |
| `mp_paidads.dws_advertiser_topup_td__reg_s0_live`（自身前一日分区） | T-1 日的历史累计快照，作为"昨日基准"参与 FULL OUTER JOIN，实现渐进式累计（子查询 `b`） |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dws_advertiser_topup_1d__reg_s0_live
  (当日增量, grass_date = ${grass_date})
           │
           │  (子查询 a)
           ▼
     FULL OUTER JOIN ──────────────────────────────────────────────────────►  dws_advertiser_topup_td__reg_s0_live
           ▲                                                                    PARTITION(tz_type, grass_region,
           │  (子查询 b)                                                                  grass_date=${grass_date})
           │
mp_paidads.dws_advertiser_topup_td__reg_s0_live
  (前日 TD 快照, grass_date = ${grass_date} - 1)
```

**JOIN Key**：`shop_id` + `region` + `seller_id`（使用 `<=>` NULL 安全等值） + `tz_type`

**合并策略**：
- **金额 / 次数字段**：`COALESCE(a.x, 0) + COALESCE(b.x, 0)`，当日增量与历史累计直接相加
- **首次时间戳**（`first_*`）：`COALESCE(b.value, a.value)`，优先取历史快照值，保证首次时间不被新数据覆盖
- **最近时间戳**（`last_*`）：`COALESCE(a.value, b.value)`，优先取当日增量值，保证最新时间及时刷新

### 注意事项

1. **渐进式自引用累计**：本表 ETL 采用"日增量 + 前日快照 FULL OUTER JOIN"的渐进累计模式。若某日调度失败导致 T-1 分区缺失，则 T 日的累计数据将仅含当日增量，**历史累计将断链**，需人工补数后重跑以恢复正确性。

2. **MAPJOIN 提示**：SQL 中对子查询 `b`（前日快照）使用了 `/*+ MAPJOIN(b) */` 提示，要求前日快照能装入 Mapper 内存。若某地区广告主规模持续增长导致前日快照过大，可能引发 OOM，需关注并适时调整 Join 策略。

3. **NULL 安全 JOIN**：`seller_id` 字段使用 `<=>` NULL 安全等值（即 `IS NOT DISTINCT FROM`），表明 `seller_id` 存在 NULL 的情况（如匿名或未绑定卖家的店铺），下游查询时对 `seller_id` 过滤需注意 NULL 值处理。

4. **`grass_region` 存储为大写**：ETL 中通过 `upper('${region}')` 写入，字段值为大写地区代码，查询时过滤条件需使用大写，如 `grass_region = 'MY'`，否则过滤条件不命中分区。

5. **本地货币与 USD 双币种**：金额字段均提供本地货币（`_local` / `_amt`）和 USD（`_usd`）两个版本，跨地区汇总应统一使用 USD 口径字段；单地区分析可使用本地货币字段。

6. **`neg_topup_amt` 为负向冲销金额**：该字段记录退款/扣减，通常为负值或接近0，计算净充值时需将其与正向充值相加（因其本身已是负数）。

---

*文档生成时间：2026-04-22*
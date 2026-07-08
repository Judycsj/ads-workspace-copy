<!-- ads-workspace-gdoc-sync: gdoc_id=1UnvlcABSLKXP8xPjTBgsqvE4TH4Z7xgKx9f4YZzWst4 gdoc_url=https://docs.google.com/document/d/1UnvlcABSLKXP8xPjTBgsqvE4TH4Z7xgKx9f4YZzWst4/edit -->

# mp_paidads.dws_advertiser_topup_nd

**分层**：DWS（数据服务层 / 汇总层）
**主键**：`shop_id` + `seller_id` + `tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1，覆盖截至 `grass_date` 的滚动 N 日窗口）
**引用频次**：1 次（候选表范围内）

---

## 业务描述

本表是广告主（卖家/店铺维度）充值行为的多周期滚动汇总宽表，以 **卖家 × 店铺 × 日期 × 时区类型 × 地区** 为粒度，预聚合近 7 天、30 天、60 天、90 天四个滚动窗口内的充值金额与充值次数指标。数据来源于每日粒度明细表 `dws_advertiser_topup_1d__reg_s0_live`，通过参数化调度覆盖全部地区，各地区按本地时区独立产出。

本表的核心价值在于为广告充值分析提供开箱即用的多周期视图，免去下游查询自行展开时间窗口的成本。典型使用场景包括：广告主充值健康度监控、自动充值与手动充值结构分析、SRM 激励充值追踪、卖家分层与标签生产（如近 30 天首次充值、高频充值卖家识别），以及报表看板中的充值趋势展示。

指标体系涵盖六大充值类型（总充值、手动充值、手动免费信用充值、手动付费信用充值、自动充值、Normal 充值、Seller Mission 充值、SRM 充值、负向充值），每类均提供本地货币与美元双口径，以及对应的充值次数，合计 97 个字段。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区，区分 `local`（本地时区）与 `utc` 等不同时区口径。各地区按本地时区参数化调度产出。⚠️ 查询时必须指定，否则数据翻倍；通常取 `tz_type = 'local'` |
| `grass_region` | string | 地区分区，大写地区代码（如 `'ID'`、`'TH'`），通过 `${region}` 参数化调度覆盖所有地区。⚠️ 查询时必须指定，避免跨地区全表扫描 |
| `grass_date` | date | 日期分区，表示该行数据对应的统计基准日期（即滚动窗口的截止日）。⚠️ 查询时必须指定，通常取最新分区日期 |

---

### 维度：主键与广告主属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `shop_id` | bigint | 店铺 ID，广告主的店铺维度标识 |
| `seller_id` | bigint | 卖家 ID，广告主的卖家维度标识；ETL 中已过滤 `seller_id IS NOT NULL`，不存在空值 |

---

### 指标：总充值金额与次数

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_topup_amt_7d` | double | 近 7 天总充值金额（本地货币） |
| `total_topup_amt_30d` | double | 近 30 天总充值金额（本地货币） |
| `total_topup_amt_60d` | double | 近 60 天总充值金额（本地货币） |
| `total_topup_amt_90d` | double | 近 90 天总充值金额（本地货币） |
| `total_topup_amt_usd_7d` | double | 近 7 天总充值金额（美元） |
| `total_topup_amt_usd_30d` | double | 近 30 天总充值金额（美元） |
| `total_topup_amt_usd_60d` | double | 近 60 天总充值金额（美元） |
| `total_topup_amt_usd_90d` | double | 近 90 天总充值金额（美元） |
| `topup_times_cnt_7d` | bigint | 近 7 天总充值次数 |
| `topup_times_cnt_30d` | bigint | 近 30 天总充值次数 |
| `topup_times_cnt_60d` | bigint | 近 60 天总充值次数 |
| `topup_times_cnt_90d` | bigint | 近 90 天总充值次数 |

---

### 指标：手动充值（Manual Topup）

| 字段 | 类型 | 说明 |
|------|------|------|
| `manual_topup_amt_7d` | double | 近 7 天手动充值总额（本地货币） |
| `manual_topup_amt_30d` | double | 近 30 天手动充值总额（本地货币） |
| `manual_topup_amt_60d` | double | 近 60 天手动充值总额（本地货币） |
| `manual_topup_amt_90d` | double | 近 90 天手动充值总额（本地货币） |
| `manual_topup_amt_usd_7d` | double | 近 7 天手动充值总额（美元） |
| `manual_topup_amt_usd_30d` | double | 近 30 天手动充值总额（美元） |
| `manual_topup_amt_usd_60d` | double | 近 60 天手动充值总额（美元） |
| `manual_topup_amt_usd_90d` | double | 近 90 天手动充值总额（美元） |
| `manual_topup_times_cnt_7d` | bigint | 近 7 天手动充值次数 |
| `manual_topup_times_cnt_30d` | bigint | 近 30 天手动充值次数 |
| `manual_topup_times_cnt_60d` | bigint | 近 60 天手动充值次数 |
| `manual_topup_times_cnt_90d` | bigint | 近 90 天手动充值次数 |

---

### 指标：手动免费信用充值（Manual Free Credit Topup）

| 字段 | 类型 | 说明 |
|------|------|------|
| `manual_free_credit_topup_amt_7d` | double | 近 7 天手动免费信用充值总额（本地货币） |
| `manual_free_credit_topup_amt_30d` | double | 近 30 天手动免费信用充值总额（本地货币） |
| `manual_free_credit_topup_amt_60d` | double | 近 60 天手动免费信用充值总额（本地货币） |
| `manual_free_credit_topup_amt_90d` | double | 近 90 天手动免费信用充值总额（本地货币）。⚠️ column_comment 标注为"60天"，实为笔误，ETL 逻辑确认为 90 天窗口 |
| `manual_free_credit_topup_amt_usd_7d` | double | 近 7 天手动免费信用充值总额（美元） |
| `manual_free_credit_topup_amt_usd_30d` | double | 近 30 天手动免费信用充值总额（美元） |
| `manual_free_credit_topup_amt_usd_60d` | double | 近 60 天手动免费信用充值总额（美元） |
| `manual_free_credit_topup_amt_usd_90d` | double | 近 90 天手动免费信用充值总额（美元） |

---

### 指标：手动付费信用充值（Manual Paid Credit Topup）

| 字段 | 类型 | 说明 |
|------|------|------|
| `manual_paid_credit_topup_amt_7d` | double | 近 7 天手动付费信用充值总额（本地货币），反映卖家对广告预算的直接付款贡献 |
| `manual_paid_credit_topup_amt_30d` | double | 近 30 天手动付费信用充值总额（本地货币） |
| `manual_paid_credit_topup_amt_60d` | double | 近 60 天手动付费信用充值总额（本地货币） |
| `manual_paid_credit_topup_amt_90d` | double | 近 90 天手动付费信用充值总额（本地货币） |
| `manual_paid_credit_topup_amt_usd_7d` | double | 近 7 天手动付费信用充值总额（美元） |
| `manual_paid_credit_topup_amt_usd_30d` | double | 近 30 天手动付费信用充值总额（美元） |
| `manual_paid_credit_topup_amt_usd_60d` | double | 近 60 天手动付费信用充值总额（美元） |
| `manual_paid_credit_topup_amt_usd_90d` | double | 近 90 天手动付费信用充值总额（美元） |

---

### 指标：自动充值（Auto Topup）

| 字段 | 类型 | 说明 |
|------|------|------|
| `auto_topup_amt_7d` | double | 近 7 天自动充值总额（本地货币） |
| `auto_topup_amt_30d` | double | 近 30 天自动充值总额（本地货币） |
| `auto_topup_amt_60d` | double | 近 60 天自动充值总额（本地货币） |
| `auto_topup_amt_90d` | double | 近 90 天自动充值总额（本地货币） |
| `auto_topup_amt_usd_7d` | double | 近 7 天自动充值总额（美元） |
| `auto_topup_amt_usd_30d` | double | 近 30 天自动充值总额（美元） |
| `auto_topup_amt_usd_60d` | double | 近 60 天自动充值总额（美元） |
| `auto_topup_amt_usd_90d` | double | 近 90 天自动充值总额（美元） |
| `auto_topup_times_cnt_7d` | bigint | 近 7 天自动充值次数。⚠️ column_comment 描述为"手动充值"，系笔误，ETL 逻辑确认为自动充值（`auto_topup_times_cnt`） |
| `auto_topup_times_cnt_30d` | bigint | 近 30 天自动充值次数 |
| `auto_topup_times_cnt_60d` | bigint | 近 60 天自动充值次数 |
| `auto_topup_times_cnt_90d` | bigint | 近 90 天自动充值次数。⚠️ column_comment 描述为"手动充值"，系笔误，ETL 逻辑确认为自动充值 |

---

### 指标：Normal 充值

| 字段 | 类型 | 说明 |
|------|------|------|
| `normal_amt_local_7d` | double | 近 7 天 Normal 充值总额（本地货币）。Normal 充值指 `order_type IN (2, 6)` 的充值类型 |
| `normal_amt_local_30d` | double | 近 30 天 Normal 充值总额（本地货币） |
| `normal_amt_local_60d` | double | 近 60 天 Normal 充值总额（本地货币） |
| `normal_amt_local_90d` | double | 近 90 天 Normal 充值总额（本地货币），`order_type IN (2, 6)` |
| `normal_amt_usd_7d` | double | 近 7 天 Normal 充值总额（美元） |
| `normal_amt_usd_30d` | double | 近 30 天 Normal 充值总额（美元） |
| `normal_amt_usd_60d` | double | 近 60 天 Normal 充值总额（美元），`order_type IN (2, 6)` |
| `normal_amt_usd_90d` | double | 近 90 天 Normal 充值总额（美元），`order_type IN (2, 6)` |
| `normal_topup_times_cnt_7d` | bigint | 近 7 天 Normal 充值次数 |
| `normal_topup_times_cnt_30d` | bigint | 近 30 天 Normal 充值次数 |
| `normal_topup_times_cnt_60d` | bigint | 近 60 天 Normal 充值次数 |
| `normal_topup_times_cnt_90d` | bigint | 近 90 天 Normal 充值次数 |

---

### 指标：Seller Mission 充值

| 字段 | 类型 | 说明 |
|------|------|------|
| `seller_mission_topup_amt_7d` | double | 近 7 天 Seller Mission 充值总额（本地货币） |
| `seller_mission_topup_amt_30d` | double | 近 30 天 Seller Mission 充值总额（本地货币） |
| `seller_mission_topup_amt_60d` | double | 近 60 天 Seller Mission 充值总额（本地货币） |
| `seller_mission_topup_amt_90d` | double | 近 90 天 Seller Mission 充值总额（本地货币） |
| `seller_mission_topup_amt_usd_7d` | double | 近 7 天 Seller Mission 充值总额（美元） |
| `seller_mission_topup_amt_usd_30d` | double | 近 30 天 Seller Mission 充值总额（美元） |
| `seller_mission_topup_amt_usd_60d` | double | 近 60 天 Seller Mission 充值总额（美元） |
| `seller_mission_topup_amt_usd_90d` | double | 近 90 天 Seller Mission 充值总额（美元） |

---

### 指标：SRM 充值（Seller Relationship Management）

| 字段 | 类型 | 说明 |
|------|------|------|
| `srm_topup_amt_7d` | double | 近 7 天 SRM 系统触发的 QSS 广告激励充值总额（本地货币） |
| `srm_topup_amt_30d` | double | 近 30 天 SRM 充值总额（本地货币） |
| `srm_topup_amt_60d` | double | 近 60 天 SRM 充值总额（本地货币） |
| `srm_topup_amt_90d` | double | 近 90 天 SRM 充值总额（本地货币） |
| `srm_topup_amt_usd_7d` | double | 近 7 天 SRM 充值总额（美元） |
| `srm_topup_amt_usd_30d` | double | 近 30 天 SRM 充值总额（美元） |
| `srm_topup_amt_usd_60d` | double | 近 60 天 SRM 充值总额（美元） |
| `srm_topup_amt_usd_90d` | double | 近 90 天 SRM 充值总额（美元） |
| `srm_topup_times_cnt_7d` | bigint | 近 7 天 SRM 充值次数 |
| `srm_topup_times_cnt_30d` | bigint | 近 30 天 SRM 充值次数 |
| `srm_topup_times_cnt_60d` | bigint | 近 60 天 SRM 充值次数 |
| `srm_topup_times_cnt_90d` | bigint | 近 90 天 SRM 充值次数 |

---

### 指标：负向充值（Neg Topup）

| 字段 | 类型 | 说明 |
|------|------|------|
| `neg_topup_amt_7d` | double | 近 7 天负向充值金额（本地货币）。负向充值通常表示退款、冲销等减少广告余额的操作，数值通常为负数或 0 |
| `neg_topup_amt_30d` | double | 近 30 天负向充值金额（本地货币） |
| `neg_topup_amt_60d` | double | 近 60 天负向充值金额（本地货币） |
| `neg_topup_amt_90d` | double | 近 90 天负向充值金额（本地货币） |
| `neg_topup_amt_usd_7d` | double | 近 7 天负向充值金额（美元） |
| `neg_topup_amt_usd_30d` | double | 近 30 天负向充值金额（美元） |
| `neg_topup_amt_usd_60d` | double | 近 60 天负向充值金额（美元） |
| `neg_topup_amt_usd_90d` | double | 近 90 天负向充值金额（美元） |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下三个分区字段，否则将触发全表扫描，导致查询性能极差、资源消耗爆增，且返回多地区、多时区的重复数据：

| 分区字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `grass_date` | `grass_date = '2026-04-21'`（通常取最新分区） | 读取全部历史分区，数据量成倍增加 |
| `grass_region` | `grass_region = 'ID'`（按需指定目标地区） | 返回所有地区数据，结果混淆 |
| `tz_type` | `tz_type = 'local'`（通常使用本地时区口径） | 数据按时区类型翻倍，指标虚高 |

**示例**：
```sql
SELECT
    seller_id,
    shop_id,
    total_topup_amt_30d,
    total_topup_amt_usd_30d
FROM mp_paidads.dws_advertiser_topup_nd__reg_s0_live
WHERE grass_date    = '2026-04-21'
  AND grass_region  = 'ID'
  AND tz_type       = 'local';
```

### 不可直接 SUM 的字段

本表所有指标字段均为**按 `(shop_id, seller_id, grass_region, tz_type, grass_date)` 粒度预聚合后的滚动窗口累计值**，存在以下使用限制：

1. **跨 `grass_date` 分区不可直接 SUM**：每个 `grass_date` 分区的指标已包含该日期截止的 N 日滚动汇总，不同日期分区的同一字段之间存在数据重叠（滑动窗口），直接对多个日期分区求 SUM 会造成**重复计数**。如需跨日期趋势分析，应逐一取各日期分区的值，不得跨分区累加。

2. **跨地区（`grass_region`）不可直接 SUM 本地货币字段**：`*_amt_*d`（非 `*_usd_*d`）字段以本地货币计价，不同地区货币单位不同，跨地区 SUM 无业务意义；如需跨地区汇总，请使用对应的 `*_usd_*d` 字段。

3. **跨 `tz_type` 不可 SUM**：同一 `grass_date` + `grass_region` 下，不同 `tz_type` 的数据来自同一批交易按不同时区口径统计，跨 `tz_type` SUM 将导致数据重复。

### 时效性说明

- 本表以 **T+1** 频率更新，`grass_date` 分区通常滞后 1 天。查询最新数据时，应取 `grass_date = CURRENT_DATE - 1`（或确认当日分区是否已产出后再使用）。
- 所有 `*_7d` / `*_30d` / `*_60d` / `*_90d` 字段均以当日 `grass_date` 为窗口截止日向前滚动计算，因此取**最新 `grass_date` 分区**即可获得截至最近一天的多周期充值汇总，**无需查询多个分区**。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dws_advertiser_topup_1d__reg_s0_live` | 广告主充值每日明细汇总表，提供各充值类型的单日金额与次数；本表对其近 90 天数据按滚动窗口（7/30/60/90d）进行二次聚合 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dws_advertiser_topup_1d__reg_s0_live
  │
  │  WHERE grass_region = upper('${region}')
  │    AND grass_date BETWEEN (${grass_date} - 89 DAYS) AND ${grass_date}
  │
  ▼
[子查询] 为每条明细行打滚动窗口标记
  │  is_7d  = CASE WHEN grass_date ∈ [T-6,  T] THEN 1 ELSE 0 END
  │  is_30d = CASE WHEN grass_date ∈ [T-29, T] THEN 1 ELSE 0 END
  │  is_60d = CASE WHEN grass_date ∈ [T-59, T] THEN 1 ELSE 0 END
  │  is_90d = CASE WHEN grass_date ∈ [T-89, T] THEN 1 ELSE 0 END
  │
  ▼
[外层聚合] GROUP BY shop_id, seller_id, grass_region, tz_type
  │  SUM(CASE WHEN is_Nd = 1 THEN metric ELSE 0 END) → metric_Nd
  │  WHERE seller_id IS NOT NULL
  │
  ▼
INSERT OVERWRITE
mp_paidads.dws_advertiser_topup_nd__reg_s0_live
  PARTITION (tz_type, grass_region, grass_date = '${grass_date}')
```

### 关键 CTE 说明

本 ETL 无显式 CTE，逻辑通过两层嵌套查询实现：

| 层次 | 来源表 | 作用 |
|------|--------|------|
| 内层子查询 | `dws_advertiser_topup_1d__reg_s0_live` | 读取近 90 天逐日明细，为每行计算 `is_7d`、`is_30d`、`is_60d`、`is_90d` 四个窗口归属标志位 |
| 外层聚合 | 内层子查询 | 按 `(shop_id, seller_id, grass_region, tz_type)` 分组，通过条件求和将四个窗口的指标展开为宽表列，最终写入目标分区 |

### 注意事项

1. **滚动窗口的边界计算**：7d 窗口为 `[T-6, T]`（含当天共 7 天），30d 为 `[T-29, T]`（共 30 天），以此类推。上游数据读取范围取最大窗口 89 天，一次 Scan 同时计算四个窗口，避免重复读取。

2. **column_comment 笔误警告**：
   - `auto_topup_times_cnt_7d` 和 `auto_topup_times_cnt_90d` 的 comment 描述为"手动充值"，属笔误，ETL SQL 确认对应字段为 `auto_topup_times_cnt`（自动充值次数）。
   - `manual_free_credit_topup_amt_90d` 的 comment 写为"近60天"，属笔误，实际为 90 天窗口（`is_90d = 1`）。
   使用时应以 ETL 逻辑为准，忽略上述 comment 错误描述。

3. **INSERT OVERWRITE 分区策略**：每次调度对目标 `grass_date` 分区执行覆盖写入，历史分区数据不变；调度结束后通过 `ALTER TABLE ... ADD IF NOT EXISTS PARTITION` 确保分区元数据注册。

4. **seller_id NULL 过滤**：ETL 在外层 `WHERE seller_id IS NOT NULL` 过滤，因此本表中不存在 `seller_id` 为空的记录；若下游发现某店铺无数据，需排查上游 1d 表的数据完整性。

5. **参数化调度**：ETL 通过 `${region}`、`${grass_date}`（以及隐含的 `${timezone}`）参数驱动，每个地区独立调度，产出到对应的 `grass_region` 分区，文档中所有地区代码示例均为调度模板实例，不代表仅覆盖特定地区。

---

*文档生成时间：2026-04-22*
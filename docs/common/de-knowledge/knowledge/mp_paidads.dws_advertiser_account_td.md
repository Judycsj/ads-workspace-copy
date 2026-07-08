<!-- ads-workspace-gdoc-sync: gdoc_id=1ObOHT29TbEux-9K1SMhYu7Cn-RL0obxtaFxe9_D5Wz0 gdoc_url=https://docs.google.com/document/d/1ObOHT29TbEux-9K1SMhYu7Cn-RL0obxtaFxe9_D5Wz0/edit -->

# mp_paidads.dws_advertiser_account_td

**分层：** DWS（数据汇总层 / Service Layer）
**主键：** `shop_id` + `grass_region` + `grass_date`
**分区：** `tz_type` / `grass_region` / `grass_date`
**更新频率：** 每日全量覆写（INSERT OVERWRITE，按地区 + 日期分区）
**引用频次：** 1 次（候选表范围内）

---

## 业务描述

本表为广告主账户余额的**截至当日（to-date）累计快照表**，记录各地区每位广告主（卖家）账户在每个自然日结束时的钱包余额状态，包括日事件发生前后的余额、对应 USD 换算金额、低余额阈值及是否触达阈值等核心指标。相较于明细层的逐笔流水，本表以天粒度保留每个 `shop_id` 最终的余额快照，便于业务方快速查询任意历史日期的账户余额水位。

本表的典型使用场景包括：监控卖家广告钱包余额健康度、识别低余额风险账户（`is_reach_threshold`）、支撑广告充值/预警运营策略，以及为下游报表或告警任务提供稳定的历史余额基准。

ETL 逻辑采用**自回滚 FULL OUTER JOIN** 模式：每日将当日明细层数据（`dws_advertiser_account_1d`）与前一日本表快照进行合并，优先取当日数据，缺失时回填昨日快照，确保所有历史存活账户的余额记录在新分区中得以延续，实现无断层的连续快照语义。各地区按本地时区参数化调度，统一以 `tz_type = 'local'` 写入。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型分区，当前写入值固定为 `'local'`（各地区按本地时区调度）。查询时**必须指定** `tz_type = 'local'`，否则将产生全分区扫描 ⚠️ 若不过滤会导致全表扫描，且存在重复计数风险 |
| `grass_region` | string | 国家/地区分区，大写地区代码（如 `'MY'`、`'TH'` 等）。查询时建议同步指定以裁剪分区 |
| `grass_date` | date | 日期分区，格式 `yyyy-MM-dd`，代表快照所属自然日。本表为累计快照，每个日期分区均保留截至当日所有活跃账户的余额状态 |

### 维度：主键与账户标识

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | bigint | 用户 ID，来源于 `shopee.paid_ads_dwd_trd_shop_transaction_di`，代表广告主对应的平台用户 |
| `shop_id` | bigint | 店铺 ID，来源于 `shopee.paid_ads_dwd_trd_shop_transaction_di`，为本表核心业务主键，唯一标识一个广告主账户 |

### 指标：账户余额（本地货币）

| 字段 | 类型 | 说明 |
|------|------|------|
| `acc_before_balance` | double | 当日事件发生**前**的账户余额（本地货币），来源于 `shopee.paid_ads_dwd_trd_shop_transaction_di`。为当日首笔事件前的余额快照 ⚠️ 为单账户快照值，多行 SUM 无业务意义，需结合 `shop_id` 粒度使用 |
| `acc_after_balance` | double | 当日事件发生**后**的账户余额（本地货币），来源于 `shopee.paid_ads_dwd_trd_shop_transaction_di`。代表截至当日结束时的实际账户余额 ⚠️ 为单账户快照值，跨账户直接 SUM 需谨慎，应先明确业务口径 |

### 指标：账户余额（USD）

| 字段 | 类型 | 说明 |
|------|------|------|
| `acc_before_balance_usd` | double | 当日事件发生**前**的账户余额（USD 换算），来源于 `shopee.paid_ads_dwd_trd_shop_transaction_di` ⚠️ 为汇率换算后的派生值，跨日或跨地区聚合时需注意汇率口径一致性，不可与本地货币字段混用 |
| `acc_after_balance_usd` | double | 当日事件发生**后**的账户余额（USD 换算），来源于 `shopee.paid_ads_dwd_trd_shop_transaction_di` ⚠️ 为汇率换算后的派生值，跨日聚合时需注意汇率口径一致性 |

### 指标：低余额阈值与预警

| 字段 | 类型 | 说明 |
|------|------|------|
| `low_threshold` | double | 卖家钱包余额（含已付费且未过期的积分余额）的预定义低阈值下限（本地货币）。该字段表示触发预警的阈值基准值本身，而非是否触达的标志 ⚠️ 字段名易被误读为布尔 flag，实为数值阈值，使用前需结合 `is_reach_threshold` 字段综合判断 |
| `low_threshold_usd` | double | 低余额阈值下限对应的 USD 换算值 ⚠️ 为汇率换算派生值，含义同 `low_threshold`，不可视为 flag 使用 |
| `is_reach_threshold` | tinyint | 当日任意时刻账户余额是否触达低阈值的标志，来源于 `shopee.paid_ads_dwd_trd_shop_transaction_di`。`1` 表示当日有触达，`0` 表示未触达 ⚠️ 为 tinyint 类型的布尔标志，直接 SUM 可统计触达账户数，但**不可**对其求均值作为比率使用，需用 `SUM / COUNT` 重新计算触达率 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下分区过滤条件，遗漏任意一项将触发跨分区全量扫描，造成严重的计算资源浪费并可能返回重复数据：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 扫描所有时区分区，当前写入仅有 `local`，遗漏将导致全分区扫描且后续如有新分区加入时会出现重复计数 |
| `grass_region` | `grass_region = 'MY'`（按需替换地区码） | 扫描所有地区数据，返回结果集膨胀，计算资源消耗大幅增加 |
| `grass_date` | `grass_date = '2026-04-21'`（按需指定日期） | 全量扫描所有历史日期分区，本表为累计快照，历史分区数据量随时间线性增长 |

> **说明**：本表为累计快照（to-date），每个 `grass_date` 分区均包含截至该日所有存活账户的完整余额记录。若只需查询"今日余额"，**只取最新 `grass_date` 分区**即可，无需跨日聚合。

### 不可直接 SUM 的字段

| 字段 | 问题说明 | 正确计算方式 |
|------|----------|-------------|
| `acc_before_balance` / `acc_after_balance` | 为单账户余额快照，不同账户直接加总通常无实际业务意义（除非明确需要计算全量账户余额总和） | 按 `shop_id` 粒度查询；如需汇总，需明确业务口径（如"账户余额 > 0 的账户总余额"）后再聚合 |
| `acc_before_balance_usd` / `acc_after_balance_usd` | 为汇率换算派生值，跨地区聚合时需确保汇率口径一致 | 同地区内可 SUM；跨地区汇总时需确认汇率转换逻辑 |
| `low_threshold` / `low_threshold_usd` | 字段含义为预警阈值数值，而非布尔标志，SUM 无实际业务含义 | 用于与 `acc_after_balance` 对比判断余额是否低于阈值，或作为过滤条件使用 |
| `is_reach_threshold` | tinyint 类型，直接 SUM 可得触达账户数，但不可直接 AVG 作触达率 | 触达率 = `SUM(is_reach_threshold) / COUNT(shop_id)` |

### 时效性说明

本表为**累计至当日（to-date）的快照表**，采用自回滚模式构建：

- **查询最新余额**：取最新可用 `grass_date` 分区（通常为 `T-1`，因 ETL 于每日调度产出前一日数据）
- **查询历史余额**：直接指定对应 `grass_date` 分区，无需跨日聚合，每个分区已包含截至该日的完整账户快照
- **注意**：若某账户当日无交易事件，其余额数据通过 FULL OUTER JOIN 从前一日分区回填，因此历史分区中的余额值反映的是该账户**最近一次有活动日期**的余额状态，而非一定是该自然日产生了新的交易

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dws_advertiser_account_1d__reg_s0_live` | 当日（T 日）广告主账户余额明细汇总，提供每日新增/变更的账户余额数据，作为当日增量输入 |
| `mp_paidads.dws_advertiser_account_td__reg_s0_live`（自身 T-1 分区） | 前一日的账户余额累计快照，通过 FULL OUTER JOIN 实现历史账户余额的向前回滚填充，确保无活动账户的余额记录不丢失 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dws_advertiser_account_1d__reg_s0_live
  (grass_date = T日, grass_region = ${region})
                        │
                        │  当日新增/变更账户余额（子查询 a）
                        │
                        ▼
              FULL OUTER JOIN（ON shop_id + grass_region）
                        │
                        ▲
                        │  历史账户余额快照（子查询 b）
                        │
mp_paidads.dws_advertiser_account_td__reg_s0_live
  (grass_date = T-1日, grass_region = ${region})
                        │
                        │  COALESCE 优先取当日值，缺失时回填昨日值
                        ▼
     dws_advertiser_account_td__reg_s0_live
  PARTITION (tz_type='local', grass_region, grass_date=T日)
  [INSERT OVERWRITE，Hive SQL 引擎执行]
```

### 关键 CTE 说明

本 ETL 无显式 CTE，核心逻辑通过两个内联子查询实现：

| 子查询别名 | 来源表 | 作用 |
|------------|--------|------|
| `a` | `dws_advertiser_account_1d__reg_s0_live` | 读取 T 日当日账户余额明细，作为 FULL OUTER JOIN 的左表（当日增量） |
| `b` | `dws_advertiser_account_td__reg_s0_live`（自身） | 读取 T-1 日累计快照，作为 FULL OUTER JOIN 的右表（历史存量），实现无活动账户的余额延续 |

### 注意事项

1. **自回滚模式（Self-referencing FULL OUTER JOIN）**：本表在 ETL 中引用自身前一日分区（`grass_date = T-1`），INSERT OVERWRITE 写入 T 日新分区，不会覆盖历史分区。这是构建连续快照的标准模式，但需注意若前一日分区数据缺失（如首次初始化或历史回刷），会导致该日快照仅包含当日有活动的账户，历史账户余额将断链。

2. **COALESCE 优先级**：对所有字段均使用 `COALESCE(a.field, b.field)`，即**当日数据（a）优先于历史数据（b）**。若同一 `shop_id` 当日和前日均有记录，以当日余额为准；若当日无记录（仅 b 存在），则延用昨日余额。

3. **地区参数化调度**：ETL 中 `upper('${region}')` 和 `date('${grass_date}')` 均为调度模板参数，实际运行时由调度系统注入各地区对应值，覆盖全部支持地区。各地区按本地时区独立调度。

4. **`low_threshold` 字段口径**：字段 comment 描述为"是否触达低阈值"，但实际数据类型为 `double`，结合 ETL 上游传递逻辑，该字段实为**阈值数值本身**，而非布尔标志。判断是否触达阈值应使用 `is_reach_threshold` 字段。

5. **分区写入方式**：采用 `INSERT OVERWRITE ... PARTITION (tz_type='local', grass_region, grass_date)` 动态分区写入，每次调度仅覆写对应地区和日期的分区，历史分区数据安全。

---

*文档生成时间：2026-04-22*
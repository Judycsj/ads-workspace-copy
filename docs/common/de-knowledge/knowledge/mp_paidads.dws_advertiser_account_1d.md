<!-- ads-workspace-gdoc-sync: gdoc_id=1tA7ccuUl8ZQSMk-xpaEyhdSfme_OgF2DwLm7QeFDzfc gdoc_url=https://docs.google.com/document/d/1tA7ccuUl8ZQSMk-xpaEyhdSfme_OgF2DwLm7QeFDzfc/edit -->

# mp_paidads.dws_advertiser_account_1d

**分层**：DWS（数据汇总层）
**主键**：`user_id`、`shop_id`、`grass_region`、`grass_date`、`tz_type`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1）
**引用频次**：11 次（候选表范围内）

---

## 业务描述

本表以广告主账户（`user_id` + `shop_id`）为粒度，按自然日汇总广告主账户余额的关键快照指标，是付费广告资金健康度监控的核心 DWS 宽表。每日调度完成后，表中记录当日交易发生前的最高期初余额（`acc_before_balance`）与当日交易发生后的最低期末余额（`acc_after_balance`），并基于各地区预设阈值判断账户余额是否在日内任意时刻触及低余额预警线（`is_reach_threshold`）。

本表的主要使用场景包括：广告主账户余额异常预警（如余额不足触发暂停投放）、日度资金消耗分析、账户风险管控以及广告平台运营看板的资金维度展示。余额字段同时提供本地货币与 USD 两种口径，便于跨地区横向对比与汇率统一换算分析。

各地区按本地时区参数化调度，`tz_type = 'local'` 为标准分区写入口径，下游查询时需显式过滤以保证时区一致性。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区分区标识。当前写入值固定为 `'local'`（各地区按本地时区调度）。查询时**必须**过滤 `tz_type = 'local'`，否则将产生重复扫描。 |
| `grass_region` | string | 国家/地区分区，如 `'SG'`、`'ID'`、`'MY'` 等，大写两字母 ISO 代码。查询时**必须**指定，避免全表扫描。 |
| `grass_date` | date | 数据日期分区（草日期，按本地时区对齐）。格式 `YYYY-MM-DD`。查询时**必须**指定具体日期或日期范围。 |

### 维度：主键与广告主属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | bigint | 广告主 ID，来源于 `dim_advertiser`，通过 `shop_id` 关联补全。若广告主维表中无对应记录则为 NULL。 |
| `shop_id` | bigint | 店铺 ID，广告账户的核心业务主键，来源于当日交易明细表。 |

### 指标：账户余额快照

| 字段 | 类型 | 说明 |
|------|------|------|
| `acc_before_balance` | double | 当日最早一笔交易发生**前**的账户余额最高值，本地货币。即日内期初余额的乐观上限，取时间戳最早且交易前余额最高的记录。⚠️ 为特定条件下的快照值（非简单聚合），不可对多行直接 SUM，跨日或跨账户聚合需明确口径。 |
| `acc_before_balance_usd` | double | `acc_before_balance` 除以当日汇率换算的 USD 值。⚠️ 为派生字段（本地货币 / 汇率），不可直接 SUM；跨地区汇总时需以分子分母重新计算，汇率取 `dim_exchange_rate` 当日值。 |
| `acc_after_balance` | double | 当日最后一笔交易发生**后**的账户余额最低值，本地货币。即日内期末余额的悲观下限，取时间戳最新且交易后余额最低的记录。⚠️ 为特定条件下的快照值，不可直接 SUM；代表当日余额的最不利状态，而非日终实际余额均值。 |
| `acc_after_balance_usd` | double | `acc_after_balance` 除以当日汇率换算的 USD 值。⚠️ 为派生字段（本地货币 / 汇率），不可直接 SUM；跨地区汇总需重新取分子分母计算。 |

### 指标：低余额预警

| 字段 | 类型 | 说明 |
|------|------|------|
| `low_threshold` | double | 各地区预设的低余额预警阈值，本地货币。阈值按 `grass_region` 硬编码（如 TW=5、ID=2000、MY=0.7 等），其余地区默认为 1。⚠️ 为业务规则配置值，非实测指标，直接 SUM 无业务意义。 |
| `low_threshold_usd` | double | `low_threshold` 除以当日汇率换算的 USD 值。⚠️ 为派生字段，不可直接 SUM。 |
| `is_reach_threshold` | tinyint | 当日账户余额是否在任意时刻触及低阈值。计算逻辑：`min_acc_after_balance < low_threshold` 时为 `1`，否则为 `0`。⚠️ 为 0/1 标志位，跨账户聚合时应使用 `SUM` 统计触达账户数或 `AVG` 计算比率，不可直接对该字段求 SUM 后与账户数混用；NULL 值（交易明细缺失时）需单独处理。 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须**同时指定以下三个分区字段，缺少任意一个将导致全分区扫描，严重影响查询性能并可能产生数据重复：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `tz_type = 'local'` | 扫描所有时区分区，若未来新增 `utc` 分区将导致数据翻倍 |
| `grass_region` | `grass_region = 'SG'`（按需指定） | 全地区扫描，数据量成倍增加，且跨地区余额因货币不同无法直接聚合 |
| `grass_date` | `grass_date = '2026-04-21'` 或日期范围 | 全量历史扫描，造成资源浪费及查询超时 |

### 不可直接 SUM 的字段

| 字段 | 问题类型 | 正确计算方式 |
|------|----------|--------------|
| `acc_before_balance_usd` | 派生字段（本地货币 / 汇率） | 跨账户汇总：`SUM(acc_before_balance) / MAX(exchange_rate)`（同一地区同一日期汇率唯一） |
| `acc_after_balance_usd` | 派生字段（本地货币 / 汇率） | 同上，需重新关联 `dim_exchange_rate` 取当日汇率后计算 |
| `low_threshold_usd` | 派生字段（配置值 / 汇率） | 直接聚合无业务意义，按需关联汇率单独换算 |
| `acc_before_balance` | 快照值（非加法指标） | 跨账户汇总取 `SUM` 可表示账户余额总量，但跨日聚合时应取各日快照而非累加 |
| `acc_after_balance` | 快照值（最低期末余额） | 同上，跨日使用应明确是取"最近一日"还是"日均"等口径 |
| `low_threshold` | 配置值 | 仅用于过滤或展示，直接 `SUM` 无意义 |
| `is_reach_threshold` | 0/1 标志位 | 统计触达账户数用 `SUM(is_reach_threshold)`，统计触达率用 `AVG(is_reach_threshold)` |

### 时效性说明

本表为 **T+1** 调度，`grass_date = CURRENT_DATE - 1` 的分区为最新可用数据。查询最新状态时应取昨日分区，当日数据在次日调度完成后方可使用。余额快照反映的是当日交易流水范围内的极值，不代表实时账户状态。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertiser_transaction_di__reg_s0_live` | 广告主逐笔交易明细，提供 `acc_before_balance`、`acc_after_balance`、`event_timestamp` 等原始字段，用于计算日内余额快照及最低余额 |
| `mp_paidads.dim_advertiser__reg_s0_live` | 广告主维表，通过 `shop_id` 关联补全 `user_id` |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供各地区当日本地货币对 USD 的汇率，用于换算 `_usd` 字段 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_advertiser_transaction_di__reg_s0_live
        │
        ├─── [子查询 t] ──────────────────────────────────────────────────────┐
        │    GROUP BY shop_id, grass_region                                   │
        │    计算：MIN(acc_after_balance) → min_acc_after_balance             │
        │          CASE WHEN grass_region → low_threshold（硬编码阈值）       │
        │                                                                     │
        └─── [子查询 balance] ────────────────────────────────────────────────┤
             双窗口函数（desc_rn / asc_rn）                                   │
             取：最新时间戳最低期末余额 → acc_after_balance                    │
                 最早时间戳最高期初余额 → acc_before_balance                   │
                                                                              ▼
                                                              LEFT JOIN（shop_id + grass_region）
                                                                              │
mp_order.dim_exchange_rate__reg_s0_live ──────────────────────────────────────┤
        提供 exchange_rate，用于 /汇率 → _usd 字段                            │
                                                              LEFT JOIN（grass_region）
                                                                              │
mp_paidads.dim_advertiser__reg_s0_live ───────────────────────────────────────┤
        提供 user_id，通过 shop_id + grass_region 关联                        │
                                                              LEFT JOIN（shop_id + grass_region）
                                                                              │
                                                                              ▼
                              dws_advertiser_account_1d__reg_s0_live
                              PARTITION (tz_type='local', grass_region, grass_date)
                              INSERT OVERWRITE（全量覆写当日分区）
```

### 关键 CTE 说明

本 ETL 无显式 CTE（`WITH` 子句），使用嵌套子查询实现相同逻辑：

| 子查询别名 | 来源表 | 作用 |
|-----------|--------|------|
| `t` | `dwd_advertiser_transaction_di__reg_s0_live` | 按 `shop_id + grass_region` 分组，计算日内最低期末余额（`min_acc_after_balance`）及各地区预设低余额阈值（`low_threshold`） |
| `balance`（内层匿名） | `dwd_advertiser_transaction_di__reg_s0_live` | 使用双路窗口函数（按时间戳降序/升序分别排名）提取期末最低余额和期初最高余额记录 |
| `balance`（外层） | 内层匿名子查询 | 过滤 `desc_rn=1 OR asc_rn=1` 后按 `shop_id + grass_region` 聚合，得到最终的 `acc_after_balance` 与 `acc_before_balance` |
| `exrate` | `dim_exchange_rate__reg_s0_live` | 获取当日汇率，Broadcast Join 方式广播到各节点，用于本地货币换算 USD |
| `dim_advertiser` | `dim_advertiser__reg_s0_live` | 通过 `shop_id` 补全广告主 `user_id` |

### 注意事项

1. **余额快照口径特殊性**：`acc_after_balance` 取日内所有交易中时间戳最新且余额最低的记录，反映的是"最坏情况下的期末余额"而非日终实际余额；`acc_before_balance` 取时间戳最早且余额最高的期初记录，两者组合描述当日余额的波动边界，使用前需充分理解其业务含义。

2. **`is_reach_threshold` 判断逻辑**：基于 `min_acc_after_balance < low_threshold` 判断，其中 `min_acc_after_balance` 为全日最低期末余额。低阈值 `low_threshold` 为各地区硬编码配置值（TW=5、ID/VN=2000、TH=5、MY=0.7、SG=0.2、PH=4，其余地区=1），阈值变更需修改 ETL SQL。

3. **`event_timestamp` 空值处理**：窗口函数中使用 `COALESCE(event_timestamp, 0)` 处理时间戳为 NULL 的情况，NULL 记录将被排到最早位置（升序）或最晚位置（降序），可能影响边界余额的取值准确性；若上游数据质量存在大量 NULL 时间戳，需关注此问题。

4. **`user_id` 可能为 NULL**：`dim_advertiser` 以 LEFT JOIN 关联，若店铺在广告主维表中无对应记录（如新注册或数据缺失），`user_id` 将为 NULL，下游按 `user_id` 聚合时需过滤或单独处理。

5. **INSERT OVERWRITE 写入方式**：每日调度对当日分区全量覆写，历史分区数据不受影响；重跑时可安全覆盖，无需手动清理分区。

6. **汇率来源单一**：USD 换算汇率来自 `dim_exchange_rate`，若某地区当日汇率缺失（LEFT JOIN），`_usd` 字段将为 NULL，监控时需关注汇率表的数据完整性。

---

*文档生成时间：2026-04-22*
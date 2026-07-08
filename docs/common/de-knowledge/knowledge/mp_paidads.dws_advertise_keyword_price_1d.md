<!-- ads-workspace-gdoc-sync: gdoc_id=1M47skDv24Ncq3BBCd2Qys7gQZRIZVB-i-DjgMrziieA gdoc_url=https://docs.google.com/document/d/1M47skDv24Ncq3BBCd2Qys7gQZRIZVB-i-DjgMrziieA/edit -->

# mp_paidads.dws_advertise_keyword_price_1d

**分层**：DWS（数据汇总层）
**主键**：`shop_id` + `ads_id` + `keyword`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日一次（T+1 调度）
**引用频次**：1 次（候选表范围内）

---

## 业务描述

本表记录付费广告关键词（Keyword）在自然日粒度上的出价（Bid Price）快照与变动摘要，覆盖每个广告活动（`ads_id`）下每个关键词在当日的首次出价、末次出价、平均出价及出价变更次数。数据来源于广告审计明细宽表，经聚合与窗口函数计算后汇总而成。

本表的典型使用场景包括：分析商家关键词出价策略（如当日是否调价、调价幅度和方向）、监控关键词出价分布与异常波动、为出价优化算法提供历史基准，以及支持广告平台运营报表中与关键词竞价相关的指标统计。

通过保留当日首尾出价及出价变更次数，业务方既能还原完整的出价轨迹，又能以较低存储成本满足日常分析需求，是付费广告关键词出价分析链路中的核心汇总层表。各地区按本地时区参数化调度，全球市场均有数据覆盖。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型。当前写入值固定为 `'local'`（各地区按本地时区调度）。⚠️ 查询时必须指定此字段，否则将扫描多个分区导致数据重复 |
| `grass_region` | string | 地区代码（大写），如 `'MX'`、`'TH'` 等，由调度参数 `${region}` 参数化生成，覆盖所有投放地区 |
| `grass_date` | date | 数据日期（本地时区自然日），格式 `yyyy-MM-dd`。⚠️ 每次查询必须指定，避免全表扫描 |

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告活动 ID，与 `shop_id`、`keyword` 共同构成业务主键 |
| `shop_id` | bigint | 店铺 ID，广告投放主体 |
| `keyword` | string | 广告关键词文本。⚠️ 来源表已过滤 `keyword IS NOT NULL`，但聚合时需注意大小写敏感性 |
| `placement` | bigint | 广告投放位置标识，取当日末次记录（`keyword_rank_last = 1`） |
| `match_type` | tinyint | 关键词匹配类型（如精确匹配、广泛匹配等），取当日末次记录 |
| `status` | tinyint | 关键词状态/激活状态（Keyword status / activeness），取当日末次记录 |

### 维度：创建与修改时间

| 字段 | 类型 | 说明 |
|------|------|------|
| `create_timestamp` | bigint | 关键词创建时间戳（Unix 毫秒或秒，取当日末次记录中的创建时间）。⚠️ 注意与 `last_modified_timestamp` 的语义区分，不代表本日新建 |
| `create_datetime` | string | 关键词创建时间的可读字符串，格式来自上游审计表 |
| `last_modified_timestamp` | bigint | 关键词当日最后一次变更的时间戳（对应上游 `event_timestamp`），由窗口函数取 `modified_timestamp DESC` 排名第 1 条获得 |
| `last_modified_datetime` | string | 关键词当日最后一次变更时间的可读字符串（对应上游 `event_datetime`） |

### 指标：关键词出价

| 字段 | 类型 | 说明 |
|------|------|------|
| `first_bid_price_local` | double | 当日首次出价（本地货币），由 `modified_timestamp ASC` 排名第 1 的记录取得。包含关键词出价与位置出价设定（seller set bid price, include keyword and location bid price setting） |
| `first_bid_price_usd` | double | 当日首次出价（USD），与 `first_bid_price_local` 对应同一条记录 |
| `last_bid_price_local` | double | 当日末次出价（本地货币），由 `modified_timestamp DESC` 排名第 1 的记录取得。包含关键词出价与位置出价设定 |
| `last_bid_price_usd` | double | 当日末次出价（USD），与 `last_bid_price_local` 对应同一条记录 |
| `avg_bid_price_local` | double | 当日平均出价（本地货币）。⚠️ ETL 口径为 `SUM(DISTINCT bid_price_local) / COUNT(DISTINCT bid_price_local)`，即对去重后的不同价格值取均值，而非按变更时间的加权均值，跨行 SUM 后需重新用分子/分母计算，不可直接 SUM |
| `avg_bid_price_usd` | double | 当日平均出价（USD）。⚠️ 同 `avg_bid_price_local`，口径为去重价格均值，不可直接 SUM |
| `bid_price_change_cnt` | bigint | 当日出价变更次数（distinct 出价值数量）。⚠️ ETL 口径为 `COUNT(DISTINCT bid_price_local)`，统计的是去重后的不同出价值个数，而非实际调价操作次数；若同一价格多次设置则不重复计数 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下三个分区字段**，否则将触发全表扫描，导致查询性能急剧下降并可能产生数据重复：

```sql
WHERE tz_type      = 'local'          -- 固定值，当前仅写入 local 分区
  AND grass_region = '<目标地区>'     -- 如 'MX'、'TH'、'SG' 等大写地区码
  AND grass_date   = '<目标日期>'     -- 如 '2025-01-01'
```

- **`tz_type`**：当前 ETL 仅写入 `'local'` 分区，遗漏此过滤条件将导致结果集重复（若未来新增其他 tz_type 分区）。
- **`grass_region`**：必须使用大写地区代码（ETL 中通过 `upper('${region}')` 写入），遗漏将导致跨地区数据混用。
- **`grass_date`**：必须指定，遗漏将导致全量历史分区扫描，资源消耗极大。

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确计算方式 |
|------|------|------|
| `avg_bid_price_local` | 预计算的去重均值（`SUM(DISTINCT) / COUNT(DISTINCT)`），多行 SUM 无业务含义 | 回溯上游明细表重新计算，或仅在 `shop_id + ads_id + keyword` 粒度直接使用 |
| `avg_bid_price_usd` | 同上，预计算的去重均值 | 同上 |
| `bid_price_change_cnt` | 统计的是当日不同出价值数量而非实际调价操作次数，直接 SUM 会高估 | 若需汇总店铺级变更次数，应以 `shop_id + ads_id + keyword` 为单位理解此字段含义后再决定是否加总 |

### 时效性说明

本表为 T+1 日调度，当日数据最早在次日写入。分析某一日的出价行为应读取对应 `grass_date` 分区。`last_bid_price_local` / `last_bid_price_usd` 反映的是截至当日末次审计记录的出价，不代表次日生效出价。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertise_audit_di__${region}_s0_live` | 广告审计事件明细宽表，提供关键词出价变更事件流，包含关键词文本、出价金额（本地货币/USD）、变更时间戳、广告/店铺维度等全部原始字段 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_advertise_audit_di__${region}_s0_live
  │  过滤条件：grass_date = ${grass_date}
  │            keyword IS NOT NULL
  │            keyword_bid_price_local IS NOT NULL
  │
  ▼
┌─────────────────────────────────────────────────────────────┐
│  CTE: base                                                  │
│  去重（DISTINCT）后的当日关键词出价事件快照                  │
│  字段：keyword, placement, status, timestamps,              │
│        ads_id, shop_id, match_type,                         │
│        bid_price_local, bid_price_usd                       │
└───────────────┬─────────────────────────────────────────────┘
                │
       ┌────────┼──────────────────┐
       ▼        ▼                  ▼
  子查询 a   子查询 b           子查询 c
  聚合均值   首次出价            末次出价
  变更次数   (ROW_NUMBER ASC)   (ROW_NUMBER DESC)
       │        │                  │
       └────────┴──────────────────┘
                │  INNER JOIN（shop_id + ads_id + keyword）
                │  WHERE b.keyword_rank_first = 1
                │    AND c.keyword_rank_last  = 1
                ▼
┌─────────────────────────────────────────────────────────────┐
│  INSERT OVERWRITE                                           │
│  dws_advertise_keyword_price_1d__reg_s0_live                │
│  PARTITION(tz_type='local', grass_region, grass_date)       │
└─────────────────────────────────────────────────────────────┘
```

### 关键 CTE 说明

| CTE / 子查询 | 来源表 | 作用 |
|------|--------|------|
| `base` | `dwd_advertise_audit_di__${region}_s0_live` | 过滤并 DISTINCT 去重当日有效的关键词出价变更事件，作为后续三个子查询的统一输入 |
| 子查询 `a` | `base` | 按 `(shop_id, ads_id, keyword)` 分组，用 `SUM(DISTINCT) / COUNT(DISTINCT)` 计算去重后的平均出价（本地/USD）及出价变更次数 |
| 子查询 `b` | `base` | 用 `ROW_NUMBER() OVER(... ORDER BY modified_timestamp ASC)` 取每个 `(shop_id, ads_id, keyword)` 当日首次出价记录 |
| 子查询 `c` | `base` | 用 `ROW_NUMBER() OVER(... ORDER BY modified_timestamp DESC)` 取每个 `(shop_id, ads_id, keyword)` 当日末次出价记录，同时携带 `placement`、`status`、`match_type` 等维度快照 |

### 注意事项

1. **`avg_bid_price` 口径特殊**：ETL 使用 `SUM(DISTINCT bid_price_local) / COUNT(DISTINCT bid_price_local)` 计算均值，是对当日出现过的**不同价格值**取算术平均，并非按时间加权或按调价次数加权的均值。若商家当日三次调价分别为 1.0、2.0、2.0，则 `avg_bid_price` = (1.0 + 2.0) / 2 = 1.5，`bid_price_change_cnt` = 2。

2. **`bid_price_change_cnt` 不等于实际调价操作次数**：由于使用 `COUNT(DISTINCT bid_price_local)`，相同价格的多次设置不会被计数，该字段更准确地描述"当日出现的不同出价档位数量"。

3. **维度字段取末次快照**：`placement`、`status`、`match_type`、`create_timestamp`、`create_datetime` 均来自末次记录（子查询 `c`，`keyword_rank_last = 1`），反映当日最新状态，不代表全天始终如此。

4. **上游数据去重依赖 DISTINCT**：`base` 层使用 `SELECT DISTINCT`，若上游审计表存在完全重复行，本表可自动处理；但若存在时间戳相同的不同出价记录，窗口函数排名结果可能不确定（`ROW_NUMBER` 随机取一条）。

5. **INNER JOIN 可能丢数**：子查询 `a`、`b`、`c` 均使用 INNER JOIN，若 `base` 中某条记录在三个子查询结果存在不一致（理论上不应发生），可能导致该关键词行丢失，排查时需回溯 `base` 层。

6. **参数化调度覆盖全地区**：`${region}`、`${grass_date}` 为调度模板参数，每个地区独立调度写入对应 `grass_region` 分区，最终全地区数据汇聚于同一张表中。

---

*文档生成时间：2026-05-20*
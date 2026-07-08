<!-- ads-workspace-gdoc-sync: gdoc_id=1mSvnU9yqIapw5HJjsXEsUSLJPxx6_s0ez_3b_ziGvSU gdoc_url=https://docs.google.com/document/d/1mSvnU9yqIapw5HJjsXEsUSLJPxx6_s0ez_3b_ziGvSU/edit -->

# mp_paidads.dws_advertise_keyword_price_td

**分层：** DWS（数据汇总层）
**主键：** `shop_id` + `ads_id` + `keyword`
**分区：** `tz_type` / `grass_region` / `grass_date`
**更新频率：** 每日全量覆盖（INSERT OVERWRITE）
**引用频次：** 4 次（候选表范围内）

---

## 业务描述

本表是**关键词广告出价价格的截至当日累计快照表（To-Date）**，记录每个关键词广告（由 `shop_id` + `ads_id` + `keyword` 唯一标识）从创建起至统计日为止的完整出价历史汇总信息，包括初始出价、最高/最低/平均/最新出价、出价变更次数等核心指标。

本表的核心价值在于**累积聚合**：通过将昨日 TD 快照与今日增量数据（来自 `dws_advertise_keyword_price_1d`）进行 FULL OUTER JOIN 合并，保证在不扫描全量历史数据的前提下，维护每条关键词广告的全生命周期出价统计状态。下游分析师可直接查询本表获取任意关键词的历史出价概览，无需自行做时间序列聚合。

典型使用场景包括：关键词出价策略分析（比较初始价与当前价的漂移幅度）、高频调价行为识别（通过 `bid_price_change_cnt` 筛选）、广告活跃状态监控、以及跨地区出价水位对比等。各地区按本地时区参数化调度，数据口径以各地区本地日期为准。

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `tz_type` | string | 时区类型，当前分区写入值为 `'local'`，表示以各地区本地时区为基准统计。⚠️ 查询时**必须**指定 `tz_type = 'local'`，否则会触发多分区扫描，造成数据重复 |
| `grass_region` | string | 地区/国家代码（大写，如 `'MX'`、`'TH'`），由调度参数 `${region}` 参数化写入，覆盖所有已接入地区 |
| `grass_date` | date | 数据统计日期（本地日期），每日刷新；TD 表中该字段标识快照所属的截止日期 |

### 维度：主键与广告属性

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `shop_id` | bigint | 广告卖家的店铺 ID，主键之一 |
| `ads_id` | bigint | 广告 ID，主键之一 |
| `keyword` | string | 关键词文本，主键之一 |
| `placement` | bigint | 关键词广告的投放位置编码 |
| `status` | tinyint | 关键词广告状态码（具体枚举值参见 `dim_advertise` 维表） |
| `match_type` | tinyint | 关键词匹配类型（如精确匹配、广泛匹配等），以整型枚举存储 |
| `is_ads_active` | tinyint | 广告当前是否活跃的标志位（来自 `dim_advertise` 维表，LEFT JOIN 关联）。⚠️ 该字段反映的是**统计日当天**的活跃状态，非历史活跃状态，不可用于回溯历史是否活跃 |

### 维度：时间戳与创建信息

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `create_timestamp` | bigint | 关键词广告创建时间戳（Unix 时间戳，毫秒或秒级请结合上游确认）⚠️ 为数值型存储，直接做时间比较需先转换 |
| `create_datetime` | string | 关键词广告创建时间，字符串格式（如 `'2024-01-01 12:00:00'`） |
| `keyword_create_timestamp` | bigint | 关键词自身的创建时间戳；若上游无此值则回退为 `last_modified_timestamp`。⚠️ 存在回退逻辑，不保证严格为首次创建时间 |
| `keyword_create_datetime` | string | 关键词自身的创建时间，字符串格式；同上，存在回退逻辑 |
| `last_modified_timestamp` | bigint | 关键词广告最后修改时间戳，优先取当日增量值 |
| `last_modified_datetime` | string | 关键词广告最后修改时间，字符串格式，优先取当日增量值 |

### 指标：出价价格（本地货币）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `initial_bid_price_local` | double | 历史初始出价（本地货币），优先取 TD 历史快照中的值，新词则取当日首次出价。⚠️ 为累计存储值，代表生命周期最早出价，不可跨行 SUM |
| `first_bid_price_local` | double | 当日首次出价（本地货币），仅反映今日增量数据中的第一次出价，与 `initial_bid_price_local` 含义不同 |
| `last_bid_price_local` | double | 截至当日的最新出价（本地货币），取当日增量与历史快照中的最新值 |
| `min_bid_price_local` | double | 历史最低出价（本地货币），由当日出价与历史最低值比较后取小值累计维护。⚠️ 为累计存储值，不可直接 SUM |
| `max_bid_price_local` | double | 历史最高出价（本地货币），由当日出价与历史最高值比较后取大值累计维护。⚠️ 为累计存储值，不可直接 SUM |
| `avg_bid_price_local` | double | 历史加权平均出价（本地货币），由 `(历史均价×历史变更次数 + 当日均价×当日变更次数) / 总变更次数` 计算得出。⚠️ 为预计算加权均值，不可直接 SUM 或 AVG，需使用 `avg_bid_price_local × bid_price_change_cnt` 作为分子重新聚合 |

### 指标：出价价格（美元）

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `initial_bid_price_usd` | double | 历史初始出价（美元），逻辑同 `initial_bid_price_local`。⚠️ 为累计存储值，不可直接 SUM |
| `first_bid_price_usd` | double | 当日首次出价（美元），仅反映今日增量数据中的第一次出价 |
| `last_bid_price_usd` | double | 截至当日的最新出价（美元） |
| `min_bid_price_usd` | double | 历史最低出价（美元）。⚠️ 为累计存储值，不可直接 SUM |
| `max_bid_price_usd` | double | 历史最高出价（美元）。⚠️ 为累计存储值，不可直接 SUM |
| `avg_bid_price_usd` | double | 历史加权平均出价（美元）。⚠️ 为预计算加权均值，不可直接 SUM 或 AVG，需结合 `bid_price_change_cnt` 重新加权聚合 |

### 指标：出价行为统计

| 字段名 | 类型 | 说明 |
|--------|------|------|
| `bid_price_change_cnt` | bigint | 截至当日的历史出价变更次数，由当日变更次数与历史累计变更次数相加维护。⚠️ 为累计值，多行 SUM 时需注意去重（同一 `shop_id+ads_id+keyword` 在同一分区内唯一） |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定**以下分区过滤条件，否则会触发全表扫描，导致性能问题或数据重复：

| 过滤字段 | 推荐写法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | `WHERE tz_type = 'local'` | 当前仅写入 `local` 分区，遗漏不影响结果正确性，但会造成不必要的分区扫描 |
| `grass_region` | `AND grass_region = 'TH'`（按业务需要指定） | 遗漏将扫描所有地区分区，数据膨胀倍数 = 地区数量 |
| `grass_date` | `AND grass_date = '2024-01-15'`（通常取最新日期） | 遗漏将返回所有历史快照日期，数据量极大且产生重复统计 |

**典型安全查询模板：**
```sql
SELECT *
FROM mp_paidads.dws_advertise_keyword_price_td__reg_s0_live
WHERE tz_type = 'local'
  AND grass_region = '${region}'
  AND grass_date = '${grass_date}'
```

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确计算方式 |
|------|------|-------------|
| `avg_bid_price_local` / `avg_bid_price_usd` | 预计算加权均值，直接 SUM/AVG 会忽略各行的权重 | 使用 `SUM(avg_bid_price_local * bid_price_change_cnt) / SUM(bid_price_change_cnt)` 重新加权 |
| `min_bid_price_local` / `min_bid_price_usd` | 历史累计最小值，跨行 SUM 无业务意义 | 跨关键词取最低价时使用 `MIN(min_bid_price_local)` |
| `max_bid_price_local` / `max_bid_price_usd` | 历史累计最大值，跨行 SUM 无业务意义 | 跨关键词取最高价时使用 `MAX(max_bid_price_local)` |
| `initial_bid_price_local` / `initial_bid_price_usd` | 生命周期首次出价，跨行 SUM 无业务意义 | 仅在关键词粒度直接引用，跨广告聚合无标准定义 |
| `is_ads_active` | 反映当日时点状态，历史分区中的值已过期 | 仅在 `grass_date = 最新日期` 分区使用，不得跨日期 SUM |

### 时效性说明

本表为 **TD（To-Date）累计快照表**，每日覆盖写入。**查询最新状态时，应取最新可用日期分区**（通常为调度完成后的 `T-1` 或 `T` 日）：

- `initial_bid_price_*`、`min_bid_price_*`、`max_bid_price_*`、`avg_bid_price_*`、`bid_price_change_cnt`：代表**自关键词创建至 `grass_date` 当天的全量累计值**，取最新分区即可获取最新状态。
- `is_ads_active`：来自当日 `dim_advertise` 维表 JOIN，**仅代表 `grass_date` 当日的活跃状态**，历史分区中该字段已失效，不可用于判断历史时点的活跃情况。
- `last_bid_price_*`：代表截至 `grass_date` 的最新出价，取最新分区使用。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dws_advertise_keyword_price_1d__${region}_s0_live` | 当日（`grass_date`）增量出价数据，提供当日首次出价、最新出价、出价变更次数等增量指标 |
| `mp_paidads.dws_advertise_keyword_price_td__${region}_s0_live` | 前一日（`day_before_grass_date`）的 TD 历史快照，提供历史累计出价统计值（供滚动合并） |
| `mp_paidads.dim_advertise__${region}_s0_live` | 广告维表，提供 `is_ads_active` 字段（当日广告活跃状态） |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dws_advertise_keyword_price_1d__${region}_s0_live
  (grass_date = ${grass_date}，当日增量)
              |
              |  FULL OUTER JOIN
              |  ON shop_id + ads_id + keyword
              v
mp_paidads.dws_advertise_keyword_price_td__${region}_s0_live  ──────────────────┐
  (grass_date = ${day_before_grass_date}，昨日 TD 快照)                         │
              |                                                                   │
              v                                                                   │
         [CTE: base]                                                              │
   价格字段滚动合并计算                                                           │
   (min/max/avg/cnt 累计更新)                                                    │
              |                                                                   │
              |  LEFT JOIN ON ads_id + shop_id                                   │
              v                                                                   │
mp_paidads.dim_advertise__${region}_s0_live                                      │
  (grass_date = ${grass_date}，当日广告维表)                                     │
   补充 is_ads_active 字段                                                       │
              |                                                                   │
              v                                                                   │
INSERT OVERWRITE                                                                  │
mp_paidads.dws_advertise_keyword_price_td__reg_s0_live  ◄────────────────────────┘
PARTITION(tz_type='local', grass_region, grass_date)
   (本表，今日 TD 快照写入)
```

**计算引擎：** Spark SQL（Studio 任务，task_code: `data_paidadsmart.studio_2926322`）

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `base` | `dws_advertise_keyword_price_1d`（当日增量）FULL OUTER JOIN `dws_advertise_keyword_price_td`（昨日 TD 快照） | 以 `shop_id + ads_id + keyword` 为粒度进行滚动合并：使用 COALESCE 处理新增/已有关键词；对 `min/max` 出价做逐字段比较取极值；对 `avg` 出价按变更次数加权合并；对 `bid_price_change_cnt` 做累加；对 `initial_bid_price_*` 优先保留历史值（首次出价不覆盖） |

### 注意事项

1. **自引用更新（Self-Referencing TD 模式）**：本表每日以昨日自身快照为输入之一，通过 FULL OUTER JOIN 合并当日增量后覆盖写入今日分区。若上游 1D 数据延迟或缺失，TD 值将静默保持昨日状态（不报错），需监控 1D 表的数据就绪情况。

2. **`avg_bid_price` 的加权合并逻辑**：当今日增量与历史快照均有数据时，均价计算公式为：
   ```
   avg = (历史均价 × 历史变更次数 + 当日均价 × 当日变更次数)
         / (历史变更次数 + 当日变更次数)
   ```
   直接对多行 `avg_bid_price_*` 执行 SUM 或 AVG 会得出错误结果，下游必须使用上述加权方式重新聚合。

3. **`initial_bid_price_*` vs `first_bid_price_*`**：`initial_bid_price_*` 优先取历史快照值（即生命周期首次出价，跨日不变），而 `first_bid_price_*` 仅代表当日增量中的首笔出价，两者含义不同，切勿混用。

4. **`keyword_create_timestamp` 回退逻辑**：当上游历史快照中不存在 `keyword_create_timestamp` 时，ETL 会回退使用 `last_modified_timestamp` 填充，导致该字段不保证严格为首次创建时间，使用时需注意。

5. **`is_ads_active` 的时点性**：该字段通过 LEFT JOIN `dim_advertise` 维表获取，每日覆盖写入，历史分区中的值已过期失效。只应在最新 `grass_date` 分区中使用该字段判断广告当前活跃状态。

6. **分区写入固定 `tz_type = 'local'`**：当前 ETL 硬编码写入 `local` 分区，查询时建议始终添加 `tz_type = 'local'` 过滤，以避免分区裁剪失效。

---

*文档生成时间：2026-04-22*
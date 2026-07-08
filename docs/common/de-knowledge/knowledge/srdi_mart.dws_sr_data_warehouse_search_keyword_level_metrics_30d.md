<!-- ads-workspace-gdoc-sync: gdoc_id=16FXZC9hNhZn8gxSbbJbcnjM_D80k6G9kWIFBRLapSek gdoc_url=https://docs.google.com/document/d/16FXZC9hNhZn8gxSbbJbcnjM_D80k6G9kWIFBRLapSek/edit -->

# srdi_mart.dws_sr_data_warehouse_search_keyword_level_metrics_30d

**分层：** dws_search
**主键：** keyword + card_type + is_ads + grass_region + local_date + time_range
**分区：** grass_region / local_date / time_range
**更新频率：** 每日（T+1）
**引用频次 / 访问频次：** 19,361

---

## 业务描述

本表为搜索关键词粒度的汇总宽表，记录各关键词在搜索结果页（SRP）上的曝光、点击、商品详情页访问（PPV）、加购、成单及 GMV 等核心电商漏斗指标，同时附带关键词的搜索量、搜索量排名、累计搜索量百分位及搜索量类型等关键词热度属性，以及关键词所属聚类和分类标签。

**核心业务场景：**
- 关键词搜索热度分析（搜索量排名、Top 300 关键词识别、长尾词分层）
- 搜索关键词的转化漏斗分析（曝光 → 点击 → PPV → 加购 → 成单 → GMV）
- 自然流量与广告流量的关键词效果对比（`is_ads` 维度）
- 不同卡片类型（商品卡、视频卡、直播卡）的关键词效果拆解
- 关键词类目归属分析（`level1_keyword_category` / `level2_keyword_category`）

**适合回答的典型问题：**
- 过去 30 天内搜索量最高的 Top 100 关键词是哪些？
- 某个关键词在广告 vs. 自然搜索场景下的 GMV 分别是多少？
- 某关键词所属品类在近 7 天的点击率和转化率趋势？
- 搜索量百分位在 0%–20% 区间的头部关键词列表？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点 / 地区标识（如 SG、MY、TH 等），每日按站点分区写入 |
| `local_date` | date | 数据日期，即 ETL 运行的基准日期（当日） |
| `time_range` | int | 时间窗口，取值：`1`（近 1 天）、`7`（近 7 天）、`30`（近 30 天） |

---

### 维度：关键词属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `keyword` | string | 搜索关键词（已做 trim + lower 标准化处理） |
| `keyword_cluster` | string | 关键词聚类标签，来自关键词维度表 |
| `level1_keyword_category` | string | 关键词一级类目，来自关键词维度表 |
| `level2_keyword_category` | string | 关键词二级类目，来自关键词维度表 |
| `keyword_search_volume_type` | string | 关键词搜索量分层类型，基于 `time_range=1` 时的当日搜索量计算：`1.top 300`、`2.0%-20%`、`3.20%-50%`、`4.50%-80%`、`5.80%-100%`、`6.volume=1`；`time_range=7/30` 时为 NULL |

---

### 维度：流量来源 & 卡片类型

| 字段 | 类型 | 说明 |
|---|---|---|
| `card_type` | string | 卡片类型（`item`=商品卡、`video`=视频卡、`livestream`=直播卡），含全量汇总值 `__ALL__` |
| `is_ads` | string | 是否为广告（`true` / `false`），含全量汇总值 `__ALL__` |

---

### 指标：搜索量与搜索热度排名

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_volume` | bigint | 对应 `time_range` 窗口内的去重搜索用户数（以 device_id + user_id 组合去重），即搜索量 |
| `search_volume_rank` | bigint | 当前关键词在 `level1_keyword_category` + `is_ads` + `card_type` 分组内按搜索量排名（RANK，越大搜索量越小） |
| `keyword_search_volume_rank` | bigint | 关键词在全局（全站点、全类目）按当日（1d）搜索量从高到低的 RANK 排名；`time_range=7/30` 时为 NULL |
| `keyword_cumulative_search_volume_percentile` | double | 关键词累计搜索量占全量搜索量的百分位（由高到低累计，越小表示热度越高）；`time_range=7/30` 时为 NULL |

---

### 指标：曝光

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 对应 `time_range` 窗口内的搜索结果页曝光次数 |
| `imp_uu` | bigint | 对应 `time_range` 窗口内产生曝光的去重用户数（user_id > 0） |

---

### 指标：点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `click_cnt` | bigint | 对应 `time_range` 窗口内的点击次数 |
| `click_uu` | bigint | 对应 `time_range` 窗口内产生点击的去重用户数（user_id > 0） |

---

### 指标：商品详情页访问（PPV）

| 字段 | 类型 | 说明 |
|---|---|---|
| `ppv_cnt` | bigint | 对应 `time_range` 窗口内的 PPV（Product Page View）次数 |
| `ppv_uu` | bigint | 对应 `time_range` 窗口内产生 PPV 的去重用户数（user_id > 0） |

---

### 指标：加购

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | bigint | 对应 `time_range` 窗口内的加购次数 |
| `cart_uu` | bigint | 对应 `time_range` 窗口内产生加购行为的去重用户数（user_id > 0） |

---

### 指标：成单

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 对应 `time_range` 窗口内的成单数 |
| `order_uu` | bigint | 对应 `time_range` 窗口内产生成单的去重用户数（user_id > 0） |

---

### 指标：GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv` | double | 对应 `time_range` 窗口内的 GMV（总成交金额） |
| `pc2_gmv` | double | 对应 `time_range` 窗口内的 PC2 口径 GMV |

---

### 指标：SRP 访问用户数

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_count` | bigint | 对应 `time_range` 窗口内查看搜索结果页（SRP）的去重用户数（`user_id > 0`），跨 `card_type` / `is_ads` 维度统一取全量汇总值（`__ALL__`），对所有细分维度行复用同一个关键词级别的数值 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：分区字段，查询时必须指定，否则将触发全表扫描。
- **`local_date`**：分区字段，必须指定具体日期或日期范围；该字段为数据写入的基准日期（非窗口内的具体日期）。
- **`time_range`**：分区字段，必须明确指定时间窗口（`1` / `7` / `30`），避免三个分区数据被叠加计算。

```sql
-- 典型查询模板
SELECT *
FROM srdi_mart.dws_sr_data_warehouse_search_keyword_level_metrics_30d
WHERE grass_region = 'SG'
  AND local_date = '2026-05-16'
  AND time_range = 7;
```

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_uu`、`click_uu`、`ppv_uu`、`cart_uu`、`order_uu`、`user_count` | 去重用户数，跨关键词或跨维度 SUM 会导致重复计数 |
| `search_volume` | 去重搜索用户数，跨关键词 SUM 无业务意义；跨 `time_range` SUM 严禁使用 |
| `keyword_cumulative_search_volume_percentile` | 百分位指标，直接 SUM 无意义 |
| `search_volume_rank`、`keyword_search_volume_rank` | 排名值，不可 SUM；需要重新排序时应基于 `search_volume` 重新计算 |
| `keyword_search_volume_type` | 分类标签，不可做聚合运算 |

### 时效性说明

- 本表为 **T+1 日更新**，`local_date` 对应前一自然日（基准计算日）。
- `time_range=1`：当日（`local_date` 当天）数据；`time_range=7`：以 `local_date` 为终点的近 7 天滑动窗口；`time_range=30`：以 `local_date` 为终点的近 30 天滑动窗口。
- `keyword_search_volume_rank`、`keyword_cumulative_search_volume_percentile`、`keyword_search_volume_type` **仅在 `time_range=1` 分区有效**，`time_range=7/30` 对应值均为 NULL，请勿将 7d/30d 分区的该类字段用于分析。
- `card_type` 和 `is_ads` 含 `__ALL__` 汇总行，与细分维度行并存，关联使用时需明确过滤，避免重复计算。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_search_srp_user_benchmark_1d` | 用户级搜索行为明细表，提供曝光、点击、PPV、加购、成单、GMV 等行为指标及关键词、页面类型等维度 |
| `srdi_mart.dim_sr_data_warehouse_keyword_di` | 关键词维度表，提供关键词聚类（`keyword_cluster`）、一级类目（`level1_keyword_category`）、二级类目（`level2_keyword_category`） |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_search_srp_user_benchmark_1d
        │
        ├──► [搜索量计算] dws_search_volume_30d（CACHE）
        │           │
        │           └──► keyword_search_rank_pct → keyword_search_rank_pct_type（CACHE）
        │
        └──► [用户行为汇总] dwm_search_user_keyword
                    │
                    └──► dws_keyword_30d（GROUPING SETS 展开维度）
                                │
srdi_mart.dim_sr_data_warehouse_keyword_di
        │
        └──► dim_keyword（取最新维度快照）
                    │
                    └──► [JOIN] dws_keyword_metrics（CACHE）
                                │
                                ├──► dws_search_user_cnt_30d（SRP 用户数汇总）
                                │
                                └──► INSERT OVERWRITE time_range=1
                                     INSERT OVERWRITE time_range=7
                                     INSERT OVERWRITE time_range=30
```

### 关键步骤

1. **搜索量计算（CACHE）**：从 `dws_sr_data_warehouse_search_srp_user_benchmark_1d` 过滤近 30 天数据，按 keyword 计算 1d / 7d / 30d 去重搜索用户数（`device_id, user_id` 组合去重），缓存为 `dws_search_volume_30d`。

2. **关键词热度排名（Temporary View）**：基于 1d 搜索量对关键词全局排名（`keyword_search_volume_rank`）和累计百分位（`keyword_cumulative_search_volume_percentile`），并按搜索量分层打标（`keyword_search_volume_type`），生成 `keyword_search_rank_pct_type`（CACHE）。

3. **用户行为明细汇总（Temporary View）**：从 `dws_sr_data_warehouse_search_srp_user_benchmark_1d` 过滤近 30 天数据，按 `user_id, device_id, keyword, target_type, is_ads, local_date` 聚合曝光、点击、PPV、加购、成单、GMV，生成用户级别明细 `dwm_search_user_keyword`。

4. **多时间窗口 × 多维度展开（Temporary View）**：以 GROUPING SETS 对 `dwm_search_user_keyword` 做 `(user_id, keyword, target_type, is_ads)` / `(user_id, keyword, target_type)` / `(user_id, keyword, is_ads)` / `(user_id, keyword)` 四种组合聚合，同时按窗口（1d/7d/30d）预聚合各指标，生成 `dws_keyword_30d`（含 `__ALL__` 汇总行）。

5. **关键词维度关联（CACHE）**：从 `dim_sr_data_warehouse_keyword_di` 取近 30 天最新快照（`row_number` 取最新一条），LEFT JOIN 到 `dws_keyword_30d`，并聚合为关键词 + `card_type` + `is_ads` 粒度的指标宽表 `dws_keyword_metrics`（含各时间窗口的 cnt 和 uu 指标）。

6. **SRP 用户数提取（Temporary View）**：从 `dws_keyword_metrics` 中取 `card_type='__ALL__' AND is_ads='__ALL__'` 行，提取关键词级别的 SRP 去重用户数（1d/7d/30d），生成 `dws_search_user_cnt_30d`。

7. **三次 INSERT OVERWRITE 写入目标分区**：
   - `time_range=1`：写入 1d 窗口指标，携带 `keyword_search_volume_rank`、`keyword_cumulative_search_volume_percentile`、`keyword_search_volume_type`，过滤 `is_search_1d=TRUE`。
   - `time_range=7`：写入 7d 窗口指标，上述三个热度字段为 NULL，过滤 `is_search_7d=TRUE`。
   - `time_range=30`：写入 30d 窗口指标，上述三个热度字段为 NULL，**不过滤 is_search 条件**（即写入所有近 30 天有搜索记录的关键词）。
   - 三次写入均计算 `search_volume_rank`（在 `level1_keyword_category + is_ads + card_type` 分组内的搜索量排名），并 LEFT JOIN `dws_search_user_cnt_30d` 补充 `user_count`。

### 注意事项

- **单 writer，无 multi-writer 风险**：本表仅由一个 ETL 文件写入，不存在多文件并发写入同一分区的风险。
- **三分区独立 INSERT OVERWRITE**：同一 ETL 任务内对 `time_range=1/7/30` 分别执行 INSERT OVERWRITE，分区之间相互独立，不会互相覆盖。
- **`__ALL__` 汇总行与细分行并存**：`card_type` 和 `is_ads` 均含 `__ALL__`，使用时必须明确过滤，否则汇总行与细分行同时出现导致指标翻倍。
- **`user_count` 跨维度复用**：`user_count` 来自 `card_type='__ALL__' AND is_ads='__ALL__'` 汇总行，对所有细分维度组合均赋同一关键词的全量值，不反映具体维度切片的用户数。
- **`keyword_search_volume_rank` 等热度字段仅对 `time_range=1` 有值**：7d/30d 分区该类字段写入 NULL，下游使用时需加 `time_range=1` 过滤。
- **搜索量口径统一性**：`search_volume` 基于 `device_id + user_id` 组合去重，与 `user_count`（仅 `user_id > 0`）口径不同，两者不可混用比较。
- **关键词维度表取最新快照**：`dim_keyword` 按 `local_date DESC` 取 `row_number=1`，若近 30 天内同一关键词存在多条维度记录，仅保留最新一条，历史维度变化不做回溯。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_search_srp_user_benchmark_1d` | 用户级搜索行为明细，提供关键词、页面类型、各行为指标（曝光/点击/PPV/加购/成单/GMV）及 is_ads 标记 |
| `srdi_mart.dim_sr_data_warehouse_keyword_di` | 关键词维度信息，提供关键词聚类、一级/二级类目标签 |

*文档生成时间：2026-05-17*
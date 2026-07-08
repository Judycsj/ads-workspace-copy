<!-- ads-workspace-gdoc-sync: gdoc_id=1ttjbyNhpURa-2Lw1stez-H7yGIlL-oJToYP184FTKp0 gdoc_url=https://docs.google.com/document/d/1ttjbyNhpURa-2Lw1stez-H7yGIlL-oJToYP184FTKp0/edit -->

# srdi_mart.dws_sr_data_warehouse_search_keyword_metrics_30d

**分层：** dws_search（数据仓库汇总层 - 搜索域）
**主键：** `grass_region` + `local_date` + `time_range` + `keyword` + `is_ads` + `card_type`
**分区：** `grass_region`（站点区域）/ `local_date`（业务日期）/ `time_range`（统计时间窗口）
**更新频率：** 每日更新（T+1）
**引用频次 / 访问频次：** 316

---

## 业务描述

本表是搜索关键词维度的多时间窗口汇总宽表，覆盖 **近 1 天（time_range=1）、近 7 天（time_range=7）、近 30 天（time_range=30）** 三个滚动窗口的搜索行为与转化指标。

**核心业务场景：**
- 搜索关键词的曝光、点击、加购、下单、GMV 全链路漏斗分析
- 关键词搜索量趋势追踪：通过 `search_volume` 与 `increased_search_volume` 识别新兴热词与衰退词
- 关键词热度排名（`search_volume_rank`）与增量排名（`increased_rank`）监控，支持趋势榜单产品
- 按一级 / 二级关键词品类、广告 / 自然流量（`is_ads`）、内容卡片类型（`card_type`）拆分的多维度分析
- 跨站点（`grass_region`）关键词搜索数据横向对比

**适合回答的典型问题：**
- 某站点过去 7 天搜索量 Top N 的关键词是哪些？
- 某关键词近 30 天的搜索量环比增减了多少？
- 商品/视频/直播卡片在各关键词下的点击转化漏斗表现如何？
- 某品类下搜索量增速最快的关键词有哪些？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域标识，如 `SG`、`MY`、`TH` 等；每次写入仅覆盖当前 `grass_region` 分区 |
| `local_date` | date | 业务日期（本地时区），数据统计的截止日期，格式 `yyyy-MM-dd` |
| `time_range` | int | 统计时间窗口（天数）：`1`=近 1 天，`7`=近 7 天，`30`=近 30 天 |

---

### 维度：关键词属性

| 字段 | 类型 | 说明 |
|---|---|---|
| `keyword` | string | 搜索关键词原始文本 |
| `keyword_cluster` | string | 关键词聚类分组标识，将语义相近的关键词归为同一簇 |
| `level1_keyword_category` | string | 关键词一级品类标签 |
| `level2_keyword_category` | string | 关键词二级品类标签 |
| `is_ads` | string | 是否为广告流量标识；区分付费搜索（广告）与自然搜索 |
| `card_type` | string | 搜索结果卡片类型：`item`（商品）、`video`（短视频）、`livestream`（直播）、`__ALL__`（全类型汇总） |

---

### 指标：曝光与流量

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 关键词搜索结果曝光次数（PV） |
| `imp_uu` | bigint | 关键词搜索结果曝光独立用户数（UV） |
| `search_volume` | bigint | 关键词搜索量（搜索次数），`time_range` 对应窗口内的累计值；ETL 过滤 `search_volume > 5` 的记录 |
| `search_volume_rank` | bigint | 关键词在当前 `level1_keyword_category` + `is_ads` + `card_type` + `time_range` 分组下按搜索量的排名 |
| `increased_search_volume` | bigint | 相对于上一个同等窗口期期初的搜索量增量（环比增减值）；`time_range=1` 对比前 1 天，`time_range=7` 对比前 7 天，`time_range=30` 对比前 30 天 |
| `increased_rank` | bigint | 关键词在 `level1_keyword_category` + `is_ads` + `card_type` + `time_range` 分组下按 `increased_search_volume` 降序的排名 |
| `user_count` | bigint | 该关键词的搜索用户数 |

---

### 指标：点击与互动

| 字段 | 类型 | 说明 |
|---|---|---|
| `click_cnt` | bigint | 搜索结果点击次数（PV） |
| `click_uu` | bigint | 搜索结果点击独立用户数（UV） |
| `ppv_cnt` | bigint | 商品详情页（PDP）访问次数（PV） |
| `ppv_uu` | bigint | 商品详情页访问独立用户数（UV） |

---

### 指标：转化与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `cart_cnt` | bigint | 加购次数 |
| `cart_uu` | bigint | 加购独立用户数（UV） |
| `order_cnt` | double | 下单件数（来自上游，类型为 double） |
| `order_uu` | bigint | 下单独立用户数（UV） |
| `gmv` | double | 搜索归因成交金额（GMV） |
| `pc2_gmv` | double | PC2 口径的搜索归因 GMV（不同归因窗口或去重规则下的 GMV 统计） |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须过滤 `grass_region`**：该字段为一级分区，跨站点扫描将导致全表扫描，严重影响性能。
- **必须过滤 `local_date`**：该字段为二级分区，建议指定具体日期或日期范围；不过滤将扫描全部历史分区。
- **必须过滤 `time_range`**：该字段为三级分区，分析时应明确指定所需时间窗口（`1`、`7` 或 `30`），避免三个窗口数据叠加导致重复计算。
- **推荐过滤 `card_type`**：表中同时包含 `item`、`video`、`livestream` 及 `__ALL__` 汇总行，若不过滤将产生重复聚合；如需全局合计，使用 `card_type = '__ALL__'`；如需分类型分析，排除 `__ALL__`。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_uu`、`click_uu`、`ppv_uu`、`cart_uu`、`order_uu`、`user_count` | UV / 去重用户数，跨关键词或跨维度 SUM 会导致重复计数，不能直接累加 |
| `search_volume_rank`、`increased_rank` | 排名字段，为预计算窗口函数结果，直接 SUM / AVG 无业务意义 |
| `increased_search_volume` | 环比增量为差值派生指标，跨时间窗口或跨关键词累加无意义 |
| `pc2_gmv` | 特定归因口径 GMV，与 `gmv` 同时 SUM 会产生口径混用 |

### 时效性说明

- 本表为 **T+1 每日批量更新**，`local_date` 为数据截止日期，当日数据通常于次日更新完成。
- `time_range` 字段代表滚动窗口长度，并非累计（TD）口径；`time_range=30` 表示截至 `local_date` 的近 30 天滚动累计，不是自然月。
- `increased_search_volume` 与 `increased_rank` 仅在 `time_range=1` 时为日环比，`time_range=7/30` 时分别为周环比和月环比。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_search_keyword_level_metrics_30d` | 主要数据源，提供关键词级别的各时间窗口曝光、点击、转化指标及搜索量；ETL 中同时读取当前日期与前 N 天日期的数据，用于计算搜索量环比增量 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_search_keyword_level_metrics_30d
    │
    ├─── [local_date 当前日期 & 前1/7/30天] ──→ Temp View: dws_increased_search_volume（环比增量）
    │
    └─── [local_date 当前日期，search_volume > 5] ──→ Temp View: base_keyword（当日基础指标）
                                                            │
                                                            ├─ LEFT JOIN dws_increased_search_volume
                                                            │
                                                            └──→ Temp View: increased_rank（附加增量排名）
                                                                        │
                                                                        └──→ INSERT OVERWRITE 目标表（按 grass_region + local_date + time_range 分区）
```

### 关键步骤

**Step 1 — Temporary View `dws_increased_search_volume`**
从上游表分别读取 `time_range = 1/7/30` 三段数据，每段取当前日期与前 N 天两个日期的 `search_volume`，使用条件聚合（`MAX(IF(...))`）计算当日 vs 前 N 天的搜索量差值，得到 `increased_search_volume`；三段结果 UNION ALL 合并。过滤条件：`card_type IN ('item','video','livestream','__ALL__')`，`time_range` 对应各段窗口值。

**Step 2 — Temporary View `base_keyword`**
从上游表读取 `local_date = 当前日期` 的当日快照数据，提取所有度量字段；过滤条件：`card_type IN ('item','video','livestream','__ALL__')`，`search_volume > 5`（过滤低频词）。

**Step 3 — Temporary View `increased_rank`**
将 `base_keyword` 与 `increased_search_volume` 按 `keyword + is_ads + card_type + time_range` 左连接，补充 `increased_search_volume`；同时使用窗口函数 `RANK() OVER (PARTITION BY level1_keyword_category, is_ads, card_type, time_range ORDER BY increased_search_volume DESC)` 计算 `increased_rank`。

**Step 4 — INSERT OVERWRITE 目标表**
将 `increased_rank` 视图数据写入目标表，按 `grass_region`（静态分区）、`local_date`（静态分区）、`time_range`（动态分区）三级分区 `INSERT OVERWRITE`，每次运行覆盖当前 `grass_region + local_date` 下的全部 `time_range` 分区数据。

### 注意事项

- **单 Writer，无 multi-writer 风险**：本表由单个 ETL 文件写入，不存在多文件并发写同一分区的竞争问题。
- **分区覆盖范围**：`INSERT OVERWRITE` 采用静态 `grass_region` + 静态 `local_date` + 动态 `time_range`，每次执行将覆盖该站点该日期下 `time_range` 的全部三个分区（1/7/30），请勿对单一 `time_range` 分区单独重跑，否则其余两个窗口分区将被清空。
- **低频词过滤**：`base_keyword` 阶段过滤了 `search_volume ≤ 5` 的关键词，目标表不包含极低频词数据，下游分析时需知悉此阈值。
- **`increased_search_volume` 计算口径**：若上一个对比日期（前 1/7/30 天）无数据，`COALESCE(..., 0)` 将缺失值补 0，即新词的增量等于当日搜索量，需注意新词与真实增长词的区分。
- **参数化执行**：ETL SQL 使用 `${grass_region}`、`${local_date}` 等参数，Temporary View 名称中亦含 `${grass_region_without_quote}`，表明该作业按站点逐个调度执行。

---

*文档生成时间：2026-05-17*
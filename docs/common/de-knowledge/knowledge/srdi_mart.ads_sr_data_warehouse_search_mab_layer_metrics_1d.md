<!-- ads-workspace-gdoc-sync: gdoc_id=1GN6waZ7DeYBTGkBh8zgEEwF8CVKqlw6YbTDeiC_aVU0 gdoc_url=https://docs.google.com/document/d/1GN6waZ7DeYBTGkBh8zgEEwF8CVKqlw6YbTDeiC_aVU0/edit -->

# srdi_mart.ads_sr_data_warehouse_search_mab_layer_metrics_1d

**分层**：ADS（应用数据层）
**主键**：`grass_region` + `local_date` + `card_type` + `level1_global_be_category_id` + `has_video` + `skip_mab` + `has_order` + `cum_order_prop_layer` + `avg_video_org_competiveness_layer` + `avg_video_roi2_competiveness_layer` + `best_video_org_competiveness_layer` + `best_video_roi2_competiveness_layer` + `main_type`
**分区**：`grass_region`（站点大区）、`local_date`（业务日期）
**更新频率**：每日一次（T+1）
**引用频次 / 访问频次**：2104

---

## 业务描述

本表是搜索 MAB（Multi-Armed Bandit，多臂老虎机）卡片层级（Layer）的**日粒度聚合指标表**，服务于搜索推荐数仓中对视频卡与图文卡在 MAB 机制下的**效果分析与竞争力评估**。

核心业务场景：
- **视频卡 vs 图文卡竞争力分析**：通过 `avg_video_org_competiveness_layer`、`best_video_org_competiveness_layer` 等字段，衡量视频卡相对自然（organic）图文卡及 ROI2.0 广告图文卡的 CTR×CR 比值，并按区间分层（`<80%` 至 `>=200%`），支持分桶分析。
- **商品多维度切片**：支持按类目（`level1_global_be_category`）、是否含视频（`has_video`）、是否跳过 MAB（`skip_mab`）、是否有成单（`has_order`）、累计成单分位层（`cum_order_prop_layer`）、内容主类型（`main_type`）等维度灵活下钻。
- **曝光与成单占比分析**：`imp_pct`、`order_pct` 表示各切片在同卡型全量中的曝光/成单占比，可用于评估特定分层商品的流量权重。
- **平均图文数 / 视频数统计**：`avg_image_cnt`、`avg_video_cnt` 反映各分组商品平均挂载的图文/视频素材数量。

适合回答的问题：
- 各站点、各类目下，视频卡相对图文卡的竞争力分布如何？
- 跳过 MAB 的商品（`skip_mab=true`）占整体曝光的比重是多少？
- 累计成单前 10% 的商品，其视频卡 vs ROI2.0 图文卡的竞争力处于哪个区间？
- 不同卡型（video/item）在各维度组合下的 GMV、点击、曝光量如何分布？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区，如 `SG`、`MY` 等，同时作为分区键 |
| `local_date` | date | 业务日期（本地时区），同时作为分区键 |

### 维度：卡片与商品基础维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `card_type` | string | 卡片类型，枚举值包含 `video`（视频卡）、`item`（图文卡）及 `__ALL__`（全部汇总） |
| `main_type` | string | 商品主要内容类型，基于图文数与视频数大小关系派生：`image`（图文为主）、`video`（视频为主）、`others`（相等或无法判断） |
| `has_video` | string | 商品是否挂载视频，`true` / `false`；`__ALL__` 表示汇总行 |
| `skip_mab` | string | 该商品是否跳过 MAB 机制，`true` / `false`；`__ALL__` 表示汇总行 |
| `has_order` | string | 商品当日是否有成单记录，`true` / `false`；`__ALL__` 表示汇总行 |

### 维度：类目维度

| 字段 | 类型 | 说明 |
|---|---|---|
| `level1_global_be_category_id` | string | 全球一级后端类目 ID；`__ALL__` 表示跨类目汇总行 |
| `level1_global_be_category` | string | 全球一级后端类目名称；类目 ID 无法关联时填充 `__ALL__` |

### 维度：累计成单分位层

| 字段 | 类型 | 说明 |
|---|---|---|
| `cum_order_prop_layer` | string | 商品按累计成单占比分位分层，枚举值：`top10%` / `top20%` / … / `top100%`；`__ALL__` 表示汇总行 |

### 维度：视频卡竞争力分层

| 字段 | 类型 | 说明 |
|---|---|---|
| `avg_video_org_competiveness_layer` | string | 视频卡**平均** CTR×CR 相对自然图文卡的竞争力分层。枚举值：`<80%` / `80%-100%` / `100%-120%` / `120%-140%` / `140%-160%` / `160%-180%` / `180%-200%` / `>=200%` / `>100%`（is_avg_video_org_100p=true 聚合行）/ `overall`（两者均有曝光的聚合行）/ `NULL` / `__ALL__` |
| `avg_video_roi2_competiveness_layer` | string | 视频卡**平均** CTR×CR 相对 ROI2.0 广告图文卡的竞争力分层，分层规则同上 |
| `best_video_org_competiveness_layer` | string | 视频卡**最优素材** CTR×CR 相对自然图文卡最优素材的竞争力分层，分层规则同上 |
| `best_video_roi2_competiveness_layer` | string | 视频卡**最优素材** CTR×CR 相对 ROI2.0 广告图文卡最优素材的竞争力分层，分层规则同上 |

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 该分组的总曝光次数（PV）；仅统计 `content_id = '__ALL__'` 的汇总行 |
| `imp_item_cnt` | bigint | 该分组中曝光次数 > 0 的商品数（UV 维度） |
| `click_cnt` | bigint | 该分组的总点击次数 |
| `imp_pct` | double | 该分组曝光量占同卡型全量曝光的比例（`imp_cnt / 同卡型全局 imp_cnt`）；为比率字段，**不可直接 SUM** |

### 指标：成单与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 该分组的总成单量 |
| `order_pct` | double | 该分组成单量占同卡型全量成单的比例（`order_cnt / 同卡型全局 order_cnt`）；为比率字段，**不可直接 SUM** |
| `gmv` | double | 该分组的总 GMV |

### 指标：素材数均值

| 字段 | 类型 | 说明 |
|---|---|---|
| `avg_image_cnt` | double | 分组内图文卡商品的平均图片素材数（`Σ content_id 去重数 / Σ item 数`，仅对 `card_type='item'` 统计）；为预聚合均值，**不可直接 SUM** |
| `avg_video_cnt` | double | 分组内视频卡商品的平均视频素材数（`Σ content_id 去重数 / Σ item 数`，仅对 `card_type='video'` 统计）；为预聚合均值，**不可直接 SUM** |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须同时指定**：`WHERE grass_region = '<站点>' AND local_date = '<日期>'`，缺少任一分区条件均会导致全表扫描，影响性能及费用。
- 本表为**日粒度快照表**，每个分区存储对应站点当日数据；查询多日趋势需枚举或范围过滤 `local_date`。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_pct` | 比率字段，由 `imp_cnt / 同卡型全局曝光` 计算，跨分组直接 SUM 无业务意义 |
| `order_pct` | 比率字段，由 `order_cnt / 同卡型全局成单` 计算，跨分组直接 SUM 无业务意义 |
| `avg_image_cnt` | 预聚合均值，跨分组 SUM 不等于真实均值；需使用上游分子/分母重新计算 |
| `avg_video_cnt` | 预聚合均值，同上 |

### `__ALL__` 汇总行说明

- 本表通过 `CUBE` 算子产生多维汇总行，维度字段值为 `__ALL__` 表示该维度未过滤（全量聚合），直接过滤查询时需明确排除汇总行或仅使用汇总行，避免重复计数。
- 竞争力分层字段（`*_competiveness_layer`）中，`overall` 表示视频卡与对比图文卡均有曝光的聚合行，`>100%` 表示视频卡胜出的聚合行，两者与细分区间行**不可混合 SUM**。

### 时效性说明

- 后缀 `_1d` 表示日粒度表，通常 T+1 更新，当日数据需次日方可查询。
- 不含累计（`*_td`）或滑动窗口（`*_nd`）语义，每个分区为独立当日快照。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_search_card_mab_analysis_1d` | 主数据源，提供商品级别的 MAB 卡片曝光、点击、成单、GMV、CTR×CR、累计成单分位等原始指标，同时用于计算分母（`pct_denominator`）及类目映射（`dim_item_cat`） |

---

## ETL 逻辑摘要

### 数据流

```
dws_sr_data_warehouse_search_card_mab_analysis_1d
        │
        ├─► raw_dim_and_metrics          （商品级原始指标聚合，content_id='__ALL__' 行）
        │
        ├─► dim_item_cat                 （类目 ID → 类目名称映射）
        │
        ├─► calculated_dim_raw           （商品级竞争力原始比值 & 素材数计算）
        │        │
        │        ▼
        │   calculated_dim_mid           （竞争力比值分层 & 100p/overall 标记）
        │        │
        │        ▼
        │   calculated_dim               （竞争力区间分层字符串 & main_type 生成）
        │
        ├─► pct_denominator              （卡型级全局曝光/成单分母）
        │
        ▼
raw_join_calculated_dim                  （商品维度与指标 JOIN）
        │
        ▼
grouped_metrics_mid                      （CUBE 多维聚合，含分子/分母中间值）
        │
        ▼
grouped_metrics                          （二次 CUBE 聚合，竞争力维度折叠 & HAVING 过滤）
        │
        ▼
INSERT OVERWRITE → ads_sr_data_warehouse_search_mab_layer_metrics_1d
（JOIN dim_item_cat 补充类目名称，JOIN pct_denominator 计算 imp_pct/order_pct，
 计算 avg_image_cnt / avg_video_cnt）
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| 1 | `raw_dim_and_metrics` | 从 DWS 层按 `item_id`、`has_video`、`skip_mab`、`card_type`、`level1_global_be_category_id` 聚合，取 `content_id='__ALL__'` 行的曝光/点击/成单/GMV，同时统计每个商品的 `content_id` 去重数（素材数） |
| 2 | `dim_item_cat` | 从 DWS 层提取全量类目 ID→类目名称映射（`card_type='__ALL__'` 且 `content_id='__ALL__'`），用于最终 JOIN 补充类目名称 |
| 3 | `calculated_dim_raw` | 按 `item_id` 聚合，计算视频卡/自然图文卡/ROI2.0图文卡的平均/最优 CTR×CR，以及图片数/视频数素材数量 |
| 4 | `calculated_dim_mid` | 基于 `calculated_dim_raw`，计算成单分位分层（`cum_order_prop_layer`）、竞争力比值（含除法），以及 `is_*_100p`（是否超过100%）、`is_overall_*`（双方是否均有曝光）标记 |
| 5 | `calculated_dim` | 将竞争力连续比值转换为区间字符串分层（`<80%`~`>=200%`），生成 `main_type`（image/video/others） |
| 6 | `raw_join_calculated_dim` | 将 `raw_dim_and_metrics`（指标）与 `calculated_dim`（维度）按 `item_id` INNER JOIN，得到商品级完整宽表 |
| 7 | `grouped_metrics_mid` | 对 `card_type` 固定分组，对 `level1_global_be_category_id`、`has_video`、`skip_mab`、`has_order`、`cum_order_prop_layer` 做 CUBE 多维汇总，同时保留竞争力分层标记列，计算 `imp_item_cnt`、汇总 `imp_cnt`/`click_cnt`/`order_cnt`/`gmv`，以及 `avg_image_cnt`/`avg_video_cnt` 的分子分母 |
| 8 | `grouped_metrics` | 对竞争力相关标记列再做 CUBE，并通过 HAVING 过滤保留有效组合（每个竞争力维度只保留：原始区间行、`overall` 行、`>100%` 行三者之一），将标记列折叠为最终竞争力分层字符串 |
| 9 | `pct_denominator` | 从 DWS 层按 `card_type` 汇总全局曝光量与成单量，作为 `imp_pct`/`order_pct` 的分母 |
| 10 | `INSERT OVERWRITE` | 将 `grouped_metrics` LEFT JOIN `dim_item_cat`（补类目名）、LEFT JOIN `pct_denominator`（算占比），最终计算 `avg_image_cnt`、`avg_video_cnt`、`order_pct`、`imp_pct`，写入目标表对应分区 |

### 注意事项

- **单 Writer**：本表仅有 1 个 ETL 文件，不存在多 Writer 并发写入风险。
- **分区覆盖写入**：采用 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)` 动态分区写入，重跑时会全量覆盖对应分区，幂等安全。
- **CUBE 展开行数膨胀**：两层 CUBE（5 个维度 + 12 个竞争力标记）会产生大量组合行，第二层通过 HAVING 大幅剪枝，最终落表行数合理，但中间视图内存压力较大，调度时需注意资源配置。
- **`avg_image_cnt` / `avg_video_cnt` 精度**：最终值由分子/分母相除得出，若分母为 0（无对应卡型商品）则结果为 NULL 或产生除零异常，使用时需注意。
- **竞争力层字段语义复合**：`*_competiveness_layer` 字段同时包含细分区间值（`<80%`~`>=200%`）、`>100%`（胜出汇总）、`overall`（全覆盖汇总）、`NULL`、`__ALL__`（CUBE 汇总），查询时需明确过滤目标语义，切勿混用。
- **参数化执行**：SQL 中使用 `${grass_region}`、`${local_date}`、`${grass_region_without_quote}` 等 Spark 参数，Temporary View 名称含站点后缀，支持同一 Job 内多站点并行执行而互不干扰。

---

*文档生成时间：2026-05-17*
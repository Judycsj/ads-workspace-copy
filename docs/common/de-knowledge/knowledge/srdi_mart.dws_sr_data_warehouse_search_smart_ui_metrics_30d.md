<!-- ads-workspace-gdoc-sync: gdoc_id=1ST_5bsPsIJvekj3lEGAdZH9MPbnVDqWA8Ofb7voDCeI gdoc_url=https://docs.google.com/document/d/1ST_5bsPsIJvekj3lEGAdZH9MPbnVDqWA8Ofb7voDCeI/edit -->

# srdi_mart.dws_sr_data_warehouse_search_smart_ui_metrics_30d

**分层：** dws_search（数据仓库服务层 - 搜索域）
**主键：** `user_id` + `item_id` + `image_id` + `grass_region` + `local_date`
**分区：** `grass_region`（站点/区域），`local_date`（日期）
**更新频率：** 每日一次（T+1 覆盖写入）
**引用频次 / 访问频次：** 2546

---

## 业务描述

本表为搜索域 Smart UI（智能图片 UI）模块的 **30 天宽窗口汇总表**，以 `(user_id, item_id, image_id)` 粒度记录每张搜索结果图片在最近 30 天和当日的曝光、点击、成单、GMV 等核心电商指标，同时融合算法侧多天累计 CTR 数据及图片属性标签（是否主图、是否 AIGC 图片、是否最优 CTR 图片等）。

**核心业务场景：**
- 搜索 Smart UI 图片效果评估：对比不同图片（主图 vs 非主图、AIGC 图 vs 普通图）在曝光、点击、转化维度的差异；
- 图片 CTR 最优筛选：基于算法侧长周期 CTR 排名，识别每个 item 的最优展示图片；
- 搜索广告（Ads）与自然结果的图片效果对比；
- 30 天滚动窗口趋势分析，支撑 Smart UI 策略迭代与 A/B 效果验证；
- 用户粒度的搜索行为-商品图片关联分析。

**适合回答的问题：**
- 某站点最近 30 天内，AIGC 生成图片相比普通图片的点击率差异如何？
- 算法推荐的最优 CTR 图片（`is_best_ctr=true`）是否带来更高的成单率？
- 某商品所有候选图片中，哪张图片在近 N 天累计曝光超过 100 次且 CTR 最高？
- 不同图片宽高比（`image_aspect_ratio`）对点击转化的影响？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/区域标识（如 SG、MY 等），每个分区独立写入 |
| `local_date` | date | 数据日期（当日），即 ETL 运行的业务日期，每日覆盖写入 |

### 维度：实体标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `user_id` | bigint | 用户 ID；ETL 过滤 `user_id > 0`，排除无效用户 |
| `item_id` | bigint | 商品 ID |
| `image_id` | string | 图片 ID，与 `item_id` 共同标识一张候选展示图片 |

### 维度：图片属性标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_cover_image` | boolean | 是否为商品主图（封面图）；通过与商品维表的第一张图片匹配判断 |
| `is_aigc_image` | boolean | 是否为 AIGC 生成图片；依据 AIGC 素材库（含背景生成、贴纸、换装等多种 library）进行标记 |
| `is_best_ctr` | boolean | 是否为该商品算法侧最优 CTR 图片；满足：在 item 维度 CTR 排名第 1 且算法累计曝光 ≥ 100 次、累计点击 > 0 次 |
| `is_ads` | boolean | 是否为广告（Ads）流量 |
| `image_aspect_ratio` | string | 图片宽高比类型（如正方形、竖图等） |
| `target_type` | string | 图片目标类型，标识图片的投放/展示场景分类 |

### 维度：商品与图片状态

| 字段 | 类型 | 说明 |
|---|---|---|
| `xui_item_status` | int | XUI 商品状态码，标识商品在 Smart UI 流程中的状态 |
| `xui_image_stage` | int | XUI 图片所处阶段码，标识图片在 Smart UI 流程中的处理阶段 |

### 指标：当日（1d）电商行为

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt_1d` | bigint | 当日曝光次数（`local_date` 当天） |
| `click_cnt_1d` | bigint | 当日点击次数 |
| `order_cnt_1d` | double | 当日成单数 |
| `gmv_1d` | double | 当日 GMV（成交金额） |

### 指标：近 30 天（30d）电商行为

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt_30d` | bigint | 近 30 天（含当日）累计曝光次数，滚动窗口汇总 |
| `click_cnt_30d` | bigint | 近 30 天累计点击次数 |
| `order_cnt_30d` | double | 近 30 天累计成单数 |
| `gmv_30d` | double | 近 30 天累计 GMV |

### 指标：算法侧长周期（nd）CTR 数据

| 字段 | 类型 | 说明 |
|---|---|---|
| `algo_imp_cnt_nd` | bigint | 算法侧累计曝光次数（跨自然月，覆盖月粒度表历史数据 + 近期日粒度数据，2023 年 4 月起至上月末，再 UNION 当月每日数据） |
| `algo_click_cnt_nd` | bigint | 算法侧累计点击次数，与 `algo_imp_cnt_nd` 同源，用于计算长周期 CTR |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须同时指定**：查询时务必携带 `grass_region` 和 `local_date` 过滤，避免全表扫描：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-01-15'
  ```
- `local_date` 每日覆盖写入，每个分区代表截止当天的 30 天滚动窗口快照，**不同 `local_date` 分区之间的指标存在天数重叠**，不可跨分区直接叠加。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_cnt_30d` / `click_cnt_30d` / `order_cnt_30d` / `gmv_30d` | 已是 30 天滚动窗口预聚合值，跨 `local_date` 分区叠加会导致重复计数 |
| `algo_imp_cnt_nd` / `algo_click_cnt_nd` | 算法侧长周期累计值，时间窗口与业务 30d 窗口不同，不可与 `_30d` 指标混合求和 |
| `is_best_ctr` | 布尔派生字段，基于 item 内排名计算，跨 item 或跨分区聚合无业务意义 |
| CTR 等比率指标 | 本表不直接存储 CTR，若需计算请用 `click_cnt / imp_cnt`，不可对分子分母分别 SUM 后再相除（需注意分母为零） |

### 时效性说明

- 本表为 **T+1 每日快照表**，`local_date` 为最新可用业务日期，通常滞后 1 天；
- `_30d` 指标窗口为 `[local_date - 29, local_date]`，共 30 天，随 `local_date` 滚动；
- `algo_*_nd` 的时间覆盖范围为 2023 年 4 月起至 `local_date`（月粒度表覆盖至上月末，日粒度表覆盖当月至当日），实际 N 天数随日期增长；
- 当日（`_1d`）指标与 30d 指标同源，`_1d` 是对 30d 数据中 `local_date = 当日` 的条件过滤聚合。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_search_smart_ui_metrics_1d` | 主要数据源，提供近 30 天每日粒度的用户-商品-图片曝光、点击、成单、GMV 指标 |
| `search_algo.search_personalized_ui_metrics_month` | 算法侧月粒度 CTR 数据（2023 年 4 月起至上月末），用于计算长周期 `algo_*_nd` 指标 |
| `search_algo.search_personalized_ui_metrics_di` | 算法侧日粒度 CTR 数据（当月至当日），补充月粒度表未覆盖的最近时段 |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维表，取商品第一张图片作为主图（`is_cover_image` 判断依据） |
| `szci_mmu.smart_ui_search_creative_placement_tab__reg_daily_s0_live` | AIGC 素材库表，用于标记图片是否为 AIGC 生成（`is_aigc_image` 判断依据） |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_search_smart_ui_metrics_1d  (近 30 天)
    │
    ├──► [dws_smart_ui_1d]          近 30 天主指标聚合（1d + 30d 双窗口）
    │
    └──► [dws_1d_data]              当日有曝光的 item_id 集合（用于过滤）
            │
search_algo.search_personalized_ui_metrics_month
search_algo.search_personalized_ui_metrics_di
    │
    └──► [dws_image_item_nd]        算法侧长周期曝光点击（月+日 UNION）
            │
            └──► [dws_restrict_item_nd]   限定当日有曝光的 item，按 item 计算 CTR 排名

srdi_mart.dim_sr_data_warehouse_item
    └──► [cover_image]              取各商品第一张图作为主图 image_id

szci_mmu.smart_ui_search_creative_placement_tab__reg_daily_s0_live
    └──► [aigc_image]               当日 AIGC 图片 ID 集合

[dws_smart_ui_1d] LEFT JOIN [dws_restrict_item_nd]
                 LEFT JOIN [cover_image]
                 LEFT JOIN [aigc_image]
    │
    └──► INSERT OVERWRITE srdi_mart.dws_sr_data_warehouse_search_smart_ui_metrics_30d
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| Step 1 | `dws_smart_ui_1d` | 从 1d 明细表读取近 30 天数据，按 `(user_id, item_id, image_id, ...)` 分组，同时计算 `_1d`（仅当日）和 `_30d`（全窗口）两套聚合指标 |
| Step 2 | `dws_1d_data` | 从 1d 明细表取当日有曝光（`imp_cnt > 0`）且有效用户（`user_id > 0`）的 `item_id` 集合，作为算法侧数据的过滤白名单 |
| Step 3 | `dws_image_item_nd` | UNION ALL 月粒度算法表（2023-04 起至上月末）+ 日粒度算法表（当月至当日），构建算法侧长周期图片曝光点击数据 |
| Step 4 | `dws_restrict_item_nd` | 对 Step 3 结果限定在 Step 2 的 item 白名单内，按 `(item_id, image_id)` 聚合 `algo_imp_cnt_nd` 和 `algo_click_cnt_nd`，并用 `RANK()` 计算每个 item 内按 CTR（满足 imp≥100 且 click>0）的图片排名 |
| Step 5 | `cover_image` | 从商品维表取当日数据，提取每个商品 images 字段第一张图片 ID，作为主图判断依据 |
| Step 6 | `aigc_image` | 从 AIGC 素材库取当日指定 library_name 的图片 ID 集合 |
| Step 7（最终写入） | — | 以 `dws_smart_ui_1d` 为主表，分别 LEFT JOIN `dws_restrict_item_nd`（算法指标+CTR 排名）、`cover_image`（主图判断）、`aigc_image`（AIGC 判断），派生 `is_cover_image`、`is_aigc_image`、`is_best_ctr` 布尔标签后，`INSERT OVERWRITE` 目标分区 |

### 注意事项

- **单一写入器**：本表仅有 1 个 ETL 文件写入，无 multi-writer 风险；每次执行为 `INSERT OVERWRITE` 指定 `(grass_region, local_date)` 分区，历史分区数据安全。
- **`is_best_ctr` 派生逻辑严格**：需同时满足 `item_ctr_rank = 1`、`algo_imp_cnt_nd >= 100`、`algo_click_cnt_nd > 0`，三个条件缺一不可；算法侧数据仅覆盖当日有曝光的 item（由 `dws_1d_data` 白名单过滤），未在当日出现曝光的 item 其 `algo_*_nd` 字段将为 NULL，`is_best_ctr` 为 false。
- **`_1d` 与 `_30d` 同源**：两类指标均来自同一张 1d 明细表，`_1d` 是对 `_30d` 数据的条件过滤子集，若 `_1d` 为 NULL 表示当日无该维度记录。
- **算法侧时间窗口边界**：月粒度表覆盖至"上月末"，日粒度表覆盖"当月首日至当日"，两者拼接保证无缝衔接，但需注意月粒度表最早仅覆盖 `202304`，更早历史数据不纳入计算。
- **user_id 过滤**：ETL 在读取 1d 明细时已过滤 `user_id > 0`，目标表中不会出现无效用户数据。

---

*文档生成时间：2026-05-17*
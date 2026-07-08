<!-- ads-workspace-gdoc-sync: gdoc_id=1vr_EOtNBdPYNpyt89Taq1WWrUGkB1x_ptK9FTtEnUMU gdoc_url=https://docs.google.com/document/d/1vr_EOtNBdPYNpyt89Taq1WWrUGkB1x_ptK9FTtEnUMU/edit -->

# srdi_mart.dws_sr_data_warehouse_search_card_mab_analysis_1d

**分层：** dws_search
**主键：** item_id + content_id + card_type + sub_product_type + grass_region + local_date（多维 GROUPING SETS 展开，行级唯一由各维组合决定）
**分区：** grass_region, local_date
**更新频率：** 每日（T+1 全量覆盖写入，按分区 INSERT OVERWRITE）
**访问频次：** 516

---

## 业务描述

本表面向搜索场景下的 **卡片维度 × 商品维度 MAB（Multi-Armed Bandit）效果分析**，每日按大区（`grass_region`）和日期（`local_date`）分区产出。

核心业务场景：

1. **搜索流量效果评估**：覆盖 `global_search`、`search_in_pdp`、`search_prefill` 三类搜索页，对 item 卡、视频卡、直播卡的曝光、点击、订单、GMV 做按日汇总。
2. **MAB 候选池管理**：通过 `skip_mab` 字段标识商品是否已进入搜索视频竞争候选池（`search_video_competitive_item_candidate`），辅助 MAB 算法策略评估。
3. **视频内容新旧程度分析**：计算视频内容发布距统计日的天数差，标记 `is_new_video`（发布 ≤ 13 天为新视频），支持新旧视频差异化运营分析。
4. **商品订单排名与分位数**：对全量 item 按 `order_cnt` 排名，输出 `item_order_rank`、`item_order_quantile`、`item_cum_order_prop`（累积订单占比），支持商品漏斗分析和头部效应评估。
5. **图片卡 / 视频卡内容排名**：对同一商品下各图片内容（image）和视频内容（video）按 `ctr_x_cr` 排名，输出 `image_ctr_x_cr_rank` / `video_ctr_x_cr_rank`，支持素材优选决策。

**适合回答的问题举例：**

- 某大区某日，搜索视频卡商品的 CTR、CR、CTR×CR 表现如何？
- 哪些商品已跳过 MAB 候选，其 GMV 贡献占比是多少？
- 指定商品下各视频内容的 CTR×CR 排名及是否为新视频？
- 某一级类目下，图片卡和视频卡商品的累积订单分布？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识，如 `ID`、`TH`、`MY` 等，所有查询必须指定 |
| `local_date` | date | 业务统计日期（本地时区），所有查询必须指定 |

### 维度：商品与类目

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，主维度 |
| `level1_global_be_category` | string | 商品一级全球后台类目名称，来自 `srdi_mart.dim_sr_data_warehouse_item` |
| `level1_global_be_category_id` | bigint | 商品一级全球后台类目 ID |

### 维度：卡片与内容

| 字段 | 类型 | 说明 |
|---|---|---|
| `card_type` | string | 搜索卡片类型，取值包括 `item`（图片卡）、`video`（视频卡）、`livestream`（直播卡）；GROUPING SETS 汇总行填充 `__ALL__` |
| `content_id` | string | 内容 ID；图片卡时为 `image_id`，视频卡时为视频 `content_id`，否则为 `NA`；汇总行填充 `__ALL__` |
| `sub_product_type` | string | 广告子产品类型（来自 `mp_paidads.dim_advertise__reg_s0_live`）；非广告流量为 `not_ads`，无法匹配时为 `NA`；汇总行填充 `__ALL__` |

### 维度：商品属性标记

| 字段 | 类型 | 说明 |
|---|---|---|
| `has_video` | boolean | 商品是否关联了 Shopee 视频内容（通过 `video.video_mart_dim_content_item_bind_df` 关联判断）|
| `skip_mab` | boolean | 商品是否在搜索视频 MAB 竞争候选池中（来自 `search_algo.search_video_competitive_item_candidate`，命中则为 `TRUE`，表示该商品已被纳入候选池跳过常规 MAB）|
| `is_new_video` | boolean | 视频内容是否为新视频；发布日期距统计日 ≤ 13 天为 `TRUE`，> 13 天为 `FALSE`，无法获取发布日期时为 `NULL`；仅在 `card_type = 'video'` 且 `content_id != '__ALL__'` 的行中有值 |
| `post_date` | date | 视频内容发布日期，来自 `video.video_mart_dim_content`；仅在 `card_type = 'video'` 且 `content_id != '__ALL__'` 的行中有值，其余行为 `NULL` |

### 指标：流量与转化基础指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数；仅直接曝光事件汇总，跨 source 归因的 video/livestream 订单行该字段为 `NULL` |
| `click_cnt` | bigint | 点击次数；同上，跨 source 归因行为 `NULL` |
| `order_cnt` | double | 订单数，包含直接触达及通过 source1/source2 归因的间接订单 |
| `gmv` | double | 下单 GMV（place_order_gmv），含归因链路 |
| `pc2_gmv` | double | PC2 口径 GMV，含归因链路 |

### 指标：派生比率指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `ctr` | double | 点击率，计算公式：`click_cnt / imp_cnt`；分母为 0 时取 0。**不可直接跨行 SUM** |
| `cr` | double | 点击转化率，计算公式：`order_cnt / click_cnt`；分母为 0 时取 0。**不可直接跨行 SUM** |
| `ctr_x_cr` | double | 曝光转化率，计算公式：`order_cnt / imp_cnt`；分母为 0 时取 0。**不可直接跨行 SUM** |

### 指标：排名与分位数指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_order_rank` | bigint | 商品在当日全量商品中按 `order_cnt` 降序的排名；仅 `card_type = '__ALL__'`、`content_id = '__ALL__'`、`sub_product_type = '__ALL__'` 的全汇总行有值，其余行为 `NULL`。**不可 SUM** |
| `item_order_quantile` | double | 商品订单排名分位数，计算公式：`item_order_rank / MAX(item_order_rank)`，值域 (0, 1]。**不可 SUM** |
| `item_cum_order_prop` | double | 商品累积订单占比，计算公式：按 `item_order_rank` 升序累积 `order_cnt` / 当日全量总 `order_cnt`，反映头部商品集中度。**不可 SUM** |
| `image_ctr_x_cr_rank` | bigint | 同一商品下图片内容（`card_type = 'item'`）按 `ctr_x_cr` 降序的排名，分区键为 `item_id + sub_product_type + card_type`；仅图片卡内容明细行有值。**不可 SUM** |
| `video_ctr_x_cr_rank` | bigint | 同一商品下视频内容（`card_type = 'video'`）按 `ctr_x_cr` 降序的排名，分区键为 `item_id + sub_product_type + card_type`；仅视频卡内容明细行有值。**不可 SUM** |

---

## 查询使用须知

### 必须指定的过滤条件

- **`grass_region`** 和 **`local_date`** 为分区字段，查询时必须同时显式过滤，否则触发全表扫描。
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2024-01-01'
  ```

### GROUPING SETS 展开行说明

- 本表通过 `GROUPING SETS` 产出多粒度汇总行，**同一 `item_id` 对应多行**，不可直接 `COUNT(DISTINCT item_id)` 或对指标直接 `SUM`，需先按业务所需维度组合精确过滤。
- `card_type`、`content_id`、`sub_product_type` 三个字段中 `'__ALL__'` 代表对应维度已聚合，查询时需根据分析粒度显式过滤所需的值或 `'__ALL__'`。
- 全维度汇总行（三者均为 `'__ALL__'`）才包含 `item_order_rank`、`item_order_quantile`、`item_cum_order_prop`。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `ctr` | 预聚合比率，跨行 SUM 无业务意义，应用 `SUM(click_cnt) / SUM(imp_cnt)` 重新计算 |
| `cr` | 预聚合比率，应用 `SUM(order_cnt) / SUM(click_cnt)` 重新计算 |
| `ctr_x_cr` | 预聚合比率，应用 `SUM(order_cnt) / SUM(imp_cnt)` 重新计算 |
| `item_order_rank` | 排名字段，跨行 SUM/AVG 无意义 |
| `item_order_quantile` | 分位数字段，跨行 SUM 无意义 |
| `item_cum_order_prop` | 累积占比字段，跨行 SUM 无意义 |
| `image_ctr_x_cr_rank` | 排名字段，跨行 SUM 无意义 |
| `video_ctr_x_cr_rank` | 排名字段，跨行 SUM 无意义 |

### 字段有效性说明

- `imp_cnt`、`click_cnt` 在 video/livestream 跨 source 归因订单行中为 `NULL`，聚合时需注意 `SUM` 对 `NULL` 的处理（默认忽略，但不影响加总语义正确性）。
- `post_date`、`is_new_video` 仅在 `card_type = 'video'` 且 `content_id != '__ALL__'` 的行中有值。
- 时效性：本表为 **T+1 日粒度全量快照**，无近 N 天窗口滚动逻辑，分析历史趋势需跨 `local_date` 分区查询。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwd_sr_data_warehouse_search` | 搜索明细事件表，提供曝光、点击、订单事件及 source1/source2 归因链路数据，是核心流量指标来源 |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维度表，关联商品一级全球后台类目信息 |
| `mp_paidads.dim_advertise__reg_s0_live` | 广告维度表，关联广告 sub_product_type（广告子产品类型） |
| `video.video_mart_dim_content_item_bind_df` | 视频内容-商品绑定关系表，判断商品是否关联视频（`has_video`） |
| `video.video_mart_dim_content` | 视频内容维度表，提供视频发布日期（`post_date`），用于计算 `is_new_video` |
| `search_algo.search_video_competitive_item_candidate` | 搜索视频 MAB 竞争候选池，标识商品是否进入候选池（`skip_mab`） |

---

## ETL 逻辑摘要

### 数据流

```
dwd_sr_data_warehouse_search（3路 UNION ALL：直接事件 + source1归因 + source2归因）
        │
        ▼
dws_search（商品+内容+广告粒度基础汇总）
        │
        ├── LEFT JOIN dim_item（类目）
        ├── LEFT JOIN ads_type（广告子产品类型）
        ├── LEFT JOIN dim_video（has_video 标记）
        └── LEFT JOIN dim_mab（skip_mab 标记）
                │
                ▼
        dws_item（商品维度明细汇总 + 维度标记）
                │
                ▼
        cube_data（GROUPING SETS 多粒度展开 + CTR/CR/CTR×CR 计算）
                │
        ┌───────┼───────────────────────┐
        ▼       ▼                       ▼
item_rank_data  content_rank_data  （非全汇总非内容明细行）
（全汇总行排名）  │
        │       ├── card_type='item' → image_ctr_x_cr_rank
        │       └── card_type='video' → video_rank_data
        │                               │
        │                       JOIN video_dim_content（post_date, is_new_video）
        │                               │
        │                       video_rank_data_dim_joined
        │
        JOIN total_order_cnt（计算 item_order_quantile, item_cum_order_prop）
                │
                ▼
        INSERT OVERWRITE（4路 UNION ALL 合并写入目标表）
```

### 关键步骤

1. **`dws_search`（Temporary View）**：从 `dwd_sr_data_warehouse_search` 按搜索页类型（`global_search / search_in_pdp / search_prefill`）、非空 `item_id`、有效用户（`user_id > 0`）过滤，三路 UNION ALL 汇总直接触达事件与 source1/source2 归因订单，得到 `item_id + content_id + ads_id + card_type` 粒度的基础指标。

2. **`ads_type`（Temporary View）**：从 `mp_paidads.dim_advertise__reg_s0_live` 取最新一条广告记录（按 `placement` 降序去重），获取 `ads_id → sub_product_type` 映射。

3. **`dim_video`（Temporary View）**：从 `video.video_mart_dim_content_item_bind_df` 获取当日有效 Shopee 视频-商品绑定关系，用于标记 `has_video`。

4. **`dim_mab`（Temporary View）**：从 `search_algo.search_video_competitive_item_candidate` 取最新一天数据（`RANK() OVER ... DESC = 1`），展开 `items` 数组，获取 MAB 候选商品列表，用于标记 `skip_mab`。

5. **`dim_item`（Temporary View）**：从 `srdi_mart.dim_sr_data_warehouse_item` 获取商品一级类目信息。

6. **`dws_item`（Temporary View）**：将步骤 1 的基础汇总与步骤 2-5 的维度表做 LEFT JOIN，丰富维度标记，按 `item_id + 类目 + has_video + skip_mab + card_type + content_id + sub_product_type` 聚合。

7. **`cube_data`（Temporary View）**：对 `dws_item` 按 8 组 GROUPING SETS（`card_type`、`content_id`、`sub_product_type` 各维度组合）展开，计算 `ctr`、`cr`、`ctr_x_cr`，空维度填充 `'__ALL__'`。

8. **`item_rank_data`（Temporary View）**：筛选三维全汇总行（`card_type = '__ALL__'` 等），按 `order_cnt` 降序 RANK，得商品排名。

9. **`content_rank_data`（Temporary View）**：筛选 `card_type IN ('item','video')` 且 `content_id != '__ALL__'` 的内容明细行，按 `item_id + sub_product_type + card_type` 分区对 `ctr_x_cr` 降序 RANK，分别用于图片卡和视频卡内容排名。

10. **`video_rank_data_dim_joined`（Temporary View）**：将视频卡内容明细行与 `video.video_mart_dim_content` FULL JOIN，补充 `post_date`，并计算 `is_new_video`（发布距统计日 ≤ 13 天为新视频）。

11. **`total_order_cnt`（Temporary View）**：汇总全汇总行总订单数，用于计算 `item_cum_order_prop`。

12. **INSERT OVERWRITE（最终写入）**：4 路 UNION ALL 合并写入目标分区：
    - **第 1 路**：`cube_data` 中非全汇总、非图片/视频内容明细行（汇总维度组合行）；
    - **第 2 路**：`item_rank_data` 全汇总行，附加 `item_order_rank`、`item_order_quantile`、`item_cum_order_prop`；
    - **第 3 路**：图片卡内容明细行，附加 `image_ctr_x_cr_rank`；
    - **第 4 路**：视频卡内容明细行，附加 `video_ctr_x_cr_rank`、`post_date`、`is_new_video`。

### 注意事项

- **单一写入器**：本表仅有 1 个 ETL 文件，不存在 multi-writer 并发写入风险。
- **分区覆盖**：每次执行按 `grass_region` 和 `local_date` 做 `INSERT OVERWRITE`，同一分区重跑为幂等操作，但须注意参数化变量 `${grass_region}`、`${local_date}` 的正确传入。
- **GROUPING SETS 行膨胀**：同一 `item_id` 在目标表中存在多行，分析时须明确所需的维度粒度行，避免重复计算指标。
- **`imp_cnt`/`click_cnt` 的 NULL 行**：source1/source2 归因订单行的 `imp_cnt` 和 `click_cnt` 为 `NULL`，汇总时 `SUM` 会忽略这些 NULL，但比率类指标（`ctr`/`cr`/`ctr_x_cr`）在汇总级别已用 `COALESCE(..., 0)` 处理分母为零的情况。
- **MAB 候选池数据时效**：`dim_mab` 使用 `grass_date` 与 `date` 双重过滤并取最新 grass_date，若当日数据缺失则可能出现 `skip_mab = FALSE` 偏差。
- **视频卡 FULL JOIN**：`video_rank_data_dim_joined` 使用 FULL JOIN 合并视频排名数据与视频维度，可能产生无流量的视频内容行（仅有 `post_date`/`is_new_video` 无指标），查询时需注意过滤。

---

*文档生成时间：2026-05-17*
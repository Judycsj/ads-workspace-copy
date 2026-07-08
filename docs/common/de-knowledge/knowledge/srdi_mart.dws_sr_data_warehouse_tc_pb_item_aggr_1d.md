<!-- ads-workspace-gdoc-sync: gdoc_id=1MWEHnbcdO0VLV3O5AKczAralU5dk6oChlI_NswGcePk gdoc_url=https://docs.google.com/document/d/1MWEHnbcdO0VLV3O5AKczAralU5dk6oChlI_NswGcePk/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_pb_item_aggr_1d

**分层：** DWS（数据仓库服务层）
**主键：** `item_id` + `mapping_general` + `grass_region` + `local_date`
**分区：** `grass_region`（站点/地区），`local_date`（本地日期）
**更新频率：** 每日（1d，按自然日全量覆盖写入对应分区）
**访问频次：** 229 次

---

## 业务描述

本表是 **搜推数仓（SRDI）付费广告与自然流量融合的商品日粒度汇总宽表**，面向 Shopee 各站点的搜索、推荐、直播等场景，以商品（`item_id`）+ 渠道类型（`mapping_general`）为最细粒度，聚合展示、点击、下单、GMV 及广告收入等核心电商指标。

**核心业务场景：**
- 分渠道（Search、You May Also Like、Daily Discover、Shop、Live Streaming、Video 等）分析商品的曝光、点击、转化表现；
- 区分自然流量（`org_*` 前缀字段）与全量流量（含广告），支持广告效果归因与 ROI 分析；
- 提供 `S&R__ALL__`（搜索+推荐汇总）和 `__ALL__`（全渠道汇总）的广告收入汇总行，支持多层下钻分析；
- 支持商品维度的跨渠道 GMV 拆分（含 PC2 维度 GMV）。

**适合回答的问题：**
- 某商品在某站点、某日、某渠道的曝光/点击/下单/GMV 各是多少？
- 自然流量 vs 广告流量的转化差异如何？
- 某商品的广告投入（`ads_revenue_usd`）在各渠道的分布？
- 搜索+推荐整体（`S&R__ALL__`）vs 全渠道（`__ALL__`）的广告收入对比？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/地区标识，如 `SG`、`MY`、`TH` 等，每个分区对应一个站点 |
| `local_date` | date | 业务本地日期（站点本地时区），数据统计的自然日 |

### 维度：商品与渠道

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID，仅保留 `item_id > 0` 的有效商品 |
| `mapping_general` | string | 渠道/流量来源类型。取值包括：`Search`、`You May Also Like`、`Daily Discover`、`Post Purchase`、`Shop`、`Live Streaming`、`Video`（自然流量渠道）；`S&R__ALL__`（搜索+推荐广告收入汇总虚拟行）；`__ALL__`（全渠道广告收入汇总虚拟行）。广告数据通过 entrance 映射规则转换至上述渠道标签 |

### 指标：曝光与点击

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 全量（自然+广告）曝光次数，NULL 时置 0 |
| `org_imp_cnt` | bigint | 自然流量曝光次数（排除广告，即 `is_ads = 'false'`），NULL 时置 0 |
| `click_cnt` | bigint | 全量点击次数，NULL 时置 0 |
| `org_click_cnt` | bigint | 自然流量点击次数（`is_ads = 'false'`），NULL 时置 0 |

### 指标：订单与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 全量订单数，NULL 时置 0 |
| `org_order_cnt` | double | 自然流量订单数（`is_ads = 'false'`），NULL 时置 0 |
| `gmv` | double | 全量 GMV（货币单位与上游保持一致），NULL 时置 0 |
| `org_gmv` | double | 自然流量 GMV（`is_ads = 'false'`），NULL 时置 0 |
| `pc2_gmv` | double | 全量 PC2（Post Click 2nd conversion 或特定转化口径）GMV，NULL 时置 0 |
| `org_pc2_gmv` | double | 自然流量 PC2 GMV（`is_ads = 'false'`），NULL 时置 0 |

### 指标：广告收入

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_revenue_usd` | double | 广告消耗金额（美元，`expenditure_amt_usd`），来源于付费广告系统。仅在广告侧有数据的渠道行有值，自然流量专属行可能为 NULL |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须同时指定 `grass_region` 和 `local_date`** 两个分区字段，缺少任一均会引发全量扫描，严重影响性能：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-01-01'
  ```
- 若需多天数据，使用 `local_date BETWEEN '2024-01-01' AND '2024-01-07'`，避免漏写 `grass_region`。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `ads_revenue_usd` | 表中存在 `S&R__ALL__` 和 `__ALL__` 两类汇总虚拟行，直接 SUM 会导致重复计算广告收入。聚合时需用 `WHERE mapping_general NOT IN ('S&R__ALL__', '__ALL__')` 过滤或明确指定渠道 |
| `gmv`、`order_cnt` 等全渠道汇总 | 若按 `mapping_general` 不加过滤地 GROUP BY 后再 SUM，`__ALL__` 虚拟行仅对广告 revenue 有意义，对曝光/点击/GMV 字段为 0，需留意含义区分 |

### 时效性说明

- 本表为 **T+1** 日粒度表（后缀 `_1d`），通常在次日产出前一自然日的完整数据。
- 数据以 `INSERT OVERWRITE … PARTITION` 方式写入，**每次运行会全量覆盖该分区**，不存在增量追加，历史分区数据在重跑时会被覆盖。
- 不包含实时/准实时数据，不适用于当日日内分析。

### 其他注意事项

- `mapping_general` 中 `S&R__ALL__` 和 `__ALL__` 为 **广告收入聚合的虚拟维度行**，仅 `ads_revenue_usd` 字段有意义，其余流量指标（`imp_cnt`、`click_cnt`、`gmv` 等）均为 0，**不代表真实流量汇总**。
- 自然流量指标（`org_*`）与全量指标的差值可近似理解为广告带来的增量，但口径以上游 `is_ads` 标记为准。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_tc_pb_basic_aggr_1d` | 提供自然流量与广告流量的商品级别曝光、点击、订单、GMV、PC2 GMV 明细汇总（按 `item_id` + `mapping_general` + `is_ads` 分组） |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 提供付费广告的商品级别广告消耗金额（`expenditure_amt_usd`）及投放入口（`entrance`） |
| `mp_paidads.dim_entry_point_mapping_v2` | 广告投放入口（`entrance`）与渠道类型（`traffic_type`）的映射维表，用于将广告数据归类到与自然流量一致的渠道标签 |

---

## ETL 逻辑摘要

### 数据流

```
srdi_mart.dws_sr_data_warehouse_tc_pb_basic_aggr_1d
        │  （按 item_id + mapping_general 聚合，区分 is_ads）
        ▼
  aggr_sum（自然+全量流量指标汇总）
                                        mp_paidads.dwd_advertise_performance_di__reg_s0_live
                                                │  + mp_paidads.dim_entry_point_mapping_v2（entrance 映射）
                                                ▼
                                        ads_raw_step1（entrance → common_feature 转换）
                                                │
                                                ▼
                                        ads_raw_step2（按 item_id + common_feature 汇总 ads_revenue_usd）
                                                │
                                                ▼
                                        ads（展开各渠道行 + S&R__ALL__ + __ALL__ 虚拟汇总行）
        │                                       │
        └──────── FULL OUTER JOIN（item_id + mapping_general = common_feature）─────────┘
                                        │
                                        ▼
        srdi_mart.dws_sr_data_warehouse_tc_pb_item_aggr_1d
                  （INSERT OVERWRITE，按 grass_region + local_date 分区）
```

### 关键步骤

1. **Step 1 — `aggr_sum`（临时视图）**
   从 `dws_sr_data_warehouse_tc_pb_basic_aggr_1d` 按 `item_id`、`mapping_general` 聚合，使用 `CASE WHEN is_ads = 'false'` 区分自然流量，分别计算全量与自然流量的曝光、点击、订单、GMV、PC2 GMV。

2. **Step 2 — `ads_raw_step1`（临时视图）**
   从付费广告宽表读取商品级别广告消耗，LEFT JOIN 入口映射维表，将 `entrance` 转换为统一的 `common_feature` 渠道标签（`Livestream` → `Live Streaming`；`entrance=23` → `Image Search`；其余取 `traffic_type` 或 `Other`）。

3. **Step 3 — `ads_raw_step2`（临时视图）**
   按 `item_id` + `common_feature` 汇总广告消耗，得到商品-渠道粒度的 `ads_revenue_usd`。

4. **Step 4 — `ads`（临时视图）**
   在 `ads_raw_step2` 基础上通过 `UNION ALL` 构建三层数据：
   - **渠道明细行**：保留 `Search`、`You May Also Like`、`Daily Discover`、`Post Purchase`、`Shop`、`Live Streaming`、`Video` 7 个渠道；
   - **`S&R__ALL__` 汇总行**：对 Search、Image Search、You May Also Like、Daily Discover、Post Purchase 的广告收入求和；
   - **`__ALL__` 汇总行**：全渠道广告收入求和。

5. **Step 5 — INSERT OVERWRITE（目标表写入）**
   将 `aggr_sum` 与 `ads` 按 `item_id` + `mapping_general = common_feature` 进行 **FULL OUTER JOIN**，使用 `COALESCE` 处理 NULL，最终覆盖写入目标分区 `grass_region` + `local_date`。

### 注意事项

- **单 Writer 无并发冲突**：本表仅有 1 个 ETL 文件写入，`multi_writer = false`，无多文件竞争写入风险。
- **FULL OUTER JOIN 导致 NULL 行**：自然流量有数据但广告侧无数据的商品-渠道行，`ads_revenue_usd` 为 NULL（未用 COALESCE 兜底）；广告侧有数据但自然侧无数据的行，流量指标字段均为 0。查询时需注意 NULL 值处理。
- **`__ALL__` / `S&R__ALL__` 虚拟行仅携带广告收入**：这两个虚拟维度行在 `aggr_sum` 中无对应行，FULL OUTER JOIN 后流量指标字段全为 0，不可用于统计自然流量汇总。
- **分区覆盖写入**：每次 ETL 以 INSERT OVERWRITE 覆盖指定 `grass_region` + `local_date` 分区，重跑安全，但同一分区内历史产出会被完整替换。
- **参数化执行**：SQL 中使用 `${grass_region}`、`${grass_region_without_quote}`、`${local_date}`、`${schema}` 等运行时参数，实际执行时由调度系统注入，支持按站点逐一产出分区。

---

*文档生成时间：2026-05-17*
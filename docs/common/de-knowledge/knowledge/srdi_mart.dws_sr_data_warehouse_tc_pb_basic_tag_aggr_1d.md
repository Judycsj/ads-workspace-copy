<!-- ads-workspace-gdoc-sync: gdoc_id=12BhEAj3-aMIjYjP1ELe7jxcj3lfmkGM1_lnYM_dhgI4 gdoc_url=https://docs.google.com/document/d/12BhEAj3-aMIjYjP1ELe7jxcj3lfmkGM1_lnYM_dhgI4/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_pb_basic_tag_aggr_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `local_hour` + `item_id` + `model_id` + `user_id` + `is_item_card` + `is_ads` + `mapping_general` + `shop_id`
**分区：** `grass_region` / `local_date` / `local_hour`
**更新频率：** 每日按小时分区写入（INSERT OVERWRITE，按 `local_hour` 动态分区）
**访问频次：** 220 次

---

## 业务描述

本表是搜推（Search & Recommendation）场景下，以 **商品（item）/ 变体（model）/ 用户 / 频道** 为粒度的每日基础指标汇总表，在 `dws_sr_data_warehouse_tc_pb_basic_aggr_1d` 的基础上，额外打标以下维度标签：

- **最低价商品标签**：当前商品/变体是否为全站最低价（cheapest item / model）或 CSPU 维度最低价（cheapest cspu all item / model）；
- **店铺 SCS 类型**：关联 SCS 本地/跨境店铺维度。

核心业务场景：

1. 分析不同频道（`mapping_general`）下最低价商品的曝光、点击、订单及 GMV 表现；
2. 评估 SCS 店铺（本地/跨境）在各推荐位的流量与转化效率；
3. 支撑广告（`is_ads`）与自然流量在最低价商品上的对比分析；
4. 按用户、商品、变体多粒度下钻，追踪搜推场景的全链路转化指标。

适合回答的问题示例：
- 某日哪些频道下最低价商品的 GMV 占比最高？
- SCS 跨境店铺在搜索频道的点击率如何？
- 广告流量与自然流量在 CSPU 最低价商品上的转化差异？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/大区，如 `ID`、`TH` 等，分区键之一，查询必须指定 |
| `local_date` | date | 业务日期（本地时区），分区键之一，查询必须指定 |
| `local_hour` | int | 业务小时（0–23），分区键之一，表示数据所属的小时切片 |

### 维度：商品与用户

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_id` | bigint | 商品 ID |
| `model_id` | bigint | 变体/SKU ID |
| `shop_id` | bigint | 店铺 ID |
| `user_id` | bigint | 用户 ID |

### 维度：流量场景与标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_item_card` | string | 是否为商品卡片展示形式 |
| `is_ads` | string | 是否为广告流量（广告/自然流量区分标志） |
| `mapping_general` | string | 频道/场景映射标签，取值范围包括：`Search`、`Daily Discover`、`You May Also Like`、`Post Purchase`、`Shop`、`Video`、`Live Streaming`、`S&R__ALL__`、`__ALL__` 等 |
| `shop_scs_type` | string | 店铺 SCS 类型，取值为 `scs-local`（本地 SCS 店铺）、`scs-cb`（跨境 SCS 店铺）或空字符串（非 SCS 店铺）；优先取最低价变体关联的类型，依次 fallback |

### 维度：最低价标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `is_cheapest_item` | bigint | 商品是否为全站最低价 item（cheapest item list 命中则为 1，否则为 0） |
| `is_cheapest_cspu_all_item` | bigint | 商品是否为 CSPU 维度最低价 item（所有 CSPU 最低价 item 命中则为 1，否则为 0） |
| `is_cheapest_model` | bigint | 变体是否为全站最低价 model（cheapest model list 命中则为 1，否则为 0） |
| `is_cheapest_cspu_all_model` | bigint | 变体是否为 CSPU 维度最低价 model（所有 CSPU 最低价 model 命中则为 1，否则为 0） |
| `cspu_pr_rate` | string | CSPU 价格比率（当前 ETL 中固定写入 `null`，暂未填充，预留字段） |

### 指标：流量与转化

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 曝光次数 |
| `click_cnt` | bigint | 点击次数 |
| `order_cnt` | double | 订单数（来自上游汇总，非整型，请勿直接对去重维度 SUM） |
| `gmv` | double | GMV（美元口径） |
| `gmv_local` | double | GMV（本地货币口径） |
| `pc2_gmv` | double | PC2 口径 GMV |

---

## 查询使用须知

### 必须包含的过滤条件

1. **`grass_region`**：分区字段，每次查询必须明确指定站点，避免全表扫描，例如 `WHERE grass_region = 'ID'`。
2. **`local_date`**：分区字段，必须指定日期范围，例如 `AND local_date = '2025-01-01'`。
3. **`local_hour`**：分区字段，若仅需全天汇总，应使用 `GROUP BY local_date` 并对所有小时 SUM；若需特定时段，需显式过滤。
4. **`mapping_general`**：本表上游已过滤为固定频道白名单（`Search`、`Daily Discover`、`You May Also Like`、`Post Purchase`、`Shop`、`Video`、`Live Streaming`、`S&R__ALL__`、`__ALL__`），查询时可进一步过滤具体频道。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `cspu_pr_rate` | 当前为 `null`，预留字段，无实际值，勿参与计算 |
| `is_cheapest_item` / `is_cheapest_model` / `is_cheapest_cspu_all_item` / `is_cheapest_cspu_all_model` | 为行级标签（0/1），跨行 SUM 无业务意义，应使用 `MAX` 或作为过滤条件；多小时聚合时需注意同一 item 在不同 `local_hour` 标签可能不同 |
| `order_cnt` / `gmv` / `gmv_local` / `pc2_gmv` | 本表为预聚合结果，跨多个维度（`user_id`、`model_id` 等）直接 SUM 可能存在重复计数，需明确聚合维度 |

### 时效性说明

- 本表为 **按天按小时** 写入的预聚合表（`*_1d` 后缀），数据精度为小时级。
- 最低价标签（`is_cheapest_*`）依赖 `local_date - 1` 的 CSPU 订单数据（`cspu_l1d_order_cnt`）进行过滤，存在 **T+1 数据延迟**。
- `cspu_pr_rate` 字段当前固定为 `null`，无时效性参考意义。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_tc_pb_basic_aggr_1d` | 主驱动表，提供商品/用户/频道粒度的曝光、点击、订单、GMV 等基础汇总指标 |
| `srdi_mart.dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf` | 提供 item → CSPU → model 的映射关系（小时级维度表） |
| `srdi_mart.dim_sr_data_warehouse_pb_one_variation_model_analysis_hf` | 提供最低价 model 候选列表（含业务类型 `business_type` 过滤） |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_cspu_level_1d` | 提供 CSPU 前一天订单数（`cspu_l1d_order_cnt`），用于过滤有效最低价候选 |
| `regds_listing.dim_scs_shop_list_df` | 提供 SCS 店铺类型维度（`scs-local` / `scs-cb`） |

---

## ETL 逻辑摘要

### 数据流

```
regds_listing.dim_scs_shop_list_df
        │
        ▼
shop_type（SCS 店铺类型）
        │
        ├──────────────────────────────────────────┐
        ▼                                          ▼
dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf  dim_sr_data_warehouse_pb_one_variation_model_analysis_hf
        │                                          │
        ▼                                          │
all_cspu_model（全量 CSPU item-model 映射）       │
        │                              dws_sr_data_warehouse_tc_pb_cspu_level_1d（T-1 CSPU 订单）
        │                                          │
        │                                          ▼
        │                              cheapest_model_list（最低价 model 候选，含业务类型过滤）
        │                                          │
        ├──────────────────────────────────────────┤
        ▼                                          ▼
cheapest_cspu_all_model（CSPU 最低价 model）   cheapest_item_list（最低价 item）
        │
        ▼
cheapest_cspu_all_item（CSPU 最低价 item，cached）
        │
        └──── 与 dws_sr_data_warehouse_tc_pb_basic_aggr_1d（主驱动表）LEFT JOIN
                        │
                        ▼
        dws_sr_data_warehouse_tc_pb_basic_tag_aggr_1d（目标表）
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| Step 1 | `shop_type` | 从 `dim_scs_shop_list_df` 过滤当前站点的 SCS 店铺，取 `shop_id` → `shop_scs_type` 映射 |
| Step 2 | `all_cspu_model` | 从 `dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf` 获取当日全量 item-CSPU-model 映射，左关联 SCS 店铺类型 |
| Step 3 | `cspu_label` | 从 `dws_sr_data_warehouse_tc_pb_cspu_level_1d` 取 T-1 日 CSPU 订单数，用于后续最低价候选过滤 |
| Step 4 | `cheapest_model_list` | 从 `dim_sr_data_warehouse_pb_one_variation_model_analysis_hf` 获取最低价 model 候选；`business_type in (3,4)` 无条件纳入；`business_type in (1,2)` 需 T-1 CSPU 订单数 > 0 或为 null（新品） |
| Step 5 | `cheapest_cspu_all_model` | `all_cspu_model` INNER JOIN `cheapest_model_list`（按 `cspu_id` + `local_hour`），得到 CSPU 维度下所有最低价 model |
| Step 6 | `cheapest_item_list` | 从 `cheapest_model_list` 按 `(hour, item_id, shop_id)` 聚合，得到最低价 item 列表 |
| Step 7 | `cheapest_cspu_all_item`（cached） | 从 `cheapest_cspu_all_model` 按 `(local_hour, item_id, shop_id)` 聚合，得到 CSPU 维度最低价 item，并 CACHE 以复用 |
| Step 8 | INSERT OVERWRITE | 以 `dws_sr_data_warehouse_tc_pb_basic_aggr_1d` 为主表（过滤固定频道白名单），LEFT JOIN 四张最低价标签表，生成 `is_cheapest_*` 标签，`shop_scs_type` 按优先级 COALESCE 填充，`cspu_pr_rate` 固定写 null，按 `(grass_region, local_date, local_hour)` 动态分区写入目标表 |

### 注意事项

1. **单 Writer，无并发冲突**：本表仅有一个 ETL 文件写入，不存在 multi-writer 风险，但需注意分区覆盖（INSERT OVERWRITE）对历史数据的影响。
2. **动态分区写入**：以 `local_hour` 为动态分区，`grass_region` 和 `local_date` 为静态分区，写入时需确认 Spark `hive.exec.dynamic.partition.mode=nonstrict`。
3. **T-1 CSPU 订单依赖**：`cspu_label` 使用 `date_sub(local_date, 1)` 的数据，若上游 `dws_sr_data_warehouse_tc_pb_cspu_level_1d` 当日分区未就绪，最低价标签计算不受影响（仅影响 `business_type in (1,2)` 的过滤逻辑），但需监控上游延迟。
4. **`cspu_pr_rate` 为预留字段**：当前 ETL 中固定写入 `null`，下游使用时需注意该字段无实际值，不可参与任何比率计算。
5. **频道白名单过滤**：上游基础表已含多个 `mapping_general` 值，本表在 ETL 层做了显式白名单过滤，仅保留指定频道，下游若需其他频道数据应查询 `dws_sr_data_warehouse_tc_pb_basic_aggr_1d`。
6. **`shop_scs_type` COALESCE 优先级**：依次为 cheapest_model → cheapest_item → cheapest_cspu_all_model → cheapest_cspu_all_item，均为 null 时填充空字符串，非 SCS 店铺将呈现为空字符串而非 null。

---

*文档生成时间：2026-05-17*
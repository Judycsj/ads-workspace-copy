<!-- ads-workspace-gdoc-sync: gdoc_id=1NZlInfwtkvc4u4wUjb-Yl5p9hjfEO_qKK1F8fvKvZhY gdoc_url=https://docs.google.com/document/d/1NZlInfwtkvc4u4wUjb-Yl5p9hjfEO_qKK1F8fvKvZhY/edit -->

# srdi_mart.ads_sr_data_warehouse_tc_pb_sr_exp_order_fast_1d

**分层：** ADS（应用数据层）
**主键：** `grass_region` + `local_date` + `exp_group_id` + `mapping_general` + `is_ads`
**分区：** `grass_region`（大区）、`local_date`（日期）
**更新频率：** 每日一次（T+1）
**引用频次 / 访问频次：** 42

---

## 业务描述

本表面向搜推（Search & Recommendation）实验分析场景，统计各 **AB 实验分组** 在不同 **流量场景**（Search、Daily Discover、You May Also Like、Post Purchase）下，与"最低价商品/型号/CSPU"标签相关的 **订单量、买家数（UV）及 GMV** 核心指标。

核心业务场景包括：

- **AB 实验效果评估**：按实验分组（`exp_group_id`）对比各场景订单量与 GMV，评估搜索/推荐策略的实验收益。
- **最低价标签分析**：分析进入最低价（cheapest item / model）、CSPU 维度最低价、竞价中标（winner / bidding SCS cheapest）的订单转化贡献。
- **广告 vs. 自然流量拆分**：通过 `is_ads` 维度区分广告流量与自然流量的订单贡献。
- **场景整体大盘监控**：通过 `scene_order_cnt`、`scene_gmv` 等字段监控各流量场景的订单基线。

适合回答的典型问题：
- 实验组 X 在搜索场景下，相比对照组最低价型号订单量提升了多少？
- 当天各场景中，广告流量和非广告流量的 GMV 各是多少？
- CSPU 维度最低价商品对 Daily Discover 场景订单的贡献占比如何？
- 竞价 SCS 最低价商品的订单量趋势如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区分区键，如 `ID`、`MY`、`TH` 等，查询时必须指定 |
| `local_date` | date | 本地业务日期，查询时必须指定，数据为当日汇总 |

### 维度：实验与场景

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | bigint | AB 实验分组 ID，来源于 `dim_sr_data_warehouse_abtest_user_group`，仅含指定 scene_id 的实验流量 |
| `mapping_general` | string | 流量场景归因标签，枚举值：`Search`、`Daily Discover`、`You May Also Like`、`Post Purchase` |
| `is_ads` | string | 是否为广告流量；值为 `'true'`、`'false'` 或 `'__ALL__'`（GROUPING SETS 汇总行，代表全量） |

### 指标：最低价型号（Cheapest Model）订单

| 字段 | 类型 | 说明 |
|---|---|---|
| `cheapest_model_order_cnt` | double | 最低价型号（cheapest model）的订单量；满足 `cheapest_model=1` 的 `order_cnt` 之和 |
| `cheapest_model_order_uv` | bigint | 最低价型号订单买家数（去重 `user_id`）；**不可直接 SUM，需重新去重** |
| `cheapest_model_gmv` | double | 最低价型号订单 GMV（标准货币） |
| `cheapest_model_gmv_local` | double | 最低价型号订单 GMV（本地货币） |

### 指标：最低价商品（Cheapest Item）订单

| 字段 | 类型 | 说明 |
|---|---|---|
| `cheapest_item_order_cnt` | double | 最低价商品（cheapest item）的订单量；满足 `cheapest_item=1` 的 `order_cnt` 之和 |
| `cheapest_item_order_uv` | bigint | 最低价商品订单买家数（去重 `user_id`）；**不可直接 SUM，需重新去重** |
| `cheapest_item_gmv` | double | 最低价商品订单 GMV（标准货币） |
| `cheapest_item_gmv_local` | double | 最低价商品订单 GMV（本地货币） |

### 指标：CSPU 维度最低价型号（CSPU All Model）订单

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_model_order_cnt` | double | CSPU 维度最低价型号（cheapest_cspu_all_model=1）的订单量 |
| `cspu_model_order_uv` | bigint | CSPU 维度最低价型号订单买家数（去重 `user_id`）；**不可直接 SUM，需重新去重** |
| `cspu_model_gmv` | double | CSPU 维度最低价型号订单 GMV（标准货币） |
| `cspu_model_gmv_local` | double | CSPU 维度最低价型号订单 GMV（本地货币） |

### 指标：场景整体订单

| 字段 | 类型 | 说明 |
|---|---|---|
| `scene_order_cnt` | double | 场景内全部订单量（含实验分组用户） |
| `scene_order_uv` | bigint | 场景内订单买家数（去重 `user_id`）；**不可直接 SUM，需重新去重** |
| `scene_gmv` | double | 场景内订单 GMV（标准货币） |
| `scene_gmv_local` | double | 场景内订单 GMV（本地货币） |

### 指标：竞价与 Winner 相关订单

| 字段 | 类型 | 说明 |
|---|---|---|
| `winner_order_cnt` | double | Winner 型号（`winner_model=1`，即 `business_type in (3,4)`）的订单量 |
| `bidding_scs_cheapest_order_cnt` | double | 竞价 SCS 最低价型号（`bidding_scs_cheapest_model=1`，即 `business_type=4`）的订单量 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：分区字段，每次查询必须指定，否则触发全表扫描。例如：`WHERE grass_region = 'ID'`。
- **`local_date`**：分区字段，每次查询必须指定具体日期或日期范围。例如：`AND local_date = '2025-01-01'`。
- **`mapping_general`**：若仅分析特定场景，务必过滤（枚举值：`Search`、`Daily Discover`、`You May Also Like`、`Post Purchase`）。

### 不可直接 SUM 的字段

以下字段为预聚合去重指标，**跨 `exp_group_id`、`mapping_general`、`is_ads` 或 `local_date` 累加时会重复计数**，需回溯明细表重新去重：

| 字段 | 原因 |
|---|---|
| `cheapest_model_order_uv` | `COUNT(DISTINCT user_id)` 预聚合，直接 SUM 会导致重复 |
| `cheapest_item_order_uv` | 同上 |
| `cspu_model_order_uv` | 同上 |
| `scene_order_uv` | 同上 |

### `is_ads` 汇总行说明

- 本表采用 `GROUPING SETS` 生成两类行：
  - `is_ads = 'true'` / `'false'`：广告/自然流量明细行
  - `is_ads = '__ALL__'`：广告 + 自然流量合并汇总行
- **跨 `is_ads` 累加订单量时，须过滤掉 `is_ads = '__ALL__'` 行**，避免重复计算。

### 时效性说明

- 本表为 **T+1 日级别**（`_1d` 后缀），每日全量覆写目标分区。
- 数据覆盖的实验分组仅限于 ETL 中预设的特定 scene_id，不涵盖所有 AB 实验。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dwm_sr_data_warehouse_tc_ab_all_cards` | 原始流量事件明细（曝光、点击、订单、GMV），按 `operation='order'` 过滤后作为订单数据源 |
| `srdi_mart.dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf` | CSPU 与商品/型号的关联关系（小时粒度），用于构建 CSPU 维度最低价候选集 |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_cspu_level_1d` | CSPU 昨日（T-1）订单量，用于过滤无订单记录的 CSPU（cspu_l1d_order_cnt > 0 或为空时保留） |
| `srdi_mart.dim_sr_data_warehouse_pb_one_variation_model_analysis_hf` | 最低价型号候选列表（小时粒度），含 `business_type` 标记（3=winner、4=bidding SCS cheapest） |
| `abtest.shopee_experiment_admin_db__group_dimension_tab__reg_continuous_s0_live` | AB 实验分组元数据，过滤指定 scene_id（449、142、132、368、381、443、373）对应的实验分组 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 用户实验分组映射（`is_assignment_log=1`），关联用户与实验分组 ID |

---

## ETL 逻辑摘要

### 数据流

```
dwm_sr_data_warehouse_tc_ab_all_cards (订单原始明细)
    → traffic_data_raw (过滤 order，按小时/用户/商品聚合)
    → every_scene_data_raw_step1 (场景归因：Search / Daily Discover / YMAL / Post Purchase / Shop)
    → every_scene_data_raw_step2 (多归因订单扩展：source1 / source2 归因复制，去重保障)
        ↓
dim_sr_data_warehouse_pb_one_variation_model_analysis_hf → cheapest_model_list (最低价型号列表)
dws_sr_data_warehouse_tc_pb_cspu_level_1d              → cspu_label (CSPU 昨日订单量过滤)
dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf     → all_cspu_model → cheapest_cspu_all_model/item
        ↓
traffic_data (LEFT JOIN 最低价标签，按用户/商品/场景聚合)
        ↓
dim_sr_data_warehouse_abtest_user_group + abtest 实验元数据 → user_exp (有效实验用户)
        ↓
traffic_exp (INNER JOIN 实验用户，保留实验流量)
        ↓
INSERT OVERWRITE → ads_sr_data_warehouse_tc_pb_sr_exp_order_fast_1d
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| 1 | `traffic_data_raw` | 从 DWM 层读取当日订单记录，保留 operation='order'，按小时 + 用户 + 商品维度聚合 |
| 2 | `every_scene_data_raw_step1` | 对 reporting_business_line / module / object 做规则映射，生成 `mapping_general`（直接归因）及 `source1_mapping_general`、`source2_mapping_general`（间接归因），过滤只保留有效场景 |
| 3 | `every_scene_data_raw_step2` | UNION ALL 三段数据：直接归因行 + source1 间接归因复制行 + source2 间接归因复制行，通过 `mapping_general != source1/source2_mapping_general` 条件防止订单重复计入 |
| 4 | `all_cspu_model` | 读取当日 CSPU-商品-型号小时粒度关联表 |
| 5 | `cspu_label` | 读取 T-1 日 CSPU 订单量，用于过滤历史无销量 CSPU |
| 6 | `cheapest_model_list` | 读取当日最低价型号候选列表，LEFT JOIN cspu_label 保留 cspu_l1d_order_cnt > 0 或为空的记录 |
| 7 | `cheapest_cspu_all_model` | INNER JOIN all_cspu_model 与 cheapest_model_list（按 cspu_id + local_hour），得到 CSPU 维度最低价覆盖的所有型号 |
| 8 | `cheapest_item_list` / `cheapest_cspu_all_item` / `winner_item_list` | 由 cheapest_model_list / cheapest_cspu_all_model 下卷到 item 粒度，区分 winner（business_type 3/4）和 bidding SCS cheapest（business_type=4） |
| 9 | `exp_traffic_info` | 从实验元数据表过滤指定 scene_id 对应的实验分组 ID |
| 10 | `user_exp_raw` / `user_exp` | 读取用户实验分组，INNER JOIN 实验分组元数据，保留有效实验用户 |
| 11 | `traffic_data` | 将 step2 流量数据与各最低价标签列表 LEFT JOIN（按 shop_id + item_id + model_id + local_hour 匹配），生成 cheapest/winner/bidding_scs 二值标签，按用户/商品/场景聚合 |
| 12 | `traffic_exp` | INNER JOIN user_exp，仅保留命中实验分组的用户流量 |
| 13 | `INSERT OVERWRITE` | 按 `GROUPING SETS((exp_group_id, mapping_general, is_ads), (exp_group_id, mapping_general))` 聚合，写入目标分区；`is_ads='__ALL__'` 行由 `grouping(is_ads)=1` 生成 |

### 注意事项

- **单 Writer**：本表仅有 1 个 ETL 文件写入，无 multi-writer 并发冲突风险。
- **分区覆写**：采用 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)` 静态分区写入，重跑时会完整覆盖目标分区，历史数据安全。
- **GROUPING SETS 汇总行**：`is_ads='__ALL__'` 行与明细行同表存储，使用时必须按业务需要过滤，避免重复累加。
- **CSPU 过滤逻辑**：`cspu_label` 使用 T-1 日数据，若某 CSPU 昨日无订单且记录不存在（LEFT JOIN 结果为 NULL），仍保留；仅当昨日订单量为 0（非 NULL）时才被过滤。
- **订单归因复制防重**：source1/source2 归因复制行通过 `source_mapping_general != mapping_general`（及 `source2 != source1`）条件去重，但当 source1 与 source2 指向相同场景时仍只计一次，分析时需注意归因逻辑边界。
- **实验覆盖范围**：仅包含 scene_id 为 449、142、132、368、381、443、373 对应分组的用户，不覆盖全量用户或其他实验，场景大盘口径以其他宽表为准。
- **`_hf` 上游表依赖**：`dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf` 和 `dim_sr_data_warehouse_pb_one_variation_model_analysis_hf` 为小时频次更新表，本表取当日最新数据，若上游小时数据不完整可能影响最低价标签准确性。

---

*文档生成时间：2026-05-17*
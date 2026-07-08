<!-- ads-workspace-gdoc-sync: gdoc_id=1Sdkqo7m-d5QuBEOov7K6Oe8HRlZYRCak774gqxHkuG4 gdoc_url=https://docs.google.com/document/d/1Sdkqo7m-d5QuBEOov7K6Oe8HRlZYRCak774gqxHkuG4/edit -->

# srdi_mart.ads_sr_data_warehouse_tc_pb_sr_exp_1d

**分层：** ADS（应用数据层）
**主键：** `grass_region` + `local_date` + `exp_group_id` + `mapping_general` + `is_ads`
**分区：** `grass_region`（站点）, `local_date`（日期）
**更新频率：** 每日（T+1）
**访问频次：** 1642

---

## 业务描述

本表为搜索推荐（SR）价格力（Price Battle / PB）A/B 实验效果分析宽表，按实验分组（`exp_group_id`）、流量场景（`mapping_general`）和是否广告（`is_ads`）维度，汇总 cheapest item/model、cspu 覆盖模型、winner/bidding-SCS 等价格力策略在各 AB 实验分桶下的每日曝光、订单和 GMV 表现。

**核心业务场景：**
- 评估搜推场景（搜索、每日发现、猜你喜欢、购后推荐）下价格力 A/B 实验的策略效果；
- 对比不同实验分组的 cheapest item/model 曝光渗透率与转化贡献；
- 评估 CSPU 级别最优商品的覆盖效果；
- 分析 Winner / Bidding-SCS 竞价策略的曝光及转化情况。

**适合回答的问题举例：**
- 实验组 X 与对照组在 Search 场景下 cheapest item 的 GMV 贡献差异是多少？
- 各 AB 组中 cspu 覆盖模型的订单 UV 占比如何？
- Bidding-SCS 策略在 Daily Discover 场景的曝光量趋势？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点/大区标识，如 `ID`、`MY` 等，分区键之一 |
| `local_date` | date | 数据日期（本地时区），分区键之一 |

### 维度：实验与流量场景

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | bigint | AB 实验分组 ID，来源于实验平台有效分桶，仅包含指定 scene_id 下的实验组 |
| `mapping_general` | string | 流量场景归类，取值范围：`Search`、`Daily Discover`、`You May Also Like`、`Post Purchase` |
| `is_ads` | string | 是否为广告流量；使用 `GROUPING SETS` 聚合，`__ALL__` 表示不区分广告/自然流量的汇总行 |

### 指标：整体场景基准指标

| 字段 | 类型 | 说明 |
|---|---|---|
| `scene_imp_pv` | bigint | 场景总曝光 PV（曝光次数） |
| `scene_imp_uv` | bigint | 场景曝光 UV（有曝光行为的用户数） |
| `scene_order_cnt` | double | 场景总归因订单数 |
| `scene_order_uv` | bigint | 场景有订单的用户数 |
| `scene_gmv` | double | 场景总归因 GMV（美元） |
| `scene_gmv_local` | double | 场景总归因 GMV（本地货币） |

### 指标：Cheapest Item（单品维度最低价商品）

| 字段 | 类型 | 说明 |
|---|---|---|
| `cheapest_item_imp_pv` | bigint | cheapest item 的曝光 PV |
| `cheapest_item_imp_uv` | bigint | cheapest item 的曝光 UV（有曝光的用户数） |
| `cheapest_item_order_cnt` | double | cheapest item 的归因订单数 |
| `cheapest_item_order_uv` | bigint | cheapest item 的下单用户数 |
| `cheapest_item_gmv` | double | cheapest item 的归因 GMV（美元） |
| `cheapest_item_gmv_local` | double | cheapest item 的归因 GMV（本地货币） |

### 指标：Cheapest Model（SKU/Model 维度最低价款式）

| 字段 | 类型 | 说明 |
|---|---|---|
| `cheapest_model_order_cnt` | double | cheapest model 的归因订单数 |
| `cheapest_model_order_uv` | bigint | cheapest model 的下单用户数 |
| `cheapest_model_gmv` | double | cheapest model 的归因 GMV（美元） |
| `cheapest_model_gmv_local` | double | cheapest model 的归因 GMV（本地货币） |

### 指标：CSPU 覆盖模型（CSPU 全款式最优商品）

| 字段 | 类型 | 说明 |
|---|---|---|
| `cspu_item_imp_pv` | bigint | CSPU 覆盖 all model 中 cheapest item 的曝光 PV |
| `cspu_item_imp_uv` | bigint | CSPU 覆盖 all model 中 cheapest item 的曝光 UV |
| `cspu_model_order_cnt` | double | CSPU 覆盖 all model 中 cheapest model 的归因订单数 |
| `cspu_model_order_uv` | bigint | CSPU 覆盖 all model 中 cheapest model 的下单用户数 |
| `cspu_model_gmv` | double | CSPU 覆盖 all model 的归因 GMV（美元） |
| `cspu_model_gmv_local` | double | CSPU 覆盖 all model 的归因 GMV（本地货币） |

### 指标：Winner / Bidding-SCS 竞价策略

| 字段 | 类型 | 说明 |
|---|---|---|
| `winner_imp_cnt` | bigint | Winner 商品（business_type in (3,4)）的曝光 PV |
| `winner_order_cnt` | double | Winner model（business_type in (3,4)）的归因订单数 |
| `bidding_scs_cheapest_imp_cnt` | bigint | Bidding-SCS cheapest item（business_type=4）的曝光 PV |
| `bidding_scs_cheapest_order_cnt` | double | Bidding-SCS cheapest model（business_type=4）的归因订单数 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：必须指定站点分区，否则全表扫描性能极差；例：`WHERE grass_region = 'ID'`。
- **`local_date`**：必须指定日期分区，建议精确到天；例：`AND local_date = '2025-01-01'`。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `*_uv`（所有 UV 字段） | UV 为去重用户数（由用户粒度聚合后计数），跨分区/维度直接 SUM 会导致重复计数 |
| `*_order_uv`、`*_imp_uv` | 同上，均为去重指标 |

- `*_order_cnt`、`*_gmv`、`*_imp_pv` 等 PV/金额/订单量字段为加和型指标，可跨行 SUM。
- 若需要跨多日汇总 UV，应回退到用户粒度明细表重新去重。

### is_ads 的 `__ALL__` 汇总行说明

- 本表通过 `GROUPING SETS` 生成两类行：
  - `is_ads = '0'` 或 `'1'`：区分广告/自然流量的明细；
  - `is_ads = '__ALL__'`：不区分广告/自然流量的全量汇总行。
- 统计全量场景指标时，请直接筛选 `is_ads = '__ALL__'`，**不要**对 `is_ads` 的明细行再次 SUM，否则会双重计算。

### 时效性说明

- 本表为 **日粒度（`_1d`）** 表，每日产出前一天完整数据，适用于 T+1 分析场景。
- cheapest model 的候选集依赖前一日（`date_sub(local_date, 1)`）的 CSPU 订单标签过滤，结果存在 1 天的滞后性。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_tc_pb_basic_aggr_1d` | 主要流量明细数据源，提供用户、商品、场景、曝光/订单/GMV 基础指标 |
| `srdi_mart.dim_sr_data_warehouse_pb_one_variation_model_analysis_hf` | cheapest model 候选列表（含 business_type，用于识别 Winner/Bidding-SCS） |
| `srdi_mart.dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf` | CSPU 与 item/model 的完整映射关系 |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_cspu_level_1d` | 前一日 CSPU 订单量标签，用于过滤活跃 CSPU |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 用户 AB 实验分组信息（`is_assignment_log = 1`） |
| `abtest.shopee_experiment_admin_db__group_dimension_tab__reg_continuous_s0_live` | 实验平台 group 白名单，过滤指定 scene_id 下的有效实验组 |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_pb_one_variation_model_analysis_hf  ─┐
dws_sr_data_warehouse_tc_pb_cspu_level_1d                  ├─► cheapest/winner item & model 候选列表
dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf         ─┘
        │
        ▼
dws_sr_data_warehouse_tc_pb_basic_aggr_1d  ──► 流量数据关联价格力标签 ──► traffic_data
        │
        ▼
dim_sr_data_warehouse_abtest_user_group  ──► 实验平台 group 白名单 ──► 用户实验分组 (user_exp)
        │
        ▼
traffic_data × user_exp ──► traffic_exp ──► GROUPING SETS 聚合 ──► traffic_exp_aggr
        │
        ▼
INSERT OVERWRITE ads_sr_data_warehouse_tc_pb_sr_exp_1d (partition by grass_region, local_date)
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| 1 | `all_cspu_model` | 读取当日 CSPU 与 item/model 的全量映射 |
| 2 | `cspu_label` | 读取前一日 CSPU 订单量，用于过滤无活跃订单的 CSPU |
| 3 | `cheapest_model_list` | 以 `dim_sr...one_variation_model_analysis_hf` 为基础，left join 前日 CSPU 标签，保留 `cspu_l1d_order_cnt > 0` 或未关联到标签的 CSPU，得到按小时的 cheapest model 候选 |
| 4 | `cheapest_cspu_all_model` | 将 all_cspu_model 与 cheapest_model_list 的 cspu+hour 维度 inner join，获取 CSPU 全款 cheapest model 列表 |
| 5 | `cheapest_item_list` | 从 cheapest_model_list 去重得到 cheapest item（shop+item+hour） |
| 6 | `winner_item_list` | 从 cheapest_model_list 过滤 business_type in (3,4) 得到 winner item |
| 7 | `cheapest_cspu_all_item` | 从 cheapest_cspu_all_model 去重得到 CSPU 覆盖的 cheapest item |
| 8 | `exp_traffic_info` | 从实验平台读取指定 scene_id 白名单下的有效 group_id |
| 9 | `user_exp_raw` / `user_exp` | 读取用户实验分组，inner join 实验白名单，得到有效用户-实验分组映射 |
| 10 | `traffic_data` | 以 `dws_sr...pb_basic_aggr_1d` 为主表，left join 各候选列表，打标 cheapest_item/model、cspu 覆盖、winner/bidding_scs 标签；过滤 mapping_general 四大场景；按用户+商品+标签聚合 |
| 11 | `traffic_exp` | `traffic_data` inner join `user_exp`，仅保留命中实验分组的流量 |
| 12 | `traffic_exp_aggr` | 使用 `GROUPING SETS((exp_group_id, mapping_general, is_ads, user_id), (exp_group_id, mapping_general, user_id))` 在用户粒度生成含/不含 is_ads 维度的双层聚合；`grouping(is_ads)=1` 时 is_ads 填充为 `__ALL__` |
| 13 | **INSERT OVERWRITE** | 在 `traffic_exp_aggr` 上按 (mapping_general, is_ads, exp_group_id) 再次聚合，将用户粒度 UV 转化为全局 UV（`sum(if(xxx > 0, 1, 0))`），写入目标表分区 |

### 注意事项

1. **UV 计算为两阶段聚合**：第 12 步在用户粒度保留各指标，第 13 步再用 `sum(if(xxx > 0, 1, 0))` 统计 UV，确保去重准确。跨分区/维度手动 SUM UV 字段会破坏该逻辑，详见查询须知。
2. **`__ALL__` 行来自 GROUPING SETS**：`is_ads = '__ALL__'` 行与明细行同时存在于同一分区，查询时须明确筛选，避免重复聚合。
3. **前日 CSPU 标签依赖**：cheapest model 候选集依赖 `date_sub(local_date, 1)` 的 CSPU 订单标签，若前日数据缺失或延迟，会影响价格力候选商品范围的准确性。
4. **实验 scene_id 白名单硬编码**：`exp_traffic_info` 中的 scene_id 列表在 SQL 中硬编码，scene_id 的增删需同步修改 ETL 脚本。
5. **单 writer、静态分区写入**：本表为单 ETL 文件写入，`INSERT OVERWRITE` 按 `grass_region` + `local_date` 覆盖分区，重跑幂等，无 multi-writer 风险。
6. **order/GMV 归因逻辑为 copy 归因**：注释明确说明 order 和 GMV 场景指标通过归因（union all）逻辑得出，而非直接归属，曝光（imp）和点击不使用 copy 逻辑，分析时需注意两类指标的口径差异。

---

*文档生成时间：2026-05-17*
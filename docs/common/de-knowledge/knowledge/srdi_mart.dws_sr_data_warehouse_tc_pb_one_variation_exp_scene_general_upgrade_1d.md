<!-- ads-workspace-gdoc-sync: gdoc_id=14KhGBVUQrT2ZxhBuNjGE6SXgSQLPvgt2hOyW0ypYAuo gdoc_url=https://docs.google.com/document/d/14KhGBVUQrT2ZxhBuNjGE6SXgSQLPvgt2hOyW0ypYAuo/edit -->

# srdi_mart.dws_sr_data_warehouse_tc_pb_one_variation_exp_scene_general_upgrade_1d

**分层：** DWS（数据汇总层）
**主键：** `exp_group_id` + `is_ads` + `is_item_card` + `mapping_general` + `shop_scs_type` + `business_type` + `grass_region` + `local_date` + `local_hour`
**分区：** `grass_region`（地区）/ `local_date`（日期）/ `local_hour`（小时）
**更新频率：** 每日按小时分区覆盖写入（INSERT OVERWRITE）
**引用频次/访问频次：** 1733

---

## 业务描述

本表为搜索与推荐（S&R）体系下，**One Variation（单变体）实验场景通用升级版**的每日聚合宽表，服务于 A/B 实验效果分析。

核心业务场景：
- **实验流量归因**：将用户流量按实验分组（`exp_group_id`，对应 experiment_id 163151/163152/163153）拆分，统计各分组在不同场景（搜索、推荐等）下的曝光、点击、下单、GMV 等核心指标。
- **最优 CSPU/商品分析**：识别平台最便宜 CSPU（Cheapest CSPU）和 Winner CSPU 对应的商品/模型，统计其在实验中的曝光与转化表现，支持 One Variation 商品策略效果评估。
- **场景全量指标汇总**：按场景（Search、Daily Discover、You May Also Like、Post Purchase、S&R 全量、RCMD）、广告/非广告、商品卡/非商品卡等维度汇总全日曝光、GMV、广告营收等指标（`*_1d` 后缀字段为全日口径）。
- **SCS 店铺分层**：结合 SCS 店铺类型（`shop_scs_type`）进行分层分析，评估不同店铺类型的商品在实验中的表现差异。

适合回答的问题：
- 某实验分组在搜索/推荐场景下，最便宜 CSPU 商品的曝光量和成交量是多少？
- 实验各分组的全日 GMV、995 分位 GMV、广告营收对比如何？
- SCS 店铺与非 SCS 店铺在实验中的 One Variation 商品转化率差异？
- 不同 `business_type` 下平台最便宜 CSPU 的整体覆盖情况？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 地区分区，如 `ID`、`TH`、`PH` 等 |
| `local_date` | date | 本地日期分区，格式 `yyyy-MM-dd` |
| `local_hour` | int | 本地小时分区（0–23），与曝光明细的小时粒度对齐 |

### 维度：实验与场景分组

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | bigint | A/B 实验分组 ID，来源于实验管理系统（experiment_id 163151/163152/163153） |
| `mapping_general` | string | 场景标识，取值包括：`Search`、`Daily Discover`、`You May Also Like`、`Post Purchase`、`S&R__ALL__`、`RCMD`（后两者为聚合场景） |
| `is_ads` | string | 是否广告流量，`__ALL__` 表示全量（不区分广告/自然） |
| `is_item_card` | string | 是否商品卡（Item Card）流量，`__ALL__` 表示全量 |
| `shop_scs_type` | string | 店铺 SCS 类型，取值：`scs-local`、`scs-cb`、`non-scs` |
| `business_type` | int | 商品业务类型，来源于 One Variation 模型分析表；1/2 对应 Cheapest CSPU，3/4 对应 Winner CSPU |

### 指标：商品级别（Item/Model 粒度）

| 字段 | 类型 | 说明 |
|---|---|---|
| `item_imp_cnt` | bigint | 最便宜商品（cheapest item）在实验分组中的曝光次数 |
| `item_click_cnt` | bigint | 最便宜商品在实验分组中的点击次数 |
| `item_order_cnt` | double | 最便宜商品在实验分组中的下单量 |
| `item_gmv` | double | 最便宜商品在实验分组中的 GMV（本地货币） |
| `model_order_cnt` | double | 命中最便宜 Model 的下单量（比 item 粒度更细，需匹配 model_id 和 business_type） |
| `model_gmv` | double | 命中最便宜 Model 的 GMV |

### 指标：CSPU 曝光与转化（平台口径）

| 字段 | 类型 | 说明 |
|---|---|---|
| `cheapest_cspu_imp_cnt` | bigint | 最优 CSPU 商品曝光次数：business_type 3/4 取 winner_cspu_imp_cnt，business_type 1/2 取 cheapest_cspu_imp_cnt |
| `cheapest_cspu_order_cnt` | double | 最优 CSPU 对应 Model 的下单量：business_type 3/4 取 winner_cspu_order_cnt，business_type 1/2 取 cheapest_cspu_order_cnt |
| `platform_cheapest_cspu_imp_cnt` | bigint | 平台口径最便宜 CSPU（winner + cheapest 合并）的商品曝光次数 |
| `platform_cheapest_cspu_order_cnt` | double | 平台口径最便宜 CSPU（winner + cheapest 合并）的 Model 下单量 |

### 指标：场景全量（当前小时截面，预留字段）

| 字段 | 类型 | 说明 |
|---|---|---|
| `scene_imp_uv` | bigint | 场景曝光 UV（当前版本恒为 NULL，预留字段） |
| `scene_imp_cnt` | bigint | 场景曝光 PV（当前版本恒为 NULL，预留字段） |
| `scene_order_cnt` | double | 场景下单量（当前版本恒为 NULL，预留字段） |
| `scene_gmv_995` | double | 场景 995 分位截断 GMV（当前版本恒为 NULL，预留字段） |
| `scene_pc2_gmv` | double | 场景 PC2 GMV（当前版本恒为 NULL，预留字段） |
| `scene_ads_rev_usd` | double | 场景广告营收 USD（当前版本恒为 NULL，预留字段） |

### 指标：场景全日汇总（_1d 口径）

| 字段 | 类型 | 说明 |
|---|---|---|
| `scene_imp_uv_1d` | bigint | 全日场景曝光 UV（去重用户数，is_ads/is_item_card 为 `__ALL__` 时有效） |
| `scene_imp_cnt_1d` | bigint | 全日场景曝光 PV |
| `scene_order_cnt_1d` | double | 全日场景下单量 |
| `scene_gmv_1d` | double | 全日场景 GMV（未截断） |
| `scene_gmv_995_1d` | double | 全日场景 995 分位截断 GMV（用于剔除极端高 GMV 用户影响） |
| `scene_pc2_gmv_1d` | double | 全日场景 PC2 GMV（二次购买 GMV） |
| `scene_ads_rev_usd_1d` | double | 全日场景广告营收（USD），仅在 `is_ads='__ALL__'` 且 `is_item_card='__ALL__'` 时关联有效 |

---

## 查询使用须知

### 必须包含的过滤条件

- **必须指定分区字段**，否则触发全表扫描：
  ```sql
  WHERE grass_region = 'ID'
    AND local_date = '2025-01-01'
  ```
- `local_hour` 为实验数据的小时粒度分区，若需全日汇总建议直接使用 `*_1d` 字段，而非按 `local_hour` 聚合。

### 不可直接 SUM 的字段

- **`scene_imp_uv_1d`**：为全日 COUNT DISTINCT 去重指标，跨多行 SUM 会重复计数，不可直接累加。
- **`scene_gmv_995_1d`**：为经过 995 分位截断的 GMV，已是派生预聚合指标，不可与 `scene_gmv_1d` 混用求和。
- **`scene_ads_rev_usd_1d`**：仅在 `is_ads = '__ALL__'` 且 `is_item_card = '__ALL__'` 的行上有意义，跨维度聚合时需注意过滤，避免重复累加。
- **`cheapest_cspu_order_cnt` / `platform_cheapest_cspu_order_cnt`**：为按 business_type 条件分支计算的下单量，汇总时应注意 `business_type` 的语义差异（1/2 vs 3/4 不可叠加）。

### 时效性说明

- 本表为每日调度的 `_1d` 表，`*_1d` 字段反映**全日累计**指标（当日 00:00–23:59）。
- `local_hour` 分区与上游明细表的小时切片对齐，但场景全量 `*_1d` 指标在所有小时行中均写入相同全日聚合值，**非小时增量**。
- `scene_imp_uv`、`scene_imp_cnt`、`scene_order_cnt`、`scene_gmv_995`、`scene_pc2_gmv`、`scene_ads_rev_usd` 六个无 `_1d` 后缀的场景字段当前版本恒为 NULL，不可用于计算。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `abtest.shopee_experiment_admin_db__group_dimension_tab__reg_continuous_s0_live` | 获取目标实验（experiment_id 163151/163152/163153）的实验分组 ID 列表 |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取用户与实验分组的归属关系（assignment log） |
| `srdi_mart.dws_sr_data_warehouse_tc_pb_basic_aggr_1d` | 搜推场景流量明细聚合表，提供曝光、点击、下单、GMV、PC2 GMV 等核心行为指标 |
| `srdi_mart.dim_sr_data_warehouse_pb_all_cspu_link_analysis_hf` | 所有 CSPU 与 Model/Item 的映射关系（小时频次维度表） |
| `srdi_mart.dim_sr_data_warehouse_pb_one_variation_model_analysis_hf` | One Variation 最便宜 CSPU 对应的 Model 列表及 business_type（小时频次维度表） |
| `regds_listing.dim_scs_shop_list_df` | SCS 店铺名单，提供店铺的 SCS 类型（scs-local / scs-cb） |
| `srdi_mart.dws_sr_data_warehouse_tc_scene_995_threshold_1d` | 各场景 GPO 的 995 分位阈值，用于截断极端 GMV |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告消耗明细，提供用户级别的广告营收 USD |
| `mp_paidads.dim_entry_point_mapping_v2` | 广告入口点与流量类型（traffic_type）的映射关系 |

---

## ETL 逻辑摘要

### 数据流

```
实验分组信息 ──┐
用户实验归属 ──┤──► 实验用户集合
               │
流量明细聚合 ──┤──► 实验用户流量（场景+小时粒度）
               │
最便宜CSPU维度─┤──► 最便宜Item/Model/CSPU列表
SCS店铺维度 ──┘
               │
               ├──► exp_cheapest：按cheapest item/model聚合实验指标（GROUPING SETS）
               ├──► traffic_exp_cspu：CSPU维度曝光/转化（GROUPING SETS）
               ├──► scene_data：场景全日指标（含995分位截断，去重UV）
               └──► exp_ads：实验分组广告营收
                              │
                              ▼
              INSERT OVERWRITE 目标表（四路 LEFT JOIN 汇合）
```

### 关键步骤

1. **实验分组筛选**（`exp_info`）：从实验管理系统拉取指定实验（163151/163152/163153）的有效分组 ID。

2. **实验用户圈定**（`user_exp_raw` → `user_exp`）：从用户实验归属表取当日 assignment log，与实验分组 ID inner join，得到本次分析的实验用户集合。

3. **流量数据准备**（`traffic_raw` → `traffic_exp_step1` → `traffic_exp`）：从基础聚合表取指定场景的流量明细，join 实验用户后，额外追加 `RCMD` 虚拟场景（Daily Discover + You May Also Like + Post Purchase 的合并），同时追加 `S&R__ALL__` 全量场景（来自上游已含的字段值）。

4. **流量实验聚合**（`traffic_exp_aggr`）：按 `local_hour`、`exp_group_id`、`is_item_card`、`is_ads`、`mapping_general`、`shop_id`、`item_id`、`model_id` 汇总曝光/点击/下单/GMV。

5. **CSPU 维度表构建**：
   - `all_cspu_model`：全量 CSPU-Model-Item 映射（小时粒度）。
   - `cheapest_model_list`：最便宜 CSPU 对应的 Model 列表，关联 SCS 店铺类型，inner join 全量 CSPU 映射过滤无效数据。
   - `cheapest_item_list` / `cheapest_cspu_list`：从上述 Model 列表派生的 Item 和 CSPU 粒度列表。
   - `cheapest_cspu_all_model`：全量 CSPU 对应的所有 Model（含 winner/cheapest 两类 business_type）。
   - `winner_cspu_model_list` / `cheapest_cspu_model_list`：按 business_type（3/4 vs 1/2）分别拆分 winner 和 cheapest CSPU 的 Model 列表。
   - `winner_cspu_item_list` / `cheapest_cspu_item_list`：对应 Item 粒度列表。

6. **实验 Cheapest 指标聚合**（`exp_cheapest_step1` → `exp_cheapest`）：将实验流量与 cheapest item/model 列表 join，统计 item 粒度和 model 粒度的曝光/下单/GMV，使用 GROUPING SETS 展开 `is_item_card` × `is_ads` 四个维度组合。

7. **CSPU 曝光/转化聚合**（`traffic_exp_cspu`）：将实验流量分别与 winner/cheapest 的 Model 列表和 Item 列表 left join，汇总各类 CSPU 的曝光量和转化量，同样使用 GROUPING SETS 展开维度。

8. **场景全日指标**（`scene_data_step1` → `scene_data`）：对全日实验流量（非小时粒度）按用户聚合后，关联 995 分位阈值截断 GMV，再按 GROUPING SETS 汇总场景级全日指标（含去重 UV）。

9. **广告营收归因**（`ads_raw_step1` → `ads_raw_step2` → `ads` → `exp_ads`）：从广告消耗明细按 traffic_type 归类，追加 `S&R__ALL__` 和 `RCMD` 虚拟场景，join 实验用户，汇总各分组广告营收。

10. **最终写入**（INSERT OVERWRITE）：以 `exp_cheapest` 为主表，left join `scene_data`（场景全日指标）、`exp_ads`（广告营收，仅 is_ads/is_item_card 均为 `__ALL__` 时关联）、`traffic_exp_cspu`（CSPU 曝光/转化），合并输出至目标分区。场景字段（无 `_1d` 后缀）在此版本中均写入 NULL，保留字段结构兼容性。

### 注意事项

- **单写入文件，无 multi-writer 风险**：本表仅由一个 ETL 文件写入，不存在多文件并发写同一分区的冲突风险。
- **NULL 字段**：`scene_imp_uv`、`scene_imp_cnt`、`scene_order_cnt`、`scene_gmv_995`、`scene_pc2_gmv`、`scene_ads_rev_usd` 六个字段在 INSERT 语句中明确写为 `null`，为历史兼容预留字段，不可用于分析。
- **广告营收字段关联限制**：`scene_ads_rev_usd_1d` 仅在 `is_ads = '__ALL__'` 且 `is_item_card = '__ALL__'` 的行有值，其他维度组合该字段为 NULL，使用前需严格过滤。
- **business_type 语义差异**：`cheapest_cspu_imp_cnt` 和 `cheapest_cspu_order_cnt` 的实际含义随 `business_type` 变化（1/2 取 cheapest，3/4 取 winner），汇总时不应跨 business_type 直接叠加。
- **GROUPING SETS 产生多行**：同一 `exp_group_id` + `mapping_general` 组合会因 `is_ads` 和 `is_item_card` 展开为 4 行（原始值 × 原始值、`__ALL__` × 原始值、原始值 × `__ALL__`、`__ALL__` × `__ALL__`），查询时需明确过滤维度值，避免重复计算。
- **`scene_data` 全日口径与小时分区不匹配**：`*_1d` 字段是基于全日用户聚合后计算的，写入时会在所有 `local_hour` 分区行中重复，不代表该小时的增量值。

---

*文档生成时间：2026-05-17*
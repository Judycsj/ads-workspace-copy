<!-- ads-workspace-gdoc-sync: gdoc_id=1lZ-Dtai2cUlYsnpFcYXzt4BB-O2tF70ztCMYcsFnWHw gdoc_url=https://docs.google.com/document/d/1lZ-Dtai2cUlYsnpFcYXzt4BB-O2tF70ztCMYcsFnWHw/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_item_category_platform_metrics_1d

**分层：** dws_search
**主键：** experiment_id + exp_group_id + platform + level1_global_be_category_id + level2_global_be_category_id + grass_region + local_date
**分区：** grass_region / local_date
**更新频率：** 每日（T+1）
**引用频次/访问频次：** 757

---

## 业务描述

本表是搜索 A/B 实验维度的商品类目 × 平台日粒度汇总宽表，服务于搜索实验效果分析场景。

表中将实验用户分组（experiment_id + exp_group_id）与搜索行为指标、GMV 指标及广告收入指标在**商品二级类目**和**平台**两个维度上进行交叉聚合，同时通过 `GROUPING SETS` 预聚合了多种维度组合（全平台、全类目、仅 level1 类目、仅 level2 类目等），支持多粒度下钻与上卷。

**核心业务场景：**
- 搜索 A/B 实验不同实验组的效果对比（曝光、点击、成交、GMV、广告收入）
- 按类目维度拆解实验效果，分析特定类目下的搜索表现
- 按平台（Android App / iOS App / PC Web 等）拆解实验效果
- 搜索量与搜索成功率的实验组对比

**适合回答的问题：**
- 实验组 A 与对照组 B 在全局搜索中的 GMV 差异是多少？
- 某实验组在 iOS 平台下，一级类目「电子产品」的搜索 GMV 相比对照组提升了多少？
- 各实验组的搜索量和搜索成功率在不同平台的分布如何？
- 搜索广告在不同实验分组下的收入表现如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区/站点标识（如 ID、MY、TH 等），分区键，查询时必须指定 |
| `local_date` | date | 数据日期（当地日期），分区键，查询时必须指定 |

### 维度：实验分组

| 字段 | 类型 | 说明 |
|---|---|---|
| `experiment_id` | bigint | A/B 实验 ID，来源于 `dim_sr_data_warehouse_abtest_user_group` |
| `exp_group_id` | bigint | 实验分组 ID（如实验组、对照组），来源于 `dim_sr_data_warehouse_abtest_user_group` |

### 维度：平台

| 字段 | 类型 | 说明 |
|---|---|---|
| `platform` | string | 用户访问平台，取值为 `android_app`、`ios_app`、`android_app_lite`、`pc_web`、`android_web`、`ios_web`、`other`；预聚合全平台汇总行时值为 `__ALL__` |

### 维度：商品类目

| 字段 | 类型 | 说明 |
|---|---|---|
| `level1_global_be_category_id` | string | 全球一级后端类目 ID；无类目时填 `NA`，预聚合全类目汇总行时值为 `__ALL__` |
| `level1_global_be_category` | string | 全球一级后端类目名称；无类目时填 `NA`，预聚合汇总行时值为 `__ALL__` |
| `level2_global_be_category_id` | string | 全球二级后端类目 ID；无类目时填 `NA`，预聚合全类目汇总行时值为 `__ALL__` |
| `level2_global_be_category` | string | 全球二级后端类目名称；无类目时填 `NA`，预聚合汇总行时值为 `__ALL__` |

### 指标：搜索曝光与用户

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 搜索结果商品曝光次数，来源于 `dws_sr_data_warehouse_platform_user_item_keyword_benchmark_1d` 的 `imp_cnt` 汇总 |
| `imp_uu` | bigint | 搜索结果有曝光的去重用户数（`imp_cnt > 0` 的 user_id 去重计数），**不可直接 SUM** |

### 指标：搜索行为

| 字段 | 类型 | 说明 |
|---|---|---|
| `click_cnt` | bigint | 搜索结果商品点击次数 |
| `search_volume` | bigint | 搜索量；以 (user_id, device_id, keyword) 为粒度统计有 view 行为的搜索去重次数（`view_cnt > 0`），**不可直接 SUM**，仅在 `level1_global_be_category = '__ALL__'` 且 `level2_global_be_category = '__ALL__'` 的行有值，其余行为 NULL |
| `search_success_result_volume` | bigint | 搜索成功量；以 (user_id, device_id, keyword) 为粒度统计有点击行为的搜索去重次数（`click_cnt > 0`），**不可直接 SUM**，仅在 `level1_global_be_category = '__ALL__'` 且 `level2_global_be_category = '__ALL__'` 的行有值，其余行为 NULL |

### 指标：GMV 与成交

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 搜索带来的订单量 |
| `gmv` | double | 搜索带来的 GMV（美元），来源于搜索基准表 |
| `pc2_gmv` | double | 搜索带来的 PC2 GMV（美元，付款后确认口径） |

### 指标：广告收入

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_revenue_usd` | double | 搜索广告收入（美元），来源于 `dws_sr_data_warehouse_ads_request_benchmark_advv_1d`，仅统计 `entrance = 1`（全局搜索入口）的广告收入 |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：分区字段，每次查询必须指定，否则触发全表扫描。
- **`local_date`**：分区字段，每次查询必须指定，建议明确指定单日或日期范围。

### 预聚合维度组合说明

本表由 `GROUPING SETS` 预聚合生成，同一 (experiment_id, exp_group_id) 下包含以下 8 种维度组合的汇总行：

| 组合 | platform | level1 类目 | level2 类目 |
|---|---|---|---|
| 1 | 具体平台 | 具体类目 | 具体类目 |
| 2 | `__ALL__` | 具体类目 | 具体类目 |
| 3 | 具体平台 | `__ALL__` | 具体 level2 |
| 4 | `__ALL__` | `__ALL__` | 具体 level2 |
| 5 | 具体平台 | 具体 level1 | `__ALL__` |
| 6 | `__ALL__` | 具体 level1 | `__ALL__` |
| 7 | 具体平台 | `__ALL__` | `__ALL__` |
| 8 | `__ALL__` | `__ALL__` | `__ALL__` |

**查询时务必通过 `platform`、`level1_global_be_category`、`level2_global_be_category` 等字段明确指定所需聚合粒度，避免重复计算。**

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `imp_uu` | 去重用户数，跨行 SUM 会导致重复计数 |
| `search_volume` | 去重搜索次数（`COUNT DISTINCT`），跨行 SUM 无意义 |
| `search_success_result_volume` | 去重搜索次数（`COUNT DISTINCT`），跨行 SUM 无意义 |

### `search_volume` 和 `search_success_result_volume` 的特殊说明

这两个字段的搜索量统计不区分类目维度（统计粒度为全局关键词），因此仅在 `level1_global_be_category = '__ALL__'` 且 `level2_global_be_category = '__ALL__'` 的行才有值，其他类目细分行该字段为 NULL。

### 时效性说明

- 本表为 **T+1 日粒度**（`_1d` 后缀），每日全量覆盖写入（`INSERT OVERWRITE`）对应分区。
- 数据通常在 T+1 早间完成更新，建议在使用前确认目标分区已落地。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取实验用户分组映射（user_id → experiment_id + exp_group_id），过滤搜索白名单用户及分配日志 |
| `srdi_mart.dim_sr_data_warehouse_item` | 获取商品类目信息（item_id → level1/level2 全球后端类目 ID 与名称） |
| `srdi_mart.dws_sr_data_warehouse_platform_user_item_keyword_benchmark_1d` | 搜索行为基准表，提供用户 × 商品 × 关键词粒度的曝光、点击、浏览、订单、GMV 等指标 |
| `srdi_mart.dws_sr_data_warehouse_ads_request_benchmark_advv_1d` | 搜索广告收入基准表，提供用户 × 商品粒度的广告曝光 revenue，过滤全局搜索入口（entrance = 1） |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group  ──┐
                                           │
dws_sr_data_warehouse_platform_user_item  ─┼─► dwm_search (搜索行为汇总)
    _keyword_benchmark_1d                  │        │
dim_sr_data_warehouse_item ────────────────┘        ├─► dws_exp_search (实验×类目×平台指标，GROUPING SETS)
                                                    └─► dws_exp_vol (搜索量，CUBE platform)
                                           
dws_sr_data_warehouse_ads_request         ──────────► dws_ads (广告收入)
    _benchmark_advv_1d                                    │
dim_sr_data_warehouse_item ────────────────────────────────► exp_ads_performance (实验×类目×平台广告收入)

dws_exp_search LEFT JOIN dws_exp_vol LEFT JOIN exp_ads_performance
    ──► INSERT OVERWRITE 目标表
```

### 关键步骤

1. **Statement 1 — `user_exp_mapping`**：从实验用户分组维表中筛选当日搜索白名单用户（`is_assignment_log = 1 AND is_search_whitelist = 1`），获得 user_id → (experiment_id, exp_group_id) 的映射。

2. **Statement 2 — `dim_item`**：从商品维表中获取当日商品 → 一/二级全球后端类目的映射。

3. **Statement 3 — `dwm_search`**：将搜索基准表（过滤 global_search / search_in_pdp / search_prefill 相关 feature_detail）与商品类目维表 LEFT JOIN，按用户 × 关键词 × 平台 × 类目分组，汇总曝光、点击、浏览、订单、GMV 等指标；platform 未知则归入 `other`，类目为空则填 `NA`。

4. **Statement 4 — `dws_exp_search`**：将 `dwm_search` 与实验用户映射 INNER JOIN，通过 `GROUPING SETS` 按 8 种维度组合聚合，产出实验组维度的曝光、去重用户数、点击、订单、GMV 指标；`NULL` 维度值替换为 `__ALL__`。

5. **Statement 5 — `dws_exp_vol`**：将 `dwm_search` 与实验用户映射 INNER JOIN，用 `CUBE(platform)` 聚合，统计搜索量（`view_cnt > 0` 的 (user_id, device_id, keyword) 去重）和搜索成功量（`click_cnt > 0` 的去重），不区分类目维度。

6. **Statement 6 — `dws_ads`**：将广告收入基准表（过滤 `entrance = 1` 全局搜索入口）与商品类目维表 LEFT JOIN，按用户 × 平台 × 类目聚合 revenue_usd。

7. **Statement 7 — `exp_ads_performance`**：将 `dws_ads` 与实验用户映射 INNER JOIN，通过与 Statement 4 相同的 `GROUPING SETS` 聚合广告收入。

8. **Statement 8 — INSERT OVERWRITE**：以 `dws_exp_search` 为主表，LEFT JOIN `dws_exp_vol`（关联条件：exp_group_id + platform 相同，且 **level1/level2 类目均为 `__ALL__`**，因此 search_volume 等字段仅在类目全汇总行有值），LEFT JOIN `exp_ads_performance`（关联条件：exp_group_id + platform + level1/level2 类目 ID 均相同），写入目标分区。

### 注意事项

- **单写入者**：本表仅由单个 ETL 文件写入，无 multi-writer 并发冲突风险。
- **`search_volume` / `search_success_result_volume` 的 NULL 分布**：最终 JOIN 逻辑中，`dws_exp_vol` 仅在 level1 和 level2 类目均为 `__ALL__` 时才能 JOIN 到，因此有类目细分的行中这两个字段为 NULL，属于设计预期，非数据质量问题。
- **GROUPING SETS 重复行风险**：目标表中同一 (experiment_id, exp_group_id, local_date, grass_region) 下存在多条聚合粒度不同的记录，查询时必须通过维度字段（尤其是 `platform`、`level1_global_be_category`、`level2_global_be_category` 的 `__ALL__` 标记）精确过滤，否则会产生重复计算。
- **平台归一化**：平台值仅保留 6 种已知平台，其余均归为 `other`；全量汇总行使用 `__ALL__`，查询时注意区分。
- **实验用户口径**：仅统计 `is_assignment_log = 1 AND is_search_whitelist = 1` 的用户，非全量用户数据。

---

*文档生成时间：2026-05-17*
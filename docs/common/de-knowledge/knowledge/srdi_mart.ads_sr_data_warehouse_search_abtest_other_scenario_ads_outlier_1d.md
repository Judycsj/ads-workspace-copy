<!-- ads-workspace-gdoc-sync: gdoc_id=1N2aMIn-KIB9qe6_RjbZ6RL_j8Y3PcxTi2YwDbGOnLBc gdoc_url=https://docs.google.com/document/d/1N2aMIn-KIB9qe6_RjbZ6RL_j8Y3PcxTi2YwDbGOnLBc/edit -->

# srdi_mart.ads_sr_data_warehouse_search_abtest_other_scenario_ads_outlier_1d

**分层：** ADS（应用数据服务层）
**主键：** `grass_region` + `local_date` + `exp_group_id` + `feature_group` + `target_type`
**分区：** `grass_region`（站点大区）, `local_date`（业务日期）
**更新频率：** 每日一次（T+1）
**引用频次 / 访问频次：** 44

---

## 业务描述

本表面向**搜索广告 A/B 实验分析**场景，聚焦于"其他场景"（Other Scenario）下各实验分组的广告关键指标，并在汇总阶段引入 **P99.9 异常值截断（Outlier Clipping）**，以消除极端大单对实验结论的干扰。

**核心业务场景：**
- 搜索广告 A/B 实验效果评估：按实验分组（`exp_group_id`）、特征分组（`feature_group`）、投放目标类型（`target_type`）多维拆解广告 GMV、Revenue、宽泛 GMV 等核心指标。
- 异常值处理对比：每个核心指标同时保留原始值（`*_usd`）与 P99.9 截断值（`*_usd_999`），支持实验置信度分析时选择更鲁棒的统计量。
- 仅覆盖通过白名单校验且有效分配的实验用户（`is_assignment_log = 1` 且 `is_search_whitelist = 1`）。

**适合回答的问题：**
- 某实验分组在特定站点、特定日期下的广告 GMV / Revenue 表现如何？
- 剔除异常大单后，各实验分组的指标差异是否显著？
- 不同 `feature_group` / `target_type` 组合下，实验组与对照组的广告效果对比。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点大区（如 SG、MY、TH 等），用于数据分区隔离 |
| `local_date` | date | 业务日期，数据统计所属自然日 |

### 维度：实验与特征分组

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_id` | bigint | A/B 实验分组 ID，标识实验组或对照组 |
| `feature_group` | string | 特征分组标识；源数据中 `'all'` 会被映射为 `'__ALL__'`，表示全量汇总 |
| `target_type` | string | 广告投放目标类型；原始值为 NULL 时映射为 `'__ALL__'`，表示不区分目标类型的汇总行（通过 `CUBE` 生成） |

### 指标：广告核心指标（原始值）

| 字段 | 类型 | 说明 |
|---|---|---|
| `revenue_usd` | double | 广告直接 Revenue（美元），对应直接归因的广告收入，原始值未经异常值截断 |
| `ads_gmv_usd` | double | 广告直接 GMV（美元），原始值未经异常值截断 |
| `broad_gmv_usd` | double | 广告宽泛归因 GMV（美元），原始值未经异常值截断 |

### 指标：广告核心指标（P99.9 截断值）

| 字段 | 类型 | 说明 |
|---|---|---|
| `revenue_usd_999` | double | 广告直接 Revenue（美元），仅统计用户级直接 ABS（平均每单 GMV）≤ P99.9 阈值的记录 |
| `ads_gmv_usd_999` | double | 广告直接 GMV（美元），仅统计用户级直接 ABS ≤ P99.9 阈值的记录 |
| `broad_gmv_usd_999` | double | 广告宽泛 GMV（美元），仅统计用户级宽泛 ABS ≤ P99.9 阈值的记录 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区过滤（强制）**：查询时必须同时指定 `grass_region` 和 `local_date`，否则将触发全分区扫描，造成严重性能问题：
  ```sql
  WHERE grass_region = 'SG'
    AND local_date = '2024-01-01'
  ```

### 不可直接 SUM 的字段

- `revenue_usd_999`、`ads_gmv_usd_999`、`broad_gmv_usd_999`：这三个字段是对**用户级 ABS 进行截断后**再汇总的结果，**不可跨 `feature_group` 或 `target_type` 直接累加**，跨维度聚合须重新从用户粒度数据计算，否则截断逻辑会失效（截断条件依赖用户级别的 ABS 计算，聚合后的数字本身不具备可再次求和的语义）。
- `revenue_usd`、`ads_gmv_usd`、`broad_gmv_usd`：原始值在同一 `exp_group_id` + `feature_group` + `target_type` 组合内可以直接使用，但注意 `target_type = '__ALL__'` 行是由 `CUBE` 生成的汇总行，**与其他 `target_type` 明细行存在重复计数**，不可混合 SUM。
- `feature_group = '__ALL__'` 行同理，是全量汇总行，混合其他 `feature_group` 求和会导致重复计数。

### 时效性说明

- 本表为 **日粒度（`_1d`）** 表，每日 T+1 全量刷新当日分区（`INSERT OVERWRITE PARTITION`）。
- 数据反映的是 `local_date` 当日的累计指标，不包含历史滚动窗口。

### 其他注意事项

- P99.9 阈值来源于 `srdi_mart.ads_sr_data_warehouse_platform_feature_group_ads_outlier_1d`，若该上游表当日数据缺失，截断值字段（`*_999`）将为 NULL，需关注上游数据质量。
- 实验用户范围限定为 `is_assignment_log = 1` 且 `is_search_whitelist = 1` 的用户，未进入白名单的用户不会出现在本表中。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取当日有效实验用户及其所属实验分组（`exp_group_id`），并过滤白名单用户 |
| `srdi_mart.ads_sr_data_warehouse_platform_feature_group_ads_outlier_1d` | 获取各 `feature_group` 下直接归因（`direct_ads_abs`）和宽泛归因（`broad_ads_abs`）的 P99.9 异常值阈值 |
| `srdi_mart.dws_sr_data_warehouse_ads_request_benchmark_advv_1d` | 获取用户级广告请求明细，包含 Revenue、GMV、订单数等原始指标，及 `feature_groups` 数组（用于 explode 展开） |

---

## ETL 逻辑摘要

### 数据流

```
dim_sr_data_warehouse_abtest_user_group          → [user_exp]        过滤有效实验用户
ads_sr_data_warehouse_platform_feature_group_ads_outlier_1d
  ├─ outlier_type='broad_ads_abs', percentile=0.999  → [ads_outlier_broad]  宽泛归因P99.9阈值
  └─ outlier_type='direct_ads_abs', percentile=0.999 → [ads_outlier_direct] 直接归因P99.9阈值
dws_sr_data_warehouse_ads_request_benchmark_advv_1d
  → explode(feature_groups)                       → [dws_advv_request_raw]  用户×feature_group 明细
  → CUBE(target_type) 汇总 + 计算用户级ABS         → [dws_advv_request_mid]
  → JOIN 阈值表，条件过滤计算截断指标               → [dws_advv_request]
  → JOIN user_exp，按实验分组聚合                  → [ads_exp] (CACHE)
  → INSERT OVERWRITE 写入目标分区
```

### 关键步骤

| 步骤 | 临时视图 / 操作 | 说明 |
|---|---|---|
| Step 1 | `user_exp` | 从实验用户维表筛选当日有效白名单用户及实验分组 |
| Step 2 | `ads_outlier_broad` | 取宽泛归因 P99.9 阈值，按 `feature_group` 聚合（取 MAX 处理可能的重复行），`'all'` 映射为 `'__ALL__'` |
| Step 3 | `ads_outlier_direct` | 取直接归因 P99.9 阈值，逻辑同 Step 2 |
| Step 4 | `dws_advv_request_raw` | 对 DWS 明细表进行 `explode(feature_groups)` 展开，过滤 `product_types` 包含 `'__ALL__'` 且 `user_id > 0` 的记录，按用户×feature_group×target_type 聚合 |
| Step 5 | `dws_advv_request_mid` | 在 Step 4 基础上对 `target_type` 进行 `CUBE` 展开（生成含 `'__ALL__'` 的汇总行），同时计算用户级直接 ABS（`direct_abs = ads_gmv_usd / ads_order_cnt`）和宽泛 ABS（`broad_abs = broad_gmv_usd / ads_broad_order_cnt`） |
| Step 6 | `dws_advv_request` | LEFT JOIN 阈值表（Broadcast），对原始指标保留全量，对截断指标仅累计 ABS ≤ P99.9 阈值的用户贡献 |
| Step 7 | `ads_exp`（CACHE） | INNER JOIN 实验用户表，按实验分组聚合，过滤出实验白名单用户的指标，结果缓存加速后续写入 |
| Step 8 | `INSERT OVERWRITE` | 以 `REPARTITION(8)` 写入目标表对应 `grass_region` + `local_date` 分区 |

### 注意事项

- **单一 Writer**：本表仅由一个 ETL 文件写入（`multi_writer = false`），无并发写入风险。
- **分区覆盖写入**：使用 `INSERT OVERWRITE PARTITION`，每次执行会完整覆盖当日分区，重跑安全。
- **CUBE 生成汇总行**：`target_type` 维度通过 `CUBE` 展开，`'__ALL__'` 行为系统生成的跨类汇总，使用时需与明细行区分，避免重复计算。
- **阈值表 LEFT JOIN**：若 `ads_outlier_broad` 或 `ads_outlier_direct` 中某 `feature_group` 无阈值记录，对应的截断指标（`*_999`）将因 `NULL` 阈值导致条件 `abs <= NULL` 恒为 false，截断值会为 0 而非原始值，需关注上游阈值表的覆盖完整性。
- **Broadcast Join 提示**：Step 6 中对阈值表使用 `BROADCAST` hint，要求阈值表数据量小，若 `feature_group` 数量大幅增加需评估是否仍适合广播。

---

*文档生成时间：2026-05-17*
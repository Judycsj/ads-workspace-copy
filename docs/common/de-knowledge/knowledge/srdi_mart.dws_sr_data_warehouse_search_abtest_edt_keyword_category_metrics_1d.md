<!-- ads-workspace-gdoc-sync: gdoc_id=1COTA2exKQLzd6uAh2iirsFO6Cpv1z-cZO_8P4gm0p-U gdoc_url=https://docs.google.com/document/d/1COTA2exKQLzd6uAh2iirsFO6Cpv1z-cZO_8P4gm0p-U/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_edt_keyword_category_metrics_1d

**分层：** dws_search
**主键：** grass_region + local_date + scene_id + layer_id + experiment_id + exp_group_id + edt_type + keyword_l1_category_id + keyword_l2_category_id
**分区：** grass_region, local_date
**更新频率：** 每日 T+1 全量覆盖写入（INSERT OVERWRITE）
**访问频次：** 1197

---

## 业务描述

本表是搜索 A/B 实验（ABTest）维度下，按 **EDT（预计送达时间）类型** 与 **关键词品类** 联合聚合的日粒度宽表，服务于搜索推荐业务的实验效果分析。

**核心业务场景：**

1. **实验效果评估**：依据实验组（scene / layer / experiment / exp_group）维度，评估不同搜索策略对曝光、点击、下单、GMV 等核心指标的影响。
2. **EDT 分层分析**：将商品展示时的预计送达时间按小时/天粒度分桶（如 `0h`、`1d`、`4-7d`、`no_edt_info` 等），分析不同 EDT 区间对转化和 GMV 的差异影响。
3. **关键词品类下钻**：支持按一级/二级关键词品类进一步细化实验效果，回答"哪类目的搜索词在实验组下 GMV 提升更显著"等问题。
4. **广告收入分析**：结合广告消耗数据，评估实验对搜索广告收入（ads_revenue）的影响。
5. **GMV 离群值处理**：提供两套 GMV 截尾（Winsorization）指标——全局 ABS 995 分位截断（`gmv_995`）及按商品高/低 GMV 分类分别截断（`high_gmv_995_v2` / `low_gmv_995_v2`），提升统计稳健性。

**适合回答的问题：**
- 某实验组在特定品类下，相较对照组 GMV / 订单量提升了多少？
- 带 EDT 信息的搜索结果在点击率和下单率上与无 EDT 信息有何差异？
- 实验中搜索 UU 数在各品类的分布情况如何？
- 广告收入在不同实验组和 EDT 区间上的分布？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区/国家标识，如 `US`、`BR` 等，作为物理分区键 |
| `local_date` | date | 业务日期（本地时区），作为物理分区键，格式 `yyyy-MM-dd` |

---

### 维度：实验层级信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `scene_id` | bigint | 实验场景 ID，来源于实验白名单维表 |
| `scene_name` | string | 实验场景名称 |
| `layer_id` | bigint | 实验层 ID |
| `layer_name` | string | 实验层名称 |
| `experiment_id` | bigint | 实验 ID |
| `experiment_name` | string | 实验名称 |
| `exp_group_id` | bigint | 实验分组 ID（如对照组、实验组） |
| `exp_group_name` | string | 实验分组名称 |

---

### 维度：EDT 类型

| 字段 | 类型 | 说明 |
|---|---|---|
| `edt_type` | string | 预计送达时间分桶标签，取值包括：`0h`、`1h`、`2h`、`3h`、`4h`、`>4h`、`0d`、`1d`、`2d`、`3d`、`4-7d`、`>7d`、`no_edt_info`、`NULL`、`__ALL__`（汇总行） |

---

### 维度：关键词品类

| 字段 | 类型 | 说明 |
|---|---|---|
| `keyword_l1_category` | string | 关键词一级品类名称；汇总行值为 `__ALL__` |
| `keyword_l1_category_id` | string | 关键词一级品类 ID；汇总行值为 `__ALL__` |
| `keyword_l2_category` | string | 关键词二级品类名称；汇总行值为 `__ALL__` |
| `keyword_l2_category_id` | string | 关键词二级品类 ID；汇总行值为 `__ALL__` |

---

### 指标：流量与转化

| 字段 | 类型 | 说明 |
|---|---|---|
| `search_uu` | bigint | 搜索独立用户数（UV）；仅在 `edt_type = '__ALL__'` 行有值，其余 EDT 分桶行为 NULL；通过 COUNT DISTINCT 计算，**不可直接 SUM** |
| `imp_cnt` | bigint | 曝光次数（商品搜索结果曝光总量） |
| `click_cnt` | bigint | 点击次数 |
| `order_cnt` | double | 下单量（含小数，来源于行为日志加权） |

---

### 指标：GMV（全量）

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv` | double | 搜索成交 GMV（美元），未截尾全量值 |

---

### 指标：GMV 截尾 v1（全局 ABS 995 分位）

| 字段 | 类型 | 说明 |
|---|---|---|
| `gmv_995` | double | 按用户 ABS（平均订单价值）全局 995 分位截断后的 GMV；**不可直接 SUM 后与其他分区比较** |
| `gmv_uu_995` | double | ABS 995 分位截断后 GMV 除以有效曝光 UU 数；为派生均值指标，**不可直接 SUM** |
| `pc2_gmv_995` | double | ABS 995 分位截断后的 PC2（二次购买）GMV |
| `pc2_gmv_uu_995` | double | ABS 995 分位截断后 PC2 GMV 除以有效曝光 UU 数；派生均值指标，**不可直接 SUM** |

---

### 指标：GMV 截尾 v2（分品类高/低 GMV 分档截断）

| 字段 | 类型 | 说明 |
|---|---|---|
| `high_gmv_995_v2` | double | 高 GMV 品类商品按品类级 995 分位截断后的 GMV |
| `high_gmv_order_cnt_995_v2` | double | 高 GMV 品类中截断范围内的订单数 |
| `high_pc2_gmv_995_v2` | double | 高 GMV 品类按 995 分位截断后的 PC2 GMV |
| `low_gmv_995_v2` | double | 低 GMV 品类商品按品类级 995 分位截断后的 GMV |
| `low_gmv_order_cnt_995_v2` | double | 低 GMV 品类中截断范围内的订单数 |
| `low_pc2_gmv_995_v2` | double | 低 GMV 品类按 995 分位截断后的 PC2 GMV |

---

### 指标：EDT 均值

| 字段 | 类型 | 说明 |
|---|---|---|
| `avg_edt` | double | 实际送达天数均值（`edtmax_in_days` 之和除以有有效 EDT 记录数）；为派生均值指标，**不可直接 SUM** |

---

### 指标：广告收入

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_revenue` | double | 搜索广告消耗金额（美元），来源于广告绩效日志 |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区过滤**：查询时必须同时指定 `grass_region` 和 `local_date`，避免全表扫描：
  ```sql
  WHERE grass_region = 'US'
    AND local_date = '2024-01-01'
  ```
- **实验维度过滤**：如需分析特定实验，应额外过滤 `experiment_id` 或 `exp_group_id`，避免混合多个实验的数据。
- **EDT 类型过滤**：`edt_type` 包含 `__ALL__`（全量汇总）和各细粒度分桶，聚合全量数据时应选取 `edt_type = '__ALL__'`，避免重复计数。
- **品类维度过滤**：`keyword_l1_category` / `keyword_l2_category` 含 `__ALL__` 汇总行，使用时需明确是否要汇总行。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `search_uu` | COUNT DISTINCT 去重指标，跨行相加会重复计数 |
| `gmv_uu_995` | 派生均值（GMV / UU），相加无业务意义 |
| `pc2_gmv_uu_995` | 派生均值（PC2 GMV / UU），相加无业务意义 |
| `avg_edt` | 派生均值（EDT 总和 / 有效记录数），相加无业务意义 |
| `gmv_995` | 预聚合截尾指标，跨 EDT 类型/品类维度直接相加可能造成双重计数（与 `__ALL__` 行不一致） |
| `gmv_uu_995`、`pc2_gmv_uu_995` | 同上，均值类指标不可跨行 SUM |

### 数据粒度与多维汇总行说明

- 本表通过 `GROUPING SETS` 预聚合，同时存在多粒度行：
  - `(exp_group_id, edt_type, l1_category, l2_category)`：最细粒度
  - `(exp_group_id, edt_type, l1_category)`：去掉二级品类的汇总
  - `(exp_group_id, edt_type)`：品类全汇总
- 汇总行的品类字段值为 `__ALL__`，查询时须明确所需粒度，**避免将多粒度行混合 SUM**。

### 时效性说明

- 本表为 `_1d` 日粒度表，每日全量覆盖写入，数据时效为 **T+1**（即当日数据于次日产出）。
- `search_uu` 仅在 `edt_type = '__ALL__'` 时有值，EDT 分桶行该字段为 NULL，系 ETL JOIN 逻辑设计，非数据缺失。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_search_scene_layer_whitelist` | 获取搜索实验白名单中的 scene_id、layer_id |
| `srdi_mart.dim_sr_data_warehouse_abtest_group` | 获取实验组元数据（scene/layer/experiment/exp_group 层级信息） |
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取用户与实验组的分流映射关系 |
| `srdi_mart.dwd_sr_data_warehouse_search` | 搜索行为明细日志，用于计算搜索 UU |
| `srdi_mart.dim_sr_data_warehouse_keyword_di` | 关键词品类维表，用于关联搜索词的一/二级品类 |
| `srdi_mart.dwd_fp_search_base_1d` | 搜索漏斗行为数据（曝光/点击/下单/GMV），核心事实表 |
| `sls_mart.dwd_edt_order_info_df_${grass_region}` | 订单级别 EDT 实际送达信息，用于计算 avg_edt |
| `srdi_mart.dwd_sr_data_warehouse_search_be_log` | 搜索后端日志，提供商品级 EDT 分桶信息 |
| `srdi_mart.dim_sr_data_warehouse_category_gmv_outlier` | 品类 GMV 995 分位阈值维表，用于 v2 截尾计算 |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维表，用于关联商品的高/低 GMV 品类标签 |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告绩效日志，用于计算搜索入口广告消耗 |

---

## ETL 逻辑摘要

### 数据流

```
实验维表 / 用户分流表
        ↓
搜索行为日志 + 关键词品类维表
        ↓
搜索漏斗行为数据 (dwd_fp_search_base_1d)
    + 订单 EDT 信息
    + 搜索后端 EDT 分桶 (be_log)
        ↓
商品/品类 GMV 离群阈值维表
        ↓
[主指标汇总] [GMV v2截尾] [ADS广告] [搜索UU]
        ↓
JOIN 拼接 + 实验组维度关联
        ↓
dws_sr_data_warehouse_search_abtest_edt_keyword_category_metrics_1d
```

### 关键步骤

**Step 1 — 实验白名单与维表准备**
- 从白名单维表中提取有效 `scene_id` 和 `layer_id`。
- 从实验组维表中 CACHE 当日搜索白名单内的实验组元数据（`dim_exp`）。
- 从用户分流维表中提取用户 → 实验组映射（`user_exp_mapping`），限定搜索白名单且为有效分流日志。

**Step 2 — 搜索 UU 计算**
- 从搜索行为日志（`dwd_sr_data_warehouse_search`，`operation = 'view'`）关联关键词品类维表，得到用户级品类标签。
- 与用户分流映射 JOIN，按 `GROUPING SETS`（品类全量 / 一级品类 / 全汇总）计算 `COUNT(DISTINCT user_id)` 作为 `search_uu`。

**Step 3 — 漏斗数据与 EDT 信息融合**
- 从 `dwd_fp_search_base_1d` 提取当日搜索漏斗数据，分为无订单行（`order_id IS NULL`）和有订单行（关联实际 EDT 送达信息）两路 UNION ALL，形成 `dwd_fp_join_edt_order`。
- 从搜索后端日志（`dwd_sr_data_warehouse_search_be_log`）按 `edt_max` / `edt_max_hours` 生成 EDT 分桶数组（`edt_types`），涵盖小时精度（`0h`~`>4h`）和天精度（`0d`~`>7d`）及无 EDT 信息标签。
- 将漏斗数据与后端日志按 `request_id + item_id` LEFT JOIN，聚合至用户×品类×商品×订单粒度，得到 `fp_edt_order_join_be_log`（含 `edt_numerator` / `edt_denominator` 用于 avg_edt 计算）。

**Step 4 — 主指标聚合（GMV v1 截尾）**
- 对用户级数据按 `edt_types` 数组 LATERAL VIEW EXPLODE 展开为单 `edt_type` 行，JOIN 用户分流映射。
- 计算全局用户 ABS（平均订单价值）的 995 分位数（`global_search_abs995_benchmark`，APPROX_PERCENTILE）作为截尾阈值。
- 按 `GROUPING SETS`（edt_type × 品类层级）聚合主指标：`imp_cnt`、`click_cnt`、`order_cnt`、`gmv`、`gmv_995`、`gmv_uu_995`、`pc2_gmv_995`、`pc2_gmv_uu_995`、`avg_edt`，输出 `dws_main_metrics`。

**Step 5 — GMV v2 截尾（分品类高/低 GMV 分档）**
- 从商品维表关联商品的高/低 GMV 品类标签（`category_tag`），得到商品级 GMV 数据（`gmv995_v2_item_order_level`）。
- 从品类 GMV 离群阈值维表获取各品类的 995 分位阈值（`gmv_995pct` / `pc2_gmv_995pct`），按品类标签 JOIN 后进行截尾（超阈值的 GMV 用阈值替换）。
- 按实验组 JOIN 用户分流映射，按高/低 GMV 品类分别聚合 `gmv_995_v2`、`gmv_order_cnt_995_v2`、`pc2_gmv_995_v2`，输出 `gmv995_v2_exp_metrics`。

**Step 6 — 广告收入聚合**
- 从广告绩效日志中，按搜索入口（`entrance = 1`）过滤，通过 `request_id + item_id` 关联 EDT 分桶数组，JOIN 用户分流映射，按 `GROUPING SETS` 聚合广告消耗（`ads_revenue`），输出 `dws_ads`。

**Step 7 — 最终写入**
- 以 `dws_main_metrics` 为主表，依次 LEFT JOIN：
  - `dim_exp`：补充实验场景/层级元数据
  - `dws_search_uu_metric`：关联 `search_uu`（仅在 `edt_type = '__ALL__'` 行匹配）
  - `dws_ads`：关联广告收入
  - `gmv995_v2_exp_metrics`：关联 v2 截尾 GMV 指标
- 按 `grass_region` 和 `local_date` 分区 INSERT OVERWRITE 写入目标表。

### 注意事项

- **单 Writer，无 multi-writer 风险**：本表仅有一个 ETL 文件写入，无并发写入冲突。
- **分区全量覆盖**：使用 `INSERT OVERWRITE ... PARTITION(grass_region, local_date)` 写入，每次执行覆盖对应分区，重跑安全。
- **`search_uu` 仅在汇总 EDT 行有值**：`search_uu` 仅在 `edt_type = '__ALL__'` 行通过 JOIN 条件匹配赋值，其余 EDT 分桶行为 NULL，为设计行为，非数据质量问题。
- **多粒度行共存**：同一分区内存在不同 GROUPING SETS 粒度的数据行，品类汇总行以 `__ALL__` 标识，查询时务必注意行级别区分，避免重复聚合。
- **`avg_edt` 依赖订单 EDT 快照**：`sls_mart.dwd_edt_order_info_df` 使用最新快照（`MAX(grass_date)`）过滤当日订单，若快照延迟会影响 `avg_edt` 数据完整性。
- **广告数据 JOIN 可能存在 NULL**：`dwd_fp_search_base_1d` 中无广告曝光的行在 JOIN 广告表时会产生 NULL，`ads_revenue` 字段可能为空，使用时建议 COALESCE 处理。
- **ABS 995 分位为近似值**：使用 `APPROX_PERCENTILE` 函数计算，存在一定误差，非精确分位数。

---

*文档生成时间：2026-05-17*
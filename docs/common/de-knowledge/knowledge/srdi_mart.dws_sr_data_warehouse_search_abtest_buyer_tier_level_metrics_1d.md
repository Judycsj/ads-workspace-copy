<!-- ads-workspace-gdoc-sync: gdoc_id=1G1HXpoz4i6aCz6zPkdMw0-IuOG69MEN9AsX3WEF1zfM gdoc_url=https://docs.google.com/document/d/1G1HXpoz4i6aCz6zPkdMw0-IuOG69MEN9AsX3WEF1zfM/edit -->

# srdi_mart.dws_sr_data_warehouse_search_abtest_buyer_tier_level_metrics_1d

**分层：** dws_search  
**主键：** exp_group_id + experiment_id + abs_tier_180d + platform_gmv_180d_pct_category + search_gmv_180d_pct_category + platform_duration_180d_pct_category + search_duration_180d_pct_category + page_tag + source1_page_tag + source2_page_tag + level1_keyword_category_max_imp + grass_region + local_date + exp_domain  
**分区：** grass_region / local_date / exp_domain  
**更新频率：** 每日（T+1）  
**引用频次/访问频次：** 888  

---

## 业务描述

本表是搜索域 A/B 实验买家层级指标宽表，面向搜索 A/B 实验效果评估场景，以**实验分组 × 买家层级标签 × 页面标签 × 关键词一级类目**为粒度，汇聚搜索核心业务指标（曝光、点击、下单、GMV、时长、广告）。

**核心业务场景：**
- 搜索 A/B 实验效果分析：对比实验组与对照组在不同买家层级（绝对消费层级、GMV 百分位分层、时长百分位分层）下的实验指标表现；
- 买家分层下钻：按 `abs_tier_180d`、`platform_gmv_180d_pct_category`、`search_gmv_180d_pct_category`、`platform_duration_180d_pct_category`、`search_duration_180d_pct_category` 拆解实验效果；
- 关键词类目维度分析：按一级关键词类目（`level1_keyword_category_max_imp`）查看搜索实验指标；
- 页面来源维度分析：按 `page_tag`、`source1_page_tag`、`source2_page_tag` 拆解页面停留时长与 DAU 指标；
- 广告负向影响评估：通过 `ads_load`、`ads_rev`、`ads_narrow_roi`、`ads_broad_roi` 衡量广告对搜索体验的影响。

**适合回答的问题：**
- 实验组 X 相比对照组在高价值买家中 GMV 是否提升？
- 不同消费层级买家在实验期间的点击率、下单率变化如何？
- 搜索实验对广告收入（ROI）是否有负向影响？
- 实验对用户搜索停留时长和 DAU 有何影响？
- 各关键词一级类目下实验效果差异如何？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 国家/地区，如 `ID`、`MY`、`TH` 等，Shopee 标准大区标识 |
| `local_date` | date | 数据日期（本地时间），格式 `yyyy-MM-dd` |
| `exp_domain` | string | 实验域，当前固定写入值为 `'Search'` |

### 维度：实验信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `experiment_id` | bigint | 实验 ID，标识具体 A/B 实验 |
| `exp_group_id` | bigint | 实验分组 ID，标识实验组或对照组 |

### 维度：买家层级标签

| 字段 | 类型 | 说明 |
|---|---|---|
| `abs_tier_180d` | string | 买家近 180 天绝对消费层级；`'__ALL__'` 表示全体汇总，`'0'` 表示无标签 |
| `platform_gmv_180d_pct_category` | string | 买家近 180 天平台 GMV 百分位分层；`'__ALL__'` 表示全体汇总，`'NULL'` 表示无标签 |
| `search_gmv_180d_pct_category` | string | 买家近 180 天搜索 GMV 百分位分层；`'__ALL__'` 表示全体汇总，`'NULL'` 表示无标签 |
| `platform_duration_180d_pct_category` | string | 买家近 180 天平台使用时长百分位分层；`'__ALL__'` 表示全体汇总，`'NULL'` 表示无标签 |
| `search_duration_180d_pct_category` | string | 买家近 180 天搜索使用时长百分位分层；`'__ALL__'` 表示全体汇总，`'NULL'` 表示无标签 |

### 维度：关键词类目

| 字段 | 类型 | 说明 |
|---|---|---|
| `level1_keyword_category_max_imp` | string | 关键词对应的一级类目名称（按曝光量取最多的类目）；`'__ALL__'` 表示全体汇总，`'NULL'` 表示无法映射到类目 |
| `level1_keyword_category_id_max_imp` | string | 关键词对应的一级类目 ID，与 `level1_keyword_category_max_imp` 对应；来自关键词宽表 `dim_sr_data_warehouse_keyword_wide` |

### 维度：页面来源

| 字段 | 类型 | 说明 |
|---|---|---|
| `page_tag` | string | 页面标签，标识用户所在页面类型；`'__ALL__'` 表示全体汇总，`'NULL'` 表示未标记 |
| `source1_page_tag` | string | 一级来源页面标签；`'__ALL__'` 表示全体汇总，`'NULL'` 表示未标记 |
| `source2_page_tag` | string | 二级来源页面标签；`'__ALL__'` 表示全体汇总，`'NULL'` 表示未标记 |

### 指标：用户规模

| 字段 | 类型 | 说明 |
|---|---|---|
| `exp_group_uu` | bigint | 实验分组内买家 UV，仅在 `abs_tier_180d` 维度可用（来自 `exp_uu` 中间表），其他层级维度下为 NULL |
| `search_uu` | bigint | 实验分组内有搜索结果浏览行为的买家 UV（`view_cnt > 0` 的用户数） |
| `page_dau` | bigint | 实验分组内页面 DAU（有页面停留时长记录的用户数） |

### 指标：搜索行为

| 字段 | 类型 | 说明 |
|---|---|---|
| `imp_cnt` | bigint | 搜索结果页商品曝光总次数 |
| `imp_uu` | bigint | 有曝光行为的买家 UV |
| `click_cnt` | bigint | 搜索结果页商品点击总次数 |
| `click_uu` | bigint | 有点击行为的买家 UV |
| `duration` | double | 搜索页面累计停留时长（秒），仅在含 `page_tag` 维度的行中有值 |

### 指标：下单与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `order_cnt` | double | 搜索带来的下单笔数 |
| `order_uu` | double | 有下单行为的买家 UV |
| `gmv` | double | 搜索带来的 GMV（USD） |
| `gmv_995` | double | 99.5% 分位截断后的 GMV（用户层面 ABS ≤ 99.5% 分位值的用户 GMV 之和），用于去除极端高消费用户影响 |
| `gmv_uu_995` | double | `gmv_995` 对应的每 UV 平均 GMV（= `gmv_995` / 满足截断条件的 `imp_uu`），**为比率指标，不可直接 SUM** |
| `pc2_gmv_995` | double | 99.5% 分位截断后的 PC2 GMV（付款确认后 GMV），与 `gmv_995` 逻辑相同 |
| `pc2_gmv_uu_995` | double | `pc2_gmv_995` 对应的每 UV 平均 PC2 GMV，**为比率指标，不可直接 SUM** |

### 指标：GMV 995 V2（高低价值商品分层截断）

| 字段 | 类型 | 说明 |
|---|---|---|
| `high_gmv_995_v2` | double | 高 GMV 类目（`category_tag = 'high gmv'`）商品经品类级别分位截断后的 GMV |
| `high_gmv_order_cnt_995_v2` | double | 高 GMV 类目商品经截断后的有效订单笔数（截断条件：单订单 GMV ≤ 品类 99.5% 分位值） |
| `high_pc2_gmv_995_v2` | double | 高 GMV 类目商品经截断后的 PC2 GMV |
| `low_gmv_995_v2` | double | 低 GMV 类目（`category_tag = 'low gmv'`）商品经品类级别分位截断后的 GMV |
| `low_gmv_order_cnt_995_v2` | double | 低 GMV 类目商品经截断后的有效订单笔数 |
| `low_pc2_gmv_995_v2` | double | 低 GMV 类目商品经截断后的 PC2 GMV |

### 指标：广告

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_rev` | double | 广告收入（USD），来自广告平台曝光消耗 |
| `ads_load` | double | 广告负载率（= 广告曝光数 / 全部搜索曝光数），**为比率指标，不可直接 SUM** |
| `ads_narrow_roi` | double | 广告窄口径 ROI（= 广告直接成交 GMV USD / 广告收入），**为比率指标，不可直接 SUM** |
| `ads_broad_roi` | double | 广告宽口径 ROI（= 广告带来的宽口径 GMV USD / 广告收入），**为比率指标，不可直接 SUM** |

### 指标：物流体验

| 字段 | 类型 | 说明 |
|---|---|---|
| `avg_edt` | double | 搜索带来订单的平均 EDT（预计送达时间，单位：天），= SUM(edtmax_in_days) / SUM(有效订单数)，**为均值指标，不可直接 SUM** |

---

## 查询使用须知

### 必须包含的过滤条件

- **`local_date`**：必须指定，否则全量扫描所有分区，严重影响性能。建议使用等值过滤，如 `local_date = '2024-01-01'`。
- **`grass_region`**：必须指定具体地区，如 `grass_region = 'ID'`。
- **`exp_domain`**：当前该表固定写入 `'Search'`，查询时建议加上 `exp_domain = 'Search'`。

### 不可直接 SUM 的字段

以下字段为**预聚合比率或均值**，跨行/跨分组直接 SUM 无业务意义，需用分子/分母字段重新推导：

| 字段 | 原因 | 正确计算方式 |
|---|---|---|
| `gmv_uu_995` | 比率 | `SUM(gmv_995) / SUM(满足截断条件的 imp_uu)`（需从明细层重算） |
| `pc2_gmv_uu_995` | 比率 | 同上，pc2 口径 |
| `ads_load` | 比率 | `SUM(ads_load_numerator) / SUM(ads_load_denominator)`（需从明细层重算） |
| `ads_narrow_roi` | 比率 | `SUM(ads_narrow_roi_numerator) / SUM(ads_rev)` |
| `ads_broad_roi` | 比率 | `SUM(ads_broad_roi_numerator) / SUM(ads_rev)` |
| `avg_edt` | 均值 | `SUM(edt_numerator) / SUM(edt_denominator)` |

### 维度组合与汇总说明

- 本表采用 **GROUPING SETS** 预聚合，每行对应一种维度组合，`'__ALL__'` 表示该维度已汇总，查询时需注意过滤避免重复计算。
- `level1_keyword_category_id_max_imp` 与 `level1_keyword_category_max_imp` 仅在关键词类目维度行中有值，其他汇总行为 NULL。
- `duration`、`page_dau` 仅在含 `page_tag` 维度（非 `'__ALL__'`）的行中有实际值；其他维度组合行中来自 `dws_page_duration_metrics` 的 FULL JOIN 填充。
- `exp_group_uu` 仅在 `abs_tier_180d` 维度有效。

### 时效性说明

- 本表为 `_1d` 日粒度表，每日 T+1 产出，数据对应 `local_date` 当天的搜索行为。
- 用户标签（`user_label`）使用的是 `local_date - 1` 的快照，即昨日标签，存在 1 天滞后。
- 广告汇率使用 `local_date` 当日汇率，每日刷新。
- EDT 数据来源为 `sls_mart.dwd_edt_order_info_df_${grass_region_without_quote}` 最新快照，取 `order_create_date = local_date` 的订单。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dim_sr_data_warehouse_abtest_user_group` | 获取 A/B 实验用户分组映射（user_id → exp_group_id、experiment_id） |
| `srdi_mart.dim_sr_data_warehouse_user_label` | 获取买家层级标签（abs_tier_180d、GMV/时长百分位分层），使用 `local_date - 1` 快照 |
| `srdi_mart.dwd_sr_data_warehouse_view_page_duration_di` | 搜索场景页面停留时长明细，用于计算 duration 和 page_dau |
| `srdi_mart.dws_sr_data_warehouse_search_srp_user_benchmark_1d` | 搜索结果页用户级曝光、点击、下单、GMV 基准表，用于计算搜索核心指标及广告负载分母 |
| `srdi_mart.dim_sr_data_warehouse_keyword_wide` | 关键词宽表，用于将关键词映射到一级类目 |
| `srdi_mart.dwd_fp_search_base_1d` | 搜索带来的订单基础事实表，用于计算 EDT 指标 |
| `sls_mart.dwd_edt_order_info_df_${grass_region_without_quote}` | EDT 订单信息维表，提供 `edtmax_in_days`（最大预计送达天数） |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告投放明细，用于计算广告收入、广告曝光、ROI 等指标 |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，用于本地货币广告 ROI 转换为 USD |
| `srdi_mart.dim_sr_data_warehouse_category_gmv_outlier` | 品类 GMV 异常值基准（99.5% 分位），用于 GMV 995 V2 截断 |
| `srdi_mart.dim_sr_data_warehouse_item` | 商品维表，用于获取商品 `category_tag`（high gmv / low gmv 分类） |
| `srdi_mart.dws_sr_data_warehouse_platform_order_benchmark_1d` | 平台层订单基准表，用于计算 GMV 995 V2 指标 |

---

## ETL 逻辑摘要

### 数据流

```
dim_abtest_user_group ──────────────────────────────────────────────────┐
dim_user_label ─────────────────────────────────────────────────────────┤
                                                                         ↓
dwd_view_page_duration_di ──→ user_page_duration → dws_page_duration_metrics ──┐
                                                                                 │
dws_srp_user_benchmark_1d ──→ srp_user_keyword_cat_level_grouped                │
dim_keyword_wide ──────────┘    → srp_user_grouped → (abs995 benchmark)         │
                                 → dws_search_metrics ──────────────────────────┤
dwd_fp_search_base_1d ──→ edt_metric_user_level → dws_edt_metrics ─────────────┤
                                                                                 │
dwd_advertise_performance → ads_user_level → ads_user_full_join                  │
dwd_ads_load_denominator ──────────────────┘  → dws_ads ────────────────────────┤
dim_exchange_rate ─────────────────────────────────────────────────────────────  │
                                                                                 │
dws_platform_order_benchmark_1d ──→ gmv995_v2_item_order_grouped                │
dim_category_gmv_outlier ──────────→ gmv995_v2_user_level_filtered              │
dim_item ──────────────────────────┘  → gmv995_v2_metrics ──────────────────────┤
                                                                                 ↓
                                        all_metrics_except_page_duration ──→ INSERT OVERWRITE
                                        dws_page_duration_metrics ─────────────┘
```

### 关键步骤

| 步骤 | Temporary View / 操作 | 说明 |
|---|---|---|
| 1 | `user_exp_mapping` | 从实验分组维表过滤出有效实验用户（白名单、search 白名单、user_id > 0） |
| 2 | `user_label` | 从用户标签维表读取 T-1 日买家层级标签 |
| 3 | `exp_uu` | 以 UNION ALL 方式分别计算全体和各 `abs_tier_180d` 层级的实验分组 UV |
| 4 | `user_page_duration` | 聚合搜索场景用户级页面停留时长 |
| 5 | `user_label_and_page_duration` | LEFT JOIN 用户标签到页面时长数据 |
| 6 | `dws_page_duration_metrics` | 以 GROUPING SETS 多维聚合页面时长和 DAU |
| 7 | `keyword_wide` / `keyword_wide_cats` | 加载关键词→类目映射，`keyword_wide_cats` 仅保留类目去重用于最终 JOIN |
| 8 | `srp_user_keyword_cat_level_grouped` | 从 SRP 用户基准表聚合关键词类目 × 买家层级的行为指标 |
| 9 | `srp_user_grouped` | 去掉类目维度再聚合，并计算每用户平均订单金额（ABS） |
| 10 | `global_search_abs995_benchmark` | CACHE TABLE，用 `APPROX_PERCENTILE` 计算全局 99.5% ABS 分位值 |
| 11 | `dws_search_metrics` | 以 GROUPING SETS + UNION ALL 多维聚合搜索核心指标及 995 截断 GMV |
| 12 | `dwd_edt_order_info` | 关联最新 EDT 订单快照，过滤当日创建订单 |
| 13 | `edt_metric_user_level` | 用户级 EDT 分子（总 EDT 天数）与分母（有效订单数）聚合 |
| 14 | `dws_edt_metrics` | 以 GROUPING SETS 聚合 avg_edt（SUM(分子)/SUM(分母)） |
| 15 | `dwd_ads_load_denominator` | 从 SRP 基准表取全量搜索曝光作为广告负载分母（含更多 page_type） |
| 16 | `exchange_rate` | 取当日汇率最大值，用于本地货币 → USD 转换 |
| 17 | `ads_user_level` | 从广告投放明细聚合用户关键词级别广告指标 |
| 18 | `ads_user_keyword_cat_join` | UNION ALL 方式：关键词非空行 LEFT JOIN 类目，关键词为空行直接归入 NULL 类目 |
| 19 | `ads_user_keyword_cat_grouped` / `ads_user_grouped` | 逐步聚合去掉类目维度，用于广告指标计算 |
| 20 | `ads_user_full_join` | FULL JOIN 广告分子与广告负载分母，并 JOIN 汇率完成本地 → USD 换算 |
| 21 | `dws_ads` | GROUPING SETS + UNION ALL 多维聚合广告指标（ads_rev、ads_load、ROI） |
| 22 | `gmv995_v2_item_order_grouped` | 从平台订单基准表聚合 item/order 粒度数据，关联品类标签和关键词类目 |
| 23 | `gmv995_v2_item_order_dim_grouped` | GROUPING SETS 多维展开 item/order 粒度 |
| 24 | `gmv995_v2_user_level_filtered` | JOIN 品类 GMV 分位阈值，按品类截断 GMV 和 PC2 GMV |
| 25 | `gmv995_v2_metrics` | 关联实验分组，区分 high gmv / low gmv 类目聚合 995 V2 指标 |
| 26 | `all_metrics_except_page_duration` | LEFT JOIN 合并 search_metrics、edt_metrics、ads、gmv995_v2 四路指标 |
| 27 | `INSERT OVERWRITE` | FULL JOIN 合并 all_metrics 与 page_duration_metrics，LEFT JOIN exp_uu 和 keyword_wide_cats，写入目标表 |

### 注意事项

- **单文件写入（non multi-writer）**：本表仅一个 ETL 文件，`INSERT OVERWRITE PARTITION(grass_region, local_date, exp_domain)` 按地区和日期分区覆盖写入，无多 writer 并发冲突风险。
- **`exp_domain` 动态分区**：ETL 中 `exp_domain` 的值在 SELECT 中硬编码为 `'Search'`，属于动态分区列，实际写入的分区值固定为 `Search`。
- **GROUPING SETS 多行展开**：同一实验分组的指标会在不同维度组合下产生多行，直接 SUM 聚合会重复计算，查询时须指定维度过滤条件（如 `abs_tier_180d = '__ALL__'` 且其他层级维度均为 `'__ALL__'`）。
- **`avg_edt` 的 GROUPING SET 引用了未声明的 `experiment_id`**：ETL SQL 中 `dws_edt_metrics` 的部分 GROUPING SETS 使用了 `experiment_id`，但 GROUP BY 主键中缺少该字段的完整声明，实际产出需关注是否有 NULL 行。
- **`global_search_abs995_benchmark` 使用 CACHE TABLE**：该全局分位值在 Spark 执行时以 BROADCAST JOIN 方式使用，需确保 Spark 内存充足。
- **广告 ROI 分子使用本地货币转换**：`ads_broad_roi_numerator` = 本地货币 GMV / 汇率，汇率取 `MAX(exchange_rate)`，需关注汇率数据是否及时更新。
- **用户标签使用 T-1 快照**：`user_label` 来自 `local_date - 1`，即当日实验用户的买家层级标签存在 1 天滞后，跨天分析时需注意。

---

*文档生成时间：2026-05-17*
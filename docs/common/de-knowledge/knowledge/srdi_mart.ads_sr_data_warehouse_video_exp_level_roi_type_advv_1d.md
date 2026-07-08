<!-- ads-workspace-gdoc-sync: gdoc_id=1CiMoVEjMLaPuyqV4YFE1j4l3X6s_gy4WmRejy4I3JoY gdoc_url=https://docs.google.com/document/d/1CiMoVEjMLaPuyqV4YFE1j4l3X6s_gy4WmRejy4I3JoY/edit -->

# srdi_mart.ads_sr_data_warehouse_video_exp_level_roi_type_advv_1d

**分层**：ADS（应用数据层）
**主键**：`grass_region`, `local_date`, `rcmd_ab_bundle`, `roi_type`, `exp_group_id`
**分区**：`grass_region`（大区）, `local_date`（日期）
**更新频率**：每日（T+1）全量覆写（INSERT OVERWRITE）
**引用频次 / 访问频次**：0

---

## 业务描述

本表面向**视频广告搜推数仓**，在**实验（A/B Test）粒度**下，按**推荐场景（rcmd_ab_bundle）** 与 **ROI 类型（roi_type）** 聚合一天内的广告投放核心指标，涵盖收入、GMV、成本、出价与扣费等多维度数据。

**核心业务场景：**
- 视频广告 A/B 实验效果评估：对比不同实验组（`exp_group_id`）在各推荐场景和 ROI 策略下的广告表现；
- ROI 类型拆解分析：区分 ROI 1.0、ROI 2.0、Simple Ads 2.0、Ads ROI 汇总等口径，支持多维下钻；
- 扣费与出价健康度监控：通过扣费/出价比（`deduction_bid_ratio`）判断竞价机制运行状态；
- 广告视频流量价值评估：结合直接/宽口径 GMV 和 Cost 计算 ROI 比率，辅助广告策略调优。

**适合回答的典型问题：**
- 实验组 A vs 控制组在视频推荐场景下的广告 Revenue、GMV 差异是多少？
- 不同 ROI 策略类型（ROI 1.0 / ROI 2.0 / Simple Ads 2.0）的直接成本比率（direct_cost_ratio）表现如何？
- 某大区某日的平均扣费价格与出价价格之比是否在健康区间？
- 各推荐 bundle（如 video_rcmd_core、dd_video 等）的宽口径 GMV 及 Cost 分布？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 大区标识（如 US、SG 等），ETL 按大区分区写入 |
| `local_date` | date | 数据所属本地日期，对应 T 日 |

### 维度：实验与推荐场景

| 字段 | 类型 | 说明 |
|---|---|---|
| `rcmd_ab_bundle` | string | 推荐场景 bundle，由 feature_group_chained 按 `#` 拆分展开，例如 `video_rcmd_core`、`dd_video`、`video_all` 等 |
| `roi_type` | string | ROI 策略类型聚合标签：`ROI 1.0`（manual/itemboost/autoboost/simple_roas 等）、`ROI 2.0`（roi2.0）、`Simple Ads 2.0`（roi2.0_simple）、`Ads ROI`（所有类型汇总行）、`others` |
| `exp_group_id` | bigint | A/B 实验分组 ID，来源于 abtest_user_group 表，场景覆盖 video_union、paidads_universal、global_priority |

### 指标：收入与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `revenue_usd` | double | 广告收入（USD），各 request 维度汇总求和 |
| `ads_gmv_usd` | double | 广告带来的 GMV（USD），直接归因口径 |
| `broad_gmv_usd` | double | 宽口径 GMV（USD），含间接归因 |
| `direct_advv_gmv` | double | 直接 ADVV GMV（USD），用于 ROI 比率分母计算 |
| `broad_advv_gmv` | double | 宽口径 ADVV GMV（USD），用于宽口径 ROI 比率分母计算 |

### 指标：广告成本

| 字段 | 类型 | 说明 |
|---|---|---|
| `direct_advv_cost` | double | 直接 ADVV 广告成本（USD） |
| `broad_advv_cost` | double | 宽口径 ADVV 广告成本（USD） |

### 指标：ROI 比率

| 字段 | 类型 | 说明 |
|---|---|---|
| `direct_cost_ratio` | double | 直接成本比率，计算方式：`SUM(revenue_usd) / SUM(direct_advv_cost)`；**不可直接 SUM** |
| `broad_cost_ratio` | double | 宽口径成本比率，计算方式：`SUM(revenue_usd) / SUM(broad_advv_cost)`；**不可直接 SUM** |
| `direct_gmv_ratio` | double | 直接 GMV 比率，分子为 `ads_gmv_usd`，分母依 product_type 区分（CPC 类用 ads_gmv_usd，OCPC/ROI 类用 direct_advv_gmv）；**不可直接 SUM** |
| `broad_gmv_ratio` | double | 宽口径 GMV 比率，分子为 `broad_gmv_usd`，分母依 product_type 区分；**不可直接 SUM** |
| `target_cir` | double | 目标 CIR（Cost-Income Ratio），由上游按 request 维度 MAX 后再 AVG 聚合；**不可直接 SUM** |

### 指标：出价与扣费

| 字段 | 类型 | 说明 |
|---|---|---|
| `sum_bid_price_usd` | double | 出价价格累计值（USD），可 SUM 后用于重新计算均值 |
| `sum_deduction_price_usd` | double | 扣费价格累计值（USD），可 SUM 后用于重新计算均值 |
| `cnt_bid_price` | double | 出价价格计数，与 `sum_bid_price_usd` 配套使用 |
| `cnt_deduction_price` | double | 扣费价格计数，与 `sum_deduction_price_usd` 配套使用 |
| `avg_bid_price_usd` | double | 平均出价价格（USD），计算方式：`SUM(sum_bid_price_usd) / SUM(cnt_bid_price)`；**不可直接 SUM** |
| `avg_deduction_price_usd` | double | 平均扣费价格（USD），计算方式：`SUM(sum_deduction_price_usd) / SUM(cnt_deduction_price)`；**不可直接 SUM** |
| `deduction_bid_ratio` | double | 扣费/出价比率，计算方式：`avg_deduction_price_usd / avg_bid_price_usd`；**不可直接 SUM** |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`**：本表按大区分区，查询时必须指定，否则将触发全分区扫描，严重影响性能；
- **`local_date`**：本表为日粒度数据，查询时必须指定日期范围，避免跨分区全表扫描；

```sql
-- 示例
WHERE grass_region = 'SG'
  AND local_date = '2025-03-01'
```

### 不可直接 SUM 的字段

以下字段为预聚合派生的比率或均值，跨行相加无业务意义，**严禁直接 SUM**，需使用其分子分母字段重新计算：

| 字段 | 正确聚合方式 |
|---|---|
| `direct_cost_ratio` | `SUM(revenue_usd) / SUM(direct_advv_cost)` |
| `broad_cost_ratio` | `SUM(revenue_usd) / SUM(broad_advv_cost)` |
| `direct_gmv_ratio` | 需结合 product_type 分母逻辑，参考 ETL |
| `broad_gmv_ratio` | 需结合 product_type 分母逻辑，参考 ETL |
| `avg_bid_price_usd` | `SUM(sum_bid_price_usd) / SUM(cnt_bid_price)` |
| `avg_deduction_price_usd` | `SUM(sum_deduction_price_usd) / SUM(cnt_deduction_price)` |
| `deduction_bid_ratio` | 先计算 `avg_deduction_price_usd` 与 `avg_bid_price_usd` 再相除 |
| `target_cir` | 聚合含 AVG，无法简单反推，建议作为参考值或从上游重新聚合 |

### ROI 类型去重注意

- `roi_type = 'Ads ROI'` 是对所有 product_type 的**汇总行**，与其他 `roi_type` 值存在**行级重叠**，统计总量时需注意过滤，避免重复计数：

```sql
-- 汇总全量时只取 Ads ROI 行
WHERE roi_type = 'Ads ROI'

-- 按策略拆分时排除汇总行
WHERE roi_type != 'Ads ROI'
```

### 时效性说明

- 本表为 **T+1 日刷新**，当天数据通常于次日凌晨完成写入；
- ETL 采用 `INSERT OVERWRITE PARTITION`，每次执行会覆盖对应 `(grass_region, local_date)` 分区，历史分区数据稳定，可放心回溯。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_ads_request_benchmark_advv_1d` | 提供 request 粒度的广告 ADVV 基准指标，包含 revenue、GMV、cost、出价/扣费等核心数值；通过 LATERAL VIEW EXPLODE 展开 `feature_groups` 和 `product_types` 数组 |
| `video.video_mart_dim_abtest_user_group_v2_di` | 提供用户与 A/B 实验分组的映射关系，覆盖 `video_union`、`paidads_universal`、`global_priority` 三大场景 |

---

## ETL 逻辑摘要

### 数据流

```
video.video_mart_dim_abtest_user_group_v2_di
        │
        │ (用户-实验组映射)
        ▼
srdi_mart.dws_sr_data_warehouse_ads_request_benchmark_advv_1d
        │
        │ EXPLODE(feature_groups, product_types)
        ▼
 request_advv_benchmark_preprocess  →  过滤 feature_group / product_type
        │
        ▼
 request_advv_benchmark_explode  →  EXPLODE(feature_group_chained, '#') 展开 rcmd_ab_bundle
        │
        ▼
 advv_request_flatten_join_exp  →  JOIN 实验组，分 rcmd_ab_bundle / product_type / exp_group_id 聚合
        │
        ▼
 ads_metrics  →  映射 roi_type，计算比率指标，UNION ALL 追加 'Ads ROI' 汇总行
        │
        ▼
ads_sr_data_warehouse_video_exp_level_roi_type_advv_1d（目标表）
```

### 关键步骤

| 步骤 | Temporary View | 说明 |
|---|---|---|
| Step 1 | `user_exp_mapping` | 从 abtest_user_group 按 `grass_region`、`grass_date`、三大 scene_key 过滤，GROUP BY `user_id`、`exp_group_id`，构建用户-实验组映射 |
| Step 2 | `request_advv_benchmark_preprocess` | 从 DWS 表读取数据，LATERAL VIEW EXPLODE 展开 `feature_groups` 和 `product_types` 两个数组，按 `feature_group`、`user_id`、`request_id`、`product_type`、`ads_id`、`item_id`、`campaign_id` 聚合，SUM 金额类字段，MAX 出价/扣费类字段 |
| Step 3 | `request_advv_benchmark_explode` | 过滤保留 5 条指定 feature_group 链，排除 `simple_mode_boost`、`roi2.0_simple (organic)`、`roi2.0_simple (ads)`、`__ALL__` 等 product_type |
| Step 4 | `advv_request_flatten_join_exp` | EXPLODE feature_group_chained（按 `#` 分割）展开为 `rcmd_ab_bundle`，JOIN 用户实验组映射，按 `rcmd_ab_bundle`、`product_type`、`exp_group_id` 聚合；计算 `denominator_direct_gmv_ratio` 与 `denominator_broad_gmv_ratio`（CPC 类用 GMV，OCPC/ROI 类用 advv_gmv，Search 渠道置为极小值） |
| Step 5 | `ads_metrics` | 将 `product_type` 映射为 `roi_type`（ROI 1.0 / ROI 2.0 / Simple Ads 2.0 / others），计算所有比率指标；UNION ALL 追加 `roi_type = 'Ads ROI'` 的全策略汇总行 |
| Step 6 | INSERT OVERWRITE | 覆盖写入目标表对应 `(grass_region, local_date)` 分区 |

### 注意事项

- **单 Writer**：本表仅有 1 个 ETL 文件，无多 Writer 并发风险；
- **分区写入安全**：采用 `INSERT OVERWRITE PARTITION(grass_region, local_date)` 静态分区覆盖，同一天重跑幂等安全；
- **极小值兜底**：`denominator_direct_gmv_ratio` 与 `denominator_broad_gmv_ratio` 在兜底场景使用 `0.0000000001` 替代 0，以防除零，但对应的 `direct_gmv_ratio`/`broad_gmv_ratio` 数值在这些场景下会异常偏大，使用时需结合 product_type 判断是否有实际意义；
- **`Ads ROI` 行重叠**：UNION ALL 产生的 `roi_type = 'Ads ROI'` 汇总行与明细行存在重叠，请勿在同一查询中对所有 `roi_type` 无差别聚合；
- **feature_group 白名单**：Step 3 仅保留 5 条指定 feature_group 链，覆盖主要视频推荐场景（trending、homepage、dd_video 等），其他场景数据不进入本表；
- **`target_cir` 精度**：上游通过 MAX 聚合后，本表再 AVG 聚合，跨多行加权意义受限，建议仅作参考指标使用。

---

*文档生成时间：2026-05-18*
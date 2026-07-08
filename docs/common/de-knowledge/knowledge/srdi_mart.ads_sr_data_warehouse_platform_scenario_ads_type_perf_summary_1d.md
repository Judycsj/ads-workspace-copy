<!-- ads-workspace-gdoc-sync: gdoc_id=1FNKb0vRn8GKG8RxYuSUJjG1Gqfbqj2_frgL29lfgM3I gdoc_url=https://docs.google.com/document/d/1FNKb0vRn8GKG8RxYuSUJjG1Gqfbqj2_frgL29lfgM3I/edit -->

# srdi_mart.ads_sr_data_warehouse_platform_scenario_ads_type_perf_summary_1d

**分层：** ADS（应用数据层）
**主键：** `grass_region` + `local_date` + `feature_group` + `ads_type` + `voucher_type`
**分区：** `grass_region`（站点区域），`local_date`（业务日期）
**更新频率：** 每日（T+1）全量覆盖写入（INSERT OVERWRITE）
**访问频次：** 11,280 次

---

## 业务描述

本表是搜推广告数仓平台场景（Platform Scenario）维度的广告类型（Ads Type）每日汇总表，面向搜推广告整体效果分析。

表中以 **场景组（feature_group）× 广告类型（ads_type）× 优惠券类型（voucher_type）** 为粒度，提供每日广告曝光、点击、订单、GMV、收入、advv 成本、竞价与扣费价格等核心指标，并同时挂载平台整体基准（plt_total_*）和场景自身基准（feature_total_*），以便在单次查询中完成广告渗透率、advv cost ratio、GMV ratio 等比率类分析。

**核心业务场景：**
- 各广告类型（如 roi1.0、simple_ocpc、autoboost 等）在不同场景（Daily Discover、Search、You May Also Like、Cart Unify、Video、Livestream 等）的每日效果追踪
- 广告 advv cost ratio / GMV ratio 拆解（direct vs broad）
- 均价（竞价均价、扣费均价）及扣费/出价比的日常监控
- 平台级与场景级广告渗透率（ads_imp/order_uu）分析
- 搜推整体（`feature_group='all'`）与细分场景对比

**适合回答的问题举例：**
- 某站点某日各广告类型的收入、GMV、曝光、点击、订单分别是多少？
- roi1.0 与 roi2.0/roi3.0 系列广告的 advv cost ratio 差异如何？
- Search 场景广告曝光 UU 在平台总曝光中的占比？
- 各场景 avg_deduction_price 与 avg_bid_price 的比值（扣费/出价率）趋势？

---

## 字段列表

### 分区字段

| 字段名 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域（如 SG、MY、TH 等），查询必须指定 |
| `local_date` | date | 业务本地日期，查询必须指定 |

### 维度：场景与广告类型

| 字段名 | 类型 | 说明 |
|---|---|---|
| `feature_group` | string | 场景组标识，如 `Daily Discover`、`Search`、`You May Also Like`、`Cart Unify`、`video_trending`、`Livestream`、`s&r`（搜推汇总）、`all`（全平台）等 |
| `ads_type` | string | 广告投放类型，如具体 product_type（`manual_cpc`、`autoboost`、`simple_ocpc`、`roi2.0_target` 等）、`roi1.0`（含 manual_cpc/manual_ecpc/itemboost/autoboost/simple_ocpc/simple_roas 的汇总）、`all`（全类型汇总，排除双计口径） |
| `voucher_type` | string | 优惠券类型；全类型汇总行使用 `__ALL__` |

### 指标：广告收入与 GMV

| 字段名 | 类型 | 说明 |
|---|---|---|
| `revenue_usd` | double | 广告收入（USD），对应 advv direct cost |
| `ads_gmv_usd` | double | 广告直接带动 GMV（USD） |
| `broad_gmv_usd` | double | 广告宽口径 GMV（USD），含归因窗口内间接成交 |
| `gmv_for_ratio` | double | 用于计算比率的宽口径 GMV（与 `broad_gmv_usd` 数值相同，语义上作比率分子） |

### 指标：Advv 成本与 GMV（direct/broad 拆分）

| 字段名 | 类型 | 说明 |
|---|---|---|
| `direct_advv_cost` | double | Direct 口径 advv 成本（USD） |
| `broad_advv_cost` | double | Broad 口径 advv 成本（USD） |
| `direct_advv_gmv` | double | Direct 口径 advv GMV（USD） |
| `broad_advv_gmv` | double | Broad 口径 advv GMV（USD） |
| `direct_cost_ratio` | double | Direct cost ratio，= `revenue_usd / direct_advv_cost`，**预计算比率，不可直接 SUM** |
| `broad_cost_ratio` | double | Broad cost ratio，= `revenue_usd / broad_advv_cost`，**预计算比率，不可直接 SUM** |
| `direct_gmv_ratio` | double | Direct GMV ratio，= `ads_gmv_usd / direct_advv_gmv`，**预计算比率，不可直接 SUM** |
| `broad_gmv_ratio` | double | Broad GMV ratio，= `broad_gmv_usd / broad_advv_gmv`，**预计算比率，不可直接 SUM** |
| `padvv_cost` | double | PADVV 成本（USD），由上游 `padvv` 字段汇总而来 |

### 指标：竞价与扣费价格

| 字段名 | 类型 | 说明 |
|---|---|---|
| `sum_deduction_price_usd` | double | 扣费价格总和（USD），可用于跨行重新计算均价 |
| `sum_bid_price_usd` | double | 出价总和（USD），可用于跨行重新计算均价 |
| `cnt_deduction_price` | bigint | 参与扣费均价计算的计数 |
| `cnt_bid_price` | bigint | 参与出价均价计算的计数 |
| `avg_deduction_price_usd` | double | 平均扣费价格（USD），= `sum_deduction_price_usd / cnt_deduction_price`，**预计算均值，不可直接 SUM** |
| `avg_bid_price_usd` | double | 平均出价（USD），= `sum_bid_price_usd / cnt_bid_price`，**预计算均值，不可直接 SUM** |
| `deduction_bid_ratio` | double | 扣费/出价比，= `avg_deduction_price_usd / avg_bid_price_usd`，**预计算比率，不可直接 SUM** |
| `target_cir` | double | 目标 CIR（Cost-Income Ratio），上游为 AVG 聚合，**不可直接 SUM** |

### 指标：广告曝光、点击与订单

| 字段名 | 类型 | 说明 |
|---|---|---|
| `ads_imp_cnt` | bigint | 广告曝光次数 |
| `ads_imp_uu` | bigint | 有广告曝光的独立用户数（COUNT DISTINCT） |
| `ads_click_cnt` | bigint | 广告点击次数 |
| `ads_click_uu` | bigint | 有广告点击的独立用户数（COUNT DISTINCT） |
| `ads_order_cnt` | double | 广告直接订单数 |
| `ads_order_uu` | bigint | 有广告订单的独立用户数（COUNT DISTINCT） |
| `ads_broad_order_cnt` | double | 广告宽口径订单数（含归因窗口内间接订单） |
| `valid_ads_imp_cnt` | bigint | 有效广告曝光数（仅 `deduction_reason=0` 的曝光行） |
| `ads_total_location` | bigint | 广告坑位总数 |

### 指标：平台级基准

| 字段名 | 类型 | 说明 |
|---|---|---|
| `plt_total_imp_cnt` | bigint | 平台全场景总曝光次数（来自 `scenario_tag='__ALL__'` 行） |
| `plt_total_click_cnt` | bigint | 平台全场景总点击次数 |
| `plt_total_order_cnt` | double | 平台全场景总订单数 |
| `plt_total_gmv` | double | 平台全场景总 GMV（USD） |

### 指标：场景级基准

| 字段名 | 类型 | 说明 |
|---|---|---|
| `feature_total_imp_cnt` | bigint | 当前场景组的总曝光次数；当 `feature_group='all'` 时等于 `plt_total_imp_cnt` |
| `feature_total_click_cnt` | bigint | 当前场景组的总点击次数；当 `feature_group='all'` 时等于 `plt_total_click_cnt` |
| `feature_total_order_cnt` | double | 当前场景组的总订单数；当 `feature_group='all'` 时等于 `plt_total_order_cnt` |
| `feature_total_gmv` | double | 当前场景组的总 GMV（USD）；当 `feature_group='all'` 时等于 `plt_total_gmv` |

---

## 查询使用须知

### 必须包含的过滤条件

- **`grass_region`** 和 **`local_date`** 均为分区字段，查询时**必须同时指定**，否则将触发全分区扫描，导致性能严重下降。
- 若只需某一 ads_type 汇总，建议同时过滤 `voucher_type`，避免 voucher 维度重复计数。
- `feature_group='all'` 行表示全平台汇总，已在 ETL 层做了特定 product_type 去重（排除 simple_mode_boost、roi2.0 系列、roi3.0 系列），与细分行直接加总可能存在口径差异，**不建议与细分行混合 SUM**。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `avg_deduction_price_usd` | 预计算均值，跨行 SUM 无意义；需用 `SUM(sum_deduction_price_usd) / SUM(cnt_deduction_price)` 重算 |
| `avg_bid_price_usd` | 预计算均值，同上；需用 `SUM(sum_bid_price_usd) / SUM(cnt_bid_price)` 重算 |
| `deduction_bid_ratio` | 预计算比率（avg 之比），跨行 SUM 无意义；需用重算后的 avg 相除 |
| `target_cir` | 上游为 AVG 聚合，本表为 AVG(AVG)，不可跨行 SUM |
| `direct_cost_ratio` | 预计算比率，需重算 |
| `broad_cost_ratio` | 预计算比率，需重算 |
| `direct_gmv_ratio` | 预计算比率，需重算 |
| `broad_gmv_ratio` | 预计算比率，需重算 |
| `ads_imp_uu` / `ads_click_uu` / `ads_order_uu` | 去重用户数，跨 `feature_group` 或 `ads_type` 维度直接 SUM 会产生重复计数 |
| `feature_total_*` / `plt_total_*` | 平台/场景基准，每个 `ads_type` 行重复存储同一分母，**绝对不可对此类字段跨行 SUM** |

### 时效性说明

- 本表为 **`_1d` 后缀**的每日汇总表，数据时效为 **T+1**，通常在次日凌晨产出，当日数据不可用。
- 历史分区为 INSERT OVERWRITE 全量覆盖写入，无增量追加风险。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `srdi_mart.dws_sr_data_warehouse_ads_request_benchmark_advv_1d` | 广告请求级 advv 基准数据，提供收入、GMV、成本、竞价/扣费价格、曝光/点击/订单等核心广告指标；通过 EXPLODE 展开 feature_groups、product_types、voucher_types 数组 |
| `srdi_mart.dws_sr_data_warehouse_platform_scenario_level_benchmark_1d` | 平台场景级基准数据，提供各场景及全平台的曝光、点击、订单、GMV 总量（用于构建 feature_total_* 和 plt_total_*） |
| `srdi_mart.ads_rcmd_onepage_ad_metrics_di` | 视频推荐（onepage）广告指标，提供视频类场景的 PV 曝光、点击、订单、GMV（按 `rcmd_ab_bundle` 分组） |
| `mp_content_oa.dwd_ls_order_omni_local_content_final_detail_di` | 直播订单明细，提供 Livestream 场景的订单数和 GMV（直接归因口径） |

---

## ETL 逻辑摘要

### 数据流

```
dws_sr_data_warehouse_ads_request_benchmark_advv_1d
    │── EXPLODE(feature_groups, product_types, voucher_types)
    └──► [Step 1] request_advv_benchmark_preprocess
             │── 视频类 feature_group 特殊处理（EXPLODE '#' 拆分）
             └──► [Step 2] feature_group_flatten
                      └──► [Step 3] ads_type_performance（多 UNION ALL）
                               ├── 细分: feature_group × product_type × voucher_type
                               ├── 汇总 all: feature_group × 'all' × '__ALL__'（排除 roi2.0/3.0 双计）
                               ├── 汇总 roi1.0: feature_group × 'roi1.0' × voucher_type
                               ├── feature_group='all': 'all' × product_type × voucher_type
                               ├── feature_group='all' × 'all'/'roi1.0' 汇总
                               └── feature_group='s&r': Daily Discover+Search+YMAL+Cart Unify 汇总

dws_sr_data_warehouse_platform_scenario_level_benchmark_1d
ads_rcmd_onepage_ad_metrics_di
dwd_ls_order_omni_local_content_final_detail_di
    └──► [Step 4] feature_performance（场景级基准，多 UNION ALL）

dws_sr_data_warehouse_platform_scenario_level_benchmark_1d (scenario_tag='__ALL__')
    └──► [Step 5] platform_total（平台级基准）

[Step 3] ads_type_performance
    LEFT JOIN [Step 4] feature_performance ON feature_group
    LEFT JOIN [Step 5] platform_total
    ──► [Step 6] INSERT OVERWRITE 目标表（派生比率字段在此计算）
```

### 关键步骤

**Step 1 — `request_advv_benchmark_preprocess`（Temporary View）**
- 读取 `dws_sr_data_warehouse_ads_request_benchmark_advv_1d`，过滤当日分区，EXPLODE 三个数组维度（feature_groups、product_types、voucher_types）。
- 排除 `product_type='__ALL__'` 和 `feature_group='__ALL__'`，按 user/request/product_type/voucher_type/ad 维度聚合，计算各指标汇总值。
- 注意价格类字段（`sum_deduction_price_usd`、`sum_bid_price_usd`、`cnt_*`）使用 MAX 而非 SUM，避免 EXPLODE 多维笛卡尔积重复累加。

**Step 2 — `feature_group_flatten`（Temporary View）**
- 对视频类复合 `feature_group`（多个 `#` 拼接的 bundle，如 `video_trending#video_rcmd_core#...`）进行特殊处理：使用 `SPLIT + EXPLODE` 拆分为独立的子 feature_group 行，实现视频场景的多标签归属。
- 非视频类 feature_group 直接保留原始行，通过 UNION ALL 合并。

**Step 3 — `ads_type_performance`（Temporary View）**
- 对 `feature_group_flatten` 进行多轮 UNION ALL 聚合，构建完整的维度组合矩阵：
  1. 细分行：`feature_group × product_type × voucher_type`
  2. `ads_type='all'` 汇总行：排除 simple_mode_boost、roi2.0/3.0 系列，仅取 `voucher_type='__ALL__'`，避免双计
  3. `ads_type='roi1.0'` 汇总行：仅含 manual_cpc、manual_ecpc、itemboost、autoboost、simple_ocpc、simple_roas
  4. `feature_group='all'` 系列：仅聚合枚举的核心场景列表
  5. `feature_group='s&r'` 系列：仅聚合 Daily Discover、Search、YMAL、Cart Unify 四个场景
- 去重 UU 指标（`ads_imp_uu`、`ads_click_uu`、`ads_order_uu`）在此层通过 `COUNT DISTINCT` 计算。

**Step 4 — `feature_performance`（Temporary View）**
- 从三个来源 UNION ALL 构建场景级基准：
  - 常规推荐场景：`dws_sr_data_warehouse_platform_scenario_level_benchmark_1d`，按 scenario_tag 映射到 feature_group 名称
  - 视频推荐场景：`ads_rcmd_onepage_ad_metrics_di`，按 `rcmd_ab_bundle` 分组，使用 AVG（非 SUM）聚合
  - 直播场景：`dwd_ls_order_omni_local_content_final_detail_di`，仅提供订单和 GMV（曝光/点击置 0）
  - 额外补充 `s&r` 汇总行

**Step 5 — `platform_total`（Temporary View）**
- 从 `dws_sr_data_warehouse_platform_scenario_level_benchmark_1d` 取 `scenario_tag='__ALL__'` 行，获取平台全场景汇总指标。

**Step 6 — INSERT OVERWRITE（最终写入）**
- `ads_type_performance` LEFT JOIN `feature_performance`（on feature_group）LEFT JOIN `platform_total`（无 JOIN 条件，即 CROSS JOIN 单行）。
- 在此步骤派生计算比率字段：`direct_cost_ratio`、`broad_cost_ratio`、`direct_gmv_ratio`、`broad_gmv_ratio`、`avg_deduction_price_usd`、`avg_bid_price_usd`、`deduction_bid_ratio`。
- 当 `feature_group='all'` 时，`feature_total_*` 字段用 `plt_total_*` 值替换（IF 逻辑）。
- 按 `PARTITION(grass_region, local_date)` 全量覆盖写入目标表。

### 注意事项

1. **双计风险**：`ads_type='all'` 汇总行已在 ETL 中排除 `simple_mode_boost`、`roi2.0_simple (organic)`、`roi2.0_simple (ads)`、`roi2.0_target`、`roi3.0_simple`、`roi3.0_target`，并限定 `voucher_type='__ALL__'`，以避免 ROI 系列广告的双重计数；分析时需注意与细分行的口径差异。
2. **视频场景多标签展开**：视频类 bundle（如 `video_trending#video_rcmd_core#...`）在 Step 2 被拆分为多个子 feature_group 行，同一笔广告数据会出现在多个 feature_group 下，**不可跨视频子类 feature_group 直接 SUM**。
3. **`feature_total_*` 非广告专属**：该字段来源于平台整体流量基准表（含非广告流量），是场景分母而非广告指标，**不可与 `ads_*` 字段加总或参与广告内部比率计算**。
4. **platform_total CROSS JOIN**：Step 6 中 `platform_total` 无 JOIN KEY，相当于将单行平台总量广播到所有行，`plt_total_*` 字段在所有行中取值相同，**绝对不可对 `plt_total_*` 字段跨行 SUM**。
5. **single-writer**：本表仅有一个 ETL 文件写入，无 multi-writer 风险。

---

*文档生成时间：2026-05-17*
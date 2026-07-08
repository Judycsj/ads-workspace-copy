<!-- ads-workspace-gdoc-sync: gdoc_id=1ss6AsCKBi4VXOQYR3tYAjnYrg7dlnB_A8PXTGPHjYdY gdoc_url=https://docs.google.com/document/d/1ss6AsCKBi4VXOQYR3tYAjnYrg7dlnB_A8PXTGPHjYdY/edit -->

# srdi_mart.dws_sr_data_warehouse_ads_request_benchmark_advv_1d

**分层：** DWS（数据汇总层）
**主键：** `grass_region` + `local_date` + `request_id` + `user_id` + `ads_id` + `item_id` + `campaign_id` + `pricing_type` + `placement` + `entrance` + `feature_groups` + `product_types`（复合逻辑主键，非唯一约束）
**分区：** `grass_region`（站点区域）、`local_date`（本地日期）
**更新频率：** 每日全量覆盖（INSERT OVERWRITE，T+1）
**引用频次/访问频次：** 4514

---

## 业务描述

本表是 Shopee 搜索与推荐广告（Search & Recommendation，SR）数仓中，以**广告请求（request）为粒度**的每日基准效果汇总表，核心聚合维度为用户、广告请求、广告单元、商品、推广计划、定价类型、流量入口及流量分组等。

**核心业务场景：**

- **广告效果基准分析：** 按站点、日期、产品类型、流量入口统计广告展现、点击、订单、GMV、消耗等核心效果指标，支持 ROI 大盘与分层分析。
- **AdvV（广告价值）体系计算：** 提供 `direct_advv_cost`、`broad_advv_cost`、`broad_advv_cost_7d`、`direct_advv_gmv`、`broad_advv_gmv`、`deepadvv` 等多维 AdvV 指标，覆盖直接归因和宽口径归因两种口径。
- **多产品类型对比：** 通过 `product_types`、`main_product_types`、`feature_groups` 字段，支持 ROI1.0/ROI2.0/Simple/Target 等不同广告产品线的横向对比。
- **券类广告分析：** 通过 `voucher_types`、`bid_voucher_id`、`voucher_details_json` 支持发券广告（ROI3.0）专项分析。
- **视频广告专项：** 通过 `decoded_video_id` 区分视频广告素材，结合 `placement` 标识视频明投（placement=54）流量。
- **出价与扣费分析：** `sum_bid_price_usd`、`sum_deduction_price_usd`、`cnt_bid_price`、`cnt_deduction_price` 支持出价分布与扣费差异分析。

**适合回答的问题：**
- 某站点某日各广告产品的消耗、GMV、ROAS 表现如何？
- 某广告位/入口的 AdvV 成本与广告价值分布？
- ROI3.0 券类广告相比普通广告的效果差异？
- 视频广告与普通广告的点击率、订单率对比？
- 按请求粒度的广告位置、平台分布分析？

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|---|---|---|
| `grass_region` | string | 站点区域标识，如 SG、MY、TH 等，分区键之一 |
| `local_date` | date | 本地日期（目标站点时区），分区键之一 |

### 维度：请求与用户标识

| 字段 | 类型 | 说明 |
|---|---|---|
| `request_id` | string | 广告请求 ID，标识一次广告检索请求 |
| `user_id` | bigint | 用户 ID |
| `ads_id` | bigint | 广告单元 ID |
| `item_id` | bigint | 推广商品 ID（非视频广告场景） |
| `decoded_video_id` | bigint | 视频广告素材 ID（视频广告场景，placement=54 或 pricing_type in (16,17,21)） |
| `campaign_id` | bigint | 推广计划 ID |

### 维度：广告产品与定价

| 字段 | 类型 | 说明 |
|---|---|---|
| `pricing_type` | int | 定价类型（广告出价模式），如 CPC=1、CPM、OCPC=4、ROI2.0-Simple=15 等 |
| `attr_data_type` | int | 归因数据类型，用于区分 Simple 模式下的 organic/ads 归因及 Simple Mode Boost |
| `placement` | bigint | 广告位 ID，如 54 为视频明投广告位 |
| `main_product_types` | array\<string\> | 粗粒度产品线分类，取值为 `roi1.0`、`roi2.0`、`others`，由 `pricing_type` 映射生成 |
| `product_types` | array\<string\> | 细粒度产品线分类，综合 `pricing_type`、`attr_data_type`、`placement` 及产品类型映射表生成，用于多维下钻分析 |

### 维度：流量入口与场景

| 字段 | 类型 | 说明 |
|---|---|---|
| `entrance` | int | 流量入口编码，如 1=搜索、3=每日发现、4=YMAL 等 |
| `sub_entrance` | int | 子入口编码，细化入口场景 |
| `feature_groups` | array\<string\> | 流量特征分组标签，由 `entrance`、`sub_entrance`、`placement` 组合映射，支持视频/搜索/推荐等多场景汇总 |
| `location` | bigint | 广告在请求结果中的展示位置（排名） |
| `sort_by` | string | 请求排序方式 |
| `page_type` | string | 页面类型 |
| `page_section` | string | 页面区块 |
| `target_type` | string | 投放目标类型 |
| `platform` | string | 客户端平台，由数字编码转换为字符串：`ios_web`、`ios_app`、`android_web`、`android_app`、`pc_web`、`android_app_lite`、`other`、`null` |

### 维度：券与出价信息

| 字段 | 类型 | 说明 |
|---|---|---|
| `bid_voucher_id` | bigint | 出价关联的券 ID，用于识别发券广告请求 |
| `voucher_types` | array\<string\> | 券类型标签数组，综合 `pricing_type`、`bid_voucher_id`、`display_ads_voucher_label` 生成，取值如 `roi3.0`、`roi3.0_display`、`no_voucher`、`__ALL__` |
| `voucher_details_json` | string | 券明细 JSON，原始券信息透传 |
| `deduction_reason` | int | 扣费原因编码 |
| `plan_bucket_list` | array\<bigint\> | 计划桶列表，用于分桶实验标识 |

### 指标：广告消耗与 GMV

| 字段 | 类型 | 说明 |
|---|---|---|
| `revenue_usd` | double | 广告直接消耗（USD），即 expenditure_amt_usd 汇总 |
| `broad_gmv_usd` | double | 宽口径归因 GMV（USD），由本地币 GMV 除以当日平均汇率换算 |
| `ads_gmv_usd` | double | 广告直接归因 GMV（USD） |

### 指标：AdvV（广告价值）体系

| 字段 | 类型 | 说明 |
|---|---|---|
| `direct_advv_cost` | double | 直接 AdvV 成本（USD）；CPC/CPM 类（pricing_type in 1,2,3,13,16）等于 revenue_usd，其余等于 ads_gmv_usd × target_cir |
| `broad_advv_cost` | double | 宽口径 AdvV 成本（USD）；CPC/CPM 类等于 revenue_usd，其余等于 broad_gmv_usd × target_cir |
| `broad_advv_cost_7d` | double | 基于 7 日滚动宽口径 GMV 计算的 AdvV 成本（USD），使用 campaign 级别 7 日 ROI 加权 |
| `broad_advv_cost_excl_outlier` | double | 排除异常值（target_cir≥50）后的宽口径 AdvV 成本（USD） |
| `direct_advv_gmv` | double | 直接 AdvV 对应 GMV（USD）；CPC/CPM 类等于 ads_gmv_usd，其余等于 revenue_usd / target_cir |
| `broad_advv_gmv` | double | 宽口径 AdvV 对应 GMV（USD）；CPC/CPM 类等于 broad_gmv_usd，其余等于 revenue_usd / target_cir |
| `deepadvv` | double | DeepAdvV 成本（USD），仅 pricing_type=15 计算，基于 campaign 7 日 broad ROI 推算广告价值；其他类型为 null |
| `padvv` | double | pAdvV 指标（USD，除以 100000 缩放），仅 pricing_type not in (16,17,21) 且存在点击时计算；视频广告类型为 null |
| `target_cir` | double | 目标 CIR（Cost-to-Income Ratio），AVG 聚合值，**不可直接 SUM** |

### 指标：流量与互动

| 字段 | 类型 | 说明 |
|---|---|---|
| `ads_imp_cnt` | bigint | 广告展现次数 |
| `ads_click_cnt` | bigint | 广告点击次数；不同 pricing_type 和 placement 使用不同点击口径（product_click/raw_click_cnt/deduplicated_click/click_cnt） |
| `ads_order_cnt` | double | 广告直接归因订单数 |
| `ads_broad_order_cnt` | double | 广告宽口径归因订单数 |
| `ads_total_location` | double | 有展现的广告位置之和（location 累计，用于计算平均位置） |
| `top20_ads_total_location` | double | 位置排名 ≤ 19（Top 20）的广告位置之和 |

### 指标：出价与扣费

| 字段 | 类型 | 说明 |
|---|---|---|
| `sum_deduction_price_usd` | double | 扣费价格之和（USD），由本地扣费价格除以汇率换算 |
| `sum_bid_price_usd` | double | 出价之和（USD），由本地出价除以汇率换算 |
| `cnt_deduction_price` | double | 有效扣费记录数（COUNT 非 NULL），**不可与价格指标直接比较，需注意为 count 语义** |
| `cnt_bid_price` | double | 有效出价记录数（COUNT 非 NULL） |

---

## 查询使用须知

### 必须包含的过滤条件

- **分区字段必须同时指定：** 查询时务必携带 `grass_region` 和 `local_date` 两个分区字段，避免全表扫描。例如：
  ```sql
  WHERE grass_region = 'SG' AND local_date = '2025-01-01'
  ```
- 本表按本地日期（`local_date`，目标站点时区）分区，注意区分与 SG 时区的差异，上游 ETL 已做时区转换。

### 不可直接 SUM 的字段

| 字段 | 原因 |
|---|---|
| `target_cir` | AVG 聚合值，跨行直接 SUM 无业务含义 |
| `padvv` | 含 `/100000` 缩放及条件过滤，跨分组 SUM 会引入错误权重 |
| `deepadvv` | 依赖 campaign 级 7 日 ROI 加权计算，跨 campaign 汇总需重新计算分子分母 |
| `broad_advv_cost_7d` | 依赖 7 日滚动 GMV 与 ROI，非简单累加 |
| `cnt_deduction_price` / `cnt_bid_price` | COUNT 语义，非金额，不可与价格类指标混合 SUM |
| `feature_groups` / `product_types` / `voucher_types` / `main_product_types` | array 类型，含 `__ALL__` 汇总行，直接聚合会重复计数；分析时需 `LATERAL VIEW EXPLODE` 后按需过滤特定标签 |
| `ads_total_location` / `top20_ads_total_location` | 位置之和，计算平均位置需除以 `ads_imp_cnt`，不可单独解读 |
| `plan_bucket_list` | array 类型，需 explode 后使用 |

### array 字段使用注意

`feature_groups`、`product_types`、`main_product_types`、`voucher_types` 均为 `array<string>` 类型，每行包含多个标签（含 `__ALL__` 汇总标签）。直接 GROUP BY 或 COUNT 会产生重复计数。正确用法示例：
```sql
LATERAL VIEW EXPLODE(feature_groups) t AS feature_group
WHERE feature_group = 'Search'
```

### 时效性说明

- 本表为 **T+1 每日全量覆盖表**（`1d` 后缀），数据反映前一自然日（本地时区）的广告效果。
- 上游视频广告数据（`dwd_request_tracking_video_hi`）源自小时分区，ETL 中已按站点时区做时间窗口转换，确保与本地日期对齐。
- 不适合用于实时或当日数据查询。

---

## 数据来源

| 上游表 | 用途 |
|---|---|
| `mkplpaidads_data.dwd_advertise_tracking_item_di__reg_s0_live` | 普通广告（非视频）的 pAdvV、出价、扣费、券展示标签等明细数据 |
| `mp_paidads.dwd_request_tracking_video_hi__reg_s0_live` | 视频广告（placement=54，明投）的出价、扣费等明细数据（小时分区，ETL 内做时区对齐） |
| `mp_order.dim_exchange_rate__reg_s0_live` | 当日平均汇率，用于本地币→USD 转换 |
| `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` | Campaign 级别近 7 日宽口径 GMV 与消耗，用于计算 `campaign_broad_roi_7d` 及 `broad_advv_cost_7d` |
| `srdi_mart.dim_sr_data_warehouse_ads_product_type_mapping` | 广告产品类型映射表，按 `pricing_type` + `placement` 补充 `sub_product_type`，用于 `product_types` 字段生成 |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告效果明细（展现、点击、订单、GMV、消耗等核心指标），本地时区分区 |

---

## ETL 逻辑摘要

### 数据流

```
dwd_advertise_performance_di   ──┐
dim_sr_data_warehouse_ads_...  ──┤→ dws_ads_parsed → dws_ads_performance
                                  │
dwd_advertise_tracking_item_di ──┤→ advertise_tracking_item（普通广告明细）
dwd_request_tracking_video_hi  ──┤→ advertise_tracking_item_video（视频广告明细）
dim_exchange_rate               ──┤→ exchange_rate（汇率）
ads_advertise_mkt_1d            ──┘→ campaign_roi（7日ROI）
                                        │
                              dws_ads_performance_joined
                                        │
                              INSERT OVERWRITE 目标表
```

### 关键步骤

1. **advertise_tracking_item（普通广告明细视图）**
   从广告 tracking 明细表中，按广告请求粒度聚合 pAdvV、出价（bid_price）、扣费（deduction_price）、券展示标签（display_ads_voucher_label），排除视频明投（placement≠54）和原生发券商品（pricing_type≠29），仅取 operation=2（限制点击）的出价/扣费记录。

2. **advertise_tracking_item_video（视频广告明细视图）**
   从视频广告小时级 tracking 表中，仅取 placement=54（视频明投）、delivery_type=0（明投）的记录，按站点时区窗口过滤后聚合出价与扣费（CPM/100000 换算）。

3. **exchange_rate（汇率视图）**
   取目标站点当日平均汇率，用于后续本地币→USD 换算。

4. **campaign_roi（7日ROI视图）**
   取 pricing_type=15 的 campaign，统计近 7 日（包含当日）宽口径 GMV / 消耗，得到 campaign 级别 7 日 broad ROI，用于 `broad_advv_cost_7d` 和 `deepadvv` 计算。

5. **product_type_mapping（产品类型映射视图）**
   从维度表加载当日 `pricing_type` + `placement` 到 `sub_product_type` 的映射关系。

6. **dws_ads_parsed（广告效果明细预处理视图）**
   从 `dwd_advertise_performance_di` 过滤当日本地时区数据，排除无效广告（ads_id≤0）和原生发券商品（pricing_type=29），解析 `bid_voucher_id`，透传各效果指标。

7. **dws_ads_performance（广告效果汇总视图）**
   关联 `dws_ads_parsed` 与 `product_type_mapping`，生成 `main_product_types`、`product_types`（按 pricing_type/attr_data_type/placement 条件映射）、`feature_groups`（按 entrance/sub_entrance/placement 条件映射）三个分组标签，并按多维维度聚合点击、展现、订单、GMV、消耗、位置等指标；点击量根据广告产品特性选择不同口径（product_click/raw_click_cnt/deduplicated_click/click_cnt）。

8. **dws_ads_performance_joined（明细关联视图）**
   通过 UNION ALL 将三类广告分支分别关联出价/扣费/pAdvV 等明细：
   - **视频广告（pricing_type in 16,17,21）：** 关联视频明细表，`sum_ads_click_cnt` 为 null。
   - **ROI2.0-Simple（pricing_type=15）：** 关联普通明细表及 7 日 ROI，计算 `sum_ads_click_cnt`（窗口函数按 user_id/request_id/feature_groups/product_types/ads_id/item_id/campaign_id 分区）。
   - **其他类型：** 关联普通明细表，计算 `sum_ads_click_cnt`，`campaign_broad_roi_7d` 为 null。

9. **INSERT OVERWRITE 目标表**
   最终关联汇率视图，按分区（grass_region, local_date）全量覆盖写入目标表。关键计算包括：
   - 按 pricing_type 分支计算各 AdvV 指标（direct/broad/deepadvv/padvv）。
   - 本地币→USD 换算（÷ fx）。
   - platform 数字编码→字符串映射。
   - voucher_types 标签由 pricing_type、bid_voucher_id、display_ads_voucher_label 三字段联合判断生成。

### 注意事项

- **单文件单分区写入：** 本表为单 ETL 文件（non-multi-writer），每次执行覆盖 `grass_region` + `local_date` 一个分区，无并发写入风险。
- **汇率 AVG 使用：** 最终 INSERT 中汇率通过 `LEFT JOIN exchange_rate` + `avg(fx)` 方式引入，属于 BROADCAST join，需确保汇率维度表数据完整，否则 USD 换算结果为 null。
- **视频广告时区对齐：** 视频广告数据来源为小时分区（SG 时区），ETL 中通过 `date_timezone_convert` 函数将本地日期 00 时和 23 时转换为 SG 时区边界进行过滤，确保数据与本地日期对齐；若站点与 SG 时差较大，需注意跨日边界覆盖是否完整。
- **`__ALL__` 汇总标签：** `feature_groups`、`product_types`、`voucher_types`、`main_product_types` 均内置 `__ALL__` 标签，下游分析时需显式过滤，否则会产生重复计数。
- **pAdvV 仅在有点击时计算：** `sum_ads_click_cnt > 0` 是 pAdvV 计算的前置条件，视频广告类型（pricing_type in 16,17,21）该字段恒为 null。
- **广告位置字段语义：** `ads_total_location` 和 `top20_ads_total_location` 为位置编号之和（仅含有展现记录），单独使用无意义，需配合 `ads_imp_cnt` 计算平均位置。

---

*文档生成时间：2026-05-17*
<!-- ads-workspace-gdoc-sync: gdoc_id=1-ynLFGfRgolnRcP5X-FANa0xY90Ury3jN8U3z51m8-M gdoc_url=https://docs.google.com/document/d/1-ynLFGfRgolnRcP5X-FANa0xY90Ury3jN8U3z51m8-M/edit -->

# mp_paidads.dws_advertise_request_benchmark_advv_1d

**分层**：DWS（数据汇总层）
**主键**：`request_id + ads_id + item_id + user_id + campaign_id + pricing_type + placement + entrance + location + grass_region + grass_date`（逻辑主键，无物理唯一约束）
**分区**：`grass_region`（地区）、`grass_date`（日期）
**更新频率**：每日调度，各地区按本地时区参数化调度
**引用频次**：0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表是广告域以 **request_id × ads_id** 为粒度的日级基准宽表，记录每次广告请求中各广告单元的完整绩效数据。表中聚合了广告曝光、点击、订单、GMV、广告费用（直接成本与宽口径成本）、出价、扣费等核心指标，并通过 `feature_groups`、`product_types`、`main_product_types` 等多维标签体系支持灵活的切面分析，是广告系统绩效监控、ROI 计算、大盘口径基准对齐的核心数仓宽表。

本表主要用于以下场景：广告系统日常大盘指标计算（消耗、GMV、ROI）、不同产品线（ROI1.0 / ROI2.0 / ROI3.0）绩效对比、入口（Search / DD / YMAL 等）维度分拆、视频广告与图文广告分流分析、平台实验（A/B Test，通过 `plan_bucket_list`）效果评估，以及出价与扣费价格分布分析。

本表的核心价值在于：统一了 CPC 与 OCPM 两种计费模式下的出价与扣费口径，内置了 advv（广告视角价值归因）逻辑（direct / broad 两个归因层级）、ROI2.0 的 deepadvv 计算，以及排除异常值的 broad_advv_cost_excl_outlier 指标，为多种广告产品绩效归因提供标准化的计算基础。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `grass_region` | string | 地区标识，如 `MY`、`TH`、`SG` 等，大写形式存储。各地区按本地时区参数化调度写入 |
| `grass_date` | date | 数据日期（本地日期），与调度时区对齐 |

---

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `user_id` | bigint | 卖家（广告主）唯一标识，来源于广告请求记录 |
| `request_id` | string | 广告请求唯一标识，与 `ads_id` 共同构成本表最细粒度 |
| `ads_id` | bigint | 广告计划（Ad）唯一标识 |
| `item_id` | bigint | 广告关联商品唯一标识；视频广告场景下可为 0 |
| `campaign_id` | bigint | 广告系列（Campaign）唯一标识 |
| `decoded_video_id` | bigint | 视频广告的视频唯一标识，仅视频广告（placement=54）场景有值，普通图文广告为 null |
| `pricing_type` | int | 计费模式，如 CPC(1/2/3)、OCPM(4/8/11/15/20) 等，具体枚举见 `dim_product_type_mapping` |
| `attr_data_type` | int | 归因数据类型，用于区分 simple_mode_boost（=1）等子产品形态 |
| `placement` | bigint | 广告位（Placement）标识 |
| `entrance` | int | 广告入口类型，如 1=搜索、3=每日发现、4=YMAL 等，详见 ETL 中 `feature_groups` 映射逻辑 |
| `sub_entrance` | int | 广告子入口类型，对 entrance 的进一步细分 |
| `location` | bigint | 广告曝光位置（坑位），0 表示未曝光 |
| `sort_by` | string | 用户当前排序选项，如默认排序、价格排序等 |
| `target_type` | string | 投放目标类型 |
| `page_type` | string | 页面类型，枚举值包括 `image_search`、`search`、`shop`、`me` 等 |
| `page_section` | string | 页面区块，枚举值包括 `search`、`rcmd`、`you_may_also_like` 等 |
| `platform` | string | 客户端平台，枚举值：`ios_web`、`ios_app`、`android_web`、`android_app`、`pc_web`、`android_app_lite`、`other`；由 ETL 将原始整型字段转换而来 ⚠️ 原始数据为整型，ETL 已做映射转换，直接 GROUP BY 使用即可，无需再做数值转换 |
| `deduction_reason` | int | 扣费原因编码，用于区分不同触发扣费的场景 |
| `bid_voucher_id` | bigint | 出价关联的优惠券 ID，从 `bid_rerank_trace.bid_voucher_id` 中解析，ROI3.0 场景下有值，其余为 null |

---

### 维度：多值标签与分组

| 字段 | 类型 | 说明 |
|------|------|------|
| `feature_groups` | array\<string\> | 广告入口特征组标签数组，按 entrance + sub_entrance 映射生成，包含 `Search`、`Daily Discover`、`YMAL`、`Livestream` 等层级标签及 `__ALL__` 汇总标签 ⚠️ 为多值数组，过滤时需使用 `array_contains(feature_groups, 'xxx')` 而非 `=` 比较；`__ALL__` 代表全量汇总，直接 GROUP BY 会导致行重复计数 |
| `product_types` | array\<string\> | 广告产品类型标签数组，按 pricing_type + attr_data_type 映射，如 `roi2.0_simple`、`simple_ocpc` 等，含 `__ALL__` 汇总 ⚠️ 同 feature_groups，多值数组，不可直接 `=` 过滤；`__ALL__` 用于全量汇总时展开，避免重复计数 |
| `main_product_types` | array\<string\> | 广告主产品类型大类标签数组，分为 `roi1.0`、`roi2.0`、`roi3.0`、`others` 及 `__ALL__` ⚠️ 同上，多值数组，GROUP BY 时会展开，请使用 `array_contains` 过滤 |
| `voucher_types` | array\<string\> | 优惠券类型标签数组，枚举值包括 `roi3.0`、`roi3.0_display`、`no_voucher`、`__ALL__` ⚠️ 同上，多值数组，需用 `array_contains` 过滤 |
| `plan_bucket_list` | array\<bigint\> | 广告计划所属 A/B 实验的 BucketID 列表，用于实验效果评估；可为空数组 |
| `voucher_details_json` | string | ROI3.0 优惠券明细信息，JSON 格式存储，需使用 `get_json_object` 解析具体字段 ⚠️ 为 JSON 字符串，不可直接用于聚合，需解析后使用 |

---

### 指标：广告消耗与 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `revenue_usd_1d` | double | 广告消耗（扣费金额）折算美元，日粒度 |
| `broad_gmv_usd_1d` | double | 宽口径 GMV（广告带来的关联订单 GMV）折算美元，计算方式：`broad_gmv_local / exchange_rate` |
| `ads_gmv_usd_1d` | double | 窄口径 GMV（直接归因的广告订单 GMV）折算美元 |

---

### 指标：广告 ADVV 归因成本与 GMV

| 字段 | 类型 | 说明 |
|------|------|------|
| `direct_advv_cost_usd_1d` | double | 直接归因口径下的 advv 成本（美元）；CPC 类产品（pricing_type in 1/2/3/13/16）等于 revenue，其余产品等于 `ads_gmv × target_cir` ⚠️ 计算逻辑与 pricing_type 强相关，跨产品线汇总时口径需对齐，不可与 revenue 直接相加 |
| `broad_advv_cost_usd_1d` | double | 宽口径 advv 成本（美元）；CPC 类产品等于 revenue，其余等于 `broad_gmv_usd × target_cir` ⚠️ 同上，依赖 target_cir，target_cir 为 null 时结果为 0，需注意空值处理 |
| `direct_advv_gmv_usd_1d` | double | 直接归因口径下的 advv GMV（美元）；CPC 类等于 ads_gmv，其余等于 `revenue / target_cir` ⚠️ target_cir=0 时分母为 0，ETL 中已做保护（返回 0），汇总时需注意 |
| `broad_advv_gmv_usd_1d` | double | 宽口径 advv GMV（美元）；CPC 类等于 broad_gmv，其余等于 `revenue / target_cir` ⚠️ 同上 |
| `broad_advv_cost_excl_outlier_usd_1d` | double | 排除异常值（target_cir ≥ 50）后的宽口径 advv 成本（美元）；CPC 类产品与 broad_advv_cost 口径一致 ⚠️ 异常值过滤逻辑仅对非 CPC 产品生效，跨产品线比较时需注意 |
| `broad_advv_cost_usd_7d` | double | 基于过去 7 日 target_cir 计算的宽口径 advv 成本（美元），平滑单日波动 ⚠️ 使用的 target_cir 来自 7 日历史数据（`broad_gmv_amt_local × target_cir_7d`），口径与 _1d 字段不同，不可混用 |
| `deepadvv_usd_1d` | double | ROI2.0 Simple（pricing_type=15）专属的 deepadvv 指标（美元），计算逻辑：`broad_gmv_usd / campaign_broad_roi_7d`，其余产品类型为 null ⚠️ 仅对 pricing_type=15 有意义；campaign_broad_roi_7d 为 0 时返回 null；不可与其他产品线 advv 指标直接相加 |
| `padvv_usd_1d` | double | 广告位视角的 advv 值（美元），来源于 tracking 链路（padvv 字段），仅在有点击时累加；视频广告（pricing_type in 16/17/21）为 null ⚠️ 原始值单位为"分/万分"（除以 100000 折算 USD），视频广告不适用，跨产品线汇总需过滤 null |
| `avg_target_cir_1d` | double | 日内平均目标 CIR（Cost-Income Ratio，目标消耗收入比），来源于 tracking 链路 ⚠️ 为预计算均值，不可直接 SUM，跨行聚合需用加权平均（分子/分母重算）|

---

### 指标：广告流量

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_imp_cnt_1d` | bigint | 广告曝光次数，vitem 非首位卡片已排除 |
| `ads_click_cnt_1d` | bigint | 广告点击次数，已按产品类型区分 CPC/OCPM 点击口径（OCPM 使用去重点击，Livestream 使用 raw_click，视频广告使用 product_click） ⚠️ 点击口径因 pricing_type 和 entrance 不同而异，跨产品线汇总时点击数可比性受限 |
| `ads_order_cnt_1d` | double | 窄口径广告订单数 |
| `ads_broad_order_cnt_1d` | double | 宽口径广告订单数 |
| `ads_location_cnt_1d` | double | 有效曝光坑位数总和（仅 impression_cnt > 0 的 location 累加） |
| `top20_ads_location_cnt_1d` | double | Top20 坑位的曝光坑位数总和（location ≤ 19 且 impression_cnt > 0）⚠️ 该字段仅统计前 20 个位置，不代表全量坑位，不可与 ads_location_cnt_1d 直接相加 |

---

### 指标：出价价格

| 字段 | 类型 | 说明 |
|------|------|------|
| `sum_bid_price_usd_1d` | double | 全量（CPC+OCPM）出价金额合计（美元），原始值已除以 100000 折算 USD |
| `bid_price_cnt_1d` | double | 全量出价记录数（有出价的行数），用于计算平均出价 ⚠️ 为记录计数，与 `sum_bid_price_usd_1d` 配合使用计算平均出价，不可单独解读 |
| `sum_cpc_bid_price_usd_1d` | double | CPC 模式出价金额合计（美元） |
| `cpc_bid_price_cnt_1d` | double | CPC 出价记录数 ⚠️ 同 bid_price_cnt_1d，需配合 sum 字段计算均值 |
| `sum_ocpm_bid_price_usd_1d` | double | OCPM 模式出价金额合计（美元） |
| `ocpm_bid_price_cnt_1d` | double | OCPM 出价记录数 ⚠️ 同 bid_price_cnt_1d，需配合 sum 字段计算均值 |

---

### 指标：扣费价格

| 字段 | 类型 | 说明 |
|------|------|------|
| `sum_deduction_price_usd_1d` | double | 全量（CPC+OCPM）扣费金额合计（美元） |
| `deduction_price_cnt_1d` | double | 全量扣费记录数 ⚠️ 为记录计数，需配合 sum 字段计算平均扣费，不可单独解读 |
| `sum_cpc_deduction_price_usd_1d` | double | CPC 模式扣费金额合计（美元） |
| `cpc_deduction_price_cnt_1d` | double | CPC 扣费记录数 ⚠️ 同上 |
| `sum_ocpm_deduction_price_usd_1d` | double | OCPM 模式扣费金额合计（美元） |
| `ocpm_deduction_price_cnt_1d` | double | OCPM 扣费记录数 ⚠️ 同上 |

---

## 查询使用须知

### 必须包含的过滤条件

1. **`grass_region`**：每次查询必须指定分区字段 `grass_region`，否则将触发全分区扫描，产生极大的计算资源消耗。示例：`WHERE grass_region = 'MY'`
2. **`grass_date`**：每次查询必须指定日期分区，避免读取历史全量数据。示例：`AND grass_date = '2024-01-01'` 或 `AND grass_date BETWEEN '2024-01-01' AND '2024-01-07'`
3. **`pricing_type != 29`**：ETL 已在源表层排除原生发券商品（pricing_type=29），本表不含该类数据，无需再过滤。
4. **多值数组字段过滤**：过滤 `feature_groups`、`product_types`、`main_product_types`、`voucher_types` 时必须使用 `array_contains(feature_groups, 'Search')` 而非 `feature_groups = 'Search'`。过滤含 `__ALL__` 的行时需明确排除，避免重复计数。

遗漏分区条件后果：全表扫描将扫描所有地区、所有历史日期的 Parquet 文件，可能导致查询超时或资源耗尽。

---

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确计算方式 |
|------|------|------------|
| `avg_target_cir_1d` | 预计算均值，直接 SUM 无业务含义 | 需用加权方式：`SUM(broad_advv_cost_usd_1d) / SUM(broad_gmv_usd_1d)` 重新推算 CIR |
| `padvv_usd_1d` | 视频广告（pricing_type in 16/17/21）为 null，汇总时需过滤 | `SUM(CASE WHEN pricing_type NOT IN (16,17,21) THEN padvv_usd_1d ELSE 0 END)` |
| `deepadvv_usd_1d` | 仅 pricing_type=15 有意义，其余为 null | 仅在 pricing_type=15 场景下 SUM |
| `direct_advv_cost_usd_1d` / `broad_advv_cost_usd_1d` | 不同 pricing_type 下计算逻辑不同（revenue vs gmv×cir），跨产品线不可混合汇总 | 按 pricing_type 分组分别汇总，或明确口径后过滤特定 pricing_type |
| `direct_advv_gmv_usd_1d` / `broad_advv_gmv_usd_1d` | 依赖 target_cir，target_cir=0 时已保护为 0，但跨产品线汇总口径不一致 | 按 pricing_type 分组分别汇总 |
| `bid_price_cnt_1d` / `cpc_bid_price_cnt_1d` / `ocpm_bid_price_cnt_1d` | 为 COUNT 值，单独 SUM 无业务含义 | 与对应 sum 字段配合：`SUM(sum_bid_price_usd_1d) / SUM(bid_price_cnt_1d)` 计算平均出价 |
| `deduction_price_cnt_1d` / `cpc_deduction_price_cnt_1d` / `ocpm_deduction_price_cnt_1d` | 同上，为 COUNT 值 | 与对应 sum 字段配合计算平均扣费 |
| `feature_groups` / `product_types` / `main_product_types` / `voucher_types` | 多值数组，展开 GROUP BY 会导致行数翻倍，产生重复计数 | 先 `LATERAL VIEW explode()` 展开再过滤，或使用 `array_contains` 过滤单行 |
| `voucher_details_json` | JSON 字符串，不可聚合 | 使用 `get_json_object(voucher_details_json, '$.field')` 提取字段 |

---

### 时效性说明

- 本表为日调度表，T+1 产出，`grass_date` 为数据自然日（按各地区本地时区对齐）。查询最新数据应取 `MAX(grass_date)` 或明确指定已产出的最近日期，避免因调度延迟取到空分区。
- `broad_advv_cost_usd_7d` 字段依赖过去 7 日的历史数据（来自 `dws_advertise_performance_1d` 的 T-6 至 T 日窗口），历史数据不足 7 日时（如表初始化早期）该字段结果偏低，使用时需注意。
- `campaign_roi`（用于 deepadvv 计算）同样依赖 7 日窗口数据，新建 campaign 早期该字段可能为 null。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 核心事实表，提供广告请求级别的曝光、点击、消耗、GMV、出价/扣费等原始字段 |
| `mkplpaidads_data.dwd_advertise_tracking_item_di__reg_s0_live` | 广告 Tracking 链路商品级明细，提供 target_cir、padvv、voucher label 等归因参数（非视频广告） |
| `mp_paidads.dwd_request_tracking_video_hi__reg_s0_live` | 视频广告（明投，placement=54）的请求 Tracking 数据，提供视频广告的 target_cir |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，提供本地货币到美元的平均汇率，用于 GMV 和 advv 的货币换算 |
| `mp_paidads.dim_advertise__reg_s0_live` | 广告计划维表，提供 campaign 维度的 pricing_type 和 placement 属性（用于 campaign_roi 计算） |
| `mp_paidads.dws_advertise_performance_1d__reg_s0_live` | 广告绩效汇总日表，提供过去 7 日 campaign 维度的消耗和宽口径 GMV（用于计算 campaign_broad_roi_7d） |
| `mp_paidads.dim_product_type_mapping__reg_s0_live` | 产品类型映射维表，根据 pricing_type + placement 映射 product_type、sub_product_type、main_product_type |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.dwd_advertise_performance_di__reg_s0_live
    │
    ├──[过滤: tz_type='local', ads_id>0, pricing_type!=29]
    │
    ▼
[CTE: dws_ads_parsed]
(解析 bid_rerank_trace 提取 bid_price/deduction_price/bid_voucher_id 等，
 拆分 CPC / OCPM 出价与扣费口径)
    │
    ├── JOIN ──► mp_paidads.dim_product_type_mapping__reg_s0_live
    │              (mapping: pricing_type + placement → product_type/sub_product_type)
    │
    ▼
[CTE: dws_ads_performance]
(生成 feature_groups / product_types / main_product_types 多值数组,
 汇总曝光/点击/GMV/消耗/出价/扣费)
    │
    ├─[pricing_type IN (16,17,21)]─► JOIN ──► [CTE: advertise_tracking_item_video]
    │                                           (来源: dwd_request_tracking_video_hi
    │                                            提供视频广告 target_cir)
    │
    ├─[pricing_type = 15]──────────► JOIN ──► [CTE: advertise_tracking_item]
    │                                           (来源: dwd_advertise_tracking_item_di
    │                                            提供 target_cir / padvv / voucher_label)
    │                                JOIN ──► [CTE: campaign_roi]
    │                                           (来源: dim_advertise + dws_advertise_performance_1d
    │                                            计算 campaign 7日宽口径 ROI)
    │
    └─[其他 pricing_type]──────────► JOIN ──► [CTE: advertise_tracking_item]
                                               (提供 target_cir / padvv / voucher_label)
    │
    ▼
[CTE: dws_ads_performance_joined]
(UNION ALL 三类产品线结果，带入 target_cir / padvv / campaign_broad_roi_7d)
    │
    ├── JOIN ──► [CTE: exchange_rate]
    │              (来源: dim_exchange_rate, 计算日均汇率 fx)
    │
    ▼
[INSERT OVERWRITE]
dws_advertise_request_benchmark_advv_1d__reg_s0_live
(计算 advv 系列指标、deepadvv、platform 映射、voucher_types,
 出价/扣费金额 ÷ 100000 ÷ fx 换算美元，写入目标表)
```

---

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `advertise_tracking_item` | `dwd_advertise_tracking_item_di` | 聚合非视频广告的 target_cir、padvv 及 voucher 展示标签；排除 placement=54（视频明投）和 pricing_type=29 |
| `advertise_tracking_item_video` | `dwd_request_tracking_video_hi` | 聚合视频广告（placement=54，delivery_type=0）的 target_cir；使用本地时区时间戳窗口过滤跨天数据 |
| `exchange_rate` | `dim_exchange_rate` | 计算当日平均汇率（avg fx），用于 local → USD 换算 |
| `campaign_roi` | `dim_advertise` + `dws_advertise_performance_1d` | 计算 ROI2.0 Simple（pricing_type=15）campaign 级别过去 7 日宽口径 ROI（`broad_gmv / expenditure`），用于 deepadvv 分母；仅取 `tz_type='local'` 数据 |
| `product_type_mapping` | `dim_product_type_mapping` | pricing_type + placement 到产品类型（product_type / sub_product_type / main_product_type）的映射关系 |
| `dws_ads_parsed` | `dwd_advertise_performance_di` | 原始事实表过滤与字段解析，提取 bid_price / deduction_price（全量/CPC/OCPM 三套口径），并解析 bid_voucher_id |
| `dws_ads_performance` | `dws_ads_parsed` + `product_type_mapping` | 生成多值标签数组（feature_groups / product_types / main_product_types），GROUP BY 聚合各项度量 |
| `dws_ads_performance_joined` | `dws_ads_performance` + tracking CTE + `campaign_roi` | 按产品类型（视频/ROI2.0/其他）UNION ALL 分支关联 tracking 数据，带入 target_cir、padvv、campaign_broad_roi_7d |

---

### 注意事项

1. **tz_type 过滤**：源表 `dwd_advertise_performance_di` 中 `tz_type='local'` 表示按本地时区切分的数据，ETL 已强制过滤该条件，本表所有数据均为本地时区口径，无需在下游再做过滤。

2. **多值数组展开与重复计数**：`feature_groups`、`product_types`、`main_product_types`、`voucher_types` 均包含 `__ALL__` 汇总行，若 `LATERAL VIEW explode()` 展开后不过滤 `__ALL__`，所有指标将被重复计入一次，导致汇总结果偏大。

3. **视频广告与图文广告分流**：ETL 在 `dws_ads_performance_joined` 中通过 UNION ALL 分三路处理：pricing_type IN (16/17/21) 走视频 tracking 链路，pricing_type=15 关联 campaign_roi，其余走普通 tracking 链路。视频广告的 `padvv_usd_1d` 固定为 null。

4. **出价/扣费字段单位换算**：原始出价（bid_price）单位为"微分"（×10^-5 USD），ETL 在最终写入时统一除以 `100000 × fx` 换算为美元，字段已是 USD 口径，无需再做换算。

5. **campaign_broad_roi_7d 为 null 的情况**：若 campaign 在过去 7 日内无消耗记录，或 campaign 未匹配到维表记录，`campaign_broad_roi_7d` 为 null，导致 `deepadvv_usd_1d` 也为 null。新建 campaign 的早期数据存在此问题。

6. **exclusion 逻辑**：ETL 全程排除 `pricing_type = 29`（原生发券商品）和 `ads_placement = 54` 在非视频链路的记录（普通 tracking CTE 中排除 placement=54），确保视频广告仅走视频专属路径。

7. **汇率使用**：`exchange_rate` CTE 取当日地区平均汇率，`broad_advv_cost_usd_7d` 使用的是当日汇率折算（而非历史各日汇率），在汇率波动较大时可能与分日计算结果有偏差。

---

*文档生成时间：2026-05-20*
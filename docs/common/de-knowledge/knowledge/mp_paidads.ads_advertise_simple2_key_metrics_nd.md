<!-- ads-workspace-gdoc-sync: gdoc_id=1RiwvB4ybCpajQsWuVRDW78uZ_BkZnJP_WkAYyGZmb-I gdoc_url=https://docs.google.com/document/d/1RiwvB4ybCpajQsWuVRDW78uZ_BkZnJP_WkAYyGZmb-I/edit -->

# mp_paidads.ads_advertise_simple2_key_metrics_nd

**分层**：ADS（应用数据服务层）
**主键**：`ads_id`（结合分区 `grass_region` + `grass_date` + `tz_type` 唯一定位一条记录）
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日调度（T+1，各地区按本地时区参数化调度）
**引用频次**：0（末端 ADS 层表，未被其他候选表直接引用）

---

## 业务描述

本表是付费广告 **ROI 2.0 智能投放（Simple ROI 2.0）** 产品线的广告维度核心指标宽表，以广告 ID（`ads_id`）为粒度，聚合了每个广告在 1 天、3 天、7 天、14 天多个时间窗口下的曝光、点击、订单、GMV、花费等绩效指标，同时关联了预算状态、ROI 估算区间、推荐预算、冷启动阶段、商家/商品属性等维度信息，形成一张兼顾"广告健康度诊断"与"预算优化"双重用途的分析宽表。

本表是运营人员、算法团队和 BI 看板的主要数据来源，支持以下典型场景：① 广告 ROI 分层（系统视角/卖家视角）评估广告出价是否合理；② 识别预算打满（`is_hit_budget = 1`）广告，为预算提升推荐提供依据；③ 冷启动阶段广告监控（`is_cold_start_stage`）；④ 跨境店铺（`is_cb_shop`）与本土店铺的投放效果对比分析。

核心价值在于将散落在 DWD/DWS 多张底层表的数据横向拼宽、纵向聚合为不同时间窗口的指标，并通过预计算 ROI 分组、`advv`（广告价值量）、`cpa` 等派生字段，减少下游重复计算负担，同时保留原始分子/分母字段，支持下游按需重新聚合。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型，固定写入值为 `'local'`（本地时区）；查询时**必须过滤**，否则会命中多个分区副本 |
| `grass_region` | string | 地区编码（大写，如 `'MY'`、`'TH'`），各地区按本地时区参数化调度 |
| `grass_date` | date | 数据日期，对应业务本地日期 |

---

### 维度：主键与广告属性

| 字段 | 类型 | 说明 |
|------|------|------|
| `ads_id` | bigint | 广告 ID，本表主键 |
| `shop_id` | bigint | 广告所属店铺 ID |
| `campaign_id` | bigint | 广告所属推广计划 ID |
| `item_id` | bigint | 广告推广的商品 ID |
| `status_combine` | string | 广告综合状态；`'normal'` 表示计划与广告均处于开启状态（`campaign_status = 1 AND ads_status = 1`），否则为 `'abnormal'` ⚠️ 为预计算枚举字符串，不可用于数值运算；若需筛选有效投放广告，请过滤 `status_combine = 'normal'` |
| `limit_type` | int | 预算限制类型：`0` = 不限预算，`1` = 限额预算（依据 `budget_usd` 是否等于 `9999999999` 判断） |
| `is_hit_budget` | tinyint | 是否打满预算：当 `expenditure_amt_usd_1d > campaign_valid_budget_amt_usd × 0.97` 且预算 > 0 时置 `1`，否则为 `0` ⚠️ 为预计算 Flag，仅在 1d 花费维度下有效，跨时间窗口不适用 |
| `is_cb_shop` | tinyint | 是否跨境店铺：`1` = 跨境，`0` = 本土；空值已被 `COALESCE` 处理为 `0` |
| `seller_type_1p` | string | 卖家类型（1P 标签），来自店铺维表；NULL 时填充为 `'unknow'` |
| `is_migrated_item` | tinyint | 商品是否为迁移商品（由其他投放类型迁移至 ROI 2.0） |
| `item_first_adopted_date` | date | 商品首次接入 Simple ROI 2.0 的日期 |
| `is_cold_start_stage` | tinyint | 当天最新一次有曝光记录的广告是否处于冷启动阶段：`1` = 是，`0` = 否；无曝光记录时为 NULL ⚠️ 仅取当日最后一次有曝光的记录状态（`row_number` 取最新），非全天汇总 |

---

### 维度：预算与推荐

| 字段 | 类型 | 说明 |
|------|------|------|
| `campaign_valid_budget_amt_usd` | double | 推广计划有效预算（本地货币），来自 `ads_campaign_valid_budget_1d` |
| `input_budget_amt` | double | 系统推荐预算功能中，用户输入的预算金额 |
| `final_recommended_budget_amt` | double | 系统最终推荐预算金额 ⚠️ 来自 `rcmd_budget` CTE，取 `row_number() = 1`（最新日期）的快照，并非当日实时值；若目标日期无数据，则沿用历史最近一条 |

---

### 维度：ROI 分组

| 字段 | 类型 | 说明 |
|------|------|------|
| `roi_group_7d_system` | string | 系统视角 ROI 分组（基于 7 日 GMV/花费 与估算 ROI 区间比较）：`1. Overbid` / `2. Fulfilled` / `3. Underbid` / `4. No GMV` / `5. No rev` / `6. Null db_value` / `7. Others` ⚠️ 为预计算派生字段，不可直接 SUM；用于分组统计时建议 `GROUP BY` 使用 |
| `roi_group_7d_seller` | string | 卖家视角 ROI 分组（在系统视角基础上引入 0.8×/1.2× 弹性系数）：`1. Overbid` / `2. Fulfil Strategy` / `3. System Underbid` / `4. Underbid` / `5. No GMV` / `6. No rev` / `7. Null db_value` / `8. Others` ⚠️ 同上，预计算枚举值，不可直接 SUM |

---

### 指标：目标参数

| 字段 | 类型 | 说明 |
|------|------|------|
| `target_cir` | double | 广告目标 CIR（花费/GMV 比值），有曝光时取均值 ⚠️ 为 `AVG` 聚合结果，跨广告 SUM 无意义，需用各广告的分子分母重新计算 |
| `cpa` | double | 目标每单成本：`target_cir × item_price / exchange_rate`（换算为美元） ⚠️ 为预计算派生字段，不可直接 SUM；跨广告比较时应回到原始价格和汇率重新计算 |
| `est_roi_lower` | double | 系统估算 ROI 下界（来自当日 `dim_campaign` 的 `simple_roi_two_estimate` 结构体字段） |
| `est_roi_upper` | double | 系统估算 ROI 上界 |
| `est_7days_order_lower` | double | 系统估算未来 7 天订单量下界 |
| `est_7days_order_upper` | double | 系统估算未来 7 天订单量上界 |

---

### 指标：1 日绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `impression_cnt_1d` | bigint | 当日曝光次数 |
| `click_cnt_1d` | bigint | 当日点击次数（去重） |
| `direct_order_cnt_1d` | bigint | 当日直接归因订单数 |
| `direct_order_gmv_amt_usd_1d` | double | 当日直接归因 GMV（本地货币，字段注释标注为 usd 但实为本地货币，见 DDL comment） ⚠️ 字段命名含 `_usd` 但 DDL 注释明确说明为 `local currency`，跨地区汇总需做汇率换算 |
| `broad_order_cnt_1d` | bigint | 当日宽口径归因订单数 |
| `broad_order_gmv_amt_usd_1d` | double | 当日宽口径归因 GMV（本地货币）⚠️ 同上，跨地区汇总需做汇率换算 |
| `expenditure_amt_usd_1d` | double | 当日广告花费（本地货币）⚠️ 同上，跨地区汇总需做汇率换算 |
| `net_expenditure_amt_usd_1d` | double | 当日净广告花费（扣除返点后），仅含 `pricing_type = 15` 的记录 |
| `advv_1d` | double | 当日广告价值量：`SUM(broad_gmv_amt_usd × target_cir)`，衡量广告带来的预期价值 ⚠️ 为预计算派生加权值，不可直接 SUM 后再做均值；跨广告汇总可直接 SUM |
| `paid_broad_order_cnt_1d` | bigint | 当日付费宽口径订单数 |
| `paid_broad_order_gmv_amt_usd_1d` | double | 当日付费宽口径 GMV（美元） |
| `paid_advv_1d` | double | 当日付费广告价值量：`SUM(paid_broad_gmv_usd × target_cir)` ⚠️ 为预计算派生字段，跨广告可直接 SUM，但不可与非付费 `advv_1d` 混用 |

---

### 指标：3 日绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `expenditure_amt_usd_3d` | double | 近 3 日广告花费（`grass_date - 2` 至 `grass_date`，本地货币） |
| `advv_3d` | double | 近 3 日广告价值量 ⚠️ 为预计算派生字段，SUM 聚合时需注意口径一致 |

---

### 指标：7 日绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `click_cnt_7d` | bigint | 近 7 日点击次数 |
| `broad_order_cnt_7d` | bigint | 近 7 日宽口径订单数 |
| `broad_order_gmv_amt_usd_7d` | double | 近 7 日宽口径 GMV（本地货币）⚠️ 跨地区汇总需做汇率换算 |
| `expenditure_amt_usd_7d` | double | 近 7 日广告花费（本地货币）⚠️ 同上 |
| `advv_7d` | double | 近 7 日广告价值量 |
| `impression_cnt_7d` | bigint | 近 7 日曝光次数 |

---

### 指标：14 日绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `click_cnt_14d` | bigint | 近 14 日点击次数 |
| `broad_order_cnt_14d` | bigint | 近 14 日宽口径订单数 |
| `broad_order_gmv_amt_usd_14d` | double | 近 14 日宽口径 GMV（本地货币）⚠️ 跨地区汇总需做汇率换算 |
| `expenditure_amt_usd_14d` | double | 近 14 日广告花费（本地货币）⚠️ 同上 |
| `advv_14d` | double | 近 14 日广告价值量 |
| `impression_cnt_14d` | bigint | 近 14 日曝光次数 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询必须同时指定以下三个分区字段，避免全表扫描：

| 分区字段 | 推荐用法 | 遗漏后果 |
|----------|----------|----------|
| `tz_type` | 固定写 `tz_type = 'local'` | 本表仅写入 `local` 分区，但若省略可能触发全分区扫描，影响性能 |
| `grass_region` | 指定目标地区，如 `grass_region = 'MY'` | 省略将扫描所有地区分区，数据量倍增且结果混杂多地区 |
| `grass_date` | 指定具体日期，如 `grass_date = '2025-01-01'` | 省略将扫描全量历史分区，极易超时或产生资源浪费 |

> **注意**：本表仅收录 **近 7 日内有曝光记录**（`has_performance_7d = 1`）的广告，无此条件的广告不会出现在结果中，查询结果与广告总数可能存在差异。

---

### 不可直接 SUM 的字段

| 字段 | 问题类型 | 正确计算方式 |
|------|----------|-------------|
| `target_cir` | `AVG` 聚合比率 | 应返回广告粒度原始值后，用 `SUM(expenditure) / SUM(gmv)` 在外部重新计算加权均值 |
| `cpa` | 派生字段（`target_cir × price / exchange_rate`） | 需用各广告的 `target_cir`、商品价格、当日汇率分别计算后再汇总 |
| `roi_group_7d_system` | 枚举字符串，已预计算分组 | 仅用于 `GROUP BY` 或 `WHERE` 过滤，不参与数值运算 |
| `roi_group_7d_seller` | 同上 | 同上 |
| `status_combine` | 枚举字符串 | 仅用于过滤（`= 'normal'`），不参与数值运算 |
| `is_hit_budget` | 仅基于 1d 花费判断 | 跨时间窗口预算打满分析需自行用 `expenditure_amt_usd_Nd / campaign_valid_budget_amt_usd` 重新判断 |
| `final_recommended_budget_amt` | 历史快照取最新值 | 非当日实时值；若同一活动当日无推荐预算记录，则为历史沿用值，使用时需关注数据时效 |
| `advv_*`（1d/3d/7d/14d） | 预计算加权值（`gmv × target_cir`） | 多广告跨店汇总可直接 `SUM`；但不可对 `advv` 求均值后再乘以数量，需始终用原始分子分母 |
| `*_usd_*`（含本地货币的字段） | 字段名含 `_usd` 但实为本地货币 | 跨地区汇总时需关联 `ex_rate`（`mp_order.dim_exchange_rate`）做汇率换算；`paid_broad_order_gmv_amt_usd_1d` 为真实 USD |

---

### 时效性说明

- **多窗口滚动计算**：`_7d`、`_14d` 等字段是在当日调度时从 `dwd_advertise_performance_di` 中回溯 N 日数据动态聚合的，**每天分区的值只代表该分区对应日期的窗口汇总**，不同日期分区下的同名字段窗口定义一致（均为当日往前 N 日），可跨日期对比趋势。
- **推荐预算快照**（`final_recommended_budget_amt`、`input_budget_amt`）：来自 ODS 日志表，取 `2024-10-01` 至当日最新一条记录，若某广告当日无新日志则沿用历史最近值，使用时需注意字段值可能并非当日最新状态。
- **数据入库建议**：建议取 **T 日最新分区**（`grass_date = current_date - 1`）进行日常分析；若需实时数据，需评估上游 `dwd_advertise_performance_di` 的数据延迟。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告每日曝光、点击、订单、GMV、花费等绩效明细（1d 及 14d 滚动窗口的基础数据、冷启动阶段标签） |
| `mp_paidads.dws_advertise_net_ads_revenue_1d__reg_s0_live` | 广告净收入（用于计算净花费 `net_expenditure_amt_usd_1d`） |
| `mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live` | 推广计划有效预算及预算类型（`limit_type`、`is_hit_budget`） |
| `mp_paidads.dim_advertise__reg_s0_live` | 广告维度表，提供 `ads_id`、`item_id`、`shop_id`、广告/计划状态、产品类型等 |
| `mp_paidads.dim_campaign__reg_s0_live` | 推广计划维度表，提供 ROI 估算区间（`est_roi_lower/upper`、`est_7days_order_*`） |
| `mp_paidads.ods_log_simple_roi2_estimated_data_s0_live` | 推荐预算日志（`input_budget`、`recommended_budget`），取最新日期快照 |
| `mp_paidads.dws_item_simple_roi2_first_adopted_td__reg_s0_live` | 商品首次接入 ROI 2.0 信息（`is_migrated_item`、`item_first_adopted_date`） |
| `cncbbi_general.shop_level_shop_info_shopee_td` | 店铺维表，提供跨境标签（`is_cb_shop`）和卖家类型（`seller_type_1p`） |
| `mp_order.dim_exchange_rate__reg_s0_live` | 汇率维表，用于计算 `cpa`（本地货币转美元） |

---

## ETL 逻辑摘要

### 数据流

```
dwd_advertise_performance_di ──────────────────────────────┐
  │ (14d 滚动窗口聚合)                                      │
  ├─► [l14d_metrics]                                        │ (1d 聚合)
  │   click/order/gmv/expenditure/advv (1d/3d/7d/14d)      ├─► [perf_metrics]
  │   has_performance_7d 过滤驱动主表                        │
  │                                                         │ (冷启动 bit 标签)
  │                                                         └─► [perf_cold_start_stage]
  │
dws_advertise_net_ads_revenue_1d ──► [net_rev]
  │   net_expenditure_amt_usd_1d
  │
ads_campaign_valid_budget_1d ──────► [valid_budget]
  │   limit_type / campaign_valid_budget / is_hit_budget
  │
dim_advertise ─────────────────────► [dim_status]
  │   ads_id / item_id / shop_id / status_combine
  │   过滤 product_type = 'ROI2.0'
  │
dim_campaign ──────────────────────► [estimate_roi_gmv]
  │   est_roi_lower/upper / est_7days_order_lower/upper
  │
ods_log_simple_roi2_estimated_data ► [rcmd_budget]
  │   input_budget / recommended_budget (取最新日期快照)
  │
shop_level_shop_info_shopee_td ────► [cb_tag]
  │   is_cb_shop / seller_type_1p
  │
dws_item_simple_roi2_first_adopted ► [adopt_tag]
  │   is_migrated_item / item_first_adopted_date
  │
dim_exchange_rate ─────────────────► [ex_rate]
      exchange_rate (用于 cpa 计算)
  │
  └─ [l14d_metrics] (has_performance_7d=1, 驱动主表)
       LEFT JOIN [dim_status]         → shop_id / item_id / status_combine
       LEFT JOIN [perf_metrics]       → 1d 绩效指标
       LEFT JOIN [valid_budget]       → 预算信息
       LEFT JOIN [net_rev]            → 净花费
       LEFT JOIN [estimate_roi_gmv]   → ROI 估算区间
       LEFT JOIN [rcmd_budget]        → 推荐预算
       LEFT JOIN [cb_tag]             → 跨境/卖家标签
       LEFT JOIN [adopt_tag]          → 商品接入信息
       LEFT JOIN [ex_rate]            → 汇率
       LEFT JOIN [perf_cold_start_stage] → 冷启动阶段
              │
              ▼
  ads_advertise_simple2_key_metrics_nd__reg_s0_live
  PARTITION (tz_type='local', grass_region, grass_date)
```

### 关键 CTE 说明

| CTE | 来源表 | 作用 |
|-----|--------|------|
| `l14d_metrics` | `dwd_advertise_performance_di` | 以 `ads_id` 为粒度，聚合近 14 日绩效指标，同时用条件 SUM 切分出 7d、3d 子窗口；包含 `has_performance_7d` 标志用于驱动主表过滤 |
| `perf_metrics` | `dwd_advertise_performance_di` | 以 `ads_id` 为粒度，聚合当日（1d）绩效指标及付费订单/GMV；同时计算 `target_cir`（AVG）、`item_price`（AVG）用于下游 `cpa` 计算 |
| `perf_cold_start_stage` | `dwd_advertise_performance_di` | 取当日最后一次有曝光记录（`row_number` 按 `timestamp` 降序），读取 `ad_tag` 第 34 位标识冷启动阶段 |
| `net_rev` | `dws_advertise_net_ads_revenue_1d` | 聚合当日净广告收入，提供 `net_expenditure_amt_usd_1d` |
| `valid_budget` | `ads_campaign_valid_budget_1d` | 读取推广计划有效预算，计算 `limit_type` 和 `is_hit_budget` |
| `dim_status` | `dim_advertise` | 取当日广告维度信息（`item_id`、`shop_id`、广告/计划状态），仅保留 `product_type = 'ROI2.0'` 的广告 |
| `estimate_roi_gmv` | `dim_campaign` | 从推广计划维表中读取 `simple_roi_two_estimate` 结构体，解析 ROI 和订单量估算区间 |
| `rcmd_budget` | `ods_log_simple_roi2_estimated_data` | 从 `2024-10-01` 至当日日志中取每个计划最新一条推荐预算记录（`row_number` 按 `grass_date` 降序） |
| `cb_tag` | `cncbbi_general.shop_level_shop_info_shopee_td` | 提供店铺跨境标签和卖家类型，NULL 的 `seller_type_1p` 填充为 `'unknow'` |
| `adopt_tag` | `dws_item_simple_roi2_first_adopted_td` | 提供商品首次接入日期和迁移标签 |
| `ex_rate` | `mp_order.dim_exchange_rate` | 提供当日汇率，用于计算 `cpa = target_cir × item_price / exchange_rate` |

### 注意事项

1. **数据入口过滤（`has_performance_7d = 1`）**：本表以 `l14d_metrics` 中 `has_performance_7d = 1` 的广告为主驱动，即**近 7 日内至少有 1 天存在绩效数据的广告才会出现**。长时间停投或未投放的广告不会出现在结果中，使用本表做广告覆盖率统计时需注意分母口径。

2. **全部使用 LEFT JOIN**：主表（`l14d_metrics`）与其他所有 CTE 均通过 `LEFT JOIN` 关联，意味着部分维度字段（如 `shop_id`、`item_id`、`est_roi_*`）可能为 NULL（如广告当日已下线、维度表无对应记录），使用时需注意 NULL 处理。

3. **货币单位混用风险**：本表大多数 `_amt_usd_*` 后缀字段实为**本地货币**（DDL 注释明确标注 `local currency`），仅 `paid_broad_order_gmv_amt_usd_1d` 注释为真实 USD。跨地区汇总分析时必须结合 `dim_exchange_rate` 进行汇率换算，切勿将不同地区的本地货币字段直接相加。

4. **`pricing_type = 15` 过滤**：所有绩效相关 CTE 均过滤 `pricing_type = 15`（对应 ROI 2.0 智能出价类型），本表数据仅代表该定价类型的投放效果，不包含其他广告类型。

5. **推荐预算时效性**：`rcmd_budget` 从 `2024-10-01` 起的历史日志中取最新快照，若某推广计划在近期无新的推荐预算日志，则 `final_recommended_budget_amt` 将沿用历史值，与当日实际推荐结果可能存在偏差。

6. **`cpa` 字段的计算链条**：`cpa = target_cir × item_price / exchange_rate`，其中 `target_cir` 和 `item_price` 均来自当日有曝光的广告记录 AVG 聚合，`exchange_rate` 来自汇率维表。任意一个环节缺失均会导致 `cpa` 为 NULL。

---

*文档生成时间：2026-04-22*
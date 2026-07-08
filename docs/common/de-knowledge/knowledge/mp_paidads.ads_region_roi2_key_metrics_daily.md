<!-- ads-workspace-gdoc-sync: gdoc_id=1cA9H8iBsn4oMlk66CNExS6OiUpWFDPLVm6r2ZlXeSjc gdoc_url=https://docs.google.com/document/d/1cA9H8iBsn4oMlk66CNExS6OiUpWFDPLVm6r2ZlXeSjc/edit -->

# mp_paidads.ads_region_roi2_key_metrics_daily

**分层**：ADS（应用数据服务层）
**主键**：`tz_type` + `grass_region` + `grass_date`
**分区**：`tz_type` / `grass_region` / `grass_date`
**更新频率**：每日 T+1 更新（写入前一自然日数据）
**引用频次**：0（末端 ADS 层表，未被其他候选表引用）

---

## 业务描述

本表为 ROI² 付费广告（placement = 40）大盘核心指标日报表，以地区（`grass_region`）+ 日期（`grass_date`）为粒度，汇聚 ROI² 广告的曝光、点击、花费、GMV、订单、活跃广告主/广告/商品、预算健康度、ROI 分布、流量提升效果以及净广告收入等多维关键指标。

本表是付费广告运营监控与经营分析的核心数据来源，适用于日常大盘 ROI² 健康度追踪、广告主活跃度分析、出价合理性（超出价/合理出价/欠出价）分布分析、预算受限分析、平台商品 GMV 提升效果评估及净收入报告等场景。BI 报表、周期性运营看板、以及管理层 ROI² 经营日报均可直接从本表取数。

各地区按本地时区参数化调度，覆盖全量业务地区。数据每日在调度完成后写入对应分区，仅包含 `tz_type = 'local'`（本地时区口径）数据。

---

## 字段列表

### 分区字段

| 字段 | 类型 | 说明 |
|------|------|------|
| `tz_type` | string | 时区类型，当前仅写入 `'local'`（本地时区口径）。查询时必须过滤，否则触发全分区扫描 |
| `grass_region` | string | 业务大区编码（大写），如 `'SG'`、`'MY'` 等，各地区独立调度写入 |
| `grass_date` | date | 业务日期（本地时区），格式 `yyyy-MM-dd`，对应前一自然日（T-1） |

---

### 维度：主键与广告属性

> 本表为纯指标聚合表，无独立维度字段。主键由三个分区字段（`tz_type`、`grass_region`、`grass_date`）联合构成，每个分区组合对应唯一一行汇总记录。

---

### 指标：ROI² 广告基础绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `roi2_ads_revenue_usd` | double | ROI² 广告（placement=40）当日广告花费总额（USD），来源字段 `ads_expenditure_amt_usd` |
| `roi2_ads_click_cnt` | bigint | ROI² 广告当日去重点击次数，来源字段 `deduplicated_click_cnt` |
| `roi2_ads_impression_cnt` | bigint | ROI² 广告当日曝光次数，来源字段 `impression_cnt` |
| `roi2_cps_dedup_click_cnt` | bigint | ROI² 广告当日 CPS 去重点击次数，来源字段 `cps_dedup_click_cnt` |
| `roi2_broad_gmv_usd` | double | ROI² 广告带来的宽口径 GMV（USD），包含广告关联的全部订单 GMV |
| `roi2_broad_order_cnt` | bigint | ROI² 广告带来的宽口径订单数 |
| `roi2_paid_broad_gmv_usd` | double | ROI² 广告带来的付费宽口径 GMV（USD），仅统计付费订单 |
| `roi2_paid_broad_order_cnt` | bigint | ROI² 广告带来的付费宽口径订单数 |

---

### 指标：ROI² 活跃规模

| 字段 | 类型 | 说明 |
|------|------|------|
| `roi2_active_ads_cnt` | bigint | ROI² 当日活跃广告数（`is_ads_active=1` 或 `has_performance=1`，按 `ads_id` 去重） |
| `roi2_active_ads_item_cnt` | bigint | ROI² 当日活跃广告覆盖的商品数（按 `item_id` 去重） |
| `roi2_active_advertiser_cnt` | bigint | ROI² 当日活跃广告主数（按 `shop_id` 去重） |
| `roi2_whitelist_shop_cnt` | bigint | ROI² 白名单店铺数。⚠️ 当前 ETL 中固定写入 `null`，字段暂无数据，不可用于分析 |
| `roi2_active_30d_whitelist_shop_cnt` | bigint | ROI² 近 30 日活跃白名单店铺数。⚠️ 当前 ETL 中固定写入 `null`，字段暂无数据，不可用于分析 |
| `active_30d_advertiser_cnt` | bigint | 过去 30 日内有活跃行为（`is_ads_active=1` 或 `has_performance=1`）的广告主数（跨所有 placement，按 `shop_id` 去重） |

---

### 指标：全平台广告基础绩效

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_ads_revenue_usd` | double | 全平台（所有 placement）当日广告花费总额（USD） |
| `total_active_ads_cnt` | bigint | 全平台当日活跃广告数（`is_ads_active=1` 或 `has_performance=1`，按 `ads_id` 去重） |
| `total_active_ads_item_cnt` | bigint | 全平台当日活跃广告覆盖的商品数（按 `item_id` 去重） |
| `total_active_advertiser_cnt` | bigint | 全平台当日活跃广告主数（按 `shop_id` 去重） |

---

### 指标：净广告收入

| 字段 | 类型 | 说明 |
|------|------|------|
| `total_net_ads_revenue_usd_1d` | double | 全平台（所有 placement）当日净广告收入（USD），来源 `dws_advertise_net_ads_revenue_1d` |
| `roi2_net_ads_revenue_usd_1d` | double | ROI²（placement=40）当日净广告收入（USD） |

---

### 指标：ROI 出价分组分布

> ROI 分组依据：基于近 7 日实际 ROI 与目标 CIR 的比值（`roi_ratio = sum(broad_gmv * target_cir) / sum(expenditure)`），将活跃广告系列分为超出价、合理出价、欠出价三大类共 6 个子区间，以及排除无数据系列后的汇总。

| 字段 | 类型 | 说明 |
|------|------|------|
| `roi2_overbid_camp_1_cnt` | bigint | ROI 比值在 [0, 0.5) 区间的广告系列数（深度超出价） |
| `roi2_overbid_camp_1_rev_usd` | double | ROI 比值在 [0, 0.5) 区间的广告系列当日花费（USD） |
| `roi2_overbid_camp_2_cnt` | bigint | ROI 比值在 [0.5, 0.8) 区间的广告系列数（轻度超出价） |
| `roi2_overbid_camp_2_rev_usd` | double | ROI 比值在 [0.5, 0.8) 区间的广告系列当日花费（USD） |
| `roi2_fulfilled_camp_1_cnt` | bigint | ROI 比值在 [0.8, 1) 区间的广告系列数（接近达成，略低于目标） |
| `roi2_fulfilled_camp_1_rev_usd` | double | ROI 比值在 [0.8, 1) 区间的广告系列当日花费（USD） |
| `roi2_fulfilled_camp_2_cnt` | bigint | ROI 比值在 [1, 1.2] 区间的广告系列数（达成目标，略超） |
| `roi2_fulfilled_camp_2_rev_usd` | double | ROI 比值在 [1, 1.2] 区间的广告系列当日花费（USD） |
| `roi2_underbid_camp_1_cnt` | bigint | ROI 比值在 (1.2, 2) 区间的广告系列数（轻度欠出价） |
| `roi2_underbid_camp_1_rev_usd` | double | ROI 比值在 (1.2, 2) 区间的广告系列当日花费（USD） |
| `roi2_underbid_camp_2_cnt` | bigint | ROI 比值 ≥ 2 的广告系列数（深度欠出价） |
| `roi2_underbid_camp_2_rev_usd` | double | ROI 比值 ≥ 2 的广告系列当日花费（USD） |
| `roi2_total_excl_nodata_camp_cnt` | bigint | 排除无数据（`no data`/`no gmv`/`no rev`）后有效广告系列总数 |
| `roi2_total_excl_nodata_camp_rev_usd` | double | 排除无数据系列后有效广告系列当日花费合计（USD） |

⚠️ 以上分组字段中的 `_rev_usd` 字段均为当日花费分拆值，各组之和约等于 `roi2_total_excl_nodata_camp_rev_usd`，但因无数据系列被剔除，**不等于** `roi2_ads_revenue_usd`，不可混用。

---

### 指标：预算健康度

| 字段 | 类型 | 说明 |
|------|------|------|
| `roi2_valid_budget_usd` | double | ROI² 白名单广告系列有效预算总额（USD），来源 `ads_campaign_valid_budget_1d`，含无限预算（budget=9999999999）系列 |
| `roi2_valid_budget_limited_usd` | double | ROI² 有预算上限（`budget_usd ≠ 9999999999`）的广告系列有效预算合计（USD）。⚠️ 与 `roi2_valid_budget_usd` 口径不同，仅含有限预算系列，不可直接对比或相加 |
| `roi2_campaign_expenditure_limited_usd` | double | ROI² 有预算上限广告系列的实际花费合计（USD），与 `roi2_valid_budget_limited_usd` 口径一致，可用于计算有限预算系列的预算使用率 |

---

### 指标：商品 GMV 提升效果（Uplift 分析）

> 逻辑说明：以 ROI² 广告（placement=40）近 7 日有曝光有花费的商品为分析窗口，对比这些商品近 7 日平均日 GMV（`platform_gmv_w7d`）与前 14 日 GMV 中位数（`platform_gmv_med14d`），判断 GMV 是否有显著提升（≥10%）。

| 字段 | 类型 | 说明 |
|------|------|------|
| `window_item_cnt` | bigint | 近 7 日 ROI² 活跃投放且有历史基准数据的商品总数（分析窗口大小） |
| `uplift_10p_item_cnt` | bigint | 窗口内 GMV 较历史中位数提升 ≥10% 的商品数 |
| `window_revenue_usd` | double | 分析窗口内全部商品的近 7 日 ROI² 广告花费合计均值汇总（USD）。⚠️ 为各商品 7 日花费均值之和，非简单 SUM，不可与 `roi2_ads_revenue_usd` 直接对比 |
| `uplift_10p_revenue_usd` | double | GMV 提升 ≥10% 的商品对应的近 7 日广告花费（USD）。⚠️ 同上，为均值汇总口径 |

---

## 查询使用须知

### 必须包含的过滤条件

每次查询**必须同时指定以下分区字段**，否则将触发全分区扫描，造成资源浪费和查询超时：

| 过滤字段 | 推荐值/说明 | 遗漏后果 |
|----------|-------------|----------|
| `tz_type` | 固定使用 `tz_type = 'local'`（当前唯一写入值） | 若省略，虽数据不变但会触发分区遍历 |
| `grass_region` | 指定目标地区，如 `grass_region = 'SG'` | 遗漏将跨所有地区扫描，结果被错误聚合 |
| `grass_date` | 指定具体日期或日期范围，如 `grass_date = '2025-04-21'` | 遗漏将扫描全量历史分区，严重影响性能 |

**示例过滤条件（最小必要条件）**：
```sql
WHERE tz_type = 'local'
  AND grass_region = 'SG'
  AND grass_date = '2025-04-21'
```

### 不可直接 SUM 的字段

| 字段 | 原因 | 正确计算方式 |
|------|------|-------------|
| `roi2_whitelist_shop_cnt` | ETL 中固定写入 `null`，当前无有效数据 | 暂不使用，等待后续填充 |
| `roi2_active_30d_whitelist_shop_cnt` | ETL 中固定写入 `null`，当前无有效数据 | 暂不使用 |
| `roi2_valid_budget_limited_usd` | 口径仅含有限预算系列（剔除无限预算），不可与 `roi2_valid_budget_usd` 相加或混用 | 单独使用，计算预算使用率时配合 `roi2_campaign_expenditure_limited_usd` |
| `window_revenue_usd` | 为各商品 7 日均值花费之和，非真实总花费，不可与 `roi2_ads_revenue_usd` 直接累加或对比 | 仅用于 Uplift 分析场景内部比较 |
| `uplift_10p_revenue_usd` | 同上，均值口径，非真实花费 | 仅用于计算 `uplift_10p_revenue_usd / window_revenue_usd` 等比率 |
| `roi2_total_excl_nodata_camp_rev_usd` | 剔除无数据系列后的花费，不等于 `roi2_ads_revenue_usd` | 用于 ROI 分组分析的分母；若需大盘花费请用 `roi2_ads_revenue_usd` |
| ROI 比值 | 本表未直接存储 ROI 比值字段，如需计算 ROI 需从 `roi2_broad_gmv_usd` 和 `roi2_ads_revenue_usd` 重新推导 | `roi2_broad_gmv_usd / roi2_ads_revenue_usd`（注意口径与目标 CIR 的配合） |

**跨地区/日期聚合注意事项**：  
- `roi2_active_advertiser_cnt`、`total_active_advertiser_cnt`、`active_30d_advertiser_cnt` 等 `count(distinct ...)` 派生字段，跨地区或跨日期 SUM 时**不等于**真实去重数，如需跨维度去重须回溯明细层。

### 时效性说明

- 本表每日 T+1 写入，`grass_date` 存储前一自然日数据，最新数据分区为昨日（`BIZ_YESTERDAY`）。
- `active_30d_advertiser_cnt` 基于过去 30 日滑动窗口（`[PREV_30D, BIZ_YESTERDAY]`）计算，取某日分区时其含义为"截至该日前 30 日的活跃广告主数"，**不可跨日期 SUM**。
- `window_revenue_usd`、`uplift_10p_revenue_usd`、`uplift_10p_item_cnt`、`window_item_cnt` 均基于近 7 日窗口计算，取每日分区时代表以该日为终点的 7 日窗口结果，时间语义为滑动窗口而非单日，**不可跨日期累加**。
- ROI 分组字段（`roi_ratio_group`）基于近 7 日 ROI 表现，`_cnt` 和 `_rev_usd` 中的花费为当日花费，ROI 判断为近 7 日窗口，两者时间窗口不同，使用时需注意口径差异。

---

## 数据来源

| 上游表 | 用途 |
|--------|------|
| `mp_paidads.ads_advertise_mkt_1d__reg_s0_live` | 广告市场日粒度明细表，提供 ROI² 及全平台的花费、点击、曝光、GMV、订单、活跃标记等基础指标；同时用于 30 日活跃广告主统计、ROI 分组当日花费、Uplift 分析中的广告端数据 |
| `mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live` | 广告系列有效预算日表，提供广告系列维度的有效预算和花费数据 |
| `mp_paidads.dim_advertise_roi_exp__reg_s0_live` | ROI² 广告系列白名单维表，用于过滤筛选参与 ROI 预算分析的广告系列 |
| `mp_paidads.dwd_advertise_performance_di__reg_s0_live` | 广告绩效明细增量表，提供近 7 日 campaign 维度的 GMV 和花费，用于计算 ROI 比值（`roi_ratio`）进而完成出价分组 |
| `mp_order.dws_item_gmv_1d__reg_s0_live` | 商品 GMV 日汇总表，提供平台侧商品日 GMV 数据，用于 Uplift 分析中的 GMV 基准计算 |
| `mp_paidads.dws_advertise_net_ads_revenue_1d__reg_s0_live` | 广告净收入日汇总表，提供全平台及 ROI²（placement=40）的净广告收入 |

---

## ETL 逻辑摘要

### 数据流

```
mp_paidads.ads_advertise_mkt_1d__reg_s0_live  ─────────────────────────────────────────────────────┐
  │ (placement=40, 当日)                                                                              │
  │──► [roi2_ads_1d]  ROI²广告基础指标（花费/点击/曝光/GMV/订单/活跃数/CPS去重点击）                │
  │                                                                                                   │
  │ (所有placement, 当日)                                                                             │
  │──► [total_ads_1d]  全平台广告花费及活跃规模                                                      │
  │                                                                                                   │
  │ (30日滑窗, 所有placement)                                                                         │
  │──► [roi2_whitelist_active_advertiser]  近30日活跃广告主数                                        │
  │                                                                                                   │
  │ (placement=40, 当日, 7日窗口花费聚合)                                                            │
  ├──► [roi_ratio_group 内层子查询-当日花费]                                                         │
  │                                                                                                   │
  │ (placement=40, 7日/21日窗口, Uplift分析广告端)                                                   │
  └──► [item_uplift 内层子查询-广告端]                                                               │
                                                                                                      │
mp_paidads.dwd_advertise_performance_di__reg_s0_live                                                  │
  │ (placement=40, 近7日)                                                                             │
  └──► [roi_ratio_group 内层子查询-ROI计算]                                                          │
       └──► [roi_ratio_group]  出价分组（overbid/fulfilled/underbid，6区间+总计）                   │
                                                                                                      │
mp_paidads.ads_campaign_valid_budget_1d__reg_s0_live ──┐                                             │
mp_paidads.dim_advertise_roi_exp__reg_s0_live ─────────┘ JOIN on campaign_id                         │
  └──► [campaign_valid_budget]  有效预算 & 有限预算花费                                               │
                                                                                                      │
mp_order.dws_item_gmv_1d__reg_s0_live                                                                 │
  │ (近20日)                                                                                          │
  └──► [platform_item_gmv]  商品平台GMV日数据                                                        │
       └──► [item_uplift]  Uplift分析（7日窗口vs14日中位数基准）                                     │
                                                                                                      │
mp_paidads.dws_advertise_net_ads_revenue_1d__reg_s0_live                                              │
  └──► [net_revenue]  全平台 & ROI² 净广告收入                                                       │
                                                                                                      │
[roi2_ads_1d] ────────────────────────────────────────────────────────────────────────────────────────┤
[total_ads_1d] ───────────────────────────────────────────────────────────────────────────────────────┤
[roi2_whitelist_active_advertiser] ───────────────────────────────────────────────────────────────────┤
[campaign_valid_budget] ──────────────────────────────────────────────────────────────────────────────┤ CROSS JOIN（笛卡尔）
[roi_ratio_group] ────────────────────────────────────────────────────────────────────────────────────┤ → INSERT OVERWRITE
[item_uplift] ────────────────────────────────────────────────────────────────────────────────────────┤    PARTITION(tz_type='local', grass_region, grass_date)
[net_revenue] ────────────────────────────────────────────────────────────────────────────────────────┘
                                              │
                                              ▼
              ads_region_roi2_key_metrics_daily__reg_s0_live
              (每地区每日一行，共 44 列)
```

### 关键 CTE 说明

| CTE / 临时视图 | 来源表 | 作用 |
|----------------|--------|------|
| `roi2_ads_1d` | `ads_advertise_mkt_1d` | 计算 ROI² placement=40 当日广告花费、点击、曝光、宽口径 GMV/订单、活跃广告/商品/广告主数、CPS 去重点击、付费 GMV/订单 |
| `total_ads_1d` | `ads_advertise_mkt_1d` | 计算全平台（所有 placement）当日广告花费及活跃广告/商品/广告主规模 |
| `roi2_whitelist_active_advertiser` | `ads_advertise_mkt_1d` | 统计近 30 日（滑动窗口）有活跃行为的广告主数 |
| `campaign_valid_budget` | `ads_campaign_valid_budget_1d` JOIN `dim_advertise_roi_exp` | 计算 ROI² 白名单系列的有效预算总额，以及剔除无限预算（=9999999999）后的有限预算和实际花费 |
| `roi_ratio_group` | `ads_advertise_mkt_1d`（当日花费）+ `dwd_advertise_performance_di`（7日ROI） | 基于 campaign 维度的 7 日 ROI 比值，将活跃系列分为 6 个出价健康区间，统计各区间系列数和当日花费 |
| `platform_item_gmv` | `mp_order.dws_item_gmv_1d` | 提取近 20 日商品平台 GMV 日数据，作为 Uplift 分析的 GMV 基准数据源 |
| `item_uplift` | `ads_advertise_mkt_1d`（7日/21日窗口）+ `platform_item_gmv` | 以近 7 日 ROI² 活跃投放商品为窗口，计算平台 GMV 提升 ≥10% 的商品数及其广告花费，使用前 14 日（PREV_21D ~ PREV_8D）GMV 中位数作为基准 |
| `net_revenue` | `dws_advertise_net_ads_revenue_1d` | 汇总全平台及 ROI²（placement=40）当日净广告收入 |

### 注意事项

1. **笛卡尔积 JOIN**：最终 INSERT 语句中七个临时视图（`roi2_ads_1d`、`roi2_whitelist_active_advertiser`、`total_ads_1d`、`campaign_valid_budget`、`roi_ratio_group`、`item_uplift`、`net_revenue`）均为单行聚合结果，通过隐式 CROSS JOIN 合并。这一设计依赖于每个子查询**有且仅有一行输出**；若上游数据异常导致某子查询产生多行，结果将发生行数爆炸，需在数据质量监控中重点关注。

2. **`roi2_whitelist_shop_cnt` 与 `roi2_active_30d_whitelist_shop_cnt` 均为 null**：ETL 中两个字段显式写入 `null`，属于预留字段，当前版本不含白名单维度的店铺粒度数据，下游不可引用这两个字段进行分析。

3. **ROI 分组的时间窗口不一致**：ROI 分组中 `_rev_usd` 字段（花费）取当日（`BIZ_YESTERDAY`），而 ROI 比值（`roi_ratio`）基于近 7 日窗口（`PREV_7D ~ BIZ_YESTERDAY`）。因此"某区间系列数量"与"该区间当日花费"组合使用时，需理解二者时间维度差异：前者描述系列的中长期 ROI 健康状态，后者描述当日消耗规模。

4. **`campaign_expenditure_usd` 字段被注释掉**：ETL SQL 中 `roi2_campaign_expenditure_usd`（全量预算系列的实际花费）字段在开发阶段已被注释，DDL 中亦未包含，**本表无此字段**，如需请从上游表 `ads_campaign_valid_budget_1d` 获取。

5. **Uplift 分析的基准窗口**：前期基准使用 `PREV_21D ~ PREV_8D`（即 T-21 至 T-8 共 14 天）的平台 GMV 中位数；观测窗口使用 `PREV_7D ~ BIZ_YESTERDAY`（近 7 天）。两个窗口不重叠，确保基准不受当前投放影响，但若广告投放在前 14 天已存在则基准可能已含广告效果，分析时需注意。

6. **各地区参数化调度**：`${region}`、`${BIZ_YESTERDAY}`、`${PREV_7D}`、`${PREV_14D}`、`${PREV_21D}`、`${PREV_8D}`、`${PREV_30D}` 均为调度模板参数，各地区独立实例化执行，覆盖全量业务地区。

---

*文档生成时间：2026-04-22*
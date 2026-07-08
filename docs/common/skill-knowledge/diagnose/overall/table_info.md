<!-- ads-workspace-gdoc-sync: gdoc_id=1uW5VYFFMQd0dBw4yHJJU0QaY6ee2NX4w3KVdeMmj2t4 gdoc_url=https://docs.google.com/document/d/1uW5VYFFMQd0dBw4yHJJU0QaY6ee2NX4w3KVdeMmj2t4/edit -->

# ads_union_key_metrics_daily 表生产逻辑与字段说明 / Production Logic and Field Definitions

> **Contributors**: luka.yang ｜ **最后更新**：2026-05-28 ｜ [GitLab](https://git.garena.com/shopee/search_recommend/ai-copilot/ads-workspace/-/blob/master/docs/common/skill-knowledge/diagnose/overall/table_info.md)

---

## 1. 表概述/Table Overview

| 属性 | 值 |
|------|------|
| Hive 表名 | `mkplpaidads_search_ads.ads_union_key_metrics_daily__reg_s0_live` |
| ClickHouse 表名 | `mkplpaidads_search_ads_ads_debug.ads_union_key_metrics_daily__reg_s0_live` |
| 分区字段 | `grass_date` (日期), `grass_region` (地区) |
| 覆盖地区 | ID, PH, SG, TH, TW, MY, VN, BR |
| 更新频率 | 每日 INSERT OVERWRITE |
| 存储格式 | Parquet |

## 2. 数据血缘与生产流程/Data Lineage and Production Flow

### 2.1 整体血缘/Overall Lineage

```
ads_union_key_metrics_daily
  (UNION ALL 4 个 type, 每日 INSERT OVERWRITE)
  |
  |-- [type='ads']      ads_advertise_key_metrics_daily  (ads 粒度)
  |-- [type='campaign']  ads_campaign_key_metrics_daily   (campaign 粒度, GROUP BY campaign_id)
  |-- [type='item']      ads_item_key_metrics_daily       (item 粒度, GROUP BY item_id)
  |-- [type='shop']      ads_seller_key_metrics_daily     (shop 粒度, GROUP BY shop_id)
               |
               | 均来自同一上游, GROUP BY 不同维度
               v
       ads_advertise_key_metrics_daily
       (两步生产, ads 粒度核心宽表)
```

### 2.2 ads_advertise_key_metrics_daily 上游依赖/Upstream Dependencies

**Step 1 (qq 基础版)**: 以下 5 张表 JOIN

| 层级    | 表                                                                    | 职责                                                         | 来源系统                   |
| ----- | -------------------------------------------------------------------- | ---------------------------------------------------------- | ---------------------- |
| 原始事实  | `mp_paidads.dwd_advertise_performance_di__reg_s0_live`               | 广告行级日志, 所有核心指标原始来源 (曝光/点击/花费/订单/出价/pCTR/pCR 等)             | mp_paidads             |
| 漏斗    | `mkplpaidads_search_ads.full_link_funnel_metrics_daily__reg_s0_live` | 召回/粗排/精排/混排各阶段数量 (request->recall->prerank->rank->mixrank) | mkplpaidads_search_ads |
| 静态配置  | `mkplpaidads_search_ads.static_ads_info_metrics`                     | 广告 campaign/shop/item 关联、预算、ROI 目标                         | mkplpaidads_search_ads |
| 维表-入口 | `mp_paidads.dim_entry_point_mapping_v2`                              | entrance 编码 -> search/rec 等 traffic_type 映射                | mp_paidads             |
| 维表-汇率 | `mp_order.dim_exchange_rate__reg_s0_live`                            | 本地货币 -> USD 汇率转换                                           | mp_order               |

**Step 2 (qq_with_omni 补充版)**: 覆盖写回同表

| 层级 | 表 | 职责 |
|------|------|------|
| 自身 | `ads_advertise_key_metrics_daily__reg_s0_live` | Step 1 产出 |
| 全渠道 | `mkplpaidads_search_ads.omni_core_key_metrics_merge_daily` | ads vs total 曝光/点击/订单/GMV 对比 |
| 维表-入口 | `mp_paidads.dim_entry_point_mapping_v2` | 复用 |

### 2.3 调度顺序/Scheduling Order

```
Step 1: dwd_advertise_performance_di + full_link_funnel + static_ads_info + dim 表
          |
          v
        ads_advertise_key_metrics_daily (qq 基础版, 按 region 分任务并行)
          |
          v
Step 2: + omni_core_key_metrics_merge_daily
          |
          v
        ads_advertise_key_metrics_daily (qq_with_omni 覆盖写)
          |
          v
Step 3: 并行 GROUP BY 聚合
        |- ads_campaign_key_metrics_daily  (GROUP BY campaign_id, entrance, pricing_type)
        |- ads_item_key_metrics_daily      (GROUP BY item_id, entrance)
        |- ads_seller_key_metrics_daily    (GROUP BY shop_id, entrance)
          |
          v
Step 4: UNION ALL -> ads_union_key_metrics_daily
```

### 2.4 辅助诊断表/Auxiliary Diagnosis Tables

UNION 表是效果与投中指标主事实源；R1 自身操作归因还必须查询 STATUS / INACTIVE 作为事件日志补充，避免日聚合配置字段滞后或缺失导致漏归因。

| 别名 | ClickHouse 表名 | 集群 | 诊断用途 |
|------|-----------------|------|----------|
| STATUS | `mkplpaidads_search_ads_ads_debug.dwd_ads_index_status_live` | SG | 广告小时级索引状态与操作日志；用于 `visible/status` 停投、`reason` 中的 `change_budget`、`change roi` / `target roi` 变更兜底 |
| INACTIVE | `mkplpaidads_search_ads_ads_debug.unactive_ads_reason_metrics` | SG | 广告未投/停投原因补充 |

STATUS 关键字段：

| 字段 | 类型 | 口径说明 | 诊断用法 |
|------|------|----------|----------|
| `grass_date` | string | 本地日期字符串 | 与诊断日、主贡献日前后 1 天对齐 |
| `hour` | int/string | 本地小时 | 同日多次操作按小时排序 |
| `id` | bigint | Ads ID | 对应 UNION ads 粒度的 `ads_id` |
| `operation` | string | 操作类型 | 非 `INDEX` 操作可作为状态/配置变化旁证 |
| `reason` | string | 操作原因与变更详情 | 解析 `change_budget`、`change roi`、`target roi`，作为 R1.1/R1.2 兜底证据 |
| `visible` | int | 是否可见/投放 | 判定 R1.5 Ads 投放状态 |
| `status` | int | 广告状态 | 非 0 状态用于 R1.5 停投/异常状态 |

> R1.1/R1.2 使用 STATUS 时，必须在报告数字依据中标注 `STATUS operation fallback`，并写出原始 `reason` 或解析后的 `old -> new` 变化。

## 3. 字段定义与计算逻辑/Field Definitions and Calculation Logic

> **约定说明**:
> - "来源表" 列中 `perf` 代表 `mp_paidads.dwd_advertise_performance_di__reg_s0_live`
> - `bid_rerank_trace_json` 是对 `perf.bid_rerank_trace` 字段 JSON 解析后的 struct
> - `_by_imp` 后缀表示按曝光粒度聚合 (条件 `impression_cnt > 0`)
> - `_by_clk` 后缀表示按点击粒度聚合 (条件 `deduplicated_click > 0`)
> - `_7d` 后缀表示最近 7 天聚合
> - 金额类字段在 `perf` 中为本地币*100000, 产出时除以 `exchange_rate` 转为 USD
> - 在 campaign/item/shop 粒度表中, 大部分指标使用 `SUM()` 聚合, tier 类字段在 campaign 粒度重新计算, 在 item/shop 粒度使用 `MAX()`

### 3.1 维度字段/Dimension Fields

| 字段 | 类型 | 口径说明 | 计算 SQL |
|------|------|----------|----------|
| `type` | string | 数据粒度标识, 仅在 union 表中存在 | `'ads'` / `'campaign'` / `'item'` / `'shop'` (UNION ALL 时硬编码) |
| `entrance` | string | 流量属性, 标识广告入口/场景 (具体枚举值可见 Paid Ads Core Dimension Mapping) | 由 `dim_entry_point_mapping_v2` 将 `perf.entrance` 映射为 `traffic_type` (如 search/Daily Discover/You May Also Like 等), 未匹配的为 `'other'` |
| `plan_bucket_id` | string | 预算实验分桶 ID, 标识流量事件上的实验分组 | ads 粒度: `concat_ws(',', transform(plan_bucket_list, x -> cast(x as string)))`, campaign 粒度: 去重合并, item/shop 粒度: NULL |
| `pricing_type` | string | 计费类型 | 直接来源于 `perf.pricing_type` (如 CPC=1, CPA 类=11/15/24/25/27 等), item/shop 粒度为 NULL |
| `ads_id` | bigint | 投广的 AdsId | 直接来源, campaign/item/shop 粒度为 NULL |
| `campaign_id` | bigint | 投广的 CampaignId | 来源于 `static_ads_info_metrics.campaign_id`, item/shop 粒度为 NULL |
| `item_id` | bigint | 投广的 ItemId | 来源于 `static_ads_info_metrics.item_id`, campaign/shop 粒度为 NULL/MAX |
| `shop_id` | bigint | 投广的 ShopId | 来源于 `static_ads_info_metrics.shop_id` |
| `shop_level1_global_be_category` | string | 投广 ShopId 所在的一级全球后端类目 | `MAX(static_ads_info_metrics.shop_level1_global_be_category)` |
| `shop_level2_global_be_category` | string | 投广 ShopId 所在的二级全球后端类目 | `MAX(static_ads_info_metrics.shop_level2_global_be_category)` |
| `grass_date` | date | 数据日期 (分区) | T-1 日 |
| `grass_region` | string | 地区 (分区) | ID/PH/SG/TH/TW/MY/VN/BR |

### 3.2 Tier/分层字段 / Tier & Bucket Fields

| 字段 | 类型 | 口径说明 | 计算 SQL (ads 粒度) |
|------|------|----------|----------|
| `under_bidding_tier_1d` | string | 当日出价偏离档位 (under_bid: cost_ratio < 0.8, full_fill: [0.8, 1.2], over_bid: > 1.2) | 若有 `idx_roi_upperbound` (Simple 模式): `broad_gmv_usd > revenue_usd * idx_roi_upperbound` -> `'under_bid'`, `>= revenue_usd * target_roi` -> `'full_fill'`（此处 `target_roi` 是 ROI 下限）, 否则 `'over_bid'`; 否则 (Target 模式): `revenue_usd < advv_usd * 0.8` -> `'under_bid'`, `<= advv_usd * 1.2` -> `'full_fill'`, 否则 `'over_bid'` |
| `under_bidding_tier_7d` | string | 近 7 日出价偏离档位 (同 1d 逻辑) | 同上逻辑, 使用 `_7d` 指标 |
| `campaign_order_tier_1d` | string | 订单数分层, broad order cnt in L1D | `ads_broad_order >= 5` -> `'above5o'`, `>= 1` -> `'above1o'`, 否则 `'zeroOrder'` |
| `campaign_order_tier_7d` | string | 订单数分层, broad order cnt in L7D | 同上逻辑, 使用 `ads_broad_order_7d` |
| `budget_tier` | string | 预算充足度档位 | `valid_budget > 3 * (item_price/imp) * sold_cnt / troi` -> `'large'`, `> 1 *` -> `'middle'`, 否则 `'small'` |
| `hit_valid_budget_tier` | string | 是否撞有效预算 | `revenue_usd > 0.97 * campaign_valid_budget_usd` -> `'has_hit_budget'`, 否则 `'no_hit_budget'` (ads 粒度阈值 0.97, campaign 粒度 0.95) |
| `hit_daily_budget_tier` | string | 是否撞日预算 | `revenue_usd > 0.97 * budget_usd` -> `'has_hit_budget'`, 否则 `'no_hit_budget'` |
| `hit_account_balance_tier` | string | 是否撞账户余额 | `revenue_usd > 0.97 * account_balance_shop` -> `'has_hit_budget'`, 否则 `'no_hit_budget'` |
| `pcoc_tier` | string | PCOC 校准档位 | `daily_pgmv_sum_last_7d_clk / exchange_rate / broad_gmv_usd > 1.2` -> `'overpcoc'`, `> 0.8` -> `'fulfillmentpcoc'`, 否则 `'underpcoc'`, NULL 值 -> `'null'` |

### 3.3 核心效果指标（当日）/Core Performance Metrics (Daily)

| 字段 | 类型 | 口径说明 | 计算 SQL (ads 粒度) |
|------|------|----------|----------|
| `revenue_usd` | double | Gross Revenue, 广告收入 (USD) | `SUM(perf.expenditure_amt_usd)` |
| `advv_usd` | double | 到达口径的预期消耗 (USD), 统计到订单发生日期, advv = broad_gmv_amt_usd * target_cir | CPA 类 (pricing_type IN 11,15,24,25,27): `SUM(broad_gmv_amt_usd * target_cir)`, 其他: `SUM(expenditure_amt_usd)` |
| `direct_gmv_usd` | double | Direct 口径 GMV (USD), 同 shop 同 item 下单订单 | `SUM(perf.ads_order_gmv_usd)` |
| `broad_gmv_usd` | double | Broad 口径 GMV (USD), 同 shop 下单订单 | `SUM(perf.broad_gmv_amt_usd)` |
| `noimp_gmv` | double | No-imp 口径 GMV (USD), 无前置 impression 和 click 行为, 同 shop 同 item 有广告在索引即归因 | `SUM(perf.no_click_gmv_usd)` |
| `ads_direct_order` | int | 直接归因订单数 | `SUM(perf.order_cnt)` |
| `ads_broad_order` | int | 宽口径订单数 | `SUM(perf.broad_order_cnt)` |
| `ads_imp` | bigint | 去重后的 impression (de-duplicated impression) | `SUM(perf.impression_cnt)` |
| `ads_clk` | bigint | 去重后点击数 (de-duplicated click) | `SUM(perf.deduplicated_click)` |

### 3.4 核心效果指标（近 7 日）/Core Performance Metrics (Last 7 Days)

| 字段 | 类型 | 口径说明 | 计算 SQL |
|------|------|----------|----------|
| `revenue_usd_7d` | double | 近 7 日广告收入 (USD) | `SUM(expenditure_amt_usd)` WHERE `grass_date BETWEEN T-7 AND T-1` |
| `advv_usd_7d` | double | 近 7 日广告主价值 (USD) | 同 advv_usd 逻辑, 7 日窗口 |
| `ads_broad_order_7d` | double | 近 7 日宽口径订单 | `SUM(broad_order_cnt)` 7 日窗口 |
| `broad_gmv_usd_7d` | double | 近 7 日宽口径 GMV | `SUM(broad_gmv_amt_usd)` 7 日窗口 |
| `ads_imp_7d` | bigint | 近 7 日曝光数 | `SUM(impression_cnt)` 7 日窗口 |
| `ads_clk_7d` | bigint | 近 7 日点击数 | `SUM(deduplicated_click)` 7 日窗口 |

### 3.5 扣费相关指标/Deduction Metrics

| 字段 | 类型 | 口径说明 | 计算 SQL |
|------|------|----------|----------|
| `bid_price_sum` | double | 算法出价总和 (USD), 按 impression 统计的 adjusted bid price | `SUM(adjusted_bid_price / 100000.0) / exchange_rate` WHERE `impression_cnt > 0` |
| `boost_price_sum` | double | 算法 boost 出价总和 (USD), 按 impression 统计 | `SUM(boost_deduction_price / 100000.0) / exchange_rate` |
| `expect_deduction_price_sum_raw` | double | 预期扣费金额 (USD), 在 raw click 行为上统计 (未兼容 CPM) | `SUM(raw_expense / 100000.0) / exchange_rate` WHERE `raw_expense > 0` |
| `expect_deduction_price_sum_valid` | double | 预期扣费金额 (USD), 在 deduct click 行为上统计 (未兼容 CPM) | 同 `expect_deduction_price_sum_raw` |
| `gross_deduction_price_sum` | double | 实际扣费金额 (USD, 含 free credit), 在 deduct click 行为上统计 (未兼容 CPM) | `SUM(expenditure_amt_local) / exchange_rate` WHERE `expenditure_amt_local > 0` |
| `net_deduction_price_sum` | double | 实际扣费金额 (USD, 仅 paid credit 含 with/without expire, 不含 free credit), 未兼容 CPM | `SUM(expense_paid_credit_without_expiry + expense_paid_credit_with_expiry) / exchange_rate` |
| `raw_deduction_cnt` | int | 原始扣费次数 | `SUM(perf.raw_click_cnt)` |
| `valid_deduction_cnt` | int | 有效扣费次数 | `SUM(perf.click_cnt)` |

### 3.6 出价/预估相关（按曝光聚合, _by_imp）/ Bid & Prediction Metrics (by Impression)

| 字段 | 类型 | 口径说明 | 计算 SQL |
|------|------|----------|----------|
| `troi_sum_by_imp` | double | TROI 之和 (按曝光), target_cir 是算法调控后的 Target ROI 倒数 | `SUM(1.0 / target_cir)` WHERE `impression_cnt > 0` |
| `target_roi_by_imp` | double | 真实 target ROI / TROI 日均值（按曝光加权）；诊断中 R1 TROI 变更、TROI 绝对值、CPA 推导使用该字段，而不是配置字段 `target_roi` | `troi_sum_by_imp / ads_imp`（要求 `ads_imp > 0`） |
| `troi_max_by_imp` | double | TROI 最大值 (按曝光) | `MAX(1.0 / target_cir)` WHERE `impression_cnt > 0` |
| `troi_min_by_imp` | double | TROI 最小值 (按曝光) | `MIN(1.0 / target_cir)` WHERE `impression_cnt > 0` |
| `rt_remain_budget_sum_by_imp` | double | 在线剩余预算之和 (USD, 按曝光), RtRemainBudget = min(campaign_daily_budget_tmp - campaign_acc_cost_daily, account_realtime_balance) | `SUM(rt_remain_budget / 100000.0) / exchange_rate` WHERE `impression_cnt > 0` |
| `rt_remain_budget_min_by_imp` | double | 在线剩余预算最小值 (USD, 按曝光) | `MIN(rt_remain_budget / 100000.0) / exchange_rate` WHERE `impression_cnt > 0 AND rt_remain_budget >= 0` |
| `rt_remain_budget_max_by_imp` | double | 在线剩余预算最大值 (USD, 按曝光) | `MAX(rt_remain_budget / 100000.0) / exchange_rate` WHERE `impression_cnt > 0` |
| `sold_cnt_sum_by_imp` | double | 商品销量之和 (按曝光), 特征离线计算口径, 非实际商品数量 | `SUM(avg_sold_cnt_item)` WHERE `impression_cnt > 0` |
| `item_price_sum_by_imp` | double | 商品价格之和 (USD, 按曝光), 特征离线计算口径, 非实际商品价格 | `SUM(item_price / 100000.0) / exchange_rate` WHERE `impression_cnt > 0` |
| `coef_sum_by_imp` | double | PID 系数之和 (按曝光) | `SUM(pid_coef)` WHERE `impression_cnt > 0` |
| `coef_min_by_imp` | double | PID 系数最小值 | `MIN(pid_coef)` WHERE `impression_cnt > 0` |
| `coef_max_by_imp` | double | PID 系数最大值 | `MAX(pid_coef)` WHERE `impression_cnt > 0` |
| `pctr_sum_by_imp` | double | pCTR 之和 (按曝光), 到达口径, 校准后值 | `SUM(pctr)` WHERE `impression_cnt > 0` |
| `pcr_direct_sum_by_imp` | double | 直接 pCR 之和 (按曝光), 到达口径, 校准后值 | `SUM(direct_pcr_7d)` WHERE `impression_cnt > 0` |
| `pcr_direct_fail_imp_cnt` | bigint | 直接 pCR 为空或 <=0 的曝光次数 | `SUM(CASE WHEN impression_cnt>0 AND (direct_pcr_7d IS NULL OR direct_pcr_7d <= 0) THEN 1 ELSE 0 END)` |
| `pcr_broad_sum_by_imp` | double | 宽口径 pCR 之和 (按曝光), broad pcr = direct_pcr_7d + shop_pcr_7d | `SUM(direct_pcr_7d + shop_pcr_7d)` WHERE `impression_cnt > 0` |
| `pgmv_direct_sum_by_imp` | double | 直接 pGMV 之和 (USD, 按曝光), 到达口径, 校准后值 | `SUM(cali_direct_pgmv_7d / 100000.0) / exchange_rate` WHERE `impression_cnt > 0` |
| `pgmv_broad_sum_by_imp` | double | 宽口径 pGMV 之和 (USD, 按曝光), 到达口径, 校准后值 | `SUM(cali_broad_pgmv_7d / 100000.0) / exchange_rate` WHERE `impression_cnt > 0` |
| `final_pgmv_sum_by_imp` | double | 最终 pGMV 之和 (USD, 按曝光) | `SUM(pgmv / 100000.0) / exchange_rate` WHERE `impression_cnt > 0` |
| `padvv_sum_by_imp` | double | pADVV 之和 (USD, 按曝光) | `SUM(padvv / 100000.0) / exchange_rate` WHERE `impression_cnt > 0` |
| `ecpm_sum_by_imp` | double | eCPM 之和 (USD, 按曝光), ecpm = adjusted_bid_price * pctr | `SUM(pctr * adjusted_bid_price / 100000.0) / exchange_rate` WHERE `impression_cnt > 0` |

### 3.7 出价/预估相关（按点击聚合, _by_clk）/ Bid & Prediction Metrics (by Click)

| 字段 | 类型 | 口径说明 | 计算 SQL |
|------|------|----------|----------|
| `pcr_direct_sum_by_clk` | double | 直接转化率预估之和 (按点击) | `SUM(direct_pcr_7d)` WHERE `deduplicated_click > 0` |
| `pcr_broad_sum_by_clk` | double | 宽口径转化率预估之和 (按点击) | `SUM(direct_pcr_7d + shop_pcr_7d)` WHERE `deduplicated_click > 0` |
| `pgmv_direct_sum_by_clk` | double | 直接 pGMV 之和 (USD, 按点击) | `SUM(cali_direct_pgmv_7d / 100000.0) / exchange_rate` WHERE `deduplicated_click > 0` |
| `pgmv_broad_sum_by_clk` | double | 宽口径 pGMV 之和 (USD, 按点击) | `SUM(cali_broad_pgmv_7d / 100000.0) / exchange_rate` WHERE `deduplicated_click > 0` |
| `final_pgmv_sum_by_clk` | double | 最终 pGMV 之和 (USD, 按点击) | `SUM(pgmv / 100000.0) / exchange_rate` WHERE `deduplicated_click > 0` |
| `padvv_sum_by_clk` | double | pADVV 之和 (USD, 按点击) | `SUM(padvv / 100000.0) / exchange_rate` WHERE `deduplicated_click > 0` |
| `ecpc_sum_by_clk` | double | eCPC 之和 (USD, 按点击) | `SUM(pctr * adjusted_bid_price / 100000.0) / exchange_rate` WHERE `deduplicated_click > 0` |

### 3.8 全链路漏斗指标/Full-Link Funnel Metrics

> 来源表: `mkplpaidads_search_ads.full_link_funnel_metrics_daily__reg_s0_live`
> 原始数据: `srdi_mart.dwd_sr_data_warehouse_*_unify_full_link_log_1h` (search + rcmd)
> JOIN 条件: `ads_id + regional_date + country + entrance`

| 字段 | 类型 | 口径说明 | 计算 SQL |
|------|------|----------|----------|
| `request_cnt` | bigint | 参竞请求数 (10% 采样, ads recall 10%, full link 5%) | `SUM(request_cnt)` from full_link_funnel_metrics_daily (rcmd 场景 2x 权重) |
| `after_recall_num` | bigint | 召回通过请求数, 包含 ads 和 organic 链路 | `SUM(after_recall_num)` |
| `ads_after_recall_num` | bigint | 广告召回通过请求数, 仅 ads 链路 | `SUM(ads_after_recall_num)` |
| `org_after_recall_num` | bigint | 自然结果召回通过请求数, 仅 organic 链路 | `SUM(org_after_recall_num)` |
| `after_prerank_num` | bigint | 粗排通过请求数 | `SUM(after_prerank_num)` |
| `after_rank_num` | bigint | 精排通过请求数 | `SUM(after_rank_num)` |
| `after_mixrank_num` | bigint | 混排通过请求数 | `SUM(after_mixrank_num)` |

### 3.9 PCOC 校准指标/PCOC Calibration Metrics

> 来源 CTE: `perf_8d_pcoc`, 使用自定义 UDF `cali_ratio_daily` 对 pgmv 进行按天校准
> 校准逻辑: `pgmv / 100000.0 * cali_ratio_daily(hour, feedback_ratio_1h/3h/24h/72h)[day_offset]`
> 窗口: 最近 8 天数据, 仅有点击的行 (`deduplicated_click > 0`), 排除 `uni_pcr_model_name='gpu_newdatav1_id'`

| 字段 | 类型 | 口径说明 | 计算 SQL |
|------|------|----------|----------|
| `daily_pgmv_sum_last_7d_clk` | double | 近 7 日校准后 pGMV 之和 (USD) | `SUM(pgmv_calibrated) / exchange_rate`, pgmv_calibrated = `pgmv/100000 * cali_ratio_daily(hour, fr_1h, fr_3h, fr_24h, fr_72h)[day_offset]` |
| `daily_padvv_sum_last_7d_clk` | double | 近 7 日校准后 pADVV 之和 (USD) | `SUM(pgmv_calibrated * target_cir) / exchange_rate` |
| `daily_advv_sum_last_7d_clk` | bigint | (已废弃) | `NULL` |
| `daily_pgmv_direct_sum_last_7d_clk` | bigint | (已废弃) | `NULL` |
| `daily_pgmv_broad_sum_last_7d_clk` | bigint | (已废弃) | `NULL` |

### 3.10 统计/计数字段 / Statistics & Count Fields

| 字段 | 类型 | 口径说明 | 计算 SQL |
|------|------|----------|----------|
| `ads_cnt` | int | 活跃广告数 (已限制有 impression) | ads 粒度: `1`, campaign/item/shop 粒度: `SUM(ads_cnt)` |
| `campaign_cnt` | int | 活跃活动数 (已限制有 impression) | ads 粒度: `1`, campaign 粒度: `1`, item/shop 粒度: `SUM(campaign_cnt)` |
| `shop_cnt` | int | 活跃店铺数 (已限制有 impression) | ads/item/shop 粒度: `1`, campaign 粒度: `1` |
| `item_cnt` | int | 活跃商品数 (已限制有 impression) | ads 粒度: `1`, item 粒度: `1`, campaign/shop 粒度: `SUM(item_cnt)` |

### 3.11 预算与账户字段/Budget and Account Fields

> 来源表: `mkplpaidads_search_ads.static_ads_info_metrics`

| 字段 | 类型 | 口径说明 | 计算 SQL |
|------|------|----------|----------|
| `valid_budget_campaign` | double | 活动有效预算 (USD) | `MAX(campaign_valid_budget_usd)` from static_ads_info_metrics |
| `topup_usd` | double | Total 充值金额 (USD), 包含所有渠道充值 | `MAX(topup_usd)` from static_ads_info_metrics |
| `manual_free_credit_topup_amt_1d` | double | 当日手动免费额度充值 (order_type=3 运营后台手动充值) | `MAX(manual_free_credit_topup_amt_1d)` from static_ads_info_metrics |
| `account_balance_shop` | double | 店铺账户当日最新余额 (USD, end of day balance) | `MAX(account_balance_shop)` from static_ads_info_metrics |
| `daily_budget` | double | 日预算 (USD) | `MAX(budget_usd)` from static_ads_info_metrics |

### 3.12 全渠道对比指标/Omni-Channel Comparison Metrics

> 来源表: `mkplpaidads_search_ads.omni_core_key_metrics_merge_daily` (Step 2 qq_with_omni 补充)
> JOIN 条件: `item_id + shop_id + grass_region + grass_date + scene(entrance)`

| 字段 | 类型 | 口径说明 | 计算 SQL |
|------|------|----------|----------|
| `ads_imp_cnt` | bigint | 广告曝光数 (全渠道口径) | `SUM(omni.ads_imp_cnt)` from omni_core_key_metrics_merge_daily |
| `ads_clk_cnt` | bigint | 广告点击数 (全渠道口径) | `SUM(omni.ads_click_cnt)` |
| `ads_order_cnt` | bigint | 广告订单数 (全渠道口径) | `SUM(omni.ads_order_cnt)` |
| `ads_gmv_usd` | double | 广告 GMV (全渠道口径, USD) | `SUM(omni.ads_gmv_usd)` |
| `total_imp` | bigint | 全渠道总曝光 | `SUM(omni.total_imp)` |
| `total_clk` | bigint | 全渠道总点击 | `SUM(omni.total_click)` |
| `total_order` | bigint | 全渠道总订单 | `SUM(omni.total_order)` |
| `total_gmv` | double | 全渠道总 GMV (USD) | `SUM(omni.total_gmv)` |

### 3.13 ROI 与竞价策略字段/ROI and Bidding Strategy Fields

> 来源表: `mkplpaidads_search_ads.static_ads_info_metrics`

| 字段 | 类型 | 口径说明 | 计算 SQL |
|------|------|----------|----------|
| `target_roi` | double | ROI 下限/配置值（即 `idx_target_roi`）；Simple 模式用于 ROI 下限，不代表真实 TROI；真实 target ROI 使用 `target_roi_by_imp = troi_sum_by_imp / ads_imp` | `MAX(idx_target_roi)` from static_ads_info_metrics |
| `idx_roi_upperbound` | double | ROI 上界 (Simple 模式) | `MAX(idx_roi_upperbound)`, 非 NULL 表示 Simple 模式 |
| `ultra_core_rev` | double | Ultra Core 收集到的 gross rev (USD) | `MAX(ultra_core_rev / 100000.0 / exchange_rate)` |
| `ultra_core_advv` | double | Ultra Core 收集到的 advv (USD) | `MAX(ultra_core_advv / 100000.0 / exchange_rate)` |
| `final_coef` | double | 最终系数 | `MAX(final_coef)` from static_ads_info_metrics |
| `mpc_e_gmv` | double | MPC 预期 GMV (USD) | `MAX(mpc_e_gmv / 100000.0 / exchange_rate)` |
| `mpc_e_cost` | double | MPC 预期 Cost (USD) | `MAX(mpc_e_cost / 100000.0 / exchange_rate)` |
| `gmv_after_23pm` | double | 23 点后 GMV (USD) | `MAX(gmv_after_23pm / 100000.0 / exchange_rate)` |
| `active_hour` | int | ads 当日在索引时长 (小时数) | `MAX(active_hour)` from static_ads_info_metrics |
| `is_active_after_20pm` | tinyint | 是否 20 点后仍活跃 | `MAX(is_active_after_20h)` from static_ads_info_metrics |

### 3.14 原始曝光/点击字段 / Raw Impression & Click Fields

> **曝光/点击字段对照表**:
>
> | 底表统一名称 | Performance 表字段 | 说明 |
> |------|------|------|
> | `ads_imp` | `impression_cnt` | 去重后曝光 |
> | `raw_ads_imp` | `raw_impression` | 原始曝光 |
> | `deduct_imp` | `deduct_impression` | 扣费曝光 (CPM) |
> | `ads_clk` | `deduplicated_click` | 去重点击 (CPC) |
> | `raw_ads_clk` | `raw_click_cnt` | 原始点击 |
> | `valid_deduction_cnt` | `click_cnt` | 扣费点击 |

| 字段 | 类型 | 口径说明 | 计算 SQL |
|------|------|----------|----------|
| `bid_rerank_trace_null_cnt` | bigint | bid_rerank_trace 为空的曝光数 | `SUM(CASE WHEN bid_rerank_trace IS NULL THEN impression_cnt ELSE 0 END)` |
| `raw_ads_imp` | bigint | 原始广告曝光 (未去重) | `SUM(perf.raw_impression)` |
| `raw_ads_clk` | bigint | 原始广告点击 (未去重) | `SUM(perf.raw_click_cnt)` |
| `deduct_imp` | bigint | 扣费曝光数 | `SUM(perf.deduct_impression)` |
| `deduplicated_click` | bigint | 去重后点击数 | `SUM(perf.deduplicated_click)` |

### 3.15 其他字段/Other Fields

| 字段 | 类型 | 口径说明 | 计算 SQL |
|------|------|----------|----------|
| `ad_tag` | bigint | 广告标签位图 | ads 粒度: `MAX(perf.ad_tag)`, campaign/item/shop 粒度: 提取第 34/50/61 位后合并 `(CASE WHEN MAX(MOD(FLOOR(ad_tag/POWER(2,34)),2))=1 THEN POWER(2,34) ELSE 0 END) + POWER(2,50) + POWER(2,61)` |
| `tc_imp_count` | bigint | 流量控制曝光数 | `SUM(CASE WHEN ad_tag 第 34 位 OR 第 56 位 = 1 THEN impression_cnt ELSE 0 END)` |

## 4. 数据过滤条件/Data Filter Conditions

- `perf` 表: `tz_type = 'local'`, `ads_id > 0`, `pricing_type != 0` (仅 Step 1)
- `static_ads_info_metrics`: `ads_id > 0`, `item_id > 0`, `shop_id > 0`
- 排除 `uni_pcr_model_name = 'gpu_newdatav1_id'` (SG 版本, 在 perf_1d 和 perf_8d_pcoc 中)
- union 表 ads 分区: `pricing_type != 0`; item/campaign/shop 分区: 无此过滤

## 5. 常用衍生指标计算方式/Common Derived Metrics

供查询时参考, 非表中直接存储:

| 衍生指标 | 计算公式 |
|----------|----------|
| CTR | `ads_clk / ads_imp` |
| CVR (直接) | `ads_direct_order / ads_clk` |
| CVR (宽口径) | `ads_broad_order / ads_clk` |
| CPC | `revenue_usd / ads_clk` |
| CPM | `revenue_usd / ads_imp * 1000` |
| ROI (宽口径) | `broad_gmv_usd / revenue_usd` |
| ROAS | `broad_gmv_usd / revenue_usd` |
| PCOC | `daily_pgmv_sum_last_7d_clk / broad_gmv_usd` |
| 平均出价 (USD) | `bid_price_sum / ads_imp` |
| 平均 pCTR | `pctr_sum_by_imp / ads_imp` |
| 平均 pCR (直接) | `pcr_direct_sum_by_imp / ads_imp` |
| 平均 eCPM | `ecpm_sum_by_imp / ads_imp` |
| 平均 PID 系数 | `coef_sum_by_imp / ads_imp` |
| 召回率 | `ads_after_recall_num / request_cnt` |
| 粗排通过率 | `after_prerank_num / after_recall_num` |
| 精排通过率 | `after_rank_num / after_prerank_num` |
| 混排通过率 | `after_mixrank_num / after_rank_num` |
| 广告渗透率 (曝光) | `ads_imp_cnt / total_imp` |
| 广告渗透率 (GMV) | `ads_gmv_usd / total_gmv` |

## 6. 各粒度字段覆盖/Field Coverage Across Granularities

> 以下标识各字段在不同粒度 (DWS 表) 中是否存在

| 字段类别 | 字段 | ads 表 | campaign 表 | item 表 | seller 表 | region 表 |
|------|------|:------:|:------:|:------:|:------:|:------:|
| 维度 | date/region/entrance | Y | Y | Y | Y | Y |
| 维度 | plan_bucket_id | Y | Y | - | - | Y |
| 维度 | pricing_type | Y | Y | - | - | Y |
| 维度 | ads_id | Y | - | - | - | - |
| 维度 | campaign_id | Y | Y | - | - | - |
| 维度 | item_id | Y | Y | Y | - | - |
| 维度 | shop_id | Y | Y | Y | Y | - |
| 维度 | L1/L2 类目 | Y | Y | Y | Y | Y |
| Tier | 超欠收/order/budget/pcoc tier | Y | Y | - | - | Y |
| 效果 | revenue/advv/gmv/order/imp/clk | Y | - | - | - | - |
| 7d 指标 | revenue_7d/advv_7d 等 | Y | - | - | - | - |
| 计费 | bid_price/boost/deduction | Y | - | - | - | - |
| 投中 | troi/budget/coef/pctr/pcr/pgmv | Y | - | - | - | - |
| 漏斗 | request/recall/prerank/rank/mixrank | Y | - | - | - | - |
| PCOC | daily_pgmv/padvv_7d_clk | Y | - | - | - | - |
| 统计 | ads/campaign/shop/item_cnt | Y | - | - | - | - |
| 预算 | valid_budget/topup/balance | Y | - | - | - | - |
| 全渠道 | omni imp/clk/order/gmv | Y | - | - | - | - |
| ROI | target_roi_by_imp/target_roi 下限/ultra_core/mpc 等 | Y | - | - | - | - |

> 注: 以上 "Y" 表示该粒度表中存在该字段, "-" 表示不存在或为 NULL。具体聚合方式详见各字段定义。
> 来源: [广告主诊断工具底表说明 GSheet](https://docs.google.com/spreadsheets/d/1XiSNynN0uFVacvqqRrcrwokcdre9qEsLyJgSKmP4M54/edit?gid=135623426#gid=135623426) "luka统一字段" tab

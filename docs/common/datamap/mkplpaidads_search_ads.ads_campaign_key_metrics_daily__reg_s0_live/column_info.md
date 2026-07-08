<!-- ads-workspace-gdoc-sync: gdoc_id=1cL-IQM_C0mHfR9R3oHCNNhRBCWjy-rgLRFbDFLisC1c gdoc_url=https://docs.google.com/document/d/1cL-IQM_C0mHfR9R3oHCNNhRBCWjy-rgLRFbDFLisC1c/edit -->

# Columns: mkplpaidads_search_ads.ads_campaign_key_metrics_daily__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

以下字段跨 campaign 聚合时不能直接 SUM，需取 MAX/MIN 或按 campaign 粒度处理：

- `target_roi`, `idx_roi_upperbound`, `final_coef` — campaign 级别属性，聚合用 MAX
- `valid_budget_campaign`, `daily_budget`, `topup_usd`, `account_balance_shop` — campaign/店铺级别，聚合用 MAX
- `item_id`, `shop_id` — 按 campaign 聚合时用 MAX (campaign 下多个 ad 的 item/shop 可能不同)
- `campaign_name`, `item_name`, `shop_name` — campaign 级别属性，聚合用 MAX
- `gmv_after_23pm`, `active_hour`, `is_active_after_20pm` — campaign 级别属性，聚合用 MAX
- `troi_change_direction`, `budget_change_direction` — campaign 级别，聚合用 MAX
- `is_ocpm` — campaign 级别属性，聚合用 MAX
- 卖家运营字段 (`is_rapid_boost_on`, `is_auto_topup_enabled`, 等) — campaign 级别属性，聚合用 MAX

### 枚举值映射 (Value Mappings)

**under_bidding_tier (1d / 7d)**:

| Value | Meaning |
|-------|---------|
| under_bid | 欠出价 (broad_gmv < target_roi x revenue) |
| full_fill | 达成出价目标 |
| over_bid | 超出价 (broad_gmv > idx_roi_upperbound x revenue) |
| others | 其他异常 |

**campaign_order_tier (1d / 7d)**:

| Value | Meaning |
|-------|---------|
| above5o | campaign 下单 >=5 单 |
| above1o | campaign 下单 1-4 单 |
| zeroOrder | campaign 无订单 |

**budget_tier**:

| Value | Meaning |
|-------|---------|
| large | 预算 > 3x 预期消耗 |
| middle | 预算 > 1x 预期消耗 |
| small | 预算较小 |

**hit_*_budget_tier**:

| Value | Meaning |
|-------|---------|
| has_hit_budget | 收入 > 预算的 95%/97% |
| no_hit_budget | 未触达预算上限 |

**pcoc_tier**:

| Value | Meaning |
|-------|---------|
| overpcoc | PCOC > 1.2, 模型高估 |
| fulfillmentpcoc | PCOC 在 0.8~1.2, 模型准确 |
| underpcoc | PCOC < 0.8, 模型低估 |
| null | 数据缺失 |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 'ID','PH','SG','TH','TW','MY','VN','BR' (标准 8 区) / 'BR' (US 扩展版 pipeline)
- `grass_date`: date('${ISO_YESTERDAY}') — 例行调度 / date('2026-05-24') 等固定日期 — ad-hoc 查询
- 分区过滤是必须的，几乎所有查询都包含 `grass_date = date(...)` 条件

## All Columns

> Note: DDL 基于 `ads_campaign_metrics_qq_us` 工作流中的最新版 CREATE TABLE (含 BR 专有扩展列)。部分列在标准 pipeline (SEA 8 区) 中不存在。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| entrance | string | 入口 (entrance ID 字符串) | - | - |
| plan_bucket_id | string | 投放计划 bucket ID (逗号分隔) | - | - |
| pricing_type | string | 出价类型 | - | - |
| ads_id | bigint | 广告 ID (campaign 粒度下为 null) | - | - |
| campaign_id | bigint | 广告计划 ID | - | - |
| item_id | bigint | 商品 ID | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| shop_level1_global_be_category | string | 店铺一级类目 | - | - |
| shop_level2_global_be_category | string | 店铺二级类目 | - | - |
| under_bidding_tier_1d | string | 当天欠出价分层标签 | - | - |
| under_bidding_tier_7d | string | 7天欠出价分层标签 | - | - |
| campaign_order_tier_1d | string | 当天 campaign 订单分层 | - | - |
| campaign_order_tier_7d | string | 7天 campaign 订单分层 | - | - |
| budget_tier | string | 预算分层标签 | - | - |
| hit_valid_budget_tier | string | 是否触达有效预算标签 | - | - |
| hit_daily_budget_tier | string | 是否触达日预算标签 | - | - |
| hit_account_balance_tier | string | 是否触达账户余额标签 | - | - |
| pcoc_tier | string | PCOC 模型预估准确度分层 | - | - |
| revenue_usd | double | 广告消耗收入 (USD) | - | - |
| advv_usd | double | 广告价值 (USD) | - | - |
| direct_gmv_usd | double | 直接 GMV (USD) | - | - |
| broad_gmv_usd | double | 宽口径 GMV (USD) | - | - |
| noimp_gmv | double | 无展示 GMV | - | - |
| ads_direct_order | int | 直接广告订单数 | - | - |
| ads_broad_order | int | 宽口径广告订单数 | - | - |
| ads_imp | bigint | 广告展示数 | - | - |
| ads_clk | bigint | 广告点击数 | - | - |
| revenue_usd_7d | double | 近7天消耗收入 (USD) | - | - |
| advv_usd_7d | double | 近7天广告价值 (USD) | - | - |
| ads_broad_order_7d | double | 近7天宽口径订单数 | - | - |
| broad_gmv_usd_7d | double | 近7天宽口径 GMV (USD) | - | - |
| ads_imp_7d | bigint | 近7天展示数 | - | - |
| ads_clk_7d | bigint | 近7天点击数 | - | - |
| bid_price_sum | double | 竞价出价总和 | - | - |
| boost_price_sum | double | Boost 出价总和 | - | - |
| expect_deduction_price_sum_raw | double | 预期扣费总和 (raw) | - | - |
| expect_deduction_price_sum_valid | double | 预期扣费总和 (valid) | - | - |
| gross_deduction_price_sum | double | 毛扣费总和 | - | - |
| net_deduction_price_sum | double | 净扣费总和 | - | - |
| raw_deduction_cnt | int | 原始扣费次数 | - | - |
| valid_deduction_cnt | int | 有效扣费次数 | - | - |
| troi_sum_by_imp | double | tROI 按展示加权总和 | - | - |
| troi_max_by_imp | double | tROI 按展示取最大值 | - | - |
| troi_min_by_imp | double | tROI 按展示取最小值 | - | - |
| rt_remain_budget_sum_by_imp | double | 实时剩余预算按展示加权总和 | - | - |
| rt_remain_budget_min_by_imp | double | 实时剩余预算按展示取最小值 | - | - |
| rt_remain_budget_max_by_imp | double | 实时剩余预算按展示取最大值 | - | - |
| sold_cnt_sum_by_imp | double | 已售数量按展示加权总和 | - | - |
| item_price_sum_by_imp | double | 商品价格按展示加权总和 | - | - |
| coef_sum_by_imp | double | 系数按展示加权总和 | - | - |
| coef_min_by_imp | double | 系数按展示取最小值 | - | - |
| coef_max_by_imp | double | 系数按展示取最大值 | - | - |
| pctr_sum_by_imp | double | pCTR 按展示加权总和 | - | - |
| pcr_direct_sum_by_imp | double | direct pCVR 按展示加权总和 | - | - |
| pcr_direct_fail_imp_cnt | bigint | direct pCVR 预测失败展示数 | - | - |
| pcr_broad_sum_by_imp | double | broad pCVR 按展示加权总和 | - | - |
| pgmv_direct_sum_by_imp | double | direct pGMV 按展示加权总和 | - | - |
| pgmv_broad_sum_by_imp | double | broad pGMV 按展示加权总和 | - | - |
| final_pgmv_sum_by_imp | double | 最终 pGMV 按展示加权总和 | - | - |
| padvv_sum_by_imp | double | pADVV 按展示加权总和 | - | - |
| ecpm_sum_by_imp | double | eCPM 按展示加权总和 | - | - |
| pcr_direct_sum_by_clk | double | direct pCVR 按点击加权总和 | - | - |
| pcr_broad_sum_by_clk | double | broad pCVR 按点击加权总和 | - | - |
| pgmv_direct_sum_by_clk | double | direct pGMV 按点击加权总和 | - | - |
| pgmv_broad_sum_by_clk | double | broad pGMV 按点击加权总和 | - | - |
| final_pgmv_sum_by_clk | double | 最终 pGMV 按点击加权总和 | - | - |
| padvv_sum_by_clk | double | pADVV 按点击加权总和 | - | - |
| ecpc_sum_by_clk | double | eCPC 按点击加权总和 | - | - |
| request_cnt | bigint | 请求数 | - | - |
| after_recall_num | bigint | 召回后广告数 | - | - |
| ads_after_recall_num | bigint | 召回后广告广告数 | - | - |
| org_after_recall_num | bigint | 召回后自然广告数 | - | - |
| after_prerank_num | bigint | 粗排后广告数 | - | - |
| after_rank_num | bigint | 精排后广告数 | - | - |
| after_mixrank_num | bigint | 混排后广告数 | - | - |
| daily_advv_sum_last_7d_clk | bigint | 近7天模型预估 ADVV 按点击汇总 (已废弃) | - | - |
| daily_pgmv_direct_sum_last_7d_clk | bigint | 近7天模型预估 direct pGMV 按点击汇总 (已废弃) | - | - |
| daily_pgmv_broad_sum_last_7d_clk | bigint | 近7天模型预估 broad pGMV 按点击汇总 (已废弃) | - | - |
| ads_cnt | int | 广告数量 | - | - |
| campaign_cnt | int | campaign 数量 (固定为 1) | - | - |
| shop_cnt | int | 店铺数量 (固定为 1) | - | - |
| item_cnt | int | 商品数量 | - | - |
| valid_budget_campaign | double | campaign 有效预算 | - | - |
| topup_usd | double | 充值金额 (USD) | - | - |
| manual_free_credit_topup_amt_1d | double | 手动免费信用充值金额 | - | - |
| account_balance_shop | double | 店铺账户余额 | - | - |
| ads_imp_cnt | bigint | Omni 渠道广告展示数 | - | - |
| ads_clk_cnt | bigint | Omni 渠道广告点击数 | - | - |
| ads_order_cnt | bigint | Omni 渠道广告订单数 | - | - |
| ads_gmv_usd | double | Omni 渠道广告 GMV (USD) | - | - |
| total_imp | bigint | 综合展示数 | - | - |
| total_clk | bigint | 综合点击数 | - | - |
| total_order | bigint | 综合订单数 | - | - |
| total_gmv | double | 综合 GMV | - | - |
| target_roi | double | 目标 ROI | - | - |
| idx_roi_upperbound | double | 索引 ROI 上界 | - | - |
| ultra_core_rev | double | Ultra Core 收入 | - | - |
| ultra_core_advv | double | Ultra Core ADVV | - | - |
| final_coef | double | 最终出价系数 | - | - |
| mpc_e_gmv | double | MPC 预估 GMV | - | - |
| mpc_e_cost | double | MPC 预估消耗 | - | - |
| gmv_after_23pm | double | 23点后 GMV | - | - |
| active_hour | int | 活跃小时数 | - | - |
| is_active_after_20pm | tinyint | 是否在20点后有活跃 | - | - |
| daily_budget | double | 日预算 | - | - |
| bid_rerank_trace_null_cnt | bigint | bid_rerank_trace 为空次数 | - | - |
| raw_ads_imp | bigint | 原始广告展示数 (未去重) | - | - |
| raw_ads_clk | bigint | 原始广告点击数 (未去重) | - | - |
| deduct_imp | bigint | 扣费展示数 | - | - |
| deduplicated_click | bigint | 去重点击 | - | - |
| daily_padvv_sum_last_7d_clk | double | 近7天 pADVV 按点击汇总 | - | - |
| daily_pgmv_sum_last_7d_clk | double | 近7天 pGMV 按点击汇总 (用于 PCOC 计算) | - | - |
| ad_tag | bigint | 广告标签 (位图, 位34/50/56/57/61) | - | - |
| tc_imp_count | bigint | TC 展示计数 | - | - |
| rt_daily_budget_min_by_imp | double | 实时日预算按展示取最小值 (BR 扩展) | - | - |
| daily_pay_pgmv_sum_last_7d_clk | double | 近7天付费 pGMV 按点击汇总 (BR 扩展) | - | - |
| paid_broad_gmv_usd | double | 付费宽口径 GMV (USD) (BR 扩展) | - | - |
| paid_broad_gmv_usd_7d | double | 近7天付费宽口径 GMV (USD) (BR 扩展) | - | - |
| daily_model_pgmv_sum_last_7d_clk | double | 近7天模型 pGMV 按点击汇总 (BR 扩展) | - | - |
| ads_paid_order | bigint | 付费广告订单数 (BR 扩展) | - | - |
| ads_paid_order_7d | bigint | 近7天付费广告订单数 (BR 扩展) | - | - |
| model_broad_gmv_usd | double | 模型预估宽口径 GMV (USD) (BR 扩展) | - | - |
| resp_ads_imp | bigint | 响应广告展示数 (BR 扩展) | - | - |
| total_add_to_cart_cnt | bigint | 总加购数 (BR 扩展) | - | - |
| shop_adopts_gms | tinyint | 店铺采用 GMS 标志 (BR 扩展) | - | - |
| shop_gmv_tier | int | 店铺 GMV 分层 (BR 扩展) | - | - |
| hot_item_tag | tinyint | 热销商品标签 (BR 扩展) | - | - |
| potential_item_tag | tinyint | 潜力商品标签 (BR 扩展) | - | - |
| new_item_tag | tinyint | 新品标签 (BR 扩展) | - | - |
| winner_item_tag | tinyint | 爆品标签 (BR 扩展) | - | - |
| cheapest_item_tag | tinyint | 最低价商品标签 (BR 扩展) | - | - |
| stock | bigint | 库存 (BR 扩展) | - | - |
| is_rapid_boost_on | tinyint | 是否开启快速打爆 (BR 扩展) | - | - |
| is_auto_topup_enabled | tinyint | 是否开启自动充值 (BR 扩展) | - | - |
| auto_topup_daily_cap_amt_usd | double | 自动充值日上限 (USD) (BR 扩展) | - | - |
| auto_topup_amt_usd | double | 自动充值金额 (USD) (BR 扩展) | - | - |
| auto_topup_threshold_amt_usd | double | 自动充值阈值 (USD) (BR 扩展) | - | - |
| is_auto_escrow_enabled | tinyint | 是否开启自动托管 (BR 扩展) | - | - |
| auto_escrow_fixed_program_fee_rate | double | 自动托管固定费率 (BR 扩展) | - | - |
| auto_escrow_additional_fee_rate | double | 自动托管附加费率 (BR 扩展) | - | - |
| is_auto_budget_increase_enabled | tinyint | 是否开启自动增加预算 (BR 扩展) | - | - |
| auto_budget_increase_percentage | double | 自动增加预算百分比 (BR 扩展) | - | - |
| auto_budget_increase_daily_cap | double | 自动增加预算日上限 (BR 扩展) | - | - |
| is_roi_three_voucher_enabled | tinyint | 是否开启 ROI3 券 (BR 扩展) | - | - |
| campaign_pause_cnt | int | campaign 暂停次数 (BR 扩展) | - | - |
| campaign_stop_cnt | int | campaign 停止次数 (BR 扩展) | - | - |
| troi_increase_cnt | int | tROI 上调次数 (BR 扩展) | - | - |
| troi_decrease_cnt | int | tROI 下调次数 (BR 扩展) | - | - |
| troi_mode_switch_cnt | int | tROI 模式切换次数 (BR 扩展) | - | - |
| finite_budget_increase_cnt | int | 有限预算增加次数 (BR 扩展) | - | - |
| finite_budget_decrease_cnt | int | 有限预算减少次数 (BR 扩展) | - | - |
| unlimited_budget_on_cnt | int | 不限预算开启次数 (BR 扩展) | - | - |
| unlimited_budget_off_cnt | int | 不限预算关闭次数 (BR 扩展) | - | - |
| max_budget_decrease_magnitude | double | 最大预算下调幅度 (BR 扩展) | - | - |
| troi_change_direction | string | tROI 变动方向 (BR 扩展) | - | - |
| budget_change_direction | string | 预算变动方向 (BR 扩展) | - | - |
| is_campaign_surge_enabled | tinyint | 是否开启 campaign surge (BR 扩展) | - | - |
| is_ocpm | tinyint | 是否 oCPM (2026-06-09 ALTER TABLE 新增) | - | - |
| campaign_name | string | campaign 名称 (BR 扩展, qq_with_omni pipeline) | - | - |
| item_name | string | 商品名称 (BR 扩展, qq_with_omni pipeline) | - | - |
| shop_name | string | 店铺名称 (BR 扩展, qq_with_omni pipeline) | - | - |
| total_seller_gmv_usd | double | 卖家总 GMV (USD) (BR 扩展) | - | - |
| grass_date | date | [PARTITION] 日期分区 | - | - |
| grass_region | string | [PARTITION] 地域分区 | - | - |

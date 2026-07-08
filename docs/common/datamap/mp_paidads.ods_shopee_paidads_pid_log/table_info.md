<!-- ads-workspace-gdoc-sync: gdoc_id=1xlYJKCIgrOXf9GE2LbBAPdgtlDOw216a6BZ5pVZV4VI gdoc_url=https://docs.google.com/document/d/1xlYJKCIgrOXf9GE2LbBAPdgtlDOw216a6BZ5pVZV4VI/edit -->

# mp_paidads.ods_shopee_paidads_pid_log

## Description

- **Desc:** ODS 层 PID (Proportional-Integral-Derivative) 出价控制日志表。记录搜索广告 PID 控制器每次迭代的实时出价状态，包括目标 ROI 达成偏差 (target_cir)、PID 参数 (P/I/D)、出价调整建议 (new_bid_price)、冷启动预算消耗等信息。数据来源于 `ods_log_search_pid_bidding_hi__reg_s0_live`，经去重和货币单位转换后写入。
- **Granularity:** message_id (事件级别)
- **Use Case:**
  1. PID 广告价值评估 (Ad Value / CIR Error Analysis) — 计算单广告的预期广告价值 `gmv * target_cir` 并与实际花费对比，评估 PID 控制精度
  2. Discovery Ads 目标 CIR 计算 — 提取 discovery ads 的目标 CIR (placement=4)，用于生成 dws_advertise_discovery_ads_target_cir_1d
  3. 基于预算的出价分析 (Budget-based Bidding) — 分析 `bid_type='8'` 的预算感知出价策略，提取 budget_ratio、expected_budget 等字段
  4. Simple CIR 监控 — 每日增量监测 PID 控制误差分布
  5. 分区就绪检查 — PySpark 任务中用 `SHOW PARTITIONS` 验证数据到达
  6. Bid2cost 训练数据生成 — 计算 `default_cpa_bid = sold_count * item_price * target_cir` 作为 bid2cost 模型训练标签 (placement=4 搜索广告)
  7. Suggest Budget 商品价格基准 — 聚合 item_price 作为预算建议模型的商品特征输入
- **Update Frequency:** Daily (按 region 分区写入)

## Key Metrics

- PID 控制指标: `target_cir` (目标CIR), `curr_cir` (当前CIR), `curr_error`, `curr_error_sum`, `last_error`
- 出价相关: `init_bid_price`, `new_bid_price`, `old_bid_price`, `bid_val_type`, `bid_price_limit`
- 效果指标: `imp_daily`/`imp_window`, `click_daily`/`click_window`, `order_daily`/`order_window`
- 成本/收入: `cost_daily`/`cost_window`, `gmv_daily`/`gmv_window`, `ecr`
- PID 参数: `proportion`(P), `integral`(I), `derivative`(D), `coef`, `p_i_ratio`
- 冷启动: `ads_spent_budget`, `region_spent_budget`, `is_ads_stop`, `is_region_stop`
- 商品信息: `item_price`, `sold_count`, `round_daily`/`round_window`
- 派生指标: `gmv * target_cir` (广告价值, 5+ files), `(1 - revenue/gmv/target_cir)` (CIR 误差比), `sold_count * item_price * target_cir` (默认 CPA 出价, 10+ files)

## Key Dimensions

- 分区: `tz_type` (local), `grass_region`, `grass_date`
- 业务: `ads_id`, `item_id`, `shop_id`, `message_id`
- extra_json 内嵌维度: `bid_type`, `pricing_type`, `budget_type`, `calc_source`

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | Parquet |
| Partition Columns | tz_type string, grass_region string, grass_date date |
| HDFS Path | hdfs://D2/projects/data_paidadsmart/hive/mp_paidads/ods_shopee_event_data__paidads_pid_log_di__reg_s0_live |
| Retention | - |
| Column Count | 38 (不含分区列) |
| Region Coverage | ID, TW, TH, SG, PH, MY, MX, CO, CL, BR, VN (+ local 变体: MX_local, CO_local, CL_local, BR_local) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 `--source from-di` 补充。

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 826 files (69 workflows, 7 scheduled_tasks, 749 manual_tasks, 1 playground)
- L7D Query Count: -
- Completeness: -
- Popularity: -

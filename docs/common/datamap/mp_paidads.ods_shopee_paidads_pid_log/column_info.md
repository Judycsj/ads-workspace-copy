<!-- ads-workspace-gdoc-sync: gdoc_id=1hljPWO41EXVvS9Co5JpZU1WxRsNF-nkr59vz8yGda_I gdoc_url=https://docs.google.com/document/d/1hljPWO41EXVvS9Co5JpZU1WxRsNF-nkr59vz8yGda_I/edit -->

# Columns: mp_paidads.ods_shopee_paidads_pid_log

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

以下字段因粒度原因不可直接 SUM 跨行聚合：

- `target_cir` -- 同一 `(grass_region, ads_id)` 下每次 PID 迭代有不同值，通常用 `MIN()` / `approx_percentile(x, 0.5)` 而非 SUM
- `new_bid_price`, `old_bid_price` -- 每轮迭代的最新建议价，非累加
- `init_bid_price` -- 同 ads 内通常一致，使用 `MIN()` 即可
- PID 参数 (`proportion`, `integral`, `derivative`, `coef`, `p_i_ratio`) -- 控制参数，非累加
- 冷启动字段 (`ads_spent_budget`, `region_spent_budget`) -- 累计值，需取最新或 MAX

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| extra_json.bid_type | 0 | 正常出价 (normal bid) |
| extra_json.bid_type | 8 | 基于预算的出价 (budget-based) |
| extra_json.pricing_type | 4 | Simple (自动出价) |
| extra_json.budget_type | 1 | 按天预算 |
| extra_json.calc_source | auto-bidding | 自动出价系统计算 |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (100% 查询)
- `grass_region`: ID, MY, PH, SG, VN, TH, TW, BR (标准 8 区); MX, CO, CL (拉美); REGION 大写匹配
- `init_bid_price > 0`: 过滤零出价广告 (高频)
- `ads_id > 0`: 过滤无效广告
- `get_json_object(extra_json, '$.bid_type') = '0'`: 按正常出价类型筛选
- `ads_id % 101 < 80`: PID 流量抽样 (80% 非 B 组)

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| message_id | string | message_id (去重键: CONCAT(session_id, sequence_id, event_timestamp, region)) | - | - |
| item_id | bigint | item_id | - | - |
| shop_id | bigint | shop_id | - | - |
| ads_id | bigint | ads_id | - | - |
| imp_daily | bigint | imp_daily (当日累计展示) | - | - |
| imp_window | bigint | imp_window (窗口累计展示) | - | - |
| click_daily | bigint | click_daily (当日累计点击) | - | - |
| click_window | bigint | click_window (窗口累计点击) | - | - |
| order_daily | bigint | order_daily (当日累计订单) | - | - |
| order_window | bigint | order_window (窗口累计订单) | - | - |
| round_daily | bigint | round_daily (当日迭代轮次) | - | - |
| round_window | bigint | round_window (窗口迭代轮次) | - | - |
| window_size | bigint | predefined window size (预定义窗口大小) | - | - |
| ecr | double | expected conversion rate (预期转化率) | - | - |
| item_price | double | price of ad item (广告商品价格, 已 /100000) | - | - |
| sold_count | double | sold_count (已售数量) | - | - |
| cost_daily | double | cost_daily (当日累计花费, 已 /100000) | - | - |
| cost_window | double | cost_window (窗口累计花费, 已 /100000) | - | - |
| gmv_daily | double | gmv_daily (当日累计GMV, 已 /100000) | - | - |
| gmv_window | double | gmv_window (窗口累计GMV, 已 /100000) | - | - |
| init_bid_price | double | init_bid_price (初始出价, 已 /100000) | - | - |
| curr_cir | double | 1/ROI (当前CIR) | - | - |
| target_cir | double | target cir (目标CIR) | - | - |
| curr_error | double | curr_error | - | - |
| curr_error_sum | double | curr cir minus target cir | - | - |
| last_error | double | last_error | - | - |
| new_bid_price | double | new_bid_price suggested by PID (PID建议新出价, 已 /100000) | - | - |
| bid_val_type | bigint | whether lower or upper bound (出价上下界标识) | - | - |
| old_bid_price | double | old_bid_price (旧出价, 已 /100000) | - | - |
| coef | double | pid coefficient | - | - |
| proportion | double | proportional parameter (P 参数) | - | - |
| integral | double | integral parameter (I 参数) | - | - |
| derivative | double | derivative (D 参数) | - | - |
| p_i_ratio | double | proportion to integral ratio (P/I 比) | - | - |
| bid_price_limit | string | bid price upper and lower limit (出价上下限) | - | - |
| err_caps | string | error upper and lower limit (误差上下限) | - | - |
| interval | bigint | pid activates every interval in seconds | - | - |
| ab_sign | string | ab_sign (AB实验标识) | - | - |
| is_ads_stop | tinyint | cold_start_status.ads_stop (广告冷启动暂停) | - | - |
| ads_spent_budget | double | cold_start_status.ads_spent_budget (广告已花预算, 已 /100000) | - | - |
| is_region_stop | tinyint | cold_start_status.region_stop (区域冷启动暂停) | - | - |
| region_spent_budget | double | cold_start_status.region_spent_budget (区域已花预算, 已 /100000) | - | - |
| extra_json | string | extra_json (扩展JSON, 包含 bid_type/pricing_type/budget_type/budget_ratio/calc_source 等) | - | - |
| event_timestamp | bigint | when pid was activated (PID触发Unix时间戳) | - | - |
| event_datetime | string | datetime in local timezone (本地时区时间) | - | - |
| cir_type | bigint | cir_type | - | - |
| cir_subtype | bigint | cir_subtype | - | - |
| tz_type | string | 分区列 - tz_type (固定 'local') | - | - |
| grass_region | string | 分区列 - 区域 (大写, 如 ID/SG/MY/... ) | - | - |
| grass_date | date | 分区列 - 数据日期 | - | - |

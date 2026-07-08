<!-- ads-workspace-gdoc-sync: gdoc_id=18d_3iWLTXzcF3tUyCO9c7C5Y3pR0h0Jp48Ve27C9nDM gdoc_url=https://docs.google.com/document/d/18d_3iWLTXzcF3tUyCO9c7C5Y3pR0h0Jp48Ve27C9nDM/edit -->

# Columns: mp_paidads.dwd_advertiser_transaction_di__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

以下字段为余额快照值，跨维度聚合时不能直接 SUM，须使用 row_number() + MIN/MAX 获取首尾值：

- `acc_before_balance_local` -- 交易前账户余额，获取日初始值需 `row_number() OVER (ORDER BY event_timestamp ASC)`
- `acc_after_balance_local` -- 交易后账户余额，获取日终值需 `row_number() OVER (ORDER BY event_timestamp DESC)`
- `dai_before_balance_local` -- 交易前日累计余额
- `dai_after_balance_local` -- 交易后日累计余额
- `paid_free_expiry_summary` -- JSON 字段，聚合前须 explode/JSON 解析，不能直接 SUM
- `deduction_details` -- JSON 数组，聚合前须 explode

### 枚举值映射 (Value Mappings)

**event_code -> event_type (在 2+ 文件中确认):**

| Column | Value | Meaning |
|--------|-------|---------|
| event_code | 1 | deduction (扣费) |
| event_code | 2 | topup_from_order (订单充值) |
| event_code | 3 | topup_manual (手动充值) |
| event_code | 4 | topup_wallet (钱包充值) |
| event_code | 5 | deduct_order (订单扣费) |
| event_code | 6 | topup_svs (SVS充值) |
| event_code | 8 | topup_from_seller_mission (卖家任务充值) |
| event_code | 9 | topup_from_srm (SRM充值) |
| event_code | 10 | topup_negative (负向充值补偿) |
| event_code | 11 | deduct_imp (展示扣费，CPM) |
| event_code | 15 | (可用) deduction 扩展 |

**paid_free_expiry_summary entry.type (在 2+ 文件中确认):**

| Column (JSON path) | Value | Meaning |
|---------------------|-------|---------|
| entry.type | 1 | Paid credit without expiry |
| entry.type | 2 | Paid credit with expiry |
| entry.type | 3 | Free credit without expiry |
| entry.type | 4 | Free credit with expiry |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: `'local'` (~90% 查询) / 偶有 `'regional'`
- `event_code`: `in (1,11)` 扣费分析 / `in (1,11,15)` 完整扣费 / `= 1` 仅 deduction
- `grass_region`: `'SG'`, `'MY'`, `'ID'`, `'PH'`, `'TH'`, `'TW'`, `'VN'`, `'BR'`, `'MX'` (Asia); `'CO'`, `'CL'`, `'AR'` (US)
- `keyword != 'system_dummy_negative_deduction'` -- 生产写入必须排除
- `price = 0` -- 排查零金额异常交易
- `grass_region = upper('${region}')` -- 变量形式，生产标准写法

## All Columns

> 列名和类型从 INSERT SELECT 语句推断，未找到 DDL。Descriptions 为 "-" 的列请运行 `--source from-di` 补充。

| Column Name | Type | Description |
|-------------|------|-------------|
| id | BIGINT | 交易ID，来自 translog |
| shop_id | BIGINT | 店铺ID |
| user_id | BIGINT | 用户ID（卖家user_id） |
| ads_id | BIGINT | 广告ID |
| campaign_id | BIGINT | 广告计划ID |
| placement | BIGINT | 广告位 |
| ads_type | STRING | 广告类型 (from dim_advertise) |
| ads_status | BIGINT | 广告状态 (from dim_advertise) |
| keywords | STRING | 关键词 |
| item_id | BIGINT | 商品ID |
| price_local | DOUBLE | 交易金额（本地货币） |
| event_code | TINYINT | 事件操作码 (1-11)，见枚举值映射 |
| event_type | STRING | 事件类型名称 |
| event_timestamp | BIGINT | 事件 Unix 时间戳 |
| event_datetime | STRING | 事件日期时间字符串 (yyyy-MM-dd HH:mm:ss) |
| acc_before_balance_local | DOUBLE | 交易前账户余额（本地货币），非累加字段 |
| acc_after_balance_local | DOUBLE | 交易后账户余额（本地货币），非累加字段 |
| dai_before_balance_local | DOUBLE | 交易前日累余额（本地货币），非累加字段 |
| dai_after_balance_local | DOUBLE | 交易后日累余额（本地货币），非累加字段 |
| deduction_details | STRING | 扣费明细 JSON（array<struct>），含 order_id/order_type/balance_before/balance_after/main_type/with_expiry/effective_type/ads_credit_id/consumption_type |
| match_type | INT | 匹配类型 |
| recall_type | INT | 召回类型 |
| expected_price_deduction | BIGINT | 预期扣费金额 |
| user_query | STRING | 用户搜索词 |
| sort_type | INT | 排序类型 |
| pdp_item_id | BIGINT | 商品详情页商品ID |
| pdp_shop_id | BIGINT | 商品详情页店铺ID |
| pctr | DOUBLE | 预估CTR |
| bid_price | BIGINT | 出价 |
| second_ads_ecpm | DOUBLE | 第二名广告eCPM |
| second_ads_id | BIGINT | 第二名广告ID |
| ab_sign | STRING | AB实验算法标识 |
| topup_order_id | BIGINT | 充值订单ID（Asia版为null，US版从topup_sign解析） |
| paid_free_expiry_summary | STRING | 花费摘要 JSON，含 entries 数组（type/amount/effective_type），见枚举值映射 |
| topup_sign | STRING | 充值标识 |
| status | BIGINT | 交易状态 |
| entrance | INT | 入口/Entry Point |
| pricing_type | INT | 计费类型 |
| decoded_extinfo | STRING | 解码后的扩展信息（完整JSON），包含 entryPoint/subEntrance/requestId/trafficSource/deductionInfo 等 |
| account_id | STRING | 账户ID |
| deduct_unique_id | STRING | 扣费唯一ID |
| grass_region | STRING | 站点，分区列 [PARTITION] |
| grass_date | DATE | 日期，分区列 [PARTITION] |
| tz_type | STRING | 时区类型 (local/regional)，分区列 [PARTITION] |

## decoded_extinfo JSON 常用提取路径

以下字段存储在 `decoded_extinfo` JSON 中，下游查询常用 `get_json_object` 提取：

| JSON Path | Extracted As | Type | Used In |
|-----------|-------------|------|---------|
| $.subEntrance | sub_entrance | INT | dwd_advertiser_deduction_di |
| $.requestId | request_id | STRING | dwd_advertiser_deduction_di |
| $.deductionInfo.deductionPrice | deduction_price | BIGINT | dwd_advertiser_deduction_di |
| $.voucherDeductionPrice | voucher_deduction_price | BIGINT | dwd_advertiser_deduction_di |
| $.trafficSource | traffic_source | INT | dwd_advertiser_deduction_di |
| $.deductTimestamp | deduct_timestamp | BIGINT | dwd_advertiser_deduction_di |
| $.clickTimestamp | click_timestamp | BIGINT | dwd_advertiser_deduction_di |
| $.cpsTotalExpense | cps_total_expenditure_amt | BIGINT | dwd_advertiser_deduction_di |
| $.cpsAvailableBudget | cps_available_budget | BIGINT | dwd_advertiser_deduction_di |
| $.validBalance | valid_balance_amt | BIGINT | dwd_advertiser_deduction_di |
| $.availableBalance | available_balance_amt | BIGINT | dwd_advertiser_deduction_di |
| $.pricingType | pricing_type | INT | 生产写入 |
| $.campaignid | campaign_id | BIGINT | 生产写入 |
| $.entrance | entrance | INT | 生产写入 |
| $.matchType | match_type | INT | 生产写入 (US variant) |
| $.recallType | recall_type | INT | 生产写入 (US variant) |
| $.expectDeductPrice | expected_price_deduction | BIGINT | 生产写入 (US variant) |

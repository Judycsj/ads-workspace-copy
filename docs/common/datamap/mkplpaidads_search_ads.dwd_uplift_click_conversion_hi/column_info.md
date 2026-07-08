<!-- ads-workspace-gdoc-sync: gdoc_id=1xlQX1oRSeoIE98zik9Mg7z1G3rj_G2lOgHrY-huochc gdoc_url=https://docs.google.com/document/d/1xlQX1oRSeoIE98zik9Mg7z1G3rj_G2lOgHrY-huochc/edit -->

# Columns: mkplpaidads_search_ads.dwd_uplift_click_conversion_hi

## Column Usage Notes

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| voucher_unpicked_reason | 17, 99 | RCT Control (no voucher picked) |
| voucher_unpicked_reason | 18 | RCT Treatment (voucher picked) |
| voucher_unpicked_reason | other | Strategy (非RCT线上策略) |
| voucher_bucket (派生) | NO_VOUCHER | voucher_price <= 0 (无券样本) |
| voucher_bucket (派生) | 02 | discount_ratio < 0.04 |
| voucher_bucket (派生) | 05 | 0.04 <= discount_ratio < 0.065 |
| voucher_bucket (派生) | 08 | 0.065 <= discount_ratio < 0.10 |
| voucher_bucket (派生) | 12 | 0.10 <= discount_ratio < 0.135 |
| voucher_bucket (派生) | 15 | 0.135 <= discount_ratio < 0.175 |
| voucher_bucket (派生) | 20 | 0.175 <= discount_ratio < 0.23 |
| voucher_bucket (派生) | 20P | discount_ratio > 0.22 (仅部分 test 表) |
| entrance | 1, 3, 4, 8, 9, 10, 11 | 生产写入过滤的入口 |
| pricing_type | 1, 2, 11, 15 | 生产写入过滤的 pricing 类型 |

### 常见 WHERE 值 (Common Filter Values)

- `grass_region`: 'ID','MY','PH','TH','SG','TW','VN','BR' (全量), 或单个 region
- `grass_date`: 通常取 `date('${bizTimeFormatter(BIZ_TIME, 'yyyy-MM-dd', '-1d')}')` 或指定日期范围
- `h`: 小时过滤，生产用 `(${BIZ_HOUR} + 23) % 24` (延迟 1h 写入)
- `deduplicated_click > 0`: 过滤有效点击
- `pcr_0 > 0.0`: 过滤 baseline 预测为零的无效记录
- `voucher_unpicked_reason IN (17, 18, 99)`: 只取 RCT 样本
- `user_id > 0 AND item_id > 0`: 过滤无效主键
- `signature IS NOT NULL AND signature <> ''`: AB 实验分析必需

### 模型输出字段来源 (Decoded Bid JSON)

| Output Column | JSON Key / Formula | Notes |
|---------------|--------------------|-------|
| pcr_0 | `$.uplift_pcr0` | baseline pCR |
| pcr_02 | `$.uplift_pcr_ratio1 * $.uplift_pcr0` | 02 档 pCR |
| pcr_05 | `$.uplift_pcr_ratio2 * $.uplift_pcr0` | 05 档 pCR |
| pcr_08 | `$.uplift_pcr_ratio3 * $.uplift_pcr0` | 08 档 pCR |
| pcr_12 | `$.uplift_pcr_ratio4 * $.uplift_pcr0` | 12 档 pCR |
| pcr_15 | `$.uplift_pcr_ratio5 * $.uplift_pcr0` | 15 档 pCR |
| pcr_20 | `$.uplift_pcr_ratio6 * $.uplift_pcr0` | 20 档 pCR |
| platform_gmv_0 | `$.platform_gmv_0` | baseline platform GMV |
| platform_gmv_ratio_1~7 | `$.platform_gmv_ratio_1` ~ `$.platform_gmv_ratio_7` | 各档位 platform GMV ratio |
| redeem_rate_1~7 | `$.redeem_rate_1` ~ `$.redeem_rate_7` | 各档位券核销率预测 |
| signature | `ods_log_ads_report_hi__reg_s0_live.signature` | AB signature |

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| request_id | STRING | 请求 ID，关联 click 和 conversion 的主键 | - | - |
| user_id | BIGINT | 用户 ID | - | - |
| item_id | BIGINT | 商品 ID | - | - |
| ads_id | BIGINT | 广告 ID | - | - |
| entrance | INT | 入口 | - | - |
| pricing_type | INT | 计费类型 | - | - |
| deduplicated_click | INT | 去重点击标识 (0/1) | - | - |
| roi3_traffic_bucket | BIGINT | ROI3 流量桶 ID (从 bid_rerank_trace JSON 解码) | - | - |
| model_roi3_bucket | STRING | 模型桶 (roi3_traffic_bucket % 100) | - | - |
| pcr_0 | DOUBLE | Baseline 预测转化率 (pcr = predicted conversion rate) | - | - |
| pcr_02 | DOUBLE | 折扣档 02 预测转化率 (约 0-4%) | - | - |
| pcr_05 | DOUBLE | 折扣档 05 预测转化率 (约 4%-6.5%) | - | - |
| pcr_08 | DOUBLE | 折扣档 08 预测转化率 (约 6.5%-10%) | - | - |
| pcr_12 | DOUBLE | 折扣档 12 预测转化率 (约 10%-13.5%) | - | - |
| pcr_15 | DOUBLE | 折扣档 15 预测转化率 (约 13.5%-17.5%) | - | - |
| pcr_20 | DOUBLE | 折扣档 20 预测转化率 (约 17.5%-23%) | - | - |
| voucher_unpicked_reason | INT | 券未领取原因 (17/99=Control, 18=Treatment) | - | - |
| pgmv | DOUBLE | 预估 GMV (来自 bid JSON, x 1e5) | - | - |
| voucher_price | DOUBLE | 券面额 (来自 bid JSON, x 1e5) | - | - |
| discount_ratio | DOUBLE | 折扣比 = voucher_price / item_price | - | - |
| pcr_v | DOUBLE | Strategy-adjusted predicted conversion rate | - | - |
| item_price | DOUBLE | 商品价格 (来自 ODS 日志) | - | - |
| is_ads_voucher_redeemed | INT | 归因 order 点击中是否含 ADS-ROI 券 (1=是, 0=否) | - | - |
| reward_discount | DOUBLE | ADS-ROI 券 reward_discount 之和 | - | - |
| direct_order_1h | INT | 1 小时内 direct order 数 (0/1) | - | - |
| signature | STRING | AB signature (用于实验分组解析) | - | - |
| platform_gmv_0 | DOUBLE | Baseline platform GMV 预测 (来自 decoded bid JSON) | - | - |
| platform_gmv_ratio_1 | DOUBLE | Platform GMV ratio 档位 1 (来自 decoded bid JSON) | - | - |
| platform_gmv_ratio_2 | DOUBLE | Platform GMV ratio 档位 2 (来自 decoded bid JSON) | - | - |
| platform_gmv_ratio_3 | DOUBLE | Platform GMV ratio 档位 3 (来自 decoded bid JSON) | - | - |
| platform_gmv_ratio_4 | DOUBLE | Platform GMV ratio 档位 4 (来自 decoded bid JSON) | - | - |
| platform_gmv_ratio_5 | DOUBLE | Platform GMV ratio 档位 5 (来自 decoded bid JSON) | - | - |
| platform_gmv_ratio_6 | DOUBLE | Platform GMV ratio 档位 6 (来自 decoded bid JSON) | - | - |
| platform_gmv_ratio_7 | DOUBLE | Platform GMV ratio 档位 7 (来自 decoded bid JSON) | - | - |
| redeem_rate_1 | DOUBLE | 券核销率预测档位 1 (来自 decoded bid JSON) | - | - |
| redeem_rate_2 | DOUBLE | 券核销率预测档位 2 (来自 decoded bid JSON) | - | - |
| redeem_rate_3 | DOUBLE | 券核销率预测档位 3 (来自 decoded bid JSON) | - | - |
| redeem_rate_4 | DOUBLE | 券核销率预测档位 4 (来自 decoded bid JSON) | - | - |
| redeem_rate_5 | DOUBLE | 券核销率预测档位 5 (来自 decoded bid JSON) | - | - |
| redeem_rate_6 | DOUBLE | 券核销率预测档位 6 (来自 decoded bid JSON) | - | - |
| redeem_rate_7 | DOUBLE | 券核销率预测档位 7 (来自 decoded bid JSON) | - | - |
| grass_region | STRING | [PARTITION] 国家区域 | - | - |
| grass_date | DATE | [PARTITION] 数据日期 | - | - |
| h | BIGINT | [PARTITION] 小时 | - | - |

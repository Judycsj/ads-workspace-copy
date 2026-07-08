<!-- ads-workspace-gdoc-sync: gdoc_id=1wN87jYwR_SzjPNkav7aRFqtR7SyKICuEAXNvGqcLMnA gdoc_url=https://docs.google.com/document/d/1wN87jYwR_SzjPNkav7aRFqtR7SyKICuEAXNvGqcLMnA/edit -->

# Columns: mp_paidads.dws_advertise_revenue_1d__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

本表所有指标列（total/paid/free expenditure）均来自 SUM 聚合，为可累加字段，无需 SUM(DISTINCT)。但需注意：
- **跨 ads_id 聚合**：同一 campaign 下可能有多条 ads_id，直接 SUM 按 campaign 维度即可
- **跨 tz_type 聚合**：tz_type 有 'local' 和 'regional' 两种，当前 US 库仅写入 'local'。Legacy 库同时写入两者，跨 tz_type 聚合时注意检查

### 枚举值映射 (Value Mappings)

以下映射从 2+ 个消费文件中的 CASE-WHEN 提取：

| Column | Value | Meaning |
|--------|-------|---------|
| entrance | - | 入口类型，从 dwd_advertiser_transaction_di.event_code in (1,11,15) 筛选 |
| sub_entrance | - | 子入口类型，从 decoded_extinfo JSON 中提取 $.subEntrance |
| traffic_source | 0 | 未知/默认（下游会转为 NULL） |
| tz_type | local | 本地时区（当前 US 库仅写入此值） |
| tz_type | regional | 区域时区（Legacy 库同时写入） |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (~100% 当前活跃查询使用 local; Legacy 有 'regional')
- `grass_region`: 标准 8 区（当前 US 库涵盖 BR/CO/CL/MX；Legacy 涵盖 SG/MY/TH/PH/VN/TW/ID）
- `grass_date`: DATE('${grass_date}') — 按日分区查询
- `traffic_source <> 0`: 下游性能表中将 traffic_source=0 转为 NULL 以对齐 report_ng

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| ads_id | bigint | 广告ID | - | - |
| placement | bigint | 广告位ID | - | - |
| campaign_id | bigint | 广告计划ID | - | - |
| shop_id | bigint | 店铺ID | - | - |
| item_id | bigint | 商品ID | - | - |
| entrance | int | 入口类型 | - | - |
| pricing_type | int | 出价类型 | - | - |
| total_expenditure_amt_local_1d | double | 总花费（本币） | - | - |
| total_expenditure_amt_usd_1d | double | 总花费（USD） | - | - |
| paid_expenditure_wo_expiry_amt_local_1d | double | 付费信用未过期花费（本币） | - | - |
| paid_expenditure_wo_expiry_amt_usd_1d | double | 付费信用未过期花费（USD） | - | - |
| paid_expenditure_w_expiry_amt_local_1d | double | 付费信用已过期花费（本币） | - | - |
| paid_expenditure_w_expiry_amt_usd_1d | double | 付费信用已过期花费（USD） | - | - |
| free_expenditure_wo_expiry_amt_local_1d | double | 免费信用未过期花费（本币） | - | - |
| free_expenditure_wo_expiry_amt_usd_1d | double | 免费信用未过期花费（USD） | - | - |
| free_expenditure_w_expiry_amt_local_1d | double | 免费信用已过期花费（本币） | - | - |
| free_expenditure_w_expiry_amt_usd_1d | double | 免费信用已过期花费（USD） | - | - |
| sub_entrance | int | 子入口类型 | - | - |
| traffic_source | int | 流量来源 | - | - |
| tz_type | string | 时区类型（分区列） | - | - |
| grass_region | string | 国家/区域（分区列） | - | - |
| grass_date | date | 数据日期（分区列） | - | - |

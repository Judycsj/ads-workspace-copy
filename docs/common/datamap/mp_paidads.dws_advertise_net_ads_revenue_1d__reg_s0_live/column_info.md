<!-- ads-workspace-gdoc-sync: gdoc_id=1U4TYLyNTmDxLFYmxhS9HXGh-4ukn6kgrgI6jPPjf59o gdoc_url=https://docs.google.com/document/d/1U4TYLyNTmDxLFYmxhS9HXGh-4ukn6kgrgI6jPPjf59o/edit -->

# Columns: mp_paidads.dws_advertise_net_ads_revenue_1d__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

- `brand_max_ads_type` — 使用 MAX() 聚合（写文件中为 `max(brand_max_ads_type)`）
- 大部分收入字段为可加字段（SUM），但跨不同聚合维度时需注意部分收入指标可能从不同上游 UNION ALL，直接 SUM 可能重复

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| push_type | 'ads_push' | 广告信用推送 |
| push_type | 'non_ads_push' | 非广告信用推送 |
| gov_order_type | 'gov' | 政府基金信用 |
| gov_order_type | 'SCS' | SCS 信用 |
| gov_order_type | 'SIP' | SIP 信用 |
| gov_order_type | 'lovito' | Lovito 信用 |
| gov_order_type | 'others' | 其他信用 |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (~80% 查询) / 'regional' (ID/TH/VN/BR 在 Take Rate 场景中使用)
- `grass_region`: 标准 8 区 ('ID','MY','PH','SG','TH','TW','VN','BR')
- `grass_date`: 单日查询或范围查询（`BETWEEN 'YYYY-MM-DD' AND 'YYYY-MM-DD'`），滚动窗口常用 7d/14d/30d
- `net_ads_revenue_usd_1d > 0` — 过滤无收入记录
- `paid_credit_revenue_usd_1d > 0 OR net_ads_revenue_usd_1d > 0` — Take Rate 场景过滤有收入 shop

## All Columns

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| shop_id | bigint | shop_id | - | - |
| ads_id | bigint | 广告 ID | - | - |
| entrance | int | 入口编码 | - | - |
| placement | int | 广告位 | - | - |
| pricing_type | int | 出价类型 | - | - |
| is_cb_shop | tinyint | 是否跨境卖家 | - | - |
| paid_credit_revenue_usd_1d | double | 付费充值收入 (USD, 税后) | - | - |
| display_ads_revenue_usd_1d | double | 展示广告收入 (USD) | - | - |
| others_free_credit_revenue_usd_1d | double | 其他免费信用收入 (USD) | - | - |
| paid_credit_expire_amt_usd_1d | double | 付费信用过期金额 (USD, 税后) | - | - |
| others_free_credit_expired_amt_usd_1d | double | 其他免费信用过期金额 (USD) | - | - |
| tax_paid_on_free_credit_revenue_usd_1d | double | 免费信用收入缴纳税费 (USD) | - | - |
| net_ads_revenue_usd_1d | double | 净广告收入 (USD) | - | - |
| entry_point | string | 入口名称 | - | - |
| free_credit_deduction_amt_usd_1d | double | 免费信用抵扣金额 (USD) | - | - |
| free_ads_revenue_amt_usd_1d | double | 免费广告收入总额 (USD, = free_credit_deduction + tax) | - | - |
| gross_ads_revenue_usd_1d | double | 广告毛收入 (USD) | - | - |
| entry_point_v2 | string | 入口名称 V2 | - | - |
| traffic_type | string | 流量类型 | - | - |
| sub_product_type | string | 子产品类型 | - | - |
| product_type | string | 产品类型 | - | - |
| main_product_type | string | 主产品类型 | - | - |
| scs_free_credit_revenue_usd_1d | double | SCS 免费信用收入 (USD) | - | - |
| sip_free_credit_revenue_usd_1d | double | SIP 免费信用收入 (USD) | - | - |
| lovito_free_credit_revenue_usd_1d | double | Lovito 免费信用收入 (USD) | - | - |
| gov_free_credit_revenue_usd_1d | double | 政府基金免费信用收入 (USD) | - | - |
| scs_free_credit_expired_amt_usd_1d | double | SCS 免费信用过期金额 (USD) | - | - |
| sip_free_credit_expired_amt_usd_1d | double | SIP 免费信用过期金额 (USD) | - | - |
| lovito_free_credit_expired_amt_usd_1d | double | Lovito 免费信用过期金额 (USD) | - | - |
| gov_free_credit_expired_amt_usd_1d | double | 政府基金免费信用过期金额 (USD) | - | - |
| seller_type | string | 卖家类型 | - | - |
| seller_type_1p | string | 卖家一级分类 | - | - |
| sub_push_type | string | 子推送类型 | - | - |
| push_type | string | 推送类型 (ads_push / non_ads_push) | - | - |
| credit_order_type | bigint | 信用订单类型编码 | - | - |
| credit_order_type_name | string | 信用订单类型名称 | - | - |
| raw_gross_ads_revenue_usd_1d | double | 原始毛收入 (USD, 税前) | - | - |
| credit_reason | string | 信用原因 | - | - |
| credit_topup_sub_type | bigint | 信用充值子类型编码 | - | - |
| credit_topup_sub_type_name | string | 信用充值子类型名称 | - | - |
| is_package_topup | tinyint | 是否套餐充值 | - | - |
| is_voucher_topup | tinyint | 是否券充值 | - | - |
| credit_program_id | bigint | 信用项目 ID | - | - |
| credit_program_name | string | 信用项目名称 | - | - |
| deduction_price_usd | double | 抵扣价格 (USD) | - | - |
| voucher_deduction_price_usd | double | 券抵扣价格 (USD) | - | - |
| credit_operator | string | 信用操作人 | - | - |
| voucher_name | string | 券名称 | - | - |
| credit_topup_type_name | string | 信用充值类型名称 | - | - |
| voucher_id | bigint | 券 ID | - | - |
| item_id | bigint | 商品 ID | - | - |
| is_cb_sip_affiliated | tinyint | 是否跨境 SIP 关联 | - | - |
| is_local_sip_affiliated | tinyint | 是否本地 SIP 关联 | - | - |
| sub_entrance | bigint | 子入口编码 | - | - |
| campaign_id | bigint | 广告计划 ID | - | - |
| ab_sign | string | AB 实验标识 | - | - |
| new_boost | int | 新型 boost 标识 | - | - |
| tz_type | string | 时区类型 (PARTITION) | - | - |
| grass_region | string | 地区 (PARTITION) | - | - |
| grass_date | date | 数据日期 (PARTITION) | - | - |

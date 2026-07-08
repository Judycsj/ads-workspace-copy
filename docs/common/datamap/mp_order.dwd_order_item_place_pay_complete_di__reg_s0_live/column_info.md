<!-- ads-workspace-gdoc-sync: gdoc_id=1uY2-QnTl8ClAVbPNvxRrIQRuZwKN46B5rRc3a301clQ gdoc_url=https://docs.google.com/document/d/1uY2-QnTl8ClAVbPNvxRrIQRuZwKN46B5rRc3a301clQ/edit -->

# Columns: mp_order.dwd_order_item_place_pay_complete_di__reg_s0_live

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

无明显 SUM(DISTINCT) 模式。但以下字段需要注意：
- `order_id` — 跨 item 聚合订单数时必须 COUNT(DISTINCT order_id)

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| is_placed | 1 | 已下单（几乎所有查询都过滤 is_placed=1） |
| is_bi_excluded | 0 | 未排除 BI（OKR/正式报表查询常过滤此字段） |
| is_cod_order | true | 货到付款订单（判断支付状态时需区分 COD vs 非 COD） |
| is_cod_order | false | 非货到付款订单 |
| tz_type | 'local' | 本地时区（~90% 查询使用） |
| tz_type | 'regional' | 区域统一时区 |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local'（绝大多数查询）
- `is_placed`: = 1（几乎所有查询必带）
- `is_bi_excluded`: = 0（用于正式报表，排除测试订单）
- `grass_region`: upper('${region}') 或标准区域 ('ID','MY','PH','SG','TH','TW','VN','BR','MX','CO','CL')
- `grass_date`: 通常 = yesterday 或 date range
- `add_on_deal_type`: IS NULL（排除附加交易）
- `create_timestamp`: >= unix_timestamp(grass_date) AND < unix_timestamp(grass_date + 1)（精确到天）
- COD 支付判断: `(is_cod_order = true AND shipping_confirm_datetime IS NOT NULL) OR (is_cod_order = false AND pay_timestamp IS NOT NULL AND pay_timestamp > 0)`

## All Columns

*注意：以下列名从代码引用中提取，非完整 DDL。运行 --source from-di 可获取完整列列表。*

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| order_id | bigint | 订单 ID | - | - |
| item_id | bigint | 商品 ID | - | - |
| model_id | bigint | SKU/型号 ID | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| buyer_id | bigint | 买家用户 ID | - | - |
| user_id | bigint | 用户 ID (alias of buyer_id in some contexts) | - | - |
| item_amount | bigint | 商品数量（件数） | - | - |
| gmv | decimal | 平台 GMV（本地货币） | - | - |
| gmv_usd | decimal | 平台 GMV（美元） | - | - |
| seller_gmv | decimal | 卖家 GMV（本地货币） | - | - |
| seller_gmv_usd | decimal | 卖家 GMV（美元） | - | - |
| commission_fee | decimal | 佣金（本地货币） | - | - |
| commission_fee_usd | decimal | 佣金（美元） | - | - |
| merchandise_subtotal_amt | decimal | 商品小计金额（本地货币） | - | - |
| merchandise_subtotal_amt_usd | decimal | 商品小计金额（美元） | - | - |
| order_price_pp | decimal | 商品单价（本地货币） | - | - |
| order_price_pp_usd | decimal | 商品单价（美元） | - | - |
| sv_rebate_by_seller_amt | decimal | 卖家承担的 SV 返利（本地货币） | - | - |
| sv_rebate_by_seller_amt_usd | decimal | 卖家承担的 SV 返利（美元） | - | - |
| pv_rebate_by_seller_amt | decimal | 卖家承担的 PV 返利（本地货币） | - | - |
| pv_rebate_by_seller_amt_usd | decimal | 卖家承担的 PV 返利（美元） | - | - |
| pv_coin_earn_by_seller_amt | decimal | 卖家承担的 PV 金币（本地货币） | - | - |
| pv_coin_earn_by_seller_amt_usd | decimal | 卖家承担的 PV 金币（美元） | - | - |
| sv_coin_earn_by_seller_amt | decimal | 卖家承担的 SV 金币（本地货币） | - | - |
| sv_coin_earn_by_seller_amt_usd | decimal | 卖家承担的 SV 金币（美元） | - | - |
| item_rebate_by_shopee_amt | decimal | Shopee 承担的商品返利（本地货币） | - | - |
| item_rebate_by_shopee_amt_usd | decimal | Shopee 承担的商品返利（美元） | - | - |
| sv_rebate_by_shopee_amt | decimal | Shopee 承担的 SV 返利（本地货币） | - | - |
| sv_rebate_by_shopee_amt_usd | decimal | Shopee 承担的 SV 返利（美元） | - | - |
| pv_rebate_by_shopee_amt | decimal | Shopee 承担的 PV 返利（本地货币） | - | - |
| pv_rebate_by_shopee_amt_usd | decimal | Shopee 承担的 PV 返利（美元） | - | - |
| coin_used_cash_amt | decimal | 金币抵现金额（本地货币） | - | - |
| coin_used_cash_amt_usd | decimal | 金币抵现金额（美元） | - | - |
| card_rebate_by_shopee_amt | decimal | Shopee 承担的卡返利（本地货币） | - | - |
| card_rebate_by_shopee_amt_usd | decimal | Shopee 承担的卡返利（美元） | - | - |
| card_rebate_by_bank_amt | decimal | 银行承担的卡返利（本地货币） | - | - |
| card_rebate_by_bank_amt_usd | decimal | 银行承担的卡返利（美元） | - | - |
| gross_buyer_service_fee | decimal | 买家服务费（本地货币） | - | - |
| gross_buyer_service_fee_usd | decimal | 买家服务费（美元） | - | - |
| buyer_paid_shipping_fee | decimal | 买家支付运费（本地货币） | - | - |
| buyer_paid_shipping_fee_usd | decimal | 买家支付运费（美元） | - | - |
| actual_buyer_paid_shipping_fee | decimal | 买家实际支付运费（本地货币） | - | - |
| actual_buyer_paid_shipping_fee_usd | decimal | 买家实际支付运费（美元） | - | - |
| insurance_premium_by_buyer_amt | decimal | 买家保险费（本地货币） | - | - |
| insurance_premium_by_buyer_amt_usd | decimal | 买家保险费（美元） | - | - |
| buyer_txn_fee | decimal | 买家交易费（本地货币） | - | - |
| buyer_txn_fee_usd | decimal | 买家交易费（美元） | - | - |
| create_timestamp | bigint | 订单创建时间戳（unix） | - | - |
| pay_timestamp | bigint | 支付时间戳（unix） | - | - |
| shipping_confirm_datetime | string | 发货确认时间 | - | - |
| is_placed | int | 是否已下单 | - | - |
| is_bi_excluded | int | 是否 BI 排除 | - | - |
| is_cod_order | boolean | 是否货到付款 | - | - |
| add_on_deal_type | string | 附加交易类型（NULL 表示普通订单） | - | - |
| level1_global_be_category_id | bigint | 一级全球类目 ID | - | - |
| level2_global_be_category_id | bigint | 二级全球类目 ID | - | - |
| level3_global_be_category_id | bigint | 三级全球类目 ID | - | - |
| level4_global_be_category_id | bigint | 四级全球类目 ID | - | - |
| level5_global_be_category_id | bigint | 五级全球类目 ID | - | - |
| grass_date | date | [PARTITION] 日期分区 | - | - |
| grass_region | string | [PARTITION] 地区分区 | - | - |
| tz_type | string | [PARTITION] 时区类型分区 | - | - |

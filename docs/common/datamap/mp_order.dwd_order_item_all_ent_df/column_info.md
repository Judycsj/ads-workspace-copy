<!-- ads-workspace-gdoc-sync: gdoc_id=1DDzE-3R78bvrwPIAdNIVNc3EvtMFJpNlV2GP8SUY3GE gdoc_url=https://docs.google.com/document/d/1DDzE-3R78bvrwPIAdNIVNc3EvtMFJpNlV2GP8SUY3GE/edit -->

# Columns: mp_order.dwd_order_item_all_ent_df

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

- `gmv_usd`: 同一订单多个商品项的行级 GMV，跨 item 聚合订单级 GMV 时需注意去重（用 `SUM(DISTINCT ...)` 或先聚合到 order_id 粒度）
- `net_sv_rebate_by_shopee_amt_usd`: 卖家券补贴金额，同一订单同一券只应加一次，跨 item 聚合需去重
- `merchandise_subtotal_amt_usd`: 订单级字段，跨 item 聚合需注意重复计算

### 枚举值映射 (Value Mappings)

本表自身无枚举映射字段，常见的枚举值来自 JOIN 的 `dim_voucher` 表（`voucher_groups` 中 `ADS-ROI` 标识广告券）。

### 常见 WHERE 值 (Common Filter Values)

- `grass_date`: 通常用 `date'${ISO_YESTERDAY}'` 或 `date'${bizTimeFormatter(BIZ_TIME,'yyyy-MM-dd','-1d')}'`（单日分区）
- `grass_region`: 标准 8 区 `('ID','TH','PH','VN','MY','TW','SG','BR')`，或单区如 `'SG'`、`'ID'`
- `tz_type`: `'local'`（本地时区，用于订单创建日期对齐）
- `DATE(create_datetime)`: 用于指定下单日期（如 `date'${ISO_YESTERDAY}'`）
- `grass_date >= date_sub(date, 30)`: 30 日窗口查询
- `net_sv_rebate_by_shopee_amt_usd > 0`: 过滤有卖家券补贴的订单
- `order_id % 1000 = 123`: 采样过滤（hash sampling）

## All Columns

DDL 未在代码库中找到。以下列来自 SQL 查询中实际使用的字段（类型为推断）：

| Column Name | Type (inferred) | Description | L7/14/30D Query | MAX(column) |
|-------------|-----------------|-------------|-----------------|-------------|
| grass_date | date | 分区日期 | - | - |
| grass_region | string | 国家/地区 | - | - |
| order_id | bigint | 订单 ID | - | - |
| item_id | bigint | 商品 ID | - | - |
| buyer_id | bigint | 买家 ID | - | - |
| seller_id | bigint | 卖家 ID | - | - |
| shop_id | bigint | 店铺 ID | - | - |
| sv_promotion_id | bigint | 卖家券 promotion_id | - | - |
| pv_promotion_id | bigint | 平台券 promotion_id | - | - |
| gmv_usd | double | GMV（美元） | - | - |
| net_sv_rebate_by_shopee_amt_usd | double | 卖家券补贴金额（含广告券，美元） | - | - |
| pv_rebate_by_shopee_amt_usd | double | 平台券补贴金额（美元） | - | - |
| net_pv_rebate_by_shopee_amt_usd | double | 平台券补贴净额（美元） | - | - |
| merchandise_subtotal_amt_usd | double | 商品小计金额（美元） | - | - |
| item_price_before_discount_pp_usd | double | 折前商品价格（美元） | - | - |
| item_input_price_pp_usd | double | 商品输入价格（美元） | - | - |
| order_price_pp_usd | double | 订单价格（美元） | - | - |
| create_datetime | timestamp | 订单创建时间 | - | - |
| create_timestamp | bigint | 订单创建时间戳（utc） | - | - |
| pay_datetime | timestamp | 订单支付时间 | - | - |
| actual_shipping_rebate_by_shopee_amt_usd | double | Shopee 实际运费补贴（美元） | - | - |
| shipping_discount_by_3pl_to_seller_amt_usd | double | 3PL 运费折扣给卖家（美元） | - | - |
| actual_shipping_rebate_by_seller_amt_usd | double | 卖家实际运费补贴（美元） | - | - |
| level1_global_be_category_id | bigint | 一级全球商品品类 ID | - | - |
| tz_type | string | 时区类型（local/regional） | - | - |
| virtual_sku_info_list | string | 虚拟 SKU 信息列表 | - | - |
| bundle_virtual_sku_info_list | string | 捆绑虚拟 SKU 信息列表 | - | - |

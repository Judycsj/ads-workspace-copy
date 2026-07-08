<!-- ads-workspace-gdoc-sync: gdoc_id=1BElfJIs0U24_gyl6SZr2pSFW1_30H6b1psLx1H1LwOY gdoc_url=https://docs.google.com/document/d/1BElfJIs0U24_gyl6SZr2pSFW1_30H6b1psLx1H1LwOY/edit -->

# Columns: mp_order.dwd_order_item_all_ent_df__reg_s0_live

> 注意：DDL 未在 paidads-alg 代码库中找到，以下列名和类型从 SQL 使用中推断。运行 `--source from-di` 可补充完整列清单、description、查询频率和 MAX 采样值。

## Column Usage Notes

### 非累加字段 (Non-Additive Fields)

- `gmv`, `gmv_usd`, `seller_gmv`, `seller_gmv_usd`, `seller_nmv`, `seller_nmv_usd`: 同一笔订单有多条 order_item 时直接 SUM 会重复计算订单级金额。跨商品聚合时注意去重。
- `order_id`: 订单级标识，跨商品聚合时须用 COUNT(DISTINCT order_id)。

### 枚举值映射 (Value Mappings)

| Column | Value | Meaning |
|--------|-------|---------|
| tz_type | 'local' | 本地时区视图（代码库中几乎所有查询都用此值） |
| tz_type | 'regional' | 区域时区视图 |
| order_item_status | 'OITEM_UNRATED' | 未评价 |
| order_item_status | 'OITEM_RATED' | 已评价 |
| is_bi_excluded | 0 | 非 BI 测试订单（正常订单，查询必加条件） |
| is_bi_excluded | 1 | BI 测试订单（需排除） |
| is_net_order | 1 | 净订单（排除取消退款） |
| order_be_status_id | 1 | 未支付/已取消（内部） |
| is_cb_shop | 1 | 跨境店铺 |
| is_cb_shop | 0 | 本地店铺 |
| order_fe_status | 'cancelled' | 已取消（前端状态） |

### 常见 WHERE 值 (Common Filter Values)

- `tz_type`: 'local' (几乎所有查询)
- `grass_region`: 标准 8 区 'ID','SG','TH','PH','TW','MY','VN','BR'；或 `upper('${region}')` 单区
- `is_bi_excluded`: 0（排除测试订单，几乎所有查询必加）
- `date(create_datetime)`: = date('${BIZ_YESTERDAY}') / >= date_sub(...) — 按创建日期滚动窗口过滤
- `grass_date`: >= date_sub('${BIZ_YESTERDAY}', N) — 按分区日期滚动窗口过滤（1d/7d/14d/30d/90d）
- `order_item_status`: IN ('OITEM_UNRATED', 'OITEM_RATED') — 已完成/已评价的有效订单
- `gmv > 0` / `gmv_usd != 0`: 有效 GMV 过滤
- `order_be_status_id != 1`: 排除未支付/取消的内部订单
- `is_net_order = 1`: 净订单过滤
- `coalesce(is_returned_item, 0) = 0`: 排除退货商品
- `coalesce(cancelled_qty, 0) = 0`: 排除取消数量
- `lower(order_fe_status) != 'cancelled'`: 排除已取消订单
- `COALESCE(payment_be_channel_id, 0) NOT IN (100061, 100062, ...)`: CB Citi 渠道排除（用于净广告收入计算）
- `pv_promotion_id IS NULL AND sv_promotion_id IS NULL`: 无券自然单识别

## All Columns

> 以下列名从 paidads-alg 代码库中的 SQL 使用推断，类型为推测值。运行 `--source from-di` 获取完整列清单。

| Column Name | Type | Description | L7/14/30D Query | MAX(column) |
|-------------|------|-------------|-----------------|-------------|
| grass_date | DATE | 分区日期 | - | - |
| grass_region | STRING | 区域（如 ID, SG, TH 等） | - | - |
| tz_type | STRING | 时区类型 (local/regional) | - | - |
| order_id | BIGINT | 订单 ID | - | - |
| shop_id | BIGINT | 店铺 ID | - | - |
| item_id | BIGINT | 商品 ID | - | - |
| buyer_id | BIGINT | 买家 ID | - | - |
| create_datetime | STRING | 订单创建时间 (yyyy-MM-dd HH:mm:ss) | - | - |
| create_timestamp | BIGINT | 创建时间 Unix 时间戳 | - | - |
| complete_datetime | STRING | 订单完成时间 | - | - |
| pay_datetime | STRING | 支付完成时间 | - | - |
| escrow_paid_datetime | STRING | 托管入账时间 | - | - |
| gmv | DOUBLE | GMV（本币） | - | - |
| gmv_usd | DOUBLE | GMV（USD） | - | - |
| seller_gmv | DOUBLE | 卖家 GMV（本币） | - | - |
| seller_gmv_usd | DOUBLE | 卖家 GMV（USD） | - | - |
| seller_nmv | DOUBLE | 卖家 NMV（本币） | - | - |
| seller_nmv_usd | DOUBLE | 卖家 NMV（USD） | - | - |
| is_bi_excluded | TINYINT | BI 排除标记 (0=正常, 1=测试) | - | - |
| is_net_order | TINYINT | 是否净订单 | - | - |
| order_item_status | STRING | 商品订单状态 (OITEM_UNRATED/OITEM_RATED/...) | - | - |
| order_be_status_id | INT | 后端订单状态 ID | - | - |
| order_fe_status | STRING | 前端订单状态 | - | - |
| order_be_status | STRING | 后端订单状态 | - | - |
| is_cb_shop | TINYINT | 是否跨境店铺 (1=是) | - | - |
| is_returned_item | TINYINT | 是否已退货 | - | - |
| cancelled_qty | INT | 取消数量 | - | - |
| payment_be_channel_id | BIGINT | 支付后端渠道 ID | - | - |
| pv_promotion_id | BIGINT | 平台优惠券 ID | - | - |
| sv_promotion_id | BIGINT | 卖家优惠券 ID | - | - |
| commission_base_amt_usd | DOUBLE | 佣金基数（USD） | - | - |
| commission_fee_usd | DOUBLE | 佣金费用（USD） | - | - |
| service_fee_usd | DOUBLE | 服务费（USD） | - | - |
| level1_global_be_category_id | BIGINT | 一级全球后台品类 ID | - | - |
| level1_global_be_category | STRING | 一级全球后台品类名 | - | - |

<!-- ads-workspace-gdoc-sync: gdoc_id=1nOkXkIGau2ZkL_RrU0qmpxwDpP5vEiSYYsqyfOhfeLs gdoc_url=https://docs.google.com/document/d/1nOkXkIGau2ZkL_RrU0qmpxwDpP5vEiSYYsqyfOhfeLs/edit -->

# mp_mgmt.ads_mgmtview_pl_1d__reg_live

## 外部表状态

- status: `resolved_describe`
- requested_table: `mp_mgmt.ads_mgmtview_pl_1d__reg_live`
- canonical_table: `mp_mgmt.ads_mgmtview_pl_1d__reg_live`
- resolution: `describe:exact`
- source: `datasuite_describe`
- business_docs: `pc2_metrics`

## 使用边界

- 这张表只在命中的业务文档显式声明时作为外部表使用。
- 字段、类型和分区过滤以本文件记录的 DataMap/DESCRIBE 元数据为准。
- 不要把这张表自动加入广告数仓主候选表集合；它只补充业务链路排查。

## 分区和过滤

- inferred_partition_keys: `grass_date`, `grass_region`, `tz_type`
- required_filters: `grass_date`, `grass_region`, `tz_type`

## 字段列表

| 字段 | 类型 | 说明 |
| --- | --- | --- |
| `business_line` | `varchar` | business lines include shopee, mp, dp, insurance, mitra/counter |
| `mandatory_commission_fee_usd_1d` | `decimal(35,10)` | The mandatory commission fee excluding VAT in USD of every date. Mandatory Commission fees charged to sellers for each successful sale made through shopee, which sellers cannot opt out of |
| `local_c2c_mandatory_commission_fee_usd_1d` | `decimal(35,10)` | The local c2c mandatory commission fee excluding VAT in USD of every date. Mandatory Commission fees charged to sellers for each successful sale made through shopee, which sellers cannot opt out of |
| `local_mall_mandatory_commission_fee_usd_1d` | `decimal(35,10)` | The local mall mandatory commission fee excluding VAT in USD of every date. Mandatory Commission fees charged to sellers for each successful sale made through shopee, which sellers cannot opt out of |
| `cb_mandatory_commission_fee_usd_1d` | `decimal(35,10)` | The cross-border mandatory commission fee excluding VAT in USD of every date. Mandatory Commission fees charged to sellers for each successful sale made through shopee, which sellers cannot opt out of |
| `optional_commission_fee_usd_1d` | `decimal(35,10)` | The shops service fees excluding VAT in USD of every date. Service fees charged to sellers for enrolling in specific programs provided by shopee, which sellers can opt out of |
| `local_c2c_optional_commission_fee_usd_1d` | `decimal(35,10)` | The local c2c shops service fees excluding VAT in USD of every date. Service fees charged to sellers for enrolling in specific programs provided by shopee, which sellers can opt out of |
| `local_mall_optional_commission_fee_usd_1d` | `decimal(35,10)` | The local mall shops service fees excluding VAT in USD of every date. Service fees charged to sellers for enrolling in specific programs provided by shopee, which sellers can opt out of |
| `cb_optional_commission_fee_usd_1d` | `decimal(35,10)` | The cross border shops service fees excluding VAT in USD of every date. Service fees charged to sellers for enrolling in specific programs provided by shopee, which sellers can opt out of |
| `handling_fee_usd_1d` | `decimal(35,10)` | Handling fee excluding VAT in USD from sellers and buyers of every date. The handling fee is the amount of transaction fee that Shopee charge to sellers/buyers for the service that Shopee help them to process order placement and payment |
| `seller_handling_fee_usd_1d` | `decimal(35,10)` | Seller handling revenue excluding VAT in USD of every date. The handling fee is the amount of transaction fee that Shopee charge to sellers for the service that Shopee help them to process order placement and payment |
| `local_seller_handling_fee_usd_1d` | `decimal(35,10)` | Local seller handling revenue excluding VAT in USD of every date. The handling fee is the amount of transaction fee that Shopee charge to local sellers for the service that Shopee help them to process order placement and payment |
| `cb_seller_handling_fee_usd_1d` | `decimal(35,10)` | CB seller handling revenue excluding VAT in USD of every date. The handling fee is the amount of transaction fee that Shopee charge to cross-border sellers for the service that Shopee help them to process order placement and payment |
| `buyer_handling_fee_usd_1d` | `decimal(35,10)` | Buyer handling fee excluding VAT in USD of every date.The handling fee is charged to buyers for using certain payment methods to process & fulfil an order |
| `local_buyer_handling_fee_usd_1d` | `decimal(35,10)` | Local buyer handling fee excluding VAT in USD of every date.The handling fee is charged to local buyers for using certain payment methods to process & fulfil an order |
| `cb_buyer_handling_fee_usd_1d` | `decimal(35,10)` | CB buyer handling fee excluding VAT in USD of every date.The handling fee is charged to cross-border buyers for using certain payment methods to process & fulfil an order |
| `other_revenue_usd_1d` | `decimal(37,10)` |  |
| `marketing_revenue_amt_usd_1d` | `decimal(36,10)` |  |
| `local_marketing_revenue_amt_usd_1d` | `decimal(36,10)` |  |
| `cb_marketing_revenue_amt_usd_1d` | `decimal(36,10)` |  |
| `net_paid_ads_revenue_usd_1d` | `decimal(35,10)` | total border net paid ads revenue amout in USD of every date |
| `local_net_paid_ads_revenue_usd_1d` | `decimal(35,10)` | local border net paid ads revenue amout in USD of every date |
| `cb_net_paid_ads_revenue_usd_1d` | `decimal(35,10)` | cross border net paid ads revenue amout in USD of every date |
| `digital_products_gross_profit_usd_1d` | `decimal(35,10)` | digital products gross profit in usd of the month |
| `subscription_revenue_usd_1d` | `decimal(35,10)` | subscription revenue in USD of the day |
| `local_subscription_revenue_usd_1d` | `decimal(35,10)` | local subscription revenue in USD of the day |
| `cb_subscription_revenue_usd_1d` | `decimal(35,10)` | cross border subscription revenue in USD of the day |
| `other_revenue_level2_usd_1d` | `decimal(36,10)` |  |
| `local_other_revenue_level2_usd_1d` | `decimal(36,10)` |  |
| `cb_other_revenue_level2_usd_1d` | `decimal(36,10)` |  |
| `ams_om_marketing_rev_usd_1d` | `decimal(25,10)` |  |
| `local_ams_om_marketing_rev_usd_1d` | `decimal(25,10)` |  |
| `cb_ams_om_marketing_rev_usd_1d` | `decimal(25,10)` |  |
| `tz_type` | `varchar` | timezone type |
| `grass_region` | `varchar` | region |
| `grass_date` | `date` | date of order creation |

## 解析日志

- `mp_mgmt.ads_mgmtview_pl_1d__reg_live` via `https://sradata.shopee.io/admin/api/datamap/table/info`: 表不存在
- `mp_mgmt.ads_mgmtview_pl_1d__reg_live` via `https://sradata.test.shopee.io/admin/api/datamap/table/info`: 表不存在

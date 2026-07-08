<!-- ads-workspace-gdoc-sync: gdoc_id=1O92lYGMy5Onod3GIMrTOWBtHPsXS-WexeeCJc5UN--w gdoc_url=https://docs.google.com/document/d/1O92lYGMy5Onod3GIMrTOWBtHPsXS-WexeeCJc5UN--w/edit -->

# mp_mgmt.dws_order_item_rev_di__reg_s0_live

## Description

- **Desc:** Order-item level revenue detail table from Shopee Management (mp_mgmt). Contains itemized commission fees (mandatory/optional by shop type), handling fees, service fees, and other revenue components. Core financial fact table for ads PC2 (Profit Contribution 2) modeling and commission-based feature engineering.
- **Granularity:** daily x order x item x model x group x bundle_order_item x region
- **Use Case:** User/Item PC2 revenue computation (dws_user_pc2_1d, dws_common_feature_user_item_pc2_1d), commission fee base extraction for ads models (item_pc2_commission_base_14d), item-level commission statistics (item_commission_stat_1p), daily order-item financial data export (mgmt_order_item_day)
- **Update Frequency:** Daily

## Key Metrics

- 佣金收入: commission_base_amt_usd, commission_fee_usd (total commission)
- 强制佣金 (Level 1): estimate_mandatory_commission_fee_usd_level1, estimate_local_c2c_mandatory_commission_fee_usd_level1, estimate_local_mall_mandatory_commission_fee_usd_level1, estimate_cb_mandatory_commission_fee_usd_level1
- 自选佣金 (Level 1): estimate_optional_commission_fee_usd_level1, estimate_local_c2c_optional_commission_fee_usd_level1, estimate_local_mall_optional_commission_fee_usd_level1, estimate_cb_optional_commission_fee_usd_level1
- 手续费 (Level 1): estimate_buyer_handling_fee_usd_level1, estimate_seller_handling_fee_usd_level1
- 其他收入 (Level 2): estimate_other_revenue_usd_level2
- 服务费: service_fee_usd

## Key Dimensions

- 分区: grass_date, grass_region
- 订单粒度: order_id, item_id, model_id, group_id, bundle_order_item_id
- 店铺: shop_id
- 商品类目: level1_global_be_category_id, level1_global_be_category
- 时间维度: regional_create_date, local_create_date, create_datetime, cancel_datetime
- 店铺类型标识: is_cb_shop, is_official_shop (mentioned in code comments)
- 过滤标识: is_bi_excluded_rev_prm, is_bi_excluded_order, is_returned_item

## Technical Properties

| Property | Value |
|----------|-------|
| Storage Format | - |
| Partition Columns | grass_date (date), grass_region (string) |
| HDFS Path | - |
| Retention | - |
| Column Count | - (DDL not found in codebase, run --source from-di to supplement) |
| Region Coverage | SEA 8 regions (ID, MY, PH, SG, TH, TW, VN, BR) |
| DQC Status | - |
| Table Size | - |

## Business Properties

未抓取 DataMap，请运行 --source from-di 补充

| Property | Value |
|----------|-------|
| Technical PIC | - |
| Team | - |
| Business Domain | - |
| DW Layer | - |

## Popularity

- Studio Tasks References: 46 files (0 write, 46 read)
- L7D Query Count: -
- Completeness: -
- Popularity: -
